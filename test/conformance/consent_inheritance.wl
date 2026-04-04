// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent Inheritance
// Tests that child scopes properly handle consent from parent scopes

to helper_with_explicit_consent() {
    remember result = false;

    // Request explicit consent for this permission
    only if okay "helper_permission" {
        result = true;
        say "Helper explicit permission granted";
    }

    when result {
        say "PASS: Helper explicit permission works";
    } otherwise {
        say "FAIL: Helper explicit permission denied";
    }
}

to main() {
    remember outer_granted = false;

    only if okay "outer_permission" {
        outer_granted = true;
        say "Outer permission granted";

        // Inner function should need its own consent
        helper_with_explicit_consent();
    }

    when outer_granted {
        say "PASS: Outer permission was granted";
    } otherwise {
        say "FAIL: Outer permission was denied";
    }
}
