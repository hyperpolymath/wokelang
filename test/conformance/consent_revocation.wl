// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent Revocation
// Tests that previously granted consent can be revoked and subsequent access is denied

to main() {
    remember first_access = false;
    remember second_access = false;

    // First access with consent
    only if okay "data_access" {
        first_access = true;
        say "First access granted";
    }

    // Revoke consent and attempt second access
    forget "data_access";

    only if okay "data_access" {
        second_access = true;
        say "Second access granted (should not happen)";
    }

    when first_access {
        say "PASS: First access was successful";
    } otherwise {
        say "FAIL: First access was denied";
    }

    when second_access {
        say "FAIL: Second access succeeded after revocation";
    } otherwise {
        say "PASS: Second access was properly denied after revocation";
    }
}
