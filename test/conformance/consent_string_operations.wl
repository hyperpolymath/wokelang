// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent with String Operations
// Tests that string operations work correctly within consent blocks

to main() {
    remember message = "";

    only if okay "string_manipulation" {
        message = "Hello";
        message = message ++ " ";
        message = message ++ "Consent";
        say message;
    }

    when message == "Hello Consent" {
        say "PASS: String concatenation within consent block worked";
    } otherwise {
        say "FAIL: String concatenation result incorrect";
    }
}
