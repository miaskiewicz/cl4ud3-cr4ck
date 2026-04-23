#!/bin/bash
# cl4ud3-cr4ck — Stop hook (Claude done, awaiting input)
# Plays random video game glitch sound
# Cooldown-only approach — no stdin reading (that blocks exit)

CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
source "$CL4UD3_HOME/config.sh" 2>/dev/null
source "$CL4UD3_HOME/hooks/play-midi.sh" 2>/dev/null

# Kill startup music loop if still playing
kill_music_loop

# Kill any modem sound still playing
kill_active_sounds

# Cooldown: skip if last sound was < 3 seconds ago
LOCKFILE="/tmp/.cl4ud3-cr4ck-stop-cooldown"
if [ -f "$LOCKFILE" ]; then
    LAST=$(stat -f %m "$LOCKFILE" 2>/dev/null || stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    DIFF=$((NOW - LAST))
    if [ "$DIFF" -lt 3 ]; then
        echo "$(date '+%H:%M:%S') cooldown skip (${DIFF}s)" >> /tmp/.cl4ud3-stop-debug.log
        exit 0
    fi
fi
touch "$LOCKFILE"

if [ "$CL4UD3_GLITCH_SOUNDS" != "false" ] && [ "$CL4UD3_SOUNDS_ENABLED" != "false" ]; then
    echo "$(date '+%H:%M:%S') playing glitch" >> /tmp/.cl4ud3-stop-debug.log
    play_random_from_dir "$CL4UD3_HOME/sounds/glitches"
fi

exit 0
