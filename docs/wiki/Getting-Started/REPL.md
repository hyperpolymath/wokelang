# REPL Guide

The WokeLang REPL (Read-Eval-Print Loop) provides an interactive environment for experimenting with the language.

---

## Starting the REPL

```bash
woke repl
```

```
WokeLang REPL v0.1.0
Type :help for commands, :quit to exit

woke>
```

---

## Basic Usage

### Evaluating Expressions

```
woke> 2 + 2
4

woke> "Hello" + " " + "World"
Hello World

woke> 10 * 5 + 3
53
```

### Declaring Variables

```
woke> remember x = 42
woke> remember y = 8
woke> x + y
50

woke> remember name = "Alice"
woke> print("Hello, " + name)
Hello, Alice
```

### Defining Functions

```
woke> to double(n: Int) → Int { give back n * 2; }
woke> double(21)
42

woke> to greet(name: String) { print("Hi, " + name + "!"); }
woke> greet("Bob")
Hi, Bob!
```

---

## REPL Commands

| Command | Description |
|---------|-------------|
| `:help` | Show available commands |
| `:quit` or `:q` | Exit the REPL |
| `:reset` | Clear all defined variables and functions |
| `:load <file>` | Load and execute a .woke file |
| `:ast <expr>` | Show the AST for an expression |

### :help

```
woke> :help
WokeLang REPL Commands:
  :help          Show this help message
  :quit, :q      Exit the REPL
  :reset         Clear interpreter state
  :load <file>   Load a WokeLang file
  :ast <expr>    Show AST for expression
```

### :load

```
woke> :load examples/math.woke
Loaded examples/math.woke

woke> factorial(5)
120
```

### :ast

```
woke> :ast 2 + 3 * 4
Binary {
    left: Literal(Int(2)),
    op: Add,
    right: Binary {
        left: Literal(Int(3)),
        op: Mul,
        right: Literal(Int(4))
    }
}
```

### :reset

```
woke> remember secret = 42
woke> secret
42

woke> :reset
State cleared.

woke> secret
Error: Undefined variable: secret
```

---

## Multi-line Input

For multi-line definitions, the REPL detects incomplete input:

```
woke> to factorial(n: Int) → Int {
...>     when n <= 1 {
...>         give back 1;
...>     } otherwise {
...>         give back n * factorial(n - 1);
...>     }
...> }

woke> factorial(10)
3628800
```

The prompt changes to `...>` when waiting for more input.

---

## Working with Types

### Checking Values

```
woke> remember x = 42
woke> x
42

woke> remember arr = [1, 2, 3]
woke> arr
[1, 2, 3]

woke> len(arr)
3
```

### Type Conversions

```
woke> toString(42)
42

woke> toInt("123")
123

woke> toFloat(42)
42.0
```

---

## Error Handling in REPL

The REPL gracefully handles errors:

```
woke> 1 / 0
Error: Division by zero

woke> undefinedVar
Error: Undefined variable: undefinedVar

woke> to broken( { }
Error: Parse error at line 1: Expected ')' or parameter
```

Errors don't crash the REPL - just fix and try again.

---

## Tips and Tricks

### Quick Calculations

```
woke> 2 ** 10
1024

woke> 100 * 1.08
108.0

woke> (10 + 20) * 3
90
```

### Testing Functions Before Saving

```
woke> to isPrime(n: Int) → Bool {
...>     when n <= 1 { give back false; }
...>     remember i = 2;
...>     repeat (n - 2) times {
...>         when n % i == 0 { give back false; }
...>         i = i + 1;
...>     }
...>     give back true;
...> }

woke> isPrime(7)
true

woke> isPrime(10)
false
```

### Exploring Built-in Functions

```
woke> print("test")
test

woke> len("hello")
5

woke> len([1, 2, 3, 4])
4

woke> toString(3.14159)
3.14159
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+C` | Cancel current input |
| `Ctrl+D` | Exit REPL (same as :quit) |
| `Up/Down` | Navigate history |
| `Ctrl+R` | Reverse search history |
| `Tab` | Auto-complete (planned) |

---

## Session Example

Here's a complete REPL session:

```
$ woke repl
WokeLang REPL v0.1.0
Type :help for commands, :quit to exit

woke> // Let's explore WokeLang!

woke> remember greeting = "Hello, WokeLang!"
woke> print(greeting)
Hello, WokeLang!

woke> to fib(n: Int) → Int {
...>     when n <= 1 {
...>         give back n;
...>     } otherwise {
...>         give back fib(n - 1) + fib(n - 2);
...>     }
...> }

woke> fib(10)
55

woke> remember results = [0, 0, 0, 0, 0]
woke> // Arrays and iteration coming in v0.2.0!

woke> :quit
Goodbye! Thanks for using WokeLang.
```

---

## Next Steps

- [First Program](First-Program.md) - Writing complete programs
- [CLI Reference](../Reference/CLI.md) - Full command-line options
- [Debugging](../Tooling/Debugger.md) - Debugging techniques
