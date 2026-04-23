#!/bin/bash
# cl4ud3-cr4ck — PreToolUse hook
# Plays dial-up modem connection sound when Claude runs a tool
# Cooldown prevents sound spam on rapid sequential tool calls

CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
if [ ! -f "$CL4UD3_HOME/config.sh" ]; then
    exit 0
fi
source "$CL4UD3_HOME/config.sh"
source "$CL4UD3_HOME/hooks/play-midi.sh"

# Kill startup music loop if still playing
kill_music_loop

# Cooldown: skip if last sound was < 10 seconds ago
LOCKFILE="/tmp/.cl4ud3-cr4ck-tool-cooldown"
if [ -f "$LOCKFILE" ]; then
    LAST=$(stat -f %m "$LOCKFILE" 2>/dev/null || stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    DIFF=$((NOW - LAST))
    [ "$DIFF" -lt 10 ] && exit 0
fi
touch "$LOCKFILE"

if [ "$CL4UD3_MODEM_SOUNDS" != "false" ] && [ "$CL4UD3_SOUNDS_ENABLED" != "false" ]; then
    play_random_from_dir "$CL4UD3_HOME/sounds/modem"
fi

exit 0
