# Error Handling

WokeLang provides gentle, human-centered error handling.

---

## Philosophy

Error handling in WokeLang emphasizes:

- **Graceful recovery** over crashes
- **Human-readable messages** over stack traces
- **Explicit handling** over silent failures

---

## Attempt Safely

The primary error handling construct:

```wokelang
attempt safely {
    // Code that might fail
} or reassure "Friendly message if it fails";
```

### Basic Usage

```wokelang
attempt safely {
    remember data = fetchFromNetwork();
    processData(data);
} or reassure "Couldn't fetch data, but the app will continue";
```

### What Happens

1. Code in the `attempt` block runs
2. If successful, continues normally
3. If an error occurs, prints the reassurance message
4. Execution continues after the block

---

## Complain

Raise an error intentionally:

```wokelang
complain "Error message";
```

### Example

```wokelang
to divide(a: Int, b: Int) → Int {
    when b == 0 {
        complain "Cannot divide by zero";
    }
    give back a / b;
}
```

### Caught by Attempt

```wokelang
attempt safely {
    remember result = divide(10, 0);
    print(result);
} or reassure "Division failed, using default value";
```

---

## Common Patterns

### Validation

```wokelang
to validateEmail(email: String) → Bool {
    when len(email) == 0 {
        complain "Email cannot be empty";
    }
    when not contains(email, "@") {
        complain "Email must contain @";
    }
    give back true;
}

// Usage
attempt safely {
    validateEmail(userInput);
    sendEmail(userInput);
} or reassure "Invalid email address";
```

### Resource Access

```wokelang
to loadUserProfile(userId: String) → Profile {
    attempt safely {
        remember data = readFile("users/" + userId + ".json");
        give back parseProfile(data);
    } or reassure "Could not load profile";

    // Return default if failed
    give back defaultProfile();
}
```

### Network Operations

```wokelang
to fetchData(url: String) → String {
    attempt safely {
        only if okay "network_access" {
            remember response = httpGet(url);
            give back response;
        }
    } or reassure "Network request failed or was denied";

    give back "";
}
```

### Cascading Attempts

```wokelang
to getData() → String {
    // Try primary source
    attempt safely {
        give back fetchFromPrimary();
    } or reassure "Primary source unavailable";

    // Try backup source
    attempt safely {
        give back fetchFromBackup();
    } or reassure "Backup source unavailable";

    // Try cache
    attempt safely {
        give back loadFromCache();
    } or reassure "Cache unavailable";

    // Last resort
    give back defaultData();
}
```

---

## Result Types (Planned)

### Okay/Oops Pattern

```wokelang
type Result[T] = Okay(T) | Oops(String);

to divide(a: Int, b: Int) → Result[Int] {
    when b == 0 {
        give back Oops("Division by zero");
    }
    give back Okay(a / b);
}

// Usage
remember result = divide(10, 2);
decide based on result {
    Okay(value) → {
        print("Result: " + toString(value));
    }
    Oops(error) → {
        print("Error: " + error);
    }
}
```

### Maybe Type

```wokelang
type Maybe[T] = Some(T) | None;

to findUser(id: String) → Maybe[User] {
    when not exists(id) {
        give back None;
    }
    give back Some(loadUser(id));
}

// Usage
remember maybeUser = findUser("123");
decide based on maybeUser {
    Some(user) → {
        print("Found: " + user.name);
    }
    None → {
        print("User not found");
    }
}
```

---

## Error Propagation (Planned)

### The `?` Operator

```wokelang
to processFile(path: String) → Result[Data] {
    remember content = readFile(path)?;  // Propagates error
    remember parsed = parseJson(content)?;
    give back Okay(parsed);
}
```

Equivalent to:

```wokelang
to processFile(path: String) → Result[Data] {
    remember contentResult = readFile(path);
    decide based on contentResult {
        Oops(e) → { give back Oops(e); }
        Okay(content) → {
            remember parsedResult = parseJson(content);
            decide based on parsedResult {
                Oops(e) → { give back Oops(e); }
                Okay(parsed) → { give back Okay(parsed); }
            }
        }
    }
}
```

---

## Best Practices

### 1. Be Specific in Complain Messages

```wokelang
// Good: Specific message
complain "User ID must be between 1 and 1000, got: " + toString(id);

// Bad: Vague message
complain "Invalid input";
```

### 2. Use Reassuring Messages

```wokelang
// Good: Reassuring, explains recovery
attempt safely {
    syncData();
} or reassure "Sync failed - your data is safe locally and will sync when connection returns";

// Bad: Alarming
attempt safely {
    syncData();
} or reassure "SYNC FAILED! DATA MIGHT BE LOST!";
```

### 3. Provide Fallbacks

```wokelang
to getTemperature() → Float {
    attempt safely {
        give back fetchFromSensor();
    } or reassure "Sensor unavailable";

    // Provide a reasonable default
    give back 20.0;  // Room temperature
}
```

### 4. Validate Early

```wokelang
to processOrder(order: Order) {
    // Validate at the start
    when order.items == 0 {
        complain "Order must have at least one item";
    }
    when order.total < 0 {
        complain "Order total cannot be negative";
    }

    // Happy path continues
    submitOrder(order);
}
```

### 5. Combine with Emote Tags

```wokelang
@cautious
to riskyOperation() {
    attempt safely {
        performRiskyAction();
    } or reassure "Risky operation failed safely";
}
```

---

## Complete Example

```wokelang
thanks to {
    "Error Handling" → "For keeping our programs running";
}

to main() {
    hello "Starting error handling demo";

    // Validation
    attempt safely {
        validateInput("test@example.com");
        print("Email is valid!");
    } or reassure "Email validation failed";

    // Division with error
    attempt safely {
        remember result = safeDivide(10, 0);
        print("Result: " + toString(result));
    } or reassure "Could not complete division";

    // Cascading fallback
    remember data = getDataWithFallback();
    print("Got data: " + data);

    goodbye "Demo complete";
}

to validateInput(email: String) {
    when len(email) == 0 {
        complain "Email cannot be empty";
    }
    // More validation...
}

to safeDivide(a: Int, b: Int) → Int {
    when b == 0 {
        complain "Division by zero is not allowed";
    }
    give back a / b;
}

to getDataWithFallback() → String {
    attempt safely {
        give back fetchPrimary();
    } or reassure "Primary fetch failed";

    attempt safely {
        give back fetchBackup();
    } or reassure "Backup fetch failed";

    give back "default data";
}

to fetchPrimary() → String {
    complain "Simulated primary failure";
}

to fetchBackup() → String {
    give back "data from backup";
}
```

**Output:**
```
[hello] Starting error handling demo
Email is valid!
[reassure] Could not complete division
[reassure] Primary fetch failed
Got data: data from backup
[goodbye] Demo complete
```

---

## Next Steps

- [Control Flow](Control-Flow.md)
- [Consent System](../Core-Concepts/Consent-System.md)
- [Functions](Functions.md)
