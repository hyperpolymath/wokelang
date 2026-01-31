#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Install git hooks for WokeLang development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "Installing git hooks..."

# Pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Pre-commit hook for WokeLang

set -e

echo "Running pre-commit checks..."

# Check for SPDX headers in staged files
echo "Checking SPDX headers..."
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(rs|woke|toml|md|adoc)$'); do
    if [ -f "$file" ]; then
        if ! head -5 "$file" | grep -q "SPDX-License-Identifier"; then
            echo "❌ Missing SPDX header: $file"
            echo "Add: // SPDX-License-Identifier: PMPL-1.0-or-later"
            exit 1
        fi
    fi
done

# Run cargo check if Rust files changed
if git diff --cached --name-only | grep -q '\.rs$'; then
    echo "Running cargo check..."
    cargo check --quiet || {
        echo "❌ cargo check failed"
        exit 1
    }
fi

# Run cargo fmt check if Rust files changed
if git diff --cached --name-only | grep -q '\.rs$'; then
    echo "Checking Rust formatting..."
    cargo fmt -- --check || {
        echo "❌ Rust formatting issues found. Run: cargo fmt"
        exit 1
    }
fi

# Check .editorconfig compliance
if command -v editorconfig-checker >/dev/null 2>&1; then
    echo "Checking EditorConfig compliance..."
    editorconfig-checker $(git diff --cached --name-only) || {
        echo "⚠️  EditorConfig issues found (non-blocking)"
    }
fi

echo "✓ Pre-commit checks passed"
EOF

# Commit-msg hook
cat > "$HOOKS_DIR/commit-msg" << 'EOF'
#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# Commit message hook for WokeLang

set -e

commit_msg_file=$1
commit_msg=$(cat "$commit_msg_file")

# Check for conventional commit format
if ! echo "$commit_msg" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|chore|build|ci)(\(.+\))?: .+'; then
    echo "❌ Commit message must follow conventional commits format:"
    echo "   type(scope): description"
    echo ""
    echo "   Types: feat, fix, docs, style, refactor, perf, test, chore, build, ci"
    echo ""
    echo "   Example: feat: add consent system runtime enforcement"
    exit 1
fi

# Check commit message length
first_line=$(echo "$commit_msg" | head -1)
if [ ${#first_line} -gt 72 ]; then
    echo "⚠️  Warning: First line exceeds 72 characters (${#first_line})"
fi

echo "✓ Commit message format valid"
EOF

# Make hooks executable
chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/commit-msg"

echo "✓ Git hooks installed successfully"
echo ""
echo "Hooks installed:"
echo "  - pre-commit: SPDX headers, cargo check, cargo fmt"
echo "  - commit-msg: Conventional commits format"
