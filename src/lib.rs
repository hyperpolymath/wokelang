pub mod ast;
pub mod codegen;
pub mod ffi;
pub mod interpreter;
pub mod lexer;
pub mod parser;
pub mod repl;
pub mod security;
pub mod stdlib;
pub mod typechecker;
pub mod vm;
pub mod worker;

pub use ast::Program;
pub use codegen::WasmCompiler;
pub use interpreter::Interpreter;
pub use lexer::Lexer;
pub use parser::Parser;
pub use repl::Repl;
pub use security::{Capability, CapabilityRegistry, ConsentStore, ConsentDuration};
pub use stdlib::StdlibRegistry;
pub use typechecker::TypeChecker;
pub use vm::{BytecodeCompiler, VirtualMachine, Optimizer};
pub use worker::{WorkerHandle, WorkerPool, WorkerMessage};

// Re-export FFI for cdylib
pub use ffi::*;
