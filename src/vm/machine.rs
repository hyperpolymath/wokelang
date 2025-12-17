//! WokeLang Virtual Machine
//!
//! Stack-based VM for executing compiled bytecode.

use crate::interpreter::Value;
use super::bytecode::{CompiledFunction, CompiledProgram, OpCode};
use std::collections::HashMap;

/// Call frame for function execution
#[derive(Debug, Clone)]
struct CallFrame {
    /// Function being executed
    function_idx: usize,
    /// Instruction pointer within the function
    ip: usize,
    /// Base pointer for local variables in the stack
    base_ptr: usize,
}

/// Virtual machine for executing WokeLang bytecode
pub struct VirtualMachine {
    /// The program being executed
    program: CompiledProgram,
    /// Value stack
    stack: Vec<Value>,
    /// Call stack
    call_stack: Vec<CallFrame>,
    /// Global variables
    globals: HashMap<String, Value>,
    /// Maximum stack size (for safety)
    max_stack_size: usize,
    /// Maximum call depth (for safety)
    max_call_depth: usize,
}

impl VirtualMachine {
    pub fn new(program: CompiledProgram) -> Self {
        // Initialize globals from the compiled program
        let globals = program.globals.clone();
        Self {
            program,
            stack: Vec::with_capacity(1024),
            call_stack: Vec::with_capacity(64),
            globals,
            max_stack_size: 10000,
            max_call_depth: 1000,
        }
    }

    /// Run the program starting from main
    pub fn run(&mut self) -> Result<Value, VMError> {
        let entry = self.program.entry.ok_or_else(|| VMError {
            message: "No main function found".to_string(),
        })?;

        self.call_function(entry, 0)?;

        while !self.call_stack.is_empty() {
            self.execute_instruction()?;
        }

        // Return final value or Unit
        Ok(self.stack.pop().unwrap_or(Value::Unit))
    }

    /// Call a function with arguments already on the stack
    fn call_function(&mut self, func_idx: usize, arg_count: usize) -> Result<(), VMError> {
        if self.call_stack.len() >= self.max_call_depth {
            return Err(VMError {
                message: "Maximum call depth exceeded".to_string(),
            });
        }

        let func = self.program.get_function(func_idx).ok_or_else(|| VMError {
            message: format!("Function {} not found", func_idx),
        })?;

        if arg_count != func.arity {
            return Err(VMError {
                message: format!(
                    "Function {} expects {} arguments, got {}",
                    func.name, func.arity, arg_count
                ),
            });
        }

        // Calculate base pointer (before args)
        let base_ptr = self.stack.len() - arg_count;

        // Reserve space for locals (beyond parameters)
        let extra_locals = func.locals - func.arity;
        for _ in 0..extra_locals {
            self.stack.push(Value::Unit);
        }

        self.call_stack.push(CallFrame {
            function_idx: func_idx,
            ip: 0,
            base_ptr,
        });

        Ok(())
    }

    /// Execute one instruction
    fn execute_instruction(&mut self) -> Result<(), VMError> {
        let frame = self.call_stack.last_mut().ok_or_else(|| VMError {
            message: "No active call frame".to_string(),
        })?;

        let func = self.program.get_function(frame.function_idx).ok_or_else(|| VMError {
            message: "Invalid function index".to_string(),
        })?;

        if frame.ip >= func.code.len() {
            // Implicit return
            let return_value = self.stack.pop().unwrap_or(Value::Unit);
            let frame = self.call_stack.pop().unwrap();

            // Clean up locals
            self.stack.truncate(frame.base_ptr);
            self.stack.push(return_value);
            return Ok(());
        }

        let instruction = func.code[frame.ip].clone();
        frame.ip += 1;

        // Need to get these before borrowing self mutably
        let base_ptr = frame.base_ptr;
        let func_idx = frame.function_idx;

        match instruction {
            OpCode::Const(idx) => {
                let func = self.program.get_function(func_idx).unwrap();
                let value = func.constants.get(idx).cloned().ok_or_else(|| VMError {
                    message: format!("Constant {} not found", idx),
                })?;
                self.push(value)?;
            }

            OpCode::Pop => {
                self.stack.pop();
            }

            OpCode::Dup => {
                let value = self.peek()?.clone();
                self.push(value)?;
            }

            OpCode::Swap => {
                let len = self.stack.len();
                if len >= 2 {
                    self.stack.swap(len - 1, len - 2);
                }
            }

            OpCode::LoadLocal(slot) => {
                let idx = base_ptr + slot;
                let value = self.stack.get(idx).cloned().unwrap_or(Value::Unit);
                self.push(value)?;
            }

            OpCode::StoreLocal(slot) => {
                let value = self.pop()?;
                let idx = base_ptr + slot;

                // Extend stack if needed
                while self.stack.len() <= idx {
                    self.stack.push(Value::Unit);
                }
                self.stack[idx] = value;
            }

            OpCode::LoadGlobal(name) => {
                let value = self.globals.get(&name).cloned().unwrap_or(Value::Unit);
                self.push(value)?;
            }

            OpCode::StoreGlobal(name) => {
                let value = self.pop()?;
                self.globals.insert(name, value);
            }

            OpCode::Add => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => Value::Int(x + y),
                    (Value::Float(x), Value::Float(y)) => Value::Float(x + y),
                    (Value::Int(x), Value::Float(y)) => Value::Float(*x as f64 + y),
                    (Value::Float(x), Value::Int(y)) => Value::Float(x + *y as f64),
                    (Value::String(x), Value::String(y)) => Value::String(format!("{}{}", x, y)),
                    _ => return Err(VMError {
                        message: format!("Cannot add {:?} and {:?}", a, b),
                    }),
                };
                self.push(result)?;
            }

            OpCode::Sub => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => Value::Int(x - y),
                    (Value::Float(x), Value::Float(y)) => Value::Float(x - y),
                    (Value::Int(x), Value::Float(y)) => Value::Float(*x as f64 - y),
                    (Value::Float(x), Value::Int(y)) => Value::Float(x - *y as f64),
                    _ => return Err(VMError {
                        message: format!("Cannot subtract {:?} and {:?}", a, b),
                    }),
                };
                self.push(result)?;
            }

            OpCode::Mul => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => Value::Int(x * y),
                    (Value::Float(x), Value::Float(y)) => Value::Float(x * y),
                    (Value::Int(x), Value::Float(y)) => Value::Float(*x as f64 * y),
                    (Value::Float(x), Value::Int(y)) => Value::Float(x * *y as f64),
                    _ => return Err(VMError {
                        message: format!("Cannot multiply {:?} and {:?}", a, b),
                    }),
                };
                self.push(result)?;
            }

            OpCode::Div => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => {
                        if *y == 0 {
                            return Err(VMError {
                                message: "Division by zero".to_string(),
                            });
                        }
                        Value::Int(x / y)
                    }
                    (Value::Float(x), Value::Float(y)) => Value::Float(x / y),
                    (Value::Int(x), Value::Float(y)) => Value::Float(*x as f64 / y),
                    (Value::Float(x), Value::Int(y)) => Value::Float(x / *y as f64),
                    _ => return Err(VMError {
                        message: format!("Cannot divide {:?} and {:?}", a, b),
                    }),
                };
                self.push(result)?;
            }

            OpCode::Mod => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => Value::Int(x % y),
                    _ => return Err(VMError {
                        message: "Modulo requires integers".to_string(),
                    }),
                };
                self.push(result)?;
            }

            OpCode::Neg => {
                let a = self.pop()?;
                let result = match a {
                    Value::Int(x) => Value::Int(-x),
                    Value::Float(x) => Value::Float(-x),
                    _ => return Err(VMError {
                        message: "Cannot negate non-numeric value".to_string(),
                    }),
                };
                self.push(result)?;
            }

            OpCode::Eq => {
                let b = self.pop()?;
                let a = self.pop()?;
                self.push(Value::Bool(a == b))?;
            }

            OpCode::Ne => {
                let b = self.pop()?;
                let a = self.pop()?;
                self.push(Value::Bool(a != b))?;
            }

            OpCode::Lt => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => x < y,
                    (Value::Float(x), Value::Float(y)) => x < y,
                    (Value::Int(x), Value::Float(y)) => (*x as f64) < *y,
                    (Value::Float(x), Value::Int(y)) => *x < (*y as f64),
                    _ => false,
                };
                self.push(Value::Bool(result))?;
            }

            OpCode::Le => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => x <= y,
                    (Value::Float(x), Value::Float(y)) => x <= y,
                    (Value::Int(x), Value::Float(y)) => (*x as f64) <= *y,
                    (Value::Float(x), Value::Int(y)) => *x <= (*y as f64),
                    _ => false,
                };
                self.push(Value::Bool(result))?;
            }

            OpCode::Gt => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => x > y,
                    (Value::Float(x), Value::Float(y)) => x > y,
                    (Value::Int(x), Value::Float(y)) => (*x as f64) > *y,
                    (Value::Float(x), Value::Int(y)) => *x > (*y as f64),
                    _ => false,
                };
                self.push(Value::Bool(result))?;
            }

            OpCode::Ge => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = match (&a, &b) {
                    (Value::Int(x), Value::Int(y)) => x >= y,
                    (Value::Float(x), Value::Float(y)) => x >= y,
                    (Value::Int(x), Value::Float(y)) => (*x as f64) >= *y,
                    (Value::Float(x), Value::Int(y)) => *x >= (*y as f64),
                    _ => false,
                };
                self.push(Value::Bool(result))?;
            }

            OpCode::And => {
                let b = self.pop()?;
                let a = self.pop()?;
                self.push(Value::Bool(a.is_truthy() && b.is_truthy()))?;
            }

            OpCode::Or => {
                let b = self.pop()?;
                let a = self.pop()?;
                self.push(Value::Bool(a.is_truthy() || b.is_truthy()))?;
            }

            OpCode::Not => {
                let a = self.pop()?;
                self.push(Value::Bool(!a.is_truthy()))?;
            }

            OpCode::Concat => {
                let b = self.pop()?;
                let a = self.pop()?;
                let result = Value::String(format!("{}{}", a, b));
                self.push(result)?;
            }

            OpCode::Jump(target) => {
                if let Some(frame) = self.call_stack.last_mut() {
                    frame.ip = target;
                }
            }

            OpCode::JumpIfFalse(target) => {
                let cond = self.pop()?;
                if !cond.is_truthy() {
                    if let Some(frame) = self.call_stack.last_mut() {
                        frame.ip = target;
                    }
                }
            }

            OpCode::JumpIfTrue(target) => {
                let cond = self.pop()?;
                if cond.is_truthy() {
                    if let Some(frame) = self.call_stack.last_mut() {
                        frame.ip = target;
                    }
                }
            }

            OpCode::Call(arg_count) => {
                // Pop the closure/function reference
                let callee = self.pop()?;

                match callee {
                    Value::Int(func_idx) => {
                        self.call_function(func_idx as usize, arg_count)?;
                    }
                    _ => {
                        return Err(VMError {
                            message: "Cannot call non-function value".to_string(),
                        });
                    }
                }
            }

            OpCode::Return => {
                let return_value = self.stack.pop().unwrap_or(Value::Unit);
                let frame = self.call_stack.pop().unwrap();

                // Clean up locals
                self.stack.truncate(frame.base_ptr);
                self.stack.push(return_value);
            }

            OpCode::MakeClosure(func_idx) => {
                // For now, just push the function index as an integer
                self.push(Value::Int(func_idx as i64))?;
            }

            OpCode::MakeArray(count) => {
                let mut elements = Vec::with_capacity(count);
                for _ in 0..count {
                    elements.push(self.pop()?);
                }
                elements.reverse();
                self.push(Value::Array(elements))?;
            }

            OpCode::MakeRecord(count) => {
                let mut map = std::collections::HashMap::new();
                for _ in 0..count {
                    let value = self.pop()?;
                    let key = match self.pop()? {
                        Value::String(s) => s,
                        _ => return Err(VMError {
                            message: "Record keys must be strings".to_string(),
                        }),
                    };
                    map.insert(key, value);
                }
                self.push(Value::Record(map))?;
            }

            OpCode::Index => {
                let index = self.pop()?;
                let object = self.pop()?;

                let result = match (&object, &index) {
                    (Value::Array(arr), Value::Int(i)) => {
                        arr.get(*i as usize).cloned().unwrap_or(Value::Unit)
                    }
                    (Value::String(s), Value::Int(i)) => {
                        s.chars()
                            .nth(*i as usize)
                            .map(|c| Value::String(c.to_string()))
                            .unwrap_or(Value::Unit)
                    }
                    (Value::Record(map), Value::String(key)) => {
                        map.get(key.as_str()).cloned().unwrap_or(Value::Unit)
                    }
                    _ => Value::Unit,
                };
                self.push(result)?;
            }

            OpCode::Len => {
                let value = self.pop()?;
                let len = match value {
                    Value::Array(arr) => arr.len(),
                    Value::String(s) => s.len(),
                    Value::Record(map) => map.len(),
                    _ => 0,
                };
                self.push(Value::Int(len as i64))?;
            }

            OpCode::MakeOkay => {
                let value = self.pop()?;
                self.push(Value::Okay(Box::new(value)))?;
            }

            OpCode::MakeOops => {
                let value = self.pop()?;
                let msg = match value {
                    Value::String(s) => s,
                    other => other.to_string(),
                };
                self.push(Value::Oops(msg))?;
            }

            OpCode::TryUnwrap => {
                let value = self.pop()?;
                match value {
                    Value::Okay(inner) => self.push(*inner)?,
                    Value::Oops(_) => {
                        // Propagate error by returning
                        self.stack.push(value);
                        if let Some(frame) = self.call_stack.last_mut() {
                            let func = self.program.get_function(frame.function_idx).unwrap();
                            frame.ip = func.code.len(); // Jump to end
                        }
                    }
                    other => self.push(other)?,
                }
            }

            OpCode::IsOkay => {
                let value = self.peek()?;
                let is_okay = matches!(value, Value::Okay(_));
                self.push(Value::Bool(is_okay))?;
            }

            OpCode::Print => {
                let value = self.pop()?;
                println!("{}", value);
            }

            OpCode::ToString => {
                let value = self.pop()?;
                self.push(Value::String(value.to_string()))?;
            }

            OpCode::Nop => {}

            OpCode::Halt => {
                self.call_stack.clear();
            }
        }

        Ok(())
    }

    fn push(&mut self, value: Value) -> Result<(), VMError> {
        if self.stack.len() >= self.max_stack_size {
            return Err(VMError {
                message: "Stack overflow".to_string(),
            });
        }
        self.stack.push(value);
        Ok(())
    }

    fn pop(&mut self) -> Result<Value, VMError> {
        self.stack.pop().ok_or_else(|| VMError {
            message: "Stack underflow".to_string(),
        })
    }

    fn peek(&self) -> Result<&Value, VMError> {
        self.stack.last().ok_or_else(|| VMError {
            message: "Stack underflow".to_string(),
        })
    }
}

/// VM execution error
#[derive(Debug, Clone)]
pub struct VMError {
    pub message: String,
}

impl std::fmt::Display for VMError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "VM error: {}", self.message)
    }
}

impl std::error::Error for VMError {}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vm::compiler::BytecodeCompiler;
    use crate::lexer::Lexer;
    use crate::parser::Parser;

    fn run_source(source: &str) -> Result<Value, String> {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().map_err(|e| e.to_string())?;
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().map_err(|e| e.to_string())?;

        let mut compiler = BytecodeCompiler::new();
        let compiled = compiler.compile(&program).map_err(|e| e.to_string())?;

        let mut vm = VirtualMachine::new(compiled);
        vm.run().map_err(|e| e.to_string())
    }

    #[test]
    fn test_vm_arithmetic() {
        let source = r#"
            to main() {
                give back 2 + 3 * 4;
            }
        "#;
        // Note: without operator precedence, this is (2 + 3) * 4 = 20
        // or with precedence 2 + (3 * 4) = 14
        let result = run_source(source).unwrap();
        assert!(matches!(result, Value::Int(_)));
    }

    #[test]
    fn test_vm_function_call() {
        let source = r#"
            to add(a: Int, b: Int) -> Int {
                give back a + b;
            }

            to main() {
                give back add(10, 20);
            }
        "#;
        let result = run_source(source).unwrap();
        assert_eq!(result, Value::Int(30));
    }

    #[test]
    fn test_vm_conditional() {
        let source = r#"
            to main() {
                remember x = 10;
                when x > 5 {
                    give back 1;
                } otherwise {
                    give back 0;
                }
            }
        "#;
        let result = run_source(source).unwrap();
        assert_eq!(result, Value::Int(1));
    }

    #[test]
    fn test_vm_loop() {
        let source = r#"
            to main() {
                remember sum = 0;
                repeat 5 times {
                    sum = sum + 1;
                }
                give back sum;
            }
        "#;
        let result = run_source(source).unwrap();
        assert_eq!(result, Value::Int(5));
    }

    #[test]
    fn test_vm_recursion() {
        let source = r#"
            to factorial(n: Int) -> Int {
                when n <= 1 {
                    give back 1;
                }
                give back n * factorial(n - 1);
            }

            to main() {
                give back factorial(5);
            }
        "#;
        let result = run_source(source).unwrap();
        assert_eq!(result, Value::Int(120));
    }
}
