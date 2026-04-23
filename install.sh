#!/bin/bash
set -e
trap 'echo "  [!] Install failed at step $LINENO. Report issue at github."; exit 1' ERR

# ============================================================================
#  cl4ud3-cr4ck installer
#  "if it compiles, ship it" - ancient proverb
#  Supports: macOS, Linux, WSL
# ============================================================================

INSTALL_DIR="$HOME/.cl4ud3-cr4ck"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
AUTO_YES=false
[[ "$1" == "--yes" || "$1" == "-y" ]] && AUTO_YES=true

# ── Platform detection ─────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
    Darwin)  PLATFORM="macos" ;;
    Linux)   PLATFORM="linux" ;;
    MINGW*|MSYS*|CYGWIN*)
        PLATFORM="windows"
        echo "  [!] Native Windows detected. cl4ud3-cr4ck works best in WSL."
        echo "      Install WSL: wsl --install"
        echo "      Then run this script inside WSL."
        exit 1
        ;;
    *)
        echo "  [!] Unknown platform: $OS"
        echo "      cl4ud3-cr4ck supports macOS, Linux, and WSL."
        exit 1
        ;;
esac

# Platform-aware sed in-place (macOS needs '' arg, GNU sed does not)
_sed_i() {
    if [ "$PLATFORM" = "macos" ]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Detect package manager (Linux)
_detect_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew"
    fi
}

# Install package by name (cross-platform)
_install_pkg() {
    local pkg="$1"
    case "$(_detect_pkg_manager)" in
        apt)     sudo apt-get install -y "$pkg" 2>/dev/null ;;
        dnf)     sudo dnf install -y "$pkg" 2>/dev/null ;;
        pacman)  sudo pacman -S --noconfirm "$pkg" 2>/dev/null ;;
        zypper)  sudo zypper install -y "$pkg" 2>/dev/null ;;
        brew)    brew install "$pkg" 2>/dev/null ;;
        *)       return 1 ;;
    esac
}

# Get package name for this distro
_pkg_name() {
    local generic="$1"
    local pm=$(_detect_pkg_manager)
    case "$generic" in
        fluidsynth)
            case "$pm" in
                apt)     echo "fluidsynth" ;;
                dnf)     echo "fluidsynth" ;;
                pacman)  echo "fluidsynth" ;;
                zypper)  echo "fluidsynth" ;;
                brew)    echo "fluid-synth" ;;
                *)       echo "fluidsynth" ;;
            esac
            ;;
        soundfont)
            case "$pm" in
                apt)     echo "fluid-soundfont-gm" ;;
                dnf)     echo "fluid-soundfont-gm" ;;
                pacman)  echo "soundfont-fluid" ;;
                zypper)  echo "fluid-soundfont-gm" ;;
                brew)    echo "fluid-soundfont" ;;
                *)       echo "" ;;
            esac
            ;;
        timidity)
            echo "timidity"
            ;;
    esac
}

# Print install instructions for this platform
_install_hint() {
    local pm=$(_detect_pkg_manager)
    case "$pm" in
        apt)     echo "        sudo apt install fluidsynth fluid-soundfont-gm" ;;
        dnf)     echo "        sudo dnf install fluidsynth fluid-soundfont-gm" ;;
        pacman)  echo "        sudo pacman -S fluidsynth soundfont-fluid" ;;
        zypper)  echo "        sudo zypper install fluidsynth fluid-soundfont-gm" ;;
        brew)    echo "        brew install fluid-synth" ;;
        *)       echo "        # Install fluidsynth via your package manager" ;;
    esac
}

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║  cl4ud3-cr4ck 1nst4ll3r                  ║"
echo "  ║  w4r3z cr3w · est. 2026                  ║"
echo "  ╚══════════════════════════════════════════╝"
echo "  Platform: $PLATFORM"
echo ""

# ── Step 1: Install to home dir ──────────────────────────────────────────────

echo "  [1/5] Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"/{hooks,art,sounds/{startup,glitches,error,modem},bin,tools}

# Preserve user toggle preferences from existing config before overwrite
_SAVED_TOGGLES=""
if [ -f "$INSTALL_DIR/config.sh" ]; then
    # Extract CL4UD3_VARNAME:-value pairs from existing config
    _SAVED_TOGGLES=$(grep -o 'CL4UD3_[A-Z_]*:-[a-z]*' "$INSTALL_DIR/config.sh" 2>/dev/null || true)
fi

cp "$REPO_DIR/config.sh" "$INSTALL_DIR/"

# Re-apply saved toggle states (e.g. if user had disabled modem, keep it disabled)
if [ -n "$_SAVED_TOGGLES" ]; then
    while IFS= read -r toggle; do
        # toggle is like "CL4UD3_MODEM_SOUNDS:-false"
        varname="${toggle%%:-*}"
        value="${toggle##*:-}"
        _sed_i "s|${varname}:-[a-z]*|${varname}:-${value}|" "$INSTALL_DIR/config.sh" 2>/dev/null || true
    done <<< "$_SAVED_TOGGLES"
fi

cp "$REPO_DIR/art/screens.sh" "$INSTALL_DIR/art/"
cp "$REPO_DIR/hooks/"*.sh "$INSTALL_DIR/hooks/"
cp "$REPO_DIR/tools/gen_midi.py" "$INSTALL_DIR/tools/"
cp "$REPO_DIR/tools/gen_wav.py" "$INSTALL_DIR/tools/" 2>/dev/null || true

# Copy pre-built WAV sounds from repo (overwrite old versions)
for subdir in modem glitches error; do
    if ls "$REPO_DIR/sounds/$subdir/"*.wav >/dev/null 2>&1; then
        rm -f "$INSTALL_DIR/sounds/$subdir/"*.wav
        cp "$REPO_DIR/sounds/$subdir/"*.wav "$INSTALL_DIR/sounds/$subdir/"
    fi
done

chmod +x "$INSTALL_DIR/hooks/"*.sh
chmod +x "$INSTALL_DIR/art/screens.sh"

echo "  [+] Files copied."

# ── Step 2: Check for MIDI player ────────────────────────────────────────────

echo "  [2/5] Checking for MIDI player..."

MIDI_PLAYER=""
SOUNDFONT=""

# SoundFont search paths — platform-aware
SF_SEARCH_PATHS=(
    "$HOME/.cl4ud3-cr4ck/sounds/"*.sf2
)

if [ "$PLATFORM" = "macos" ]; then
    SF_SEARCH_PATHS+=(
        /opt/homebrew/share/fluidsynth/*.sf2
        /opt/homebrew/Cellar/fluid-synth/*/share/fluid-synth/sf2/*.sf2
        /opt/homebrew/share/soundfonts/*.sf2
        /usr/local/share/fluidsynth/*.sf2
        /usr/local/share/soundfonts/*.sf2
    )
else
    SF_SEARCH_PATHS+=(
        /usr/share/sounds/sf2/*.sf2
        /usr/share/soundfonts/*.sf2
        /usr/share/fluidsynth/*.sf2
        /usr/local/share/soundfonts/*.sf2
        /usr/local/share/fluidsynth/*.sf2
    )
fi

if command -v fluidsynth >/dev/null 2>&1; then
    MIDI_PLAYER="fluidsynth"
    echo "  [+] FluidSynth found."

    # Try to find a soundfont
    for sf in "${SF_SEARCH_PATHS[@]}"; do
        if [ -f "$sf" ]; then
            SOUNDFONT="$sf"
            break
        fi
    done

    if [ -z "$SOUNDFONT" ]; then
        echo "  [!] No SoundFont found. FluidSynth needs one."
        echo "      Download GeneralUser GS from:"
        echo "      https://schristiancollins.com/generaluser.php"
        echo "      Place .sf2 file in: $INSTALL_DIR/sounds/"
        echo ""
        local sf_pkg=$(_pkg_name soundfont)
        if [ -n "$sf_pkg" ]; then
            if [ "$AUTO_YES" = true ]; then
                REPLY="y"
            else
                read -p "  Install SoundFont package ($sf_pkg)? (y/N) " -n 1 -r
                echo
            fi
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "  [*] Installing $sf_pkg..."
                _install_pkg "$sf_pkg" || true
                for sf in "${SF_SEARCH_PATHS[@]}"; do
                    [ -f "$sf" ] && SOUNDFONT="$sf" && break
                done
            fi
        fi
    fi

    if [ -n "$SOUNDFONT" ]; then
        # Copy to install dir for reliable path resolution
        SF_BASENAME=$(basename "$SOUNDFONT")
        cp "$SOUNDFONT" "$INSTALL_DIR/sounds/$SF_BASENAME" 2>/dev/null || true
        SOUNDFONT="$INSTALL_DIR/sounds/$SF_BASENAME"
        echo "  [+] SoundFont: $SOUNDFONT"
    fi

elif command -v timidity >/dev/null 2>&1; then
    MIDI_PLAYER="timidity"
    echo "  [+] TiMidity++ found."
else
    echo "  [!] No MIDI player found."
    echo ""
    echo "      Install one:"
    _install_hint
    echo ""
    if [ "$AUTO_YES" = true ]; then
        REPLY="y"
    else
        read -p "  Install FluidSynth now? (y/N) " -n 1 -r
        echo
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "  [*] Installing FluidSynth..."
        _install_pkg "$(_pkg_name fluidsynth)" || true
        if command -v fluidsynth >/dev/null 2>&1; then
            MIDI_PLAYER="fluidsynth"
            for sf in "${SF_SEARCH_PATHS[@]}"; do
                [ -f "$sf" ] && SOUNDFONT="$sf" && break
            done
            echo "  [+] FluidSynth installed."
        else
            echo "  [!] FluidSynth install failed. Install manually."
        fi
    else
        echo "  [!] Skipping MIDI player. Sounds won't play until one is installed."
    fi
fi

# Update config with detected player
if [ -n "$MIDI_PLAYER" ]; then
    _sed_i "s|CL4UD3_MIDI_PLAYER=\"\${CL4UD3_MIDI_PLAYER:-}\"|CL4UD3_MIDI_PLAYER=\"\${CL4UD3_MIDI_PLAYER:-$MIDI_PLAYER}\"|" "$INSTALL_DIR/config.sh"
fi
if [ -n "$SOUNDFONT" ]; then
    _sed_i "s|CL4UD3_SOUNDFONT=\"\${CL4UD3_SOUNDFONT:-}\"|CL4UD3_SOUNDFONT=\"\${CL4UD3_SOUNDFONT:-$SOUNDFONT}\"|" "$INSTALL_DIR/config.sh"
fi

# ── Step 3: Generate MIDI files ──────────────────────────────────────────────

echo "  [3/5] Generating MIDI sound effects..."

if command -v pip3 >/dev/null 2>&1; then
    pip3 install --user "midiutil>=1.2.1,<2" --quiet 2>/dev/null || pip3 install "midiutil>=1.2.1,<2" 2>/dev/null || true
fi

if python3 -c "import midiutil" 2>/dev/null; then
    if ! python3 "$INSTALL_DIR/tools/gen_midi.py"; then
        echo "  [!] MIDI generation failed. Sounds may be missing."
    fi
else
    echo "  [!] midiutil not installed. Run: pip3 install midiutil"
    echo "      Then: python3 $INSTALL_DIR/tools/gen_midi.py"
fi

# ── Step 4: Configure Claude Code hooks ──────────────────────────────────────

echo "  [4/5] Configuring Claude Code hooks..."

mkdir -p "$(dirname "$CLAUDE_SETTINGS")"

# Generate settings with expanded $HOME
HOOKS_JSON=$(cat <<ENDJSON
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$INSTALL_DIR/hooks/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$INSTALL_DIR/hooks/stop.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$INSTALL_DIR/hooks/pre-tool-use.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$INSTALL_DIR/hooks/user-prompt-submit.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
ENDJSON
)

if [ -f "$CLAUDE_SETTINGS" ]; then
    # Merge hooks into existing settings
    if command -v jq >/dev/null 2>&1; then
        EXISTING=$(cat "$CLAUDE_SETTINGS")
        echo "$EXISTING" | jq --argjson new_hooks "$(echo "$HOOKS_JSON" | jq '.hooks')" \
            '.hooks = (.hooks // {}) * $new_hooks' > "$CLAUDE_SETTINGS.tmp"
        mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
        echo "  [+] Merged hooks into existing settings.json"
    else
        echo "  [!] jq not found. Cannot merge settings automatically."
        echo "      Manual merge needed. Template saved to: $INSTALL_DIR/settings.template.json"
        cp "$REPO_DIR/settings.template.json" "$INSTALL_DIR/"
    fi
else
    echo "$HOOKS_JSON" > "$CLAUDE_SETTINGS"
    echo "  [+] Created $CLAUDE_SETTINGS"
fi

# ── Step 5: Done ─────────────────────────────────────────────────────────────

echo "  [5/5] Installation complete!"
echo ""
echo "  ┌──────────────────────────────────────────────────────┐"
echo "  │  cl4ud3-cr4ck installed successfully!                │"
echo "  │                                                      │"
echo "  │  Config:  $INSTALL_DIR/config.sh        │"
echo "  │  Hooks:   ~/.claude/settings.json                    │"
echo "  │                                                      │"
echo "  │  Toggle sounds:                                      │"
echo "  │    export CL4UD3_SOUNDS_ENABLED=false  # kill all    │"
echo "  │    export CL4UD3_STARTUP_JINGLE=false  # no jingle   │"
echo "  │    export CL4UD3_GLITCH_SOUNDS=false   # no glitches │"
echo "  │    export CL4UD3_ERROR_SOUNDS=false    # no errors   │"
echo "  │    export CL4UD3_MODEM_SOUNDS=false    # no modem    │"
echo "  │                                                      │"
echo "  │  Or edit: $INSTALL_DIR/config.sh        │"
echo "  │                                                      │"
echo "  │  Uninstall: bash $REPO_DIR/uninstall.sh │"
echo "  │                                                      │"
echo "  │  n0w g0 h4ck s0m3th1ng.                              │"
echo "  └──────────────────────────────────────────────────────┘"
echo ""
