# Control Flow

WokeLang provides intuitive control flow constructs with clear, readable syntax.

---

## Conditionals

### When/Otherwise

```wokelang
when condition {
    // Code if condition is true
} otherwise {
    // Code if condition is false
}
```

**Example:**

```wokelang
when score >= 90 {
    print("Excellent!");
} otherwise {
    print("Keep trying!");
}
```

### Without Otherwise

The `otherwise` clause is optional:

```wokelang
when needsUpdate {
    refreshData();
}
// Continues here regardless
```

### Nested Conditions

```wokelang
when score >= 90 {
    print("A");
} otherwise {
    when score >= 80 {
        print("B");
    } otherwise {
        when score >= 70 {
            print("C");
        } otherwise {
            print("F");
        }
    }
}
```

### Condition Expressions

Any expression that produces a truthy value:

```wokelang
when count > 0 {
    print("Has items");
}

when name == "Admin" {
    showAdminPanel();
}

when isActive and hasPermission {
    performAction();
}
```

---

## Loops

### Repeat Times

```wokelang
repeat count times {
    // Executed 'count' times
}
```

**Examples:**

```wokelang
// Fixed count
repeat 5 times {
    print("Hello!");
}

// Variable count
remember n = 3;
repeat n times {
    print("Counting...");
}
```

### Loop with Counter (Pattern)

```wokelang
remember i = 0;
repeat 10 times {
    print("Index: " + toString(i));
    i = i + 1;
}
```

### Early Exit (Planned)

```wokelang
repeat 100 times {
    when found {
        stop;  // Exit loop
    }
}
```

### Skip Iteration (Planned)

```wokelang
repeat items times {
    when shouldSkip {
        skip;  // Continue to next iteration
    }
    process(item);
}
```

---

## Pattern Matching

### Decide Based On

```wokelang
decide based on value {
    pattern1 → {
        // Code for pattern1
    }
    pattern2 → {
        // Code for pattern2
    }
    _ → {
        // Default case (wildcard)
    }
}
```

### String Matching

```wokelang
decide based on status {
    "success" → {
        print("Operation succeeded!");
        celebrate();
    }
    "pending" → {
        print("Still waiting...");
    }
    "error" → {
        print("Something went wrong");
        handleError();
    }
    _ → {
        print("Unknown status: " + status);
    }
}
```

### Numeric Matching

```wokelang
decide based on code {
    200 → {
        print("OK");
    }
    404 → {
        print("Not Found");
    }
    500 → {
        print("Server Error");
    }
    _ → {
        print("Status: " + toString(code));
    }
}
```

### Boolean Matching

```wokelang
decide based on isActive {
    true → {
        showActiveState();
    }
    false → {
        showInactiveState();
    }
}
```

---

## Error Handling Control Flow

### Attempt Safely

```wokelang
attempt safely {
    // Code that might fail
    remember data = riskyOperation();
    processData(data);
} or reassure "Operation failed, but we're okay";
```

### Complain (Throw Error)

```wokelang
to divide(a: Int, b: Int) → Int {
    when b == 0 {
        complain "Cannot divide by zero";
    }
    give back a / b;
}
```

See [Error Handling](Error-Handling.md) for more details.

---

## Consent Control Flow

### Only If Okay

```wokelang
only if okay "permission_name" {
    // Code requiring permission
}
```

**Example:**

```wokelang
only if okay "camera_access" {
    remember photo = takePhoto();
    displayPhoto(photo);
}
```

See [Consent System](../Core-Concepts/Consent-System.md) for more details.

---

## Control Flow in Functions

### Early Return

```wokelang
to findFirst(items: [Int], target: Int) → Int {
    remember i = 0;
    repeat len(items) times {
        when items[i] == target {
            give back i;  // Early return
        }
        i = i + 1;
    }
    give back -1;  // Not found
}
```

### Guard Clauses

```wokelang
to processUser(user: Maybe User) {
    when user == none {
        give back;  // Early exit
    }
    // Process valid user
}
```

---

## Truthiness

Values are evaluated for truthiness in conditions:

| Value | Truthy? |
|-------|---------|
| `true` | Yes |
| `false` | No |
| `0` | No |
| Non-zero integers | Yes |
| `0.0` | No |
| Non-zero floats | Yes |
| `""` (empty string) | No |
| Non-empty strings | Yes |
| `[]` (empty array) | No |
| Non-empty arrays | Yes |
| `Unit` | No |

**Example:**

```wokelang
remember count = 5;
when count {  // true because count != 0
    print("Has items");
}

remember name = "";
when name {  // false because name is empty
    print("Has name");
}
```

---

## Combined Examples

### Menu System

```wokelang
to handleMenu(choice: String) {
    decide based on choice {
        "1" → {
            print("Starting new game...");
            startGame();
        }
        "2" → {
            print("Loading saved game...");
            loadGame();
        }
        "3" → {
            print("Opening settings...");
            openSettings();
        }
        "q" → {
            print("Goodbye!");
            // Exit
        }
        _ → {
            print("Invalid choice. Please try again.");
        }
    }
}
```

### Validation Loop

```wokelang
to getValidInput() → Int {
    remember attempts = 0;
    remember maxAttempts = 3;
    remember result = 0;

    repeat maxAttempts times {
        attempts = attempts + 1;
        print("Attempt " + toString(attempts) + " of " + toString(maxAttempts));

        attempt safely {
            remember input = readInput();
            result = toInt(input);

            when result > 0 {
                give back result;
            }

            print("Please enter a positive number");
        } or reassure "Invalid input, try again";
    }

    complain "Too many invalid attempts";
}
```

### State Machine

```wokelang
to runStateMachine(initialState: String) {
    remember state = initialState;
    remember running = true;

    repeat 100 times {  // Max iterations for safety
        when not running {
            // Would use 'stop' when available
        }

        decide based on state {
            "idle" → {
                print("Waiting for input...");
                state = "processing";
            }
            "processing" → {
                print("Processing...");
                state = "complete";
            }
            "complete" → {
                print("Done!");
                running = false;
            }
            _ → {
                print("Unknown state");
                running = false;
            }
        }
    }
}
```

---

## Best Practices

### 1. Prefer Pattern Matching

```wokelang
// Good: Clear pattern matching
decide based on status {
    "active" → { activate(); }
    "inactive" → { deactivate(); }
    _ → { handleUnknown(); }
}

// Less clear: Nested ifs
when status == "active" {
    activate();
} otherwise {
    when status == "inactive" {
        deactivate();
    } otherwise {
        handleUnknown();
    }
}
```

### 2. Always Handle the Default Case

```wokelang
decide based on value {
    // Known cases
    1 → { handleOne(); }
    2 → { handleTwo(); }
    // Always include wildcard
    _ → { handleDefault(); }
}
```

### 3. Keep Conditions Simple

```wokelang
// Good: Clear, simple condition
remember isEligible = age >= 18 and hasConsent;
when isEligible {
    proceed();
}

// Harder to read
when age >= 18 and hasConsent and not isBanned and accountActive {
    proceed();
}
```

### 4. Use Guard Clauses

```wokelang
// Good: Early exit for invalid cases
to processOrder(order: Order) {
    when order == none {
        give back;
    }
    when not order.isValid {
        give back;
    }
    // Happy path continues
    submitOrder(order);
}
```

---

## Next Steps

- [Functions](Functions.md)
- [Error Handling](Error-Handling.md)
- [Pattern Matching](Pattern-Matching.md)
