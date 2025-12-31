use miette::Result;
use std::env;
use std::fs;
use wokelang::{Interpreter, Lexer, Parser, Repl, TypeChecker};

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        println!("WokeLang v0.1.0 - A human-centered, consent-driven programming language");
        println!();
        println!("Usage: woke <file.woke>           Run a WokeLang program");
        println!("       woke repl                  Start interactive REPL");
        println!("       woke --tokenize <file>     Show lexer tokens");
        println!("       woke --parse <file>        Show parsed AST");
        println!("       woke --typecheck <file>    Type-check without running");
        return Ok(());
    }

    // Check for REPL mode first
    if args.get(1).map(|s| s.as_str()) == Some("repl") {
        let mut repl = Repl::new().expect("Failed to create REPL");
        repl.run().expect("REPL error");
        return Ok(());
    }

    let (mode, file_path) = match args.get(1).map(|s| s.as_str()) {
        Some("--tokenize") => ("tokenize", args.get(2)),
        Some("--parse") => ("parse", args.get(2)),
        Some("--typecheck") => ("typecheck", args.get(2)),
        Some(_) => ("run", Some(&args[1])),
        None => {
            eprintln!("Expected file path");
            return Ok(());
        }
    };

    let file_path = match file_path {
        Some(p) => p,
        None => {
            eprintln!("Expected file path after flag");
            return Ok(());
        }
    };

    let source = fs::read_to_string(file_path).expect("Failed to read file");
    let lexer = Lexer::new(&source);

    let tokens = match lexer.tokenize() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("{:?}", miette::Report::new(e));
            return Ok(());
        }
    };

    match mode {
        "tokenize" => {
            for token in &tokens {
                println!("{:?} @ {:?}", token.value, token.span);
            }
            println!("\nTokenized {} tokens successfully.", tokens.len());
        }
        "parse" => {
            let mut parser = Parser::new(tokens, &source);
            match parser.parse() {
                Ok(program) => {
                    println!("{:#?}", program);
                    println!("\nParsed {} top-level items successfully.", program.items.len());
                }
                Err(e) => {
                    eprintln!("{:?}", miette::Report::new(e));
                }
            }
        }
        "typecheck" => {
            let mut parser = Parser::new(tokens, &source);
            match parser.parse() {
                Ok(program) => {
                    let mut typechecker = TypeChecker::new();
                    match typechecker.check_program(&program) {
                        Ok(()) => {
                            println!("Type check passed!");
                        }
                        Err(e) => {
                            eprintln!("Type error: {}", e);
                        }
                    }
                }
                Err(e) => {
                    eprintln!("{:?}", miette::Report::new(e));
                }
            }
        }
        "run" => {
            let mut parser = Parser::new(tokens, &source);
            match parser.parse() {
                Ok(program) => {
                    // Type check first
                    let mut typechecker = TypeChecker::new();
                    if let Err(e) = typechecker.check_program(&program) {
                        eprintln!("Type error: {}", e);
                        eprintln!("\nType checking failed. Not running.");
                        return Ok(());
                    }

                    // Run the program
                    let mut interpreter = Interpreter::new();
                    if let Err(e) = interpreter.run(&program) {
                        eprintln!("Runtime error: {}", e);
                    }
                }
                Err(e) => {
                    eprintln!("{:?}", miette::Report::new(e));
                }
            }
        }
        _ => unreachable!(),
    }

    Ok(())
}
