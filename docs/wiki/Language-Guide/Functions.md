# Functions

Functions are the primary way to organize code in WokeLang.

---

## Basic Function Definition

```wokelang
to functionName() {
    // function body
}
```

### With Parameters

```wokelang
to greet(name: String) {
    print("Hello, " + name + "!");
}
```

### With Return Type

```wokelang
to add(a: Int, b: Int) → Int {
    give back a + b;
}
```

---

## The `to` Keyword

Functions are declared with `to`, suggesting intention:

```wokelang
to calculateTotal(items: [Float]) → Float {
    // "To calculate total, we..."
}
```

This reads naturally: "To calculate total, given items..."

---

## Parameters

### Required Parameters

```wokelang
to sendEmail(to: String, subject: String, body: String) {
    // All parameters must be provided
}
```

### Type Annotations

All parameters require type annotations:

```wokelang
to process(
    name: String,
    count: Int,
    ratio: Float,
    active: Bool
) {
    // ...
}
```

### Reference Parameters (Planned)

```wokelang
to modify(data: &[Int]) {
    // Can modify the original array
}
```

---

## Return Values

### Explicit Return

Use `give back` to return values:

```wokelang
to square(n: Int) → Int {
    give back n * n;
}
```

### Early Return

Return early from conditionals:

```wokelang
to absoluteValue(n: Int) → Int {
    when n < 0 {
        give back -n;
    }
    give back n;
}
```

### Implicit Unit

Functions without `give back` return `Unit`:

```wokelang
to logMessage(msg: String) {
    print(msg);
    // Implicitly returns Unit
}
```

---

## Lifecycle Messages

### Hello and Goodbye

Functions can have entry and exit messages:

```wokelang
to processOrder(orderId: String) {
    hello "Starting order processing";

    // Processing logic here
    validateOrder(orderId);
    chargePayment(orderId);
    shipOrder(orderId);

    goodbye "Order processing complete";
}
```

**Output:**
```
[hello] Starting order processing
[goodbye] Order processing complete
```

### Purpose

- `hello`: Setup, logging, initialization context
- `goodbye`: Cleanup, completion logging, summary

### Optional

Both are optional:

```wokelang
to quickTask() {
    // No hello/goodbye needed for simple functions
    print("Done!");
}
```

---

## Emote Tags

Add emotional context with tags:

```wokelang
@important
to validateCreditCard(number: String) → Bool {
    // Security-critical code
}

@experimental
to tryNewAlgorithm(data: [Int]) → [Int] {
    // Unstable code
}

@deprecated(reason="Use newAPI()")
to oldAPI() {
    // Legacy code
}
```

See [Emote Tags](../Core-Concepts/Emote-Tags.md) for details.

---

## Calling Functions

### Basic Calls

```wokelang
greet("Alice");
remember result = add(3, 5);
print(toString(result));
```

### Chained Results

```wokelang
remember doubled = double(triple(5));  // 30
```

### As Arguments

```wokelang
print(toString(add(1, 2)));
```

---

## Recursion

WokeLang supports recursive functions:

```wokelang
to factorial(n: Int) → Int {
    when n <= 1 {
        give back 1;
    } otherwise {
        give back n * factorial(n - 1);
    }
}
```

### Fibonacci

```wokelang
to fibonacci(n: Int) → Int {
    when n <= 1 {
        give back n;
    }
    give back fibonacci(n - 1) + fibonacci(n - 2);
}
```

---

## Function Patterns

### Guard Clauses

```wokelang
to divide(a: Int, b: Int) → Int {
    when b == 0 {
        complain "Cannot divide by zero";
    }
    give back a / b;
}
```

### Default Behavior

```wokelang
to greet(name: String) → String {
    when len(name) == 0 {
        give back "Hello, stranger!";
    }
    give back "Hello, " + name + "!";
}
```

### Builder Pattern (Planned)

```wokelang
to createUser() → UserBuilder {
    give back UserBuilder.new();
}

// Usage
remember user = createUser()
    .withName("Alice")
    .withEmail("alice@example.com")
    .build();
```

---

## Higher-Order Functions (Planned)

### Function Parameters

```wokelang
to applyTwice(f: (Int) → Int, x: Int) → Int {
    give back f(f(x));
}

to double(n: Int) → Int {
    give back n * 2;
}

// Usage
remember result = applyTwice(double, 5);  // 20
```

### Anonymous Functions (Planned)

```wokelang
remember numbers = [1, 2, 3, 4, 5];
remember doubled = map(numbers, (n) → n * 2);
```

---

## Complete Example

```wokelang
thanks to {
    "Math" → "For the beauty of numbers";
}

@important
to main() {
    hello "Calculator starting";

    remember nums = [1, 2, 3, 4, 5];
    remember total = sum(nums);
    remember avg = average(nums);

    print("Sum: " + toString(total));
    print("Average: " + toString(avg));

    remember fact5 = factorial(5);
    print("5! = " + toString(fact5));

    goodbye "Calculator done";
}

to sum(numbers: [Int]) → Int {
    remember total = 0;
    remember i = 0;
    repeat len(numbers) times {
        total = total + numbers[i];
        i = i + 1;
    }
    give back total;
}

to average(numbers: [Int]) → Float {
    remember total = sum(numbers);
    give back toFloat(total) / toFloat(len(numbers));
}

to factorial(n: Int) → Int {
    when n <= 1 {
        give back 1;
    }
    give back n * factorial(n - 1);
}
```

---

## Best Practices

### 1. Clear Names

```wokelang
// Good: Descriptive names
to calculateMonthlyPayment(principal: Float, rate: Float, months: Int) → Float

// Bad: Unclear names
to calc(p: Float, r: Float, m: Int) → Float
```

### 2. Single Responsibility

```wokelang
// Good: Focused functions
to validateEmail(email: String) → Bool { ... }
to sendEmail(to: String, body: String) { ... }

// Bad: Doing too much
to validateAndSendEmail(email: String, body: String) { ... }
```

### 3. Use Lifecycle Messages Meaningfully

```wokelang
// Good: Informative messages
to processPayment(amount: Float) {
    hello "Processing payment of $" + toString(amount);
    // ...
    goodbye "Payment processed successfully";
}

// Unnecessary for simple functions
to add(a: Int, b: Int) → Int {
    // No need for hello/goodbye here
    give back a + b;
}
```

### 4. Appropriate Emote Tags

```wokelang
@cautious
to deleteAccount() { ... }  // Destructive - cautious is appropriate

@happy
to sendWelcome() { ... }    // Positive - happy is appropriate
```

---

## Next Steps

- [Control Flow](Control-Flow.md)
- [Variables and Types](Variables-and-Types.md)
- [Error Handling](Error-Handling.md)
