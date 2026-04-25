#!/usr/bin/env python3
"""
cl4ud3-cr4ck ACID 303 Generator
Generative acid bassline + harmonically-matched stab MIDIs.
Everything generated fresh at runtime. MIDI output — no CPU-killing DSP.
Requires: pip install midiutil
"""

import argparse
import math
import os
import random
import sys

from midiutil import MIDIFile


# ── Scales/Keys ──────────────────────────────────────────────────────────────

# Each entry: (root_name, root_midi, scale_intervals)
SCALES = [
    ("Am", 57, [0, 3, 5, 7, 10]),       # A minor pentatonic
    ("Dm", 50, [0, 3, 5, 7, 10]),       # D minor pentatonic
    ("Gm", 55, [0, 3, 5, 7, 10]),       # G minor pentatonic
    ("Cm", 48, [0, 3, 5, 7, 10]),       # C minor pentatonic
    ("Em", 52, [0, 1, 3, 5, 7, 8, 10]), # E phrygian
]

# GM programs (fallback when no 303 soundfont)
BASS_PROGRAM = 87     # Lead 8 (bass+lead) — grittier than Synth Bass
# HS TB-303 soundfont programs (used when _ACID_303_SF is set)
TB303_BASS_PROGRAMS = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45]  # TB-BASS 1-10
TB303_SQR_PROGRAMS = [50, 55, 60, 65, 70, 75, 80, 85]          # TB303 SQR 1-8
LEAD_PROGRAM = 81     # Lead 2 (sawtooth)
PAD_PROGRAM = 89      # Pad 2 (warm)
SQUARE_PROGRAM = 80   # Lead 1 (square)

# Pad chord types — diatonic triads + color chords (Amiga jungle style)
# Each chord = list of intervals from root
CHORD_TYPES = [
    [0, 7],           # power chord (root + 5th)
    [0, 3, 7],        # minor triad
    [0, 5, 7],        # sus4
    [0, 2, 7],        # sus2
    [0, 3, 7, 10],    # minor 7th
    [0, 3, 10],       # minor 7th (no 5th) — thin + dark
    [0, 7, 12],       # octave power chord
]


def _pick_key():
    """Pick random key/scale, return (name, root_midi, midi_note_pool)."""
    name, root_midi, intervals = random.choice(SCALES)
    notes = []
    for octave_offset in [-12, 0, 12]:
        for iv in intervals:
            midi = root_midi + octave_offset + iv
            if 30 <= midi <= 80:
                notes.append(midi)
    return name, root_midi, sorted(set(notes))


# ── Chord Progression Generation ─────────────────────────────────────────────

def _generate_chord_progression(note_pool, root_midi):
    """Build 4-8 diatonic chords for dark pad layer.

    Chords use scale tones from note_pool, transposed to octave 3-4 range
    (MIDI 48-72) for warm pad register. Returns list of chords, each chord
    a list of 2-3 MIDI notes.
    """
    # Filter note pool to pad range (octave 3-4)
    pad_notes = [n for n in note_pool if 48 <= n <= 72]
    if not pad_notes:
        # Transpose root into range
        r = root_midi
        while r < 48:
            r += 12
        while r > 60:
            r -= 12
        pad_notes = [r, r + 3, r + 7]

    num_chords = random.randint(4, 8)
    chords = []

    for _ in range(num_chords):
        # Pick a root from pad-range scale tones
        root = random.choice(pad_notes)
        chord_type = random.choice(CHORD_TYPES)

        # Build chord, snap to scale where possible
        chord = []
        for interval in chord_type:
            note = root + interval
            # Keep in pad range — drop octave if too high
            if note > 72:
                note -= 12
            if note < 48:
                note += 12
            chord.append(note)

        # Limit to 2-3 notes for that crisp tracker sound
        if len(chord) > 3:
            chord = chord[:3]

        chords.append(sorted(set(chord)))

    return chords


# ── 303 Pattern Generation ───────────────────────────────────────────────────

def _generate_pattern(note_pool, steps=16):
    """Generate one 16-step 303-style pattern."""
    pattern = []
    for _ in range(steps):
        if random.random() < 0.15:
            pattern.append({"type": "rest"})
        else:
            note = random.choice(note_pool)
            if random.random() < 0.2:
                note += 12  # octave up
            pattern.append({
                "type": "note",
                "midi": note,
                "accent": random.random() < 0.3,
                "slide": random.random() < 0.2,
            })
    return pattern


def _write_filter_envelope(midi, track, channel, beat_pos, step_beats, accent=False):
    """Write per-note CC74 filter sweep — the classic 303 squelch."""
    if accent:
        cc_start, cc_end, steps = 127, 15, 8
    else:
        cc_start, cc_end, steps = 110, 25, 5

    for s in range(steps):
        t = beat_pos + s * (step_beats / steps)
        # Steeper exponential decay — snappier squelch
        ratio = (s / max(1, steps - 1)) ** 0.4
        cc_val = int(cc_start - (cc_start - cc_end) * ratio)
        midi.addControllerEvent(track, channel, t, 74, max(0, min(127, cc_val)))
    # Drive via expression surge on attack
    if accent:
        midi.addControllerEvent(track, channel, beat_pos, 11, 127)
        midi.addControllerEvent(track, channel, beat_pos + step_beats * 0.3, 11, 100)


def _write_bassline(midi, track, channel, note_pool, bpm=140, measures=16, start_beat=0.0):
    """Write 303 bassline — 1-2 patterns repeated to fill target measures.

    Each pattern = 16 steps = 1 measure of 16th notes.
    A section = 1-2 patterns repeated/alternated for `measures` measures.
    Slight variations on repeats keep it alive without losing the groove.
    Returns the beat position after the last note (for chaining sections).
    """
    step_beats = 0.25  # 16th note = quarter beat
    beats_per_measure = 4.0
    target_beats = start_beat + measures * beats_per_measure

    # Always 2 patterns — A/B alternation like real 303 programming
    pat_a = _generate_pattern(note_pool)
    # Pattern B: variation of A — swap a few notes + flip some accents
    pat_b = []
    for step in pat_a:
        s = dict(step)
        if s["type"] == "note":
            if random.random() < 0.3:
                s["midi"] = random.choice(note_pool)
                if random.random() < 0.2:
                    s["midi"] += 12
            if random.random() < 0.25:
                s["accent"] = not s["accent"]
            if random.random() < 0.15:
                s["slide"] = not s.get("slide", False)
        pat_b.append(s)
    patterns = [pat_a, pat_b]

    # A/B form options — like real 303 pattern chains
    ab_forms = [
        [0, 0, 1, 0],   # AABA — classic
        [0, 0, 1, 1],   # AABB
        [0, 1, 0, 1],   # ABAB
        [0, 0, 0, 1],   # AAAB — B as tension/release
    ]
    ab_form = random.choice(ab_forms)

    # Max resonance for acid character
    midi.addControllerEvent(track, channel, start_beat, 71, 127)
    # Brightness up — opens filter range
    midi.addControllerEvent(track, channel, start_beat, 74, 100)
    # Expression max — drive the output hard
    midi.addControllerEvent(track, channel, start_beat, 11, 120)

    beat_pos = start_beat
    measure_count = 0

    while beat_pos < target_beats:
        # A/B alternation following chosen form
        pat_idx = ab_form[measure_count % len(ab_form)]
        pat = patterns[pat_idx]

        # Micro-variations on each repeat — flip accents, swap occasional slide
        varied = []
        for step in pat:
            s = dict(step)
            if s["type"] == "note":
                if random.random() < 0.08:
                    s["accent"] = not s["accent"]
                if random.random() < 0.05:
                    s["slide"] = not s.get("slide", False)
            varied.append(s)

        prev_note = None
        for step in varied:
            if beat_pos >= target_beats:
                break

            if step["type"] == "note":
                velocity = 127 if step["accent"] else 100
                dur = step_beats * 0.8

                # Portamento for slides
                if step.get("slide") and prev_note is not None:
                    midi.addControllerEvent(track, channel, beat_pos, 65, 127)
                    midi.addControllerEvent(track, channel, beat_pos, 5, 30)
                    dur = step_beats * 0.95  # near-legato
                else:
                    midi.addControllerEvent(track, channel, beat_pos, 65, 0)

                # Per-note filter envelope — the squelch
                _write_filter_envelope(midi, track, channel, beat_pos, step_beats,
                                       accent=step["accent"])

                midi.addNote(track, channel, step["midi"], beat_pos, dur, velocity)
                prev_note = step["midi"]
            else:
                # Rest — close filter
                midi.addControllerEvent(track, channel, beat_pos, 74, 30)
                prev_note = None

            beat_pos += step_beats

        measure_count += 1

    return beat_pos


# ── Stab Generators ──────────────────────────────────────────────────────────
# All stabs: single note, higher octave, CC74 squelch, dub echo delays, trippy af

def _stab_add_echo(midi, track, channel, note, start, vel, repeats=6, delay=0.75):
    """Add dub delay echo — decaying repeats at dotted 8th intervals."""
    for i in range(repeats):
        if vel < 20:
            break
        t = start + i * delay
        midi.addNote(track, channel, note, t, 0.25, vel)
        midi.addControllerEvent(track, channel, t, 74, max(20, 127 - i * 20))
        vel = int(vel * 0.55)


def _stab_squelch_hit(midi, track, channel, note_pool, bpm):
    """Stab 1: single acid hit with deep filter squelch + dub echo."""
    prog = random.choice(TB303_SQR_PROGRAMS)
    midi.addProgramChange(track, channel, 0, prog)
    midi.addControllerEvent(track, channel, 0, 71, 127)
    midi.addControllerEvent(track, channel, 0, 74, 127)
    note = random.choice(note_pool) + 12
    midi.addNote(track, channel, note, 0, 0.4, 127)
    # Squelch sweep
    midi.addControllerEvent(track, channel, 0.1, 74, 80)
    midi.addControllerEvent(track, channel, 0.2, 74, 40)
    midi.addControllerEvent(track, channel, 0.35, 74, 15)
    _stab_add_echo(midi, track, channel, note, 0.75, 80, repeats=7)


def _stab_acid_scream(midi, track, channel, note_pool, bpm):
    """Stab 2: high pitched acid scream with long delay tail."""
    prog = random.choice(TB303_SQR_PROGRAMS)
    midi.addProgramChange(track, channel, 0, prog)
    midi.addControllerEvent(track, channel, 0, 71, 127)
    midi.addControllerEvent(track, channel, 0, 74, 127)
    note = random.choice(note_pool) + 24  # two octaves up
    midi.addNote(track, channel, min(note, 96), 0, 0.6, 127)
    midi.addControllerEvent(track, channel, 0.2, 74, 90)
    midi.addControllerEvent(track, channel, 0.4, 74, 50)
    midi.addControllerEvent(track, channel, 0.6, 74, 15)
    _stab_add_echo(midi, track, channel, min(note, 96), 0.75, 85, repeats=8, delay=0.75)


def _stab_slide_up(midi, track, channel, note_pool, bpm):
    """Stab 3: chromatic slide up — single notes ascending with squelch."""
    prog = random.choice(TB303_BASS_PROGRAMS)
    midi.addProgramChange(track, channel, 0, prog)
    midi.addControllerEvent(track, channel, 0, 71, 127)
    start = random.choice(note_pool) + 12
    num_notes = random.randint(4, 7)
    step = 0.125
    for i in range(num_notes):
        t = i * step
        midi.addNote(track, channel, start + i, t, step * 0.9, 110)
        midi.addControllerEvent(track, channel, t, 74, min(127, 60 + i * 10))
    _stab_add_echo(midi, track, channel, start + num_notes - 1,
                   num_notes * step, 65, delay=0.5)


def _stab_slide_down(midi, track, channel, note_pool, bpm):
    """Stab 4: chromatic slide down — descending acid squelch."""
    prog = random.choice(TB303_SQR_PROGRAMS)
    midi.addProgramChange(track, channel, 0, prog)
    midi.addControllerEvent(track, channel, 0, 71, 127)
    start = random.choice(note_pool) + 24
    num_notes = random.randint(5, 9)
    step = 0.125
    for i in range(num_notes):
        t = i * step
        midi.addNote(track, channel, max(start - i, 36), t, step * 0.9, 105)
        midi.addControllerEvent(track, channel, t, 74, max(15, 127 - i * 14))
    _stab_add_echo(midi, track, channel, max(start - num_notes + 1, 36),
                   num_notes * step, 55, delay=0.75)


def _stab_dub_ping(midi, track, channel, note_pool, bpm):
    """Stab 5: single note dub ping — long echo, slow filter close."""
    prog = random.choice(TB303_SQR_PROGRAMS)
    midi.addProgramChange(track, channel, 0, prog)
    midi.addControllerEvent(track, channel, 0, 71, 120)
    midi.addControllerEvent(track, channel, 0, 74, 127)
    note = random.choice(note_pool) + 12
    midi.addNote(track, channel, note, 0, 0.15, 127)
    # Deep dub echo — long tail
    _stab_add_echo(midi, track, channel, note, 0.5, 95, repeats=10, delay=0.75)


def _stab_tape_echo(midi, track, channel, note_pool, bpm):
    """Stab 6: acid hit with warped tape echo — pitch drift on repeats."""
    prog = random.choice(TB303_SQR_PROGRAMS)
    midi.addProgramChange(track, channel, 0, prog)
    midi.addControllerEvent(track, channel, 0, 71, 127)
    midi.addControllerEvent(track, channel, 0, 74, 127)
    note = random.choice(note_pool) + 12
    midi.addNote(track, channel, note, 0, 0.3, 127)
    # Warped echo — pitch drifts up/down
    vel = 90
    delay = 0.75
    for i in range(8):
        if vel < 20:
            break
        t = 0.75 + i * delay
        drift = random.choice([-2, -1, 0, 0, 0, 1, 2])
        midi.addNote(track, channel, max(36, note + drift), t, 0.2, vel)
        midi.addControllerEvent(track, channel, t, 74, max(15, 120 - i * 15))
        vel = int(vel * 0.55)


def _stab_stutter(midi, track, channel, note_pool, bpm):
    """Stab 7: rapid single-note stutter — machine gun acid."""
    prog = random.choice(TB303_BASS_PROGRAMS)
    midi.addProgramChange(track, channel, 0, prog)
    midi.addControllerEvent(track, channel, 0, 71, 127)
    note = random.choice(note_pool) + 12
    num_hits = random.randint(8, 16)
    dur = 0.0625  # 32nd note
    for i in range(num_hits):
        t = i * dur
        vel = random.randint(80, 127)
        midi.addNote(track, channel, note, t, dur * 0.8, vel)
        midi.addControllerEvent(track, channel, t, 74, random.randint(30, 127))
    _stab_add_echo(midi, track, channel, note, num_hits * dur, 55, repeats=5)


def _stab_ghost(midi, track, channel, note_pool, bpm):
    """Stab 8: ghost note — barely there, all echo, deep dub."""
    prog = random.choice(TB303_SQR_PROGRAMS)
    midi.addProgramChange(track, channel, 0, prog)
    midi.addControllerEvent(track, channel, 0, 71, 127)
    midi.addControllerEvent(track, channel, 0, 74, 60)
    note = random.choice(note_pool) + 12
    midi.addNote(track, channel, note, 0, 0.1, 50)  # ghost hit
    # Echo builds up louder then fades — reverse swell feel
    vel = 40
    for i in range(10):
        t = 0.5 + i * 0.5
        v = min(100, vel + i * 8) if i < 4 else max(15, 100 - (i - 4) * 18)
        midi.addNote(track, channel, note, t, 0.15, v)
        midi.addControllerEvent(track, channel, t, 74, min(127, 40 + i * 10))


STAB_GENERATORS = [
    _stab_squelch_hit,
    _stab_acid_scream,
    _stab_slide_up,
    _stab_slide_down,
    _stab_dub_ping,
    _stab_tape_echo,
    _stab_stutter,
    _stab_ghost,
]


# ── Main Generation ──────────────────────────────────────────────────────────

def generate(bpm, output_dir, measures=16, count=1):
    """Generate loop MIDI + stab MIDIs in output_dir.

    Creates one continuous MIDI with `count` sections of `measures` measures each.
    Each section uses 1-2 patterns repeated/alternated. Sections share the same key
    for harmonic continuity. Zero gap between sections — all in one MIDI file.
    """
    os.makedirs(output_dir, exist_ok=True)

    key_name, root_midi, note_pool = _pick_key()

    # ── Single continuous bassline MIDI ──
    bass_midi = MIDIFile(1, deinterleave=False)
    bass_midi.addTempo(0, 0, bpm)

    # Write all sections into one MIDI — zero gap
    beat_pos = 0.0
    beats_per_measure = 4.0
    for n in range(count):
        # Vary program per section — cycle through 303 patches
        prog = TB303_BASS_PROGRAMS[n % len(TB303_BASS_PROGRAMS)] if random.random() < 0.7 \
            else random.choice(TB303_SQR_PROGRAMS)
        bass_midi.addProgramChange(0, 0, beat_pos, prog)
        section_beats = _write_bassline(bass_midi, 0, 0, note_pool, bpm=bpm,
                                         measures=measures, start_beat=beat_pos)
        beat_pos = section_beats

    with open(os.path.join(output_dir, "loop.mid"), "wb") as f:
        bass_midi.writeFile(f)

    # Write note pool for FIFO stab injection (bash reads this for in-key stabs)
    with open(os.path.join(output_dir, "notes.txt"), "w") as f:
        for n in note_pool:
            f.write(f"{n}\n")

    # Write chord progression for pad layer (bash reads this for FIFO pad injection)
    chord_prog = _generate_chord_progression(note_pool, root_midi)
    with open(os.path.join(output_dir, "chords.txt"), "w") as f:
        for chord in chord_prog:
            f.write(" ".join(str(n) for n in chord) + "\n")

    # ── Stab MIDIs ──
    for i, gen_func in enumerate(STAB_GENERATORS):
        stab_midi = MIDIFile(1, deinterleave=False)
        stab_midi.addTempo(0, 0, bpm)
        gen_func(stab_midi, 0, 0, note_pool, bpm)

        with open(os.path.join(output_dir, f"stab-{i+1:02d}.mid"), "wb") as f:
            stab_midi.writeFile(f)

    return key_name


def main():
    parser = argparse.ArgumentParser(description="cl4ud3-cr4ck acid 303 generator")
    parser.add_argument("--bpm", type=int, default=120, help="BPM (default: 120)")
    parser.add_argument("--output-dir", required=True, help="Output directory for MIDIs")
    parser.add_argument("--measures", type=int, default=16, help="Measures per section (default: 16)")
    parser.add_argument("--count", type=int, default=1, help="Number of sections to generate")
    # Backward compat: --duration still accepted, converted to measures
    parser.add_argument("--duration", type=int, default=0, help=argparse.SUPPRESS)
    args = parser.parse_args()

    measures = args.measures
    if args.duration > 0:
        # Convert seconds to measures: measures = duration * bpm / 60 / 4 * 4
        measures = max(4, int(args.duration * args.bpm / 60 / 4))

    key = generate(args.bpm, args.output_dir, measures=measures, count=args.count)
    print(f"key={key} bpm={args.bpm} dir={args.output_dir}")


if __name__ == "__main__":
    main()
