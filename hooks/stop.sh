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

# Kill acid loop if running
kill_acid_loop 2>/dev/null || true

# Kill strobe (this tab + all if config changed to off)
if [ -f "$CL4UD3_HOME/hooks/acid-mode.sh" ]; then
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    _strobe_kill 2>/dev/null || true
fi

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
    if [ "$DIFF" -lt "${CL4UD3_STOP_COOLDOWN:-3}" ]; then
        # 🍄 acid bypasses sound cooldown
        if [ -f "$CL4UD3_HOME/hooks/acid-mode.sh" ]; then
            source "$CL4UD3_HOME/hooks/acid-mode.sh"
            if _is_acid_active; then
                _acid_effect
                _acid_random_stab
            fi
        fi
        exit 0
    fi
fi
touch "$LOCKFILE"

# 🍄
_acid_is_on=false
if [ -f "$CL4UD3_HOME/hooks/acid-mode.sh" ]; then
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    if _is_acid_active; then
        _acid_is_on=true
        _acid_effect
        _acid_random_stab
    fi
fi

# Normal glitch sound — skip if acid mode replaces it
if ! $_acid_is_on || [ "$_ACID_REPLACE_SOUNDS" != "true" ]; then
    if [ "$CL4UD3_GLITCH_SOUNDS" != "false" ] && [ "$CL4UD3_SOUNDS_ENABLED" != "false" ]; then
        play_random_from_dir "$CL4UD3_HOME/sounds/glitches"
    fi
fi

exit 0
