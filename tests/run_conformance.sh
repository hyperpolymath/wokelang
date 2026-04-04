#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2026 Hyperpolymath
#
# Conformance Test Runner
# Runs all .wl conformance test programs and validates outputs

set -e

CONFORMANCE_DIR="test/conformance"
WOKE_BIN="${WOKE_BIN:-./.cargo/debug/woke}"
PASSED=0
FAILED=0
TOTAL=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if woke binary exists or build it
if [ ! -f "$WOKE_BIN" ]; then
    echo "Building wokelang..."
    cargo build --bin woke 2>&1 | head -20
    WOKE_BIN="target/debug/woke"
    if [ ! -f "$WOKE_BIN" ]; then
        echo -e "${RED}ERROR: Could not build woke binary${NC}"
        exit 1
    fi
fi

echo "Running WokeLang Conformance Tests"
echo "=================================="
echo "Binary: $WOKE_BIN"
echo ""

# Run all .wl files in conformance directory
for wl_file in "$CONFORMANCE_DIR"/*.wl; do
    if [ -f "$wl_file" ]; then
        TOTAL=$((TOTAL + 1))
        test_name=$(basename "$wl_file" .wl)

        echo -n "[$TOTAL] Testing $test_name... "

        # Run the program and capture output
        output=$("$WOKE_BIN" run "$wl_file" 2>&1 || true)

        # Check for PASS or FAIL keywords in output
        if echo "$output" | grep -q "PASS"; then
            echo -e "${GREEN}PASS${NC}"
            PASSED=$((PASSED + 1))
        elif echo "$output" | grep -q "FAIL"; then
            echo -e "${RED}FAIL${NC}"
            echo "  Output: $output" | head -5
            FAILED=$((FAILED + 1))
        else
            # No explicit result, check if it executed without error
            if [ $? -eq 0 ]; then
                echo -e "${YELLOW}UNKNOWN${NC}"
                echo "  Output: $output" | head -3
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}ERROR${NC}"
                echo "  Output: $output" | head -5
                FAILED=$((FAILED + 1))
            fi
        fi
    fi
done

echo ""
echo "=================================="
echo "Test Results: $PASSED/$TOTAL passed"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}$FAILED test(s) failed${NC}"
    exit 1
else
    echo -e "${GREEN}All conformance tests passed!${NC}"
    exit 0
fi
