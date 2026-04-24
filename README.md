```
  ╔═══════════════════════════════════════════════════════════════╗
  ║                                                               ║
  ║                      c  l  4   u  d 3                         ║
  ║                   ─── c  r  4  c  k ───                       ║
  ║                                                               ║
  ║        warez-inspired sound & art pack for Claude Code        ║
  ║                  est. 2026 · a gr0g joint                     ║
  ╚═══════════════════════════════════════════════════════════════╝
```

## wH4t 1z th1s

**cl4ud3-cr4ck** turns your Claude Code terminal into a 90s warez scene crack screen. Inspired by RAZOR 1911, FAIRLIGHT, ACiD/iCE ANSI art, keygen chiptunes, and the beautiful chaos of l33t cracker crews and BBS list servs.

**Features:**
- 🖥 **39 ASCII art crack screens** — randomly displayed on startup (demoscene, cyberpunk, BBS, graffiti, rave, animals, multilingual, psychedelic)
- 🎬 **5 animation styles** — scanline, fade, rainbow, matrix rain, glitch (randomly chosen per session)
- 🎵 **5 warez intro loops** — short glitchy SID-style cracktro stabs (5-8s each)
- 🎵 **13 classic jingles** — SID/chiptune tracks (tracker, jungle, gabber x2, beltram, frequency, disco polo, detroit techno, demoscene x2)
- 🎮 **Glitch sounds** — video game blips when Claude finishes (coin, powerup, warp, chirp, blip)
- 💀 **Error sounds** — 7 tritone/stutter/alarm chaos sounds when shit goes wrong (5 MIDI + 2 raw WAV)
- 📠 **Modem sounds** — 8 short (1-2s) dial-up blasts when Claude uses tools (5 MIDI + 3 raw WAV)
- 🎛 **`/cr4ck` command** — enable/disable any sound category live from Claude Code
- 🎹 **Custom jingles** — drop MIDI/WAV files into `~/.cl4ud3-cr4ck/sounds/custom/`
- 🖼 **Custom art** — drop `.txt` files into `~/.cl4ud3-cr4ck/art/custom/`
- ⏱ **Auto-kill timer** — intro music stops after configurable max play time (default 60s)

All sounds generated programmatically — MIDI via `midiutil`, raw WAV via Python stdlib. No sample packs, no downloads, pure math.

<img width="378" height="218" alt="Screenshot 2026-04-23 at 19 09 13" src="https://github.com/user-attachments/assets/8b76724f-2c1f-4090-835f-12eaee90e7e5" />
<img width="470" height="244" alt="Screenshot 2026-04-23 at 20 51 06" src="https://github.com/user-attachments/assets/fe78da3a-f108-43bc-9f47-77a51c6f1cbe" />


## 1nst4ll

### Quick Install (Claude Code)

Open Claude Code and run:

```
/terminal git clone https://github.com/YOUR_USER/cl4ud3-cr4ck.git /tmp/cl4ud3-cr4ck && bash /tmp/cl4ud3-cr4ck/install.sh --yes
```

Or from any terminal:

```bash
git clone https://github.com/YOUR_USER/cl4ud3-cr4ck.git
cd cl4ud3-cr4ck
bash install.sh        # Interactive — prompts for MIDI player install
bash install.sh --yes  # Non-interactive — auto-installs everything
```

### What the Installer Does

1. Copies hooks, art, and tools to `~/.cl4ud3-cr4ck/`
2. Detects or installs a MIDI player (FluidSynth via Homebrew)
3. Finds/copies a SoundFont for synthesis
4. Generates all MIDI sound effects via Python (`gen_midi.py`)
5. Generates raw WAV sound effects via Python (`gen_wav.py`)
6. Merges hooks into `~/.claude/settings.json` (preserves existing settings)

After install, restart Claude Code. You'll see a random crack screen and hear a keygen jingle.

### How It Works with Claude Code

cl4ud3-cr4ck uses [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) — shell commands that fire on specific events. The installer adds five hooks to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart":      [{ "matcher": "startup", "hooks": [{ "type": "command", "command": "~/.cl4ud3-cr4ck/hooks/session-start.sh" }] }],
    "Stop":              [{ "hooks": [{ "type": "command", "command": "~/.cl4ud3-cr4ck/hooks/stop.sh" }] }],
    "PreToolUse":        [{ "hooks": [{ "type": "command", "command": "~/.cl4ud3-cr4ck/hooks/pre-tool-use.sh" }] }],
    "PostToolUse":       [{ "hooks": [{ "type": "command", "command": "~/.cl4ud3-cr4ck/hooks/post-tool-use.sh" }] }],
    "UserPromptSubmit":  [{ "hooks": [{ "type": "command", "command": "~/.cl4ud3-cr4ck/hooks/user-prompt-submit.sh" }] }]
  }
}
```

Each hook script sources the shared config (`config.sh`), checks enable/disable flags, and plays a random sound from the appropriate directory. All playback is non-blocking (backgrounded with `&` + `disown`).

### Verify Installation

After restarting Claude Code, check hooks are active:
```
/hooks
```

You should see cl4ud3-cr4ck hooks under SessionStart, Stop, PreToolUse, PostToolUse, and UserPromptSubmit.

### Prerequisites

- **Claude Code** (obviously)
- **macOS** (Linux support possible but untested)
- **MIDI player** (one of — installer can auto-install):
  - `brew install fluid-synth` — best quality, comes with a SoundFont
  - `brew install timidity` — also good
  - Compile `mac-playmidi` — zero deps, uses Apple's built-in synth
- **Python 3** + `midiutil` — for generating MIDI files
  - `pip3 install midiutil`
- **jq** — for merging hooks into existing settings.json
  - `brew install jq` (most devs already have this)

## c0nf1g

Edit `~/.cl4ud3-cr4ck/config.sh` or set environment variables:

```bash
# Master kill switch
export CL4UD3_SOUNDS_ENABLED=false   # silence everything

# Individual toggles (all true by default)
export CL4UD3_STARTUP_JINGLE=false   # no startup music
export CL4UD3_STARTUP_ART=false      # no ASCII art
export CL4UD3_GLITCH_SOUNDS=false    # no completion blips
export CL4UD3_ERROR_SOUNDS=false     # no error sounds
export CL4UD3_MODEM_SOUNDS=false     # no dial-up on tool use

# Animation styles — enable/disable individually (all ON by default)
# If multiple enabled, one is randomly chosen each session
export CL4UD3_ANIM_SCANLINE=true   # line-by-line CRT reveal
export CL4UD3_ANIM_FADE=true       # dark→bright color fade-in
export CL4UD3_ANIM_RAINBOW=true    # color cycle shift
export CL4UD3_ANIM_MATRIX=true     # matrix rain then reveal
export CL4UD3_ANIM_GLITCH=true     # scrambled→clean reveal

# Jingle directory — which set of startup sounds to use
#   "all"            — cycle through warez + classic combined (default)
#   "startup-warez"  — short glitchy warez cracktro loops only
#   "startup"        — classic longer jingles only (dnb, gabber, etc.)
export CL4UD3_JINGLE_DIR=all

# Loop mode — keep playing jingles until user interacts
export CL4UD3_STARTUP_LOOP=false     # true = loop, false = single play

# Kill intro jingle when user sends first message
export CL4UD3_KILL_INTRO_ON_MESSAGE=true

# Max intro play time in seconds — auto-kills jingle loop
# Default 60s. Set to 0 for unlimited.
export CL4UD3_INTRO_MAX_PLAY=60

# Jingle duration target in seconds (used by gen_midi.py)
# Only affects regeneration, not playback
export CL4UD3_JINGLE_DURATION=25

# SoundFont selection — controls MIDI playback character
#   "generaluser"  — GeneralUser GS (cleaner, fuller)
#   "vintage"      — VintageDreamsWaves (lo-fi, retro)
#   "random"       — randomly pick each time (default)
export CL4UD3_SOUNDFONT_MODE=random
```

## h00k 3v3ntz

| Hook | Trigger | Sound | Cooldown |
|------|---------|-------|----------|
| `SessionStart` | New Claude Code session | ASCII art + warez loop (max 60s) | None |
| `Stop` | Claude finishes responding | Random video game glitch | 3s |
| `PreToolUse` | Claude runs any tool | Short dial-up blast (1-2s) | 10s |
| `PostToolUse` | Tool execution completes | Modem "connected" chirp | 10s (shared w/ PreToolUse) |
| `UserPromptSubmit` | User sends a message | Kills startup jingle loop | None |

Cooldowns prevent infinite loops (e.g. Stop → sound → Stop → ...) and sound spam on rapid tool calls.

## s0und f1l3z

MIDI generated by `tools/gen_midi.py`, raw WAV by `tools/gen_wav.py` — across 5 categories:

```
sounds/
├── startup-warez/                     # Short glitchy warez loops (5-8s)
│   ├── warez-01-keygen.mid            # Stabby square wave Am stabs
│   ├── warez-02-cracktro.mid          # Harsh one-channel Dm stabs
│   ├── warez-03-scene.mid             # Square + saw SID stabs
│   ├── warez-04-nfo.mid               # Saw wave stabs + square bass
│   └── warez-05-glitchload.mid        # Random square stabs — corrupted MIDI chaos
├── startup/                           # Classic longer jingles — all SID/chiptune patches
│   ├── jingle-01.mid                  # Keygen-style Am arpeggio
│   ├── jingle-02.mid                  # C64 SID rapid-fire burst
│   ├── jingle-03.mid                  # Demoscene tracker bounce (4 melody variations)
│   ├── jingle-04-jungle.mid          # DnB / jungle — SID stabs + rolling bass
│   ├── jingle-05-breakcore.mid       # Breakcore gabber — reverse bass + screech
│   ├── jingle-06-beltram.mid         # Belgian techno 1992 — Joey Beltram hoover (Dm, 130 BPM)
│   ├── jingle-06-frequency.mid       # Frequency / acid techno
│   ├── jingle-07-discopolo.mid       # Disco polo — eastern euro party vibes
│   ├── jingle-07-gabber2.mid         # Gabber #2 — Rotterdam terror (Eb minor, 155 BPM)
│   ├── jingle-08-gabber.mid          # Gabber #1 — Rotterdam terror (150 BPM)
│   ├── jingle-09-detroit.mid         # Detroit techno — Underground Resistance (C#m, 130 BPM)
│   ├── jingle-10-demoscene.mid      # Amiga MOD tracker — 4-channel counterpoint (Am, 140 BPM)
│   └── jingle-11-chip.mid           # XM tracker chip arpeggios with echo (Dm, 155 BPM)
├── glitches/                          # Random blip when Claude finishes
│   ├── glitch-01-coin.mid + .wav     # Mario coin pickup
│   ├── glitch-02-powerup.mid + .wav  # Ascending power-up
│   ├── glitch-03-blip.mid + .wav     # Short blip
│   ├── glitch-04-chirp.mid + .wav    # Quick warble
│   └── glitch-05-warp.mid + .wav     # Descending warp
├── error/                             # Error notification
│   ├── error-01-tritone.mid          # Tritone stab + low buzz
│   ├── error-02-descend.mid          # Descending stabs + cluster
│   ├── error-03-stutter.mid          # Rapid stutter + death note
│   ├── error-04-alarm.mid           # Rapid alternating alarm + crash chord
│   ├── error-05-crash.mid           # Ascending saw then sudden low crash
│   ├── error-critical.wav           # Raw WAV critical alert
│   └── error-ohshit.wav             # Raw WAV oh-shit alarm
└── modem/                             # Dial-up blasts on tool use (1-2s each)
    ├── dialup-01-light.mid + .wav    # Quick carrier chirp + short scramble
    ├── dialup-02-medium.mid + .wav   # Answer tone + denser scramble
    ├── dialup-03-heavy.mid + .wav    # Full chaos scramble
    ├── dialup-04-chaos.mid + .wav    # Staccato data burst
    ├── dialup-05-ping.mid + .wav     # Two tones + minimal scramble
    ├── dialup-06-blip.wav            # Raw WAV data blip
    ├── dialup-07-saw.wav             # Raw WAV saw burst
    └── dialup-08-stutter.wav         # Raw WAV stutter chirp
```

Regenerate MIDI: `python3 ~/.cl4ud3-cr4ck/tools/gen_midi.py`
Regenerate WAV: `python3 ~/.cl4ud3-cr4ck/tools/gen_wav.py`

## /cr4ck c0mm4nd

Control sounds live from Claude Code:

```
/cr4ck status          # show all toggles
/cr4ck enable          # master switch ON
/cr4ck disable         # master switch OFF
/cr4ck enable-modem    # modem sounds ON
/cr4ck disable-modem   # modem sounds OFF
/cr4ck enable-error    # error sounds ON
/cr4ck disable-error   # error sounds OFF
/cr4ck enable-glitch   # glitch sounds ON
/cr4ck disable-glitch  # glitch sounds OFF
/cr4ck enable-jingle   # startup jingle ON
/cr4ck disable-jingle  # startup jingle OFF
/cr4ck enable-art       # ASCII art ON
/cr4ck disable-art      # ASCII art OFF
/cr4ck enable-anim-scanline  # scanline animation ON
/cr4ck disable-anim-scanline # scanline animation OFF
/cr4ck enable-anim-fade     # fade animation ON
/cr4ck disable-anim-fade    # fade animation OFF
/cr4ck enable-anim-rainbow  # rainbow animation ON
/cr4ck disable-anim-rainbow # rainbow animation OFF
/cr4ck enable-anim-matrix   # matrix animation ON
/cr4ck disable-anim-matrix  # matrix animation OFF
/cr4ck enable-anim-glitch   # glitch animation ON
/cr4ck disable-anim-glitch  # glitch animation OFF
/cr4ck enable-all       # all categories ON
/cr4ck disable-all      # all categories OFF
```

Changes take effect next session (or next hook fire for modem/error/glitch).

## 4n1m4t10n styl3z

Five animation styles for ASCII art reveal. Enable any combination — one is randomly chosen each session.

| Style | Description | Duration |
|-------|-------------|----------|
| **Scanline** | Line-by-line CRT reveal | ~0.6s |
| **Fade** | Dark→bright color fade-in (4 passes) | ~1.5s |
| **Rainbow** | Color cycle shift through rainbow palette | ~2s |
| **Matrix** | Random green chars rain, then reveal | ~2.5s |
| **Glitch** | Scrambled text progressively cleans up | ~1.5s |

All five styles are enabled by default — one is randomly chosen each session. Disable individually via config or `/cr4ck`:

```bash
# Disable specific animation styles
export CL4UD3_ANIM_MATRIX=false
export CL4UD3_ANIM_GLITCH=false
```

Backward compat: setting `CL4UD3_STARTUP_ANIMATION=false` disables all animation styles.

## cust0m1z4t10n

### Custom Jingles (MIDI/WAV)

Drop `.mid` or `.wav` files into the custom jingles directory:

```bash
mkdir -p ~/.cl4ud3-cr4ck/sounds/custom/
cp my-sick-beat.mid ~/.cl4ud3-cr4ck/sounds/custom/
cp keygen-remix.wav ~/.cl4ud3-cr4ck/sounds/custom/
```

Custom jingles automatically join the rotation when `CL4UD3_JINGLE_DIR=all` (default). WAV files preferred over MIDI when both exist. Any standard MIDI file works — General MIDI instruments, any tempo/length.

You can also drop files directly into built-in dirs:

```bash
# Add to warez rotation
cp my-cracktro.mid ~/.cl4ud3-cr4ck/sounds/startup-warez/

# Add custom glitch notification
cp boop.wav ~/.cl4ud3-cr4ck/sounds/glitches/

# Add another modem variation
cp screech.mid ~/.cl4ud3-cr4ck/sounds/modem/
```

To disable a specific built-in sound without deleting it, move it out:
```bash
mkdir -p ~/.cl4ud3-cr4ck/sounds/startup/disabled
mv ~/.cl4ud3-cr4ck/sounds/startup/jingle-03.mid ~/.cl4ud3-cr4ck/sounds/startup/disabled/
```

### Custom Crack Screens (ASCII Art)

**Easy way** — drop `.txt` files into the custom art directory:

```bash
mkdir -p ~/.cl4ud3-cr4ck/art/custom/
```

Each `.txt` file = one crack screen. Supports ANSI escape codes for color. Example file `~/.cl4ud3-cr4ck/art/custom/my-screen.txt`:

```
\033[38;5;46m
    ╔═══════════════════════════════════╗
    ║   YOUR CUSTOM CRACK SCREEN HERE   ║
    ║   use ANSI color codes for flair  ║
    ╚═══════════════════════════════════╝
\033[0m
```

Custom screens join the random rotation alongside the built-in 39 screens.

**Advanced way** — edit `~/.cl4ud3-cr4ck/art/screens.sh` directly. Each screen is a bash string in the `SCREENS` array:

```bash
# Add a new screen — append before the "Pick random" section
SCREENS+=("""
\033[38;5;46m
    ╔═══════════════════════════════════╗
    ║   YOUR CUSTOM CRACK SCREEN HERE   ║
    ║   use ANSI color codes for flair  ║
    ╚═══════════════════════════════════╝
\033[0m""")
```

**ANSI color reference:**
- `\033[38;5;196m` = red
- `\033[38;5;46m` = green
- `\033[38;5;51m` = cyan
- `\033[38;5;226m` = yellow
- `\033[38;5;208m` = orange
- `\033[38;5;93m` = purple
- `\033[38;5;231m` = white
- `\033[38;5;245m` = gray
- `\033[0m` = reset (always end with this)
- `\033[1m` = bold

39 screens included by default. Styles: gr0g classic, demoscene, cyberpunk, BBS, graffiti, rave/freetek, animals (dolphin, dog, cat), skull, glitch art, multilingual (Japanese, Russian, Thai, Chinese), psychedelic/acid.

### Adjusting Cooldowns

Edit the hook scripts in `~/.cl4ud3-cr4ck/hooks/`. The `DIFF` check controls cooldown seconds:

```bash
# In stop.sh — change 3 to desired seconds
[ "$DIFF" -lt 3 ] && exit 0

# In pre-tool-use.sh — change 10 to desired seconds
[ "$DIFF" -lt 10 ] && exit 0
```

### Generate New MIDI Sounds

Edit `~/.cl4ud3-cr4ck/tools/gen_midi.py` to add new generators, then regenerate:

```bash
python3 ~/.cl4ud3-cr4ck/tools/gen_midi.py
```

The MIDI generator uses `midiutil` — full GM instrument list available. All patches SID/chiptune style:
- `80` = Square lead (C64 SID — primary voice)
- `81` = Saw lead (hoover/detuned — secondary voice)
- Channel 9 = GM drums (38=snare, 42=hat, 46=open hat — no kicks)

The WAV generator (`gen_wav.py`) uses only Python stdlib (`wave` + `struct`). Pure square/saw/triangle waves, 8-bit 22050Hz — maximum crunch, no SoundFont needed:

```bash
python3 ~/.cl4ud3-cr4ck/tools/gen_wav.py
```

## t3st su1t3

Tests use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System):

```bash
make test        # run all tests
make lint        # shellcheck all scripts
make clean       # remove temp files
```

## upd4t3 / sync

Already installed and want the latest sounds, art, and hooks? Just re-run the installer:

```bash
cd /path/to/cl4ud3-cr4ck
git pull
bash install.sh --yes
```

This copies everything fresh to `~/.cl4ud3-cr4ck/` and regenerates all sound files. Your `config.sh` settings are preserved.

Works from any project directory — cl4ud3-cr4ck installs globally to `~/.cl4ud3-cr4ck/`.

## qu1ck r3f3r3nc3

**Turn sounds ON/OFF** — from inside Claude Code:

| Want to... | Type this |
|-----------|-----------|
| Shut everything up | `/cr4ck disable` |
| Turn everything back on | `/cr4ck enable` |
| Mute just modem sounds | `/cr4ck disable-modem` |
| Mute just startup jingle | `/cr4ck disable-jingle` |
| Mute just glitch blips | `/cr4ck disable-glitch` |
| Mute just error sounds | `/cr4ck disable-error` |
| Hide ASCII art | `/cr4ck disable-art` |
| Disable scanline animation | `/cr4ck disable-anim-scanline` |
| Disable fade animation | `/cr4ck disable-anim-fade` |
| Disable rainbow animation | `/cr4ck disable-anim-rainbow` |
| Disable matrix animation | `/cr4ck disable-anim-matrix` |
| Disable glitch animation | `/cr4ck disable-anim-glitch` |
| Mute ALL categories | `/cr4ck disable-all` |
| Enable ALL categories | `/cr4ck enable-all` |
| Check what's on/off | `/cr4ck status` |

Changes take effect immediately (next hook fire). Startup jingle/art changes take effect next session.

**Turn sounds ON/OFF** — from any terminal (without Claude Code):

```bash
# Edit config directly
nano ~/.cl4ud3-cr4ck/config.sh

# Change "true" to "false" on any line, e.g.:
# CL4UD3_MODEM_SOUNDS="${CL4UD3_MODEM_SOUNDS:-false}"
```

## un1nst4ll

```bash
bash /path/to/cl4ud3-cr4ck/uninstall.sh
```

Removes `~/.cl4ud3-cr4ck/` and cleans hooks from `~/.claude/settings.json`.

## cr3d1tz

Inspired by the legendary crews: RAZOR 1911, FAIRLIGHT, DEViANCE, SKIDROW, CLASS, iCE, ACiD.

In memory of the BBSes, the 14.4k modems, the NFO files, and everyone who ever typed `FORMAT C:` by accident.

```
 ─────────────────────────────────────────
  gr33tz: #flux · d4 h0m13z · 4LL cr3wZ
  "w3 d0n't sl33p · w3 c0d3"
 ─────────────────────────────────────────
```

## l1c3ns3

MIT. Do whatever. Spread the warez.

<img width="1006" height="620" alt="image" src="https://github.com/user-attachments/assets/aa321ad5-84d9-4c0c-85bd-b5f641a276d7" />
