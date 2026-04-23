#!/bin/bash
# cl4ud3-cr4ck — SessionStart hook
# Displays random ASCII crack screen + plays startup jingle

CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
source "$CL4UD3_HOME/config.sh" 2>/dev/null
source "$CL4UD3_HOME/hooks/play-midi.sh" 2>/dev/null

# ASCII art splash — writes directly to /dev/tty to bypass capture
if [ "$CL4UD3_STARTUP_ART" != "false" ]; then
    bash "$CL4UD3_HOME/art/screens.sh"
fi

# Startup jingle — uses configured jingle directory
JINGLE_DIR="${CL4UD3_JINGLE_DIR:-all}"
if [ "$JINGLE_DIR" = "all" ]; then
    # Combine both dirs into temp dir for random pick
    _ALL_DIR="/tmp/.cl4ud3-cr4ck-all-jingles"
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
if [ "$CL4UD3_STARTUP_JINGLE" != "false" ] && [ "$CL4UD3_SOUNDS_ENABLED" != "false" ]; then
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
            echo $! > "$_PF_TIMER"
            disown 2>/dev/null
        fi
    fi
fi

exit 0
