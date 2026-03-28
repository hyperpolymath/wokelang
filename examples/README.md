<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
# WokeLang Example Programs

This directory contains example programs demonstrating WokeLang's features.

## Running Examples

### Using the Interpreter (Tree-Walking)
```bash
woke run examples/01_hello.woke
```

### Using the VM (Bytecode)
```bash
woke run-vm examples/01_hello.woke
```

### Type Checking
```bash
woke typecheck examples/01_hello.woke
```

### Linting
```bash
woke lint examples/01_hello.woke
```

## Examples

### 01_hello.woke ✓ Interpreter ✓ VM
The simplest possible WokeLang program. Returns the answer to everything.

### 02_arithmetic.woke ✓ Interpreter ✓ VM
Basic arithmetic operations: addition, subtraction, multiplication, division, modulo.

### 03_conditionals.woke ✓ Interpreter ✓ VM
Conditional execution with `when/otherwise` (if/else) statements.

### 04_loops.woke ✓ Interpreter ⚠ VM (partial)
Repetition with `repeat...times` loops. Includes a factorial implementation.
*Note: VM loop implementation in progress*

### 05_functions.woke ✓ Interpreter ⚠ VM (not yet)
Function definitions, parameters, return types, and function calls.
*Note: VM function calls not yet implemented*

### 06_variables.woke ✓ Interpreter ✓ VM
Variable declaration with `remember` and reassignment.

### 07_arrays.woke ✓ Interpreter ⚠ VM (not yet)
Array creation, indexing, and manipulation.
*Note: VM array indexing not yet implemented*

### 08_consent.woke ✓ Interpreter ✓ VM
Consent gates with `only if okay` for permission-protected operations.

## Language Features

### Human-Centered Syntax
- `to function_name()` - Define a function
- `remember x = value` - Declare a variable
- `give back value` - Return from a function
- `when condition { ... } otherwise { ... }` - Conditional
- `repeat n times { ... }` - Loop
- `only if okay "permission" { ... }` - Consent gate

### Types
- `Int` - Integer numbers
- `Float` - Floating-point numbers
- `String` - Text strings
- `Bool` - Boolean values (true/false)
- `Array` - Collections
- `Result<T, E>` - Success/error values (Okay/Oops)

### Unique Features
- **Consent-Driven**: `only if okay` gates for capability-based security
- **Gratitude Blocks**: `thanks to { ... }` for acknowledgments
- **Emote Annotations**: `@emote` for emotional context
- **Units of Measure**: `measured in meters` for dimensional types

## Contributing

Feel free to add more examples! Follow these guidelines:
- Number examples sequentially
- Include comments explaining the code
- Keep examples focused on a single feature
- Test examples before committing

## License

PMPL-1.0-or-later
