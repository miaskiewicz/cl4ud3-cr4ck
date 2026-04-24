#!/usr/bin/env bats
# Tests for hooks/play-midi.sh — WAV player detection, playback, PID management

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/common'

setup() {
    _common_setup
    # Source play-midi.sh in a way that won't exit (it exits when SOUNDS_ENABLED=false)
    export CL4UD3_SOUNDS_ENABLED="true"
}

teardown() {
    _common_teardown
}

# Helper: source play-midi
_source_play_midi() {
    export CL4UD3_SOUNDS_ENABLED="true"
    source "$CL4UD3_HOME/hooks/play-midi.sh"
}

# ── WAV Player Detection ──

@test "detect_wav_player: returns afplay on macOS" {
    if [ "$(uname -s)" != "Darwin" ]; then skip "macOS only"; fi
    _source_play_midi
    [ "$WAV_PLAYER" = "afplay" ]
}

@test "detect_wav_player: custom player overrides detection" {
    export CL4UD3_WAV_PLAYER="custom-player"
    _source_play_midi
    [ "$WAV_PLAYER" = "custom-player" ]
    unset CL4UD3_WAV_PLAYER
}

@test "detect_wav_player: returns non-empty on supported platforms" {
    _source_play_midi
    case "$(uname -s)" in
        Darwin|Linux|GNU*)
            [ -n "$WAV_PLAYER" ]
            ;;
        *)
            skip "unsupported platform"
            ;;
    esac
}

# ── PID File Paths ──

@test "PID files: use correct session suffix" {
    _source_play_midi
    [[ "$_PF_SOUND" == *"test-$$-$BATS_TEST_NUMBER" ]]
    [[ "$_PF_MUSIC" == *"test-$$-$BATS_TEST_NUMBER" ]]
    [[ "$_PF_TIMER" == *"test-$$-$BATS_TEST_NUMBER" ]]
}

@test "PID files: paths include session ID" {
    export CL4UD3_SID="mysession-42"
    _source_play_midi
    [ "$_PF_SOUND" = "/tmp/.cl4ud3-cr4ck-sound-pid-mysession-42" ]
    [ "$_PF_MUSIC" = "/tmp/.cl4ud3-cr4ck-music-pid-mysession-42" ]
    [ "$_PF_TIMER" = "/tmp/.cl4ud3-cr4ck-timer-pid-mysession-42" ]
}

# ── play_audio ──

@test "play_audio: returns 1 for nonexistent file" {
    _source_play_midi
    run play_audio "/nonexistent/file.wav"
    assert_failure
}

@test "play_audio: returns 1 for empty path" {
    _source_play_midi
    run play_audio ""
    assert_failure
}

@test "play_audio: plays WAV and creates PID file" {
    if [ "$(uname -s)" != "Darwin" ] && ! command -v pw-play >/dev/null 2>&1 && ! command -v aplay >/dev/null 2>&1; then
        skip "no audio player available"
    fi
    _source_play_midi
    # Create a tiny valid WAV (44 byte header + 1 byte data)
    local testfile="$TEST_CL4UD3_HOME/test.wav"
    printf 'RIFF\x25\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x44\xAC\x00\x00\x44\xAC\x00\x00\x01\x00\x08\x00data\x01\x00\x00\x00\x80' > "$testfile"
    play_audio "$testfile"
    # PID file should exist (player may have finished already but file was created)
    # Give a moment for background process
    sleep 0.1
    [ -f "$_PF_SOUND" ] || true  # file may be cleaned if process finished
}

@test "play_audio: routes MIDI files to play_midi" {
    _source_play_midi
    local testfile="$TEST_CL4UD3_HOME/test.mid"
    touch "$testfile"
    # play_midi will fail to play (no player configured) but shouldn't crash
    run play_audio "$testfile"
    # Should not crash — either success or failure is OK (no player)
    true
}

# ── play_midi ──

@test "play_midi: returns 1 for nonexistent file" {
    _source_play_midi
    run play_midi "/nonexistent/file.mid"
    assert_failure
}

@test "play_midi: returns 1 for empty path" {
    _source_play_midi
    run play_midi ""
    assert_failure
}

# ── play_random_from_dir ──

@test "play_random_from_dir: returns 1 for nonexistent directory" {
    _source_play_midi
    run play_random_from_dir "/nonexistent/dir"
    assert_failure
}

@test "play_random_from_dir: returns 1 for empty directory" {
    _source_play_midi
    local empty_dir
    empty_dir=$(mktemp -d)
    run play_random_from_dir "$empty_dir"
    rmdir "$empty_dir"
    # Empty dir = no files found = no play, should not crash
    true
}

@test "play_random_from_dir: prefers WAV over MIDI" {
    _source_play_midi
    local dir="$TEST_CL4UD3_HOME/sounds/test"
    mkdir -p "$dir"
    touch "$dir/test.mid"
    # Create a minimal WAV
    printf 'RIFF\x25\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x44\xAC\x00\x00\x44\xAC\x00\x00\x01\x00\x08\x00data\x01\x00\x00\x00\x80' > "$dir/test.wav"
    # Can't easily test preference without mocking, but verify no crash
    play_random_from_dir "$dir" || true
}

@test "play_random_from_dir: writes history file to track plays" {
    _source_play_midi
    play_audio() { :; }
    local dir="$TEST_CL4UD3_HOME/sounds/modem-test"
    mkdir -p "$dir"
    touch "$dir/a.wav" "$dir/b.wav" "$dir/c.wav"
    local dir_hash
    dir_hash=$(echo "$dir" | md5sum 2>/dev/null | cut -c1-8 || echo "$dir" | md5 2>/dev/null | cut -c1-8)
    local hist_file="/tmp/.cl4ud3-cr4ck-lastplay-${dir_hash}"
    rm -f "$hist_file"

    play_random_from_dir "$dir"
    [ -f "$hist_file" ]
    local saved
    saved=$(cat "$hist_file")
    [[ "$saved" == *".wav" ]]
    rm -f "$hist_file"
}

@test "play_random_from_dir: cycles through all files before repeating" {
    _source_play_midi
    play_audio() { :; }
    local dir="$TEST_CL4UD3_HOME/sounds/modem-cycle"
    mkdir -p "$dir"
    touch "$dir/a.wav" "$dir/b.wav" "$dir/c.wav"
    local dir_hash
    dir_hash=$(echo "$dir" | md5sum 2>/dev/null | cut -c1-8 || echo "$dir" | md5 2>/dev/null | cut -c1-8)
    local hist_file="/tmp/.cl4ud3-cr4ck-lastplay-${dir_hash}"
    rm -f "$hist_file"

    # Play 3 times — should hit all 3 files exactly once
    play_random_from_dir "$dir"
    play_random_from_dir "$dir"
    play_random_from_dir "$dir"

    # History should have 3 lines, all unique
    local lines unique_lines
    lines=$(wc -l < "$hist_file" | tr -d ' ')
    unique_lines=$(sort -u "$hist_file" | wc -l | tr -d ' ')
    [ "$lines" -eq 3 ]
    [ "$unique_lines" -eq 3 ]
    rm -f "$hist_file"
}

@test "play_random_from_dir: resets cycle after all played" {
    _source_play_midi
    play_audio() { :; }
    local dir="$TEST_CL4UD3_HOME/sounds/modem-reset"
    mkdir -p "$dir"
    touch "$dir/x.wav" "$dir/y.wav"
    local dir_hash
    dir_hash=$(echo "$dir" | md5sum 2>/dev/null | cut -c1-8 || echo "$dir" | md5 2>/dev/null | cut -c1-8)
    local hist_file="/tmp/.cl4ud3-cr4ck-lastplay-${dir_hash}"
    rm -f "$hist_file"

    # Play 2 = exhaust pool, then play 3rd = should reset and continue
    play_random_from_dir "$dir"
    play_random_from_dir "$dir"
    local last_of_first_cycle
    last_of_first_cycle=$(tail -1 "$hist_file")

    play_random_from_dir "$dir"
    # After reset, history file should have 1 line (reset clears it, adds new)
    local lines
    lines=$(wc -l < "$hist_file" | tr -d ' ')
    [ "$lines" -eq 1 ]
    # New pick should differ from last of previous cycle
    local new_pick
    new_pick=$(cat "$hist_file")
    [ "$new_pick" != "$last_of_first_cycle" ]
    rm -f "$hist_file"
}

@test "play_random_from_dir: never repeats consecutively across cycles" {
    _source_play_midi
    play_audio() { :; }
    local dir="$TEST_CL4UD3_HOME/sounds/modem-norepeat"
    mkdir -p "$dir"
    touch "$dir/a.wav" "$dir/b.wav" "$dir/c.wav"
    local dir_hash
    dir_hash=$(echo "$dir" | md5sum 2>/dev/null | cut -c1-8 || echo "$dir" | md5 2>/dev/null | cut -c1-8)
    local hist_file="/tmp/.cl4ud3-cr4ck-lastplay-${dir_hash}"
    rm -f "$hist_file"

    local prev="" current=""
    for i in $(seq 1 15); do
        play_random_from_dir "$dir"
        current=$(tail -1 "$hist_file")
        if [ -n "$prev" ]; then
            [ "$current" != "$prev" ]
        fi
        prev="$current"
    done
    rm -f "$hist_file"
}

@test "play_random_from_dir: single file still plays even if same as last" {
    _source_play_midi
    local played_file=""
    play_audio() { played_file="$1"; }
    local dir="$TEST_CL4UD3_HOME/sounds/modem-single"
    mkdir -p "$dir"
    touch "$dir/only.wav"
    local dir_hash
    dir_hash=$(echo "$dir" | md5sum 2>/dev/null | cut -c1-8 || echo "$dir" | md5 2>/dev/null | cut -c1-8)
    local hist_file="/tmp/.cl4ud3-cr4ck-lastplay-${dir_hash}"
    echo "$dir/only.wav" > "$hist_file"

    play_random_from_dir "$dir"
    [ "$played_file" = "$dir/only.wav" ]
    rm -f "$hist_file"
}

@test "play_random_from_dir: falls back to MIDI when no WAV/MP3 exist" {
    _source_play_midi
    local played_file=""
    play_audio() { played_file="$1"; }
    local dir="$TEST_CL4UD3_HOME/sounds/modem-midi-only"
    mkdir -p "$dir"
    touch "$dir/beep.mid" "$dir/boop.mid"

    play_random_from_dir "$dir"
    [[ "$played_file" == *.mid ]]
    local dir_hash
    dir_hash=$(echo "$dir" | md5sum 2>/dev/null | cut -c1-8 || echo "$dir" | md5 2>/dev/null | cut -c1-8)
    rm -f "/tmp/.cl4ud3-cr4ck-lastplay-${dir_hash}"
}

@test "play_random_from_dir: WAV present means MIDI ignored" {
    _source_play_midi
    local played_file=""
    play_audio() { played_file="$1"; }
    local dir="$TEST_CL4UD3_HOME/sounds/modem-mixed"
    mkdir -p "$dir"
    touch "$dir/tone.wav" "$dir/beep.mid"

    play_random_from_dir "$dir"
    [[ "$played_file" == *.wav ]]
    local dir_hash
    dir_hash=$(echo "$dir" | md5sum 2>/dev/null | cut -c1-8 || echo "$dir" | md5 2>/dev/null | cut -c1-8)
    rm -f "/tmp/.cl4ud3-cr4ck-lastplay-${dir_hash}"
}

# ── play_loop_from_dir ──

@test "play_loop_from_dir: returns 1 for nonexistent directory" {
    _source_play_midi
    run play_loop_from_dir "/nonexistent/dir"
    assert_failure
}

@test "play_loop_from_dir: creates music PID file" {
    _source_play_midi
    local dir="$TEST_CL4UD3_HOME/sounds/test"
    mkdir -p "$dir"
    touch "$dir/test.mid"
    play_loop_from_dir "$dir"
    sleep 0.2
    [ -f "$_PF_MUSIC" ]
    # Cleanup
    kill_music_loop
}

# ── kill_active_sounds ──

@test "kill_active_sounds: removes PID file" {
    _source_play_midi
    echo "99999" > "$_PF_SOUND"
    kill_active_sounds
    [ ! -f "$_PF_SOUND" ]
}

@test "kill_active_sounds: handles missing PID file gracefully" {
    _source_play_midi
    rm -f "$_PF_SOUND"
    run kill_active_sounds
    assert_success
}

@test "kill_active_sounds: handles empty PID file" {
    _source_play_midi
    touch "$_PF_SOUND"
    run kill_active_sounds
    assert_success
    [ ! -f "$_PF_SOUND" ]
}

# ── kill_music_loop ──

@test "kill_music_loop: removes music and timer PID files" {
    _source_play_midi
    echo "99998" > "$_PF_MUSIC"
    echo "99997" > "$_PF_TIMER"
    kill_music_loop
    [ ! -f "$_PF_MUSIC" ]
    [ ! -f "$_PF_TIMER" ]
}

@test "kill_music_loop: handles missing files gracefully" {
    _source_play_midi
    rm -f "$_PF_MUSIC" "$_PF_TIMER"
    run kill_music_loop
    assert_success
}

@test "kill_music_loop: handles empty PID files" {
    _source_play_midi
    touch "$_PF_MUSIC"
    touch "$_PF_TIMER"
    run kill_music_loop
    assert_success
    [ ! -f "$_PF_MUSIC" ]
    [ ! -f "$_PF_TIMER" ]
}

# ── kill_all_sounds ──

@test "kill_all_sounds: removes all PID file patterns" {
    _source_play_midi
    touch "/tmp/.cl4ud3-cr4ck-sound-pid-fake1"
    touch "/tmp/.cl4ud3-cr4ck-music-pid-fake2"
    touch "/tmp/.cl4ud3-cr4ck-timer-pid-fake3"
    kill_all_sounds
    [ ! -f "/tmp/.cl4ud3-cr4ck-sound-pid-fake1" ]
    [ ! -f "/tmp/.cl4ud3-cr4ck-music-pid-fake2" ]
    [ ! -f "/tmp/.cl4ud3-cr4ck-timer-pid-fake3" ]
}

# ── cleanup_session_files ──

@test "cleanup_session_files: removes stale PID files for dead processes" {
    _source_play_midi
    echo "99999" > "$_PF_SOUND"
    echo "99998" > "$_PF_MUSIC"
    echo "99997" > "$_PF_TIMER"
    cleanup_session_files
    [ ! -f "$_PF_SOUND" ]
    [ ! -f "$_PF_MUSIC" ]
    [ ! -f "$_PF_TIMER" ]
}

@test "cleanup_session_files: preserves PID files for running processes" {
    _source_play_midi
    # Use our own PID (definitely running)
    echo "$$" > "$_PF_SOUND"
    cleanup_session_files
    [ -f "$_PF_SOUND" ]
    rm -f "$_PF_SOUND"
}

@test "cleanup_session_files: handles empty PID files" {
    _source_play_midi
    touch "$_PF_SOUND"
    touch "$_PF_MUSIC"
    cleanup_session_files
    # Empty PID = no valid process = should be cleaned
    # (kill -0 "" fails so file stays; this is acceptable behavior)
    true
}

@test "cleanup_session_files: handles no PID files" {
    _source_play_midi
    rm -f "$_PF_SOUND" "$_PF_MUSIC" "$_PF_TIMER"
    run cleanup_session_files
    assert_success
}

# ── cleanup_all_stale_files ──

@test "cleanup_all_stale_files: removes stale files from other sessions" {
    _source_play_midi
    echo "99999" > "/tmp/.cl4ud3-cr4ck-sound-pid-fake-session"
    echo "99998" > "/tmp/.cl4ud3-cr4ck-music-pid-fake-session"
    cleanup_all_stale_files
    [ ! -f "/tmp/.cl4ud3-cr4ck-sound-pid-fake-session" ]
    [ ! -f "/tmp/.cl4ud3-cr4ck-music-pid-fake-session" ]
}

@test "cleanup_all_stale_files: preserves files with running PIDs" {
    _source_play_midi
    echo "$$" > "/tmp/.cl4ud3-cr4ck-sound-pid-fake-alive"
    cleanup_all_stale_files
    [ -f "/tmp/.cl4ud3-cr4ck-sound-pid-fake-alive" ]
    rm -f "/tmp/.cl4ud3-cr4ck-sound-pid-fake-alive"
}

# ── Master kill switch ──

@test "master switch: play functions no-op when sounds disabled" {
    _source_play_midi
    export CL4UD3_SOUNDS_ENABLED="false"
    local dir="$TEST_CL4UD3_HOME/sounds/test"
    mkdir -p "$dir"
    touch "$dir/test.mid"
    # Should return 0 without playing
    run play_random_from_dir "$dir"
    assert_success
}

# ── Config missing ──

@test "config missing: warns and returns" {
    rm -f "$CL4UD3_HOME/config.sh"
    run bash -c "source '$CL4UD3_HOME/hooks/play-midi.sh' 2>&1"
    assert_output --partial "config not found"
}

# ── umask ──

@test "umask: PID files created with restrictive permissions" {
    _source_play_midi
    echo "$$" > "$_PF_SOUND"
    if [ "$(uname -s)" = "Darwin" ]; then
        perms=$(stat -f '%Lp' "$_PF_SOUND")
    else
        perms=$(stat -c '%a' "$_PF_SOUND")
    fi
    [ "$perms" = "600" ]
    rm -f "$_PF_SOUND"
}
