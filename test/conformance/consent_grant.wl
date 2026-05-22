// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent Grant
// Tests that consent gates properly gate sensitive operations

to main() {
    remember accessed = false;

    only if okay "test_resource_access" {
        accessed = true;
        say "Resource access granted";
    }

    when accessed {
        say "PASS: Consent was granted and body executed";
    } otherwise {
        say "FAIL: Consent body was not executed";
    }
}
