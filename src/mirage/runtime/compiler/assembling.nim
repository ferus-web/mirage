import std/[os, osproc]

type
  AssemblyFailed* = object of CatchableError
  LinkingFailed* = object of CatchableError

proc assemblyFailed*(msg: string) {.inline.} =
  raise newException(AssemblyFailed, "The assembling process has failed: " & msg)

proc linkingFailed*(msg: string) {.inline.} =
  raise newException(LinkingFailed, "The linking process has failed: " & msg)

proc getMirageCacheDir*: string {.inline.} =
  getCacheDir() / "mirage" / "compiled"

proc assembleAndLink*(source, filename, clause: string): string {.inline.} =
  let finalName = getMirageCacheDir() / filename & '-' & clause
  discard existsOrCreateDir(getMirageCacheDir())
  writeFile(
    finalName & ".s",
    source
  )

  # invoke system assembler
  let assembler = findExe("as")
  if assembler.len < 1:
    assemblyFailed("cannot find assembler")

  let (output, exitCode) = execCmdEx(assembler & ' ' & finalName & ".s -o " & finalName & ".o -s")
  if exitCode != 0:
    assemblyFailed(assembler & " exited with non-zero exit code (" & $exitCode & "): " & output)

  # invoke system linker
  let linker = findExe("ld")
  if linker.len < 1:
    linkingFailed("cannot find linker")

  let (lnOutput, lnExitCode) = execCmdEx(linker & " --shared " & finalName & ".o -o " & finalName & ".so")
  if lnExitCode != 0:
    linkingFailed(linker & " exited with non-zero exit code (" & $exitCode & "): " & lnOutput)

  finalName & ".so"
