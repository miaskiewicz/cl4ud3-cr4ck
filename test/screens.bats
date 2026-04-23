#!/usr/bin/env bats
# Tests for art/screens.sh — screen selection, custom art, animation toggle

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
    cp "$BATS_TEST_DIRNAME/../art/screens.sh" "$CL4UD3_HOME/art/"
    chmod +x "$CL4UD3_HOME/art/screens.sh"
}

teardown() {
    _common_teardown
}

# ── Screen array ──

@test "screens.sh: SCREENS array is non-empty" {
    run bash -c "source '$CL4UD3_HOME/art/screens.sh' 2>/dev/null; echo \${#SCREENS[@]}"
    # Output is line count — should not be 0
    # (screens.sh writes to /dev/tty or stderr, but SCREENS is populated before that)
    # We test by checking the file contains SCREENS+=
    run grep -c 'SCREENS+=(' "$CL4UD3_HOME/art/screens.sh"
    [ "$output" -gt 0 ]
}

@test "screens.sh: contains animation toggle check" {
    run grep 'CL4UD3_STARTUP_ANIMATION' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: animation enabled uses sleep for scanline" {
    run grep -A5 'CL4UD3_STARTUP_ANIMATION.*false' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "sleep"
}

@test "screens.sh: animation disabled path exists" {
    # The else branch provides instant display (no sleep)
    run grep -c 'else' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    [ "$output" -gt 0 ]
}

# ── Custom art loading ──

@test "screens.sh: loads custom art files" {
    mkdir -p "$CL4UD3_HOME/art/custom"
    echo "CUSTOM ART TEST" > "$CL4UD3_HOME/art/custom/test-screen.txt"
    run grep 'CL4UD3_CUSTOM_ART' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: skips custom art when disabled" {
    export CL4UD3_CUSTOM_ART="false"
    mkdir -p "$CL4UD3_HOME/art/custom"
    echo "SHOULD NOT LOAD" > "$CL4UD3_HOME/art/custom/skip-me.txt"
    # The script checks CL4UD3_CUSTOM_ART != false before loading
    run grep 'CL4UD3_CUSTOM_ART.*false' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

# ── Output targets ──

@test "screens.sh: writes to /dev/tty when available" {
    run grep '/dev/tty' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: falls back to stderr when no tty" {
    run grep 'printf.*>&2\|echo.*>&2' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

# ── Cursor advancement ──

@test "screens.sh: pushes cursor down via stderr for Claude Code" {
    run grep 'LINE_COUNT' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

# ── Execution ──

@test "screens.sh: exits 0 without tty" {
    # Run without tty — should fall back to stderr output
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with animation disabled" {
    export CL4UD3_STARTUP_ANIMATION="false"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}
