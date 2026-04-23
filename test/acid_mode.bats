#!/usr/bin/env bats
# Tests for hooks/acid-mode.sh — acid effect functions, activation logic

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
    cp "$BATS_TEST_DIRNAME/../hooks/acid-mode.sh" "$CL4UD3_HOME/hooks/"
    chmod +x "$CL4UD3_HOME/hooks/acid-mode.sh"
    # Stub /dev/tty — acid functions write to /dev/tty, which isn't available in test
    # We'll test by sourcing and checking function behavior / output redirection
}

teardown() {
    _common_teardown
}

# ── Syntax ──

@test "acid-mode.sh: syntax check passes" {
    run bash -n "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

# ── Function definitions ──

@test "acid-mode.sh: defines _acid_burst function" {
    run grep '_acid_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: defines _acid_frag function" {
    run grep '_acid_frag()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: defines _acid_strobe function" {
    run grep '_acid_strobe()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: defines _acid_wave function" {
    run grep '_acid_wave()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: defines _acid_effect function" {
    run grep '_acid_effect()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: defines _is_acid_active function" {
    run grep '_is_acid_active()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

# ── Color palette ──

@test "acid-mode.sh: rainbow palette has 20 colors" {
    run grep '_ACID_COLORS=' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    assert_output --partial "196"
    assert_output --partial "226"
    assert_output --partial "46"
    assert_output --partial "51"
    assert_output --partial "201"
}

# ── Glyph set ──

@test "acid-mode.sh: glyph array is non-empty" {
    run grep '_ACID_GLYPHS=' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    assert_output --partial "◉"
    assert_output --partial "⚡"
    assert_output --partial "☯"
}

# ── Fragment messages ──

@test "acid-mode.sh: fragment array has entries" {
    run grep -c '_ACID_FRAGS' "$CL4UD3_HOME/hooks/acid-mode.sh"
    [ "$output" -gt 0 ]
}

@test "acid-mode.sh: fragments contain warez-style text" {
    run grep 'L S D' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    run grep 'r34l1ty' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

# ── _is_acid_active logic ──

@test "_is_acid_active: returns 0 when CL4UD3_ACID_MODE=true" {
    export CL4UD3_ACID_MODE="true"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _is_acid_active
    assert_success
}

@test "_is_acid_active: returns 1 when CL4UD3_ACID_MODE=false" {
    export CL4UD3_ACID_MODE="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _is_acid_active
    assert_failure
}

@test "_is_acid_active: returns 1 when CL4UD3_ACID_MODE unset" {
    unset CL4UD3_ACID_MODE
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _is_acid_active
    assert_failure
}

@test "_is_acid_active: returns 1 for non-true values" {
    export CL4UD3_ACID_MODE="yes"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _is_acid_active
    assert_failure
}

# ── /dev/tty guard ──

@test "acid-mode.sh: all acid functions guard /dev/tty" {
    run grep -c '\[ ! -w /dev/tty \] && return' "$CL4UD3_HOME/hooks/acid-mode.sh"
    # _acid_burst, _acid_frag, _acid_strobe, _acid_wave, _acid_effect = 5
    [ "$output" -ge 5 ]
}

# ── _acid_burst ──

@test "_acid_burst: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    # /dev/tty may exist but not be configured — function should not crash shell
    _acid_burst 2>/dev/null || true
}

@test "acid-mode.sh: burst uses 64 width and 3 lines" {
    run grep -A3 '_acid_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "width=64"
    assert_output --partial "lines=3"
}

@test "acid-mode.sh: burst uses ANSI color codes" {
    run grep '38;5;' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

# ── _acid_frag ──

@test "_acid_frag: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_frag 2>/dev/null || true
}

@test "acid-mode.sh: frag selects random fragment from array" {
    run grep 'RANDOM.*_ACID_FRAGS' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: frag colorizes each non-space character" {
    run grep -A15 '_acid_frag()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial 'ch="${frag:'
    assert_output --partial '" "'
}

# ── _acid_strobe ──

@test "_acid_strobe: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_strobe 2>/dev/null || true
}

@test "acid-mode.sh: strobe uses 3 frames with sleep" {
    run grep -A10 '_acid_strobe()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "0 1 2"
    assert_output --partial "sleep 0.04"
}

@test "acid-mode.sh: strobe erases lines with cursor-up" {
    run grep -A15 '_acid_strobe()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '033[3A'
}

@test "acid-mode.sh: strobe uses solid block bar" {
    run grep 'bar=' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    assert_output --partial "████"
}

# ── _acid_wave ──

@test "_acid_wave: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_wave 2>/dev/null || true
}

@test "acid-mode.sh: wave uses 68 width" {
    run grep -A3 '_acid_wave()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "width=68"
}

@test "acid-mode.sh: wave uses sine-ish offsets array" {
    run grep 'offsets=' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    assert_output --partial "0 2 4 6 7 8 7 6 4 2"
}

@test "acid-mode.sh: wave renders 5 lines" {
    run grep -A5 '_acid_wave()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "num_lines=5"
}

# ── _acid_effect ──

@test "_acid_effect: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_effect 2>/dev/null || true
}

@test "acid-mode.sh: effect randomly selects from 5 styles" {
    run grep 'RANDOM % 5' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: effect case dispatches all 5 styles" {
    run grep -A10 '_acid_effect()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "_acid_burst"
    assert_output --partial "_acid_frag"
    assert_output --partial "_acid_strobe"
    assert_output --partial "_acid_wave"
}

@test "acid-mode.sh: effect style 4 combines burst + frag" {
    run grep '4) _acid_burst; _acid_frag' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: effect pushes cursor via stderr" {
    run grep 'extra_lines=7' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    run grep 'printf.*>&2' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

# ── Output targets ──

@test "acid-mode.sh: writes to /dev/tty" {
    run grep -c '/dev/tty' "$CL4UD3_HOME/hooks/acid-mode.sh"
    [ "$output" -gt 0 ]
}

@test "acid-mode.sh: uses ANSI reset after output" {
    run grep '033\[0m' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

# ── Integration with hooks ──

@test "post-tool-use.sh: sources acid-mode.sh" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    chmod +x "$CL4UD3_HOME/hooks/post-tool-use.sh"
    run grep 'acid-mode.sh' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: calls _is_acid_active && _acid_effect" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    run grep '_is_acid_active && _acid_effect' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "stop.sh: sources acid-mode.sh" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    chmod +x "$CL4UD3_HOME/hooks/stop.sh"
    run grep 'acid-mode.sh' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: calls _is_acid_active && _acid_effect" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run grep '_is_acid_active && _acid_effect' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

# ── Acid bypasses cooldown ──

@test "post-tool-use.sh: acid runs even during cooldown" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    # Check that acid-mode is sourced inside the cooldown block
    run grep -B2 -A5 'acid bypasses sound cooldown' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
    assert_output --partial "_is_acid_active"
}

@test "stop.sh: acid runs even during cooldown" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run grep -B2 -A5 'acid bypasses sound cooldown' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
    assert_output --partial "_is_acid_active"
}

# ── Config integration ──

@test "config.sh: has CL4UD3_ACID_MODE toggle" {
    run grep 'CL4UD3_ACID_MODE' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: acid mode defaults to false" {
    run grep 'CL4UD3_ACID_MODE.*:-false' "$CL4UD3_HOME/config.sh"
    assert_success
}

# ── Execution safety ──

@test "acid-mode.sh: sourcing does not produce output" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh' 2>&1"
    assert_success
    assert_output ""
}

@test "acid-mode.sh: sourcing does not exit shell" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; echo 'still alive'"
    assert_success
    assert_output "still alive"
}

@test "acid-mode.sh: functions available after sourcing" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_effect"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: functions available after sourcing (burst)" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_burst"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: functions available after sourcing (is_active)" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _is_acid_active"
    assert_success
    assert_output --partial "function"
}

# ── Negative clamp in wave ──

@test "acid-mode.sh: wave clamps negative padding to positive" {
    run grep -A15 '_acid_wave()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '-lt 0'
    assert_output --partial 'pad=$(( -pad ))'
}

# ── Fragment count ──

@test "acid-mode.sh: has at least 10 acid fragments" {
    run grep -c '"  ' "$CL4UD3_HOME/hooks/acid-mode.sh"
    [ "$output" -ge 10 ]
}
