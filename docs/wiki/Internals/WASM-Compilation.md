# WASM Compilation

WokeLang can compile programs to WebAssembly for browser and edge runtime execution.

---

## Overview

The WASM compiler translates WokeLang functions into WebAssembly binary format, enabling:

- **Browser execution**: Run WokeLang in web pages
- **Edge computing**: Deploy to WASI-compatible runtimes
- **Embedding**: Use WokeLang functions in other languages

---

## Architecture

```
WokeLang Source
      │
      ▼
    Parser
      │
      ▼
     AST
      │
      ▼
┌─────────────────┐
│  WASM Compiler  │
├─────────────────┤
│ - Type Section  │
│ - Function Sec  │
│ - Export Sec    │
│ - Code Section  │
└─────────────────┘
      │
      ▼
   .wasm binary
```

---

## Implementation

Located in `src/codegen/wasm.rs`:

```rust
use wasm_encoder::{
    CodeSection, ExportKind, ExportSection, Function, FunctionSection,
    Instruction, Module, TypeSection, ValType,
};

pub struct WasmCompiler {
    module: Module,
    type_section: TypeSection,
    function_section: FunctionSection,
    export_section: ExportSection,
    code_section: CodeSection,
    function_types: Vec<u32>,
}

impl WasmCompiler {
    pub fn new() -> Self {
        Self {
            module: Module::new(),
            type_section: TypeSection::new(),
            function_section: FunctionSection::new(),
            export_section: ExportSection::new(),
            code_section: CodeSection::new(),
            function_types: Vec::new(),
        }
    }

    pub fn compile(&mut self, program: &Program) -> Result<Vec<u8>, CompileError> {
        // Collect and compile functions
        let functions: Vec<_> = program.items
            .iter()
            .filter_map(|item| {
                if let TopLevelItem::Function(f) = item {
                    Some(f)
                } else {
                    None
                }
            })
            .collect();

        for func in &functions {
            self.compile_function(func)?;
        }

        // Build module sections
        self.module.section(&self.type_section);
        self.module.section(&self.function_section);
        self.module.section(&self.export_section);
        self.module.section(&self.code_section);

        Ok(self.module.finish())
    }
}
```

### Function Compilation

```rust
impl WasmCompiler {
    fn compile_function(&mut self, func: &Function) -> Result<(), CompileError> {
        let func_idx = self.function_types.len() as u32;

        // Build function type signature
        let param_types: Vec<ValType> = func.params
            .iter()
            .map(|p| self.woke_type_to_wasm(&p.type_expr))
            .collect::<Result<_, _>>()?;

        let return_types: Vec<ValType> = if let Some(ret) = &func.return_type {
            vec![self.woke_type_to_wasm(ret)?]
        } else {
            vec![]
        };

        // Add type to type section
        self.type_section.function(param_types.clone(), return_types.clone());
        self.function_section.function(func_idx);

        // Export the function
        self.export_section.export(&func.name, ExportKind::Func, func_idx);

        // Compile function body
        let mut code = Function::new(vec![]); // No locals beyond params

        // Build local variable index map
        let mut local_indices: HashMap<String, u32> = HashMap::new();
        for (i, param) in func.params.iter().enumerate() {
            local_indices.insert(param.name.clone(), i as u32);
        }

        // Compile body statements
        for stmt in &func.body {
            self.compile_statement(&mut code, stmt, &local_indices)?;
        }

        // Ensure function has end instruction
        code.instruction(&Instruction::End);

        self.code_section.function(&code);
        self.function_types.push(func_idx);

        Ok(())
    }
}
```

### Type Mapping

```rust
impl WasmCompiler {
    fn woke_type_to_wasm(&self, type_expr: &TypeExpr) -> Result<ValType, CompileError> {
        match type_expr {
            TypeExpr::Simple(name) => match name.as_str() {
                "Int" => Ok(ValType::I64),
                "Float" => Ok(ValType::F64),
                "Bool" => Ok(ValType::I32), // Booleans as i32
                _ => Err(CompileError::UnsupportedType(name.clone())),
            },
            _ => Err(CompileError::UnsupportedType("complex type".into())),
        }
    }
}
```

### Statement Compilation

```rust
impl WasmCompiler {
    fn compile_statement(
        &self,
        code: &mut Function,
        stmt: &Statement,
        locals: &HashMap<String, u32>,
    ) -> Result<(), CompileError> {
        match stmt {
            Statement::Return { value } => {
                self.compile_expr(code, value, locals)?;
                code.instruction(&Instruction::Return);
            }

            Statement::When { condition, then_block, else_block } => {
                // Compile condition
                self.compile_expr(code, condition, locals)?;

                // Convert to i32 for branch
                code.instruction(&Instruction::I32WrapI64);

                // if-then-else block
                code.instruction(&Instruction::If(wasm_encoder::BlockType::Empty));

                for stmt in then_block {
                    self.compile_statement(code, stmt, locals)?;
                }

                if let Some(else_b) = else_block {
                    code.instruction(&Instruction::Else);
                    for stmt in else_b {
                        self.compile_statement(code, stmt, locals)?;
                    }
                }

                code.instruction(&Instruction::End);
            }

            _ => {
                // Other statements not yet supported in WASM
                return Err(CompileError::UnsupportedStatement);
            }
        }

        Ok(())
    }
}
```

### Expression Compilation

```rust
impl WasmCompiler {
    fn compile_expr(
        &self,
        code: &mut Function,
        expr: &Expr,
        locals: &HashMap<String, u32>,
    ) -> Result<(), CompileError> {
        match expr {
            Expr::Literal(Literal::Int(n)) => {
                code.instruction(&Instruction::I64Const(*n));
            }

            Expr::Literal(Literal::Float(f)) => {
                code.instruction(&Instruction::F64Const(*f));
            }

            Expr::Literal(Literal::Bool(b)) => {
                code.instruction(&Instruction::I64Const(if *b { 1 } else { 0 }));
            }

            Expr::Identifier(name) => {
                let idx = locals.get(name)
                    .ok_or_else(|| CompileError::UndefinedVariable(name.clone()))?;
                code.instruction(&Instruction::LocalGet(*idx));
            }

            Expr::Binary { left, op, right } => {
                self.compile_expr(code, left, locals)?;
                self.compile_expr(code, right, locals)?;

                match op {
                    BinOp::Add => code.instruction(&Instruction::I64Add),
                    BinOp::Sub => code.instruction(&Instruction::I64Sub),
                    BinOp::Mul => code.instruction(&Instruction::I64Mul),
                    BinOp::Div => code.instruction(&Instruction::I64DivS),
                    BinOp::Mod => code.instruction(&Instruction::I64RemS),
                    BinOp::Lt => code.instruction(&Instruction::I64LtS),
                    BinOp::Gt => code.instruction(&Instruction::I64GtS),
                    BinOp::Le => code.instruction(&Instruction::I64LeS),
                    BinOp::Ge => code.instruction(&Instruction::I64GeS),
                    BinOp::Eq => code.instruction(&Instruction::I64Eq),
                    BinOp::Ne => code.instruction(&Instruction::I64Ne),
                    _ => return Err(CompileError::UnsupportedOperator),
                };
            }

            Expr::Unary { op, operand } => {
                match op {
                    UnaryOp::Neg => {
                        code.instruction(&Instruction::I64Const(0));
                        self.compile_expr(code, operand, locals)?;
                        code.instruction(&Instruction::I64Sub);
                    }
                    UnaryOp::Not => {
                        self.compile_expr(code, operand, locals)?;
                        code.instruction(&Instruction::I64Eqz);
                    }
                }
            }

            _ => return Err(CompileError::UnsupportedExpression),
        }

        Ok(())
    }
}
```

---

## Usage

### CLI Compilation

```bash
# Compile to WASM
woke compile --wasm -o output.wasm input.woke

# With optimization
woke compile --wasm --opt-level=s -o output.wasm input.woke
```

### Programmatic API

```rust
use wokelang::{Lexer, Parser, WasmCompiler};

fn compile_to_wasm(source: &str) -> Result<Vec<u8>, Error> {
    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize()?;

    let mut parser = Parser::new(tokens, source);
    let program = parser.parse()?;

    let mut compiler = WasmCompiler::new();
    compiler.compile(&program)
}
```

---

## WASM Module Structure

A compiled WokeLang module contains:

```
WASM Module
├── Type Section     - Function signatures
├── Function Section - Function type indices
├── Export Section   - Exported function names
└── Code Section     - Function bodies
```

### Example Output

For this WokeLang function:

```wokelang
to add(a: Int, b: Int) → Int {
    give back a + b;
}
```

The generated WASM (in WAT format) is:

```wat
(module
  (type (;0;) (func (param i64 i64) (result i64)))
  (func (;0;) (type 0) (param i64 i64) (result i64)
    local.get 0
    local.get 1
    i64.add
    return
  )
  (export "add" (func 0))
)
```

---

## Supported Features

### Currently Supported

| Feature | Status |
|---------|--------|
| Integer arithmetic | ✅ |
| Integer comparisons | ✅ |
| Boolean operations | ✅ |
| Function parameters | ✅ |
| Return statements | ✅ |
| Conditionals (when/otherwise) | ✅ |
| Float arithmetic | ✅ |

### Planned (v0.4.0)

| Feature | Status |
|---------|--------|
| Local variables | 🔜 |
| Loops (repeat) | 🔜 |
| Function calls | 🔜 |
| Arrays | 🔜 |
| Strings (via linear memory) | 🔜 |

---

## Using WASM Output

### In Browser

```html
<script>
async function run() {
    const response = await fetch('output.wasm');
    const bytes = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(bytes);

    // Call exported function
    const result = instance.exports.add(BigInt(5), BigInt(3));
    console.log('Result:', result);  // 8n
}
run();
</script>
```

### In Node.js

```javascript
const fs = require('fs');

async function run() {
    const bytes = fs.readFileSync('output.wasm');
    const { instance } = await WebAssembly.instantiate(bytes);

    const result = instance.exports.add(5n, 3n);
    console.log('Result:', result);  // 8n
}
run();
```

### In Rust (wasmtime)

```rust
use wasmtime::*;

fn main() -> Result<()> {
    let engine = Engine::default();
    let module = Module::from_file(&engine, "output.wasm")?;
    let mut store = Store::new(&engine, ());
    let instance = Instance::new(&mut store, &module, &[])?;

    let add = instance.get_typed_func::<(i64, i64), i64>(&mut store, "add")?;
    let result = add.call(&mut store, (5, 3))?;
    println!("Result: {}", result);  // 8

    Ok(())
}
```

---

## Limitations

1. **No garbage collection**: Linear memory management required
2. **No closures**: Functions cannot capture environment
3. **No strings directly**: Require memory allocation strategy
4. **No recursion limit**: Can overflow WASM stack

---

## Future Roadmap

### v0.4.0 - Full WASM Support
- Linear memory for strings and arrays
- WASI integration for I/O
- Exception handling
- Imported functions

### v0.5.0 - Optimizations
- Constant folding
- Dead code elimination
- Function inlining

---

## Debugging WASM

### View as WAT (text format)

```bash
# Using wasm2wat from wabt
wasm2wat output.wasm -o output.wat
```

### Validate WASM

```bash
# Using wasm-validate from wabt
wasm-validate output.wasm
```

### Inspect with hexdump

```bash
od -A x -t x1z output.wasm | head
# Should start with: 00 61 73 6d (\0asm)
```

---

## Next Steps

- [FFI Internals](FFI.md)
- [CLI Reference](../Reference/CLI.md)
- [Interpreter Internals](Interpreter.md)
