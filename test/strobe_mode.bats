#!/usr/bin/env bats
# Tests for strobe mode — visual effects, config, toggles, hook integration
# Coverage: acid-mode.sh strobe functions, config.sh, post-tool-use.sh, stop.sh

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
    cp "$BATS_TEST_DIRNAME/../hooks/acid-mode.sh" "$CL4UD3_HOME/hooks/"
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    chmod +x "$CL4UD3_HOME/hooks/acid-mode.sh"
    # Use local scope in tests for predictable PID path
    export _STROBE_SCOPE="local"
}

teardown() {
    rm -f /tmp/.cl4ud3-cr4ck-strobe-pid /tmp/.cl4ud3-cr4ck-strobe-pid-*
    _common_teardown
}

# ═══════════════════════════════════════════════════════════════════════════════
# Config Defaults
# ═══════════════════════════════════════════════════════════════════════════════

@test "config.sh: CL4UD3_STROBE_MODE config exists" {
    run grep 'CL4UD3_STROBE_MODE' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: strobe mode defaults to false" {
    run bash -c "source '$CL4UD3_HOME/config.sh'; echo \$CL4UD3_STROBE_MODE"
    assert_output "false"
}

@test "config.sh: _STROBE_SPEED config exists" {
    run grep '_STROBE_SPEED' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: _STROBE_SPEED defaults to 0.08" {
    run bash -c "source '$CL4UD3_HOME/config.sh'; echo \$_STROBE_SPEED"
    assert_output "0.08"
}

@test "config.sh: _STROBE_BURST_LEN defaults to 6" {
    run bash -c "source '$CL4UD3_HOME/config.sh'; echo \$_STROBE_BURST_LEN"
    assert_output "6"
}

@test "config.sh: _STROBE_PAUSE defaults to 0.4" {
    run bash -c "source '$CL4UD3_HOME/config.sh'; echo \$_STROBE_PAUSE"
    assert_output "0.4"
}

@test "config.sh: _STROBE_SCOPE defaults to global" {
    run bash -c "source '$CL4UD3_HOME/config.sh'; echo \$_STROBE_SCOPE"
    assert_output "global"
}

@test "config.sh: _ACID_SCOPE defaults to global" {
    run bash -c "source '$CL4UD3_HOME/config.sh'; echo \$_ACID_SCOPE"
    assert_output "global"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Function Definitions
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-mode.sh: defines _is_strobe_active function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _is_strobe_active"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _is_strobe_running function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _is_strobe_running"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _strobe_burst function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _strobe_burst"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _strobe_flicker function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _strobe_flicker"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _strobe_effect function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _strobe_effect"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _strobe_start_loop function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _strobe_start_loop"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _strobe_kill function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _strobe_kill"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _strobe_toggle function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _strobe_toggle"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _strobe_cleanup_on_exit function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _strobe_cleanup_on_exit"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _PF_STROBE variable" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; echo \$_PF_STROBE"
    assert_success
    assert_output --partial "cl4ud3-cr4ck-strobe-pid"
}

@test "acid-mode.sh: _PF_STROBE includes SID when scope=global" {
    run bash -c "
        _STROBE_SCOPE=global
        CL4UD3_SID=test123
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        echo \$_PF_STROBE
    "
    assert_output --partial "strobe-pid-test123"
}

@test "acid-mode.sh: _PF_STROBE has no SID when scope=local" {
    run bash -c "
        _STROBE_SCOPE=local
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        echo \$_PF_STROBE
    "
    assert_output "/tmp/.cl4ud3-cr4ck-strobe-pid"
}

# ═══════════════════════════════════════════════════════════════════════════════
# _is_strobe_active
# ═══════════════════════════════════════════════════════════════════════════════

@test "_is_strobe_active: returns 0 when CL4UD3_STROBE_MODE=true" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        CL4UD3_STROBE_MODE=true
        _is_strobe_active && echo 'active' || echo 'inactive'
    "
    assert_output "active"
}

@test "_is_strobe_active: returns 1 when CL4UD3_STROBE_MODE=false" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        CL4UD3_STROBE_MODE=false
        _is_strobe_active && echo 'active' || echo 'inactive'
    "
    assert_output "inactive"
}

@test "_is_strobe_active: returns 1 when CL4UD3_STROBE_MODE unset" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        unset CL4UD3_STROBE_MODE
        _is_strobe_active && echo 'active' || echo 'inactive'
    "
    assert_output "inactive"
}

@test "_is_strobe_active: returns 1 for non-true values" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        CL4UD3_STROBE_MODE=yes
        _is_strobe_active && echo 'active' || echo 'inactive'
    "
    assert_output "inactive"
}

# ═══════════════════════════════════════════════════════════════════════════════
# _is_strobe_running
# ═══════════════════════════════════════════════════════════════════════════════

@test "_is_strobe_running: returns 1 when no pidfile" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid
        _is_strobe_running && echo 'running' || echo 'stopped'
    "
    assert_output "stopped"
}

@test "_is_strobe_running: returns 1 when pidfile has dead pid" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        echo 99999 > /tmp/.cl4ud3-cr4ck-strobe-pid
        _is_strobe_running && echo 'running' || echo 'stopped'
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid
    "
    assert_output "stopped"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Visual Functions — /dev/tty Guard
# ═══════════════════════════════════════════════════════════════════════════════

@test "_strobe_burst: does not crash without tty" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; _strobe_burst"
    assert_success
}

@test "_strobe_flicker: does not crash without tty" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; _strobe_flicker"
    assert_success
}

@test "_strobe_effect: does not crash without tty" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; _strobe_effect"
    assert_success
}

@test "_strobe_cleanup_on_exit: does not crash without tty" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; _strobe_cleanup_on_exit"
    assert_success
}

# ═══════════════════════════════════════════════════════════════════════════════
# Implementation Details — Burst
# ═══════════════════════════════════════════════════════════════════════════════

@test "strobe burst: uses DECSCNM reverse video escape" {
    run grep -A15 '_strobe_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '\\033[?5h'
    assert_output --partial '\\033[?5l'
}

@test "strobe burst: uses bright white foreground (97m)" {
    run grep -A15 '_strobe_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '97m'
}

@test "strobe burst: uses bright white background (107m)" {
    run grep -A15 '_strobe_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '107m'
}

@test "strobe burst: restores clean terminal state" {
    run grep -A20 '_strobe_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '\\033[0m'
}

@test "strobe burst: guards /dev/tty writable" {
    run grep -A3 '_strobe_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '! -w /dev/tty'
}

@test "strobe burst: reads _STROBE_SPEED" {
    run grep -A10 '_strobe_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_STROBE_SPEED'
}

@test "strobe burst: reads _STROBE_BURST_LEN" {
    run grep -A10 '_strobe_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_STROBE_BURST_LEN'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Implementation Details — Flicker
# ═══════════════════════════════════════════════════════════════════════════════

@test "strobe flicker: uses solid block bar" {
    run grep -A15 '_strobe_flicker()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '█'
}

@test "strobe flicker: erases lines with cursor-up" {
    run grep -A20 '_strobe_flicker()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '\\033[1A'
}

@test "strobe flicker: guards /dev/tty writable" {
    run grep -A3 '_strobe_flicker()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '! -w /dev/tty'
}

@test "strobe flicker: uses bright white on white (97;107m)" {
    run grep -A15 '_strobe_flicker()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '97;107m'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Implementation Details — Effect Dispatcher
# ═══════════════════════════════════════════════════════════════════════════════

@test "strobe effect: has 3 styles" {
    run grep -A10 '_strobe_effect()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial 'RANDOM % 3'
}

@test "strobe effect: dispatches _strobe_burst" {
    run grep -A12 '_strobe_effect()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_strobe_burst'
}

@test "strobe effect: dispatches _strobe_flicker" {
    run grep -A12 '_strobe_effect()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_strobe_flicker'
}

@test "strobe effect: style 2 combines burst + flicker" {
    run grep -A12 '_strobe_effect()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_strobe_burst; _strobe_flicker'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Background Loop
# ═══════════════════════════════════════════════════════════════════════════════

@test "strobe loop: uses _STROBE_SPEED" {
    run grep -A30 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_STROBE_SPEED'
}

@test "strobe loop: uses _STROBE_BURST_LEN" {
    run grep -A30 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_STROBE_BURST_LEN'
}

@test "strobe loop: uses _STROBE_PAUSE" {
    run grep -A40 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_STROBE_PAUSE'
}

@test "strobe loop: checks pidfile for termination" {
    run grep -A40 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial 'my_pidfile'
}

@test "strobe loop: traps HUP to survive parent exit" {
    run grep -A25 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "trap '' HUP"
}

@test "strobe loop: disowns background process" {
    run grep -A65 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial 'disown'
}

@test "strobe loop: writes PID to _PF_STROBE" {
    run grep -A65 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_PF_STROBE'
}

@test "strobe loop: writes to /dev/tty" {
    run grep -A50 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '/dev/tty'
}

@test "strobe loop: returns 0 when strobe not active" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        CL4UD3_STROBE_MODE=false
        _strobe_start_loop
        echo \$?
    "
    assert_output "0"
}

@test "strobe loop: skips if already running" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        CL4UD3_STROBE_MODE=true
        # Fake running strobe with our own PID
        echo \$\$ > /tmp/.cl4ud3-cr4ck-strobe-pid
        _strobe_start_loop
        echo \$?
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid
    "
    assert_output "0"
}

@test "strobe loop: has random white bar flicker between bursts" {
    run grep -A55 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '████'
}

@test "strobe loop: has jitter on pause duration" {
    run grep -A55 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial 'jitter'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Acid Mode Interaction
# ═══════════════════════════════════════════════════════════════════════════════

@test "strobe loop: checks _is_acid_active for color mixing" {
    run grep -A70 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_is_acid_active'
}

@test "strobe loop: uses _ACID_COLORS when acid active" {
    run grep -A70 '_strobe_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_ACID_COLORS'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Cleanup + Terminal Restore
# ═══════════════════════════════════════════════════════════════════════════════

@test "strobe cleanup: restores DECSCNM off" {
    run grep -A3 '_strobe_cleanup_on_exit()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '\\033[?5l'
}

@test "strobe cleanup: resets all attributes" {
    run grep -A3 '_strobe_cleanup_on_exit()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '\\033[0m'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Toggle
# ═══════════════════════════════════════════════════════════════════════════════

@test "_strobe_toggle: outputs ON message when starting" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        CL4UD3_STROBE_MODE=false
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid
        _strobe_toggle 2>/dev/null
    "
    assert_output --partial "strobe: ON"
}

@test "_strobe_toggle: outputs OFF message when stopping" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        echo \$\$ > /tmp/.cl4ud3-cr4ck-strobe-pid
        _strobe_toggle 2>/dev/null
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid
    "
    assert_output --partial "strobe: OFF"
}

@test "_strobe_toggle: sets CL4UD3_STROBE_MODE=true when enabling" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        CL4UD3_STROBE_MODE=false
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid
        _strobe_toggle 2>/dev/null
        echo \$CL4UD3_STROBE_MODE
    "
    assert_output --partial "true"
}

@test "_strobe_toggle: sets CL4UD3_STROBE_MODE=false when disabling" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        echo \$\$ > /tmp/.cl4ud3-cr4ck-strobe-pid
        _strobe_toggle 2>/dev/null
        echo \$CL4UD3_STROBE_MODE
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid
    "
    assert_output --partial "false"
}

@test "_strobe_toggle: exports CL4UD3_STROBE_MODE" {
    run grep -A10 '_strobe_toggle()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial 'export CL4UD3_STROBE_MODE'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Kill
# ═══════════════════════════════════════════════════════════════════════════════

@test "_strobe_kill: removes pidfile" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        echo 99999 > /tmp/.cl4ud3-cr4ck-strobe-pid
        _strobe_kill 2>/dev/null
        [ ! -f /tmp/.cl4ud3-cr4ck-strobe-pid ] && echo 'cleaned' || echo 'still there'
    "
    assert_output "cleaned"
}

@test "acid-mode.sh: defines _strobe_kill_all function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _strobe_kill_all"
    assert_success
    assert_output --partial "function"
}

@test "_strobe_kill_all: removes all strobe pidfiles" {
    run bash -c "
        _STROBE_SCOPE=local
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        echo 99999 > /tmp/.cl4ud3-cr4ck-strobe-pid
        echo 99998 > /tmp/.cl4ud3-cr4ck-strobe-pid-fake1
        echo 99997 > /tmp/.cl4ud3-cr4ck-strobe-pid-fake2
        _strobe_kill_all 2>/dev/null
        ls /tmp/.cl4ud3-cr4ck-strobe-pid* 2>/dev/null || echo 'all cleaned'
    "
    assert_output "all cleaned"
}

@test "_strobe_kill_all: safe when no strobe running" {
    run bash -c "
        _STROBE_SCOPE=local
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid*
        _strobe_kill_all 2>/dev/null
        echo 'ok'
    "
    assert_output "ok"
}

@test "_strobe_toggle: uses _strobe_kill_all when disabling" {
    run grep -A10 '_strobe_toggle()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_strobe_kill_all'
}

@test "_strobe_kill: safe when no strobe running" {
    run bash -c "
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        rm -f /tmp/.cl4ud3-cr4ck-strobe-pid
        _strobe_kill 2>/dev/null
        echo 'ok'
    "
    assert_output "ok"
}

@test "_strobe_kill: restores terminal state" {
    run grep -A10 '_strobe_kill()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '/dev/tty'
    assert_output --partial '033[0m'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Hook Integration
# ═══════════════════════════════════════════════════════════════════════════════

@test "post-tool-use.sh: checks _is_strobe_active" {
    run grep 'strobe' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
    assert_output --partial '_is_strobe_active'
}

@test "post-tool-use.sh: calls _strobe_start_loop" {
    run grep 'strobe' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
    assert_output --partial '_strobe_start_loop'
}

@test "stop.sh: calls _strobe_kill" {
    run grep 'strobe_kill' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: sources acid-mode.sh for strobe cleanup" {
    run grep -B2 'strobe_kill' "$CL4UD3_HOME/hooks/stop.sh"
    assert_output --partial 'acid-mode.sh'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Syntax
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# Acid-Strobe Auto-Link
# ═══════════════════════════════════════════════════════════════════════════════

@test "config.sh: _ACID_STROBE_ENABLED config exists" {
    run grep '_ACID_STROBE_ENABLED' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "acid-mode.sh: _acid_start_loop checks _ACID_STROBE_ENABLED" {
    run grep -A15 '_acid_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_ACID_STROBE_ENABLED'
}

@test "acid-mode.sh: _acid_start_loop auto-starts strobe when linked" {
    run grep -A15 '_acid_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_strobe_start_loop'
}

# ═══════════════════════════════════════════════════════════════════════════════
# play-midi.sh Cleanup
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: cleanup_all_stale_files includes strobe PIDs" {
    run grep -A20 'cleanup_all_stale_files()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "strobe-pid"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Syntax
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-mode.sh: syntax check passes with strobe code" {
    run bash -n "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: sourcing with strobe code does not produce output" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh' 2>&1"
    assert_success
    assert_output ""
}

@test "acid-mode.sh: sourcing with strobe code does not exit shell" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; echo 'still alive'"
    assert_success
    assert_output "still alive"
}
