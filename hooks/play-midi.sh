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

# Clean stale PID files for this session (dead processes)
cleanup_session_files() {
    for pf in "$_PF_SOUND" "$_PF_MUSIC" "$_PF_TIMER"; do
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
    for pf in /tmp/.cl4ud3-cr4ck-sound-pid-* /tmp/.cl4ud3-cr4ck-music-pid-* /tmp/.cl4ud3-cr4ck-timer-pid-*; do
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

    # Prefer WAV files, fall back to MIDI
    local file
    file=$(find "$dir" -maxdepth 1 -type f \( -name '*.wav' -o -name '*.mp3' \) 2>/dev/null | sort -R | head -1)
    if [ -z "$file" ]; then
        file=$(find -L "$dir" -maxdepth 1 -type f -name '*.mid' 2>/dev/null | sort -R | head -1)
    fi
    [ -n "$file" ] && play_audio "$file"
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

# Nuclear option: kill ALL cl4ud3 sounds across ALL sessions
# Use only for manual cleanup, not in hooks
kill_all_sounds() {
    killall fluidsynth 2>/dev/null || true
    killall afplay 2>/dev/null || true
    killall pw-play 2>/dev/null || true
    killall paplay 2>/dev/null || true
    killall aplay 2>/dev/null || true
    rm -f /tmp/.cl4ud3-cr4ck-sound-pid-* /tmp/.cl4ud3-cr4ck-music-pid-* /tmp/.cl4ud3-cr4ck-timer-pid-*
    return 0
}
