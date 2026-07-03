#!/usr/bin/env bash
# pm - Unit Tests
# Tests for pm project manager with multi-base and env file support

# Test utilities
_test() {
	local description="$1"
	local command="$2"

	if eval "$command" >/dev/null 2>&1; then
		echo "Testing: $description ... ✓"
		((PASS++))
	else
		echo "Testing: $description ... ✗"
		((FAIL++))
	fi
}

# Counters
PASS=0
FAIL=0

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'; cd /home/ppang/Public/bash-project-mod" EXIT

export XDG_CONFIG_HOME="$TEST_DIR/config"
export HOME="$TEST_DIR/home"
export PM_CURRENT_BASE=""
export PROJECT_BASE=""
export PROJECT=""

# Create test directories
mkdir -p "$TEST_DIR/bases/base1/proj1"
mkdir -p "$TEST_DIR/bases/base1/proj2"
mkdir -p "$TEST_DIR/bases/base2/proj1"
mkdir -p "$TEST_DIR/bases/base2/proj2"
mkdir -p "$TEST_DIR/config/pm/config"
mkdir -p "$TEST_DIR/config/pm/env"

# Source pm.sh
source "$(dirname "$0")/pm.sh"

echo "=== pm Unit Tests ==="
echo "Test directory: $TEST_DIR"
echo

# ============================================================================
# Test Suite 1: Initialization and Base Management
# ============================================================================
echo "Test Suite 1: Initialization and Base Management"
_test "pm init registers base" "pm i '$TEST_DIR/bases/base1' | grep -q 'base1'"
_test "default base file created" "[[ -f '$TEST_DIR/config/pm/default-base' ]]"
_test "base definition file exists" "[[ -f '$TEST_DIR/config/pm/config/base1.base' ]]"
_test "pm init adds second base" "pm i '$TEST_DIR/bases/base2' >/dev/null 2>&1"
_test "both base files exist" "[[ -f '$TEST_DIR/config/pm/config/base1.base' && -f '$TEST_DIR/config/pm/config/base2.base' ]]"

echo

# ============================================================================
# Test Suite 2: Base Switching
# ============================================================================
echo "Test Suite 2: Base Switching"
_test "pm base switches to base1" "pm b base1 2>&1 | grep -q 'switched to base'"
_test "pm base switches to base2" "pm b base2 >/dev/null 2>&1"
_test "PROJECT_BASE matches base2" "pm b base2 >/dev/null 2>&1 && [[ \"\$PROJECT_BASE\" == *'base2' ]]"

echo

# ============================================================================
# Test Suite 3: Project Management
# ============================================================================
echo "Test Suite 3: Project Management"
pm b base1 >/dev/null 2>&1  # Ensure we start in base1
_test "pm switch selects project" "pm s proj1 2>&1 | grep -q 'switched to project'"
_test "default project file created" "[[ -f '$TEST_DIR/config/pm/default-project-base1' ]]"
_test "pm switch to proj2" "pm s proj2 >/dev/null 2>&1"
_test "pm pwd shows correct path" "pm p 2>&1 | grep -q 'base1/proj2'"

echo

# ============================================================================
# Test Suite 4: Default Management
# ============================================================================
echo "Test Suite 4: Default Management"
_test "pm default set project" "pm d s proj1 2>&1 | grep -q 'default project set'"
_test "pm default get project" "pm d g 2>&1 | grep -q 'proj1'"

echo

# ============================================================================
# Test Suite 5: Env File Management
# ============================================================================
echo "Test Suite 5: Env File Management"
pm b base2 >/dev/null 2>&1  # Ensure we start in base2
pm s proj1  # Switch to proj1 in base2
echo 'export TEST_VAR=test_value' > "$TEST_DIR/config/pm/env/test.env"
echo 'export ANOTHER_VAR=another_value' > "$TEST_DIR/config/pm/env/another.env"
_test "pm env attach links env file" "pm env attach test.env 2>&1 | grep -q 'attached'"
_test "env association file created" "[[ -f '$TEST_DIR/config/pm/env-base2-proj1' ]]"
_test "pm env attach second file" "pm env attach another.env >/dev/null 2>&1"
_test "pm env detach removes file" "pm env detach test.env >/dev/null 2>&1 && ! grep -q 'test.env' '$TEST_DIR/config/pm/env-base2-proj1'"

echo

# ============================================================================
# Test Suite 6: Env File Auto-Sourcing
# ============================================================================
echo "Test Suite 6: Env File Auto-Sourcing"
pm env attach test.env  # Re-attach for testing
_test "pm switch executes without error" "pm s proj1 >/dev/null 2>&1"

echo

# ============================================================================
# Test Suite 7: File Operations
# ============================================================================
echo "Test Suite 7: File Operations"
pm b base2 >/dev/null 2>&1  # Ensure we start in base2
pm s proj1 >/dev/null 2>&1  # Ensure we're in proj1
mkdir -p "$TEST_DIR/bases/base2/proj1"
touch "$TEST_DIR/bases/base2/proj1/testfile.txt"
_test "pm ls lists files" "pm ls 2>&1 | grep -q 'testfile'"

echo

# ============================================================================
# Test Summary
# ============================================================================
echo "Test Results"
echo "Passed: \033[0;32m$PASS\033[0m"
echo "Failed: \033[0;31m$FAIL\033[0m"

if [[ $FAIL -eq 0 ]]; then
	echo "✓ All tests passed!"
	exit 0
else
	echo "✗ Some tests failed"
	exit 1
fi
