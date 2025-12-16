use miette::Result;
use std::env;
use std::fs;
use std::path::Path;
use wokelang::{Interpreter, Lexer, Parser, Repl, WasmCompiler};

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        // No arguments - start REPL
        let mut repl = Repl::new().expect("Failed to start REPL");
        repl.run().expect("REPL error");
        return Ok(());
    }

    let (mode, file_path) = match args.get(1).map(|s| s.as_str()) {
        Some("--repl" | "-i") => {
            let mut repl = Repl::new().expect("Failed to start REPL");
            repl.run().expect("REPL error");
            return Ok(());
        }
        Some("--help" | "-h") => {
            print_help();
            return Ok(());
        }
        Some("--version" | "-v") => {
            println!("WokeLang v0.1.0");
            return Ok(());
        }
        Some("--tokenize") => ("tokenize", args.get(2)),
        Some("--parse") => ("parse", args.get(2)),
        Some("--compile-wasm" | "-c") => ("compile-wasm", args.get(2)),
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
        "compile-wasm" => {
            let mut parser = Parser::new(tokens, &source);
            match parser.parse() {
                Ok(program) => {
                    let mut compiler = WasmCompiler::new();
                    match compiler.compile(&program) {
                        Ok(wasm_bytes) => {
                            // Determine output path
                            let input_path = Path::new(file_path);
                            let output_path = args
                                .get(3)
                                .map(|s| s.to_string())
                                .unwrap_or_else(|| {
                                    input_path
                                        .with_extension("wasm")
                                        .to_string_lossy()
                                        .to_string()
                                });

                            fs::write(&output_path, &wasm_bytes).expect("Failed to write WASM file");
                            println!(
                                "Compiled to {} ({} bytes)",
                                output_path,
                                wasm_bytes.len()
                            );
                        }
                        Err(e) => {
                            eprintln!("Compile error: {}", e);
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

fn print_help() {
    println!("WokeLang v0.1.0 - A human-centered, consent-driven programming language");
    println!();
    println!("USAGE:");
    println!("    woke                          Start interactive REPL");
    println!("    woke <file.woke>              Run a WokeLang program");
    println!("    woke --repl, -i               Start interactive REPL");
    println!("    woke --compile-wasm, -c <f>   Compile to WebAssembly");
    println!("    woke --tokenize <file>        Show lexer tokens");
    println!("    woke --parse <file>           Show parsed AST");
    println!("    woke --help, -h               Show this help");
    println!("    woke --version, -v            Show version");
    println!();
    println!("REPL COMMANDS:");
    println!("    :help       Show REPL commands");
    println!("    :quit       Exit the REPL");
    println!("    :load <f>   Load a file");
    println!("    :reset      Reset interpreter state");
    println!();
    println!("WASM COMPILATION:");
    println!("    woke -c input.woke            Output to input.wasm");
    println!("    woke -c input.woke out.wasm   Output to out.wasm");
}
