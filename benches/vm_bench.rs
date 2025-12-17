//! WokeLang VM Performance Benchmarks
//!
//! Benchmarks comparing interpreter vs VM execution.

use std::time::Instant;
use wokelang::{Interpreter, Lexer, Parser};
use wokelang::vm::{run_vm, compile};

fn bench_interpreter(source: &str, iterations: u32) -> std::time::Duration {
    let start = Instant::now();

    for _ in 0..iterations {
        let lexer = Lexer::new(source);
        let tokens = lexer.tokenize().unwrap();
        let mut parser = Parser::new(tokens, source);
        let program = parser.parse().unwrap();
        let mut interpreter = Interpreter::new();
        interpreter.run(&program).unwrap();
    }

    start.elapsed()
}

fn bench_vm(source: &str, iterations: u32) -> std::time::Duration {
    let start = Instant::now();

    for _ in 0..iterations {
        run_vm(source).unwrap();
    }

    start.elapsed()
}

fn bench_vm_precompiled(source: &str, iterations: u32) -> std::time::Duration {
    // Compile once
    let compiled = compile(source).unwrap();

    let start = Instant::now();

    for _ in 0..iterations {
        let mut vm = wokelang::vm::VirtualMachine::new(compiled.clone());
        vm.run().unwrap();
    }

    start.elapsed()
}

fn main() {
    println!("WokeLang Performance Benchmarks");
    println!("================================\n");

    // Benchmark 1: Simple arithmetic
    let simple_arithmetic = r#"
        to main() {
            remember x = 10;
            remember y = 20;
            give back x + y * 3 - 5;
        }
    "#;

    // Benchmark 2: Function calls
    let function_calls = r#"
        to add(a: Int, b: Int) -> Int {
            give back a + b;
        }

        to main() {
            remember sum = 0;
            sum = add(sum, 10);
            sum = add(sum, 20);
            sum = add(sum, 30);
            give back sum;
        }
    "#;

    // Benchmark 3: Conditionals
    let conditionals = r#"
        to abs(n: Int) -> Int {
            when n < 0 {
                give back 0 - n;
            } otherwise {
                give back n;
            }
        }

        to main() {
            remember sum = 0;
            sum = sum + abs(-5);
            sum = sum + abs(10);
            sum = sum + abs(-15);
            give back sum;
        }
    "#;

    // Benchmark 4: Loops
    let loops = r#"
        to main() {
            remember sum = 0;
            repeat 10 times {
                sum = sum + 1;
            }
            give back sum;
        }
    "#;

    // Benchmark 5: Recursion
    let recursion = r#"
        to factorial(n: Int) -> Int {
            when n <= 1 {
                give back 1;
            }
            give back n * factorial(n - 1);
        }

        to main() {
            give back factorial(10);
        }
    "#;

    let iterations = 1000;

    let benchmarks = [
        ("Simple Arithmetic", simple_arithmetic),
        ("Function Calls", function_calls),
        ("Conditionals", conditionals),
        ("Loops", loops),
        ("Recursion", recursion),
    ];

    for (name, source) in benchmarks {
        println!("Benchmark: {}", name);
        println!("{}", "-".repeat(50));

        let interp_time = bench_interpreter(source, iterations);
        let vm_time = bench_vm(source, iterations);
        let vm_precompiled_time = bench_vm_precompiled(source, iterations);

        println!(
            "  Interpreter:    {:>8.2}ms ({:>8.2}us/iter)",
            interp_time.as_secs_f64() * 1000.0,
            interp_time.as_secs_f64() * 1_000_000.0 / iterations as f64
        );
        println!(
            "  VM (full):      {:>8.2}ms ({:>8.2}us/iter)",
            vm_time.as_secs_f64() * 1000.0,
            vm_time.as_secs_f64() * 1_000_000.0 / iterations as f64
        );
        println!(
            "  VM (precomp):   {:>8.2}ms ({:>8.2}us/iter)",
            vm_precompiled_time.as_secs_f64() * 1000.0,
            vm_precompiled_time.as_secs_f64() * 1_000_000.0 / iterations as f64
        );

        let speedup = interp_time.as_secs_f64() / vm_precompiled_time.as_secs_f64();
        println!("  Speedup (precompiled vs interpreter): {:.2}x", speedup);
        println!();
    }
}
