# Architecture Overview

This document describes the internal architecture of the WokeLang implementation.

---

## High-Level Pipeline

```
Source Code (.woke)
        │
        ▼
    ┌─────────┐
    │  Lexer  │  ─── Tokenization
    └────┬────┘
         │ Vec<Token>
         ▼
    ┌─────────┐
    │ Parser  │  ─── Syntax Analysis
    └────┬────┘
         │ AST (Program)
         ▼
    ┌─────────────────────────┐
    │  Execution Target       │
    ├─────────────────────────┤
    │ ┌─────────────────────┐ │
    │ │   Interpreter       │ │  ─── Tree-walking execution
    │ └─────────────────────┘ │
    │ ┌─────────────────────┐ │
    │ │   WASM Compiler     │ │  ─── WebAssembly compilation
    │ └─────────────────────┘ │
    └─────────────────────────┘
```

---

## Module Structure

```
src/
├── lib.rs              # Library exports
├── main.rs             # CLI entry point
├── repl.rs             # Interactive REPL
│
├── lexer/
│   ├── mod.rs          # Lexer implementation
│   └── token.rs        # Token types (logos-derived)
│
├── parser/
│   └── mod.rs          # Recursive descent parser
│
├── ast/
│   └── mod.rs          # AST node types
│
├── interpreter/
│   ├── mod.rs          # Tree-walking interpreter
│   └── value.rs        # Runtime value types
│
├── codegen/
│   └── wasm.rs         # WASM code generator
│
└── ffi/
    └── c_api.rs        # C-compatible FFI
```

---

## Component Details

### 1. Lexer (`src/lexer/`)

**Purpose**: Convert source text into a stream of tokens.

**Implementation**: Uses the `logos` crate for efficient lexer generation.

```rust
#[derive(Logos, Debug, Clone, PartialEq)]
pub enum Token {
    #[token("to")]
    To,

    #[token("remember")]
    Remember,

    #[regex(r"[a-zA-Z_][a-zA-Z0-9_]*")]
    Identifier,

    #[regex(r"-?[0-9]+", |lex| lex.slice().parse().ok())]
    Integer(i64),

    // ...
}
```

**Output**: `Vec<Spanned<Token>>` where `Spanned<T> = (T, Range<usize>)`

### 2. Parser (`src/parser/`)

**Purpose**: Build an Abstract Syntax Tree from tokens.

**Implementation**: Hand-written recursive descent parser with Pratt parsing for expressions.

```rust
impl Parser {
    pub fn parse(&mut self) -> Result<Program> {
        let mut items = Vec::new();
        while !self.is_at_end() {
            items.push(self.parse_top_level_item()?);
        }
        Ok(Program { items })
    }

    fn parse_expression(&mut self) -> Result<Expr> {
        self.parse_or_expr()  // Lowest precedence
    }

    fn parse_or_expr(&mut self) -> Result<Expr> {
        let mut left = self.parse_and_expr()?;
        while self.match_token(Token::Or) {
            let right = self.parse_and_expr()?;
            left = Expr::Binary { left, op: BinOp::Or, right };
        }
        Ok(left)
    }
    // ... cascading precedence levels
}
```

**Output**: `Program` containing `Vec<TopLevelItem>`

### 3. AST (`src/ast/`)

**Purpose**: Define the tree structure representing parsed code.

**Key Types**:

```rust
pub struct Program {
    pub items: Vec<TopLevelItem>,
}

pub enum TopLevelItem {
    Function(Function),
    Worker(Worker),
    SideQuest(SideQuest),
    TypeDef(TypeDef),
    GratitudeBlock(GratitudeBlock),
    Pragma(Pragma),
    Import(Import),
}

pub enum Statement {
    Remember { name: String, type_ann: Option<TypeExpr>, value: Expr, unit: Option<String> },
    Assignment { target: String, value: Expr },
    Return { value: Expr },
    When { condition: Expr, then_block: Vec<Statement>, else_block: Option<Vec<Statement>> },
    Repeat { count: Expr, body: Vec<Statement> },
    // ...
}

pub enum Expr {
    Literal(Literal),
    Identifier(String),
    Binary { left: Box<Expr>, op: BinOp, right: Box<Expr> },
    Unary { op: UnaryOp, operand: Box<Expr> },
    Call { function: String, args: Vec<Expr> },
    // ...
}
```

### 4. Interpreter (`src/interpreter/`)

**Purpose**: Execute the AST directly via tree-walking.

**Key Components**:

```rust
pub struct Interpreter {
    environments: Vec<Environment>,  // Scope stack
    functions: HashMap<String, Function>,
    output: Vec<String>,
}

impl Interpreter {
    pub fn run(&mut self, program: &Program) -> Result<Value> {
        // Register functions
        for item in &program.items {
            if let TopLevelItem::Function(f) = item {
                self.functions.insert(f.name.clone(), f.clone());
            }
        }

        // Call main if it exists
        if let Some(main) = self.functions.get("main").cloned() {
            self.call_function(&main, vec![])
        } else {
            Ok(Value::Unit)
        }
    }

    fn eval_expr(&mut self, expr: &Expr) -> Result<Value> {
        match expr {
            Expr::Literal(lit) => self.eval_literal(lit),
            Expr::Binary { left, op, right } => {
                let l = self.eval_expr(left)?;
                let r = self.eval_expr(right)?;
                self.eval_binary_op(op, l, r)
            }
            // ...
        }
    }
}
```

**Runtime Values**:

```rust
pub enum Value {
    Int(i64),
    Float(f64),
    String(String),
    Bool(bool),
    Array(Vec<Value>),
    Unit,
}
```

### 5. WASM Compiler (`src/codegen/wasm.rs`)

**Purpose**: Compile WokeLang functions to WebAssembly.

**Implementation**: Uses `wasm-encoder` crate for binary generation.

```rust
pub struct WasmCompiler {
    module: wasm_encoder::Module,
    type_section: TypeSection,
    function_section: FunctionSection,
    code_section: CodeSection,
    // ...
}

impl WasmCompiler {
    pub fn compile(&mut self, program: &Program) -> Result<Vec<u8>> {
        // Collect functions
        for item in &program.items {
            if let TopLevelItem::Function(f) = item {
                self.compile_function(f)?;
            }
        }

        // Build module
        self.module.section(&self.type_section);
        self.module.section(&self.function_section);
        self.module.section(&self.code_section);

        Ok(self.module.finish())
    }
}
```

### 6. FFI (`src/ffi/c_api.rs`)

**Purpose**: Expose WokeLang to C, Zig, and other languages.

**Key Exports**:

```rust
#[no_mangle]
pub extern "C" fn woke_interpreter_new() -> *mut WokeInterpreter;

#[no_mangle]
pub unsafe extern "C" fn woke_exec(
    interp: *mut WokeInterpreter,
    source: *const c_char
) -> WokeResult;

#[no_mangle]
pub unsafe extern "C" fn woke_value_as_int(
    value: *const WokeValue,
    out: *mut c_longlong
) -> WokeResult;
```

---

## Data Flow

### Interpretation Flow

```
1. Source: "remember x = 2 + 3;"

2. Lexer Output:
   [Remember, Identifier("x"), Equals, Integer(2), Plus, Integer(3), Semicolon]

3. Parser Output:
   Statement::Remember {
       name: "x",
       value: Expr::Binary {
           left: Expr::Literal(Int(2)),
           op: BinOp::Add,
           right: Expr::Literal(Int(3))
       }
   }

4. Interpreter:
   - Evaluates Binary(2, Add, 3) → Value::Int(5)
   - Stores ("x", Value::Int(5)) in current environment
```

### WASM Compilation Flow

```
1. Source: "to add(a: Int, b: Int) → Int { give back a + b; }"

2. Parser → Function AST

3. WASM Compiler:
   - Creates function type: (i64, i64) → i64
   - Generates instructions:
     local.get 0   ; Get 'a'
     local.get 1   ; Get 'b'
     i64.add       ; Add them
     return        ; Return result

4. Output: Binary .wasm module
```

---

## Error Handling

### Error Types

```rust
#[derive(Error, Debug, Diagnostic)]
pub enum WokeError {
    #[error("Lexer error: {message}")]
    LexError { message: String, span: Range<usize> },

    #[error("Parse error: {message}")]
    ParseError { message: String, span: Range<usize> },

    #[error("Runtime error: {message}")]
    RuntimeError { message: String },

    #[error("Type error: {message}")]
    TypeError { message: String },
}
```

### Error Recovery

The parser attempts to recover from errors to report multiple issues:

```rust
fn synchronize(&mut self) {
    while !self.is_at_end() {
        if self.previous().0 == Token::Semicolon {
            return;
        }
        match self.peek().0 {
            Token::To | Token::Remember | Token::When => return,
            _ => self.advance(),
        }
    }
}
```

---

## Memory Management

- **Interpreter**: Uses Rust's ownership system; values are cloned when necessary
- **WASM**: Linear memory model with explicit allocation
- **FFI**: Box-based heap allocation with explicit free functions

---

## Threading Model

Currently single-threaded. Planned concurrency:

- **Workers**: Will use async/await or thread pools
- **Side Quests**: Background task queue
- **Superpowers**: Capability-based permission system

---

## Extension Points

1. **New Syntax**: Add tokens to lexer, parsing rules to parser
2. **New Built-ins**: Add to `Interpreter::call_builtin()`
3. **New Targets**: Implement trait for code generation
4. **New FFI**: Add `extern "C"` functions to `c_api.rs`

---

## Next Steps

- [Lexer Internals](Lexer.md)
- [Parser Internals](Parser.md)
- [Interpreter Internals](Interpreter.md)
- [WASM Compilation](WASM-Compilation.md)
