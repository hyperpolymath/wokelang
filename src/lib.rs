pub mod ast;
pub mod codegen;
pub mod ffi;
pub mod interpreter;
pub mod lexer;
pub mod parser;
pub mod repl;
pub mod typechecker;
pub mod worker;

pub use ast::Program;
pub use codegen::WasmCompiler;
pub use interpreter::Interpreter;
pub use lexer::Lexer;
pub use parser::Parser;
pub use repl::Repl;
pub use typechecker::TypeChecker;
pub use worker::{WorkerHandle, WorkerPool, WorkerMessage};

// Re-export FFI for cdylib
pub use ffi::*;
