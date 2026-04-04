// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Consent Nesting
// Tests that multiple nested consent blocks work correctly

to main() {
    remember level1 = false;
    remember level2 = false;
    remember level3 = false;

    only if okay "level1_permission" {
        level1 = true;
        say "Level 1 permission granted";

        only if okay "level2_permission" {
            level2 = true;
            say "Level 2 permission granted";

            only if okay "level3_permission" {
                level3 = true;
                say "Level 3 permission granted";
            }
        }
    }

    when level1 {
        say "PASS: Level 1 consent granted";
    } otherwise {
        say "FAIL: Level 1 consent denied";
    }

    when level2 {
        say "PASS: Level 2 consent granted";
    } otherwise {
        say "FAIL: Level 2 consent denied";
    }

    when level3 {
        say "PASS: Level 3 consent granted";
    } otherwise {
        say "FAIL: Level 3 consent denied";
    }
}
