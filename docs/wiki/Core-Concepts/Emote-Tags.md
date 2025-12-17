# Emote Tags

Emote tags provide emotional context and semantic meaning to WokeLang code.

---

## Philosophy

Code has emotional context. A function that deletes data should feel different from one that displays a welcome message. Emote tags make this context explicit, helping both humans and tools understand code intent.

---

## Basic Syntax

```wokelang
@tag_name
to functionName() {
    // function body
}
```

### With Parameters

```wokelang
@tag_name(param="value", other=123)
to functionName() {
    // function body
}
```

---

## Standard Emote Tags

### @important

Marks critical code that requires special attention.

```wokelang
@important
to validatePayment(amount: Float) → Bool {
    // This code handles money - must be correct
    when amount <= 0 {
        give back false;
    }
    give back processPayment(amount);
}
```

**Use cases:**
- Security-sensitive operations
- Financial calculations
- Data integrity checks

### @cautious

Indicates code that should be approached carefully.

```wokelang
@cautious
to deleteUserAccount(userId: String) {
    only if okay "delete_account" {
        removeFromDatabase(userId);
        clearUserFiles(userId);
        sendGoodbyeEmail(userId);
    }
}
```

**Use cases:**
- Destructive operations
- Irreversible actions
- Data modifications

### @experimental

Marks unstable or work-in-progress code.

```wokelang
@experimental(stability="alpha")
to newSearchAlgorithm(data: [Int]) → [Int] {
    // This might change or be removed
    give back experimentalSort(data);
}
```

**Use cases:**
- New features
- Proof of concepts
- A/B testing code

### @deprecated

Marks code that should no longer be used.

```wokelang
@deprecated(reason="Use newFunction() instead", since="0.2.0")
to oldFunction() {
    // Legacy code
    newFunction();
}
```

**Use cases:**
- Legacy APIs
- Renamed functions
- Superseded implementations

### @happy

Marks code with positive outcomes.

```wokelang
@happy
to celebrateSuccess(user: String) {
    print("Congratulations, " + user + "!");
    playConfetti();
    sendCelebrationEmail(user);
}
```

**Use cases:**
- Success handlers
- Achievement notifications
- Positive feedback

### @sad

Marks code dealing with negative outcomes.

```wokelang
@sad
to handleFailure(error: String) {
    print("Sorry, something went wrong: " + error);
    logError(error);
    offerHelp();
}
```

**Use cases:**
- Error handlers
- Failure notifications
- Disappointment responses

### @curious

Marks exploratory or diagnostic code.

```wokelang
@curious
to investigatePerformance() {
    remember start = now();
    runBenchmark();
    remember duration = now() - start;
    print("Benchmark took: " + toString(duration) + "ms");
}
```

**Use cases:**
- Debugging code
- Profiling
- Logging
- Exploration

---

## Custom Emote Tags

Define your own tags for domain-specific semantics:

```wokelang
@security_critical
to encryptData(data: String) → String {
    // ...
}

@user_facing
to displayWelcome(name: String) {
    // ...
}

@performance_sensitive
to processLargeDataset(data: [Int]) {
    // ...
}

@requires_network
to syncWithServer() {
    // ...
}
```

---

## Tag Parameters

### Stability Level

```wokelang
@experimental(stability="alpha")
to alphaFeature() { }

@experimental(stability="beta")
to betaFeature() { }
```

### Deprecation Info

```wokelang
@deprecated(
    reason="Replaced by newAPI",
    since="0.2.0",
    remove_in="1.0.0"
)
to oldAPI() { }
```

### Priority

```wokelang
@important(priority=1)
to criticalFunction() { }

@important(priority=2)
to lessUrgentFunction() { }
```

### Author Attribution

```wokelang
@author(name="Jane Doe", date="2024-03-15")
to featureByJane() { }
```

---

## Multiple Tags

Apply multiple tags to a single function:

```wokelang
@important
@cautious
@deprecated(reason="Security concerns")
to riskyLegacyFunction() {
    // Handle with extreme care
}
```

---

## Emote Tags on Other Constructs

### On Workers

```wokelang
@experimental
worker backgroundProcessor {
    // ...
}
```

### On Side Quests

```wokelang
@happy
side quest celebration {
    playMusic();
    showFireworks();
}
```

### On Type Definitions (Planned)

```wokelang
@important
type SecureToken = String;
```

---

## Tooling Integration

### IDE Support (Planned)

Emote tags can trigger visual indicators:

- `@important` → Red highlight
- `@cautious` → Yellow warning
- `@experimental` → Dashed underline
- `@deprecated` → Strikethrough
- `@happy` → Green accent
- `@sad` → Gray accent

### Documentation Generation (Planned)

```bash
woke doc --include-emotes
```

Generates documentation with emote context:

```markdown
## deleteAccount

⚠️ **Cautious** - This function should be approached carefully.

🔒 **Requires consent** - `delete_account`

Deletes a user's account and all associated data.
```

### Static Analysis (Planned)

```bash
woke lint --check-deprecated
# Warning: Use of deprecated function 'oldAPI' at line 42
```

---

## Best Practices

### 1. Use Appropriate Tags

```wokelang
// Good: Tag matches function behavior
@cautious
to deleteFile(path: String) { }

// Misleading: Happy tag on destructive function
@happy  // Don't do this
to deleteFile(path: String) { }
```

### 2. Add Context with Parameters

```wokelang
// Better with reason
@deprecated(reason="Use formatCurrency() for locale support")
to formatMoney(amount: Float) → String { }
```

### 3. Combine Meaningfully

```wokelang
// Good: Tags complement each other
@important
@cautious
to handleSensitiveData(data: String) { }

// Confusing: Contradictory tags
@experimental
@deprecated  // If deprecated, why still experimental?
to confusingFunction() { }
```

### 4. Document Custom Tags

```wokelang
// Document what your custom tags mean
// @security_critical: Functions that handle encryption/auth
// @user_facing: Functions that produce user-visible output
// @requires_network: Functions that need internet connection

@security_critical
to hashPassword(password: String) → String { }
```

---

## Implementation

### AST Representation

```rust
pub struct EmoteTag {
    pub name: String,
    pub params: Vec<(String, EmoteValue)>,
}

pub enum EmoteValue {
    String(String),
    Number(f64),
    Identifier(String),
}
```

### Parsing

```rust
fn parse_emote_tag(&mut self) -> Result<EmoteTag> {
    self.expect(Token::At)?;
    let name = self.expect_identifier()?;

    let params = if self.match_token(Token::LeftParen) {
        let p = self.parse_emote_params()?;
        self.expect(Token::RightParen)?;
        p
    } else {
        vec![]
    };

    Ok(EmoteTag { name, params })
}
```

---

## Example: Complete Program

```wokelang
thanks to {
    "WokeLang" → "For emotive programming";
}

@happy
to main() {
    hello "Welcome to the emote demo!";

    // Call various emote-tagged functions
    processUserData("Alice");

    goodbye "Thanks for exploring emotes!";
}

@important
@cautious
to processUserData(name: String) {
    only if okay "process_data" {
        print("Processing data for: " + name);
        saveSecurely(name);
    }
}

@deprecated(reason="Use saveSecurely instead")
to saveData(data: String) {
    // Old implementation
}

@experimental(stability="beta")
to saveSecurely(data: String) {
    // New secure implementation
    print("Saving securely: " + data);
}

@curious
to debugInfo() {
    print("Debug: checking system state");
}
```

---

## Next Steps

- [Consent System](Consent-System.md)
- [Gratitude System](Gratitude.md)
- [Functions](../Language-Guide/Functions.md)
