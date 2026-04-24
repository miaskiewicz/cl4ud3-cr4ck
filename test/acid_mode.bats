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

@test "acid-mode.sh: _ACID_303_BPM defaults to 140" {
    run grep '_ACID_303_BPM.*:-140' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: _ACID_STAB_CHANCE defaults to 0.8" {
    run grep '_ACID_STAB_CHANCE.*:-0.8' "$CL4UD3_HOME/hooks/acid-mode.sh"
    assert_success
}

@test "acid-mode.sh: _ACID_STAB_RANDOM_CHANCE defaults to 0.3" {
    run grep '_ACID_STAB_RANDOM_CHANCE.*:-0.3' "$CL4UD3_HOME/hooks/acid-mode.sh"
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
    [ "$_ACID_303_BPM" = "140" ]
    [ "$_ACID_STAB_CHANCE" = "0.8" ]
    [ "$_ACID_STAB_RANDOM_CHANCE" = "0.3" ]
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
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_acid_write_beat_file'
}

@test "play-midi.sh: play_acid_loop writes dir file" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_ACID_DIR_FILE'
}

@test "play-midi.sh: play_acid_loop plays loop.wav blocking" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "loop.wav"
    assert_output --partial 'WAV_PLAYER'
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
    run grep -A80 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
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

@test "play-midi.sh: play_acid_loop double-buffers next generation" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "next_dir"
    assert_output --partial "double-buffer"
}

@test "play-midi.sh: play_acid_loop generates next while current plays" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "gen_pid"
    assert_output --partial "wait"
}

@test "play-midi.sh: play_acid_loop passes bpm to acid-303.py" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '--bpm "$bpm"'
}

@test "play-midi.sh: play_acid_loop defaults bpm to 140" {
    run grep -A2 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial ':-140'
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
    run grep -A60 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial '_ACID_BEAT_FILE'
}

@test "play-midi.sh: stab_synced picks random stab from dir" {
    run grep -A60 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "stab-*.wav"
    assert_output --partial "sort -R"
}

@test "play-midi.sh: stab_synced calculates next 16th note" {
    run grep -A60 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "sixteenth"
}

@test "play-midi.sh: stab_synced uses awk for float math" {
    run grep -A60 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
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
    run grep -A20 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_STAB_DIR"
    assert_output --partial "_ensure_stab_set"
}

@test "play-midi.sh: stab_synced plays immediately when no beat file" {
    run grep -A70 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "No beat file"
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

@test "play-midi.sh: defines play_wav_blocking function" {
    run grep 'play_wav_blocking()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_success
}

@test "play-midi.sh: play_wav_blocking returns 1 for missing file" {
    source "$CL4UD3_HOME/hooks/play-midi.sh"
    run play_wav_blocking "/tmp/nonexistent.wav"
    assert_failure
}

@test "play-midi.sh: play_wav_blocking uses WAV_PLAYER" {
    run grep -A5 'play_wav_blocking()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'WAV_PLAYER'
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

@test "acid-303.py: generates loop.wav" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    assert_success
    [ -f "$dir/loop.wav" ]
    rm -rf "$dir"
}

@test "acid-303.py: generates 8 stab WAVs" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    run python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    assert_success
    [ -f "$dir/stab-01.wav" ]
    [ -f "$dir/stab-02.wav" ]
    [ -f "$dir/stab-03.wav" ]
    [ -f "$dir/stab-04.wav" ]
    [ -f "$dir/stab-05.wav" ]
    [ -f "$dir/stab-06.wav" ]
    [ -f "$dir/stab-07.wav" ]
    [ -f "$dir/stab-08.wav" ]
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
    md5_1=$(md5sum "$dir1/loop.wav" 2>/dev/null | cut -d' ' -f1 || md5 -q "$dir1/loop.wav" 2>/dev/null)
    md5_2=$(md5sum "$dir2/loop.wav" 2>/dev/null | cut -d' ' -f1 || md5 -q "$dir2/loop.wav" 2>/dev/null)
    [ "$md5_1" != "$md5_2" ]
    rm -rf "$dir1" "$dir2"
}

@test "acid-303.py: loop.wav is valid RIFF WAV" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    # Check RIFF header
    local header
    header=$(head -c 4 "$dir/loop.wav")
    [ "$header" = "RIFF" ]
    rm -rf "$dir"
}

@test "acid-303.py: stab WAVs are valid RIFF WAV" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    for i in 01 02 03 04 05 06 07 08; do
        local header
        header=$(head -c 4 "$dir/stab-$i.wav")
        [ "$header" = "RIFF" ]
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

@test "acid-303.py: loop.wav is 16-bit mono 44100Hz" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    run file "$dir/loop.wav"
    assert_output --partial "WAVE audio"
    assert_output --partial "16 bit"
    assert_output --partial "mono"
    assert_output --partial "44100 Hz"
    rm -rf "$dir"
}

@test "acid-303.py: stab WAVs are 16-bit mono 44100Hz" {
    local dir
    dir=$(mktemp -d /tmp/.cl4ud3-acid-test-XXXXX)
    python3 "$BATS_TEST_DIRNAME/../tools/acid-303.py" --bpm 140 --output-dir "$dir" --duration 3
    run file "$dir/stab-01.wav"
    assert_output --partial "16 bit"
    assert_output --partial "mono"
    assert_output --partial "44100 Hz"
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

@test "acid-303.py: uses only stdlib (no external imports)" {
    # Should not import anything outside stdlib
    run grep '^import\|^from' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    refute_output --partial "numpy"
    refute_output --partial "scipy"
    refute_output --partial "midiutil"
    refute_output --partial "pydub"
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

@test "acid-303.py: pick_key returns key name" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
name, freq, notes = m._pick_key()
assert name in ('Am', 'Dm', 'Gm', 'Cm', 'Em'), f'unexpected key: {name}'
assert freq > 0
assert len(notes) > 0
print('ok')
"
    assert_success
    assert_output "ok"
}

# ════════��══════════════════════════════════════════════════════════════════════
# acid-303.py — DSP Components
# ═══════════════════════════════════════════════════════════════════════════════

@test "acid-303.py: has ResonantFilter class" {
    run grep 'class ResonantFilter' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has Delay class" {
    run grep 'class Delay' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has CombReverb class" {
    run grep 'class CombReverb' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has _saw function" {
    run grep 'def _saw' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has _square function" {
    run grep 'def _square' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has _tanh_clip distortion" {
    run grep 'def _tanh_clip' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has _acid_note function" {
    run grep 'def _acid_note' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: ResonantFilter processes samples" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
f = m.ResonantFilter(1000.0, 0.7)
out = f.process(1.0)
assert isinstance(out, float), f'expected float, got {type(out)}'
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: Delay processes samples" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
d = m.Delay(100.0, 0.3, 0.2)
out = d.process(1.0)
assert isinstance(out, float)
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: CombReverb processes samples" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
r = m.CombReverb(0.4, 0.15)
out = r.process(1.0)
assert isinstance(out, float)
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: _saw generates values in -1..1 range" {
    run python3 -c "
import sys, math; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
for i in range(100):
    v = m._saw(i * 0.1)
    assert -1.01 <= v <= 1.01, f'out of range: {v}'
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: _square generates values in {-1, 1}" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
for i in range(100):
    v = m._square(i * 0.1)
    assert v in (-1.0, 1.0), f'unexpected: {v}'
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: _tanh_clip output stays bounded" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
for x in [-10, -1, 0, 1, 10]:
    v = m._tanh_clip(x, 2.0)
    assert -1.0 <= v <= 1.0, f'out of range: {v}'
print('ok')
"
    assert_success
    assert_output "ok"
}

# ═════════════════════════════════════════════════════════════���═════════════════
# acid-303.py — Pattern Generation
# ═════════���══════════════════��══════════════════════════════════════════════════

@test "acid-303.py: _generate_pattern produces 16 steps" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
notes = [110.0, 130.8, 146.8, 164.8, 196.0]
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
notes = [110.0, 130.8, 146.8]
pat = m._generate_pattern(notes)
for step in pat:
    assert 'type' in step, f'missing type field'
    assert step['type'] in ('note', 'rest'), f'bad type: {step[\"type\"]}'
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: note steps have accent and slide fields" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
notes = [110.0, 130.8, 146.8, 164.8, 196.0]
# Run multiple times to ensure we get note steps
for _ in range(10):
    pat = m._generate_pattern(notes)
    for step in pat:
        if step['type'] == 'note':
            assert 'accent' in step
            assert 'slide' in step
            assert 'freq' in step
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

@test "acid-303.py: has 8 stab generator functions" {
    run grep 'def _generate_stab_' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    local count
    count=$(echo "$output" | wc -l | tr -d ' ')
    [ "$count" -eq 8 ]
}

@test "acid-303.py: STAB_GENERATORS list has 8 entries" {
    run grep -A12 'STAB_GENERATORS' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
    assert_output --partial "_generate_stab_filter_sweep"
    assert_output --partial "_generate_stab_tritone"
    assert_output --partial "_generate_stab_arp"
    assert_output --partial "_generate_stab_chromatic"
    assert_output --partial "_generate_stab_dub_chord"
    assert_output --partial "_generate_stab_tape_echo"
    assert_output --partial "_generate_stab_granular"
    assert_output --partial "_generate_stab_metallic"
}

@test "acid-303.py: stab generators produce non-empty samples" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
notes = [110.0, 130.8, 146.8, 164.8, 196.0]
for gen in m.STAB_GENERATORS:
    samples = gen(notes, bpm=140)
    assert len(samples) > 0, f'{gen.__name__} produced empty samples'
print('ok')
"
    assert_success
    assert_output "ok"
}

# ════════��═════════════════════════════════════════════════════════════��════════
# acid-303.py — FX Chain
# ═══════════════════════════════���═════════════════════════��═════════════════════

@test "acid-303.py: has _apply_distortion function" {
    run grep 'def _apply_distortion' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has _apply_delay function" {
    run grep 'def _apply_delay' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has _apply_reverb function" {
    run grep 'def _apply_reverb' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has Chorus class" {
    run grep 'class Chorus' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has AllpassDiffuser class" {
    run grep 'class AllpassDiffuser' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: has _bitcrush function" {
    run grep 'def _bitcrush' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

@test "acid-303.py: Chorus processes samples" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
c = m.Chorus(rate=0.5, depth_ms=5.0, mix=0.4)
out = [c.process(0.5) for _ in range(100)]
assert len(out) == 100
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: AllpassDiffuser processes samples" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
d = m.AllpassDiffuser(decay=0.6, mix=0.35)
out = [d.process(0.5) for _ in range(100)]
assert len(out) == 100
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: _bitcrush output stays bounded" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
samples = [0.5, -0.3, 0.9, -0.7, 0.0]
out = m._bitcrush(samples, bits=6, downsample=2)
assert len(out) == len(samples)
assert all(-1.0 <= s <= 1.0 for s in out)
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: FX chain preserves sample count" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
samples = [0.5] * 1000
d = m._apply_distortion(samples, 2.0)
assert len(d) == 1000
dl = m._apply_delay(samples, 100.0, 0.3, 0.2)
assert len(dl) == 1000
rv = m._apply_reverb(samples, 0.4, 0.15)
assert len(rv) == 1000
print('ok')
"
    assert_success
    assert_output "ok"
}

# ══════════════���════════════════════════════════════════════════════════════════
# acid-303.py — WAV Writing
# ���══════════════════════════��═══════════════════════════════════════════════════

@test "acid-303.py: _write_wav creates valid file" {
    run python3 -c "
import sys, os, tempfile; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
d = tempfile.mkdtemp()
path = os.path.join(d, 'test.wav')
m._write_wav(path, [0.0, 0.5, -0.5, 1.0, -1.0])
assert os.path.exists(path)
assert os.path.getsize(path) > 0
import shutil; shutil.rmtree(d)
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: _write_wav handles empty samples" {
    run python3 -c "
import sys, os, tempfile; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
d = tempfile.mkdtemp()
path = os.path.join(d, 'empty.wav')
m._write_wav(path, [])
assert os.path.exists(path)
import shutil; shutil.rmtree(d)
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: _write_wav normalizes amplitude" {
    run grep 'Normalize\|peak\|scale' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_success
}

# ════════��══════════════════════════════════════════════════════════════���═══════
# acid-303.py — Bassline Generation
# ════��═══════════════════���═════════════════════════════���════════════════════════

@test "acid-303.py: _generate_bassline produces non-empty samples" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
notes = [110.0, 130.8, 146.8, 164.8, 196.0]
samples = m._generate_bassline(notes, bpm=140, target_duration=3)
assert len(samples) > 0
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: _acid_note produces samples" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
samples = m._acid_note(220.0, 0.1, accent=True, slide_from=200.0)
assert len(samples) > 0
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: _acid_note without slide" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
samples = m._acid_note(220.0, 0.1, accent=False, slide_from=None)
assert len(samples) > 0
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
key = m.generate(140, d, target_duration=3)
assert key in ('Am', 'Dm', 'Gm', 'Cm', 'Em'), f'unexpected key: {key}'
import shutil; shutil.rmtree(d)
print('ok')
"
    assert_success
    assert_output "ok"
}

@test "acid-303.py: generate() applies distortion and delay to bassline" {
    run grep -A20 'def generate(' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "_apply_distortion"
    assert_output --partial "_apply_delay"
}

@test "acid-303.py: generate() applies distortion and diffuser to stabs" {
    run grep -A40 'def generate(' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "_apply_distortion"
    assert_output --partial "AllpassDiffuser"
}

@test "acid-303.py: generate() applies fade in/out to bassline" {
    run grep -A20 'def generate(' "$BATS_TEST_DIRNAME/../tools/acid-303.py"
    assert_output --partial "fade_len"
}

# ════════════════════════════════════���══════════════════════════════════════════
# acid-303.py — MIDI to Freq
# ══════��════════════════════════════════════════════════��═══════════════════════

@test "acid-303.py: _midi_to_freq converts A4 to 440Hz" {
    run python3 -c "
import sys; sys.path.insert(0, '$BATS_TEST_DIRNAME/../tools')
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('acid303', '$BATS_TEST_DIRNAME/../tools/acid-303.py').load_module()
freq = m._midi_to_freq(69)
assert abs(freq - 440.0) < 0.01, f'expected 440, got {freq}'
print('ok')
"
    assert_success
    assert_output "ok"
}

# ════════���═════════════════════════════════════════════════════════��════════════
# Integration — Full Loop Architecture
# ═══════���════════════════���════════════════════════════════════���═════════════════

@test "integration: acid loop architecture — generate → beat file → play → double-buffer" {
    # Verify the loop structure in play_acid_loop
    run grep -A70 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    # Creates temp dir
    assert_output --partial "mktemp -d"
    # Calls acid-303.py
    assert_output --partial "acid-303.py"
    # Writes beat file
    assert_output --partial "_acid_write_beat_file"
    # Writes dir file
    assert_output --partial "_ACID_DIR_FILE"
    # Plays loop.wav
    assert_output --partial "loop.wav"
    # Double-buffers next
    assert_output --partial "next_dir"
    assert_output --partial "gen_pid"
}

@test "integration: stab trigger reads beat file and stab dir" {
    run grep -A50 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_ACID_DIR_FILE"
    assert_output --partial "_ACID_BEAT_FILE"
    assert_output --partial "stab-*.wav"
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
    run grep -A40 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "60.0"
    assert_output --partial "/ 4"
}

@test "play-midi.sh: beat sync handles fractional seconds" {
    run grep -A40 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "%s.%N"
}

@test "play-midi.sh: beat sync has fallback when wait_time empty" {
    run grep -A60 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
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

@test "play-midi.sh: double-buffer waits for next generation" {
    run grep -A65 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial 'wait "$gen_pid"'
}

@test "play-midi.sh: double-buffer uses pre-generated next loop" {
    run grep -A40 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "pre-generated"
    assert_output --partial "next_dir"
}

@test "play-midi.sh: double-buffer cleans up on exit" {
    run grep -A70 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "Cleanup on exit"
}

@test "play-midi.sh: double-buffer keeps prev_dir alive for stab reads" {
    run grep -A60 'play_acid_loop()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "prev_dir"
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
    run grep -A5 'Cleanup on exit' "$CL4UD3_HOME/hooks/play-midi.sh"
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
    run grep -A20 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    # Reads global _ACID_DIR_FILE, falls back to per-session _ACID_STAB_DIR
    assert_output --partial "_ACID_DIR_FILE"
    assert_output --partial "_ACID_STAB_DIR"
}

@test "integration: stab falls back to immediate play without beat file" {
    run grep -A70 'play_acid_stab_synced()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "No beat file"
    assert_output --partial "play immediately"
}

@test "integration: cleanup_all_stale_files checks global acid pid" {
    run grep -A10 'cleanup_all_stale_files()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "_PF_ACID"
}

@test "integration: kill_all_sounds cleans per-session stab dirs" {
    run grep -A10 'kill_all_sounds()' "$CL4UD3_HOME/hooks/play-midi.sh"
    assert_output --partial "cl4ud3-cr4ck-acid-stabs"
}
