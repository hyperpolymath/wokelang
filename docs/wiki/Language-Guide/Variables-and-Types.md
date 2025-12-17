# Variables and Types

WokeLang provides a clear, type-safe variable system.

---

## Variables

### Declaration with `remember`

Variables are declared with `remember`:

```wokelang
remember name = "Alice";
remember age = 30;
remember pi = 3.14159;
remember active = true;
```

The keyword suggests the program is "remembering" a value for later use.

### Type Inference

Types are inferred from the value:

```wokelang
remember x = 42;        // Int
remember y = 3.14;      // Float
remember z = "hello";   // String
remember w = true;      // Bool
```

### Explicit Type Annotations

Optionally specify types:

```wokelang
remember count: Int = 0;
remember ratio: Float = 0.5;
remember message: String = "";
remember enabled: Bool = false;
```

### Reassignment

Variables can be reassigned:

```wokelang
remember x = 10;
x = 20;           // Now x is 20
x = x + 5;        // Now x is 25
```

---

## Primitive Types

### Int

64-bit signed integers:

```wokelang
remember positive = 42;
remember negative = -17;
remember zero = 0;
remember large = 9223372036854775807;  // Max Int
```

**Operations:**
```wokelang
remember sum = 5 + 3;       // 8
remember diff = 10 - 4;     // 6
remember prod = 6 * 7;      // 42
remember quot = 20 / 4;     // 5
remember rem = 17 % 5;      // 2
```

### Float

64-bit floating-point numbers:

```wokelang
remember pi = 3.14159;
remember e = 2.71828;
remember negative = -0.5;
remember scientific = 1.5;  // Scientific notation planned
```

**Operations:**
```wokelang
remember sum = 1.5 + 2.5;   // 4.0
remember prod = 2.0 * 3.5;  // 7.0
remember div = 10.0 / 4.0;  // 2.5
```

### String

UTF-8 encoded text:

```wokelang
remember greeting = "Hello, World!";
remember empty = "";
remember multiword = "This is a sentence.";
```

**Escape sequences:**
```wokelang
remember newline = "Line1\nLine2";
remember tab = "Col1\tCol2";
remember quote = "She said \"Hello\"";
remember backslash = "Path\\to\\file";
```

**Operations:**
```wokelang
remember full = "Hello" + ", " + "World";  // Concatenation
remember length = len("hello");             // 5
```

### Bool

Boolean values:

```wokelang
remember yes = true;
remember no = false;
```

**Operations:**
```wokelang
remember both = true and false;   // false
remember either = true or false;  // true
remember opposite = not true;     // false
```

---

## Composite Types

### Arrays

Ordered collections of same-type values:

```wokelang
remember numbers = [1, 2, 3, 4, 5];
remember names = ["Alice", "Bob", "Charlie"];
remember empty: [Int] = [];
```

**Type annotations:**
```wokelang
remember items: [String] = ["a", "b", "c"];
remember matrix: [[Int]] = [[1, 2], [3, 4]];
```

**Operations:**
```wokelang
remember first = numbers[0];        // 1
remember length = len(numbers);     // 5
```

### Optional Types (Planned)

Values that might not exist:

```wokelang
type Maybe[T] = Some(T) | None;

remember maybeValue: Maybe Int = findValue();
```

---

## Unit Values

Values with associated units of measurement:

```wokelang
remember distance = 100 measured in meters;
remember speed = 60 measured in mph;
remember temperature = 98.6 measured in fahrenheit;
remember duration = 30 measured in seconds;
```

Unit types help prevent errors like adding meters to seconds.

---

## Type Aliases (Planned)

Create named types:

```wokelang
type UserId = String;
type Temperature = Float;
type Point = { x: Float, y: Float };

remember user: UserId = "user_123";
remember temp: Temperature = 72.5;
```

---

## Struct Types (Planned)

Define structured data:

```wokelang
type Person = {
    name: String,
    age: Int,
    email: Maybe String
};

remember alice: Person = {
    name: "Alice",
    age: 30,
    email: Some("alice@example.com")
};
```

---

## Enum Types (Planned)

Define variants:

```wokelang
type Status = Active | Inactive | Pending;
type Result[T] = Success(T) | Failure(String);

remember status: Status = Active;
remember result: Result[Int] = Success(42);
```

---

## Type Conversions

### Built-in Conversions

```wokelang
// To String
remember s = toString(42);        // "42"
remember s2 = toString(3.14);     // "3.14"
remember s3 = toString(true);     // "true"

// To Int
remember i = toInt("42");         // 42
remember i2 = toInt(3.14);        // 3 (truncates)

// To Float
remember f = toFloat("3.14");     // 3.14
remember f2 = toFloat(42);        // 42.0
```

### Mixed-Type Arithmetic

```wokelang
// Int + Float promotes to Float
remember mixed = 5 + 3.5;  // 8.5 (Float)
```

---

## Scope

Variables are scoped to their block:

```wokelang
to main() {
    remember x = 10;

    when true {
        remember y = 20;
        print(x);  // Can access x from outer scope
        print(y);  // Can access y
    }

    print(x);      // Can still access x
    // print(y);   // Error: y not in scope
}
```

---

## Constants (Planned)

Immutable values:

```wokelang
const MAX_SIZE = 100;
const PI = 3.14159;
const APP_NAME = "MyApp";
```

---

## Complete Example

```wokelang
to main() {
    hello "Variables and types demo";

    // Primitives
    remember name = "WokeLang";
    remember version = 1;
    remember stable = true;

    // Type annotations
    remember count: Int = 0;

    // Arrays
    remember features = ["consent", "gratitude", "emotes"];

    // Unit values
    remember codeLines = 5000 measured in lines;

    // Operations
    remember greeting = "Hello, " + name + "!";
    remember doubled = version * 2;
    remember featureCount = len(features);

    // Output
    print(greeting);
    print("Version: " + toString(version));
    print("Stable: " + toString(stable));
    print("Features: " + toString(featureCount));

    // Type conversions
    remember versionStr = toString(version);
    remember parsed = toInt("42");

    print("Parsed: " + toString(parsed));

    goodbye "Demo complete";
}
```

---

## Best Practices

### 1. Use Descriptive Names

```wokelang
// Good
remember userName = "Alice";
remember totalItems = 42;
remember isEnabled = true;

// Bad
remember u = "Alice";
remember n = 42;
remember b = true;
```

### 2. Initialize Variables

```wokelang
// Good: Initialized
remember count = 0;

// Avoid: Using before initialization
remember count;  // Not valid in WokeLang
```

### 3. Use Type Annotations for Clarity

```wokelang
// Clearer with type
remember config: [String] = [];
remember result: Maybe Int = findValue();
```

### 4. Prefer Immutability (When Available)

```wokelang
// Prefer const when value won't change
const MAX_RETRIES = 3;

// Use remember for values that change
remember currentRetry = 0;
```

---

## Next Steps

- [Functions](Functions.md)
- [Control Flow](Control-Flow.md)
- [Built-in Functions](../Reference/Builtin-Functions.md)
