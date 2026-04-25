#!/bin/bash
# cl4ud3-cr4ck — ACID MODE
# Psychedelic terminal effects triggered between tool calls
# Writes directly to /dev/tty to bypass Claude Code capture
# Toggle via: /cr4ck acid

# ── Hidden acid config ───────────────────────────────────────────────────────
_ACID_303_ENABLED="${_ACID_303_ENABLED:-false}"
_ACID_STABS_ENABLED="${_ACID_STABS_ENABLED:-true}"
_ACID_303_BPM="${_ACID_303_BPM:-120}"
_ACID_STAB_CHANCE="${_ACID_STAB_CHANCE:-0.95}"
_ACID_STAB_RANDOM_CHANCE="${_ACID_STAB_RANDOM_CHANCE:-0.6}"
_ACID_IDLE_TIMEOUT="${_ACID_IDLE_TIMEOUT:-100}"
_ACID_PADS_ENABLED="${_ACID_PADS_ENABLED:-false}"
_ACID_REPLACE_SOUNDS="${_ACID_REPLACE_SOUNDS:-false}"

# Rainbow palette — full spectrum cycle
_ACID_COLORS=(196 202 208 214 220 226 190 154 118 82 46 49 51 45 39 33 93 129 165 201)

# Trippy unicode glyphs
_ACID_GLYPHS=(◉ ◈ ◆ ✦ ✧ ✶ ◬ ▲ ▼ ◢ ◣ ◤ ◥ ☯ ⚡ ★ ☆ ♦ ♠ ♣ ♥ ⊕ ⊗ ⊛ ⊘ ◎ ⦿ ❋ ✿ ❖ ▓ ▒ ░ █ ╳ ∞ ∴ ∵ ≋ ≈ ◊ ☀ ☾ ☽)

# Mini acid art fragments — short bursts
_ACID_FRAGS=(
"  ◉◈◆✦ L S D . E X E ✦◆◈◉  "
"  ▓▒░ r34l1ty.exe h4s st0pp3d ░▒▓  "
"  ✶✧✦ 3y3s w1d3 0p3n ✦✧✶  "
"  ◢◣◤◥ k4l31d0sc0p3 ◥◤◣◢  "
"  ☯ c0nsc10usn3ss h4ck3d ☯  "
"  ⚡ n3ur0ns f1r1ng ⚡  "
"  ∞ fr4ct4l c0r3 d34d ∞  "
"  ░▒▓█ m3lt1ng █▓▒░  "
"  ☯⊛◎⦿ th1rd 3y3 0p3n ⦿◎⊛☯  "
"  ▼▽▼▽ 4c1d r41n ▽▼▽▼  "
)

# Acid burst — brief rainbow glyph explosion (~0.3s)
_acid_burst() {
    [ ! -w /dev/tty ] && return
    local width=64
    local lines=3
    for ((line=0; line<lines; line++)); do
        local out=""
        for ((i=0; i<width; i++)); do
            local ci=$(( (i + line * 7 + RANDOM) % ${#_ACID_COLORS[@]} ))
            local gi=$(( RANDOM % ${#_ACID_GLYPHS[@]} ))
            out+="\033[38;5;${_ACID_COLORS[$ci]}m${_ACID_GLYPHS[$gi]}"
        done
        printf '%b\033[0m\n' "$out" > /dev/tty
    done
}

# Acid fragment — rainbow-colored message flash
_acid_frag() {
    [ ! -w /dev/tty ] && return
    local fi=$(( RANDOM % ${#_ACID_FRAGS[@]} ))
    local frag="${_ACID_FRAGS[$fi]}"
    local out=""
    local idx=0
    for ((i=0; i<${#frag}; i++)); do
        local ch="${frag:$i:1}"
        if [ "$ch" != " " ]; then
            local ci=$(( (idx + RANDOM) % ${#_ACID_COLORS[@]} ))
            out+="\033[38;5;${_ACID_COLORS[$ci]}m$ch"
            ((idx++))
        else
            out+=" "
        fi
    done
    printf '%b\033[0m\n' "$out" > /dev/tty
}

# Acid strobe — rapid color flash (3 frames, ~0.15s)
_acid_strobe() {
    [ ! -w /dev/tty ] && return
    local bar="████████████████████████████████████████████████████████████████"
    for frame in 0 1 2; do
        local ci=$(( (frame * 7 + RANDOM) % ${#_ACID_COLORS[@]} ))
        printf '\033[38;5;%dm%s\033[0m\n' "${_ACID_COLORS[$ci]}" "$bar" > /dev/tty
        sleep 0.04
    done
    # Erase strobe lines
    printf '\033[3A' > /dev/tty
    printf '\033[K\n\033[K\n\033[K\n' > /dev/tty
    printf '\033[3A' > /dev/tty
}

# Acid wave — sine-ish wave of glyphs across terminal
_acid_wave() {
    [ ! -w /dev/tty ] && return
    local width=68
    local offsets=(0 2 4 6 7 8 7 6 4 2 0 -2 -4 -6 -7 -8 -7 -6 -4 -2)
    local num_lines=5
    for ((line=0; line<num_lines; line++)); do
        local offset_idx=$(( (line * 3) % ${#offsets[@]} ))
        local pad=${offsets[$offset_idx]}
        # Clamp padding to >= 0
        [ "$pad" -lt 0 ] && pad=$(( -pad ))
        local spaces=""
        for ((s=0; s<pad; s++)); do spaces+=" "; done
        local out="$spaces"
        local seg_width=$(( width - pad ))
        for ((i=0; i<seg_width; i++)); do
            local ci=$(( (i + line * 5 + RANDOM) % ${#_ACID_COLORS[@]} ))
            local gi=$(( RANDOM % ${#_ACID_GLYPHS[@]} ))
            out+="\033[38;5;${_ACID_COLORS[$ci]}m${_ACID_GLYPHS[$gi]}"
        done
        printf '%b\033[0m\n' "$out" > /dev/tty
    done
}

# Main acid effect — randomly picks one style
_acid_effect() {
    [ ! -w /dev/tty ] && return
    printf '\n' > /dev/tty
    local style=$(( RANDOM % 5 ))
    case $style in
        0) _acid_burst ;;
        1) _acid_frag ;;
        2) _acid_strobe ;;
        3) _acid_wave ;;
        4) _acid_burst; _acid_frag ;;
    esac
    printf '\n' > /dev/tty

    # Push Claude Code's cursor to match
    local extra_lines=7
    printf '\n%.0s' $(seq 1 $extra_lines) >&2
}

# Check if acid mode is active
_is_acid_active() {
    [ "$CL4UD3_ACID_MODE" = "true" ] && return 0
    return 1
}

# ── 303 loop + stab integration ──────────────────────────────────────────────

# Start acid 303 loop if not already running
_acid_start_loop() {
    _is_acid_active || return 0

    # Auto-start strobe when acid is active and strobe linked
    if [ "$_ACID_STROBE_ENABLED" = "true" ] && ! _is_strobe_running; then
        CL4UD3_STROBE_MODE="true"
        export CL4UD3_STROBE_MODE
        _strobe_start_loop
    fi

    [ "$_ACID_303_ENABLED" = "true" ] || return 0
    # Only start if play-midi.sh is sourced (has play_acid_loop)
    type play_acid_loop >/dev/null 2>&1 || return 0

    # Signal activity for idle timeout
    type _acid_touch_activity >/dev/null 2>&1 && _acid_touch_activity

    # Already running?
    [ -f "$_PF_ACID" ] && kill -0 "$(cat "$_PF_ACID" 2>/dev/null)" 2>/dev/null && return 0
    play_acid_loop "$_ACID_303_BPM"
}

# Maybe play a beat-synced stab (random chance roll)
# Works independently of 303 — generates own stabs if needed
_acid_maybe_stab() {
    _is_acid_active || return 0
    [ "$_ACID_STABS_ENABLED" = "true" ] || return 0
    type play_acid_stab_synced >/dev/null 2>&1 || return 0

    # Signal activity for idle timeout
    type _acid_touch_activity >/dev/null 2>&1 && _acid_touch_activity

    # Ensure beat clock + stab set exist (even without 303)
    type _ensure_beat_clock >/dev/null 2>&1 && _ensure_beat_clock "$_ACID_303_BPM"
    type _ensure_stab_set >/dev/null 2>&1 && _ensure_stab_set "$_ACID_303_BPM"

    local roll chance
    chance="$_ACID_STAB_CHANCE"
    roll=$(awk "BEGIN { srand(); printf \"%.4f\", rand() }" 2>/dev/null)
    [ -n "$roll" ] || return 0

    if awk "BEGIN { exit ($roll < $chance) ? 0 : 1 }" 2>/dev/null; then
        play_acid_stab_synced
    fi
}

# Random stab — lower chance, fires independently of tool calls
# Works independently of 303
_acid_random_stab() {
    _is_acid_active || return 0
    [ "$_ACID_STABS_ENABLED" = "true" ] || return 0
    type play_acid_stab_synced >/dev/null 2>&1 || return 0

    # Ensure beat clock + stab set exist (even without 303)
    type _ensure_beat_clock >/dev/null 2>&1 && _ensure_beat_clock "$_ACID_303_BPM"
    type _ensure_stab_set >/dev/null 2>&1 && _ensure_stab_set "$_ACID_303_BPM"

    local roll chance
    chance="$_ACID_STAB_RANDOM_CHANCE"
    roll=$(awk "BEGIN { srand(); printf \"%.4f\", rand() }" 2>/dev/null)
    [ -n "$roll" ] || return 0

    if awk "BEGIN { exit ($roll < $chance) ? 0 : 1 }" 2>/dev/null; then
        play_acid_stab_synced
    fi
}

# Toggle 303 loop on/off
_acid_toggle_303() {
    if [ "$_ACID_303_ENABLED" = "true" ]; then
        _ACID_303_ENABLED="false"
        export _ACID_303_ENABLED
        type kill_acid_loop >/dev/null 2>&1 && kill_acid_loop
        echo "303: OFF"
    else
        _ACID_303_ENABLED="true"
        export _ACID_303_ENABLED
        _acid_start_loop
        echo "303: ON"
    fi
}

# Toggle stabs on/off
_acid_toggle_stabs() {
    if [ "$_ACID_STABS_ENABLED" = "true" ]; then
        _ACID_STABS_ENABLED="false"
        export _ACID_STABS_ENABLED
        echo "stabs: OFF"
    else
        _ACID_STABS_ENABLED="true"
        export _ACID_STABS_ENABLED
        echo "stabs: ON"
    fi
}

# Toggle pads on/off
_acid_toggle_pads() {
    if [ "$_ACID_PADS_ENABLED" = "true" ]; then
        _ACID_PADS_ENABLED="false"
        export _ACID_PADS_ENABLED
        echo "pads: OFF"
    else
        _ACID_PADS_ENABLED="true"
        export _ACID_PADS_ENABLED
        echo "pads: ON"
    fi
}

# ── STROBE MODE ──────────────────────────────────────────────────────────────
# Pulsating bright white flashes — full screen strobe via /dev/tty
# Uses DECSCNM (reverse video) + bright white bursts for seizure-grade flicker
# Toggle via: /cr4ck strobe

# Strobe PID: "global" = per-tab (all tabs flash), "local" = single instance
if [ "$_STROBE_SCOPE" = "local" ]; then
    _PF_STROBE="/tmp/.cl4ud3-cr4ck-strobe-pid"
else
    _PF_STROBE="/tmp/.cl4ud3-cr4ck-strobe-pid-$CL4UD3_SID"
fi

_is_strobe_active() {
    [ "$CL4UD3_STROBE_MODE" = "true" ] && return 0
    return 1
}

_is_strobe_running() {
    [ -f "$_PF_STROBE" ] || return 1
    local pid
    pid=$(cat "$_PF_STROBE" 2>/dev/null)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && return 0
    return 1
}

# Single strobe burst — bright white flash sequence
_strobe_burst() {
    [ ! -w /dev/tty ] && return
    local speed="${_STROBE_SPEED:-0.08}"
    local frames="${_STROBE_BURST_LEN:-6}"

    for ((f=0; f<frames; f++)); do
        # FLASH ON — reverse video + bright white foreground
        printf '\033[?5h' > /dev/tty
        printf '\033[97m\033[107m' > /dev/tty
        sleep "$speed"
        # FLASH OFF — restore normal
        printf '\033[?5l' > /dev/tty
        printf '\033[0m' > /dev/tty
        sleep "$speed"
    done
    # Ensure clean state
    printf '\033[?5l\033[0m' > /dev/tty
}

# Strobe with random white bar flickers (works alongside acid)
_strobe_flicker() {
    [ ! -w /dev/tty ] && return
    local width=80
    local bar=""
    for ((i=0; i<width; i++)); do bar+="█"; done

    # 2-4 rapid white bars
    local count=$((2 + RANDOM % 3))
    for ((c=0; c<count; c++)); do
        # Bright white on white — maximum burn
        printf '\033[97;107m%s\033[0m\n' "$bar" > /dev/tty
        sleep 0.03
        # Erase
        printf '\033[1A\033[K' > /dev/tty
        sleep 0.05
    done
}

# Combined strobe effect — randomly picks intensity
_strobe_effect() {
    [ ! -w /dev/tty ] && return
    local style=$(( RANDOM % 3 ))
    case $style in
        0) _strobe_burst ;;
        1) _strobe_flicker ;;
        2) _strobe_burst; _strobe_flicker ;;
    esac
}

# Background strobe loop — continuous pulsating flashes
_strobe_start_loop() {
    _is_strobe_active || return 0

    # Already running?
    if _is_strobe_running; then
        return 0
    fi

    [ ! -w /dev/tty ] && return 1

    local my_pidfile="$_PF_STROBE"
    (
        trap '' HUP
        trap '_strobe_cleanup_on_exit' EXIT

        while [ -f "$my_pidfile" ]; do
            # Strobe burst
            local speed="${_STROBE_SPEED:-0.08}"
            local frames="${_STROBE_BURST_LEN:-6}"
            local pause="${_STROBE_PAUSE:-0.4}"

            for ((f=0; f<frames; f++)); do
                [ -f "$my_pidfile" ] || break
                # FLASH — reverse video (inverts ALL screen content)
                printf '\033[?5h' > /dev/tty 2>/dev/null
                sleep "$speed" 2>/dev/null
                # NORMAL
                printf '\033[?5l' > /dev/tty 2>/dev/null
                sleep "$speed" 2>/dev/null
            done

            # Random white bar flicker between bursts (30% chance)
            if [ $((RANDOM % 10)) -lt 3 ]; then
                local bar="████████████████████████████████████████████████████████████████████████████████"
                printf '\033[97;107m%s\033[0m' "$bar" > /dev/tty 2>/dev/null
                sleep 0.04
                printf '\r\033[K' > /dev/tty 2>/dev/null
            fi

            # Pause between bursts — randomize slightly
            local jitter
            jitter=$(awk "BEGIN { srand(); printf \"%.2f\", $pause * (0.5 + rand()) }" 2>/dev/null)
            [ -n "$jitter" ] || jitter="$pause"
            sleep "$jitter" 2>/dev/null

            # If acid mode also on, occasionally throw acid colors into the strobe
            if _is_acid_active 2>/dev/null; then
                if [ $((RANDOM % 4)) -eq 0 ]; then
                    local ci=$(( RANDOM % ${#_ACID_COLORS[@]} ))
                    printf '\033[38;5;%dm' "${_ACID_COLORS[$ci]}" > /dev/tty 2>/dev/null
                    printf '\033[?5h' > /dev/tty 2>/dev/null
                    sleep 0.06
                    printf '\033[?5l\033[0m' > /dev/tty 2>/dev/null
                fi
            fi
        done
    ) &
    local loop_pid=$!
    echo "$loop_pid" > "$_PF_STROBE"
    disown "$loop_pid" 2>/dev/null
}

_strobe_cleanup_on_exit() {
    printf '\033[?5l\033[0m' > /dev/tty 2>/dev/null
}

# Kill strobe loop
# Kill this tab's strobe loop
_strobe_kill() {
    if [ -f "$_PF_STROBE" ]; then
        local pid
        pid=$(cat "$_PF_STROBE" 2>/dev/null)
        rm -f "$_PF_STROBE"
        if [ -n "$pid" ]; then
            kill "$pid" 2>/dev/null || true
        fi
    fi
    # Ensure terminal is clean
    printf '\033[?5l\033[0m' > /dev/tty 2>/dev/null || true
}

# Kill ALL strobe loops across all tabs
_strobe_kill_all() {
    for pf in /tmp/.cl4ud3-cr4ck-strobe-pid /tmp/.cl4ud3-cr4ck-strobe-pid-*; do
        [ -f "$pf" ] || continue
        local pid
        pid=$(cat "$pf" 2>/dev/null)
        rm -f "$pf"
        if [ -n "$pid" ]; then
            kill "$pid" 2>/dev/null || true
        fi
    done
    # Clean local terminal
    printf '\033[?5l\033[0m' > /dev/tty 2>/dev/null || true
}

# Toggle strobe on/off
_strobe_toggle() {
    if _is_strobe_running; then
        CL4UD3_STROBE_MODE="false"
        export CL4UD3_STROBE_MODE
        _strobe_kill_all
        echo "strobe: OFF"
    else
        CL4UD3_STROBE_MODE="true"
        export CL4UD3_STROBE_MODE
        _strobe_start_loop
        echo "strobe: ON ⚡⚡⚡"
    fi
}
