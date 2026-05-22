// SPDX-License-Identifier: MPL-2.0
//! Virtual Machine
//!
//! Stack-based bytecode interpreter for executing compiled WokeLang programs.

use crate::interpreter::Value;
use crate::vm::bytecode::{CompiledFunction, CompiledProgram, OpCode};
use std::collections::HashMap;
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
}

impl VirtualMachine {
    /// Create a new VM with a compiled program
    pub fn new(program: CompiledProgram) -> Self {
        Self {
            program,
            stack: Vec::new(),
            frames: Vec::new(),
            globals: HashMap::new(),
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

                OpCode::Return => {
                    let return_value = self.pop()?;

                    // Pop call frame
                    self.frames.pop();

                    // If no more frames, we're done
                    if self.frames.is_empty() {
                        return Ok(return_value);
                    }

                    // Push return value onto stack
                    self.push(return_value);
                }

                OpCode::Print => {
                    let value = self.pop()?;
                    println!("{:?}", value);
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

                _ => {
                    return Err(VMError::TypeError(format!(
                        "Unimplemented opcode: {:?}",
                        opcode
                    )));
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
