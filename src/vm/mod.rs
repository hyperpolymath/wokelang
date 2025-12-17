//! WokeLang Virtual Machine
//!
//! A bytecode compiler and stack-based VM for efficient execution.

pub mod bytecode;
pub mod compiler;
pub mod machine;
pub mod optimizer;

pub use bytecode::{CompiledFunction, CompiledProgram, OpCode};
pub use compiler::{BytecodeCompiler, CompileError};
pub use machine::{VirtualMachine, VMError};
pub use optimizer::Optimizer;

use crate::interpreter::Value;
use crate::lexer::Lexer;
use crate::parser::Parser;

/// Compile and run WokeLang source code using the VM
pub fn run_vm(source: &str) -> Result<Value, String> {
    // Lex
    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().map_err(|e| format!("Lexer error: {}", e))?;

    // Parse
    let mut parser = Parser::new(tokens, source);
    let program = parser.parse().map_err(|e| format!("Parse error: {}", e))?;

    // Compile to bytecode
    let mut compiler = BytecodeCompiler::new();
    let mut compiled = compiler
        .compile(&program)
        .map_err(|e| format!("Compile error: {}", e))?;

    // Optimize
    let optimizer = Optimizer::new();
    optimizer.optimize(&mut compiled);

    // Execute
    let mut vm = VirtualMachine::new(compiled);
    vm.run().map_err(|e| format!("VM error: {}", e))
}

/// Compile WokeLang source to bytecode (without running)
pub fn compile(source: &str) -> Result<CompiledProgram, String> {
    let lexer = Lexer::new(source);
    let tokens = lexer.tokenize().map_err(|e| format!("Lexer error: {}", e))?;

    let mut parser = Parser::new(tokens, source);
    let program = parser.parse().map_err(|e| format!("Parse error: {}", e))?;

    let mut compiler = BytecodeCompiler::new();
    let mut compiled = compiler
        .compile(&program)
        .map_err(|e| format!("Compile error: {}", e))?;

    let optimizer = Optimizer::new();
    optimizer.optimize(&mut compiled);

    Ok(compiled)
}

/// Disassemble bytecode for debugging
pub fn disassemble(program: &CompiledProgram) -> String {
    let mut output = String::new();

    for (func_idx, func) in program.functions.iter().enumerate() {
        output.push_str(&format!(
            "\n=== Function {}: {} (arity: {}, locals: {}) ===\n",
            func_idx, func.name, func.arity, func.locals
        ));

        // Constants
        if !func.constants.is_empty() {
            output.push_str("Constants:\n");
            for (i, c) in func.constants.iter().enumerate() {
                output.push_str(&format!("  {}: {:?}\n", i, c));
            }
        }

        // Instructions
        output.push_str("Code:\n");
        for (i, op) in func.code.iter().enumerate() {
            output.push_str(&format!("  {:04}: {:?}\n", i, op));
        }
    }

    if let Some(entry) = program.entry {
        output.push_str(&format!("\nEntry point: function {}\n", entry));
    }

    output
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run_vm_simple() {
        let source = r#"
            to main() {
                give back 42;
            }
        "#;
        let result = run_vm(source).unwrap();
        assert_eq!(result, Value::Int(42));
    }

    #[test]
    fn test_run_vm_arithmetic() {
        let source = r#"
            to main() {
                remember x = 10;
                remember y = 20;
                give back x + y;
            }
        "#;
        let result = run_vm(source).unwrap();
        assert_eq!(result, Value::Int(30));
    }

    #[test]
    fn test_run_vm_function_call() {
        let source = r#"
            to double(n: Int) -> Int {
                give back n * 2;
            }

            to main() {
                give back double(21);
            }
        "#;
        let result = run_vm(source).unwrap();
        assert_eq!(result, Value::Int(42));
    }

    #[test]
    fn test_disassemble() {
        let source = r#"
            to main() {
                remember x = 5;
                give back x;
            }
        "#;
        let compiled = compile(source).unwrap();
        let disasm = disassemble(&compiled);

        assert!(disasm.contains("main"));
        assert!(disasm.contains("Code:"));
    }
}
