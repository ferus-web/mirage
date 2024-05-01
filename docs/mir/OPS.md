# MIR Operations

## Load/write type functions
### LOADI (load integer)
Loads an integer onto the stack position provided. \
**Arguments**: `<stack_position> <value>`

### LOADS (load string)
Loads a string onto the stack position provided. \
**Arguments**: `<stack_position> <value>`

## Misc Functions
### CALL (call function)
Calls a built-in function or clause. \
**Arguments**: `<fn_name> <arguments>`

## Logical Functions
### EQU (equate)
Executes the next operation if the two values on the stack are true, otherwise skips to the line after that one. \
**Arguments**: `<stack positions>`

### JUMP (jump)
Jumps to an operation number inside the current clause.
**Arguments**: `<operation number>`
