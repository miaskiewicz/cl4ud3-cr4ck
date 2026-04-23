#!/bin/bash
# cl4ud3-cr4ck — UserPromptSubmit hook
# Kills startup jingle loop when user sends first message

CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
if [ ! -f "$CL4UD3_HOME/config.sh" ]; then
    exit 0
fi
source "$CL4UD3_HOME/config.sh"
source "$CL4UD3_HOME/hooks/play-midi.sh"

# Kill startup music loop if still playing
if [ "$CL4UD3_KILL_INTRO_ON_MESSAGE" != "false" ]; then
    kill_music_loop
fi

exit 0
