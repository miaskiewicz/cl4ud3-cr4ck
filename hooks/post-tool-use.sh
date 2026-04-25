#!/bin/bash
# cl4ud3-cr4ck — PostToolUse hook
# Plays modem "connected" confirmation chirp after tool execution completes
# Pairs with PreToolUse (dialing) for full modem lifecycle
# Cooldown prevents sound spam on rapid sequential tool calls

CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
if [ ! -f "$CL4UD3_HOME/config.sh" ]; then
    exit 0
fi
source "$CL4UD3_HOME/config.sh"
source "$CL4UD3_HOME/hooks/play-midi.sh"

# Reset acid idle timeout — any session's tool call keeps 303 alive
_acid_touch_activity

# Cooldown: skip if last sound was < 10 seconds ago
# Shares cooldown with PreToolUse to avoid overlapping modem sounds
LOCKFILE="/tmp/.cl4ud3-cr4ck-tool-cooldown"
if [ -f "$LOCKFILE" ]; then
    LAST=$(stat -f %m "$LOCKFILE" 2>/dev/null || stat -c %Y "$LOCKFILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    DIFF=$((NOW - LAST))
    if [ "$DIFF" -lt "${CL4UD3_TOOL_COOLDOWN:-10}" ]; then
        # 🍄 acid bypasses sound cooldown
        if [ -f "$CL4UD3_HOME/hooks/acid-mode.sh" ]; then
            source "$CL4UD3_HOME/hooks/acid-mode.sh"
            if _is_acid_active; then
                _acid_effect
                _acid_start_loop
                _acid_maybe_stab
            fi
        fi
        exit 0
    fi
fi
touch "$LOCKFILE"

if [ "$CL4UD3_MODEM_SOUNDS" != "false" ] && [ "$CL4UD3_SOUNDS_ENABLED" != "false" ]; then
    play_random_from_dir "$CL4UD3_HOME/sounds/modem"
    # 🍄 acid mode: sometimes layer distorted robo-acid voice over modem sound
    if [ -f "$CL4UD3_HOME/hooks/acid-mode.sh" ]; then
        source "$CL4UD3_HOME/hooks/acid-mode.sh"
        if _is_acid_active && [ $((RANDOM % 16)) -eq 0 ]; then
            ROBO_WAV=$(find "$CL4UD3_HOME/sounds/acid-vocals" -maxdepth 1 -name 'robo-acid*.wav' 2>/dev/null | sort -R | head -1)
            [ -n "$ROBO_WAV" ] && [ -f "$ROBO_WAV" ] && play_audio "$ROBO_WAV"
        fi
    fi
fi

# 🍄
if [ -f "$CL4UD3_HOME/hooks/acid-mode.sh" ]; then
    source "$CL4UD3_HOME/hooks/acid-mode.sh"
    if _is_acid_active; then
        _acid_effect
        _acid_start_loop
        _acid_maybe_stab
    fi
    # ⚡ strobe — keep loop alive between tool calls
    if _is_strobe_active; then
        _strobe_start_loop
    fi
fi

exit 0
