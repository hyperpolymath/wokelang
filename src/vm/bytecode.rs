//! WokeLang Bytecode Instruction Set
//!
//! A stack-based bytecode format for efficient execution.

use crate::interpreter::Value;
use std::collections::HashMap;

/// Bytecode instructions for the WokeLang VM
#[derive(Debug, Clone, PartialEq)]
pub enum OpCode {
    // Stack operations
    /// Push a constant onto the stack
    Const(usize),
    /// Pop the top value from the stack
    Pop,
    /// Duplicate the top value on the stack
    Dup,
    /// Swap the top two values on the stack
    Swap,

    // Local variables
    /// Load a local variable onto the stack
    LoadLocal(usize),
    /// Store the top of stack into a local variable
    StoreLocal(usize),
    /// Load a global variable
    LoadGlobal(String),
    /// Store into a global variable
    StoreGlobal(String),

    // Arithmetic operations (pop operands, push result)
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Neg,

    // Comparison operations
    Eq,
    Ne,
    Lt,
    Le,
    Gt,
    Ge,

    // Logical operations
    And,
    Or,
    Not,

    // String operations
    Concat,

    // Control flow
    /// Unconditional jump to instruction index
    Jump(usize),
    /// Jump if top of stack is false
    JumpIfFalse(usize),
    /// Jump if top of stack is true
    JumpIfTrue(usize),

    // Functions
    /// Call a function with N arguments
    Call(usize),
    /// Return from function
    Return,
    /// Create a closure
    MakeClosure(usize),

    // Array/Record operations
    /// Create an array from N elements on stack
    MakeArray(usize),
    /// Create a record from N key-value pairs
    MakeRecord(usize),
    /// Index into array or record
    Index,
    /// Get length of array/string
    Len,

    // Result types
    /// Wrap top of stack in Okay
    MakeOkay,
    /// Wrap top of stack in Oops
    MakeOops,
    /// Unwrap Okay or propagate Oops
    TryUnwrap,
    /// Check if value is Okay
    IsOkay,

    // Built-in functions
    /// Print the top of stack
    Print,
    /// Convert to string
    ToString,

    // No operation (for padding/optimization)
    Nop,
    /// Halt execution
    Halt,
}

/// A compiled function
#[derive(Debug, Clone)]
pub struct CompiledFunction {
    /// Function name (for debugging)
    pub name: String,
    /// Number of parameters
    pub arity: usize,
    /// Number of local variables (including parameters)
    pub locals: usize,
    /// Bytecode instructions
    pub code: Vec<OpCode>,
    /// Constant pool for this function
    pub constants: Vec<Value>,
}

impl CompiledFunction {
    pub fn new(name: String, arity: usize) -> Self {
        Self {
            name,
            arity,
            locals: arity,
            code: Vec::new(),
            constants: Vec::new(),
        }
    }

    /// Add a constant and return its index
    pub fn add_constant(&mut self, value: Value) -> usize {
        // Check if constant already exists
        for (i, c) in self.constants.iter().enumerate() {
            if c == &value {
                return i;
            }
        }
        let idx = self.constants.len();
        self.constants.push(value);
        idx
    }

    /// Emit an instruction and return its index
    pub fn emit(&mut self, op: OpCode) -> usize {
        let idx = self.code.len();
        self.code.push(op);
        idx
    }

    /// Patch a jump instruction with the correct target
    pub fn patch_jump(&mut self, jump_idx: usize, target: usize) {
        match &mut self.code[jump_idx] {
            OpCode::Jump(ref mut t) => *t = target,
            OpCode::JumpIfFalse(ref mut t) => *t = target,
            OpCode::JumpIfTrue(ref mut t) => *t = target,
            _ => panic!("Tried to patch non-jump instruction"),
        }
    }

    /// Get current instruction index (for jump targets)
    pub fn current_offset(&self) -> usize {
        self.code.len()
    }
}

/// A compiled program
#[derive(Debug, Clone)]
pub struct CompiledProgram {
    /// All compiled functions
    pub functions: Vec<CompiledFunction>,
    /// Index of the main/entry function
    pub entry: Option<usize>,
    /// Global variables (name -> value)
    pub globals: HashMap<String, Value>,
}

impl CompiledProgram {
    pub fn new() -> Self {
        Self {
            functions: Vec::new(),
            entry: None,
            globals: HashMap::new(),
        }
    }

    /// Add a function and return its index
    pub fn add_function(&mut self, func: CompiledFunction) -> usize {
        let idx = self.functions.len();
        if func.name == "main" {
            self.entry = Some(idx);
        }
        self.functions.push(func);
        idx
    }

    /// Get a function by index
    pub fn get_function(&self, idx: usize) -> Option<&CompiledFunction> {
        self.functions.get(idx)
    }
}

impl Default for CompiledProgram {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compiled_function() {
        let mut func = CompiledFunction::new("test".to_string(), 2);

        let c1 = func.add_constant(Value::Int(42));
        let c2 = func.add_constant(Value::String("hello".to_string()));
        let c3 = func.add_constant(Value::Int(42)); // Should reuse c1

        assert_eq!(c1, 0);
        assert_eq!(c2, 1);
        assert_eq!(c3, 0); // Reused

        func.emit(OpCode::Const(c1));
        func.emit(OpCode::Const(c2));
        func.emit(OpCode::Add);

        assert_eq!(func.code.len(), 3);
    }

    #[test]
    fn test_jump_patching() {
        let mut func = CompiledFunction::new("test".to_string(), 0);

        let jump_idx = func.emit(OpCode::JumpIfFalse(0)); // Placeholder
        func.emit(OpCode::Const(0));
        func.emit(OpCode::Pop);
        let target = func.current_offset();
        func.patch_jump(jump_idx, target);

        assert_eq!(func.code[jump_idx], OpCode::JumpIfFalse(3));
    }
}
