# Interpreter Internals

The interpreter executes WokeLang programs by walking the AST.

---

## Overview

WokeLang uses a **tree-walking interpreter** that directly evaluates the Abstract Syntax Tree. This approach is:

- **Simple**: Easy to understand and modify
- **Flexible**: Supports dynamic features
- **Debuggable**: Natural mapping from source to execution

---

## Core Components

### Value Types

Located in `src/interpreter/value.rs`:

```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Int(i64),
    Float(f64),
    String(String),
    Bool(bool),
    Array(Vec<Value>),
    Unit,
}

impl Value {
    pub fn type_name(&self) -> &'static str {
        match self {
            Value::Int(_) => "Int",
            Value::Float(_) => "Float",
            Value::String(_) => "String",
            Value::Bool(_) => "Bool",
            Value::Array(_) => "Array",
            Value::Unit => "Unit",
        }
    }

    pub fn is_truthy(&self) -> bool {
        match self {
            Value::Bool(b) => *b,
            Value::Int(n) => *n != 0,
            Value::String(s) => !s.is_empty(),
            Value::Array(a) => !a.is_empty(),
            Value::Unit => false,
            Value::Float(f) => *f != 0.0,
        }
    }
}

impl std::fmt::Display for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Value::Int(n) => write!(f, "{}", n),
            Value::Float(n) => write!(f, "{}", n),
            Value::String(s) => write!(f, "{}", s),
            Value::Bool(b) => write!(f, "{}", b),
            Value::Array(arr) => {
                write!(f, "[")?;
                for (i, v) in arr.iter().enumerate() {
                    if i > 0 { write!(f, ", ")?; }
                    write!(f, "{}", v)?;
                }
                write!(f, "]")
            }
            Value::Unit => write!(f, "()"),
        }
    }
}
```

### Environment (Scope)

```rust
#[derive(Debug, Clone)]
pub struct Environment {
    values: HashMap<String, Value>,
}

impl Environment {
    pub fn new() -> Self {
        Self {
            values: HashMap::new(),
        }
    }

    pub fn define(&mut self, name: String, value: Value) {
        self.values.insert(name, value);
    }

    pub fn get(&self, name: &str) -> Option<&Value> {
        self.values.get(name)
    }

    pub fn set(&mut self, name: &str, value: Value) -> bool {
        if self.values.contains_key(name) {
            self.values.insert(name.to_string(), value);
            true
        } else {
            false
        }
    }
}
```

### Interpreter State

```rust
pub struct Interpreter {
    /// Stack of environments (scopes)
    environments: Vec<Environment>,

    /// Registered functions
    functions: HashMap<String, Function>,

    /// Collected output (for testing)
    output: Vec<String>,
}

impl Interpreter {
    pub fn new() -> Self {
        Self {
            environments: vec![Environment::new()],
            functions: HashMap::new(),
            output: Vec::new(),
        }
    }
}
```

---

## Execution Flow

### Program Execution

```rust
impl Interpreter {
    pub fn run(&mut self, program: &Program) -> Result<Value> {
        // Phase 1: Register all functions
        for item in &program.items {
            match item {
                TopLevelItem::Function(f) => {
                    self.functions.insert(f.name.clone(), f.clone());
                }
                TopLevelItem::GratitudeBlock(g) => {
                    self.execute_gratitude(g)?;
                }
                TopLevelItem::Pragma(p) => {
                    self.execute_pragma(p)?;
                }
                _ => {}
            }
        }

        // Phase 2: Call main() if it exists
        if let Some(main) = self.functions.get("main").cloned() {
            self.call_function(&main, vec![])
        } else {
            // No main function - execute top-level statements
            Ok(Value::Unit)
        }
    }
}
```

### Statement Execution

```rust
impl Interpreter {
    fn execute_statement(&mut self, stmt: &Statement) -> Result<ControlFlow> {
        match stmt {
            Statement::Remember { name, value, .. } => {
                let val = self.eval_expr(value)?;
                self.current_scope_mut().define(name.clone(), val);
                Ok(ControlFlow::Continue)
            }

            Statement::Assignment { target, value } => {
                let val = self.eval_expr(value)?;
                if !self.assign(target, val.clone()) {
                    return Err(RuntimeError::UndefinedVariable(target.clone()));
                }
                Ok(ControlFlow::Continue)
            }

            Statement::Return { value } => {
                let val = self.eval_expr(value)?;
                Ok(ControlFlow::Return(val))
            }

            Statement::When { condition, then_block, else_block } => {
                let cond = self.eval_expr(condition)?;
                if cond.is_truthy() {
                    self.execute_block(then_block)
                } else if let Some(else_b) = else_block {
                    self.execute_block(else_b)
                } else {
                    Ok(ControlFlow::Continue)
                }
            }

            Statement::Repeat { count, body } => {
                let n = match self.eval_expr(count)? {
                    Value::Int(n) => n,
                    _ => return Err(RuntimeError::TypeError("repeat count must be Int".into())),
                };

                for _ in 0..n {
                    match self.execute_block(body)? {
                        ControlFlow::Return(v) => return Ok(ControlFlow::Return(v)),
                        ControlFlow::Continue => {}
                    }
                }
                Ok(ControlFlow::Continue)
            }

            Statement::Attempt { body, fallback_msg } => {
                self.push_scope();
                let result = self.execute_block(body);
                self.pop_scope();

                match result {
                    Ok(flow) => Ok(flow),
                    Err(_) => {
                        self.print(&format!("[reassure] {}", fallback_msg));
                        Ok(ControlFlow::Continue)
                    }
                }
            }

            Statement::Consent { permission, body } => {
                // For now, always grant consent (real impl would prompt)
                self.print(&format!("[consent requested: {}]", permission));
                self.execute_block(body)
            }

            Statement::Complain { message } => {
                Err(RuntimeError::Complaint(message.clone()))
            }

            Statement::ExpressionStatement { expr } => {
                self.eval_expr(expr)?;
                Ok(ControlFlow::Continue)
            }

            Statement::Hello { message } => {
                self.print(&format!("[hello] {}", message));
                Ok(ControlFlow::Continue)
            }

            Statement::Goodbye { message } => {
                self.print(&format!("[goodbye] {}", message));
                Ok(ControlFlow::Continue)
            }

            Statement::Decide { value, arms } => {
                let val = self.eval_expr(value)?;

                for arm in arms {
                    if self.pattern_matches(&arm.pattern, &val) {
                        return self.execute_block(&arm.body);
                    }
                }

                Ok(ControlFlow::Continue)
            }
        }
    }
}
```

---

## Expression Evaluation

```rust
impl Interpreter {
    fn eval_expr(&mut self, expr: &Expr) -> Result<Value> {
        match expr {
            Expr::Literal(lit) => self.eval_literal(lit),

            Expr::Identifier(name) => {
                self.lookup(name)
                    .ok_or_else(|| RuntimeError::UndefinedVariable(name.clone()))
            }

            Expr::Binary { left, op, right } => {
                let l = self.eval_expr(left)?;
                let r = self.eval_expr(right)?;
                self.eval_binary_op(op, l, r)
            }

            Expr::Unary { op, operand } => {
                let val = self.eval_expr(operand)?;
                self.eval_unary_op(op, val)
            }

            Expr::Call { function, args } => {
                let evaluated_args: Vec<Value> = args
                    .iter()
                    .map(|a| self.eval_expr(a))
                    .collect::<Result<_>>()?;

                self.call(function, evaluated_args)
            }

            Expr::Array(elements) => {
                let values: Vec<Value> = elements
                    .iter()
                    .map(|e| self.eval_expr(e))
                    .collect::<Result<_>>()?;
                Ok(Value::Array(values))
            }

            Expr::Index { array, index } => {
                let arr = self.eval_expr(array)?;
                let idx = self.eval_expr(index)?;
                self.eval_index(arr, idx)
            }

            Expr::FieldAccess { object, field } => {
                let obj = self.eval_expr(object)?;
                self.eval_field_access(obj, field)
            }

            Expr::Gratitude(msg) => {
                self.print(&format!("[thanks] {}", msg));
                Ok(Value::Unit)
            }
        }
    }
}
```

### Binary Operations

```rust
impl Interpreter {
    fn eval_binary_op(&self, op: &BinOp, left: Value, right: Value) -> Result<Value> {
        match op {
            // Arithmetic
            BinOp::Add => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a + b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a + b)),
                (Value::Int(a), Value::Float(b)) => Ok(Value::Float(a as f64 + b)),
                (Value::Float(a), Value::Int(b)) => Ok(Value::Float(a + b as f64)),
                (Value::String(a), Value::String(b)) => Ok(Value::String(a + &b)),
                _ => Err(RuntimeError::TypeError("Invalid operands for +".into())),
            },

            BinOp::Sub => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a - b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a - b)),
                _ => Err(RuntimeError::TypeError("Invalid operands for -".into())),
            },

            BinOp::Mul => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Int(a * b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a * b)),
                _ => Err(RuntimeError::TypeError("Invalid operands for *".into())),
            },

            BinOp::Div => match (left, right) {
                (Value::Int(a), Value::Int(b)) => {
                    if b == 0 {
                        Err(RuntimeError::DivisionByZero)
                    } else {
                        Ok(Value::Int(a / b))
                    }
                }
                (Value::Float(a), Value::Float(b)) => Ok(Value::Float(a / b)),
                _ => Err(RuntimeError::TypeError("Invalid operands for /".into())),
            },

            BinOp::Mod => match (left, right) {
                (Value::Int(a), Value::Int(b)) => {
                    if b == 0 {
                        Err(RuntimeError::DivisionByZero)
                    } else {
                        Ok(Value::Int(a % b))
                    }
                }
                _ => Err(RuntimeError::TypeError("Invalid operands for %".into())),
            },

            // Comparison
            BinOp::Eq => Ok(Value::Bool(left == right)),
            BinOp::Ne => Ok(Value::Bool(left != right)),

            BinOp::Lt => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a < b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a < b)),
                (Value::String(a), Value::String(b)) => Ok(Value::Bool(a < b)),
                _ => Err(RuntimeError::TypeError("Invalid operands for <".into())),
            },

            BinOp::Gt => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a > b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a > b)),
                (Value::String(a), Value::String(b)) => Ok(Value::Bool(a > b)),
                _ => Err(RuntimeError::TypeError("Invalid operands for >".into())),
            },

            BinOp::Le => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a <= b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a <= b)),
                _ => Err(RuntimeError::TypeError("Invalid operands for <=".into())),
            },

            BinOp::Ge => match (left, right) {
                (Value::Int(a), Value::Int(b)) => Ok(Value::Bool(a >= b)),
                (Value::Float(a), Value::Float(b)) => Ok(Value::Bool(a >= b)),
                _ => Err(RuntimeError::TypeError("Invalid operands for >=".into())),
            },

            // Logical
            BinOp::And => Ok(Value::Bool(left.is_truthy() && right.is_truthy())),
            BinOp::Or => Ok(Value::Bool(left.is_truthy() || right.is_truthy())),
        }
    }
}
```

---

## Function Calls

```rust
impl Interpreter {
    fn call(&mut self, name: &str, args: Vec<Value>) -> Result<Value> {
        // Check for built-in functions first
        if let Some(result) = self.call_builtin(name, &args)? {
            return Ok(result);
        }

        // Look up user-defined function
        let func = self.functions
            .get(name)
            .cloned()
            .ok_or_else(|| RuntimeError::UndefinedFunction(name.to_string()))?;

        self.call_function(&func, args)
    }

    fn call_function(&mut self, func: &Function, args: Vec<Value>) -> Result<Value> {
        // Validate argument count
        if args.len() != func.params.len() {
            return Err(RuntimeError::ArgumentCount {
                expected: func.params.len(),
                got: args.len(),
            });
        }

        // Create new scope
        self.push_scope();

        // Bind parameters
        for (param, value) in func.params.iter().zip(args) {
            self.current_scope_mut().define(param.name.clone(), value);
        }

        // Execute hello message
        if let Some(msg) = &func.hello {
            self.print(&format!("[hello] {}", msg));
        }

        // Execute body
        let result = self.execute_block(&func.body);

        // Execute goodbye message
        if let Some(msg) = &func.goodbye {
            self.print(&format!("[goodbye] {}", msg));
        }

        // Pop scope
        self.pop_scope();

        // Handle result
        match result? {
            ControlFlow::Return(value) => Ok(value),
            ControlFlow::Continue => Ok(Value::Unit),
        }
    }
}
```

---

## Built-in Functions

```rust
impl Interpreter {
    fn call_builtin(&mut self, name: &str, args: &[Value]) -> Result<Option<Value>> {
        match name {
            "print" => {
                let output: Vec<String> = args.iter().map(|v| v.to_string()).collect();
                self.print(&output.join(" "));
                Ok(Some(Value::Unit))
            }

            "len" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArgumentCount { expected: 1, got: args.len() });
                }
                match &args[0] {
                    Value::String(s) => Ok(Some(Value::Int(s.len() as i64))),
                    Value::Array(a) => Ok(Some(Value::Int(a.len() as i64))),
                    _ => Err(RuntimeError::TypeError("len() requires String or Array".into())),
                }
            }

            "toString" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArgumentCount { expected: 1, got: args.len() });
                }
                Ok(Some(Value::String(args[0].to_string())))
            }

            "toInt" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArgumentCount { expected: 1, got: args.len() });
                }
                match &args[0] {
                    Value::String(s) => {
                        s.parse::<i64>()
                            .map(|n| Some(Value::Int(n)))
                            .map_err(|_| RuntimeError::TypeError("Cannot parse as Int".into()))
                    }
                    Value::Float(f) => Ok(Some(Value::Int(*f as i64))),
                    Value::Int(n) => Ok(Some(Value::Int(*n))),
                    _ => Err(RuntimeError::TypeError("toInt() requires String, Float, or Int".into())),
                }
            }

            "toFloat" => {
                if args.len() != 1 {
                    return Err(RuntimeError::ArgumentCount { expected: 1, got: args.len() });
                }
                match &args[0] {
                    Value::String(s) => {
                        s.parse::<f64>()
                            .map(|f| Some(Value::Float(f)))
                            .map_err(|_| RuntimeError::TypeError("Cannot parse as Float".into()))
                    }
                    Value::Int(n) => Ok(Some(Value::Float(*n as f64))),
                    Value::Float(f) => Ok(Some(Value::Float(*f))),
                    _ => Err(RuntimeError::TypeError("toFloat() requires String, Int, or Float".into())),
                }
            }

            _ => Ok(None), // Not a built-in
        }
    }
}
```

---

## Scope Management

```rust
impl Interpreter {
    fn push_scope(&mut self) {
        self.environments.push(Environment::new());
    }

    fn pop_scope(&mut self) {
        if self.environments.len() > 1 {
            self.environments.pop();
        }
    }

    fn current_scope_mut(&mut self) -> &mut Environment {
        self.environments.last_mut().unwrap()
    }

    fn lookup(&self, name: &str) -> Option<Value> {
        // Search from innermost to outermost scope
        for env in self.environments.iter().rev() {
            if let Some(value) = env.get(name) {
                return Some(value.clone());
            }
        }
        None
    }

    fn assign(&mut self, name: &str, value: Value) -> bool {
        // Search from innermost to outermost scope
        for env in self.environments.iter_mut().rev() {
            if env.set(name, value.clone()) {
                return true;
            }
        }
        false
    }
}
```

---

## Control Flow

```rust
pub enum ControlFlow {
    Continue,
    Return(Value),
}

impl Interpreter {
    fn execute_block(&mut self, statements: &[Statement]) -> Result<ControlFlow> {
        for stmt in statements {
            match self.execute_statement(stmt)? {
                ControlFlow::Return(v) => return Ok(ControlFlow::Return(v)),
                ControlFlow::Continue => {}
            }
        }
        Ok(ControlFlow::Continue)
    }
}
```

---

## Error Handling

```rust
#[derive(Debug)]
pub enum RuntimeError {
    UndefinedVariable(String),
    UndefinedFunction(String),
    TypeError(String),
    DivisionByZero,
    IndexOutOfBounds { index: i64, len: usize },
    ArgumentCount { expected: usize, got: usize },
    Complaint(String),
}

impl std::fmt::Display for RuntimeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::UndefinedVariable(name) => write!(f, "Undefined variable: {}", name),
            Self::UndefinedFunction(name) => write!(f, "Undefined function: {}", name),
            Self::TypeError(msg) => write!(f, "Type error: {}", msg),
            Self::DivisionByZero => write!(f, "Division by zero"),
            Self::IndexOutOfBounds { index, len } => {
                write!(f, "Index {} out of bounds for array of length {}", index, len)
            }
            Self::ArgumentCount { expected, got } => {
                write!(f, "Expected {} arguments, got {}", expected, got)
            }
            Self::Complaint(msg) => write!(f, "Complaint: {}", msg),
        }
    }
}
```

---

## Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    fn run(source: &str) -> Result<Value> {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();
        let mut interpreter = Interpreter::new();
        interpreter.run(&program)
    }

    #[test]
    fn test_arithmetic() {
        let mut interp = Interpreter::new();

        // Test basic operations
        assert_eq!(run("to main() { give back 2 + 3; }").unwrap(), Value::Int(5));
        assert_eq!(run("to main() { give back 10 - 4; }").unwrap(), Value::Int(6));
        assert_eq!(run("to main() { give back 6 * 7; }").unwrap(), Value::Int(42));
        assert_eq!(run("to main() { give back 20 / 4; }").unwrap(), Value::Int(5));
    }

    #[test]
    fn test_variables() {
        let result = run(r#"
            to main() {
                remember x = 10;
                remember y = 20;
                give back x + y;
            }
        "#);
        assert_eq!(result.unwrap(), Value::Int(30));
    }

    #[test]
    fn test_function_call() {
        let result = run(r#"
            to add(a: Int, b: Int) -> Int {
                give back a + b;
            }
            to main() {
                give back add(3, 4);
            }
        "#);
        assert_eq!(result.unwrap(), Value::Int(7));
    }

    #[test]
    fn test_recursion() {
        let result = run(r#"
            to factorial(n: Int) -> Int {
                when n <= 1 {
                    give back 1;
                } otherwise {
                    give back n * factorial(n - 1);
                }
            }
            to main() {
                give back factorial(5);
            }
        "#);
        assert_eq!(result.unwrap(), Value::Int(120));
    }
}
```

---

## Performance Considerations

- **Value cloning**: Values are cloned when passed; future work may add reference counting
- **HashMap lookups**: Function and variable lookups are O(1) average
- **Recursion**: Uses Rust's call stack; deep recursion may overflow

---

## Future Enhancements

- **Tail call optimization**
- **Bytecode compilation** for faster execution
- **JIT compilation** for hot paths
- **Garbage collection** for long-running programs

---

## Next Steps

- [WASM Compilation](WASM-Compilation.md)
- [FFI Internals](FFI.md)
- [Value Types Reference](../Reference/Types.md)
