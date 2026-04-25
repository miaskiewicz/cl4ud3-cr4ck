#!/bin/bash
# cl4ud3-cr4ck configuration
# All sounds ON by default. Set to "false" to disable.

# Enable/disable individual sound categories
CL4UD3_STARTUP_JINGLE="${CL4UD3_STARTUP_JINGLE:-true}"
CL4UD3_STARTUP_ART="${CL4UD3_STARTUP_ART:-true}"
CL4UD3_GLITCH_SOUNDS="${CL4UD3_GLITCH_SOUNDS:-true}"
CL4UD3_ERROR_SOUNDS="${CL4UD3_ERROR_SOUNDS:-true}"
CL4UD3_MODEM_SOUNDS="${CL4UD3_MODEM_SOUNDS:-true}"

# Startup jingle loop — keep playing until user interacts
# Set to "false" for single play (one jingle then stop)
CL4UD3_STARTUP_LOOP="${CL4UD3_STARTUP_LOOP:-false}"

# Kill intro jingle when user sends first message
# Set to "false" to let jingle finish naturally (or until tool call / max play)
CL4UD3_KILL_INTRO_ON_MESSAGE="${CL4UD3_KILL_INTRO_ON_MESSAGE:-true}"

# Max intro play time in seconds — kills jingle loop after this
# Default 60s. Set to 0 for unlimited.
CL4UD3_INTRO_MAX_PLAY="${CL4UD3_INTRO_MAX_PLAY:-60}"

# Jingle directory — which set of startup jingles to use
#   "all"            — cycle through warez + classic combined (default)
#   "startup-warez"  — short glitchy warez cracktro loops only
#   "startup"        — classic longer jingles only (dnb, gabber, etc.)
CL4UD3_JINGLE_DIR="${CL4UD3_JINGLE_DIR:-all}"

# Jingle duration target in seconds (used by gen_midi.py)
# Default 25s — only affects regeneration, not playback
CL4UD3_JINGLE_DURATION="${CL4UD3_JINGLE_DURATION:-25}"

# Custom content directories — drop your own .mid or .txt files here
# Custom jingles: ~/.cl4ud3-cr4ck/sounds/custom/ (MIDI or WAV)
# Custom art:     ~/.cl4ud3-cr4ck/art/custom/     (plain text files)
CL4UD3_CUSTOM_JINGLES="${CL4UD3_CUSTOM_JINGLES:-true}"
CL4UD3_CUSTOM_ART="${CL4UD3_CUSTOM_ART:-true}"

# Animation styles — enable/disable individually
# If multiple enabled, one is randomly chosen each session
# Backward compat: CL4UD3_STARTUP_ANIMATION=false skips all animations
CL4UD3_ANIM_SCANLINE="${CL4UD3_ANIM_SCANLINE:-true}"    # line-by-line CRT reveal
CL4UD3_ANIM_FADE="${CL4UD3_ANIM_FADE:-true}"             # dark→bright color fade-in
CL4UD3_ANIM_RAINBOW="${CL4UD3_ANIM_RAINBOW:-true}"       # color cycle shift
CL4UD3_ANIM_MATRIX="${CL4UD3_ANIM_MATRIX:-true}"         # matrix rain then reveal
CL4UD3_ANIM_GLITCH="${CL4UD3_ANIM_GLITCH:-true}"         # scrambled→clean reveal

# Cooldowns — minimum seconds between sounds (prevents spam)
CL4UD3_STOP_COOLDOWN="${CL4UD3_STOP_COOLDOWN:-3}"       # between glitch sounds on stop
CL4UD3_TOOL_COOLDOWN="${CL4UD3_TOOL_COOLDOWN:-10}"      # between modem sounds on tool use

# Secret mode — shhh
CL4UD3_ACID_MODE="${CL4UD3_ACID_MODE:-false}"
_ACID_303_ENABLED="${_ACID_303_ENABLED:-false}"
_ACID_STABS_ENABLED="${_ACID_STABS_ENABLED:-true}"
_ACID_303_BPM="${_ACID_303_BPM:-120}"
_ACID_303_SF="$HOME/.cl4ud3-cr4ck/sounds/HS TB-303.SF2"

# Master kill switch — overrides everything above
CL4UD3_SOUNDS_ENABLED="${CL4UD3_SOUNDS_ENABLED:-true}"

# MIDI player command (auto-detected by install.sh)
CL4UD3_MIDI_PLAYER="${CL4UD3_MIDI_PLAYER:-}"

# SoundFont selection — controls which .sf2 is used for MIDI playback
#   "generaluser"  — always use GeneralUser GS (cleaner, fuller)
#   "vintage"      — always use VintageDreamsWaves (lo-fi, retro)
#   "random"       — randomly pick between them each time (default)
CL4UD3_SOUNDFONT_MODE="${CL4UD3_SOUNDFONT_MODE:-random}"

# Resolved soundfont path — set automatically based on mode above
# Override with a full path to use a custom soundfont
_SF_GENERALUSER="$HOME/.cl4ud3-cr4ck/sounds/GeneralUser-GS.sf2"
_SF_VINTAGE="$HOME/.cl4ud3-cr4ck/sounds/VintageDreamsWaves-v2.sf2"

if [ -n "$CL4UD3_SOUNDFONT" ] && [ "$CL4UD3_SOUNDFONT" != "auto" ]; then
    : # User set explicit path, use it
elif [ "$CL4UD3_SOUNDFONT_MODE" = "generaluser" ]; then
    CL4UD3_SOUNDFONT="$_SF_GENERALUSER"
elif [ "$CL4UD3_SOUNDFONT_MODE" = "vintage" ]; then
    CL4UD3_SOUNDFONT="$_SF_VINTAGE"
elif [ "$CL4UD3_SOUNDFONT_MODE" = "random" ]; then
    if [ $((RANDOM % 2)) -eq 0 ] && [ -f "$_SF_GENERALUSER" ]; then
        CL4UD3_SOUNDFONT="$_SF_GENERALUSER"
    elif [ -f "$_SF_VINTAGE" ]; then
        CL4UD3_SOUNDFONT="$_SF_VINTAGE"
    else
        CL4UD3_SOUNDFONT="$_SF_GENERALUSER"
    fi
else
    CL4UD3_SOUNDFONT="${CL4UD3_SOUNDFONT:-$_SF_GENERALUSER}"
fi

# Installation directory (set by install.sh)
CL4UD3_HOME="${CL4UD3_HOME:-$HOME/.cl4ud3-cr4ck}"
