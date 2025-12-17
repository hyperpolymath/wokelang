# WokeLang-Specific Library

This directory contains libraries that are **unique to WokeLang** and represent the language's distinctive features. These are NOT part of the common aggregate-library.

## What Makes WokeLang Unique

WokeLang is a **human-centered, consent-driven programming language** with features not found in the other six languages in the ecosystem:

1. **Consent-First Design** - Sensitive operations require explicit user permission
2. **Emotional Annotations** - Code can express and track emotional context
3. **Gratitude as Code** - Attribution and acknowledgment are first-class constructs
4. **Hello/Goodbye Lifecycle** - Functions can declare entry/exit messages

## Library Modules

### consent.woke
Permission and consent management for sensitive operations:
- `withConsent(permission, reason, action)` - Execute action only with consent
- `requireAllConsents(permissions, action)` - Require multiple permissions
- `safeReadFile(path)`, `safeWriteFile(path, content)` - Consent-protected I/O
- `redact(text, patterns)`, `anonymize(data)` - Privacy utilities
- Permission constants: `PERM_READ_FILE`, `PERM_NETWORK_HTTP`, etc.

### emotes.woke
Emotional annotations and sentiment-aware programming:
- Emote types: `Happy`, `Sad`, `Curious`, `Careful`, `Mindful`, `Thoughtful`, etc.
- `logWithEmote(emote, message)` - Emotion-aware logging
- `withCaution(level, action)` - Sentiment-controlled execution
- `EmotionalState` tracking and `CodeHealth` assessment

### gratitude.woke
Attribution and acknowledgment utilities:
- `GratitudeRegistry` for managing acknowledgments
- `generateCredits(registry)` - Create attribution text
- `acknowledgeDependency(...)` - Track third-party dependencies
- `recognizeContributor(contributor)` - Spotlight contributors

## Usage

```woke
use lib.wokelang.consent;
use lib.wokelang.emotes;
use lib.wokelang.gratitude;

@mindful(importance=8)
to main() {
    hello "Starting application";

    (* Use consent-protected file reading *)
    remember config = safeReadFile("config.json")?;

    (* Log with emotional context *)
    logWithEmote(Happy(7), "Configuration loaded successfully!");

    (* Execute with caution for risky operations *)
    remember result = withCaution(5, to () -> Result[Data, String] {
        give back processData(config);
    });

    give back 0;

    goodbye "Application complete";
}

thanks to {
    "WokeLang Community" → "Building human-centered software";
}
```

## What's NOT Here

The following belong in `lib/common/` as they're shared across all seven languages:
- Basic arithmetic (`add`, `subtract`, `multiply`, `divide`, `modulo`)
- Comparisons (`less_than`, `greater_than`, `equal`, etc.)
- Logical operations (`and`, `or`, `not`)
- String operations (`concat`, `length`, `substring`)
- Collection operations (`map`, `filter`, `fold`, `contains`)
- Conditional (`if_then_else`)

## Philosophy

> "Code should be written for humans first, machines second."

WokeLang's specific library embodies this philosophy by providing:
- **Consent** - Respecting user autonomy and privacy
- **Emotion** - Acknowledging the human side of programming
- **Gratitude** - Celebrating contributions and collaboration

## See Also

- [Common Library](../common/README.md) - Shared operations from aggregate-library
- [aggregate-library](https://github.com/hyperpolymath/aggregate-library) - The cross-language specification
