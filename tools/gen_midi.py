#!/usr/bin/env python3
"""
cl4ud3-cr4ck MIDI Generator
Generates all sound effects as MIDI files.
Requires: pip install midiutil
"""

import os
import random
from midiutil import MIDIFile


SOUNDS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "sounds")


def _ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def generate_startup_jingle():
    """Chiptune arpeggio jingle — classic keygen/crackintro vibes.
    ~25 seconds. Extended melody — 8 chord progressions before repeat.
    Am-Dm-Em-Am-F-C-Dm-Em cycle with ascending/descending arps.
    """
    midi = MIDIFile(2, deinterleave=False)
    tempo = 180
    target_beats = 25 * tempo / 60  # ~75 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 80)  # Square lead — SID
    midi.addProgramChange(1, 1, 0, 80)  # Square bass — SID

    # Extended chord progression — 8 chords before repeat
    chords = [
        [69, 72, 76],  # Am (A4 C5 E5)
        [62, 65, 69],  # Dm (D4 F4 A4)
        [64, 67, 71],  # Em (E4 G4 B4)
        [69, 72, 76],  # Am
        [65, 69, 72],  # F  (F4 A4 C5)
        [60, 64, 67],  # C  (C4 E4 G4)
        [62, 65, 69],  # Dm
        [64, 67, 71],  # Em
    ]
    bass_roots = [45, 50, 52, 45, 41, 48, 50, 52]

    t = 0.0
    ci = 0
    while t < target_beats:
        chord = chords[ci % len(chords)]
        bass = bass_roots[ci % len(bass_roots)]

        # Arpeggio — vary direction based on position in cycle
        arp = chord + [n + 12 for n in chord]
        if ci % 4 == 1:
            arp = list(reversed(arp))
        elif ci % 4 == 2:
            # Zigzag: up-down interleave
            arp = [arp[i] for i in [0, 5, 1, 4, 2, 3]]
        elif ci % 4 == 3:
            # High to low with skip
            arp = [arp[i] for i in [5, 2, 4, 1, 3, 0]]

        for i, note in enumerate(arp):
            if t >= target_beats:
                break
            dur = 0.15
            vel = max(70, 100 - i * 3)
            midi.addNote(0, 0, note, t, dur, vel)
            t += dur

        # Hold top note
        if t < target_beats:
            midi.addNote(0, 0, arp[-1], t, 0.4, 85)
            t += 0.4

        # Bass pulse
        bass_t = t - len(arp) * 0.15 - 0.4
        if bass_t >= 0:
            midi.addNote(1, 1, bass, bass_t, 1.0, 110)
            midi.addNote(1, 1, bass, bass_t + 0.5, 0.3, 80)

        ci += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-01.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_startup_jingle_2():
    """C64 SID-style rapid fire — ~25 seconds.
    Rapid pentatonic bursts cycling through Cm-Gm-Bb-Fm with
    SID-signature rapid-fire arpeggios and pulse width modulation feel.
    """
    midi = MIDIFile(2, deinterleave=False)
    tempo = 200
    target_beats = 25 * tempo / 60  # ~83 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 81)  # Saw lead
    midi.addProgramChange(1, 1, 0, 80)  # Square — second voice

    # SID-style: rapid arpeggio patterns for each chord
    patterns = [
        [60, 63, 67, 72, 75, 79, 84],  # Cm
        [55, 58, 62, 67, 70, 74, 79],  # Gm
        [58, 62, 65, 70, 74, 77, 82],  # Bb
        [53, 56, 60, 65, 68, 72, 77],  # Fm
    ]

    t = 0.0
    cycle = 0
    while t < target_beats:
        for pi, pattern in enumerate(patterns):
            if t >= target_beats:
                break

            # Rapid up burst
            for n in pattern:
                if t >= target_beats:
                    break
                midi.addNote(0, 0, n, t, 0.1, 100)
                t += 0.08

            # Rapid down burst (variation)
            if cycle % 2 == 0:
                for n in reversed(pattern[:-1]):
                    if t >= target_beats:
                        break
                    midi.addNote(0, 0, n, t, 0.1, 90)
                    t += 0.08

            # SID second voice — counter melody
            if t < target_beats:
                midi.addNote(1, 1, pattern[0] + 24, t, 0.3, 70)
                midi.addNote(1, 1, pattern[2] + 24, t + 0.15, 0.3, 65)
                t += 0.4

            # Brief pause between chord changes
            t += 0.1

        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-02.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_startup_jingle_3():
    """Demoscene tracker — ~25 seconds. E minor riff with
    4 melody variations cycling. Classic Amiga MOD tracker vibes.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 160
    target_beats = 25 * tempo / 60  # ~67 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 80)  # Square wave melody — SID
    midi.addProgramChange(1, 1, 0, 81)  # Saw bass — SID
    midi.addProgramChange(2, 9, 0, 0)   # Drums

    # Four melody phrases — longer cycle before repeating
    melody_a = [
        (64, 0.25), (67, 0.25), (71, 0.25), (76, 0.25),
        (74, 0.25), (71, 0.25), (67, 0.5),
        (64, 0.25), (67, 0.25), (71, 0.25), (76, 0.5),
        (79, 0.75),
    ]
    melody_b = [
        (76, 0.25), (74, 0.25), (71, 0.25), (67, 0.25),
        (69, 0.25), (71, 0.25), (74, 0.5),
        (76, 0.25), (79, 0.25), (76, 0.25), (74, 0.5),
        (71, 0.75),
    ]
    melody_c = [
        (71, 0.25), (74, 0.25), (76, 0.25), (79, 0.25),
        (83, 0.5), (79, 0.25), (76, 0.25),
        (74, 0.25), (71, 0.25), (67, 0.25), (64, 0.5),
        (67, 0.75),
    ]
    melody_d = [
        (79, 0.25), (76, 0.5), (71, 0.25),
        (67, 0.25), (64, 0.25), (67, 0.25), (71, 0.5),
        (76, 0.25), (74, 0.25), (71, 0.5),
        (64, 0.5), (67, 0.75),
    ]
    melodies = [melody_a, melody_b, melody_c, melody_d]

    bass_patterns = [
        [(40, 0.5), (40, 0.25), (40, 0.25), (43, 0.5), (43, 0.5),
         (45, 0.5), (45, 0.25), (47, 0.25), (47, 1.0)],
        [(43, 0.5), (43, 0.25), (45, 0.25), (47, 0.5), (45, 0.5),
         (40, 0.5), (40, 0.25), (43, 0.25), (40, 1.0)],
    ]

    # Extended melodies — 6 phrases total
    melody_e = [
        (67, 0.25), (71, 0.25), (76, 0.25), (79, 0.5),
        (83, 0.25), (79, 0.25), (76, 0.5),
        (71, 0.25), (67, 0.25), (64, 0.25), (67, 0.5),
        (71, 0.75),
    ]
    melody_f = [
        (83, 0.25), (79, 0.5), (76, 0.25),
        (71, 0.25), (74, 0.25), (76, 0.25), (79, 0.5),
        (76, 0.25), (71, 0.25), (67, 0.5),
        (64, 0.5), (67, 0.75),
    ]
    melodies = [melody_a, melody_b, melody_c, melody_d, melody_e, melody_f]

    # Minimal drums — sparse hats only, no snare
    drum_pattern = [
        (42, 0.0),
        (42, 2.0),
        (46, 3.5),
    ]
    phrase_len = sum(d for _, d in melody_a)

    t = 0.0
    cycle = 0
    while t < target_beats:
        mel = melodies[cycle % 6]
        mt = t
        for note, dur in mel:
            if mt >= target_beats:
                break
            midi.addNote(0, 0, note, mt, dur, 95)
            mt += dur

        bt = t
        bp = bass_patterns[cycle % 2]
        for note, dur in bp:
            if bt >= target_beats:
                break
            midi.addNote(1, 1, note, bt, dur, 80)
            bt += dur

        for dn, dt in drum_pattern:
            drum_t = t + dt
            if drum_t < target_beats:
                midi.addNote(2, 9, dn, drum_t, 0.1, 85)

        t += phrase_len
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-03.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_dnb_jungle_1():
    """Drum & Bass / Jungle — ~25 seconds. 170 BPM.
    SID stabs over mid-range bass (not too deep). Sparse hats.
    12 stab variations + 8 bass variations — long before repeat.
    More glitchy and full — rapid stab patterns + double-tracked.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 170
    target_beats = 25 * tempo / 60  # ~71 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 81)   # Saw lead — SID
    midi.addProgramChange(1, 1, 0, 80)   # Square bass — SID
    midi.addProgramChange(2, 9, 0, 0)    # Drums

    # Sparse hats only
    hat_pats = [
        [(42, 0.0), (42, 1.0), (46, 1.75)],
        [(42, 0.5), (46, 1.5)],
        [(42, 0.0), (42, 1.25)],
        [(46, 0.75), (42, 1.5)],
    ]

    # 8 bass variations — MID register (40-55 range, not deep 28-35)
    bass_lines = [
        [(42, 0.0, 0.5), (42, 0.5, 0.25), (45, 0.75, 0.5),
         (40, 1.5, 0.5), (45, 2.0, 0.25), (47, 2.5, 0.5)],
        [(45, 0.0, 0.5), (42, 0.5, 0.5),
         (40, 1.0, 0.25), (42, 1.5, 0.25), (45, 2.0, 0.5), (40, 2.5, 0.5)],
        [(40, 0.0, 0.25), (42, 0.25, 0.25), (45, 0.5, 0.5),
         (47, 1.0, 0.25), (45, 1.5, 0.25), (42, 2.0, 0.25), (40, 2.5, 0.5)],
        [(47, 0.0, 0.25), (45, 0.25, 0.5), (42, 0.75, 0.25),
         (40, 1.0, 0.5), (42, 1.5, 0.25), (45, 2.0, 0.5)],
        [(42, 0.0, 0.5), (47, 0.5, 0.25), (45, 0.75, 0.5),
         (42, 1.5, 0.25), (40, 2.0, 0.5), (42, 2.5, 0.5)],
        [(45, 0.0, 0.25), (47, 0.25, 0.5), (45, 0.75, 0.25),
         (42, 1.0, 0.5), (40, 1.5, 0.5), (45, 2.0, 0.5)],
        [(40, 0.0, 0.5), (45, 0.5, 0.5), (47, 1.0, 0.5),
         (50, 1.5, 0.25), (47, 2.0, 0.25), (45, 2.5, 0.5)],
        [(50, 0.0, 0.25), (47, 0.25, 0.25), (45, 0.5, 0.5),
         (42, 1.0, 0.5), (40, 1.5, 0.25), (42, 2.0, 0.25), (45, 2.5, 0.5)],
    ]

    # 12 stab patterns — glitchy, rapid, double-tracked for fullness
    stab_sets = [
        [(0.0, [60, 63, 67]), (0.75, [63, 67, 70]), (1.5, [58, 62, 65]),
         (2.0, [56, 60, 63]), (2.5, [58, 62, 67])],
        [(0.25, [63, 67, 72]), (0.75, [60, 63, 67]),
         (1.25, [58, 62, 65]), (2.0, [63, 67, 70]), (2.75, [56, 60, 63])],
        [(0.0, [56, 60, 63]), (0.5, [58, 62, 65]), (1.0, [60, 63, 67]),
         (1.5, [63, 67, 70]), (2.25, [60, 63, 67])],
        [(0.25, [58, 62, 67]), (1.0, [56, 60, 63]),
         (1.5, [63, 67, 72]), (2.0, [60, 63, 67]), (2.75, [58, 62, 65])],
        [(0.0, [67, 70, 75]), (0.5, [63, 67, 70]),
         (1.25, [60, 63, 67]), (2.0, [58, 62, 65]), (2.5, [56, 60, 63])],
        [(0.5, [56, 60, 65]), (1.0, [58, 63, 67]),
         (1.75, [60, 65, 70]), (2.25, [63, 67, 72])],
        [(0.0, [60, 65, 70]), (0.75, [58, 62, 67]),
         (1.25, [56, 60, 63]), (2.0, [58, 62, 67]), (2.5, [63, 67, 72])],
        [(0.25, [67, 72, 75]), (0.75, [63, 67, 70]),
         (1.5, [60, 63, 67]), (2.0, [56, 60, 65]), (2.75, [58, 62, 67])],
        [(0.0, [58, 63, 67]), (0.5, [60, 65, 70]),
         (1.0, [63, 67, 72]), (1.75, [60, 63, 67]), (2.5, [56, 60, 63])],
        [(0.25, [63, 67, 72]), (1.0, [67, 70, 75]),
         (1.5, [63, 67, 70]), (2.25, [58, 62, 65])],
        [(0.0, [56, 60, 65]), (0.5, [60, 63, 70]),
         (1.0, [58, 65, 67]), (1.75, [63, 67, 72]), (2.5, [60, 63, 67])],
        [(0.25, [60, 67, 72]), (0.75, [58, 63, 67]),
         (1.5, [56, 60, 65]), (2.0, [60, 63, 70]), (2.75, [63, 67, 72])],
    ]

    t = 0.0
    cycle = 0
    while t < target_beats:
        # Sparse hats
        hp = hat_pats[cycle % len(hat_pats)]
        for note, dt in hp:
            drum_t = t + dt
            if drum_t < target_beats:
                midi.addNote(2, 9, note, drum_t, 0.1, 60)

        # Bass — mid register
        bass = bass_lines[cycle % len(bass_lines)]
        for note, bt, dur in bass:
            bass_t = t + bt
            if bass_t < target_beats:
                midi.addNote(1, 1, note, bass_t, dur, 95)

        # Stabs — double-tracked for fullness (octave up quieter)
        stabs = stab_sets[cycle % len(stab_sets)]
        for st, notes in stabs:
            stab_t = t + st
            if stab_t < target_beats:
                for n in notes:
                    midi.addNote(0, 0, n, stab_t, 0.15, 100)
                    midi.addNote(0, 0, n + 12, stab_t, 0.1, 70)

        t += 3.0  # Shorter cycles = more variety
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-04-jungle.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_dnb_jungle_2():
    """Belgian hoover #2 — ~25 seconds at 135 BPM.
    Beltram-style like jingle-06 but in E minor. Dark saw hoover riff
    with detuned double-track, rolling sub bass, minimal hats.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 135
    target_beats = 25 * tempo / 60  # ~56 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 81)   # Saw wave — hoover
    midi.addProgramChange(1, 1, 0, 80)   # Square bass — sub
    midi.addProgramChange(2, 9, 0, 0)    # Drums

    # Hoover riff — dark Em, low register, detuned double-tracked
    hoover_a = [
        (52, 0.5), (55, 0.25), (59, 0.25), (64, 0.5),
        (62, 0.25), (59, 0.5), (55, 0.25),
        (52, 0.5), (59, 0.25), (64, 0.75),
    ]
    hoover_b = [
        (64, 0.5), (62, 0.25), (59, 0.25), (55, 0.5),
        (52, 0.25), (55, 0.5), (59, 0.25),
        (62, 0.5), (64, 0.25), (67, 0.75),
    ]
    hoover_c = [
        (67, 0.25), (64, 0.25), (62, 0.5), (59, 0.25),
        (55, 0.25), (52, 0.5), (55, 0.25),
        (59, 0.5), (62, 0.25), (64, 0.75),
    ]
    hoover_d = [
        (52, 0.25), (55, 0.5), (59, 0.25), (62, 0.25),
        (64, 0.5), (67, 0.25), (64, 0.25),
        (62, 0.5), (59, 0.25), (55, 0.75),
    ]
    hoovers = [hoover_a, hoover_b, hoover_c, hoover_d]
    riff_len = sum(d for _, d in hoover_a)  # 4.0 beats

    # Sub bass — dark rolling offbeat
    sub_notes = [28, 28, 31, 28, 26, 28, 31, 33]

    t = 0.0
    cycle = 0
    while t < target_beats:
        riff = hoovers[cycle % len(hoovers)]
        mt = t
        for note, dur in riff:
            if mt >= target_beats:
                break
            # Hoover = detuned double-track
            midi.addNote(0, 0, note, mt, dur, 100)
            midi.addNote(0, 0, note - 12, mt, dur, 75)
            mt += dur

        # Sub bass — offbeat pulse
        sub = sub_notes[cycle % len(sub_notes)]
        i = 0
        while t + i * 0.5 + 0.25 < t + riff_len and t + i * 0.5 + 0.25 < target_beats:
            midi.addNote(1, 1, sub, t + i * 0.5 + 0.25, 0.2, 110)
            i += 1

        # Minimal hats — just a pulse
        i = 0
        while t + i * 1.0 < t + riff_len and t + i * 1.0 < target_beats:
            midi.addNote(2, 9, 42, t + i * 1.0, 0.1, 60)
            i += 1

        t += riff_len
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-05-breakcore.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_belgian_techno():
    """Belgian techno rave 1992 — ~25 seconds at 130 BPM.
    Joey Beltram hoover style. Dark saw hoover riff over
    rolling sub bass. Minimal hats only. D minor.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 130
    target_beats = 25 * tempo / 60  # ~54 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 81)   # Saw wave — hoover
    midi.addProgramChange(1, 1, 0, 80)   # Square bass — sub
    midi.addProgramChange(2, 9, 0, 0)    # Drums

    # Hoover riff — dark Dm, low register, detuned double-tracked
    hoover_a = [
        (50, 0.5), (53, 0.25), (57, 0.25), (62, 0.5),
        (60, 0.25), (57, 0.5), (53, 0.25),
        (50, 0.5), (57, 0.25), (62, 0.75),
    ]
    hoover_b = [
        (62, 0.5), (60, 0.25), (57, 0.25), (53, 0.5),
        (50, 0.25), (53, 0.5), (57, 0.25),
        (60, 0.5), (62, 0.25), (65, 0.75),
    ]
    hoover_c = [
        (65, 0.25), (62, 0.25), (60, 0.5), (57, 0.25),
        (53, 0.25), (50, 0.5), (53, 0.25),
        (57, 0.5), (60, 0.25), (62, 0.75),
    ]
    hoovers = [hoover_a, hoover_b, hoover_c]
    riff_len = sum(d for _, d in hoover_a)  # 4.0 beats

    # Sub bass — dark rolling offbeat, lower register
    sub_notes = [26, 26, 29, 26, 24, 26, 29, 31]

    t = 0.0
    cycle = 0
    while t < target_beats:
        riff = hoovers[cycle % 3]
        mt = t
        for note, dur in riff:
            if mt >= target_beats:
                break
            # Hoover = detuned double-track
            midi.addNote(0, 0, note, mt, dur, 100)
            midi.addNote(0, 0, note - 12, mt, dur, 75)
            mt += dur

        # Sub bass — offbeat pulse
        sub = sub_notes[cycle % len(sub_notes)]
        i = 0
        while t + i * 0.5 + 0.25 < t + riff_len and t + i * 0.5 + 0.25 < target_beats:
            midi.addNote(1, 1, sub, t + i * 0.5 + 0.25, 0.2, 110)
            i += 1

        # Minimal hats — just a pulse
        i = 0
        while t + i * 1.0 < t + riff_len and t + i * 1.0 < target_beats:
            midi.addNote(2, 9, 42, t + i * 1.0, 0.1, 60)
            i += 1

        t += riff_len
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-06-beltram.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_gabber_2():
    """Gabber #2 — ~25 seconds at 155 BPM.
    Rotterdam terror in Eb minor. Hoover-style saw riff (like beltram)
    with detuned double-track. Mid-range bass, not deep.
    Abrasive screech — sharp intervals, high velocity. 8 melody phrases.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 155
    target_beats = 25 * tempo / 60  # ~65 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 81)   # Saw — hoover riff
    midi.addProgramChange(1, 1, 0, 80)   # Square — abrasive screech
    midi.addProgramChange(2, 9, 0, 0)    # Drums

    # Hoover riff — Eb minor, detuned double-track like beltram
    hoover_pats = [
        [(51, 0.5), (54, 0.25), (58, 0.25), (63, 0.5),
         (61, 0.25), (58, 0.5), (54, 0.25), (51, 0.5), (58, 0.25), (63, 0.75)],
        [(63, 0.5), (61, 0.25), (58, 0.25), (54, 0.5),
         (51, 0.25), (54, 0.5), (58, 0.25), (61, 0.5), (63, 0.25), (66, 0.75)],
        [(66, 0.25), (63, 0.25), (61, 0.5), (58, 0.25),
         (54, 0.25), (51, 0.5), (54, 0.25), (58, 0.5), (61, 0.25), (63, 0.75)],
        [(51, 0.25), (54, 0.5), (58, 0.25), (61, 0.25),
         (63, 0.5), (66, 0.25), (63, 0.25), (61, 0.5), (58, 0.25), (54, 0.75)],
        [(58, 0.5), (61, 0.25), (63, 0.5), (66, 0.25),
         (63, 0.25), (61, 0.25), (58, 0.5), (54, 0.25), (51, 0.5), (54, 0.75)],
        [(54, 0.25), (58, 0.25), (63, 0.5), (66, 0.25),
         (68, 0.5), (66, 0.25), (63, 0.25), (61, 0.5), (58, 0.25), (54, 0.75)],
    ]
    riff_len = sum(d for _, d in hoover_pats[0])

    # Mid-range sub bass — offbeat pulse (not deep, 39-46 range)
    sub_notes = [39, 39, 42, 39, 37, 39, 42, 44]

    # Abrasive screech — sharp dissonant intervals, tritones, high vel
    screech_pats = [
        [(94, 0.15), (99, 0.15), (95, 0.2), (100, 0.15), (94, 0.15),
         (89, 0.2), (94, 0.15), (100, 0.15), (95, 0.2), (99, 0.15),
         (94, 0.15), (89, 0.2), (94, 0.5)],
        [(99, 0.15), (94, 0.2), (100, 0.15), (95, 0.15), (89, 0.2),
         (94, 0.15), (99, 0.15), (94, 0.2), (89, 0.15), (94, 0.15),
         (100, 0.2), (95, 0.5)],
    ]

    t = 0.0
    cycle = 0
    while t < target_beats:
        # Hoover — detuned double-track
        riff = hoover_pats[cycle % len(hoover_pats)]
        mt = t
        for note, dur in riff:
            if mt >= target_beats:
                break
            midi.addNote(0, 0, note, mt, dur, 100)
            midi.addNote(0, 0, note - 12, mt, dur, 70)
            mt += dur

        # Sub bass — offbeat pulse
        sub = sub_notes[cycle % len(sub_notes)]
        i = 0
        while t + i * 0.5 + 0.25 < t + riff_len and t + i * 0.5 + 0.25 < target_beats:
            midi.addNote(1, 1, sub, t + i * 0.5 + 0.25, 0.2, 105)
            i += 1

        # Screech — every other cycle for contrast
        if cycle % 2 == 1:
            sp = screech_pats[(cycle // 2) % len(screech_pats)]
            st = t
            for note, dur in sp:
                if st >= target_beats:
                    break
                midi.addNote(1, 1, note, st, dur, 120)
                st += dur

        # Minimal hats
        i = 0
        while t + i * 1.0 < t + riff_len and t + i * 1.0 < target_beats:
            midi.addNote(2, 9, 42, t + i * 1.0, 0.1, 55)
            i += 1

        t += riff_len
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-07-gabber2.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_gabber_hardstyle():
    """Gabber / hardstyle — ~25 seconds at 150 BPM.
    Hoover-style saw riff (like beltram) in E minor.
    Detuned double-track, mid-range bass, abrasive screech.
    6 hoover phrases for extended melody.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 150
    target_beats = 25 * tempo / 60  # ~63 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 81)   # Saw — hoover riff
    midi.addProgramChange(1, 1, 0, 80)   # Square — abrasive screech
    midi.addProgramChange(2, 9, 0, 0)    # Drums

    # Hoover riff — E minor, detuned double-track
    hoover_pats = [
        [(52, 0.5), (55, 0.25), (59, 0.25), (64, 0.5),
         (62, 0.25), (59, 0.5), (55, 0.25), (52, 0.5), (59, 0.25), (64, 0.75)],
        [(64, 0.5), (62, 0.25), (59, 0.25), (55, 0.5),
         (52, 0.25), (55, 0.5), (59, 0.25), (62, 0.5), (64, 0.25), (67, 0.75)],
        [(67, 0.25), (64, 0.25), (62, 0.5), (59, 0.25),
         (55, 0.25), (52, 0.5), (55, 0.25), (59, 0.5), (62, 0.25), (64, 0.75)],
        [(55, 0.25), (59, 0.5), (62, 0.25), (64, 0.25),
         (67, 0.5), (71, 0.25), (67, 0.25), (64, 0.5), (62, 0.25), (59, 0.75)],
        [(59, 0.5), (62, 0.25), (64, 0.5), (67, 0.25),
         (71, 0.25), (67, 0.25), (64, 0.5), (59, 0.25), (55, 0.5), (52, 0.75)],
        [(52, 0.25), (59, 0.25), (64, 0.5), (67, 0.25),
         (71, 0.5), (67, 0.25), (64, 0.25), (62, 0.5), (59, 0.25), (55, 0.75)],
    ]
    riff_len = sum(d for _, d in hoover_pats[0])

    # Mid-range sub bass (40-47)
    sub_notes = [40, 40, 43, 40, 38, 40, 43, 45]

    # Abrasive screech — sharp dissonant intervals, tritones
    screech_pats = [
        [(92, 0.15), (97, 0.15), (93, 0.2), (98, 0.15), (92, 0.15),
         (87, 0.2), (92, 0.15), (98, 0.15), (93, 0.2), (97, 0.15),
         (92, 0.15), (87, 0.2), (92, 0.5)],
        [(97, 0.15), (92, 0.2), (98, 0.15), (93, 0.15), (87, 0.2),
         (92, 0.15), (97, 0.15), (92, 0.2), (87, 0.15), (92, 0.15),
         (98, 0.2), (93, 0.5)],
        [(87, 0.2), (92, 0.15), (97, 0.15), (93, 0.2), (98, 0.15),
         (92, 0.15), (87, 0.2), (92, 0.15), (97, 0.15), (98, 0.2),
         (93, 0.15), (87, 0.5)],
    ]

    t = 0.0
    cycle = 0
    while t < target_beats:
        # Hoover — detuned double-track
        riff = hoover_pats[cycle % len(hoover_pats)]
        mt = t
        for note, dur in riff:
            if mt >= target_beats:
                break
            midi.addNote(0, 0, note, mt, dur, 100)
            midi.addNote(0, 0, note - 12, mt, dur, 70)
            mt += dur

        # Sub bass — offbeat pulse
        sub = sub_notes[cycle % len(sub_notes)]
        i = 0
        while t + i * 0.5 + 0.25 < t + riff_len and t + i * 0.5 + 0.25 < target_beats:
            midi.addNote(1, 1, sub, t + i * 0.5 + 0.25, 0.2, 105)
            i += 1

        # Screech — every other cycle
        if cycle % 2 == 1:
            sp = screech_pats[(cycle // 2) % len(screech_pats)]
            st = t
            for note, dur in sp:
                if st >= target_beats:
                    break
                midi.addNote(1, 1, note, st, dur, 120)
                st += dur

        # Minimal hats
        i = 0
        while t + i * 1.0 < t + riff_len and t + i * 1.0 < target_beats:
            midi.addNote(2, 9, 42, t + i * 1.0, 0.1, 55)
            i += 1

        t += riff_len
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-08-gabber.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_detroit_techno():
    """Detroit techno — Underground Resistance style. ~25 seconds at 130 BPM.
    Dark minor key string-pad stabs over rolling saw bass.
    Minimal hats. C# minor. Hypnotic looping progression.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 130
    target_beats = 25 * tempo / 60  # ~54 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 81)   # Saw — string-like pads
    midi.addProgramChange(1, 1, 0, 80)   # Square — deep bass
    midi.addProgramChange(2, 9, 0, 0)    # Drums

    # Chord stab patterns — C# minor, sparse and hypnotic (8 variations)
    stab_sets = [
        # C#m - Abm
        [(0.0, [61, 64, 68], 0.8), (1.5, [56, 59, 64], 0.6),
         (3.0, [61, 64, 68], 0.4)],
        # F#m - G#m
        [(0.5, [54, 57, 61], 0.8), (2.0, [56, 59, 63], 0.6),
         (3.5, [54, 57, 61], 0.4)],
        # Abm - B
        [(0.0, [56, 59, 64], 0.8), (1.5, [59, 63, 66], 0.6),
         (3.0, [56, 59, 64], 0.4)],
        # E - C#m
        [(0.5, [52, 56, 59], 0.8), (2.0, [61, 64, 68], 0.6),
         (3.5, [52, 56, 59], 0.4)],
        # B major — brighter, higher register lift
        [(0.0, [71, 75, 78], 0.8), (2.0, [71, 75, 78], 0.6),
         (3.0, [68, 71, 76], 0.4)],
        # C#m octave up — soaring
        [(0.0, [73, 76, 80], 1.2), (2.5, [80, 83, 85], 0.6)],
        # Descending — G#m down to E
        [(0.0, [68, 71, 75], 0.6), (1.0, [64, 68, 71], 0.6),
         (2.0, [61, 64, 68], 0.6), (3.0, [52, 56, 59], 0.8)],
        # Resolve — low Abm swell up to C#m
        [(0.0, [44, 47, 52], 1.5), (2.0, [49, 52, 56], 1.0),
         (3.5, [61, 64, 68], 0.4)],
    ]

    # Bass — deep rolling saw, C# minor root movement
    bass_pats = [
        [(37, 0.0, 1.0), (37, 1.0, 0.5), (40, 1.5, 0.5),
         (37, 2.0, 1.0), (35, 3.0, 0.5), (37, 3.5, 0.5)],
        [(40, 0.0, 1.0), (37, 1.0, 1.0),
         (35, 2.0, 0.5), (37, 2.5, 0.5), (40, 3.0, 0.5), (42, 3.5, 0.5)],
        [(35, 0.0, 0.5), (37, 0.5, 0.5), (40, 1.0, 1.0),
         (42, 2.0, 0.5), (40, 2.5, 0.5), (37, 3.0, 1.0)],
    ]

    t = 0.0
    cycle = 0
    while t < target_beats:
        # Chord stabs — each with own timing
        stabs = stab_sets[cycle % len(stab_sets)]
        for offset, notes, dur in stabs:
            stab_t = t + offset
            if stab_t < target_beats:
                for n in notes:
                    midi.addNote(0, 0, n, stab_t, dur, 90)

        # Bass
        bp = bass_pats[cycle % len(bass_pats)]
        for note, bt, dur in bp:
            bass_t = t + bt
            if bass_t < target_beats:
                midi.addNote(1, 1, note, bass_t, dur, 105)

        # Minimal hats — sparse
        for i in range(2):
            ht = t + i * 2.0
            if ht < target_beats:
                midi.addNote(2, 9, 42, ht, 0.1, 55)

        t += 4.0
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-09-detroit.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_demoscene_1():
    """Demoscene tracker 2 — Amiga MOD style. ~25 seconds at 140 BPM.
    A minor. Fast arpeggiated melody over pulsing square bass.
    Two voice counterpoint — classic 4-channel tracker limitation.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 140
    target_beats = 25 * tempo / 60  # ~58 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 80)   # Square — melody
    midi.addProgramChange(1, 1, 0, 81)   # Saw — counter melody
    midi.addProgramChange(2, 2, 0, 80)   # Square — bass

    # 6 melody phrases — tracker style arpeggios
    melodies = [
        [(69, 0.125), (72, 0.125), (76, 0.125), (81, 0.125),
         (76, 0.125), (72, 0.125), (69, 0.25), (76, 0.25), (81, 0.5)],
        [(81, 0.125), (76, 0.125), (72, 0.125), (69, 0.125),
         (65, 0.125), (69, 0.125), (72, 0.25), (76, 0.25), (69, 0.5)],
        [(72, 0.125), (76, 0.125), (81, 0.125), (84, 0.125),
         (81, 0.125), (76, 0.125), (72, 0.25), (69, 0.25), (76, 0.5)],
        [(84, 0.125), (81, 0.125), (76, 0.125), (72, 0.125),
         (69, 0.125), (72, 0.125), (76, 0.25), (81, 0.25), (84, 0.5)],
        [(69, 0.125), (76, 0.125), (81, 0.125), (84, 0.125),
         (88, 0.25), (84, 0.125), (81, 0.125), (76, 0.25), (72, 0.5)],
        [(88, 0.125), (84, 0.125), (81, 0.125), (76, 0.125),
         (72, 0.25), (69, 0.125), (65, 0.125), (69, 0.25), (72, 0.5)],
    ]
    phrase_len = sum(d for _, d in melodies[0])

    # Counter melody — slower, offset
    counter_notes = [
        [(57, 0.5), (60, 0.5), (64, 0.5), (60, 0.5)],
        [(60, 0.5), (64, 0.5), (57, 0.5), (64, 0.5)],
        [(64, 0.5), (60, 0.5), (57, 0.5), (60, 0.5)],
    ]

    # Bass — pulsing
    bass_notes = [45, 45, 48, 45, 43, 45, 48, 50, 45, 43, 41, 45]

    t = 0.0
    cycle = 0
    while t < target_beats:
        mel = melodies[cycle % len(melodies)]
        mt = t
        for note, dur in mel:
            if mt >= target_beats:
                break
            midi.addNote(0, 0, note, mt, dur, 100)
            mt += dur

        # Counter melody
        cn = counter_notes[cycle % len(counter_notes)]
        ct = t
        for note, dur in cn:
            if ct >= target_beats:
                break
            midi.addNote(1, 1, note, ct, dur, 75)
            ct += dur

        # Bass pulse
        bn = bass_notes[cycle % len(bass_notes)]
        midi.addNote(2, 2, bn, t, 0.25, 95)
        if t + 0.5 < target_beats:
            midi.addNote(2, 2, bn, t + 0.5, 0.25, 80)
        if t + 1.0 < target_beats:
            midi.addNote(2, 2, bn, t + 1.0, 0.25, 95)
        if t + 1.5 < target_beats:
            midi.addNote(2, 2, bn + 5, t + 1.5, 0.25, 80)

        t += phrase_len
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-10-demoscene.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_demoscene_2():
    """Demoscene chip — XM tracker style. ~25 seconds at 155 BPM.
    D minor. Rapid chip arpeggios with echo effect (delayed quieter notes).
    Classic Amiga demo competition vibes. 3 voices.
    """
    midi = MIDIFile(3, deinterleave=False)
    tempo = 155
    target_beats = 25 * tempo / 60  # ~65 beats

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 80)   # Square — main
    midi.addProgramChange(1, 1, 0, 80)   # Square — echo
    midi.addProgramChange(2, 2, 0, 81)   # Saw — bass

    # 8 chip arpeggio phrases — D minor
    arps = [
        [62, 65, 69, 74, 77, 81, 74, 69],
        [74, 69, 65, 62, 57, 62, 65, 69],
        [65, 69, 74, 77, 81, 86, 81, 77],
        [86, 81, 77, 74, 69, 65, 62, 65],
        [57, 62, 65, 69, 74, 69, 65, 62],
        [69, 74, 77, 81, 86, 89, 86, 81],
        [81, 77, 74, 69, 65, 62, 57, 53],
        [53, 57, 62, 65, 69, 74, 77, 81],
    ]
    step = 0.125
    phrase_len = len(arps[0]) * step  # 1.0 beat

    # Bass pattern — Dm root movement
    bass_pats = [
        [(38, 1.0)], [(38, 0.5), (41, 0.5)],
        [(36, 1.0)], [(41, 0.5), (38, 0.5)],
        [(38, 0.5), (36, 0.5)], [(33, 1.0)],
        [(36, 0.5), (38, 0.5)], [(41, 1.0)],
    ]

    t = 0.0
    cycle = 0
    while t < target_beats:
        arp = arps[cycle % len(arps)]
        mt = t
        for n in arp:
            if mt >= target_beats:
                break
            # Main voice
            midi.addNote(0, 0, n, mt, step * 0.8, 100)
            # Echo — delayed, quieter
            echo_t = mt + step * 0.5
            if echo_t < target_beats:
                midi.addNote(1, 1, n, echo_t, step * 0.6, 55)
            mt += step

        # Bass
        bp = bass_pats[cycle % len(bass_pats)]
        bt = t
        for note, dur in bp:
            if bt >= target_beats:
                break
            midi.addNote(2, 2, note, bt, dur, 90)
            bt += dur

        t += phrase_len
        cycle += 1

    out = os.path.join(SOUNDS_DIR, "startup", "jingle-11-chip.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_warez_keygen():
    """Keygen Classic — Stabby square wave in Am. ~6s at 140 BPM.
    Just stabs + bass. Two parts. Every keygen.exe ever.
    """
    midi = MIDIFile(2, deinterleave=False)
    tempo = 140
    target_beats = 6 * tempo / 60

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 80)   # Square wave — stabs
    midi.addProgramChange(1, 1, 0, 80)   # Square wave — bass

    # Two-chord stab pattern: Am - F
    stabs = [
        # Am stabs
        [(69, 0.15), (None, 0.1), (72, 0.15), (None, 0.1),
         (76, 0.15), (None, 0.35), (69, 0.15), (72, 0.15), (None, 0.1)],
        # F stabs
        [(65, 0.15), (None, 0.1), (69, 0.15), (None, 0.1),
         (72, 0.15), (None, 0.35), (65, 0.15), (69, 0.15), (None, 0.1)],
    ]
    bass_notes = [45, 41]

    t = 0.0
    while t < target_beats:
        for si, (stab_pat, bass) in enumerate(zip(stabs, bass_notes)):
            if t >= target_beats:
                break
            start = t
            for note, dur in stab_pat:
                if t >= target_beats:
                    break
                if note is not None:
                    midi.addNote(0, 0, note, t, 0.1, 110)
                t += dur
            midi.addNote(1, 1, bass, start, t - start, 95)

    out = os.path.join(SOUNDS_DIR, "startup-warez", "warez-01-keygen.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_warez_cracktro():
    """Cracktro Stab — Harsh square stabs. ~5s at 160 BPM.
    Just one channel hammering notes. Busted Commodore garbage.
    """
    midi = MIDIFile(1, deinterleave=False)
    tempo = 160
    target_beats = 5 * tempo / 60

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 80)   # Square

    # Stabby one-channel pattern — Dm
    pattern = [62, None, 65, None, 69, 62, None, 74,
               None, 69, 65, None, 62, None, 69, 74]
    dur = 0.125

    t = 0.0
    while t < target_beats:
        for n in pattern:
            if t >= target_beats:
                break
            if n is not None:
                midi.addNote(0, 0, n, t, 0.08, 120)
            t += dur

    out = os.path.join(SOUNDS_DIR, "startup-warez", "warez-02-cracktro.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_warez_scene():
    """Scene Loader — Glitchy stabs + wrong bass. ~7s at 120 BPM.
    Steel drums playing minor stabs over harmonica bass.
    Wrong instruments = crack screen aesthetic.
    """
    midi = MIDIFile(2, deinterleave=False)
    tempo = 120
    target_beats = 7 * tempo / 60

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 80)   # Square wave — SID stabs
    midi.addProgramChange(1, 1, 0, 81)   # Saw wave — SID bass

    # Stabby pattern — Em stabs with gaps
    stabs = [64, None, 67, 71, None, None, 64, 67,
             None, 71, 76, None, 67, None, 64, None]
    bass_pat = [40, None, None, None, 40, None, 43, None,
                None, None, 40, None, None, 45, None, None]
    dur = 0.125

    t = 0.0
    while t < target_beats:
        for s, b in zip(stabs, bass_pat):
            if t >= target_beats:
                break
            if s is not None:
                midi.addNote(0, 0, s, t, 0.08, 105)
            if b is not None:
                midi.addNote(1, 1, b, t, 0.2, 90)
            t += dur

    out = os.path.join(SOUNDS_DIR, "startup-warez", "warez-03-scene.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_warez_nfo():
    """NFO Reader — Saw wave stabs. ~6s at 150 BPM.
    Two-part stab pattern. Saw lead + square bass.
    .MOD file playing in WinAmp circa 2001.
    """
    midi = MIDIFile(2, deinterleave=False)
    tempo = 150
    target_beats = 6 * tempo / 60

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 81)   # Saw lead — stabs
    midi.addProgramChange(1, 1, 0, 80)   # Square bass

    # Part A: high stabs
    part_a = [72, None, 75, 79, None, 72, None, 84,
              79, None, 75, None, 72, 79, None, None]
    # Part B: lower stabs
    part_b = [67, None, 70, 75, None, 67, None, 79,
              75, None, 70, None, 67, 75, None, None]
    bass_a = 36
    bass_b = 31
    dur = 0.125

    t = 0.0
    alt = 0
    while t < target_beats:
        part = part_a if alt % 2 == 0 else part_b
        bass = bass_a if alt % 2 == 0 else bass_b
        start = t
        for n in part:
            if t >= target_beats:
                break
            if n is not None:
                midi.addNote(0, 0, n, t, 0.08, 110)
            t += dur
        midi.addNote(1, 1, bass, start, 0.5, 100)
        midi.addNote(1, 1, bass, start + 0.5, 0.5, 100)
        midi.addNote(1, 1, bass + 5, start + 1.0, 0.5, 100)
        midi.addNote(1, 1, bass, start + 1.5, 0.5, 100)
        alt += 1

    out = os.path.join(SOUNDS_DIR, "startup-warez", "warez-04-nfo.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_warez_glitchload():
    """Glitch Loader — Random stabby chaos. ~5s at 150 BPM.
    Harp doing stabs at random pitches. Pure corrupted MIDI.
    """
    midi = MIDIFile(2, deinterleave=False)
    tempo = 150
    target_beats = 5 * tempo / 60

    midi.addTempo(0, 0, tempo)
    midi.addProgramChange(0, 0, 0, 80)   # Square wave — SID glitch
    midi.addProgramChange(1, 1, 0, 80)   # Square bass

    random.seed(42)
    t = 0.0
    while t < target_beats:
        # Random stabs with gaps
        if random.random() > 0.3:
            n = random.choice([62, 65, 69, 74, 77, 81, 86, 53, 57])
            midi.addNote(0, 0, n, t, 0.08, random.randint(80, 127))
        # Bass stab every 4th step
        if random.random() > 0.7:
            midi.addNote(1, 1, random.choice([38, 33, 40, 36]), t, 0.15, 100)
        t += 0.125
    random.seed()

    out = os.path.join(SOUNDS_DIR, "startup-warez", "warez-05-glitchload.mid")
    _ensure_dir(os.path.dirname(out))
    with open(out, "wb") as f:
        midi.writeFile(f)
    print(f"  [+] {out}")


def generate_modem_sounds():
    """Generate 5 short modem sounds (~1-2 seconds each).
    Quick glitchy handshake blasts for tool-use notifications.
    """
    modem_dir = os.path.join(SOUNDS_DIR, "modem")
    _ensure_dir(modem_dir)

    random.seed(99)  # Deterministic

    # Modem 1: Light — quick carrier chirp + short scramble (1s)
    midi = MIDIFile(2, deinterleave=False)
    midi.addTempo(0, 0, 480)
    midi.addProgramChange(0, 0, 0, 80)   # Square
    midi.addProgramChange(1, 1, 0, 87)   # Calliope
    midi.addNote(0, 0, 81, 0.0, 0.1, 70)
    midi.addNote(0, 0, 84, 0.08, 0.1, 70)
    t = 0.2
    for _ in range(15):
        midi.addNote(1, 1, random.randint(72, 108), t, 0.03, random.randint(50, 85))
        t += random.uniform(0.02, 0.04)
    midi.addNote(0, 0, 84, t, 0.1, 40)
    with open(os.path.join(modem_dir, "dialup-01-light.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] dialup-01-light.mid")

    # Modem 2: Medium — answer tone + denser scramble (1.5s)
    midi = MIDIFile(3, deinterleave=False)
    midi.addTempo(0, 0, 480)
    midi.addProgramChange(0, 0, 0, 80)
    midi.addProgramChange(1, 1, 0, 87)
    midi.addProgramChange(2, 2, 0, 81)
    for i in range(2):
        midi.addNote(0, 0, 72, i * 0.12, 0.06, 90)
        midi.addNote(0, 0, 84, i * 0.12 + 0.05, 0.06, 90)
    t = 0.3
    for _ in range(25):
        midi.addNote(1, 1, random.randint(60, 108), t, 0.02, random.randint(50, 90))
        midi.addNote(2, 2, random.randint(48, 84), t, 0.03, random.randint(40, 70))
        t += random.uniform(0.015, 0.035)
    midi.addNote(0, 0, 84, t, 0.12, 45)
    with open(os.path.join(modem_dir, "dialup-02-medium.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] dialup-02-medium.mid")

    # Modem 3: Heavy — full chaos scramble (2s)
    midi = MIDIFile(4)
    midi.addTempo(0, 0, 600)
    midi.addProgramChange(0, 0, 0, 80)
    midi.addProgramChange(1, 1, 0, 87)
    midi.addProgramChange(2, 2, 0, 81)
    midi.addProgramChange(3, 3, 0, 78)
    t = 0.0
    end = 2.0
    while t < end:
        midi.addNote(0, 0, random.randint(60, 108), t, 0.02, random.randint(60, 100))
        midi.addNote(1, 1, random.randint(48, 96), t + 0.005, 0.03, random.randint(50, 90))
        if random.random() > 0.5:
            midi.addNote(2, 2, random.randint(36, 72), t, 0.04, random.randint(40, 80))
        if random.random() > 0.7:
            midi.addNote(3, 3, random.randint(90, 120), t, 0.015, random.randint(30, 70))
        t += random.uniform(0.01, 0.03)
    midi.addNote(0, 0, 84, t, 0.1, 40)
    with open(os.path.join(modem_dir, "dialup-03-heavy.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] dialup-03-heavy.mid")

    # Modem 4: Burst — short staccato data burst (1s)
    midi = MIDIFile(2, deinterleave=False)
    midi.addTempo(0, 0, 600)
    midi.addProgramChange(0, 0, 0, 80)
    midi.addProgramChange(1, 1, 0, 81)
    t = 0.0
    for _ in range(30):
        n = random.choice([72, 84, 96, 60, 90, 78, 66])
        midi.addNote(0, 0, n, t, 0.015, random.randint(70, 110))
        midi.addNote(1, 1, n - 12, t, 0.02, random.randint(50, 80))
        t += random.uniform(0.01, 0.025)
    with open(os.path.join(modem_dir, "dialup-04-chaos.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] dialup-04-chaos.mid")

    # Modem 5: Ping — two quick tones + minimal scramble (1s)
    midi = MIDIFile(2, deinterleave=False)
    midi.addTempo(0, 0, 480)
    midi.addProgramChange(0, 0, 0, 80)
    midi.addProgramChange(1, 1, 0, 87)
    midi.addNote(0, 0, 84, 0.0, 0.08, 80)
    midi.addNote(0, 0, 96, 0.06, 0.08, 80)
    t = 0.15
    for _ in range(10):
        midi.addNote(1, 1, random.randint(72, 96), t, 0.02, random.randint(40, 70))
        t += random.uniform(0.02, 0.05)
    midi.addNote(0, 0, 84, t, 0.08, 35)
    with open(os.path.join(modem_dir, "dialup-05-ping.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] dialup-05-ping.mid")

    random.seed()  # Reset


def generate_glitch_sounds():
    """Short notification glitch sounds — 5 variations.
    Video game style: coin pickup, power-up, blip, chirp, warp.
    """
    glitch_dir = os.path.join(SOUNDS_DIR, "glitches")
    _ensure_dir(glitch_dir)

    # Glitch 1: Coin pickup (Mario-ish two-note)
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 200)
    midi.addProgramChange(0, 0, 0, 80)
    midi.addNote(0, 0, 83, 0.0, 0.15, 100)  # B5
    midi.addNote(0, 0, 88, 0.12, 0.3, 100)  # E6
    with open(os.path.join(glitch_dir, "glitch-01-coin.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] glitch-01-coin.mid")

    # Glitch 2: Power-up ascending sweep
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 300)
    midi.addProgramChange(0, 0, 0, 81)
    notes = [60, 64, 67, 72, 76, 79, 84]
    for i, n in enumerate(notes):
        midi.addNote(0, 0, n, i * 0.06, 0.1, 100 - i * 5)
    with open(os.path.join(glitch_dir, "glitch-02-powerup.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] glitch-02-powerup.mid")

    # Glitch 3: Blip — single short high note
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 200)
    midi.addProgramChange(0, 0, 0, 80)
    midi.addNote(0, 0, 96, 0.0, 0.08, 110)  # C7
    midi.addNote(0, 0, 84, 0.08, 0.15, 80)  # C6
    with open(os.path.join(glitch_dir, "glitch-03-blip.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] glitch-03-blip.mid")

    # Glitch 4: Chirp — quick warble
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 240)
    midi.addProgramChange(0, 0, 0, 80)
    chirp = [90, 85, 92, 87, 95]
    for i, n in enumerate(chirp):
        midi.addNote(0, 0, n, i * 0.05, 0.06, 100)
    with open(os.path.join(glitch_dir, "glitch-04-chirp.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] glitch-04-chirp.mid")

    # Glitch 5: Warp — descending with pitch bend feel
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 200)
    midi.addProgramChange(0, 0, 0, 87)  # Lead 8 (calliope)
    warp = [96, 93, 89, 84, 79, 72, 65, 60]
    for i, n in enumerate(warp):
        midi.addNote(0, 0, n, i * 0.04, 0.08, 110 - i * 8)
    with open(os.path.join(glitch_dir, "glitch-05-warp.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] glitch-05-warp.mid")


def generate_error_sounds():
    """3 short glitchy error sounds — random pick on playback."""
    error_dir = os.path.join(SOUNDS_DIR, "error")
    _ensure_dir(error_dir)

    # Error 1: Tritone stab — two dissonant hits + low buzz
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 200)
    midi.addProgramChange(0, 0, 0, 87)   # Calliope — buzzy
    midi.addNote(0, 0, 72, 0.0, 0.1, 120)
    midi.addNote(0, 0, 78, 0.0, 0.1, 110)   # Tritone
    midi.addNote(0, 0, 66, 0.12, 0.1, 120)
    midi.addNote(0, 0, 72, 0.12, 0.1, 110)  # Tritone
    midi.addNote(0, 0, 36, 0.25, 0.3, 127)  # Low buzz
    midi.addNote(0, 0, 37, 0.25, 0.3, 100)
    with open(os.path.join(error_dir, "error-01-tritone.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] error-01-tritone.mid")

    # Error 2: Descending stabs — 4 harsh notes falling
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 240)
    midi.addProgramChange(0, 0, 0, 80)   # Square
    for i, n in enumerate([84, 78, 72, 60]):
        midi.addNote(0, 0, n, i * 0.08, 0.06, 127)
        midi.addNote(0, 0, n + 6, i * 0.08, 0.06, 100)  # Tritone layer
    # Final cluster
    for n in [36, 42, 48]:
        midi.addNote(0, 0, n, 0.35, 0.2, 120)
    with open(os.path.join(error_dir, "error-02-descend.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] error-02-descend.mid")

    # Error 3: Glitch stutter — rapid repeated note + death
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 300)
    midi.addProgramChange(0, 0, 0, 115)  # Steel drums (wrong = glitchy)
    t = 0.0
    for _ in range(6):
        midi.addNote(0, 0, 72, t, 0.03, 120)
        t += 0.04
    # Death note
    midi.addNote(0, 0, 36, t, 0.25, 127)
    midi.addNote(0, 0, 37, t, 0.25, 110)
    midi.addNote(0, 0, 42, t, 0.25, 90)
    with open(os.path.join(error_dir, "error-03-stutter.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] error-03-stutter.mid")

    # Error 4: Alarm — rapid alternating high notes
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 240)
    midi.addProgramChange(0, 0, 0, 80)   # Square
    t = 0.0
    for _ in range(8):
        midi.addNote(0, 0, 96, t, 0.04, 120)
        midi.addNote(0, 0, 84, t + 0.05, 0.04, 110)
        t += 0.1
    # Crash chord
    for n in [36, 39, 42, 48]:
        midi.addNote(0, 0, n, t, 0.3, 127)
    with open(os.path.join(error_dir, "error-04-alarm.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] error-04-alarm.mid")

    # Error 5: Glitch crash — ascending then sudden drop
    midi = MIDIFile(1, deinterleave=False)
    midi.addTempo(0, 0, 300)
    midi.addProgramChange(0, 0, 0, 81)   # Saw
    t = 0.0
    for n in [48, 55, 62, 69, 76, 83, 90, 97]:
        midi.addNote(0, 0, n, t, 0.03, 100 + min(27, n - 48))
        t += 0.03
    # Sudden drop — low cluster
    midi.addNote(0, 0, 24, t, 0.4, 127)
    midi.addNote(0, 0, 25, t, 0.4, 120)
    midi.addNote(0, 0, 30, t, 0.3, 100)
    with open(os.path.join(error_dir, "error-05-crash.mid"), "wb") as f:
        midi.writeFile(f)
    print(f"  [+] error-05-crash.mid")


def main():
    print("\n  cl4ud3-cr4ck MIDI g3n3r4t0r")
    print("  ===========================\n")

    print("  [*] Generating warez intro loops (default)...")
    generate_warez_keygen()
    generate_warez_cracktro()
    generate_warez_scene()
    generate_warez_nfo()
    generate_warez_glitchload()

    print("  [*] Generating classic startup jingles...")
    generate_startup_jingle()
    generate_startup_jingle_2()
    generate_startup_jingle_3()
    generate_dnb_jungle_1()
    generate_dnb_jungle_2()
    generate_belgian_techno()
    generate_gabber_2()
    generate_gabber_hardstyle()
    generate_detroit_techno()
    generate_demoscene_1()
    generate_demoscene_2()

    print("  [*] Generating glitch notifications...")
    generate_glitch_sounds()

    print("  [*] Generating error sounds...")
    generate_error_sounds()

    print("  [*] Generating modem sounds (1-2s)...")
    generate_modem_sounds()

    print("\n  [!] All MIDI files generated. H4pPy h4ck1nG.\n")


if __name__ == "__main__":
    main()
