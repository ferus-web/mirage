## Utilities for making the in-memory JIT executable
## Copyright (C) 2024 Trayambak Rai

when defined(posix):
  import std/posix

type
  JITAllocationError* = object of Defect
  MarkExecutableError* = object of Defect

proc getPageSize*: uint {.inline.} =
  when defined(posix):
    sysconf(SC_PAGESIZE).uint
  else:
    {.error: "Unsupported platform".}

proc verifySize*(size: uint) {.raises: [JITAllocationError], inline.} =
  if size mod getPageSize() != 0:
    raise newException(JITAllocationError, 
      "JIT compiler failed to allocate memory segment: requested size is not fully divisible by page size!\n" &
      "size = " & $size & "; page_size = " & $getPageSize()
    )

proc jitAlloc*(size: uint): pointer {.inline.} =
  verifySize(size)

  when defined(posix):
    let flags = MAP_ANONYMOUS or MAP_PRIVATE
    var memory = mmap(nil, size.int, PROT_READ or PROT_WRITE, flags, -1, 0)

    if memory == MAP_FAILED:
      raise newException(JITAllocationError,
        "JIT compiler failed to allocate memory segment: mmap() returned MAP_FAILED!"
      )

    return memory

proc jitFree*(memory: pointer, size: uint) {.inline.} =
  verifySize(size)

  when defined(posix):
    let failed = munmap(memory, size.int)
    
    if failed.bool:
      raise newException(JITAllocationError,
        "JIT compiler failed to free memory segment: munmap() returned " & $failed
      )

proc markExecutable*(memory: pointer, size: uint) {.inline.} =
  if size == 0:
    return

  verifySize(size)
  when defined(posix):
    let failed = mprotect(memory, size.int, PROT_EXEC or PROT_READ)
    if failed.bool:
      raise newException(MarkExecutableError,
        "JIT compiler failed to mark memory segment as executable: mprotect() returned " & $failed & '\n' &
        "size = " & $size & "; errno = " & $errno
      )

proc getBits*(value: uint64, start, width: uint8): uint32 {.inline.} =
  if width > 32:
    raise newException(ValueError, "`width` must be greater than or equal to 32; got " & $width & " instead!")

  return cast[uint32]((value shr start) and ((1'u64 shl width) - 1'u))

proc setBits*(
  loc: ptr uint32,
  locStart: uint8,
  value: uint64, valueStart, width: uint8
) {.inline.} =
  if locStart + width > 32:
    raise newException(ValueError, "locStart + width must be lesser than 32.")

  loc[] = cast[uint32]((((1'u64 shl width) - 1) shl locStart))

  assert getBits(loc[], locStart, width) != 0

  loc[] = loc[] or getBits(value, valueStart, width) shl locStart
  
  assert getBits(loc[], locStart, width) == getBits(value, valueStart, width)
