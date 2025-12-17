# Hello, World!

Let's write your first WokeLang program.

---

## Your First Program

Create a file called `hello.woke`:

```wokelang
to main() {
    hello "Welcome to WokeLang!";

    print("Hello, World!");

    goodbye "Thanks for running me!";
}
```

Run it:

```bash
woke hello.woke
```

Output:
```
[hello] Welcome to WokeLang!
Hello, World!
[goodbye] Thanks for running me!
```

---

## Understanding the Code

### Function Definition

```wokelang
to main() {
    // code here
}
```

- `to` declares a function
- `main()` is the entry point (like C/Rust)
- Code goes inside `{ }`

### Lifecycle Messages

```wokelang
hello "Welcome to WokeLang!";
goodbye "Thanks for running me!";
```

- `hello` runs when a function starts
- `goodbye` runs when it ends
- These are optional but encouraged for meaningful functions

### Printing Output

```wokelang
print("Hello, World!");
```

- `print()` outputs to the console
- Strings use double quotes `""`

---

## A More Complete Example

```wokelang
// Gratitude block - acknowledge contributors
thanks to {
    "WokeLang Community" → "For believing in kind code";
}

// Main function with emote tag
@happy
to main() {
    hello "Starting the greeting program";

    remember name = "Developer";
    remember greeting = greet(name);

    print(greeting);

    goodbye "Hope you enjoyed this!";
}

// Helper function with return type
to greet(name: String) → String {
    give back "Hello, " + name + "! Welcome to WokeLang!";
}
```

---

## Key Concepts Introduced

| Concept | Syntax | Purpose |
|---------|--------|---------|
| Function | `to name() { }` | Define reusable code |
| Variable | `remember x = value;` | Store data |
| Return | `give back value;` | Return from function |
| Hello/Goodbye | `hello "msg";` | Lifecycle hooks |
| Comments | `// comment` | Documentation |
| Emote Tags | `@happy` | Emotional context |
| Gratitude | `thanks to { }` | Attribution |

---

## Try the REPL

For quick experimentation, use the interactive REPL:

```bash
woke repl
```

```
WokeLang REPL v0.1.0
Type :help for commands, :quit to exit

woke> print("Hello from REPL!")
Hello from REPL!

woke> remember x = 42
woke> print(x * 2)
84

woke> :quit
Goodbye! Thanks for using WokeLang.
```

---

## Next Steps

- [Basic Syntax](Basic-Syntax.md) - Learn variables, types, and operators
- [Functions](../Language-Guide/Functions.md) - Deep dive into functions
- [REPL Guide](REPL.md) - Master the interactive environment
