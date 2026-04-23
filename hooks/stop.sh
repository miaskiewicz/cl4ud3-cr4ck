#!/bin/bash
# cl4ud3-cr4ck — Stop hook (Claude done, awaiting input)
# Plays random video game glitch sound
# Cooldown-only approach — no stdin reading (that blocks exit)

CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
if [ ! -f "$CL4UD3_HOME/config.sh" ]; then
    exit 0
fi
source "$CL4UD3_HOME/config.sh"
source "$CL4UD3_HOME/hooks/play-midi.sh"

# Kill startup music loop if still playing
kill_music_loop

# Kill any modem sound still playing
kill_active_sounds

# Sweep stale PID files from all sessions (dead processes)
cleanup_all_stale_files

# Clean up orphaned jingle symlink directories
for d in /tmp/.cl4ud3-cr4ck-all-jingles-*; do
    [ -d "$d" ] || continue
    # Remove if no associated music loop is running
    sid="${d##*-jingles-}"
    music_pf="/tmp/.cl4ud3-cr4ck-music-pid-$sid"
    if [ ! -f "$music_pf" ]; then
        rm -rf "$d"
    fi
done

# Cooldown: skip if last sound was < 3 seconds ago
LOCKFILE="/tmp/.cl4ud3-cr4ck-stop-cooldown"
if [ -f "$LOCKFILE" ]; then
    LAST=$(stat -f %m "$LOCKFILE" 2>/dev/null || stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    DIFF=$((NOW - LAST))
    if [ "$DIFF" -lt 3 ]; then
        # 🍄 acid bypasses sound cooldown
        if [ -f "$CL4UD3_HOME/hooks/acid-mode.sh" ]; then
            source "$CL4UD3_HOME/hooks/acid-mode.sh"
            _is_acid_active && _acid_effect
        fi
        exit 0
    fi
fi
touch "$LOCKFILE"

if [ "$CL4UD3_GLITCH_SOUNDS" != "false" ] && [ "$CL4UD3_SOUNDS_ENABLED" != "false" ]; then
    play_random_from_dir "$CL4UD3_HOME/sounds/glitches"
fi

# 🍄
if [ -f "$CL4UD3_HOME/hooks/acid-mode.sh" ]; then
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _is_acid_active && _acid_effect
fi

exit 0
