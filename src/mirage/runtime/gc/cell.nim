type
  Cell* = object
    index*: int
    references*: uint
    survived*: uint64

const
  OldCellThreshold* {.intdefine: "MirageGCOldCellThreshold".} = 4

proc old*(cell: Cell): bool {.inline.} =
  cell.survived > OldCellThreshold

proc `$`*(cell: Cell): string =
  var s = "Mirage GC Cell"
  s &= "\nPoints to Stack Index: " & $cell.index
  s &= "\nAlive References: " & $cell.references
  s &= "\nSurvived Sweeps: " & $cell.survived

  s
