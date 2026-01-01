// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Hello World - WokeLang Core Example
// This example demonstrates the core features of WokeLang:
// - Gratitude blocks (thanks to)
// - Function definitions with hello/goodbye lifecycle
// - Consent gates (only if okay)
// - Units of measure (measured in)
// - Error handling (attempt safely)
// - Emote annotations (@enthusiastic)

thanks to {
    "OCaml Community" → "For the robust type system";
    "You" → "For trying WokeLang";
}

@enthusiastic
to greet(name: String) → String {
    hello "Starting the greeting";

    remember message = "Hello, " + name + "!";
    say message;
    give back message;

    goodbye "Greeting complete";
}

to demonstrate_units() {
    // Units of measure prevent mixing incompatible values
    remember distance = 42 measured in km;
    remember time_taken = 2 measured in hours;

    say "Distance: ";
    say distance;
    say "Time: ";
    say time_taken;
}

to demonstrate_consent() {
    // Consent gates ensure explicit permission for sensitive operations
    only if okay "greeting_permission" {
        say "You consented to receive a greeting!";
        greet("World");
    }
}

to demonstrate_safety() {
    // Safe error handling with reassurance
    attempt safely {
        say "Attempting something that might fail...";
        // This would normally be a risky operation
        say "Operation succeeded!";
    } or reassure "Don't worry, we handled that gracefully";
}

to demonstrate_loops() {
    // Natural language loop syntax
    say "Counting to 3:";
    repeat 3 times {
        say "Hello again!";
    }
}

to main() {
    say "=== WokeLang Hello World ===";
    say "";

    // Simple greeting
    greet("WokeLang");
    say "";

    // Demonstrate units
    say "--- Units of Measure ---";
    demonstrate_units();
    say "";

    // Demonstrate consent
    say "--- Consent Gates ---";
    demonstrate_consent();
    say "";

    // Demonstrate safety
    say "--- Safe Error Handling ---";
    demonstrate_safety();
    say "";

    // Demonstrate loops
    say "--- Natural Loops ---";
    demonstrate_loops();
    say "";

    say "=== End of Demo ===";
}
