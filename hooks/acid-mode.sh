#!/bin/bash
# cl4ud3-cr4ck — ACID MODE
# Psychedelic terminal effects triggered between tool calls
# Writes directly to /dev/tty to bypass Claude Code capture
# Toggle via: /cr4ck acid

# ── Hidden acid config ───────────────────────────────────────────────────────
_ACID_303_ENABLED="${_ACID_303_ENABLED:-false}"
_ACID_STABS_ENABLED="${_ACID_STABS_ENABLED:-true}"
_ACID_303_BPM="${_ACID_303_BPM:-140}"
_ACID_STAB_CHANCE="${_ACID_STAB_CHANCE:-0.4}"
_ACID_STAB_RANDOM_CHANCE="${_ACID_STAB_RANDOM_CHANCE:-0.15}"

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
    [ "$_ACID_303_ENABLED" = "true" ] || return 0
    # Only start if play-midi.sh is sourced (has play_acid_loop)
    type play_acid_loop >/dev/null 2>&1 || return 0
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
