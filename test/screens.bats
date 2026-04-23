#!/usr/bin/env bats
# Tests for art/screens.sh — screen selection, custom art, animation styles

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
    run grep -c 'SCREENS+=(' "$CL4UD3_HOME/art/screens.sh"
    [ "$output" -gt 0 ]
}

@test "screens.sh: syntax check passes" {
    run bash -n "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

# ── Config toggles ──

@test "config.sh: has CL4UD3_ANIM_SCANLINE toggle" {
    run grep 'CL4UD3_ANIM_SCANLINE' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: has CL4UD3_ANIM_FADE toggle" {
    run grep 'CL4UD3_ANIM_FADE' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: has CL4UD3_ANIM_RAINBOW toggle" {
    run grep 'CL4UD3_ANIM_RAINBOW' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: has CL4UD3_ANIM_MATRIX toggle" {
    run grep 'CL4UD3_ANIM_MATRIX' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: has CL4UD3_ANIM_GLITCH toggle" {
    run grep 'CL4UD3_ANIM_GLITCH' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: scanline enabled by default" {
    run grep 'CL4UD3_ANIM_SCANLINE.*:-true' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: fade disabled by default" {
    run grep 'CL4UD3_ANIM_FADE.*:-false' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: rainbow disabled by default" {
    run grep 'CL4UD3_ANIM_RAINBOW.*:-false' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: matrix disabled by default" {
    run grep 'CL4UD3_ANIM_MATRIX.*:-false' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: glitch disabled by default" {
    run grep 'CL4UD3_ANIM_GLITCH.*:-false' "$CL4UD3_HOME/config.sh"
    assert_success
}

# ── Animation functions exist ──

@test "screens.sh: defines _anim_scanline function" {
    run grep '_anim_scanline()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: defines _anim_fade function" {
    run grep '_anim_fade()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: defines _anim_rainbow function" {
    run grep '_anim_rainbow()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: defines _anim_matrix function" {
    run grep '_anim_matrix()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: defines _anim_glitch function" {
    run grep '_anim_glitch()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

# ── Animation selection logic ──

@test "screens.sh: builds _ANIMS array from enabled toggles" {
    run grep '_ANIMS+=(scanline)' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    run grep '_ANIMS+=(fade)' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    run grep '_ANIMS+=(rainbow)' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    run grep '_ANIMS+=(matrix)' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    run grep '_ANIMS+=(glitch)' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: random selection from _ANIMS array" {
    run grep 'RANDOM.*_ANIMS' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: case dispatch for all animation types" {
    run grep -E 'scanline\)|fade\)|rainbow\)|matrix\)|glitch\)' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "scanline)"
    assert_output --partial "fade)"
    assert_output --partial "rainbow)"
    assert_output --partial "matrix)"
    assert_output --partial "glitch)"
}

# ── Backward compatibility ──

@test "screens.sh: CL4UD3_STARTUP_ANIMATION=false skips all animations" {
    run grep 'CL4UD3_STARTUP_ANIMATION.*false' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    run grep '_SKIP_ALL_ANIMS' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: _SKIP_ALL_ANIMS prevents building _ANIMS" {
    run grep -A2 '_SKIP_ALL_ANIMS.*true' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

# ── Instant display fallback ──

@test "screens.sh: instant display when no animations enabled" {
    # When _ANIMS is empty, falls through to echo -e "$ART"
    run grep -A2 '#.*No animations enabled' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "echo -e"
}

# ── Scanline animation ──

@test "screens.sh: scanline uses sleep 0.03 for CRT effect" {
    run grep -A5 '_anim_scanline()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "sleep 0.03"
}

@test "screens.sh: scanline reads lines with IFS= read" {
    run grep -A5 '_anim_scanline()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "IFS= read -r"
}

# ── Fade animation ──

@test "screens.sh: fade uses dark color stages 232 240 245" {
    run grep -A3 'fade_colors=' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "232"
    assert_output --partial "240"
    assert_output --partial "245"
}

@test "screens.sh: fade replaces ANSI color codes with fade color" {
    run grep 'sed.*38;5;.*m.*38;5;' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: fade uses cursor-up to overwrite frames" {
    run grep '033\[.*A.*dev/tty' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

# ── Rainbow animation ──

@test "screens.sh: rainbow has color palette array" {
    run grep 'rainbow=(' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "196"
    assert_output --partial "208"
    assert_output --partial "46"
    assert_output --partial "51"
}

@test "screens.sh: rainbow cycles through frames" {
    run grep -A15 '_anim_rainbow()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "num_frames"
}

# ── Matrix animation ──

@test "screens.sh: matrix uses random green characters" {
    run grep -A20 '_anim_matrix()' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "chars="
}

@test "screens.sh: matrix generates green-shaded output" {
    run grep 'shade.*28.*RANDOM' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: matrix strips ANSI codes for dimension matching" {
    run grep "sed.*x1b" "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

# ── Glitch animation ──

@test "screens.sh: glitch uses corruption percentages" {
    run grep 'corruption_pcts=' "$CL4UD3_HOME/art/screens.sh"
    assert_success
    assert_output --partial "80"
    assert_output --partial "50"
    assert_output --partial "25"
    assert_output --partial "8"
}

@test "screens.sh: glitch preserves ANSI escape sequences" {
    run grep 'in_escape' "$CL4UD3_HOME/art/screens.sh"
    assert_success
}

@test "screens.sh: glitch uses special characters for corruption" {
    run grep 'glitch_chars=' "$CL4UD3_HOME/art/screens.sh"
    assert_success
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
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with all animations disabled" {
    export CL4UD3_ANIM_SCANLINE="false"
    export CL4UD3_ANIM_FADE="false"
    export CL4UD3_ANIM_RAINBOW="false"
    export CL4UD3_ANIM_MATRIX="false"
    export CL4UD3_ANIM_GLITCH="false"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with backward compat CL4UD3_STARTUP_ANIMATION=false" {
    export CL4UD3_STARTUP_ANIMATION="false"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with only scanline enabled" {
    export CL4UD3_ANIM_SCANLINE="true"
    export CL4UD3_ANIM_FADE="false"
    export CL4UD3_ANIM_RAINBOW="false"
    export CL4UD3_ANIM_MATRIX="false"
    export CL4UD3_ANIM_GLITCH="false"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with only fade enabled" {
    export CL4UD3_ANIM_SCANLINE="false"
    export CL4UD3_ANIM_FADE="true"
    export CL4UD3_ANIM_RAINBOW="false"
    export CL4UD3_ANIM_MATRIX="false"
    export CL4UD3_ANIM_GLITCH="false"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with only rainbow enabled" {
    export CL4UD3_ANIM_SCANLINE="false"
    export CL4UD3_ANIM_FADE="false"
    export CL4UD3_ANIM_RAINBOW="true"
    export CL4UD3_ANIM_MATRIX="false"
    export CL4UD3_ANIM_GLITCH="false"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with only matrix enabled" {
    export CL4UD3_ANIM_SCANLINE="false"
    export CL4UD3_ANIM_FADE="false"
    export CL4UD3_ANIM_RAINBOW="false"
    export CL4UD3_ANIM_MATRIX="true"
    export CL4UD3_ANIM_GLITCH="false"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with only glitch enabled" {
    export CL4UD3_ANIM_SCANLINE="false"
    export CL4UD3_ANIM_FADE="false"
    export CL4UD3_ANIM_RAINBOW="false"
    export CL4UD3_ANIM_MATRIX="false"
    export CL4UD3_ANIM_GLITCH="true"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

@test "screens.sh: exits 0 with all animations enabled" {
    export CL4UD3_ANIM_SCANLINE="true"
    export CL4UD3_ANIM_FADE="true"
    export CL4UD3_ANIM_RAINBOW="true"
    export CL4UD3_ANIM_MATRIX="true"
    export CL4UD3_ANIM_GLITCH="true"
    run bash "$CL4UD3_HOME/art/screens.sh" 2>/dev/null
    assert_success
}

# ── install.sh timeout ──

@test "install.sh: SessionStart timeout is 15 seconds" {
    run grep -A10 'SessionStart' "$BATS_TEST_DIRNAME/../install.sh"
    assert_success
    assert_output --partial '"timeout": 15'
}
