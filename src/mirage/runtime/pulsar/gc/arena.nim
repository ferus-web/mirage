import ./[cell, graph], ../interpreter_type,
       ../../atom

proc addAliveRef*(arena: Arena, stackIndex: int) {.inline.} =
  for i, _ in arena.cells:
    var cell = arena.cells[i]

    if cell.index != stackIndex:
      continue

    inc cell.references

proc noLongerAliveRef*(arena: Arena, stackIndex: int) {.inline.} =
  for i, _ in arena.cells:
    var cell = arena.cells[i]

    if cell.index != stackIndex:
      continue

    cell.references = 0'u64

proc removeAliveRef*(arena: Arena, stackIndex: int) {.inline.} =
  for i, _ in arena.cells:
    var cell = arena.cells[i]

    if cell.index != stackIndex:
      continue

    dec cell.references

    arena.cells[i] = cell
import pretty
proc minorCollect*(arena: Arena) =
  var 
    graph = GCGraph()
    deallocCells: seq[int]

  for i, cell in deepCopy(arena.cells):
    if cell.old():
      continue

    if cell.references < 1:
      graph.removes.add(cell)
  
  graph.commit(arena.interpreter)
  
  # delete cells who's stack references no longer exist
  for i, de in deallocCells:
    arena.cells.del(i + de)

  # promote survivor cells
  for i, _ in arena.cells:
    var promoted = arena.cells[i]
    inc promoted.survived
    arena.cells[i] = promoted

proc addCell*(arena: Arena, stackIndex: int) {.inline.} =
  arena.cells.add(
    Cell(
      index: stackIndex,
      references: 1'u64,
      survived: 0'u64
    )
  )

proc synchronize*(arena: Arena) {.inline.} =
  ## Synchronize all cells with the interpreter's stack
  reset arena.cells
  for i, _ in arena.interpreter.stack: 
    arena.cells.add(
      Cell(
        index: i,
        references: 0'u64,
        survived: 0'u64
      )
    )

proc newArena*(interpreter: Interpreter): Arena {.inline.} =
  Arena(
    interpreter: interpreter,
    cells: @[]
  )
