// SPDX-License-Identifier: PMPL-1.0-or-later
pub mod ast;
pub mod interpreter;
pub mod lexer;
pub mod linter;
pub mod lsp;
pub mod parser;
pub mod repl;
pub mod security;
pub mod stdlib;
pub mod typechecker;
pub mod vm;
// Worker module disabled due to Send trait issues with Value/Closure
// pub mod worker;

pub use ast::Program;
pub use interpreter::Interpreter;
pub use lexer::Lexer;
pub use linter::Linter;
pub use parser::Parser;
pub use repl::Repl;
pub use security::CapabilityRegistry;
pub use stdlib::StdlibRegistry;
pub use typechecker::TypeChecker;
pub use vm::{disassemble, BytecodeCompiler, CompiledProgram, VirtualMachine};
// Worker exports disabled
// pub use worker::{WorkerPool, WorkerHandle, WorkerMessage};
