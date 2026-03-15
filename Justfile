# SPDX-License-Identifier: PMPL-1.0-or-later
# WokeLang Justfile

# Build the compiler
build:
    cargo build --release

# Run tests
test:
    cargo test

# Format code
format:
    cargo fmt

# Lint
lint:
    cargo clippy

# Clean
clean:
    cargo clean

# Validate RSR compliance
validate:
    @echo "Checking SPDX headers..."
    @grep -rL "SPDX-License-Identifier" src/ --include='*.rs' || echo "All files have SPDX headers"
