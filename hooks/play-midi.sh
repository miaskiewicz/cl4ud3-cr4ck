#!/bin/bash
# cl4ud3-cr4ck — shared sound playback utility
# Plays WAV (via platform audio player) or MIDI (via FluidSynth/timidity) files
# WAV preferred when available — raw 8-bit garbage sounds better
# Supports: macOS, Linux (PulseAudio/PipeWire/ALSA), WSL

CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
if [ ! -f "$CL4UD3_HOME/config.sh" ]; then
    # When sourced by hooks, warn but don't kill the sourcing script
    echo "cl4ud3-cr4ck: config not found at $CL4UD3_HOME/config.sh" >&2
    return 0 2>/dev/null || true
fi
# shellcheck disable=SC1091
source "$CL4UD3_HOME/config.sh"

# Restrictive permissions for PID/cooldown files (owner-only)
umask 077

# Per-session PID files — PPID = Claude Code process, unique per tab/session
# Prevents cross-tab sound killing (maximum chaos mode)
CL4UD3_SID="${CL4UD3_SID:-$PPID}"
_PF_SOUND="/tmp/.cl4ud3-cr4ck-sound-pid-$CL4UD3_SID"
_PF_MUSIC="/tmp/.cl4ud3-cr4ck-music-pid-$CL4UD3_SID"
_PF_TIMER="/tmp/.cl4ud3-cr4ck-timer-pid-$CL4UD3_SID"
_PF_LOADING="/tmp/.cl4ud3-cr4ck-loading-pid-$CL4UD3_SID"
# Acid 303 loop = GLOBAL singleton (one bassline across all terminals)
# Stabs are per-session but read global beat/dir files
_PF_ACID="/tmp/.cl4ud3-cr4ck-acid-pid"
_ACID_BEAT_FILE="/tmp/.cl4ud3-cr4ck-acid-beat"
_ACID_DIR_FILE="/tmp/.cl4ud3-cr4ck-acid-dir"
_ACID_ACTIVITY_FILE="/tmp/.cl4ud3-cr4ck-acid-activity"
_ACID_STAB_DIR="/tmp/.cl4ud3-cr4ck-acid-stabs-$CL4UD3_SID"

# Touch activity file — called from hooks to signal tool use
_acid_touch_activity() {
    touch "$_ACID_ACTIVITY_FILE"
}

# Check if idle too long — returns 0 if timed out
_acid_is_idle() {
    local timeout="${_ACID_IDLE_TIMEOUT:-30}"
    [ -f "$_ACID_ACTIVITY_FILE" ] || return 0
    local last now diff
    last=$(stat -f %m "$_ACID_ACTIVITY_FILE" 2>/dev/null || stat -c %Y "$_ACID_ACTIVITY_FILE" 2>/dev/null || echo 0)
    now=$(date +%s)
    diff=$((now - last))
    [ "$diff" -ge "$timeout" ] && return 0
    return 1
}

# Clean stale PID files for this session (dead processes)
cleanup_session_files() {
    for pf in "$_PF_SOUND" "$_PF_MUSIC" "$_PF_TIMER" "$_PF_LOADING" "$_PF_ACID"; do
        if [ -f "$pf" ]; then
            local pid
            pid=$(cat "$pf" 2>/dev/null)
            if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
                rm -f "$pf"
            fi
        fi
    done
}

# Clean stale PID files from ALL sessions (dead processes)
cleanup_all_stale_files() {
    # Also check global acid PID
    if [ -f "$_PF_ACID" ]; then
        local acid_pid
        acid_pid=$(cat "$_PF_ACID" 2>/dev/null)
        if [ -z "$acid_pid" ] || ! kill -0 "$acid_pid" 2>/dev/null; then
            rm -f "$_PF_ACID" "$_ACID_BEAT_FILE" "$_ACID_DIR_FILE"
        fi
    fi
    for pf in /tmp/.cl4ud3-cr4ck-sound-pid-* /tmp/.cl4ud3-cr4ck-music-pid-* /tmp/.cl4ud3-cr4ck-timer-pid-* /tmp/.cl4ud3-cr4ck-loading-pid-*; do
        [ -f "$pf" ] || continue
        local pid
        pid=$(cat "$pf" 2>/dev/null)
        if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$pf"
        fi
    done
}

# Detect platform and set WAV player
_detect_wav_player() {
    if [ -n "$CL4UD3_WAV_PLAYER" ]; then
        echo "$CL4UD3_WAV_PLAYER"
        return
    fi
    case "$(uname -s)" in
        Darwin)
            echo "afplay"
            ;;
        Linux|GNU*)
            # PipeWire/PulseAudio > ALSA > mpv > ffplay
            if command -v pw-play >/dev/null 2>&1; then
                echo "pw-play"
            elif command -v paplay >/dev/null 2>&1; then
                echo "paplay"
            elif command -v aplay >/dev/null 2>&1; then
                echo "aplay"
            elif command -v mpv >/dev/null 2>&1; then
                echo "mpv --no-video"
            elif command -v ffplay >/dev/null 2>&1; then
                echo "ffplay -nodisp -autoexit"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Git Bash / MSYS2 on Windows
            if command -v powershell.exe >/dev/null 2>&1; then
                echo "powershell.exe -c (New-Object Media.SoundPlayer"
            fi
            ;;
    esac
}

WAV_PLAYER=$(_detect_wav_player)

play_audio() {
    local file="$1"
    [ ! -f "$file" ] && return 1
    [ "$CL4UD3_SOUNDS_ENABLED" = "false" ] && return 0

    cleanup_session_files

    case "$file" in
        *.wav|*.mp3|*.aiff|*.aac)
            if [ -n "$WAV_PLAYER" ]; then
                # shellcheck disable=SC2086  # Intentional word splitting for player + flags
                $WAV_PLAYER "$file" >/dev/null 2>&1 &
                local player_pid=$!
                if [ -n "$player_pid" ]; then
                    echo "$player_pid" > "$_PF_SOUND"
                    disown "$player_pid" 2>/dev/null
                fi
            fi
            ;;
        *.mid|*.midi)
            play_midi "$file"
            return
            ;;
    esac
}

play_midi() {
    local midi_file="$1"
    [ ! -f "$midi_file" ] && return 1
    [ "$CL4UD3_SOUNDS_ENABLED" = "false" ] && return 0

    cleanup_session_files

    if [ -n "$CL4UD3_MIDI_PLAYER" ]; then
        if [[ "$CL4UD3_MIDI_PLAYER" == *fluidsynth* ]]; then
            # shellcheck disable=SC2086
            $CL4UD3_MIDI_PLAYER -ni "$CL4UD3_SOUNDFONT" "$midi_file" >/dev/null 2>&1 &
        else
            # shellcheck disable=SC2086
            $CL4UD3_MIDI_PLAYER "$midi_file" >/dev/null 2>&1 &
        fi
    elif command -v fluidsynth >/dev/null 2>&1 && [ -n "$CL4UD3_SOUNDFONT" ]; then
        fluidsynth -ni --reverb=no --chorus=no "$CL4UD3_SOUNDFONT" "$midi_file" >/dev/null 2>&1 &
    elif command -v timidity >/dev/null 2>&1; then
        timidity "$midi_file" >/dev/null 2>&1 &
    elif [ -x "$CL4UD3_HOME/bin/playmidi" ]; then
        "$CL4UD3_HOME/bin/playmidi" "$midi_file" >/dev/null 2>&1 &
    fi
    local player_pid=$!
    if [ -n "$player_pid" ]; then
        echo "$player_pid" > "$_PF_SOUND"
        disown "$player_pid" 2>/dev/null
    fi
}

play_random_from_dir() {
    local dir="$1"
    [ ! -d "$dir" ] && return 1
    [ "$CL4UD3_SOUNDS_ENABLED" = "false" ] && return 0

    cleanup_session_files

    # Track play history per directory — cycle through all before repeating
    local dir_hash hist_file
    dir_hash=$(echo "$dir" | md5sum 2>/dev/null | cut -c1-8 || echo "$dir" | md5 2>/dev/null | cut -c1-8 || echo "x")
    hist_file="/tmp/.cl4ud3-cr4ck-lastplay-${dir_hash}"

    # Prefer WAV files, fall back to MIDI
    local file candidates
    candidates=$(find "$dir" -maxdepth 1 -type f \( -name '*.wav' -o -name '*.mp3' \) 2>/dev/null)
    if [ -z "$candidates" ]; then
        candidates=$(find -L "$dir" -maxdepth 1 -type f -name '*.mid' 2>/dev/null)
    fi
    [ -z "$candidates" ] && return 1

    local count
    count=$(echo "$candidates" | wc -l | tr -d ' ')

    # Filter out all previously played files to cycle through entire pool
    local remaining=""
    if [ "$count" -gt 1 ] && [ -s "$hist_file" ]; then
        remaining=$(echo "$candidates" | grep -v -F -x -f "$hist_file" || true)
        # All played? Reset cycle — exclude only last played to avoid repeat
        if [ -z "$remaining" ]; then
            local last_played
            last_played=$(tail -1 "$hist_file" 2>/dev/null)
            rm -f "$hist_file"
            if [ -n "$last_played" ]; then
                remaining=$(echo "$candidates" | grep -v "^${last_played}$" || true)
            fi
            [ -z "$remaining" ] && remaining="$candidates"
        fi
    else
        remaining="$candidates"
    fi

    file=$(echo "$remaining" | sort -R | head -1)

    if [ -n "$file" ]; then
        echo "$file" >> "$hist_file"
        play_audio "$file"
    fi
}

# Loop playback — plays random sounds from dir until killed
# PID saved to per-session pidfile
play_loop_from_dir() {
    local dir="$1"
    [ ! -d "$dir" ] && return 1
    [ "$CL4UD3_SOUNDS_ENABLED" = "false" ] && return 0

    # Kill any existing loop first
    kill_music_loop

    # Start loop in background subshell
    local my_pidfile="$_PF_MUSIC"
    (
        while true; do
            # Self-terminate if pidfile removed (Stop hook deletes it)
            [ ! -f "$my_pidfile" ] && break

            # For looping, prefer MIDI (longer jingles) over WAV
            local file
            file=$(find -L "$dir" -maxdepth 1 -type f -name '*.mid' 2>/dev/null | sort -R | head -1)
            if [ -z "$file" ]; then
                file=$(find "$dir" -maxdepth 1 -type f \( -name '*.wav' -o -name '*.mp3' \) 2>/dev/null | sort -R | head -1)
            fi
            [ -z "$file" ] && break

            # Play synchronously (blocking) so we know when it ends
            case "$file" in
                *.wav|*.mp3|*.aiff|*.aac)
                    if [ -n "$WAV_PLAYER" ]; then
                        # shellcheck disable=SC2086
                        $WAV_PLAYER "$file" >/dev/null 2>&1
                    fi
                    ;;
                *.mid|*.midi)
                    if [ -n "$CL4UD3_MIDI_PLAYER" ]; then
                        if [[ "$CL4UD3_MIDI_PLAYER" == *fluidsynth* ]]; then
                            # shellcheck disable=SC2086
                            $CL4UD3_MIDI_PLAYER -ni "$CL4UD3_SOUNDFONT" "$file" >/dev/null 2>&1
                        else
                            # shellcheck disable=SC2086
                            $CL4UD3_MIDI_PLAYER "$file" >/dev/null 2>&1
                        fi
                    elif command -v fluidsynth >/dev/null 2>&1 && [ -n "$CL4UD3_SOUNDFONT" ]; then
                        fluidsynth -ni --reverb=no --chorus=no "$CL4UD3_SOUNDFONT" "$file" >/dev/null 2>&1
                    elif command -v timidity >/dev/null 2>&1; then
                        timidity "$file" >/dev/null 2>&1
                    elif [ -x "$CL4UD3_HOME/bin/playmidi" ]; then
                        "$CL4UD3_HOME/bin/playmidi" "$file" >/dev/null 2>&1
                    fi
                    ;;
            esac

            sleep 0.5  # Brief gap between tracks
        done
    ) &
    local loop_pid=$!
    if [ -n "$loop_pid" ]; then
        echo "$loop_pid" > "$_PF_MUSIC"
        disown "$loop_pid" 2>/dev/null
    fi
}

# Kill this session's active sounds (modem, etc.) — does NOT touch other sessions
kill_active_sounds() {
    if [ -f "$_PF_SOUND" ]; then
        local pid
        pid=$(cat "$_PF_SOUND" 2>/dev/null)
        [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
        rm -f "$_PF_SOUND"
    fi
    return 0
}

# Kill this session's looping music — does NOT touch other sessions (chaos mode!)
kill_music_loop() {
    if [ -f "$_PF_MUSIC" ]; then
        local pid
        pid=$(cat "$_PF_MUSIC" 2>/dev/null)
        if [ -n "$pid" ]; then
            # Kill children (fluidsynth/afplay spawned by loop), then loop itself
            pkill -P "$pid" 2>/dev/null || true
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$_PF_MUSIC"
    fi
    # Kill this session's intro-timer subshell
    if [ -f "$_PF_TIMER" ]; then
        local tpid
        tpid=$(cat "$_PF_TIMER" 2>/dev/null)
        [ -n "$tpid" ] && kill "$tpid" 2>/dev/null || true
        rm -f "$_PF_TIMER"
    fi
    return 0
}

# ── Acid 303 loop + beat-synced stabs ────────────────────────────────────────

# Write current epoch + bpm to beat file (used for stab sync)
_acid_write_beat_file() {
    local bpm="$1"
    if command -v gdate >/dev/null 2>&1; then
        gdate +%s.%N > "$_ACID_BEAT_FILE"
    elif date +%s.%N 2>/dev/null | grep -q '\.'; then
        date +%s.%N > "$_ACID_BEAT_FILE"
    else
        date +%s > "$_ACID_BEAT_FILE"
    fi
    echo " $bpm" >> "$_ACID_BEAT_FILE"
}

# Play generative acid 303 loop — GLOBAL singleton, double-buffered
# Only one instance runs across all terminals. Stabs read global files.
# Play a MIDI file in blocking mode (used by acid loop)
_play_midi_blocking() {
    local midi_file="$1"
    [ ! -f "$midi_file" ] && return 1

    if [ -n "$CL4UD3_MIDI_PLAYER" ]; then
        if [[ "$CL4UD3_MIDI_PLAYER" == *fluidsynth* ]]; then
            # shellcheck disable=SC2086
            $CL4UD3_MIDI_PLAYER -ni "$CL4UD3_SOUNDFONT" "$midi_file" >/dev/null 2>&1
        else
            # shellcheck disable=SC2086
            $CL4UD3_MIDI_PLAYER "$midi_file" >/dev/null 2>&1
        fi
    elif command -v fluidsynth >/dev/null 2>&1 && [ -n "$CL4UD3_SOUNDFONT" ]; then
        fluidsynth -ni "$CL4UD3_SOUNDFONT" "$midi_file" >/dev/null 2>&1
    elif command -v timidity >/dev/null 2>&1; then
        timidity "$midi_file" >/dev/null 2>&1
    elif [ -x "$CL4UD3_HOME/bin/playmidi" ]; then
        "$CL4UD3_HOME/bin/playmidi" "$midi_file" >/dev/null 2>&1
    fi
}

play_acid_loop() {
    local bpm="${1:-140}"

    # Global singleton: if another terminal already runs 303, skip
    if [ -f "$_PF_ACID" ]; then
        local existing_pid
        existing_pid=$(cat "$_PF_ACID" 2>/dev/null)
        if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
            return 0
        fi
        rm -f "$_PF_ACID"
    fi

    _acid_touch_activity

    local my_pidfile="$_PF_ACID"
    (
        local prev_dir=""

        while [ -f "$my_pidfile" ]; do
            if _acid_is_idle; then
                break
            fi

            # Generate MIDI — instant, no double-buffering needed
            local dir
            dir=$(mktemp -d /tmp/.cl4ud3-acid-XXXXX)
            python3 "$CL4UD3_HOME/tools/acid-303.py" --bpm "$bpm" --output-dir "$dir" >/dev/null 2>&1 || {
                rm -rf "$dir"; continue
            }

            # Publish beat + stab dir for all terminals
            _acid_write_beat_file "$bpm"
            echo "$dir" > "$_ACID_DIR_FILE"

            # Play loop.mid blocking
            if [ -f "$dir/loop.mid" ]; then
                _play_midi_blocking "$dir/loop.mid"
            fi

            # Cleanup previous dir
            [ -n "$prev_dir" ] && rm -rf "$prev_dir"
            prev_dir="$dir"
        done

        # Cleanup on exit
        [ -n "$prev_dir" ] && rm -rf "$prev_dir"
        rm -f "$my_pidfile" "$_ACID_BEAT_FILE" "$_ACID_DIR_FILE" "$_ACID_ACTIVITY_FILE"
    ) &
    local loop_pid=$!
    if [ -n "$loop_pid" ]; then
        echo "$loop_pid" > "$_PF_ACID"
        disown "$loop_pid" 2>/dev/null
    fi
}

# Kill acid 303 loop + cleanup global files
kill_acid_loop() {
    if [ -f "$_PF_ACID" ]; then
        local pid
        pid=$(cat "$_PF_ACID" 2>/dev/null)
        if [ -n "$pid" ]; then
            pkill -P "$pid" 2>/dev/null || true
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$_PF_ACID"
    fi
    rm -f "$_ACID_BEAT_FILE" "$_ACID_DIR_FILE" "$_ACID_ACTIVITY_FILE"
    # Cleanup any orphaned acid temp dirs
    rm -rf /tmp/.cl4ud3-acid-* 2>/dev/null || true
    return 0
}

# Check if global 303 loop is running (any terminal)
is_acid_loop_running() {
    [ -f "$_PF_ACID" ] || return 1
    local pid
    pid=$(cat "$_PF_ACID" 2>/dev/null)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && return 0
    return 1
}

# Ensure global beat clock exists — all stabs sync to this grid
# Created once, persists until acid mode deactivated
_ensure_beat_clock() {
    local bpm="${1:-140}"
    if [ ! -f "$_ACID_BEAT_FILE" ]; then
        _acid_write_beat_file "$bpm"
    fi
}

# Ensure per-session stab set exists (for stabs-only mode, no 303 needed)
_ensure_stab_set() {
    local bpm="${1:-140}"
    # If 303 running, use its stabs
    if [ -f "$_ACID_DIR_FILE" ]; then
        local gdir
        gdir=$(cat "$_ACID_DIR_FILE" 2>/dev/null)
        if [ -d "$gdir" ] && ls "$gdir"/stab-*.mid >/dev/null 2>&1; then
            return 0
        fi
    fi
    # Generate standalone stab set for this session
    if [ ! -d "$_ACID_STAB_DIR" ] || ! ls "$_ACID_STAB_DIR"/stab-*.mid >/dev/null 2>&1; then
        mkdir -p "$_ACID_STAB_DIR"
        python3 "$CL4UD3_HOME/tools/acid-303.py" --bpm "$bpm" --output-dir "$_ACID_STAB_DIR" --duration 3 >/dev/null 2>&1 || return 1
    fi
    # Always ensure global clock
    _ensure_beat_clock "$bpm"
    return 0
}

# Play a random stab — reads from 303 dir if running, else own stab set
# Beat-synced when 303 running, immediate when standalone
play_acid_stab_synced() {
    local bpm="${_ACID_303_BPM:-140}"

    # Find stab dir: prefer global 303, fall back to per-session
    local stab_dir=""
    if [ -f "$_ACID_DIR_FILE" ]; then
        stab_dir=$(cat "$_ACID_DIR_FILE" 2>/dev/null)
        [ -d "$stab_dir" ] || stab_dir=""
    fi
    if [ -z "$stab_dir" ] || ! ls "$stab_dir"/stab-*.mid >/dev/null 2>&1; then
        # No 303 running — use/generate per-session stabs
        _ensure_stab_set "$bpm" || return 0
        stab_dir="$_ACID_STAB_DIR"
    fi

    # Pick random stab
    local stab
    stab=$(find "$stab_dir" -maxdepth 1 -name 'stab-*.mid' 2>/dev/null | sort -R | head -1)
    [ -n "$stab" ] && [ -f "$stab" ] || return 0

    # Beat-sync if beat file exists (303 running), else play immediately
    if [ -f "$_ACID_BEAT_FILE" ]; then
        local beat_start beat_bpm
        beat_start=$(head -1 "$_ACID_BEAT_FILE" 2>/dev/null | tr -d ' ')
        beat_bpm=$(tail -1 "$_ACID_BEAT_FILE" 2>/dev/null | tr -d ' ')

        if [ -n "$beat_start" ] && [ -n "$beat_bpm" ]; then
            local now
            if command -v gdate >/dev/null 2>&1; then
                now=$(gdate +%s.%N)
            elif date +%s.%N 2>/dev/null | grep -q '\.'; then
                now=$(date +%s.%N)
            else
                now=$(date +%s)
            fi

            local wait_time
            wait_time=$(awk "BEGIN {
                sixteenth = 60.0 / $beat_bpm / 4;
                elapsed = $now - $beat_start;
                beat_pos = elapsed - int(elapsed / sixteenth) * sixteenth;
                wait = sixteenth - beat_pos;
                if (wait < 0.01) wait = sixteenth;
                printf \"%.4f\", wait;
            }" 2>/dev/null)
            [ -n "$wait_time" ] || wait_time="0.05"

            (
                sleep "$wait_time" 2>/dev/null || true
                [ -f "$stab" ] && play_midi "$stab"
            ) &
            disown $! 2>/dev/null || true
            return 0
        fi
    fi

    # No beat file — play immediately in background
    [ -f "$stab" ] && play_midi "$stab"
}

# Play a WAV file in blocking mode (used by acid loop)
play_wav_blocking() {
    local file="$1"
    [ ! -f "$file" ] && return 1
    if [ -n "$WAV_PLAYER" ]; then
        # shellcheck disable=SC2086
        $WAV_PLAYER "$file" >/dev/null 2>&1
    fi
}

# Nuclear option: kill ALL cl4ud3 sounds across ALL sessions
# Use only for manual cleanup, not in hooks
kill_all_sounds() {
    killall fluidsynth 2>/dev/null || true
    killall afplay 2>/dev/null || true
    killall pw-play 2>/dev/null || true
    killall paplay 2>/dev/null || true
    killall aplay 2>/dev/null || true
    rm -f /tmp/.cl4ud3-cr4ck-sound-pid-* /tmp/.cl4ud3-cr4ck-music-pid-* /tmp/.cl4ud3-cr4ck-timer-pid-* /tmp/.cl4ud3-cr4ck-loading-pid-* /tmp/.cl4ud3-cr4ck-acid-pid /tmp/.cl4ud3-cr4ck-acid-beat /tmp/.cl4ud3-cr4ck-acid-dir
    rm -rf /tmp/.cl4ud3-acid-* /tmp/.cl4ud3-cr4ck-acid-stabs-* 2>/dev/null || true
    return 0
}
