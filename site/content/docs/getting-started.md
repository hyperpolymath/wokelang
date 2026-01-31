---
title: Getting Started with WokeLang
description: Learn the basics of WokeLang
template: page.html
draft: false
---

# Getting Started

## Installation

```bash
# Clone the repository
git clone https://github.com/hyperpolymath/wokelang
cd wokelang

# Build the interpreter
cargo build --release

# Add to PATH
export PATH="$PWD/target/release:$PATH"
```

## Your First Program

Create a file `hello.woke`:

```woke
to main() {
    print("Hello, World!");
}
```

Run it:

```bash
wokelang hello.woke
```

## Basic Syntax

### Variables

```woke
remember x = 42;
remember name = "Alice";
remember isActive = true;
```

### Functions

```woke
to add(a: Int, b: Int) gives back Int {
    give back a + b;
}

remember result = add(5, 3);
print(result);  // 8
```

### Pattern Matching

```woke
type Option = Some(Int) | None;

to getValue(opt: Option) gives back Int {
    case opt of
        | Some(x) then x
        | None then 0
    end
}
```

## Consent-Driven Computing

WokeLang requires explicit permission for resource access:

```woke
to readConfig() {
    consent for file.read:config.yaml {
        remember config = readFile("config.yaml");
        processConfig(config);
    } or {
        print("⚠️  Cannot proceed without config file access");
        giveBack defaultConfig();
    }
}
```

## Next Steps

- Read the [Language Guide](/docs/language-guide)
- Explore [Examples](/examples)
- Try the [Playground](/playground)
