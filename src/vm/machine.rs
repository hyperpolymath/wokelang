// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Virtual Machine
//!
//! Stack-based bytecode interpreter for executing compiled WokeLang programs.

use crate::interpreter::Value;
use crate::vm::bytecode::{CompiledProgram, OpCode};
use std::collections::{HashMap, HashSet};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum VMError {
    #[error("Stack underflow")]
    StackUnderflow,

    #[error("Invalid function index: {0}")]
    InvalidFunctionIndex(usize),

    #[error("Invalid local variable index: {0}")]
    InvalidLocalIndex(usize),

    #[error("Undefined global variable: {0}")]
    UndefinedGlobal(String),

    #[error("Type error: {0}")]
    TypeError(String),

    #[error("Division by zero")]
    DivisionByZero,

    #[error("Index out of bounds: {0}")]
    IndexOutOfBounds(i64),

    #[error("No entry point (main function)")]
    NoEntryPoint,

    #[error("Invalid instruction pointer")]
    InvalidIP,

    #[error("Runtime error: {0}")]
    Runtime(String),
}

/// Call frame for function calls
#[derive(Debug, Clone)]
struct CallFrame {
    /// Function being executed
    function_idx: usize,
    /// Instruction pointer
    ip: usize,
    /// Base pointer for locals (points into value stack)
    bp: usize,
}

/// The virtual machine
pub struct VirtualMachine {
    /// The compiled program
    program: CompiledProgram,
    /// Value stack
    stack: Vec<Value>,
    /// Call frames
    frames: Vec<CallFrame>,
    /// Global variables
    globals: HashMap<String, Value>,
    /// Permissions granted for this run; seeds `CheckConsent`. Empty by default,
    /// so under `#care` consent is denied unless a permission was granted.
    granted: HashSet<String>,
}

impl VirtualMachine {
    /// Create a new VM with a compiled program
    pub fn new(program: CompiledProgram) -> Self {
        Self {
            program,
            stack: Vec::new(),
            frames: Vec::new(),
            globals: HashMap::new(),
            granted: HashSet::new(),
        }
    }

    /// Run the program
    pub fn run(&mut self) -> Result<Value, VMError> {
        // Get entry point
        let entry_idx = self.program.entry.ok_or(VMError::NoEntryPoint)?;

        // Create initial call frame
        self.frames.push(CallFrame {
            function_idx: entry_idx,
            ip: 0,
            bp: 0,
        });

        // Execute
        self.execute()
    }

    /// Execute bytecode
    fn execute(&mut self) -> Result<Value, VMError> {
        loop {
            // Get current frame
            let frame = self.frames.last_mut().ok_or(VMError::InvalidIP)?;
            let func_idx = frame.function_idx;
            let func = self
                .program
                .get_function(func_idx)
                .ok_or(VMError::InvalidFunctionIndex(func_idx))?;

            // Check if we're at end of function
            if frame.ip >= func.code.len() {
                return Err(VMError::InvalidIP);
            }

            // Fetch and decode instruction
            let opcode = func.code[frame.ip].clone();
            frame.ip += 1;

            // Execute instruction
            match opcode {
                OpCode::Const(idx) => {
                    let value = func.constants.get(idx).ok_or(VMError::InvalidIP)?.clone();
                    self.push(value);
                }

                OpCode::Pop => {
                    self.pop()?;
                }

                OpCode::Dup => {
                    let value = self.peek(0)?;
                    self.push(value);
                }

                OpCode::Swap => {
                    let a = self.pop()?;
                    let b = self.pop()?;
                    self.push(a);
                    self.push(b);
                }

                OpCode::LoadLocal(idx) => {
                    let frame = self.frames.last().ok_or(VMError::StackUnderflow)?;
                    let local_idx = frame.bp + idx;
                    let value = self
                        .stack
                        .get(local_idx)
                        .ok_or(VMError::InvalidLocalIndex(idx))?
                        .clone();
                    self.push(value);
                }

                OpCode::StoreLocal(idx) => {
                    let value = self.pop()?;
                    let frame = self.frames.last().ok_or(VMError::StackUnderflow)?;
                    let local_idx = frame.bp + idx;

                    // Extend stack if needed
                    while self.stack.len() <= local_idx {
                        self.stack.push(Value::Unit);
                    }
                    self.stack[local_idx] = value;
                }

                OpCode::LoadGlobal(name) => {
                    let value = self
                        .globals
                        .get(&name)
                        .ok_or(VMError::UndefinedGlobal(name.clone()))?
                        .clone();
                    self.push(value);
                }

                OpCode::StoreGlobal(name) => {
                    let value = self.pop()?;
                    self.globals.insert(name, value);
                }

                OpCode::Add => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Int(x + y)),
                    (Value::Float(x), Value::Float(y)) => Ok(Value::Float(x + y)),
                    (Value::String(x), Value::String(y)) => {
                        Ok(Value::String(format!("{}{}", x, y)))
                    }
                    _ => Err(VMError::TypeError("Invalid operands for +".to_string())),
                })?,

                OpCode::Sub => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Int(x - y)),
                    (Value::Float(x), Value::Float(y)) => Ok(Value::Float(x - y)),
                    _ => Err(VMError::TypeError("Invalid operands for -".to_string())),
                })?,

                OpCode::Mul => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Int(x * y)),
                    (Value::Float(x), Value::Float(y)) => Ok(Value::Float(x * y)),
                    _ => Err(VMError::TypeError("Invalid operands for *".to_string())),
                })?,

                OpCode::Div => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(_), Value::Int(0)) => Err(VMError::DivisionByZero),
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Int(x / y)),
                    (Value::Float(x), Value::Float(y)) => Ok(Value::Float(x / y)),
                    _ => Err(VMError::TypeError("Invalid operands for /".to_string())),
                })?,

                OpCode::Mod => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Int(x % y)),
                    _ => Err(VMError::TypeError("Invalid operands for %".to_string())),
                })?,

                OpCode::Neg => {
                    let value = self.pop()?;
                    match value {
                        Value::Int(n) => self.push(Value::Int(-n)),
                        Value::Float(f) => self.push(Value::Float(-f)),
                        _ => {
                            return Err(VMError::TypeError(
                                "Cannot negate non-numeric value".to_string(),
                            ))
                        }
                    }
                }

                OpCode::Eq => self.comparison_op(|a, b| a == b)?,
                OpCode::Ne => self.comparison_op(|a, b| a != b)?,

                OpCode::Lt => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Bool(x < y)),
                    (Value::Float(x), Value::Float(y)) => Ok(Value::Bool(x < y)),
                    _ => Err(VMError::TypeError("Invalid operands for <".to_string())),
                })?,

                OpCode::Le => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Bool(x <= y)),
                    (Value::Float(x), Value::Float(y)) => Ok(Value::Bool(x <= y)),
                    _ => Err(VMError::TypeError("Invalid operands for <=".to_string())),
                })?,

                OpCode::Gt => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Bool(x > y)),
                    (Value::Float(x), Value::Float(y)) => Ok(Value::Bool(x > y)),
                    _ => Err(VMError::TypeError("Invalid operands for >".to_string())),
                })?,

                OpCode::Ge => self.binary_op(|a, b| match (a, b) {
                    (Value::Int(x), Value::Int(y)) => Ok(Value::Bool(x >= y)),
                    (Value::Float(x), Value::Float(y)) => Ok(Value::Bool(x >= y)),
                    _ => Err(VMError::TypeError("Invalid operands for >=".to_string())),
                })?,

                OpCode::And => self.binary_op(|a, b| match (a, b) {
                    (Value::Bool(x), Value::Bool(y)) => Ok(Value::Bool(x && y)),
                    _ => Err(VMError::TypeError("Invalid operands for and".to_string())),
                })?,

                OpCode::Or => self.binary_op(|a, b| match (a, b) {
                    (Value::Bool(x), Value::Bool(y)) => Ok(Value::Bool(x || y)),
                    _ => Err(VMError::TypeError("Invalid operands for or".to_string())),
                })?,

                OpCode::Not => {
                    let value = self.pop()?;
                    match value {
                        Value::Bool(b) => self.push(Value::Bool(!b)),
                        _ => {
                            return Err(VMError::TypeError(
                                "Cannot negate non-boolean value".to_string(),
                            ))
                        }
                    }
                }

                OpCode::Jump(target) => {
                    let frame = self.frames.last_mut().ok_or(VMError::InvalidIP)?;
                    frame.ip = target;
                }

                OpCode::JumpIfFalse(target) => {
                    let condition = self.pop()?;
                    if !self.is_truthy(&condition) {
                        let frame = self.frames.last_mut().ok_or(VMError::InvalidIP)?;
                        frame.ip = target;
                    }
                }

                OpCode::JumpIfTrue(target) => {
                    let condition = self.pop()?;
                    if self.is_truthy(&condition) {
                        let frame = self.frames.last_mut().ok_or(VMError::InvalidIP)?;
                        frame.ip = target;
                    }
                }

                OpCode::Call(callee_idx) => {
                    let callee = self
                        .program
                        .get_function(callee_idx)
                        .ok_or(VMError::InvalidFunctionIndex(callee_idx))?;
                    let arity = callee.arity;

                    // Arguments sit on top of the stack in parameter order; the
                    // new frame's base points at the first argument so that
                    // locals 0..arity coincide with the arguments.
                    let bp = self
                        .stack
                        .len()
                        .checked_sub(arity)
                        .ok_or(VMError::StackUnderflow)?;

                    self.frames.push(CallFrame {
                        function_idx: callee_idx,
                        ip: 0,
                        bp,
                    });
                }

                OpCode::Return => {
                    let return_value = self.pop()?;

                    // Pop call frame and discard its locals/arguments by
                    // truncating the stack back to the frame's base pointer.
                    let frame = self.frames.pop().ok_or(VMError::InvalidIP)?;
                    self.stack.truncate(frame.bp);

                    // If no more frames, we're done
                    if self.frames.is_empty() {
                        return Ok(return_value);
                    }

                    // Push return value onto stack
                    self.push(return_value);
                }

                OpCode::Print => {
                    // Use Display (not Debug) to match the interpreter's `print`.
                    let value = self.pop()?;
                    println!("{}", value);
                    self.push(Value::Unit);
                }

                OpCode::MakeArray(size) => {
                    let mut elements = Vec::with_capacity(size);
                    for _ in 0..size {
                        elements.insert(0, self.pop()?);
                    }
                    self.push(Value::Array(elements));
                }

                OpCode::Halt => {
                    return Ok(self.pop().unwrap_or(Value::Unit));
                }

                OpCode::MakeOkay => {
                    let v = self.pop()?;
                    self.push(Value::Okay(Box::new(v)));
                }

                OpCode::MakeOops => {
                    let v = self.pop()?;
                    let msg = match v {
                        Value::String(s) => s,
                        other => other.to_string(),
                    };
                    self.push(Value::Oops(msg));
                }

                OpCode::IsOkay => {
                    let v = self.pop()?;
                    self.push(Value::Bool(v.is_okay()));
                }

                OpCode::TryUnwrap => {
                    let v = self.pop()?;
                    match v {
                        Value::Okay(inner) => self.push(*inner),
                        // Unwrapping an Oops short-circuits: the program yields the
                        // error. (A future refinement returns from the current
                        // function only, matching the interpreter's propagation.)
                        Value::Oops(e) => return Ok(Value::Oops(e)),
                        other => self.push(other),
                    }
                }

                OpCode::Index => {
                    let index = self.pop()?;
                    let collection = self.pop()?;
                    let value = match (collection, index) {
                        (Value::Array(a), Value::Int(i)) => {
                            let idx = if i < 0 { i + a.len() as i64 } else { i };
                            if idx < 0 || idx as usize >= a.len() {
                                return Err(VMError::IndexOutOfBounds(i));
                            }
                            a[idx as usize].clone()
                        }
                        (Value::String(s), Value::Int(i)) => {
                            let chars: Vec<char> = s.chars().collect();
                            let idx = if i < 0 { i + chars.len() as i64 } else { i };
                            if idx < 0 || idx as usize >= chars.len() {
                                return Err(VMError::IndexOutOfBounds(i));
                            }
                            Value::String(chars[idx as usize].to_string())
                        }
                        (Value::Record(m), Value::String(k)) => m
                            .get(&k)
                            .cloned()
                            .ok_or_else(|| VMError::Runtime(format!("no field '{}'", k)))?,
                        _ => return Err(VMError::TypeError("invalid index operation".to_string())),
                    };
                    self.push(value);
                }

                OpCode::Len => {
                    let v = self.pop()?;
                    let len = match v {
                        Value::Array(a) => a.len(),
                        Value::String(s) => s.chars().count(),
                        Value::Record(m) => m.len(),
                        _ => {
                            return Err(VMError::TypeError(
                                "len expects an array, string, or record".to_string(),
                            ))
                        }
                    };
                    self.push(Value::Int(len as i64));
                }

                OpCode::MakeRecord(n) => {
                    // Fields are pushed as key then value; pop value then key.
                    let mut map = HashMap::new();
                    for _ in 0..n {
                        let value = self.pop()?;
                        let key = match self.pop()? {
                            Value::String(s) => s,
                            other => other.to_string(),
                        };
                        map.insert(key, value);
                    }
                    self.push(Value::Record(map));
                }

                OpCode::Concat => {
                    let b = self.pop()?;
                    let a = self.pop()?;
                    self.push(Value::String(format!("{}{}", a, b)));
                }

                OpCode::ToString => {
                    let v = self.pop()?;
                    self.push(Value::String(v.to_string()));
                }

                OpCode::Nop => {}

                OpCode::Throw => {
                    let v = self.pop()?;
                    let msg = match v {
                        Value::String(s) => s,
                        other => other.to_string(),
                    };
                    return Err(VMError::Runtime(msg));
                }

                OpCode::CheckConsent(permission) => {
                    // `#care` off => always granted; `#care` on => granted only
                    // if pre-granted (deny-by-default for the non-interactive VM,
                    // matching the interpreter's non-interactive consent path).
                    let granted = !self.program.care || self.granted.contains(&permission);
                    self.push(Value::Bool(granted));
                }

                OpCode::MakeClosure(func_idx) => {
                    // Non-capturing closure: just the bytecode function index.
                    self.push(Value::VmClosure(func_idx));
                }

                OpCode::CallValue(argc) => {
                    // Stack: [callee_closure, arg0, .., arg{argc-1}]. Remove the
                    // closure from below the args, then enter its frame with the
                    // args as locals 0..argc.
                    let cpos = self
                        .stack
                        .len()
                        .checked_sub(argc + 1)
                        .ok_or(VMError::StackUnderflow)?;
                    let callee = self.stack.remove(cpos);
                    let func_idx = match callee {
                        Value::VmClosure(idx) => idx,
                        other => {
                            return Err(VMError::TypeError(format!(
                                "cannot call non-closure value: {:?}",
                                other
                            )))
                        }
                    };
                    if self.program.get_function(func_idx).is_none() {
                        return Err(VMError::InvalidFunctionIndex(func_idx));
                    }
                    self.frames.push(CallFrame {
                        function_idx: func_idx,
                        ip: 0,
                        bp: cpos,
                    });
                }
            }
        }
    }

    /// Push a value onto the stack
    fn push(&mut self, value: Value) {
        self.stack.push(value);
    }

    /// Pop a value from the stack
    fn pop(&mut self) -> Result<Value, VMError> {
        self.stack.pop().ok_or(VMError::StackUnderflow)
    }

    /// Peek at a value on the stack (0 = top)
    fn peek(&self, distance: usize) -> Result<Value, VMError> {
        let idx = self
            .stack
            .len()
            .checked_sub(distance + 1)
            .ok_or(VMError::StackUnderflow)?;
        self.stack.get(idx).cloned().ok_or(VMError::StackUnderflow)
    }

    /// Apply a binary operation
    fn binary_op<F>(&mut self, op: F) -> Result<(), VMError>
    where
        F: Fn(Value, Value) -> Result<Value, VMError>,
    {
        let b = self.pop()?;
        let a = self.pop()?;
        let result = op(a, b)?;
        self.push(result);
        Ok(())
    }

    /// Apply a comparison operation
    fn comparison_op<F>(&mut self, op: F) -> Result<(), VMError>
    where
        F: Fn(&Value, &Value) -> bool,
    {
        let b = self.pop()?;
        let a = self.pop()?;
        let result = op(&a, &b);
        self.push(Value::Bool(result));
        Ok(())
    }

    /// Check if a value is truthy
    fn is_truthy(&self, value: &Value) -> bool {
        match value {
            Value::Bool(b) => *b,
            Value::Unit => false,
            _ => true,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::vm::bytecode::CompiledFunction;

    #[test]
    fn test_vm_arithmetic() {
        let mut program = CompiledProgram::new();
        let mut func = CompiledFunction::new("main".to_string(), 0);

        // Push 5 and 3, then add
        let c1 = func.add_constant(Value::Int(5));
        let c2 = func.add_constant(Value::Int(3));
        func.emit(OpCode::Const(c1));
        func.emit(OpCode::Const(c2));
        func.emit(OpCode::Add);
        func.emit(OpCode::Return);

        program.add_function(func);

        let mut vm = VirtualMachine::new(program);
        let result = vm.run().unwrap();

        assert_eq!(result, Value::Int(8));
    }

    #[test]
    fn test_vm_record_index_okay_unwrap() {
        // {age: 42} -> ["age"] -> Okay(_) -> unwrap == 42
        let mut program = CompiledProgram::new();
        let mut func = CompiledFunction::new("main".to_string(), 0);
        let k = func.add_constant(Value::String("age".to_string()));
        let v = func.add_constant(Value::Int(42));
        func.emit(OpCode::Const(k));
        func.emit(OpCode::Const(v));
        func.emit(OpCode::MakeRecord(1));
        let field = func.add_constant(Value::String("age".to_string()));
        func.emit(OpCode::Const(field));
        func.emit(OpCode::Index);
        func.emit(OpCode::MakeOkay);
        func.emit(OpCode::TryUnwrap);
        func.emit(OpCode::Return);
        program.add_function(func);

        let mut vm = VirtualMachine::new(program);
        assert_eq!(vm.run().unwrap(), Value::Int(42));
    }

    #[test]
    fn test_vm_array_len() {
        // len([10, 20]) == 2
        let mut program = CompiledProgram::new();
        let mut func = CompiledFunction::new("main".to_string(), 0);
        let a = func.add_constant(Value::Int(10));
        let b = func.add_constant(Value::Int(20));
        func.emit(OpCode::Const(a));
        func.emit(OpCode::Const(b));
        func.emit(OpCode::MakeArray(2));
        func.emit(OpCode::Len);
        func.emit(OpCode::Return);
        program.add_function(func);

        let mut vm = VirtualMachine::new(program);
        assert_eq!(vm.run().unwrap(), Value::Int(2));
    }

    #[test]
    fn test_vm_local_vars() {
        let mut program = CompiledProgram::new();
        let mut func = CompiledFunction::new("main".to_string(), 0);
        func.locals = 1;

        // Store 42 in local 0, then load it
        let c1 = func.add_constant(Value::Int(42));
        func.emit(OpCode::Const(c1));
        func.emit(OpCode::StoreLocal(0));
        func.emit(OpCode::LoadLocal(0));
        func.emit(OpCode::Return);

        program.add_function(func);

        let mut vm = VirtualMachine::new(program);
        let result = vm.run().unwrap();

        assert_eq!(result, Value::Int(42));
    }
}
