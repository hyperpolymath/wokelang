//! WokeLang Bytecode Optimizer
//!
//! Optimization passes for improving bytecode performance.

use crate::interpreter::Value;
use super::bytecode::{CompiledFunction, CompiledProgram, OpCode};

/// Optimizer for bytecode programs
pub struct Optimizer {
    /// Enable constant folding
    pub constant_folding: bool,
    /// Enable dead code elimination
    pub dead_code_elimination: bool,
    /// Enable peephole optimizations
    pub peephole: bool,
}

impl Optimizer {
    pub fn new() -> Self {
        Self {
            constant_folding: true,
            dead_code_elimination: true,
            peephole: true,
        }
    }

    /// Optimize a compiled program
    pub fn optimize(&self, program: &mut CompiledProgram) {
        for func in &mut program.functions {
            if self.constant_folding {
                self.fold_constants(func);
            }
            if self.peephole {
                self.peephole_optimize(func);
            }
            if self.dead_code_elimination {
                self.eliminate_dead_code(func);
            }
        }
    }

    /// Constant folding - evaluate constant expressions at compile time
    fn fold_constants(&self, func: &mut CompiledFunction) {
        let mut i = 0;
        while i + 2 < func.code.len() {
            // Look for patterns like: Const(a), Const(b), BinaryOp
            if let (OpCode::Const(a_idx), OpCode::Const(b_idx)) =
                (&func.code[i], &func.code[i + 1])
            {
                let a = func.constants.get(*a_idx).cloned();
                let b = func.constants.get(*b_idx).cloned();

                if let (Some(a), Some(b)) = (a, b) {
                    let result = match &func.code[i + 2] {
                        OpCode::Add => self.fold_add(&a, &b),
                        OpCode::Sub => self.fold_sub(&a, &b),
                        OpCode::Mul => self.fold_mul(&a, &b),
                        OpCode::Div => self.fold_div(&a, &b),
                        OpCode::Eq => Some(Value::Bool(a == b)),
                        OpCode::Ne => Some(Value::Bool(a != b)),
                        OpCode::Lt => self.fold_lt(&a, &b),
                        OpCode::Le => self.fold_le(&a, &b),
                        OpCode::Gt => self.fold_gt(&a, &b),
                        OpCode::Ge => self.fold_ge(&a, &b),
                        OpCode::And => Some(Value::Bool(a.is_truthy() && b.is_truthy())),
                        OpCode::Or => Some(Value::Bool(a.is_truthy() || b.is_truthy())),
                        _ => None,
                    };

                    if let Some(result) = result {
                        // Replace the three instructions with a single Const
                        let result_idx = func.add_constant(result);
                        func.code[i] = OpCode::Const(result_idx);
                        func.code[i + 1] = OpCode::Nop;
                        func.code[i + 2] = OpCode::Nop;
                    }
                }
            }
            i += 1;
        }

        // Remove Nop instructions and update jump targets
        self.remove_nops(func);
    }

    fn fold_add(&self, a: &Value, b: &Value) -> Option<Value> {
        match (a, b) {
            (Value::Int(x), Value::Int(y)) => Some(Value::Int(x + y)),
            (Value::Float(x), Value::Float(y)) => Some(Value::Float(x + y)),
            (Value::Int(x), Value::Float(y)) => Some(Value::Float(*x as f64 + y)),
            (Value::Float(x), Value::Int(y)) => Some(Value::Float(x + *y as f64)),
            (Value::String(x), Value::String(y)) => Some(Value::String(format!("{}{}", x, y))),
            _ => None,
        }
    }

    fn fold_sub(&self, a: &Value, b: &Value) -> Option<Value> {
        match (a, b) {
            (Value::Int(x), Value::Int(y)) => Some(Value::Int(x - y)),
            (Value::Float(x), Value::Float(y)) => Some(Value::Float(x - y)),
            (Value::Int(x), Value::Float(y)) => Some(Value::Float(*x as f64 - y)),
            (Value::Float(x), Value::Int(y)) => Some(Value::Float(x - *y as f64)),
            _ => None,
        }
    }

    fn fold_mul(&self, a: &Value, b: &Value) -> Option<Value> {
        match (a, b) {
            (Value::Int(x), Value::Int(y)) => Some(Value::Int(x * y)),
            (Value::Float(x), Value::Float(y)) => Some(Value::Float(x * y)),
            (Value::Int(x), Value::Float(y)) => Some(Value::Float(*x as f64 * y)),
            (Value::Float(x), Value::Int(y)) => Some(Value::Float(x * *y as f64)),
            _ => None,
        }
    }

    fn fold_div(&self, a: &Value, b: &Value) -> Option<Value> {
        match (a, b) {
            (Value::Int(x), Value::Int(y)) if *y != 0 => Some(Value::Int(x / y)),
            (Value::Float(x), Value::Float(y)) => Some(Value::Float(x / y)),
            (Value::Int(x), Value::Float(y)) => Some(Value::Float(*x as f64 / y)),
            (Value::Float(x), Value::Int(y)) => Some(Value::Float(x / *y as f64)),
            _ => None,
        }
    }

    fn fold_lt(&self, a: &Value, b: &Value) -> Option<Value> {
        match (a, b) {
            (Value::Int(x), Value::Int(y)) => Some(Value::Bool(x < y)),
            (Value::Float(x), Value::Float(y)) => Some(Value::Bool(x < y)),
            _ => None,
        }
    }

    fn fold_le(&self, a: &Value, b: &Value) -> Option<Value> {
        match (a, b) {
            (Value::Int(x), Value::Int(y)) => Some(Value::Bool(x <= y)),
            (Value::Float(x), Value::Float(y)) => Some(Value::Bool(x <= y)),
            _ => None,
        }
    }

    fn fold_gt(&self, a: &Value, b: &Value) -> Option<Value> {
        match (a, b) {
            (Value::Int(x), Value::Int(y)) => Some(Value::Bool(x > y)),
            (Value::Float(x), Value::Float(y)) => Some(Value::Bool(x > y)),
            _ => None,
        }
    }

    fn fold_ge(&self, a: &Value, b: &Value) -> Option<Value> {
        match (a, b) {
            (Value::Int(x), Value::Int(y)) => Some(Value::Bool(x >= y)),
            (Value::Float(x), Value::Float(y)) => Some(Value::Bool(x >= y)),
            _ => None,
        }
    }

    /// Peephole optimizations - local pattern-based improvements
    fn peephole_optimize(&self, func: &mut CompiledFunction) {
        let mut i = 0;
        while i < func.code.len() {
            // Pattern: Pop followed by Const -> remove Pop if value unused
            // Pattern: Dup followed by Pop -> remove both
            if i + 1 < func.code.len() {
                match (&func.code[i], &func.code[i + 1]) {
                    (OpCode::Dup, OpCode::Pop) => {
                        func.code[i] = OpCode::Nop;
                        func.code[i + 1] = OpCode::Nop;
                    }
                    (OpCode::Not, OpCode::Not) => {
                        // Double negation elimination
                        func.code[i] = OpCode::Nop;
                        func.code[i + 1] = OpCode::Nop;
                    }
                    (OpCode::Neg, OpCode::Neg) => {
                        // Double negation elimination
                        func.code[i] = OpCode::Nop;
                        func.code[i + 1] = OpCode::Nop;
                    }
                    _ => {}
                }
            }

            // Pattern: Jump to next instruction -> remove
            if let OpCode::Jump(target) = &func.code[i] {
                if *target == i + 1 {
                    func.code[i] = OpCode::Nop;
                }
            }

            // Pattern: Const(true) followed by JumpIfFalse -> remove both (never jumps)
            if i + 1 < func.code.len() {
                if let OpCode::Const(c_idx) = func.code[i] {
                    // Check for Const(true) followed by JumpIfFalse
                    if let Some(Value::Bool(true)) = func.constants.get(c_idx) {
                        if matches!(func.code[i + 1], OpCode::JumpIfFalse(_)) {
                            func.code[i] = OpCode::Nop;
                            func.code[i + 1] = OpCode::Nop;
                        }
                    }
                    // Check for Const(false) followed by JumpIfFalse
                    else if let Some(Value::Bool(false)) = func.constants.get(c_idx) {
                        if let OpCode::JumpIfFalse(target) = func.code[i + 1] {
                            // Always jumps, convert to unconditional
                            func.code[i] = OpCode::Nop;
                            func.code[i + 1] = OpCode::Jump(target);
                        }
                    }
                }
            }

            i += 1;
        }

        self.remove_nops(func);
    }

    /// Dead code elimination - remove unreachable code
    fn eliminate_dead_code(&self, func: &mut CompiledFunction) {
        if func.code.is_empty() {
            return;
        }

        // Mark reachable instructions using control flow analysis
        let mut reachable = vec![false; func.code.len()];
        let mut worklist = vec![0usize]; // Start from first instruction

        while let Some(idx) = worklist.pop() {
            if idx >= func.code.len() || reachable[idx] {
                continue;
            }

            reachable[idx] = true;

            match &func.code[idx] {
                OpCode::Jump(target) => {
                    worklist.push(*target);
                }
                OpCode::JumpIfFalse(target) | OpCode::JumpIfTrue(target) => {
                    worklist.push(*target);
                    worklist.push(idx + 1);
                }
                OpCode::Return | OpCode::Halt => {
                    // Don't add next instruction
                }
                _ => {
                    worklist.push(idx + 1);
                }
            }
        }

        // Replace unreachable instructions with Nop
        for (i, is_reachable) in reachable.iter().enumerate() {
            if !is_reachable {
                func.code[i] = OpCode::Nop;
            }
        }

        self.remove_nops(func);
    }

    /// Remove Nop instructions and update jump targets
    fn remove_nops(&self, func: &mut CompiledFunction) {
        // Build mapping from old to new indices
        let mut new_indices = Vec::with_capacity(func.code.len());
        let mut new_idx = 0usize;

        for op in &func.code {
            new_indices.push(new_idx);
            if !matches!(op, OpCode::Nop) {
                new_idx += 1;
            }
        }

        // Update jump targets
        for op in &mut func.code {
            match op {
                OpCode::Jump(ref mut target) => {
                    if *target < new_indices.len() {
                        *target = new_indices[*target];
                    }
                }
                OpCode::JumpIfFalse(ref mut target) | OpCode::JumpIfTrue(ref mut target) => {
                    if *target < new_indices.len() {
                        *target = new_indices[*target];
                    }
                }
                _ => {}
            }
        }

        // Remove Nops
        func.code.retain(|op| !matches!(op, OpCode::Nop));
    }
}

impl Default for Optimizer {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_constant_folding() {
        let mut func = CompiledFunction::new("test".to_string(), 0);

        let c1 = func.add_constant(Value::Int(10));
        let c2 = func.add_constant(Value::Int(20));

        func.emit(OpCode::Const(c1));
        func.emit(OpCode::Const(c2));
        func.emit(OpCode::Add);
        func.emit(OpCode::Return);

        let mut program = CompiledProgram::new();
        program.add_function(func);

        let optimizer = Optimizer::new();
        optimizer.optimize(&mut program);

        let func = &program.functions[0];

        // Should have folded to a single constant
        assert!(func.code.len() < 4);
        assert!(func.constants.iter().any(|c| c == &Value::Int(30)));
    }

    #[test]
    fn test_double_negation_elimination() {
        let mut func = CompiledFunction::new("test".to_string(), 0);

        func.emit(OpCode::LoadLocal(0));
        func.emit(OpCode::Not);
        func.emit(OpCode::Not);
        func.emit(OpCode::Return);

        let mut program = CompiledProgram::new();
        program.add_function(func);

        let optimizer = Optimizer::new();
        optimizer.optimize(&mut program);

        let func = &program.functions[0];

        // Should have removed both Not instructions
        assert!(!func.code.iter().any(|op| matches!(op, OpCode::Not)));
    }

    #[test]
    fn test_dead_code_elimination() {
        let mut func = CompiledFunction::new("test".to_string(), 0);

        let c1 = func.add_constant(Value::Int(1));

        func.emit(OpCode::Const(c1));
        func.emit(OpCode::Return);
        func.emit(OpCode::Const(c1)); // Dead code
        func.emit(OpCode::Print); // Dead code

        let mut program = CompiledProgram::new();
        program.add_function(func);

        let optimizer = Optimizer::new();
        optimizer.optimize(&mut program);

        let func = &program.functions[0];

        // Should have removed dead code
        assert_eq!(func.code.len(), 2);
    }
}
