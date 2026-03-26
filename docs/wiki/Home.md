# WokeLang Wiki

> *A human-centered, consent-driven programming language*

Welcome to the WokeLang documentation wiki. This wiki provides comprehensive documentation for learning, using, and contributing to WokeLang.

---

## Quick Links

| Getting Started | Reference | Advanced |
|-----------------|-----------|----------|
| [Installation](Getting-Started/Installation.md) | [Language Spec](Reference/Language-Specification.md) | [Compiler Internals](Internals/Compiler.md) |
| [Hello World](Getting-Started/Hello-World.md) | [Built-in Functions](Reference/Builtin-Functions.md) | [Parser Design](Internals/Parser.md) |
| [Basic Syntax](Getting-Started/Basic-Syntax.md) | [Standard Library](Reference/Standard-Library.md) | [WASM Target](Internals/WASM-Compilation.md) |
| [REPL Guide](Getting-Started/REPL.md) | [CLI Reference](Reference/CLI.md) | [FFI Guide](Internals/FFI.md) |

---

## Table of Contents

### 1. Getting Started
- [Installation](Getting-Started/Installation.md)
- [Hello World](Getting-Started/Hello-World.md)
- [Basic Syntax](Getting-Started/Basic-Syntax.md)
- [Using the REPL](Getting-Started/REPL.md)
- [Your First Program](Getting-Started/First-Program.md)

### 2. Language Guide
- [Variables and Types](Language-Guide/Variables-and-Types.md)
- [Functions](Language-Guide/Functions.md)
- [Control Flow](Language-Guide/Control-Flow.md)
- [Pattern Matching](Language-Guide/Pattern-Matching.md)
- [Error Handling](Language-Guide/Error-Handling.md)
- [Modules and Imports](Language-Guide/Modules.md)

### 3. Core Concepts
- [The Consent System](Core-Concepts/Consent-System.md)
- [Gratitude and Attribution](Core-Concepts/Gratitude.md)
- [Emote Tags](Core-Concepts/Emote-Tags.md)
- [Unit System](Core-Concepts/Unit-System.md)
- [Workers and Concurrency](Core-Concepts/Concurrency.md)

### 4. Reference
- [Language Specification](Reference/Language-Specification.md)
- [Built-in Functions](Reference/Builtin-Functions.md)
- [Operators](Reference/Operators.md)
- [Keywords](Reference/Keywords.md)
- [Standard Library](Reference/Standard-Library.md)
- [CLI Reference](Reference/CLI.md)

### 5. Tooling
- [Compiler](Tooling/Compiler.md)
- [Interpreter](Tooling/Interpreter.md)
- [REPL](Tooling/REPL.md)
- [Debugger](Tooling/Debugger.md)
- [Package Manager](Tooling/Package-Manager.md)
- [IDE Support](Tooling/IDE-Support.md)

### 6. Internals
- [Architecture Overview](Internals/Architecture.md)
- [Lexer Design](Internals/Lexer.md)
- [Parser Design](Internals/Parser.md)
- [AST Structure](Internals/AST.md)
- [Interpreter](Internals/Interpreter.md)
- [Compiler](Internals/Compiler.md)
- [WASM Compilation](Internals/WASM-Compilation.md)
- [FFI](Internals/FFI.md)

### 7. Tutorials
- [Building a CLI App](Tutorials/CLI-App.md)
- [Web Server with WokeLang](Tutorials/Web-Server.md)
- [Data Processing](Tutorials/Data-Processing.md)
- [Testing Your Code](Tutorials/Testing.md)
- [Embedding WokeLang](Tutorials/Embedding.md)

### 8. Frameworks
- [WokeWeb (HTTP)](Frameworks/WokeWeb.md)
- [WokeCLI (Command Line)](Frameworks/WokeCLI.md)
- [WokeTest (Testing)](Frameworks/WokeTest.md)
- [WokeData (Database)](Frameworks/WokeData.md)

### 9. Contributing
- [Development Setup](Contributing/Development-Setup.md)
- [Code Style](Contributing/Code-Style.md)
- [Testing Guidelines](Contributing/Testing.md)
- [Documentation](Contributing/Documentation.md)
- [Release Process](Contributing/Release-Process.md)

---

## Philosophy

WokeLang is built on these core principles:

### 1. Consent First
Every sensitive operation requires explicit consent. No hidden file access, no silent network calls, no surprise data collection.

```wokelang
only if okay "read_contacts" {
    remember contacts = loadContacts();
}
```

### 2. Gratitude Built-In
Attribution isn't an afterthought—it's a language feature. Give credit where credit is due.

```wokelang
thanks to {
    "Alice" → "Algorithm design";
    "Bob" → "Performance optimization";
}
```

### 3. Emotional Context
Code has emotional weight. Emote tags let you annotate intent and mood.

```wokelang
@cautious
to deleteUserData(userId: String) {
    // This is a sensitive operation
}
```

### 4. Human-Readable Syntax
Code should read like natural language where possible.

```wokelang
repeat 5 times {
    print("Hello!");
}

when temperature > 100 {
    complain "It's too hot!";
}
```

### 5. Safety by Default
Errors are handled gently. The language guides you toward safe patterns.

```wokelang
attempt safely {
    remember data = fetchData();
} or reassure "We'll try again later";
```

---

## Community

- **GitHub**: [github.com/hyperpolymath/wokelang](https://github.com/hyperpolymath/wokelang)
- **Discord**: Coming soon
- **Forum**: Coming soon

---

## License

WokeLang is open source under the MIT License.
