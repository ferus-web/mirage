import std/options
import ./[cell],
       ../../../atom

type
  ArenaKind* = enum
    akNewest = 0
    akNew = 1
    akOld = 2

  Arena* = object # We can't let the arena be a refcounted object otherwise that causes silly stuff to happen
    kind*: ArenaKind
    cells*: seq[Cell]

proc `=destroy`*(arena: Arena) {.inline, nimcall.} =
  `=destroy`(arena.cells)

proc evacuate*(source: Arena, target: var Arena) {.inline.} =
  assert source.kind < target.kind, "Cannot evacuate cells from a higher arena to a lower one!"
  ## "Evacuate" (aka sink) all cells from one arena to another
  for cell in source.cells:
    target.cells.add(cell)

  # zero out the source
  `=destroy`(source)

proc add*(arena: var Arena, cell: Cell) {.inline.} =
  var adds = true
  for i, c in arena.cells.deepCopy():
    if c.id == cell.id:
      arena.cells[i] = cell
      adds = false

  if adds:
    arena.cells.add(cell)

proc purge*(arena: var Arena, id: uint) {.inline.} =
  var i: int = -1

  for c in arena.cells:
    if c.id == id:
      i = c.id.int
  
  arena.cells.del(i)

proc find*(arena: Arena, id: uint): Option[Cell] {.inline, gcsafe, noSideEffect.} =
  for c in arena.cells:
    if c.id == id:
      return some c
