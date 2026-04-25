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
_ACID_NOTES_FILE="/tmp/.cl4ud3-acid-notes"
_ACID_CHORDS_FILE="/tmp/.cl4ud3-acid-chords"
_ACID_FIFO_PATH_FILE="/tmp/.cl4ud3-acid-fifo-path"

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
    local sf_override="${2:-}"  # optional soundfont override
    local sf="${sf_override:-$CL4UD3_SOUNDFONT}"
    [ ! -f "$midi_file" ] && return 1

    # Acid mode: drive gain hard for distortion + chorus for thickness
    local fs_extra=""
    if [ -n "$sf_override" ]; then
        fs_extra="-g 4.0 -o synth.chorus.active=yes -o synth.chorus.depth=3 -o synth.chorus.speed=0.2 -o synth.reverb.active=yes -o synth.reverb.room-size=0.2 -o synth.reverb.level=0.3 -o synth.sample-rate=22050"
    fi

    if [ -n "$CL4UD3_MIDI_PLAYER" ]; then
        if [[ "$CL4UD3_MIDI_PLAYER" == *fluidsynth* ]]; then
            # shellcheck disable=SC2086
            $CL4UD3_MIDI_PLAYER -ni $fs_extra "$sf" "$midi_file" >/dev/null 2>&1
        else
            # shellcheck disable=SC2086
            $CL4UD3_MIDI_PLAYER "$midi_file" >/dev/null 2>&1
        fi
    elif command -v fluidsynth >/dev/null 2>&1 && [ -n "$sf" ]; then
        # shellcheck disable=SC2086
        fluidsynth -ni $fs_extra "$sf" "$midi_file" >/dev/null 2>&1
    elif command -v timidity >/dev/null 2>&1; then
        timidity "$midi_file" >/dev/null 2>&1
    elif [ -x "$CL4UD3_HOME/bin/playmidi" ]; then
        "$CL4UD3_HOME/bin/playmidi" "$midi_file" >/dev/null 2>&1
    fi
}

play_acid_loop() {
    local bpm="${1:-120}"
    local sections=4      # sections per batch (each = 16 measures of A/B patterns)
    local measures=16     # measures per section

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

    # FIFO for fluidsynth shell commands (stabs + player control)
    local acid_fifo="/tmp/.cl4ud3-acid-fifo-$$"
    mkfifo "$acid_fifo" 2>/dev/null || return 1
    echo "$acid_fifo" > "/tmp/.cl4ud3-acid-fifo-path"

    local my_pidfile="$_PF_ACID"
    (
        # Survive parent shell exit (SIGHUP from bash tool calls)
        trap '' HUP
        local cur_dir="" next_dir="" prev_dir="" gen_pid=""
        local sf="${_ACID_303_SF:-$CL4UD3_SOUNDFONT}"

        # Generate first batch
        cur_dir=$(mktemp -d /tmp/.cl4ud3-acid-XXXXX)
        python3 "$CL4UD3_HOME/tools/acid-303.py" --bpm "$bpm" --output-dir "$cur_dir" --measures "$measures" --count "$sections" >/dev/null 2>&1 || {
            rm -rf "$cur_dir"; rm -f "$acid_fifo"; exit 1
        }

        # Publish note pool for FIFO stabs (in-key sync)
        [ -f "$cur_dir/notes.txt" ] && cp "$cur_dir/notes.txt" "$_ACID_NOTES_FILE"
        # Publish chord progression for pad layer
        [ -f "$cur_dir/chords.txt" ] && cp "$cur_dir/chords.txt" "$_ACID_CHORDS_FILE"

        # Open FIFO read-write — keeps it alive on macOS
        # (macOS tail -f exits when last writer closes FIFO = EOF)
        exec 7<>"$acid_fifo"

        # Start persistent fluidsynth reading from fd 7
        # Stabs + player control sent via FIFO path, read via fd 7
        # nohup protects from SIGHUP when parent shells exit
        nohup fluidsynth \
            -g 4.0 \
            -o synth.chorus.active=yes -o synth.chorus.depth=3 -o synth.chorus.speed=0.2 \
            -o synth.reverb.active=yes -o synth.reverb.room-size=0.2 -o synth.reverb.level=0.3 \
            -o synth.sample-rate=22050 \
            "$sf" "$cur_dir/loop.mid" <&7 >/dev/null 2>&1 &
        local fs_pid=$!

        # Give fluidsynth time to load SF2 + MIDI, then start looping
        sleep 1
        echo "player_loop -1" > "$acid_fifo"
        echo "player_start" > "$acid_fifo"

        # Vocal sample trigger — 20% chance every 16 measures (~80 measures avg)
        local vocals_dir="$CL4UD3_HOME/sounds/acid-vocals"
        if [ -d "$vocals_dir" ] && ls "$vocals_dir"/*.wav >/dev/null 2>&1; then
            local section_secs
            section_secs=$(awk "BEGIN { printf \"%.0f\", 16 * 4 * 60.0 / $bpm }" 2>/dev/null)
            [ -n "$section_secs" ] || section_secs=32
            (
                while [ -f "$my_pidfile" ]; do
                    sleep "$section_secs" 2>/dev/null || break
                    # 65% chance per 16-measure section
                    [ $((RANDOM % 20)) -ge 13 ] && continue
                    local wav
                    wav=$(find "$vocals_dir" -maxdepth 1 -name '*.wav' 2>/dev/null | sort -R | head -1)
                    if [ -n "$wav" ] && [ -f "$wav" ]; then
                        # shellcheck disable=SC2086
                        $WAV_PLAYER "$wav" >/dev/null 2>&1 &
                    fi
                done
            ) &
            local vocal_pid=$!
        fi

        # Dark pad chord trigger — sustained chords every 2-4 measures
        local pad_pid=""
        if [ "$_ACID_PADS_ENABLED" = "true" ] && [ -f "$_ACID_CHORDS_FILE" ]; then
            local measure_secs
            measure_secs=$(awk "BEGIN { printf \"%.0f\", 4 * 60.0 / $bpm }" 2>/dev/null)
            [ -n "$measure_secs" ] || measure_secs=2
            (
                while [ -f "$my_pidfile" ]; do
                    # Wait 4-8 measures between chords — sparse, let bass breathe
                    local wait_measures=$((4 + RANDOM % 5))
                    sleep $((wait_measures * measure_secs)) 2>/dev/null || break
                    [ -f "$my_pidfile" ] || break
                    # Play pad chord via FIFO
                    if [ -p "$acid_fifo" ]; then
                        _play_pad_via_fifo "$acid_fifo" "$bpm"
                    fi
                done
            ) &
            pad_pid=$!
        fi

        # Calculate batch duration in seconds
        local batch_secs
        batch_secs=$(awk "BEGIN { printf \"%.0f\", $sections * $measures * 4 * 60 / $bpm }" 2>/dev/null)
        [ -n "$batch_secs" ] || batch_secs=128

        while [ -f "$my_pidfile" ] && kill -0 "$fs_pid" 2>/dev/null; do
            if _acid_is_idle; then
                break
            fi

            # Publish stab dir for all terminals
            _acid_write_beat_file "$bpm"
            echo "$cur_dir" > "$_ACID_DIR_FILE"

            # Pre-generate next batch in background
            next_dir=$(mktemp -d /tmp/.cl4ud3-acid-XXXXX)
            python3 "$CL4UD3_HOME/tools/acid-303.py" --bpm "$bpm" --output-dir "$next_dir" --measures "$measures" --count "$sections" >/dev/null 2>&1 &
            gen_pid=$!

            # Wait for current batch to finish (~128s at 120bpm)
            # Check every 5s if we should stop
            local elapsed=0
            while [ "$elapsed" -lt "$batch_secs" ] && [ -f "$my_pidfile" ]; do
                sleep 5
                elapsed=$((elapsed + 5))
                _acid_touch_activity
                _acid_is_idle && break 2
            done

            # Wait for next batch
            if [ -n "$gen_pid" ]; then
                wait "$gen_pid" 2>/dev/null || { rm -rf "$next_dir"; next_dir=""; }
                gen_pid=""
            fi

            # Swap: kill old fluidsynth, start new with new MIDI
            # (can't reload MIDI via shell — fluidsynth keeps old file in memory)
            if [ -n "$next_dir" ] && [ -d "$next_dir" ] && [ -f "$next_dir/loop.mid" ]; then
                # Kill old fluidsynth
                echo "quit" > "$acid_fifo" 2>/dev/null || true
                kill "$fs_pid" 2>/dev/null; wait "$fs_pid" 2>/dev/null
                sleep 0.1

                # Swap in new batch
                cp "$next_dir/loop.mid" "$cur_dir/loop.mid"
                [ -f "$next_dir/notes.txt" ] && cp "$next_dir/notes.txt" "$_ACID_NOTES_FILE"
                [ -f "$next_dir/chords.txt" ] && cp "$next_dir/chords.txt" "$_ACID_CHORDS_FILE"

                # Start new fluidsynth with new MIDI (fd 7 still open)
                nohup fluidsynth \
                    -g 4.0 \
                    -o synth.chorus.active=yes -o synth.chorus.depth=3 -o synth.chorus.speed=0.2 \
                    -o synth.reverb.active=yes -o synth.reverb.room-size=0.2 -o synth.reverb.level=0.3 \
                    -o synth.sample-rate=22050 \
                    "$sf" "$cur_dir/loop.mid" <&7 >/dev/null 2>&1 &
                fs_pid=$!
                sleep 1
                echo "player_loop -1" > "$acid_fifo"
                echo "player_start" > "$acid_fifo"

                [ -n "$prev_dir" ] && rm -rf "$prev_dir"
                prev_dir=""
                rm -rf "$next_dir"
                next_dir=""
            fi
        done

        # Cleanup
        [ -n "$vocal_pid" ] && { kill "$vocal_pid" 2>/dev/null; wait "$vocal_pid" 2>/dev/null; }
        [ -n "$pad_pid" ] && { kill "$pad_pid" 2>/dev/null; wait "$pad_pid" 2>/dev/null; }
        echo "quit" > "$acid_fifo" 2>/dev/null || true
        [ -n "$gen_pid" ] && { kill "$gen_pid" 2>/dev/null; wait "$gen_pid" 2>/dev/null; }
        kill "$fs_pid" 2>/dev/null; wait "$fs_pid" 2>/dev/null
        exec 7>&- 2>/dev/null  # Close FIFO fd
        [ -n "$prev_dir" ] && rm -rf "$prev_dir"
        [ -n "$cur_dir" ] && rm -rf "$cur_dir"
        rm -f "$acid_fifo" "$_ACID_FIFO_PATH_FILE" "$_ACID_NOTES_FILE" "$_ACID_CHORDS_FILE"
        [ -n "$cur_dir" ] && rm -rf "$cur_dir"
        [ -n "$next_dir" ] && rm -rf "$next_dir"
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
    rm -f "$_ACID_BEAT_FILE" "$_ACID_DIR_FILE" "$_ACID_ACTIVITY_FILE" "$_ACID_NOTES_FILE" "$_ACID_CHORDS_FILE" "$_ACID_FIFO_PATH_FILE"
    # Kill any orphaned tail -f feeding the FIFO
    pkill -f "tail -f /tmp/.cl4ud3-acid-fifo" 2>/dev/null || true
    # Cleanup any orphaned acid temp dirs + FIFOs
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

# Calculate wait time to next 16th note on the beat grid
_acid_calc_beat_sync() {
    local bpm="$1"
    [ -f "$_ACID_BEAT_FILE" ] || { echo "0.05"; return; }
    local beat_start beat_bpm
    beat_start=$(head -1 "$_ACID_BEAT_FILE" 2>/dev/null | tr -d ' ')
    beat_bpm=$(tail -1 "$_ACID_BEAT_FILE" 2>/dev/null | tr -d ' ')
    [ -n "$beat_start" ] && [ -n "$beat_bpm" ] || { echo "0.05"; return; }

    local now
    if command -v gdate >/dev/null 2>&1; then
        now=$(gdate +%s.%N)
    elif date +%s.%N 2>/dev/null | grep -q '\.'; then
        now=$(date +%s.%N)
    else
        now=$(date +%s)
    fi

    awk "BEGIN {
        sixteenth = 60.0 / $beat_bpm / 4;
        elapsed = $now - $beat_start;
        beat_pos = elapsed - int(elapsed / sixteenth) * sixteenth;
        wait = sixteenth - beat_pos;
        if (wait < 0.01) wait = sixteenth;
        printf \"%.4f\", wait;
    }" 2>/dev/null || echo "0.05"
}

# Read note pool from global file, return as space-separated string
_acid_read_notes() {
    if [ -f "$_ACID_NOTES_FILE" ]; then
        tr '\n' ' ' < "$_ACID_NOTES_FILE" 2>/dev/null
    else
        # Fallback: A minor pentatonic across 2 octaves
        echo "45 48 50 52 55 57 60 62 64 67 69"
    fi
}

# Play acid stab via FIFO — sends raw noteon/cc/noteoff to persistent fluidsynth
# Channel 1 (bass = channel 0), same soundfont + effects chain
_play_stab_via_fifo() {
    local fifo="$1"
    local bpm="$2"

    # Read note pool
    local notes_str
    notes_str=$(_acid_read_notes)
    local notes=($notes_str)
    local num_notes=${#notes[@]}
    [ "$num_notes" -eq 0 ] && return

    # Beat-sync wait
    local wait_time
    wait_time=$(_acid_calc_beat_sync "$bpm")

    # Pick random note, octave up for stab
    local ni=$((RANDOM % num_notes))
    local base_note=${notes[$ni]}
    local octave_up=$((12 + (RANDOM % 2) * 12))  # +12 or +24
    local note=$((base_note + octave_up))
    [ "$note" -gt 96 ] && note=96

    # Pick random 303 program for channel 1
    local sqr_progs=(50 55 60 65 70 75 80 85)
    local bass_progs=(0 5 10 15 20 25 30 35 40 45)
    local prog
    if [ $((RANDOM % 3)) -lt 2 ]; then
        prog=${sqr_progs[$((RANDOM % ${#sqr_progs[@]}))]}
    else
        prog=${bass_progs[$((RANDOM % ${#bass_progs[@]}))]}
    fi

    # Pick stab style
    local style=$((RANDOM % 6))

    # Fire stab in background — timed events via sleep
    (
        sleep "$wait_time" 2>/dev/null || true

        # Set up channel 1: program + filter
        echo "prog 1 $prog" > "$fifo"
        echo "cc 1 71 127" > "$fifo"

        case $style in
            0) # squelch hit + dub echo
                echo "cc 1 74 127" > "$fifo"
                echo "noteon 1 $note 127" > "$fifo"
                sleep 0.1; echo "cc 1 74 80" > "$fifo"
                sleep 0.1; echo "cc 1 74 40" > "$fifo"
                sleep 0.15; echo "cc 1 74 15" > "$fifo"
                sleep 0.05; echo "noteoff 1 $note" > "$fifo"
                local vel=80
                for _ei in 1 2 3 4 5 6; do
                    sleep 0.75
                    [ "$vel" -lt 20 ] && break
                    local _cc=$((127 - _ei * 20)); [ "$_cc" -lt 20 ] && _cc=20
                    echo "cc 1 74 $_cc" > "$fifo"
                    echo "noteon 1 $note $vel" > "$fifo"
                    sleep 0.25; echo "noteoff 1 $note" > "$fifo"
                    vel=$((vel * 55 / 100))
                done
                ;;
            1) # acid scream — high + long delay
                local hn=$((note + 12))
                [ "$hn" -gt 96 ] && hn=96
                echo "cc 1 74 127" > "$fifo"
                echo "noteon 1 $hn 127" > "$fifo"
                sleep 0.2; echo "cc 1 74 90" > "$fifo"
                sleep 0.2; echo "cc 1 74 50" > "$fifo"
                sleep 0.2; echo "cc 1 74 15" > "$fifo"
                echo "noteoff 1 $hn" > "$fifo"
                local vel=85
                for _ei in 1 2 3 4 5 6 7; do
                    sleep 0.75
                    [ "$vel" -lt 20 ] && break
                    echo "cc 1 74 $((127 - _ei * 15))" > "$fifo"
                    echo "noteon 1 $hn $vel" > "$fifo"
                    sleep 0.2; echo "noteoff 1 $hn" > "$fifo"
                    vel=$((vel * 55 / 100))
                done
                ;;
            2) # chromatic slide up
                echo "cc 1 74 60" > "$fifo"
                local num=$((4 + RANDOM % 4))
                for ((si=0; si<num; si++)); do
                    local sn=$((note + si))
                    [ "$sn" -gt 96 ] && sn=96
                    echo "cc 1 74 $((60 + si * 10))" > "$fifo"
                    echo "noteon 1 $sn 110" > "$fifo"
                    sleep 0.11; echo "noteoff 1 $sn" > "$fifo"
                done
                local last=$((note + num - 1))
                [ "$last" -gt 96 ] && last=96
                local vel=65
                for _ei in 1 2 3 4 5; do
                    sleep 0.5
                    [ "$vel" -lt 20 ] && break
                    echo "noteon 1 $last $vel" > "$fifo"
                    sleep 0.2; echo "noteoff 1 $last" > "$fifo"
                    vel=$((vel * 55 / 100))
                done
                ;;
            3) # dub ping — single hit, deep echo
                echo "cc 1 74 127" > "$fifo"
                echo "noteon 1 $note 127" > "$fifo"
                sleep 0.15; echo "noteoff 1 $note" > "$fifo"
                local vel=95
                for _ei in 1 2 3 4 5 6 7 8 9 10; do
                    sleep 0.75
                    [ "$vel" -lt 20 ] && break
                    local cc=$((127 - _ei * 10))
                    [ "$cc" -lt 20 ] && cc=20
                    echo "cc 1 74 $cc" > "$fifo"
                    echo "noteon 1 $note $vel" > "$fifo"
                    sleep 0.15; echo "noteoff 1 $note" > "$fifo"
                    vel=$((vel * 55 / 100))
                done
                ;;
            4) # stutter — rapid fire
                echo "cc 1 74 100" > "$fifo"
                local num=$((8 + RANDOM % 9))
                for ((si=0; si<num; si++)); do
                    local v=$((80 + RANDOM % 48))
                    [ "$v" -gt 127 ] && v=127
                    echo "cc 1 74 $((30 + RANDOM % 98))" > "$fifo"
                    echo "noteon 1 $note $v" > "$fifo"
                    sleep 0.0625; echo "noteoff 1 $note" > "$fifo"
                done
                local vel=55
                for _ei in 1 2 3 4 5; do
                    sleep 0.5
                    [ "$vel" -lt 20 ] && break
                    echo "noteon 1 $note $vel" > "$fifo"
                    sleep 0.15; echo "noteoff 1 $note" > "$fifo"
                    vel=$((vel * 55 / 100))
                done
                ;;
            5) # ghost — quiet hit, reverse swell echo
                echo "cc 1 74 60" > "$fifo"
                echo "noteon 1 $note 50" > "$fifo"
                sleep 0.1; echo "noteoff 1 $note" > "$fifo"
                for _ei in 0 1 2 3 4 5 6 7 8 9; do
                    sleep 0.5
                    local v
                    if [ "$_ei" -lt 4 ]; then
                        v=$((40 + _ei * 15))
                    else
                        v=$((100 - (_ei - 4) * 18))
                        [ "$v" -lt 15 ] && v=15
                    fi
                    echo "cc 1 74 $((40 + _ei * 10))" > "$fifo"
                    echo "noteon 1 $note $v" > "$fifo"
                    sleep 0.15; echo "noteoff 1 $note" > "$fifo"
                done
                ;;
        esac
    ) &
    disown $! 2>/dev/null || true
}

# Play dark pad chord via FIFO — sustained chord on channel 2
# Reads chord progression from $_ACID_CHORDS_FILE, cycles through
# Channel 2 (bass=0, stabs=1, pads=2), same fluidsynth + effects chain
_play_pad_via_fifo() {
    local fifo="$1"
    local bpm="$2"

    # Read chord progression
    [ -f "$_ACID_CHORDS_FILE" ] || return
    local num_chords
    num_chords=$(wc -l < "$_ACID_CHORDS_FILE" 2>/dev/null | tr -d ' ')
    [ "$num_chords" -gt 0 ] 2>/dev/null || return

    # Cycle through chords using a counter file
    local counter_file="/tmp/.cl4ud3-acid-pad-counter"
    local idx=0
    [ -f "$counter_file" ] && idx=$(cat "$counter_file" 2>/dev/null || echo 0)
    idx=$((idx % num_chords))
    echo $(( (idx + 1) % num_chords )) > "$counter_file"

    # Read chord at index (1-based for sed)
    local chord_line
    chord_line=$(sed -n "$((idx + 1))p" "$_ACID_CHORDS_FILE" 2>/dev/null)
    [ -n "$chord_line" ] || return

    # Parse notes
    local chord_notes=($chord_line)
    [ "${#chord_notes[@]}" -gt 0 ] || return

    # Pick a crisp SQR program for Amiga crunch character
    local sqr_progs=(50 55 60 65 70 75 80 85)
    local prog=${sqr_progs[$((RANDOM % ${#sqr_progs[@]}))]}

    # Long sustain: 8-16 beats — let chords breathe like Detroit
    local sustain_beats=$((8 + RANDOM % 9))
    local sustain_secs
    sustain_secs=$(awk "BEGIN { printf \"%.1f\", $sustain_beats * 60.0 / $bpm }" 2>/dev/null)
    [ -n "$sustain_secs" ] || sustain_secs=6

    # Fire pad in background — sustained chord
    (
        # Set up channel 2: program + Amiga tracker crunch
        echo "prog 2 $prog" > "$fifo"
        echo "cc 2 7 53" > "$fifo"     # channel volume — 42%, pad way behind bass
        echo "cc 2 71 127" > "$fifo"   # resonance — max squelch, Amiga nasty
        echo "cc 2 74 95" > "$fifo"    # filter — wide open, let harmonics through
        echo "cc 2 11 127" > "$fifo"   # expression — max overdrive into bitcrush
        echo "cc 2 91 127" > "$fifo"   # reverb send — max, big wash
        echo "cc 2 93 80" > "$fifo"    # chorus send — thicken
        echo "cc 2 1 40" > "$fifo"     # mod wheel — subtle wobble, tracker style

        # Note on — hot velocity drives distortion character
        for n in "${chord_notes[@]}"; do
            echo "noteon 2 $n 110" > "$fifo"
        done

        # Slow filter sweep during sustain — adds movement
        local half_secs
        half_secs=$(awk "BEGIN { printf \"%.1f\", $sustain_secs / 2 }" 2>/dev/null)
        [ -n "$half_secs" ] || half_secs=3
        sleep "$half_secs" 2>/dev/null || true
        echo "cc 2 74 75" > "$fifo"    # filter closes slightly mid-chord
        sleep "$half_secs" 2>/dev/null || true

        # Slow filter close during release — long tail into reverb
        echo "cc 2 74 55" > "$fifo"
        sleep 0.5
        echo "cc 2 74 35" > "$fifo"
        sleep 0.4
        echo "cc 2 74 20" > "$fifo"
        sleep 0.3

        # Note off — all chord notes
        for n in "${chord_notes[@]}"; do
            echo "noteoff 2 $n" > "$fifo"
        done
    ) &
    disown $! 2>/dev/null || true
}

# Play a random stab — FIFO injection when acid loop running, else MIDI file fallback
# FIFO mode: raw events on channel 1, same fluidsynth + effects as bassline
# Fallback: separate fluidsynth instance with 303 soundfont
play_acid_stab_synced() {
    local bpm="${_ACID_303_BPM:-120}"

    # Prefer FIFO injection (same fluidsynth instance as bassline)
    if [ -f "$_ACID_FIFO_PATH_FILE" ]; then
        local fifo
        fifo=$(cat "$_ACID_FIFO_PATH_FILE" 2>/dev/null)
        if [ -n "$fifo" ] && [ -p "$fifo" ]; then
            _play_stab_via_fifo "$fifo" "$bpm"
            return 0
        fi
    fi

    # ── Fallback: MIDI file + separate fluidsynth ──
    local stab_dir=""
    if [ -f "$_ACID_DIR_FILE" ]; then
        stab_dir=$(cat "$_ACID_DIR_FILE" 2>/dev/null)
        [ -d "$stab_dir" ] || stab_dir=""
    fi
    if [ -z "$stab_dir" ] || ! ls "$stab_dir"/stab-*.mid >/dev/null 2>&1; then
        _ensure_stab_set "$bpm" || return 0
        stab_dir="$_ACID_STAB_DIR"
    fi

    local stab
    stab=$(find "$stab_dir" -maxdepth 1 -name 'stab-*.mid' 2>/dev/null | sort -R | head -1)
    [ -n "$stab" ] && [ -f "$stab" ] || return 0

    # Beat-sync wait then play
    local wait_time
    wait_time=$(_acid_calc_beat_sync "$bpm")

    (
        sleep "$wait_time" 2>/dev/null || true
        [ -f "$stab" ] && _play_midi_blocking "$stab" "${_ACID_303_SF:-}"
    ) &
    disown $! 2>/dev/null || true
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
    pkill -f "tail -f /tmp/.cl4ud3-acid-fifo" 2>/dev/null || true
    rm -f /tmp/.cl4ud3-cr4ck-sound-pid-* /tmp/.cl4ud3-cr4ck-music-pid-* /tmp/.cl4ud3-cr4ck-timer-pid-* /tmp/.cl4ud3-cr4ck-loading-pid-* /tmp/.cl4ud3-cr4ck-acid-pid /tmp/.cl4ud3-cr4ck-acid-beat /tmp/.cl4ud3-cr4ck-acid-dir /tmp/.cl4ud3-acid-notes /tmp/.cl4ud3-acid-chords /tmp/.cl4ud3-acid-fifo-path
    rm -rf /tmp/.cl4ud3-acid-* /tmp/.cl4ud3-cr4ck-acid-stabs-* 2>/dev/null || true
    return 0
}
