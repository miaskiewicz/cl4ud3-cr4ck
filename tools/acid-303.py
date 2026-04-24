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

# GM programs
BASS_PROGRAM = 38     # Synth Bass 1
LEAD_PROGRAM = 81     # Lead 2 (sawtooth)
PAD_PROGRAM = 89      # Pad 2 (warm)
SQUARE_PROGRAM = 80   # Lead 1 (square)


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
        cc_start, cc_end, steps = 125, 35, 6
    else:
        cc_start, cc_end, steps = 95, 45, 4

    for s in range(steps):
        t = beat_pos + s * (step_beats / steps)
        # Exponential-ish decay curve
        ratio = (s / max(1, steps - 1)) ** 0.5
        cc_val = int(cc_start - (cc_start - cc_end) * ratio)
        midi.addControllerEvent(track, channel, t, 74, max(0, min(127, cc_val)))


def _write_bassline(midi, track, channel, note_pool, bpm=140, target_duration=17):
    """Write 303 bassline as MIDI notes with filter sweeps and portamento."""
    step_beats = 0.25  # 16th note = quarter beat
    target_beats = target_duration * bpm / 60.0

    num_patterns = random.choice([2, 3])
    patterns = [_generate_pattern(note_pool) for _ in range(num_patterns)]

    # High resonance for acid character
    midi.addControllerEvent(track, channel, 0, 71, 115)

    beat_pos = 0.0

    for pat in patterns:
        for _repeat in range(2):
            # Slight variation on repeat
            varied = []
            for step in pat:
                if random.random() < 0.1 and step["type"] == "note":
                    s = dict(step)
                    s["accent"] = not s["accent"]
                    varied.append(s)
                else:
                    varied.append(step)

            prev_note = None
            for step in varied:
                if beat_pos >= target_beats:
                    break

                if step["type"] == "note":
                    velocity = 110 if step["accent"] else 80
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

            if beat_pos >= target_beats:
                break

    return beat_pos


# ── Stab Generators ──────────────────────────────────────────────────────────
# Each writes MIDI notes to a MIDIFile. Musical patterns preserved, DSP gone.

def _stab_filter_sweep(midi, track, channel, note_pool, bpm):
    """Stab 1: chord hit with descending velocity (simulates filter sweep)."""
    midi.addProgramChange(track, channel, 0, LEAD_PROGRAM)
    chord = random.sample(note_pool, min(3, len(note_pool)))
    duration = 60.0 / bpm  # 1 beat in seconds → 1.0 beat
    # Velocity ramp down across notes for sweep feel
    for i, note in enumerate(sorted(chord)):
        vel = 120 - i * 15
        midi.addNote(track, channel, note, 0, 1.0, vel)


def _stab_tritone(midi, track, channel, note_pool, bpm):
    """Stab 2: tritone interval hit."""
    midi.addProgramChange(track, channel, 0, LEAD_PROGRAM)
    root = random.choice(note_pool)
    tritone = root + 6  # tritone = 6 semitones
    midi.addNote(track, channel, root, 0, 0.5, 110)
    midi.addNote(track, channel, tritone, 0, 0.5, 110)


def _stab_arp(midi, track, channel, note_pool, bpm):
    """Stab 3: rapid arpeggio burst (32nd notes)."""
    midi.addProgramChange(track, channel, 0, SQUARE_PROGRAM)
    arp_notes = random.sample(note_pool, min(4, len(note_pool)))
    arp_notes = sorted(arp_notes)
    step = 0.125  # 32nd note
    for i, note in enumerate(arp_notes):
        midi.addNote(track, channel, note, i * step, step * 0.9, 100)


def _stab_chromatic(midi, track, channel, note_pool, bpm):
    """Stab 4: chromatic run."""
    midi.addProgramChange(track, channel, 0, SQUARE_PROGRAM)
    start = random.choice(note_pool)
    direction = random.choice([-1, 1])
    num_notes = random.randint(4, 6)
    step = 0.125  # 32nd note
    for i in range(num_notes):
        note = start + direction * i
        midi.addNote(track, channel, note, i * step, step * 0.9, 95)


def _stab_dub_chord(midi, track, channel, note_pool, bpm):
    """Stab 5: dub techno chord wash — long pad."""
    midi.addProgramChange(track, channel, 0, PAD_PROGRAM)
    chord = random.sample(note_pool, min(4, len(note_pool)))
    for note in chord:
        midi.addNote(track, channel, note, 0, 2.0, 75)


def _stab_tape_echo(midi, track, channel, note_pool, bpm):
    """Stab 6: single hit with simulated echo repeats (velocity decay)."""
    midi.addProgramChange(track, channel, 0, LEAD_PROGRAM)
    note = random.choice(note_pool)
    if random.random() < 0.3:
        note += 12  # octave up sometimes
    # Dotted 8th echo pattern via repeated notes with decaying velocity
    delay_beats = 0.75  # dotted 8th
    vel = 110
    for i in range(5):
        if vel < 30:
            break
        midi.addNote(track, channel, note, i * delay_beats, 0.25, vel)
        vel = int(vel * 0.6)


def _stab_granular(midi, track, channel, note_pool, bpm):
    """Stab 7: granular stutter — rapid micro-hits at varied pitches."""
    midi.addProgramChange(track, channel, 0, LEAD_PROGRAM)
    base = random.choice(note_pool)
    pos = 0.0
    for _ in range(12):
        if random.random() < 0.3:
            # Gap
            pos += random.choice([0.0625, 0.125])
            continue
        pitch_offset = random.choice([-12, 0, 0, 0, 7, 12])
        dur = random.choice([0.0625, 0.125, 0.1875])
        midi.addNote(track, channel, base + pitch_offset, pos, dur * 0.8, random.randint(70, 120))
        pos += dur


def _stab_metallic(midi, track, channel, note_pool, bpm):
    """Stab 8: metallic ring mod — dissonant interval hit."""
    midi.addProgramChange(track, channel, 0, LEAD_PROGRAM)
    root = random.choice(note_pool)
    # Non-standard intervals for metallic/dissonant character
    offsets = random.choice([[0, 6, 11], [0, 1, 7], [0, 5, 11]])
    for offset in offsets:
        midi.addNote(track, channel, root + offset, 0, 0.75, 105)


STAB_GENERATORS = [
    _stab_filter_sweep,
    _stab_tritone,
    _stab_arp,
    _stab_chromatic,
    _stab_dub_chord,
    _stab_tape_echo,
    _stab_granular,
    _stab_metallic,
]


# ── Main Generation ──────────────────────────────────────────────────────────

def generate(bpm, output_dir, target_duration=17, count=1):
    """Generate loop MIDIs + stab MIDIs in output_dir.

    count=1: single loop.mid (backward compat)
    count>1: loop-01.mid through loop-{count}.mid (batch mode)
    All loops share same key for harmonic continuity.
    """
    os.makedirs(output_dir, exist_ok=True)

    key_name, root_midi, note_pool = _pick_key()

    # ── Bassline MIDI(s) ──
    for n in range(count):
        bass_midi = MIDIFile(1, deinterleave=False)
        bass_midi.addTempo(0, 0, bpm)
        bass_midi.addProgramChange(0, 0, 0, BASS_PROGRAM)

        _write_bassline(bass_midi, 0, 0, note_pool, bpm=bpm, target_duration=target_duration)

        if count == 1:
            fname = "loop.mid"
        else:
            fname = f"loop-{n+1:02d}.mid"

        with open(os.path.join(output_dir, fname), "wb") as f:
            bass_midi.writeFile(f)

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
    parser.add_argument("--bpm", type=int, default=140, help="BPM (default: 140)")
    parser.add_argument("--output-dir", required=True, help="Output directory for MIDIs")
    parser.add_argument("--duration", type=int, default=17, help="Target loop duration in seconds")
    parser.add_argument("--count", type=int, default=1, help="Number of loop variations to generate")
    args = parser.parse_args()

    key = generate(args.bpm, args.output_dir, target_duration=args.duration, count=args.count)
    print(f"key={key} bpm={args.bpm} dir={args.output_dir}")


if __name__ == "__main__":
    main()
