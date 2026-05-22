// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Hyperpolymath

// Conformance Test: Multiple Permissions
// Tests that multiple distinct permissions can be requested independently

to main() {
    remember read_granted = false;
    remember write_granted = false;
    remember delete_granted = false;

    only if okay "read_permission" {
        read_granted = true;
        say "Read permission granted";
    }

    only if okay "write_permission" {
        write_granted = true;
        say "Write permission granted";
    }

    only if okay "delete_permission" {
        delete_granted = true;
        say "Delete permission granted";
    }

    when read_granted {
        say "PASS: Read permission was independent";
    } otherwise {
        say "FAIL: Read permission was denied";
    }

    when write_granted {
        say "PASS: Write permission was independent";
    } otherwise {
        say "FAIL: Write permission was denied";
    }

    when delete_granted {
        say "PASS: Delete permission was independent";
    } otherwise {
        say "FAIL: Delete permission was denied";
    }
}
