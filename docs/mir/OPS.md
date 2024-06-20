# MIR Operations

## Load/write type functions
### LOADI (load integer)
Loads an integer onto the stack position provided. \
**Arguments**: `<stack_position> <value>`

### LOADS (load string)
Loads a string onto the stack position provided. \
**Arguments**: `<stack_position> <value>`

### LOADO (load object)
Loads an object (data type with named/integer fields) onto the stack position provided. \
**Arguments**: `<stack_position>`

### LOADB (load bool)
Loads a boolean onto the stack position provided. \
**Arguments**: `<stack_position> <value>`

### LOADUI (load unsigned int)
Loads an unsigned integer onto the stack position provided. \
**Arguments**: `<stack_position> <value>`

### LOADL (load list)
Loads a list (dynamically expanding array of different types) onto the stack position provided. \
**Arguments**: `<stack_position>`

## Misc Functions
### CALL (call function)
Calls a built-in function or clause. \
**Arguments**: `<fn_name> <arguments>`

### SCAPL (set cap on list)
Sets a cap on a container atom like a list or string. Any overflows will result in the execution being halted. \
**Arguments**: `<stack_position> <cap>`

### MARKHOMO (mark homogenous)
Marks a list as homogenous (i. e, it can't host more than one type of atom inside of it) \
This can be used to speed up a few computations. \
**Arguments**: `<stack_position>`

## Logical Functions
### EQU (equate)
Executes the next operation if the two values on the stack are true, otherwise skips to the line after that one. \
**Arguments**: `<stack positions>`

### JUMP (jump)
Jumps to an operation number inside the current clause.
**Arguments**: `<operation number>`
