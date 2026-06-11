// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! WokeLang REPL (Read-Eval-Print Loop)
//!
//! Interactive shell for experimenting with WokeLang.

use crate::{Interpreter, Lexer, Parser};
use miette::Result;
use rustyline::error::ReadlineError;
use rustyline::{DefaultEditor, Result as RustyResult};

pub struct Repl {
    editor: DefaultEditor,
    interpreter: Interpreter,
}

impl Repl {
    pub fn new() -> RustyResult<Self> {
        Ok(Self {
            editor: DefaultEditor::new()?,
            interpreter: Interpreter::new(),
        })
    }

    pub fn run(&mut self) -> Result<()> {
        println!("WokeLang v0.1.0 - Interactive REPL");
        println!("Type 'exit' or press Ctrl+D to quit\n");

        loop {
            match self.editor.readline("woke> ") {
                Ok(line) => {
                    let line = line.trim();

                    if line.is_empty() {
                        continue;
                    }

                    if line == "exit" || line == "quit" {
                        break;
                    }

                    // Add to history
                    let _ = self.editor.add_history_entry(line);

                    // Execute the line
                    if let Err(e) = self.execute(line) {
                        eprintln!("Error: {}", e);
                    }
                }
                Err(ReadlineError::Interrupted) => {
                    println!("^C");
                    continue;
                }
                Err(ReadlineError::Eof) => {
                    println!("^D");
                    break;
                }
                Err(err) => {
                    eprintln!("Error: {:?}", err);
                    break;
                }
            }
        }

        println!("Goodbye!");
        Ok(())
    }

    fn execute(&mut self, source: &str) -> Result<()> {
        // Lex
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize()?;

        // Parse
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse()?;

        // Interpret
        match self.interpreter.run(&program) {
            Ok(value) => {
                // Print non-unit values
                match value {
                    crate::interpreter::Value::Unit => {} // Don't print unit
                    crate::interpreter::Value::Int(n) => println!("{}", n),
                    crate::interpreter::Value::Float(f) => println!("{}", f),
                    crate::interpreter::Value::String(s) => println!("\"{}\"", s),
                    crate::interpreter::Value::Bool(b) => println!("{}", b),
                    crate::interpreter::Value::Array(arr) => {
                        print!("[");
                        for (i, val) in arr.iter().enumerate() {
                            if i > 0 {
                                print!(", ");
                            }
                            print!("{:?}", val);
                        }
                        println!("]");
                    }
                    crate::interpreter::Value::Record(map) => {
                        println!("{{");
                        for (k, v) in map.iter() {
                            println!("  {}: {:?}", k, v);
                        }
                        println!("}}");
                    }
                    crate::interpreter::Value::Okay(v) => println!("Okay({:?})", v),
                    crate::interpreter::Value::Oops(msg) => println!("Oops(\"{}\")", msg),
                    crate::interpreter::Value::Function(_) => println!("<function>"),
                    crate::interpreter::Value::Channel(_) => println!("<channel>"),
                }
            }
            Err(e) => {
                eprintln!("Runtime error: {}", e);
            }
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_repl_creation() {
        let repl = Repl::new();
        assert!(repl.is_ok());
    }
}
