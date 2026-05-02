#!/bin/bash
# cl4ud3-cr4ck — SessionStart hook
# Displays random ASCII crack screen + plays startup jingle

CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
if [ ! -f "$CL4UD3_HOME/config.sh" ]; then
    exit 0
fi
source "$CL4UD3_HOME/config.sh"
source "$CL4UD3_HOME/hooks/play-midi.sh"

# ASCII art splash — writes directly to /dev/tty to bypass capture
if [ "$CL4UD3_STARTUP_ART" != "false" ]; then
    bash "$CL4UD3_HOME/art/screens.sh"
fi

# Startup jingle — uses configured jingle directory
JINGLE_DIR="${CL4UD3_JINGLE_DIR:-all}"
if [ "$JINGLE_DIR" = "all" ]; then
    # Session-scoped temp dir for combined jingle symlinks
    _ALL_DIR="/tmp/.cl4ud3-cr4ck-all-jingles-$CL4UD3_SID"
    mkdir -p "$_ALL_DIR"
    rm -f "$_ALL_DIR"/*.mid "$_ALL_DIR"/*.wav 2>/dev/null
    # Symlink files individually to avoid broken glob symlinks
    for f in "$CL4UD3_HOME/sounds/startup-warez"/*.mid "$CL4UD3_HOME/sounds/startup-warez"/*.wav \
             "$CL4UD3_HOME/sounds/startup"/*.mid "$CL4UD3_HOME/sounds/startup"/*.wav; do
        [ -f "$f" ] && ln -sf "$f" "$_ALL_DIR/" 2>/dev/null
    done
    # Include custom jingles if enabled and dir exists
    if [ "$CL4UD3_CUSTOM_JINGLES" != "false" ] && [ -d "$CL4UD3_HOME/sounds/custom" ]; then
        for f in "$CL4UD3_HOME/sounds/custom"/*.mid "$CL4UD3_HOME/sounds/custom"/*.wav; do
            [ -f "$f" ] && ln -sf "$f" "$_ALL_DIR/" 2>/dev/null
        done
    fi
    JINGLE_PATH="$_ALL_DIR"
else
    JINGLE_PATH="$CL4UD3_HOME/sounds/$JINGLE_DIR"
fi
# Skip intro jingle if acid mode on + 303 loop already playing
_acid_303_running=false
if [ "$CL4UD3_ACID_MODE" = "true" ]; then
    _PF_ACID="/tmp/.cl4ud3-cr4ck-acid-pid"
    if [ -f "$_PF_ACID" ]; then
        _acid_pid=$(cat "$_PF_ACID" 2>/dev/null)
        if [ -n "$_acid_pid" ] && kill -0 "$_acid_pid" 2>/dev/null; then
            _acid_303_running=true
        fi
    fi
fi

if [ "$_acid_303_running" = "true" ]; then
    : # Acid 303 playing — skip intro jingle
elif [ "$CL4UD3_STARTUP_JINGLE" != "false" ] && [ "$CL4UD3_SOUNDS_ENABLED" != "false" ]; then
    if [ "$CL4UD3_STARTUP_LOOP" = "false" ]; then
        play_random_from_dir "$JINGLE_PATH"
    else
        play_loop_from_dir "$JINGLE_PATH"

        # Auto-kill loop after max play time
        MAX_PLAY="${CL4UD3_INTRO_MAX_PLAY:-60}"
        if [ "$MAX_PLAY" -gt 0 ] 2>/dev/null; then
            (
                sleep "$MAX_PLAY"
                source "$CL4UD3_HOME/hooks/play-midi.sh" 2>/dev/null
                kill_music_loop
            ) &
            local_timer_pid=$!
            if [ -n "$local_timer_pid" ]; then
                echo "$local_timer_pid" > "$_PF_TIMER"
                disown "$local_timer_pid" 2>/dev/null
            fi
        fi
    fi
fi

exit 0
