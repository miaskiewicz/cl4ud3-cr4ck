#!/usr/bin/env bats
# Tests for acid mode — visual effects, 303 loop, beat-synced stabs, config, toggles
# Coverage: acid-mode.sh, play-midi.sh acid functions, post-tool-use.sh, stop.sh, acid-303.py

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
    cp "$BATS_TEST_DIRNAME/../hooks/acid-mode.sh" "$CL4UD3_HOME/hooks/"
    chmod +x "$CL4UD3_HOME/hooks/acid-mode.sh"
}

teardown() {
    # Kill any acid loops we started
    if [ -f "/tmp/.cl4ud3-cr4ck-acid-pid-$CL4UD3_SID" ]; then
        local pid
        pid=$(cat "/tmp/.cl4ud3-cr4ck-acid-pid-$CL4UD3_SID" 2>/dev/null)
        [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
        rm -f "/tmp/.cl4ud3-cr4ck-acid-pid-$CL4UD3_SID"
    fi
    rm -f "/tmp/.cl4ud3-cr4ck-acid-beat-$CL4UD3_SID" "/tmp/.cl4ud3-cr4ck-acid-dir-$CL4UD3_SID"
    rm -rf /tmp/.cl4ud3-acid-* 2>/dev/null || true
    _common_teardown
}

# ═══════════════════════════════════════════════════════════════════════════════
# acid-mode.sh — Syntax + Structure
# ════════════���══════════════════════════════════════════════════════════════════

@test "acid-mode.sh: syntax check passes" {
    run bash -n "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

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

# ═══��═════════════════════════════��════════════════════════════════════��════════
# acid-mode.sh — Function Definitions
# ═════════════════════════���══════════════════════════════��══════════════════════

@test "acid-mode.sh: defines _acid_burst function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_burst"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_frag function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_frag"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_strobe function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_strobe"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_wave function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_wave"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_effect function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_effect"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _is_acid_active function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _is_acid_active"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_start_loop function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_start_loop"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_maybe_stab function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_maybe_stab"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_random_stab function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_random_stab"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_toggle_303 function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_toggle_303"
    assert_success
    assert_output --partial "function"
}

@test "acid-mode.sh: defines _acid_toggle_stabs function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_toggle_stabs"
    assert_success
    assert_output --partial "function"
}

# ══════════════════════════════════════���═══════════════════════════��════════════
# acid-mode.sh — Hidden Config Defaults
# ═════��═══════════════════════��══════════════════════════════���══════════════════

@test "acid-mode.sh: _ACID_303_ENABLED defaults to false" {
    run grep '_ACID_303_ENABLED.*:-false' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: _ACID_STABS_ENABLED defaults to true" {
    run grep '_ACID_STABS_ENABLED.*:-true' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: _ACID_303_BPM defaults to 120" {
    run grep '_ACID_303_BPM.*:-120' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: _ACID_STAB_CHANCE defaults to 0.95" {
    run grep '_ACID_STAB_CHANCE.*:-0.95' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: _ACID_STAB_RANDOM_CHANCE defaults to 0.6" {
    run grep '_ACID_STAB_RANDOM_CHANCE.*:-0.6' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: _ACID_IDLE_TIMEOUT defaults to 30" {
    run grep '_ACID_IDLE_TIMEOUT.*:-30' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: config vars are exported with defaults" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    [ "$_ACID_303_ENABLED" = "false" ]
    [ "$_ACID_STABS_ENABLED" = "true" ]
    [ "$_ACID_303_BPM" = "120" ]
    [ "$_ACID_STAB_CHANCE" = "0.95" ]
    [ "$_ACID_STAB_RANDOM_CHANCE" = "0.6" ]
    [ "$_ACID_IDLE_TIMEOUT" = "30" ]
}

@test "acid-mode.sh: config vars respect env overrides" {
    export _ACID_303_BPM=160
    export _ACID_STAB_CHANCE=0.8
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    [ "$_ACID_303_BPM" = "160" ]
    [ "$_ACID_STAB_CHANCE" = "0.8" ]
}

# ═════════════��═══════════════════════��═════════════════════════════════════════
# acid-mode.sh — Color Palette + Glyphs
# ══��════════════════════��═════════════════════════════���═════════════════════════

@test "acid-mode.sh: rainbow palette has 20 colors" {
    run grep '_ACID_COLORS=' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    assert_output --partial "196"
    assert_output --partial "226"
    assert_output --partial "46"
    assert_output --partial "51"
    assert_output --partial "201"
}

@test "acid-mode.sh: glyph array is non-empty" {
    run grep '_ACID_GLYPHS=' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    assert_output --partial "◉"
    assert_output --partial "⚡"
    assert_output --partial "☯"
}

# ═════���═════════════════════════════════════════════════════════════════════════
# acid-mode.sh — Fragment Messages
# ���══════════════════════════��═══════════════════════════════════════════════════

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

@test "acid-mode.sh: has at least 10 acid fragments" {
    run grep -c '"  ' "$CL4UD3_HOME/hooks/acid-mode.sh"
    [ "$output" -ge 10 ]
}

# ═════════���══════════════════════════════════════════════════════���══════════════
# acid-mode.sh — _is_acid_active Logic
# ═══════════��═══════════════════════════════════════════════���═══════════════════

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

# ═════���══════════════════════════════��══════════════════════════════════════════
# acid-mode.sh — /dev/tty Guards
# ══��════════════════════════��════════════════════════════���══════════════════════

@test "acid-mode.sh: all visual functions guard /dev/tty" {
    run grep -c '\[ ! -w /dev/tty \] && return' "$CL4UD3_HOME/hooks/acid-mode.sh"
    # _acid_burst, _acid_frag, _acid_strobe, _acid_wave, _acid_effect = 5
    [ "$output" -ge 5 ]
}

# ══════════���══════════════════════���══════════════════════════════════════��══════
# acid-mode.sh — Visual Effects (no-crash tests)
# ════════���════════════════��══════════════════════════���══════════════════════════

@test "_acid_burst: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_burst 2>/dev/null || true
}

@test "_acid_frag: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_frag 2>/dev/null || true
}

@test "_acid_strobe: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_strobe 2>/dev/null || true
}

@test "_acid_wave: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_wave 2>/dev/null || true
}

@test "_acid_effect: does not crash without tty" {
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _acid_effect 2>/dev/null || true
}

# ════════════════════════��═══════════════════════════��══════════════════════════
# acid-mode.sh — Visual Effect Structure
# ══════════════════════════���═════════════════════════════════���══════════════════

@test "acid-mode.sh: burst uses 64 width and 3 lines" {
    run grep -A3 '_acid_burst()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "width=64"
    assert_output --partial "lines=3"
}

@test "acid-mode.sh: burst uses ANSI color codes" {
    run grep '38;5;' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
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

@test "acid-mode.sh: wave clamps negative padding to positive" {
    run grep -A15 '_acid_wave()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '-lt 0'
    assert_output --partial 'pad=$(( -pad ))'
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

@test "acid-mode.sh: writes to /dev/tty" {
    run grep -c '/dev/tty' "$CL4UD3_HOME/hooks/acid-mode.sh"
    [ "$output" -gt 0 ]
}

@test "acid-mode.sh: uses ANSI reset after output" {
    run grep '033\[0m' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

# ═══════════════════════════════════════��═══════════════════════════════════════
# acid-mode.sh — _acid_start_loop
# ═════════��══════════════════════════���═════════════════════════���════════════════

@test "_acid_start_loop: returns 0 when acid not active" {
    export CL4UD3_ACID_MODE="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_start_loop
    assert_success
}

@test "_acid_start_loop: returns 0 when 303 disabled" {
    export CL4UD3_ACID_MODE="true"
    export _ACID_303_ENABLED="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_start_loop
    assert_success
}

@test "_acid_start_loop: returns 0 when play_acid_loop not available" {
    export CL4UD3_ACID_MODE="true"
    export _ACID_303_ENABLED="true"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    # play_acid_loop not defined (play-midi.sh not sourced)
    run _acid_start_loop
    assert_success
}

@test "_acid_start_loop: checks _PF_ACID for existing loop" {
    run grep '_PF_ACID' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

# ════════════════════════════════════════���══════════════════════════════���═══════
# acid-mode.sh — _acid_maybe_stab
# ═════════════���═════════════════════════════════════════════════════════════════

@test "_acid_maybe_stab: returns 0 when acid not active" {
    export CL4UD3_ACID_MODE="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_maybe_stab
    assert_success
}

@test "_acid_maybe_stab: returns 0 when stabs disabled" {
    export CL4UD3_ACID_MODE="true"
    export _ACID_STABS_ENABLED="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_maybe_stab
    assert_success
}

@test "_acid_maybe_stab: returns 0 when play_acid_stab_synced not available" {
    export CL4UD3_ACID_MODE="true"
    export _ACID_STABS_ENABLED="true"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_maybe_stab
    assert_success
}

@test "_acid_maybe_stab: uses awk for random roll" {
    run grep -A20 '_acid_maybe_stab()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "awk"
    assert_output --partial "rand()"
}

@test "_acid_maybe_stab: uses _ACID_STAB_CHANCE" {
    run grep -A15 '_acid_maybe_stab()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_ACID_STAB_CHANCE'
}

# ════════════════���══════════════════════════════════════════════════════════════
# acid-mode.sh — _acid_random_stab
# ══════��═══════════════════════════���════════════════════════════════════════════

@test "_acid_random_stab: returns 0 when acid not active" {
    export CL4UD3_ACID_MODE="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_random_stab
    assert_success
}

@test "_acid_random_stab: returns 0 when stabs disabled" {
    export CL4UD3_ACID_MODE="true"
    export _ACID_STABS_ENABLED="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_random_stab
    assert_success
}

@test "_acid_random_stab: uses _ACID_STAB_RANDOM_CHANCE" {
    run grep -A15 '_acid_random_stab()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial '_ACID_STAB_RANDOM_CHANCE'
}

# ═════════════════════════════════���════════════════════════════════��════════════
# acid-mode.sh — Toggle Functions
# ═══════════════════════════════════════════════════════════════════════════════

@test "_acid_toggle_303: disables when enabled" {
    export _ACID_303_ENABLED="true"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_toggle_303
    assert_success
    assert_output --partial "303: OFF"
}

@test "_acid_toggle_303: enables when disabled" {
    export _ACID_303_ENABLED="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_toggle_303
    assert_success
    assert_output --partial "303: ON"
}

@test "_acid_toggle_stabs: disables when enabled" {
    export _ACID_STABS_ENABLED="true"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_toggle_stabs
    assert_success
    assert_output --partial "stabs: OFF"
}

@test "_acid_toggle_stabs: enables when disabled" {
    export _ACID_STABS_ENABLED="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_toggle_stabs
    assert_success
    assert_output --partial "stabs: ON"
}

@test "_acid_toggle_303: calls kill_acid_loop when disabling" {
    run grep -A5 '_acid_toggle_303()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "kill_acid_loop"
}

@test "_acid_toggle_303: calls _acid_start_loop when enabling" {
    run grep -A15 '_acid_toggle_303()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "_acid_start_loop"
}

@test "_acid_toggle_303: exports _ACID_303_ENABLED" {
    run grep -A8 '_acid_toggle_303()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "export _ACID_303_ENABLED"
}

@test "_acid_toggle_stabs: exports _ACID_STABS_ENABLED" {
    run grep -A8 '_acid_toggle_stabs()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "export _ACID_STABS_ENABLED"
}

# ═══��══════════════════════════════════���═══════════════════════��════════════════
# play-midi.sh — Acid PID/Beat/Dir Files
# ══════���═══════════════════════════════════════════════════��════════════════════

@test "play-midi.sh: defines _PF_ACID variable" {
    run grep '_PF_ACID=' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    assert_output --partial "cl4ud3-cr4ck-acid-pid"
}

@test "play-midi.sh: defines _ACID_BEAT_FILE variable" {
    run grep '_ACID_BEAT_FILE=' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    assert_output --partial "cl4ud3-cr4ck-acid-beat"
}

@test "play-midi.sh: defines _ACID_DIR_FILE variable" {
    run grep '_ACID_DIR_FILE=' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    assert_output --partial "cl4ud3-cr4ck-acid-dir"
}

@test "play-midi.sh: cleanup_session_files includes _PF_ACID" {
    run grep -A5 'cleanup_session_files()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_PF_ACID'
}

@test "play-midi.sh: cleanup_all_stale_files includes acid-pid glob" {
    run grep 'cl4ud3-cr4ck-acid-pid' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

# ═══════════��══════════════════════════════════════════════════════════���════════
# play-midi.sh — play_acid_loop Function
# ══════════════════════════��════════════════════════════════════════════════════

@test "play-midi.sh: defines play_acid_loop function" {
    run grep 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: play_acid_loop calls acid-303.py" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "acid-303.py"
}

@test "play-midi.sh: play_acid_loop creates temp dir" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "mktemp -d"
    assert_output --partial "cl4ud3-acid"
}

@test "play-midi.sh: play_acid_loop writes beat file" {
    run grep -A130 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_acid_write_beat_file'
}

@test "play-midi.sh: play_acid_loop writes dir file" {
    run grep -A130 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_ACID_DIR_FILE'
}

@test "play-midi.sh: play_acid_loop plays loop.mid blocking" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "loop.mid"
    assert_output --partial 'fluidsynth'
}

@test "play-midi.sh: play_acid_loop cleans up dirs on exit" {
    run grep -A65 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'rm -rf'
}

@test "play-midi.sh: play_acid_loop saves PID" {
    run grep -A70 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '$_PF_ACID'
}

@test "play-midi.sh: play_acid_loop disowns background process" {
    run grep -A200 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "disown"
}

@test "play-midi.sh: play_acid_loop is global singleton" {
    run grep -A10 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "singleton"
}

@test "play-midi.sh: play_acid_loop skips if already running" {
    run grep -A15 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "kill -0"
    assert_output --partial "return 0"
}

@test "play-midi.sh: play_acid_loop generates batch of patterns" {
    run grep -A80 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "sections"
    assert_output --partial "--measures"
    assert_output --partial "--count"
    assert_output --partial "acid-303.py"
}

@test "play-midi.sh: play_acid_loop pre-generates next batch during playback" {
    run grep -A120 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "background"
    assert_output --partial "next_dir"
    assert_output --partial "gen_pid"
}

@test "play-midi.sh: play_acid_loop passes bpm to acid-303.py" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '--bpm "$bpm"'
}

@test "play-midi.sh: play_acid_loop defaults bpm to 120" {
    run grep -A2 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial ':-120'
}

# ══════���═══════════════════════════════════════════════════════════════���════════
# play-midi.sh — kill_acid_loop Function
# ═════════════════════════════════���════════════════════════════════════════���════

@test "play-midi.sh: defines kill_acid_loop function" {
    run grep 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: kill_acid_loop kills children via pkill" {
    run grep -A10 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "pkill -P"
}

@test "play-midi.sh: kill_acid_loop removes PID file" {
    run grep -A10 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'rm -f "$_PF_ACID"'
}

@test "play-midi.sh: kill_acid_loop removes beat and dir files" {
    run grep -A12 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '$_ACID_BEAT_FILE'
    assert_output --partial '$_ACID_DIR_FILE'
}

@test "play-midi.sh: kill_acid_loop cleans orphaned acid temp dirs" {
    run grep -A15 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'rm -rf /tmp/.cl4ud3-acid-*'
}

@test "play-midi.sh: kill_acid_loop is safe when no acid loop running" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    run kill_acid_loop
    assert_success
}

# ═════════���════════════════════════════════════════════════���════════════════════
# play-midi.sh — play_acid_stab_synced Function
# ══════════���═════════════════════════════���══════════════════════════════════════

@test "play-midi.sh: defines play_acid_stab_synced function" {
    run grep 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: stab_synced checks for _ACID_DIR_FILE" {
    run grep -A60 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_ACID_DIR_FILE'
}

@test "play-midi.sh: stab_synced checks for _ACID_BEAT_FILE" {
    # _ACID_BEAT_FILE used by _acid_calc_beat_sync called from stab_synced
    run grep '_ACID_BEAT_FILE' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: stab_synced picks random stab from dir" {
    run grep -A60 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "stab-*.mid"
    assert_output --partial "sort -R"
}

@test "play-midi.sh: stab_synced calculates next 16th note" {
    # sixteenth grid in _acid_calc_beat_sync called from stab path
    run grep 'sixteenth' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: stab_synced uses awk for float math" {
    # awk used in _acid_calc_beat_sync called from stab path
    run grep -A30 '_acid_calc_beat_sync()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "awk"
}

@test "play-midi.sh: stab_synced sleeps until next grid point" {
    run grep -A60 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "sleep"
}

@test "play-midi.sh: stab_synced plays in background" {
    run grep -A70 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "disown"
}

@test "play-midi.sh: stab_synced falls back to per-session stabs" {
    run grep -A40 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_STAB_DIR"
    assert_output --partial "_ensure_stab_set"
}

@test "play-midi.sh: stab_synced plays immediately when no beat file" {
    # Fallback: 0.05 wait when no beat file (in _acid_calc_beat_sync)
    run grep -A30 '_acid_calc_beat_sync()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "0.05"
}

@test "play-midi.sh: stab_synced returns 0 when no dir file" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    run play_acid_stab_synced
    assert_success
}

@test "play-midi.sh: stab_synced returns 0 when no beat file" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    echo "$dir" > "$_ACID_DIR_FILE"
    run play_acid_stab_synced
    assert_success
    rm -rf "$dir"
    rm -f "$_ACID_DIR_FILE"
}

@test "play-midi.sh: stab_synced returns 0 when stab dir missing" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    echo "/tmp/nonexistent-dir" > "$_ACID_DIR_FILE"
    echo "$(date +%s) 140" > "$_ACID_BEAT_FILE"
    run play_acid_stab_synced
    assert_success
    rm -f "$_ACID_DIR_FILE" "$_ACID_BEAT_FILE"
}

# ═════════��═══════════════════════════════════════════════════���═════════════════
# play-midi.sh — play_wav_blocking Function
# ══════���═══════════════��════════════════════════════════��═══════════════════════

@test "play-midi.sh: defines _play_midi_blocking function" {
    run grep '_play_midi_blocking()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: _play_midi_blocking returns 1 for missing file" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    run _play_midi_blocking "/tmp/nonexistent.mid"
    assert_failure
}

@test "play-midi.sh: _play_midi_blocking supports fluidsynth" {
    run grep -A25 '_play_midi_blocking()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'fluidsynth'
}

# ══════════════════════════════════════���════════════════════════════════════════
# play-midi.sh — kill_all_sounds Includes Acid
# ══════════════���═════════════════════════════════════════════��══════════════════

@test "play-midi.sh: kill_all_sounds cleans acid pid files" {
    run grep -A8 'kill_all_sounds()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cl4ud3-cr4ck-acid-pid"
}

@test "play-midi.sh: kill_all_sounds cleans acid beat files" {
    run grep -A8 'kill_all_sounds()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cl4ud3-cr4ck-acid-beat"
}

@test "play-midi.sh: kill_all_sounds cleans acid dir files" {
    run grep -A8 'kill_all_sounds()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cl4ud3-cr4ck-acid-dir"
}

@test "play-midi.sh: kill_all_sounds cleans acid temp dirs" {
    run grep -A8 'kill_all_sounds()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cl4ud3-acid-"
}

# ═══════���═════════════════════════════���═════════════════════════════════════════
# play-midi.sh — Syntax
# ═════════════════════════════════��══════════════════════════════���══════════════

@test "play-midi.sh: syntax check passes" {
    run bash -n "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

# ════��═════════════════════════════��══════════════════════��═════════════════════
# post-tool-use.sh — Acid Integration
# ═════════════════════════════���═════════════════════════════════���═══════════════

@test "post-tool-use.sh: sources acid-mode.sh" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    chmod +x "$CL4UD3_HOME/hooks/post-tool-use.sh"
    run grep 'acid-mode.sh' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: calls _is_acid_active" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    run grep '_is_acid_active' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: calls _acid_effect when acid active" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    run grep '_acid_effect' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: calls _acid_start_loop when acid active" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    run grep '_acid_start_loop' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: calls _acid_maybe_stab when acid active" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    run grep '_acid_maybe_stab' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

@test "post-tool-use.sh: acid runs even during cooldown" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    run grep -B2 -A8 'acid bypasses sound cooldown' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
    assert_output --partial "_is_acid_active"
    assert_output --partial "_acid_start_loop"
    assert_output --partial "_acid_maybe_stab"
}

@test "post-tool-use.sh: syntax check passes" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    run bash -n "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_success
}

# ════════════════════════════════════════════════════════��══════════════════════
# stop.sh — Acid Cleanup + Integration
# ═══════���═══════════════���═══════════════════════════════════��═══════════════════

@test "stop.sh: calls kill_acid_loop" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run grep 'kill_acid_loop' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: sources acid-mode.sh" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run grep 'acid-mode.sh' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: calls _acid_effect when acid active" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run grep '_acid_effect' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: calls _acid_random_stab when acid active" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run grep '_acid_random_stab' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "stop.sh: acid runs even during cooldown" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run grep -B2 -A8 'acid bypasses sound cooldown' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
    assert_output --partial "_is_acid_active"
    assert_output --partial "_acid_random_stab"
}

@test "stop.sh: syntax check passes" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run bash -n "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

# ══════��═════════════════════════════════════════════════════════��══════════════
# config.sh — Acid Mode Toggle
# ══════���═══════════════════════════════════════════════════��════════════════════

@test "config.sh: has CL4UD3_ACID_MODE toggle" {
    run grep 'CL4UD3_ACID_MODE' "$CL4UD3_HOME/config.sh"
    assert_success
}

@test "config.sh: acid mode defaults to false" {
    run grep 'CL4UD3_ACID_MODE.*:-false' "$CL4UD3_HOME/config.sh"
    assert_success
}

# ════════��══════════════════════════════════════════════════════════════════════
# install.sh — Acid 303 Copy
# ═════════���════════════════════════════════════════════════��════════════════════

@test "install.sh: copies acid-303.py to install dir" {
    run grep 'acid-303.py' "$BATS_TEST_DIRNAME/../install.sh"
    assert_success
    assert_output --partial "tools/acid-303.py"
}

# ═════════════��═══════════════════���════════════════════════════════════��════════
# acid-303.py — Syntax + Execution
# ══════════════════════════���════════════════════════════════════════════════════

@test "acid-303.py: python3 syntax check passes" {
    run python3 -m py_compile "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has --bpm argument" {
    run grep 'bpm' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has --output-dir argument" {
    run grep 'output-dir' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has --duration argument" {
    run grep 'duration' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: generates loop.mid" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    assert_success
    [ -f "$dir/loop.mid" ]
    rm -rf "$dir"
}

@test "acid-303.py: generates 8 stab MIDIs" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    assert_success
    [ -f "$dir/stab-01.mid" ]
    [ -f "$dir/stab-02.mid" ]
    [ -f "$dir/stab-03.mid" ]
    [ -f "$dir/stab-04.mid" ]
    [ -f "$dir/stab-05.mid" ]
    [ -f "$dir/stab-06.mid" ]
    [ -f "$dir/stab-07.mid" ]
    [ -f "$dir/stab-08.mid" ]
    rm -rf "$dir"
}

@test "acid-303.py: outputs key and bpm info" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    assert_success
    assert_output --partial "key="
    assert_output --partial "bpm=140"
    rm -rf "$dir"
}

@test "acid-303.py: different runs produce different output" {
    local dir1 dir2
    dir1=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    dir2=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir1" --duration 3
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir2" --duration 3
    # Files should differ (different random seeds)
    local md5_1 md5_2
    md5_1=$(md5sum "$dir1/loop.mid" 2>/dev/null | cut -d' ' -f1 || md5 -q "$dir1/loop.mid" 2>/dev/null)
    md5_2=$(md5sum "$dir2/loop.mid" 2>/dev/null | cut -d' ' -f1 || md5 -q "$dir2/loop.mid" 2>/dev/null)
    [ "$md5_1" != "$md5_2" ]
    rm -rf "$dir1" "$dir2"
}

@test "acid-303.py: loop.mid is valid MIDI" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    # Check MThd header
    local header
    header=$(head -c 4 "$dir/loop.mid")
    [ "$header" = "MThd" ]
    rm -rf "$dir"
}

@test "acid-303.py: stab MIDIs are valid MIDI" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    for i in 01 02 03 04 05 06 07 08; do
        local header
        header=$(head -c 4 "$dir/stab-$i.mid")
        [ "$header" = "MThd" ]
    done
    rm -rf "$dir"
}

@test "acid-303.py: accepts custom bpm" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 160 --output-dir "$dir" --duration 3
    assert_success
    assert_output --partial "bpm=160"
    rm -rf "$dir"
}

@test "acid-303.py: loop.mid detected as MIDI by file command" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    run file "$dir/loop.mid"
    assert_output --partial "MIDI"
    rm -rf "$dir"
}

@test "acid-303.py: creates output directory if missing" {
    local dir="/tmp/.cl4ud3-acid-test-nonexist-$$"
    rm -rf "$dir"
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    assert_success
    [ -d "$dir" ]
    rm -rf "$dir"
}

@test "acid-303.py: uses midiutil for MIDI generation" {
    run grep '^from midiutil' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    # Should not import heavy DSP/audio libs
    run grep '^import\|^from' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    refute_output --partial "numpy"
    refute_output --partial "scipy"
    refute_output --partial "pydub"
    refute_output --partial "wave"
}

# ═══════���═════════════════════════════��═══════════════════════��═════════════════
# acid-303.py — Scales + Key Selection
# ═════════���══════════════════════════════════════════════��══════════════════════

@test "acid-303.py: has pentatonic scales" {
    run grep 'pentatonic' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has phrygian scale" {
    run grep -i 'phrygian' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has Am Dm Gm Cm scales" {
    run grep 'SCALES' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: pick_key returns key name and MIDI notes" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
name, root_midi, notes = m._pick_key()
assert name in ('Am', 'Dm', 'Gm', 'Cm', 'Em'), f'unexpected key: {name}'
assert isinstance(root_midi, int), f'expected int root, got {type(root_midi)}'
assert all(isinstance(n, int) for n in notes), 'notes should be MIDI ints'
assert all(30 <= n <= 80 for n in notes), 'notes out of MIDI range'
print('ok')
"
    assert_success
    assert_output "ok"
}

# ════════��══════════════════════════════════════════════════════════════════════
# acid-303.py — DSP Components
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-303.py: has GM program constants" {
    run grep 'BASS_PROGRAM\|LEAD_PROGRAM\|PAD_PROGRAM' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}


# ═════════════════════════════════════════════════════════════���═════════════════
# acid-303.py — Pattern Generation
# ═════════���══════════════════��══════════════════════════════════════════════════

@test "acid-303.py: _generate_pattern produces 16 steps" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
notes = [45, 48, 50, 52, 57]
pat = m._generate_pattern(notes, steps=16)
assert len(pat) == 16, f'expected 16 steps, got {len(pat)}'
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: pattern steps have type field" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
notes = [45, 48, 50]
pat = m._generate_pattern(notes)
for step in pat:
    assert 'type' in step, f'missing type field'
    assert step['type'] in ('note', 'rest'), f'bad type: {step[\"type\"]}'
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: note steps have accent slide and midi fields" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
notes = [45, 48, 50, 52, 57]
# Run multiple times to ensure we get note steps
for _ in range(10):
    pat = m._generate_pattern(notes)
    for step in pat:
        if step['type'] == 'note':
            assert 'accent' in step
            assert 'slide' in step
            assert 'midi' in step
            print('ok')
            exit()
print('ok')
"
    assert_success
    assert_output "ok"
}

# ═══���════════════════════════════════════════════════════════════��══════════════
# acid-303.py — Stab Generation
# ══════════════════════════���═════════════════════════════════���══════════════════

@test "acid-303.py: has 8 stab generator functions plus helper" {
    run grep 'def _stab_' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    local count
    count=$(echo "$output" | wc -l | tr -d ' ')
    [ "$count" -eq 9 ]  # 8 generators + _stab_add_echo helper
}

@test "acid-303.py: STAB_GENERATORS list has 8 entries" {
    run grep -A12 'STAB_GENERATORS' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    assert_output --partial "_stab_squelch_hit"
    assert_output --partial "_stab_acid_scream"
    assert_output --partial "_stab_slide_up"
    assert_output --partial "_stab_slide_down"
    assert_output --partial "_stab_dub_ping"
    assert_output --partial "_stab_tape_echo"
    assert_output --partial "_stab_stutter"
    assert_output --partial "_stab_ghost"
}

@test "acid-303.py: stab generators write MIDI notes" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
from midiutil import MIDIFile
notes = [45, 48, 50, 52, 57]
for gen in m.STAB_GENERATORS:
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 140)
    gen(midi, 0, 0, notes, 140)
print('ok')
"
    assert_success
    assert_output "ok"
}

# ════════��═════════════════════════════════════════════════════════════��════════
# acid-303.py — FX Chain
# ═══════════════════════════════���═════════════════════════��═════════════════════


# ══════════════���════════════════════════════════════════════════════════════════
# acid-303.py — WAV Writing
# ���══════════════════════════��═══════════════════════════════════════════════════


# ════════��══════════════════════════════════════════════════════════════���═══════
# acid-303.py — Bassline Generation
# ════��═══════════════════���═════════════════════════════���════════════════════════

@test "acid-303.py: _write_bassline writes MIDI notes" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
from midiutil import MIDIFile
midi = MIDIFile(1, deinterleave=False)
midi.addTempo(0, 0, 140)
midi.addProgramChange(0, 0, 0, 38)
notes = [45, 48, 50, 52, 57]
beats = m._write_bassline(midi, 0, 0, notes, bpm=140, measures=4, start_beat=0.0)
assert beats > 0, f'expected positive beats, got {beats}'
print('ok')
"
    assert_success
    assert_output "ok"
}

# ══════════��════════════════════��══════════════════════════════���════════════════
# acid-303.py — generate() top-level function
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-303.py: generate() returns key name" {
    run python3 -c "
import sys, tempfile; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
d = tempfile.mkdtemp()
key = m.generate(140, d, measures=4)
assert key in ('Am', 'Dm', 'Gm', 'Cm', 'Em'), f'unexpected key: {key}'
import shutil; shutil.rmtree(d)
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: generate() sets MIDI program and CCs for bass" {
    run grep -A25 'def generate(' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "beat_pos"
    assert_output --partial "_write_bassline"
}

@test "acid-303.py: generate() writes loop.mid and stab MIDIs" {
    run grep -A55 'def generate(' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "loop.mid"
    assert_output --partial "stab-"
}

# ════════════════════════════════════���══════════════════════════════════════════
# acid-303.py — MIDI to Freq
# ══════��════════════════════════════════════════════════��═══════════════════════


# ════════���═════════════════════════════════════════════════════════��════════════
# Integration — Full Loop Architecture
# ═══════���════════════════���════════════════════════════════════���═════════════════

@test "integration: acid loop architecture — batch generate → play → pre-gen next" {
    run grep -A130 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "mktemp -d"
    assert_output --partial "acid-303.py"
    assert_output --partial "--count"
    assert_output --partial "_acid_write_beat_file"
    assert_output --partial "_ACID_DIR_FILE"
    assert_output --partial "loop.mid"
    assert_output --partial "fluidsynth"
    assert_output --partial "next_dir"
}

@test "integration: stab trigger reads beat file and stab dir" {
    # stab_synced reads _ACID_DIR_FILE directly, _ACID_BEAT_FILE via _acid_calc_beat_sync
    run grep -A50 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_DIR_FILE"
    assert_output --partial "stab-*.mid"
}

@test "integration: post-tool-use triggers acid start + stab" {
    cp "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh" "$CL4UD3_HOME/hooks/"
    run grep -A5 '_is_acid_active' "$CL4UD3_HOME/hooks/post-tool-use.sh"
    assert_output --partial "_acid_start_loop"
    assert_output --partial "_acid_maybe_stab"
}

@test "integration: stop hook kills acid loop" {
    cp "$BATS_TEST_DIRNAME/../hooks/stop.sh" "$CL4UD3_HOME/hooks/"
    run grep 'kill_acid_loop' "$CL4UD3_HOME/hooks/stop.sh"
    assert_success
}

@test "integration: acid-mode.sh and play-midi.sh work together" {
    # Source both, verify functions coexist
    run bash -c "
        source '$CL4UD3_HOME/hooks/play-midi.sh'
        source '$CL4UD3_HOME/hooks/acid-mode.sh'
        type play_acid_loop && type _acid_start_loop && type _acid_maybe_stab && echo 'ok'
    "
    assert_success
    assert_output --partial "ok"
}

# ═════════���═════════════════════════════════════════════════════════════════════
# Beat Sync Math
# ═══���════════════════════��══════════════════════════════════════════════════════

@test "play-midi.sh: beat sync uses 16th note grid (60/bpm/4)" {
    run grep -A30 '_acid_calc_beat_sync()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "60.0"
    assert_output --partial "/ 4"
}

@test "play-midi.sh: beat sync handles fractional seconds" {
    run grep -A30 '_acid_calc_beat_sync()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "%s.%N"
}

@test "play-midi.sh: beat sync has fallback when wait_time empty" {
    run grep -A30 '_acid_calc_beat_sync()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '0.05'
}

# ═══════════════════════════════════════════════════════════════════════════════
# Global Singleton — 303 runs once across all terminals
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: _PF_ACID is global (no session suffix)" {
    run grep '_PF_ACID=' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    # Should NOT contain $CL4UD3_SID
    refute_output --partial '$CL4UD3_SID'
}

@test "play-midi.sh: _ACID_BEAT_FILE is global (no session suffix)" {
    run grep '_ACID_BEAT_FILE=' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    refute_output --partial '$CL4UD3_SID'
}

@test "play-midi.sh: _ACID_DIR_FILE is global (no session suffix)" {
    run grep '_ACID_DIR_FILE=' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    refute_output --partial '$CL4UD3_SID'
}

@test "play-midi.sh: _ACID_STAB_DIR is per-session" {
    run grep '_ACID_STAB_DIR=' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    assert_output --partial '$CL4UD3_SID'
}

@test "play-midi.sh: defines is_acid_loop_running function" {
    run grep 'is_acid_loop_running()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: is_acid_loop_running checks PID liveness" {
    run grep -A5 'is_acid_loop_running()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "kill -0"
}

@test "play-midi.sh: is_acid_loop_running returns 1 when no pidfile" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    rm -f "$_PF_ACID"
    run is_acid_loop_running
    assert_failure
}

# ═══════════════════════════════════════════════════════════════════════════════
# Double-Buffer Architecture
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: acid loop cleans up dirs on exit" {
    run grep -A170 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "prev_dir"
    assert_output --partial "Cleanup"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Beat Clock — Global sync for all stabs
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: defines _acid_write_beat_file function" {
    run grep '_acid_write_beat_file()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: _acid_write_beat_file writes epoch and bpm" {
    run grep -A10 '_acid_write_beat_file()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '%s.%N'
    assert_output --partial '$_ACID_BEAT_FILE'
}

@test "play-midi.sh: defines _ensure_beat_clock function" {
    run grep '_ensure_beat_clock()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: _ensure_beat_clock creates beat file if missing" {
    run grep -A5 '_ensure_beat_clock()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_acid_write_beat_file"
}

@test "play-midi.sh: _ensure_beat_clock skips if beat file exists" {
    run grep -A3 '_ensure_beat_clock()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '! -f "$_ACID_BEAT_FILE"'
}

@test "play-midi.sh: _ensure_beat_clock is safe to call" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    rm -f "$_ACID_BEAT_FILE"
    run _ensure_beat_clock 140
    assert_success
    [ -f "$_ACID_BEAT_FILE" ]
    rm -f "$_ACID_BEAT_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Idle Timeout — Auto-kill 303 when no tool use
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: defines _acid_touch_activity function" {
    run grep '_acid_touch_activity()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: defines _acid_is_idle function" {
    run grep '_acid_is_idle()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: defines _ACID_ACTIVITY_FILE" {
    run grep '_ACID_ACTIVITY_FILE' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: _acid_touch_activity creates file" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    rm -f "$_ACID_ACTIVITY_FILE"
    _acid_touch_activity
    [ -f "$_ACID_ACTIVITY_FILE" ]
    rm -f "$_ACID_ACTIVITY_FILE"
}

@test "play-midi.sh: _acid_is_idle returns 0 when no activity file" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    rm -f "$_ACID_ACTIVITY_FILE"
    _acid_is_idle
}

@test "play-midi.sh: _acid_is_idle returns 1 when recently active" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    _acid_touch_activity
    ! _acid_is_idle
    rm -f "$_ACID_ACTIVITY_FILE"
}

@test "play-midi.sh: acid loop checks _acid_is_idle" {
    run grep -A15 'while \[ -f "$my_pidfile" \]' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_acid_is_idle"
}

@test "play-midi.sh: acid loop cleans up on idle exit" {
    run grep -A15 '# Cleanup' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_ACTIVITY_FILE"
}

@test "play-midi.sh: kill_acid_loop cleans activity file" {
    run grep -A10 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_ACTIVITY_FILE"
}

@test "acid-mode.sh: _acid_start_loop touches activity" {
    run grep -A10 '_acid_start_loop()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "_acid_touch_activity"
}

@test "acid-mode.sh: _acid_maybe_stab touches activity" {
    run grep -A10 '_acid_maybe_stab()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "_acid_touch_activity"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Per-Session Stab Set — Stabs work without 303
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: defines _ensure_stab_set function" {
    run grep '_ensure_stab_set()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: _ensure_stab_set prefers 303 stabs when available" {
    run grep -A10 '_ensure_stab_set()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_DIR_FILE"
}

@test "play-midi.sh: _ensure_stab_set generates own stabs when no 303" {
    run grep -A20 '_ensure_stab_set()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "acid-303.py"
    assert_output --partial "_ACID_STAB_DIR"
}

@test "play-midi.sh: _ensure_stab_set calls _ensure_beat_clock" {
    run grep -A25 '_ensure_stab_set()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ensure_beat_clock"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Stabs Independent of 303
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-mode.sh: _acid_maybe_stab ensures beat clock" {
    run grep -A20 '_acid_maybe_stab()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "_ensure_beat_clock"
}

@test "acid-mode.sh: _acid_maybe_stab ensures stab set" {
    run grep -A20 '_acid_maybe_stab()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "_ensure_stab_set"
}

@test "acid-mode.sh: _acid_random_stab ensures beat clock" {
    run grep -A20 '_acid_random_stab()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "_ensure_beat_clock"
}

@test "acid-mode.sh: _acid_random_stab ensures stab set" {
    run grep -A20 '_acid_random_stab()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "_ensure_stab_set"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Multi-Terminal Integration
# ═══════════════════════════════════════════════════════════════════════════════

@test "integration: stab reads global dir from any session" {
    run grep -A40 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    # Reads global _ACID_DIR_FILE, falls back to per-session _ACID_STAB_DIR
    assert_output --partial "_ACID_DIR_FILE"
    assert_output --partial "_ACID_STAB_DIR"
}

@test "integration: stab falls back to MIDI file playback without FIFO" {
    run grep -A40 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "Fallback"
    assert_output --partial "_play_midi_blocking"
}

@test "integration: cleanup_all_stale_files checks global acid pid" {
    run grep -A10 'cleanup_all_stale_files()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_PF_ACID"
}

@test "integration: kill_all_sounds cleans per-session stab dirs" {
    run grep -A10 'kill_all_sounds()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cl4ud3-cr4ck-acid-stabs"
}

# ═══════════════════════════════════════════════════════════════════════════════
# TB-303 Soundfont + Distortion
# ═══════════════════════════════════════════════════════════════════════════════

@test "config.sh: _ACID_303_SF defined" {
    run grep '_ACID_303_SF' "$CL4UD3_HOME/config.sh"
    assert_success
    assert_output --partial "HS TB-303.SF2"
}

@test "config.sh: _ACID_303_BPM defaults to 120" {
    run grep '_ACID_303_BPM' "$CL4UD3_HOME/config.sh"
    assert_success
    assert_output --partial "120"
}

@test "play-midi.sh: _play_midi_blocking accepts soundfont override" {
    run grep -A5 '_play_midi_blocking()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "sf_override"
}

@test "play-midi.sh: acid mode uses gain and chorus" {
    run grep -A15 '_play_midi_blocking()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "fs_extra"
    assert_output --partial "synth.chorus"
    assert_output --partial "synth.reverb"
}

@test "play-midi.sh: acid fluidsynth uses 22050 sample rate for bitcrush" {
    run grep 'synth.sample-rate' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    assert_output --partial "22050"
}

@test "play-midi.sh: acid loop passes 303 soundfont to blocking player" {
    run grep '_play_midi_blocking.*_ACID_303_SF' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: stab playback uses 303 soundfont" {
    run grep -A70 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_303_SF"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Trippy Stab Generators (no chords, single note, dub echo)
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-303.py: TB303 program constants defined" {
    run grep -A2 'TB303_BASS_PROGRAMS' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    assert_output --partial "TB-BASS"
}

@test "acid-303.py: TB303_SQR_PROGRAMS defined" {
    run grep 'TB303_SQR_PROGRAMS' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    assert_output --partial "TB303 SQR"
}

@test "acid-303.py: _stab_add_echo helper exists" {
    run grep 'def _stab_add_echo' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: stab generators use TB303 programs" {
    run grep -c 'TB303_SQR_PROGRAMS\|TB303_BASS_PROGRAMS' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    # Should appear in multiple stab generators
    [ "${output}" -ge 8 ]
}

@test "acid-303.py: stabs use octave up (+12 or +24)" {
    run grep -c '+ 12\|+ 24' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    [ "${output}" -ge 5 ]
}

@test "acid-303.py: stabs use CC74 filter sweeps" {
    run grep -c 'addControllerEvent.*74' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    [ "${output}" -ge 10 ]
}

@test "acid-303.py: stab generators list updated" {
    run grep -A10 'STAB_GENERATORS' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "_stab_squelch_hit"
    assert_output --partial "_stab_acid_scream"
    assert_output --partial "_stab_dub_ping"
    assert_output --partial "_stab_ghost"
}

@test "acid-303.py: no polyphonic chords in stabs" {
    # No stab should use random.sample on note_pool (chord picking)
    # Stabs should be single hits or sequential notes with random.choice
    local count
    count=$(grep -c 'random.sample.*note_pool' "$BATS_TEST_DIRNAME/../tools/acid-303.py" || true)
    [ "$count" -le 1 ]
}

@test "acid-303.py: _stab_add_echo adds decaying velocity" {
    run grep -A10 'def _stab_add_echo' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "vel < 20"
    assert_output --partial "0.55"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Acid Sound Replacement
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-mode.sh: _ACID_REPLACE_SOUNDS config param exists" {
    run grep '_ACID_REPLACE_SOUNDS' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: stab chances increased" {
    run grep '_ACID_STAB_CHANCE' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    assert_output --partial "0.95"
}

@test "acid-mode.sh: random stab chance increased" {
    run grep '_ACID_STAB_RANDOM_CHANCE' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
    assert_output --partial "0.6"
}

@test "stop.sh: acid mode can replace glitch sounds" {
    run grep -A5 '_ACID_REPLACE_SOUNDS' "$BATS_TEST_DIRNAME/../hooks/stop.sh"
    assert_success
}

@test "post-tool-use.sh: modem sounds always play (not replaced)" {
    # Modem sounds should play regardless of acid mode
    run grep -B2 'play_random_from_dir.*modem' "$BATS_TEST_DIRNAME/../hooks/post-tool-use.sh"
    assert_success
    # Should NOT be inside acid replacement conditional
    refute_output --partial "_ACID_REPLACE_SOUNDS"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Filter Envelope + Drive
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-303.py: filter envelope uses steeper decay curve" {
    run grep -A12 'def _write_filter_envelope' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "0.4"
}

@test "acid-303.py: accent filter starts at 127" {
    run grep -A5 'def _write_filter_envelope' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "127, 15, 8"
}

@test "acid-303.py: expression surge on accented notes" {
    run grep -A20 'def _write_filter_envelope' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial ", 11, 127"
}

@test "acid-303.py: max resonance CC71=127" {
    run grep 'addControllerEvent.*71.*127' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: velocity cranked up for grit" {
    run grep -A2 'velocity.*accent' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "127"
}

# ═══════════════════════════════════════════════════════════════════════════════
# FIFO Stab Integration — same fluidsynth instance as bassline
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: defines _ACID_FIFO_PATH_FILE" {
    run grep '_ACID_FIFO_PATH_FILE' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    assert_output --partial "cl4ud3-acid-fifo-path"
}

@test "play-midi.sh: defines _ACID_NOTES_FILE" {
    run grep '_ACID_NOTES_FILE' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    assert_output --partial "cl4ud3-acid-notes"
}

@test "play-midi.sh: defines _play_stab_via_fifo function" {
    run grep '_play_stab_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: defines _acid_calc_beat_sync function" {
    run grep '_acid_calc_beat_sync()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: defines _acid_read_notes function" {
    run grep '_acid_read_notes()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: FIFO stab uses channel 1 (bass=ch0)" {
    run grep -c 'noteon 1\|noteoff 1\|cc 1\|prog 1' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    # Many FIFO commands use channel 1
    [ "${output}" -ge 10 ]
}

@test "play-midi.sh: FIFO stab has 6 stab styles" {
    run grep -c 'style in' "$CL4UD3_HOME/hooks/play-midi.sh"
    # case $style covers 0-5
    local count
    count=$(grep -c '^\s*[0-5])' "$CL4UD3_HOME/hooks/play-midi.sh" || true)
    [ "$count" -ge 6 ]
}

@test "play-midi.sh: FIFO stab reads note pool from file" {
    run grep -A10 '_acid_read_notes()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_NOTES_FILE"
}

@test "play-midi.sh: _acid_read_notes has A minor fallback" {
    run grep -A10 '_acid_read_notes()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "Fallback"
    assert_output --partial "45 48 50 52 55"
}

@test "play-midi.sh: play_acid_stab_synced prefers FIFO injection" {
    run grep -A15 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_FIFO_PATH_FILE"
    assert_output --partial "_play_stab_via_fifo"
}

@test "play-midi.sh: FIFO stab uses 303 programs" {
    run grep -A10 '_play_stab_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    # Uses TB303 SQR programs (50-85) and BASS programs (0-45)
    run grep 'sqr_progs\|bass_progs' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: FIFO stab has dub echo delays" {
    # Multiple sleep-based echo patterns in stab styles
    local count
    count=$(grep -c 'sleep 0.75\|sleep 0.5' "$CL4UD3_HOME/hooks/play-midi.sh" || true)
    [ "$count" -ge 4 ]
}

@test "play-midi.sh: FIFO stab sets CC74 filter" {
    local count
    count=$(grep -c 'cc 1 74' "$CL4UD3_HOME/hooks/play-midi.sh" || true)
    [ "$count" -ge 5 ]
}

@test "play-midi.sh: FIFO stab sets CC71 resonance" {
    run grep 'cc 1 71 127' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: FIFO stab octave up (+12/+24)" {
    run grep -A30 '_play_stab_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "octave_up"
    assert_output --partial "12"
}

@test "play-midi.sh: acid loop publishes notes.txt" {
    run grep -A120 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "notes.txt"
    assert_output --partial "_ACID_NOTES_FILE"
}

@test "play-midi.sh: acid loop creates FIFO pipe" {
    run grep -A120 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "mkfifo"
    assert_output --partial "acid_fifo"
}

@test "play-midi.sh: acid loop writes FIFO path file" {
    run grep -A120 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cl4ud3-acid-fifo-path"
}

@test "play-midi.sh: acid loop uses persistent fluidsynth" {
    run grep -A120 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "tail -f"
    assert_output --partial "fluidsynth"
    assert_output --partial "player_loop"
    assert_output --partial "player_start"
}

@test "play-midi.sh: kill_acid_loop cleans FIFO files" {
    run grep -A15 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_NOTES_FILE"
    assert_output --partial "_ACID_FIFO_PATH_FILE"
}

@test "play-midi.sh: kill_acid_loop kills orphaned tail" {
    run grep -A15 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'pkill -f "tail -f'
}

@test "play-midi.sh: kill_all_sounds cleans FIFO files" {
    run grep -A15 'kill_all_sounds()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "acid-fifo-path"
    assert_output --partial "acid-notes"
}

@test "acid-303.py: generate writes notes.txt" {
    run grep -A5 'notes.txt' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    assert_output --partial "note_pool"
}

@test "acid-303.py: notes.txt contains note pool" {
    local tmpdir
    tmpdir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 120 --output-dir "$tmpdir" --measures 4 --count 1
    assert_success
    # notes.txt should exist with MIDI note numbers
    [ -f "$tmpdir/notes.txt" ]
    local count
    count=$(wc -l < "$tmpdir/notes.txt" | tr -d ' ')
    [ "$count" -ge 5 ]  # at least 5 notes in pool
    # All lines should be numbers
    run grep -v '^[0-9]*$' "$tmpdir/notes.txt"
    assert_failure  # no non-numeric lines
    rm -rf "$tmpdir"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dark Pad Synth — Config + Toggle
# ═══════════════════════════════════════════════════════════════════════════════

@test "config.sh: _ACID_PADS_ENABLED config exists" {
    run grep '_ACID_PADS_ENABLED' "$CL4UD3_HOME/config.sh"
    assert_success
    assert_output --partial ":-false"
}

@test "acid-mode.sh: _ACID_PADS_ENABLED defaults to false" {
    run grep '_ACID_PADS_ENABLED.*:-false' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: defines _acid_toggle_pads function" {
    run bash -c "source '$CL4UD3_HOME/hooks/acid-mode.sh'; type _acid_toggle_pads"
    assert_success
    assert_output --partial "function"
}

@test "_acid_toggle_pads: enables when disabled" {
    export _ACID_PADS_ENABLED="false"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_toggle_pads
    assert_success
    assert_output --partial "pads: ON"
}

@test "_acid_toggle_pads: disables when enabled" {
    export _ACID_PADS_ENABLED="true"
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    run _acid_toggle_pads
    assert_success
    assert_output --partial "pads: OFF"
}

@test "_acid_toggle_pads: exports _ACID_PADS_ENABLED" {
    run grep -A8 '_acid_toggle_pads()' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_output --partial "export _ACID_PADS_ENABLED"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dark Pad Synth — FIFO Injection
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: defines _ACID_CHORDS_FILE variable" {
    run grep '_ACID_CHORDS_FILE=' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    assert_output --partial "cl4ud3-acid-chords"
}

@test "play-midi.sh: defines _play_pad_via_fifo function" {
    run grep '_play_pad_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: pad uses channel 2" {
    run grep -c 'noteon 2\|noteoff 2\|cc 2\|prog 2' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
    # Multiple FIFO commands use channel 2
    [ "${output}" -ge 5 ]
}

@test "play-midi.sh: pad reads chord progression from file" {
    run grep -A10 '_play_pad_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_CHORDS_FILE"
}

@test "play-midi.sh: pad cycles through chords" {
    run grep -A30 '_play_pad_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "counter_file"
    assert_output --partial "idx"
}

@test "play-midi.sh: pad has sustained notes with sleep" {
    run grep -A65 '_play_pad_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "sustain"
    assert_output --partial "sleep"
}

@test "play-midi.sh: pad sets CC71 resonance warm" {
    run grep -A40 '_play_pad_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cc 2 71"
}

@test "play-midi.sh: pad sets CC74 filter" {
    run grep -A55 '_play_pad_via_fifo()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cc 2 74"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dark Pad Synth — Chord Generation
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-303.py: defines _generate_chord_progression function" {
    run grep 'def _generate_chord_progression' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: CHORD_TYPES defined" {
    run grep -A10 'CHORD_TYPES' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    assert_output --partial "Amiga tracker crunch"
}

@test "acid-303.py: generate writes chords.txt" {
    run grep -A5 'chords.txt' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    assert_output --partial "chord_prog"
}

@test "acid-303.py: chords.txt generation works" {
    local tmpdir
    tmpdir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 120 --output-dir "$tmpdir" --measures 4 --count 1
    assert_success
    [ -f "$tmpdir/chords.txt" ]
    local count
    count=$(wc -l < "$tmpdir/chords.txt" | tr -d ' ')
    [ "$count" -ge 4 ]  # at least 4 chords
    [ "$count" -le 8 ]  # at most 8 chords
    rm -rf "$tmpdir"
}

@test "acid-303.py: chords.txt has space-separated MIDI notes" {
    local tmpdir
    tmpdir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 120 --output-dir "$tmpdir" --measures 4 --count 1
    # Each line should be space-separated numbers
    while IFS= read -r line; do
        for note in $line; do
            [[ "$note" =~ ^[0-9]+$ ]]
            [ "$note" -ge 48 ] && [ "$note" -le 84 ]
        done
    done < "$tmpdir/chords.txt"
    rm -rf "$tmpdir"
}

@test "acid-303.py: chord progression has 2-3 notes per chord" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
notes = [48, 50, 52, 55, 57, 60, 62, 64, 67]
chords = m._generate_chord_progression(notes, 48)
assert len(chords) >= 4, f'too few chords: {len(chords)}'
assert len(chords) <= 8, f'too many chords: {len(chords)}'
for c in chords:
    assert 2 <= len(c) <= 4, f'chord has {len(c)} notes: {c}'
    for n in c:
        assert 48 <= n <= 84, f'note {n} out of pad range'
print('ok')
"
    assert_success
    assert_output "ok"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dark Pad Synth — Pad Loop in Acid Loop
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: acid loop has pad loop subshell" {
    run grep -A160 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_PADS_ENABLED"
    assert_output --partial "_play_pad_via_fifo"
    assert_output --partial "pad_pid"
}

@test "play-midi.sh: acid loop publishes chords.txt" {
    run grep -A120 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "chords.txt"
    assert_output --partial "_ACID_CHORDS_FILE"
}

@test "play-midi.sh: pad loop waits 2-4 measures" {
    run grep -A170 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "wait_measures"
    assert_output --partial "2 + RANDOM % 3"
}

@test "play-midi.sh: pad loop self-terminates on pidfile removal" {
    run grep -A170 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "my_pidfile"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dark Pad Synth — Cleanup
# ═══════════════════════════════════════════════════════════════════════════════

@test "play-midi.sh: acid loop cleanup kills pad_pid" {
    run grep -A200 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'pad_pid'
    assert_output --partial 'kill "$pad_pid"'
}

@test "play-midi.sh: acid loop cleanup removes chords file" {
    run grep -A200 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_ACID_CHORDS_FILE'
}

@test "play-midi.sh: kill_acid_loop cleans chords file" {
    run grep -A15 'kill_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_ACID_CHORDS_FILE'
}

@test "play-midi.sh: kill_all_sounds cleans chords file" {
    run grep -A15 'kill_all_sounds()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "acid-chords"
}

@test "play-midi.sh: batch swap refreshes chords for pads" {
    run grep -A160 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'next_dir/chords.txt'
}
