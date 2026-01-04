#!/bin/bash
#
# Run all tests and linting checks locally
# This mirrors the CI pipeline in .github/workflows/ci.yml
#
# Usage: ./scripts/run-tests.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track results
PASSED=0
FAILED=0
SKIPPED=0

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}  Running All Tests and Linting Checks${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""

# Function to print test status
print_status() {
    local test_name="$1"
    local status="$2"

    if [[ "$status" == "PASS" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((PASSED++))
    elif [[ "$status" == "FAIL" ]]; then
        echo -e "${RED}✗${NC} $test_name"
        ((FAILED++))
    elif [[ "$status" == "SKIP" ]]; then
        echo -e "${YELLOW}⊘${NC} $test_name (skipped - tool not installed)"
        ((SKIPPED++))
    fi
}

#
# 1. ShellCheck - Bash Script Linting
#
echo -e "\n${BLUE}[1/5] ShellCheck - Bash Script Linting${NC}"
if command -v shellcheck &> /dev/null; then
    if shellcheck scripts/*.sh; then
        print_status "ShellCheck" "PASS"
    else
        print_status "ShellCheck" "FAIL"
    fi
else
    print_status "ShellCheck" "SKIP"
    echo "  Install: brew install shellcheck (macOS) or apt install shellcheck (Linux)"
fi

#
# 2. Bash Syntax Check
#
echo -e "\n${BLUE}[2/5] Bash Syntax Check${NC}"
BASH_SYNTAX_ERRORS=0
for script in scripts/*.sh; do
    if bash -n "$script" 2>&1; then
        : # Syntax OK
    else
        echo -e "${RED}  Syntax error in: $script${NC}"
        BASH_SYNTAX_ERRORS=$((BASH_SYNTAX_ERRORS + 1))
    fi
done

if [[ $BASH_SYNTAX_ERRORS -eq 0 ]]; then
    print_status "Bash Syntax Check ($(ls scripts/*.sh | wc -l | tr -d ' ') scripts)" "PASS"
else
    print_status "Bash Syntax Check" "FAIL"
fi

#
# 3. YAML Lint
#
echo -e "\n${BLUE}[3/5] YAML Lint${NC}"
if command -v yamllint &> /dev/null; then
    if yamllint docker-compose.yml .github/workflows/; then
        print_status "YAML Lint" "PASS"
    else
        print_status "YAML Lint" "FAIL"
    fi
else
    print_status "YAML Lint" "SKIP"
    echo "  Install: pip install yamllint"
fi

#
# 4. Docker Compose Validation
#
echo -e "\n${BLUE}[4/5] Docker Compose Validation${NC}"
if command -v docker &> /dev/null; then
    # Suppress env var warnings (expected when .env not configured)
    if docker compose config --quiet 2>&1 | grep -v "variable is not set" | grep -qE "error|Error"; then
        print_status "Docker Compose Validation" "FAIL"
    else
        print_status "Docker Compose Validation" "PASS"
    fi
else
    print_status "Docker Compose Validation" "SKIP"
    echo "  Install: https://docs.docker.com/get-docker/"
fi

#
# 5. Markdown Lint
#
echo -e "\n${BLUE}[5/5] Markdown Lint${NC}"
if command -v markdownlint &> /dev/null; then
    if markdownlint --config .markdownlint.json *.md docs/*.md packaging/*/*.md 2>/dev/null; then
        print_status "Markdown Lint" "PASS"
    else
        print_status "Markdown Lint" "FAIL"
    fi
else
    print_status "Markdown Lint" "SKIP"
    echo "  Install: npm install -g markdownlint-cli"
fi

#
# Summary
#
echo ""
echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "${GREEN}Passed:${NC}  $PASSED"
echo -e "${RED}Failed:${NC}  $FAILED"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo -e "${RED}✗ TESTS FAILED${NC}"
    echo "Please fix the failures above before committing."
    exit 1
else
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    if [[ $SKIPPED -gt 0 ]]; then
        echo ""
        echo "Note: $SKIPPED checks were skipped due to missing tools."
        echo "Install the recommended tools for full validation."
        echo ""
        echo "Quick install (macOS with Homebrew):"
        echo "  brew install shellcheck"
        echo "  pip install yamllint"
        echo "  npm install -g markdownlint-cli"
    fi
    exit 0
fi
