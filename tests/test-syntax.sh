#!/usr/bin/env bash
set -euo pipefail

echo "=== Syntax Validation Test ==="
cd "$(dirname "$0")/.."

SYNTAX_ERRORS=0

check_syntax() {
    local file="$1"
    echo "Checking syntax: $file"
    
    if ! python3 <<PYTHON
import sys
with open('$file', 'r') as f:
    content = f.read()
    
open_braces = content.count('{')
close_braces = content.count('}')
open_brackets = content.count('[')
close_brackets = content.count(']')
open_parens = content.count('(')
close_parens = content.count(')')

errors = []
if open_braces != close_braces:
    errors.append(f"Mismatched braces: {open_braces} open, {close_braces} close")
if open_brackets != close_brackets:
    errors.append(f"Mismatched brackets: {open_brackets} open, {close_brackets} close")
if open_parens != close_parens:
    errors.append(f"Mismatched parentheses: {open_parens} open, {close_parens} close")

if errors:
    for error in errors:
        print(f"  Syntax issue: {error}", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PYTHON
    then
        echo "  ✗ Basic syntax check failed for $file"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        return 1
    fi
    
    echo "  ✓ Syntax valid"
    return 0
}

for file in configuration.nix disko.nix hardware-configuration.nix modules/impermanence.nix; do
    if [ -f "$file" ]; then
        check_syntax "$file"
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    echo "✓ All syntax checks passed"
    exit 0
else
    echo "✗ Found $SYNTAX_ERRORS syntax error(s)"
    exit 1
fi