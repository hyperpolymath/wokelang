---
title: Welcome to WokeLang
description: A Human-Centered Programming Language
template: index.html
draft: false
---

# Welcome to WokeLang

WokeLang is a programming language designed with human values at its core.

## Core Principles

### 🔐 Consent-Driven Computing

Programs request explicit permission before accessing resources:

```woke
consent for file.read:config.yaml {
    remember config = readFile("config.yaml");
    print("Config loaded!");
} or {
    print("Cannot proceed without config");
}
```

### 🙏 Gratitude System

Dependencies are acknowledged with gratitude:

```woke
thanks to "pulldown-cmark" for markdown parsing;
thanks to "tera" for templating;

to buildSite() {
    // Your code here
}
```

### 💭 Emotive Programming

Code can express tone and emotion:

```woke
@cheerful
to greetUser(name: String) {
    print("Hello, " + name + "! 🎉");
}

@concerned
when errorOccurred {
    print("Something went wrong ⚠️");
}
```

## Features

- **Type inference** - Hindley-Milner type system
- **Pattern matching** - Exhaustive case analysis
- **Module system** - Organize code with modules
- **Concurrency** - Worker-based parallelism
- **Security** - Capability-based security model

## Getting Started

Check out the [documentation](/docs/getting-started) to start using WokeLang!
