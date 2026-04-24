#!/usr/bin/env python3
"""
cl4ud3-cr4ck ACID 303 Generator
Generative acid bassline + harmonically-matched stab WAVs.
Everything generated fresh at runtime. Pure stdlib.
"""

import argparse
import math
import os
import random
import struct
import sys
import wave

SAMPLE_RATE = 44100
BIT_DEPTH = 16
MAX_INT16 = 32767

# ── Scales/Keys ──────────────────────────────────────────────────────────────

# Each entry: (root_name, root_midi, scale_intervals)
SCALES = [
    ("Am", 57, [0, 3, 5, 7, 10]),       # A minor pentatonic
    ("Dm", 50, [0, 3, 5, 7, 10]),       # D minor pentatonic
    ("Gm", 55, [0, 3, 5, 7, 10]),       # G minor pentatonic
    ("Cm", 48, [0, 3, 5, 7, 10]),       # C minor pentatonic
    ("Em", 52, [0, 1, 3, 5, 7, 8, 10]), # E phrygian
]


def _midi_to_freq(midi_note):
    """MIDI note number to frequency."""
    return 440.0 * (2.0 ** ((midi_note - 69) / 12.0))


def _pick_key():
    """Pick random key/scale, return (name, root_freq, note_freqs)."""
    name, root_midi, intervals = random.choice(SCALES)
    # Build 2-octave note pool
    notes = []
    for octave_offset in [-12, 0, 12]:
        for iv in intervals:
            midi = root_midi + octave_offset + iv
            if 30 <= midi <= 80:
                notes.append(_midi_to_freq(midi))
    root_freq = _midi_to_freq(root_midi)
    return name, root_freq, sorted(set(notes))


# ── DSP primitives ───────────────────────────────────────────────────────────

def _saw(phase):
    """Raw sawtooth -1..1."""
    return 2.0 * ((phase / (2 * math.pi)) % 1.0) - 1.0


def _square(phase, pw=0.5):
    """Pulse wave with variable width."""
    return 1.0 if ((phase / (2 * math.pi)) % 1.0) < pw else -1.0


def _tanh_clip(x, drive=2.0):
    """Soft-clip distortion."""
    return math.tanh(x * drive)


class ResonantFilter:
    """2-pole state-variable filter (the acid sound)."""

    def __init__(self, cutoff=1000.0, resonance=0.7):
        self.cutoff = cutoff
        self.resonance = resonance
        self.low = 0.0
        self.band = 0.0

    def process(self, sample):
        f = 2.0 * math.sin(math.pi * min(self.cutoff, SAMPLE_RATE * 0.45) / SAMPLE_RATE)
        q = max(0.5, 1.0 - self.resonance)
        self.low += f * self.band
        high = sample - self.low - q * self.band
        self.band += f * high
        return self.low


class Delay:
    """Simple delay line."""

    def __init__(self, delay_ms=150.0, feedback=0.3, mix=0.25):
        self.delay_samples = int(SAMPLE_RATE * delay_ms / 1000.0)
        self.feedback = feedback
        self.mix = mix
        self.buffer = [0.0] * max(1, self.delay_samples)
        self.pos = 0

    def process(self, sample):
        delayed = self.buffer[self.pos]
        self.buffer[self.pos] = sample + delayed * self.feedback
        self.pos = (self.pos + 1) % len(self.buffer)
        return sample * (1.0 - self.mix) + delayed * self.mix


class CombReverb:
    """Simple comb filter reverb."""

    def __init__(self, decay=0.4, mix=0.15):
        self.mix = mix
        # Multiple comb filters at different delay lengths
        delays = [1117, 1277, 1493, 1637]
        self.buffers = [[0.0] * d for d in delays]
        self.positions = [0] * len(delays)
        self.decays = [decay * (0.9 + 0.1 * i / len(delays)) for i in range(len(delays))]

    def process(self, sample):
        out = 0.0
        for i, buf in enumerate(self.buffers):
            pos = self.positions[i]
            delayed = buf[pos]
            buf[pos] = sample + delayed * self.decays[i]
            self.positions[i] = (pos + 1) % len(buf)
            out += delayed
        out /= len(self.buffers)
        return sample * (1.0 - self.mix) + out * self.mix


# ── 303 Note Synthesis ───────────────────────────────────────────────────────

def _acid_note(freq, duration, accent=False, slide_from=None, bpm=140):
    """Generate one 303 note with filter envelope sweep."""
    num_samples = int(SAMPLE_RATE * duration)
    samples = []

    # Filter envelope params
    base_cutoff = 300.0
    peak_cutoff = 4000.0 if accent else 2500.0
    decay_rate = 8.0 if accent else 12.0
    resonance = 0.85 if accent else 0.7

    filt = ResonantFilter(base_cutoff, resonance)
    phase = 0.0
    current_freq = slide_from if slide_from else freq

    # Amp envelope: attack 2ms, sustain, release 15ms
    attack_samples = int(SAMPLE_RATE * 0.002)
    release_samples = int(SAMPLE_RATE * 0.015)

    for i in range(num_samples):
        t = i / SAMPLE_RATE

        # Slide toward target freq
        if slide_from and current_freq != freq:
            slide_speed = 0.002
            if current_freq < freq:
                current_freq = min(freq, current_freq + (freq - slide_from) * slide_speed)
            else:
                current_freq = max(freq, current_freq + (freq - slide_from) * slide_speed)

        phase += 2.0 * math.pi * current_freq / SAMPLE_RATE

        # Saw oscillator (classic 303)
        osc = _saw(phase)

        # Filter envelope: exponential decay from peak to base
        env = math.exp(-decay_rate * t)
        filt.cutoff = base_cutoff + (peak_cutoff - base_cutoff) * env

        filtered = filt.process(osc)

        # Amp envelope
        if i < attack_samples:
            amp = i / max(1, attack_samples)
        elif i > num_samples - release_samples:
            amp = (num_samples - i) / max(1, release_samples)
        else:
            amp = 1.0

        volume = 0.7 if accent else 0.5
        samples.append(filtered * amp * volume)

    return samples


# ── 303 Pattern Generation ───────────────────────────────────────────────────

def _generate_pattern(note_pool, steps=16):
    """Generate one 16-step 303-style pattern."""
    pattern = []
    for _ in range(steps):
        if random.random() < 0.15:
            # Rest
            pattern.append({"type": "rest"})
        else:
            note = random.choice(note_pool)
            # Occasional octave up
            if random.random() < 0.2:
                note *= 2
            pattern.append({
                "type": "note",
                "freq": note,
                "accent": random.random() < 0.3,
                "slide": random.random() < 0.2,
            })
    return pattern


def _generate_bassline(note_pool, bpm=140, target_duration=17):
    """Generate full 303 bassline as samples."""
    step_duration = 60.0 / bpm / 4  # 16th note duration

    # Generate 2-3 patterns, each repeated 2x
    num_patterns = random.choice([2, 3])
    patterns = [_generate_pattern(note_pool) for _ in range(num_patterns)]

    samples = []
    total_duration = 0

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

            prev_freq = None
            for step in varied:
                if total_duration >= target_duration:
                    break
                if step["type"] == "rest":
                    rest_samples = int(SAMPLE_RATE * step_duration)
                    samples.extend([0.0] * rest_samples)
                else:
                    slide_from = prev_freq if step["slide"] and prev_freq else None
                    note_samples = _acid_note(
                        step["freq"], step_duration,
                        accent=step["accent"],
                        slide_from=slide_from,
                        bpm=bpm
                    )
                    samples.extend(note_samples)
                    prev_freq = step["freq"]
                total_duration += step_duration

            if total_duration >= target_duration:
                break

    return samples


# ── Stab Generation ──────────────────────────────────────────────────────────

def _generate_stab_filter_sweep(note_pool, bpm=140):
    """Stab type 1: filter sweep chord."""
    duration = 60.0 / bpm  # 1 beat
    num_samples = int(SAMPLE_RATE * duration)

    # Pick 2-3 chord tones from pool
    chord_notes = random.sample(note_pool, min(3, len(note_pool)))
    chord_freqs = [n for n in chord_notes]

    filt = ResonantFilter(5000.0, 0.8)
    samples = []
    phases = [0.0] * len(chord_freqs)

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Sweep filter down
        filt.cutoff = 5000.0 * math.exp(-6.0 * t)

        mix = 0.0
        for j, freq in enumerate(chord_freqs):
            phases[j] += 2.0 * math.pi * freq / SAMPLE_RATE
            mix += _saw(phases[j])
        mix /= len(chord_freqs)

        filtered = filt.process(mix)

        # Amp envelope
        env = math.exp(-4.0 * t)
        samples.append(filtered * env * 0.5)

    return samples


def _generate_stab_tritone(note_pool, bpm=140):
    """Stab type 2: tritone interval hit."""
    duration = 60.0 / bpm * 0.5  # half beat
    num_samples = int(SAMPLE_RATE * duration)

    root = random.choice(note_pool)
    tritone = root * (2 ** (6 / 12))  # up a tritone

    filt = ResonantFilter(3000.0, 0.9)
    samples = []
    phase_a, phase_b = 0.0, 0.0

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        phase_a += 2.0 * math.pi * root / SAMPLE_RATE
        phase_b += 2.0 * math.pi * tritone / SAMPLE_RATE

        mix = (_square(phase_a, 0.3) + _square(phase_b, 0.7)) * 0.5
        filt.cutoff = 800.0 + 2200.0 * math.exp(-10.0 * t)
        filtered = filt.process(mix)

        env = math.exp(-6.0 * t)
        samples.append(filtered * env * 0.6)

    return samples


def _generate_stab_arp(note_pool, bpm=140):
    """Stab type 3: rapid arpeggio burst."""
    arp_notes = random.sample(note_pool, min(4, len(note_pool)))
    note_dur = 60.0 / bpm / 8  # 32nd notes
    samples = []

    filt = ResonantFilter(4000.0, 0.75)

    for idx, freq in enumerate(arp_notes):
        num_samples = int(SAMPLE_RATE * note_dur)
        phase = 0.0
        for i in range(num_samples):
            t = i / SAMPLE_RATE
            phase += 2.0 * math.pi * freq / SAMPLE_RATE
            osc = _saw(phase)
            filt.cutoff = 2000.0 + 2000.0 * math.exp(-15.0 * t)
            filtered = filt.process(osc)
            env = math.exp(-8.0 * t)
            samples.append(filtered * env * 0.5)

    return samples


def _generate_stab_chromatic(note_pool, bpm=140):
    """Stab type 4: chromatic run."""
    start = random.choice(note_pool)
    direction = random.choice([-1, 1])
    num_notes = random.randint(4, 6)
    note_dur = 60.0 / bpm / 8

    semitone = 2 ** (1 / 12)
    freqs = [start * (semitone ** (direction * i)) for i in range(num_notes)]

    filt = ResonantFilter(3500.0, 0.8)
    samples = []

    for freq in freqs:
        num_samples = int(SAMPLE_RATE * note_dur)
        phase = 0.0
        for i in range(num_samples):
            t = i / SAMPLE_RATE
            phase += 2.0 * math.pi * freq / SAMPLE_RATE
            osc = _square(phase, 0.4)
            filt.cutoff = 1500.0 + 2000.0 * math.exp(-12.0 * t)
            filtered = filt.process(osc)
            env = math.exp(-6.0 * t)
            samples.append(filtered * env * 0.45)

    return samples


STAB_GENERATORS = [
    _generate_stab_filter_sweep,
    _generate_stab_tritone,
    _generate_stab_arp,
    _generate_stab_chromatic,
]


# ── FX Chain ─────────────────────────────────────────────────────────────────

def _apply_distortion(samples, drive=2.0):
    """Apply tanh soft-clip distortion."""
    return [_tanh_clip(s, drive) for s in samples]


def _apply_delay(samples, delay_ms=150.0, feedback=0.3, mix=0.25):
    """Apply delay effect."""
    delay = Delay(delay_ms, feedback, mix)
    return [delay.process(s) for s in samples]


def _apply_reverb(samples, decay=0.4, mix=0.15):
    """Apply comb filter reverb."""
    reverb = CombReverb(decay, mix)
    return [reverb.process(s) for s in samples]


# ── WAV I/O ──────────────────────────────────────────────────────────────────

def _write_wav(filepath, samples):
    """Write 16-bit mono WAV."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)

        # Normalize
        peak = max(abs(s) for s in samples) if samples else 1.0
        if peak > 0:
            scale = 0.9 / peak
        else:
            scale = 1.0

        data = b""
        for s in samples:
            val = int(s * scale * MAX_INT16)
            val = max(-MAX_INT16, min(MAX_INT16, val))
            data += struct.pack("<h", val)

        w.writeframes(data)


# ── Main Generation ──────────────────────────────────────────────────────────

def generate(bpm, output_dir, target_duration=17):
    """Generate loop.wav + stab-{01..04}.wav in output_dir."""
    os.makedirs(output_dir, exist_ok=True)

    # Pick key — everything matches
    key_name, root_freq, note_pool = _pick_key()

    # Generate 303 bassline
    bassline = _generate_bassline(note_pool, bpm=bpm, target_duration=target_duration)

    # FX chain: distortion → delay
    bassline = _apply_distortion(bassline, drive=1.8)
    bassline = _apply_delay(bassline, delay_ms=int(60000 / bpm / 4 * 0.75), feedback=0.25, mix=0.2)

    # Fade in/out
    fade_len = min(int(SAMPLE_RATE * 0.05), len(bassline) // 4)
    for i in range(fade_len):
        bassline[i] *= i / fade_len
        bassline[-(i + 1)] *= i / fade_len

    _write_wav(os.path.join(output_dir, "loop.wav"), bassline)

    # Generate 4 matching stabs (same key!)
    for i, gen_func in enumerate(STAB_GENERATORS):
        stab = gen_func(note_pool, bpm=bpm)

        # FX: light delay + reverb
        stab = _apply_delay(stab, delay_ms=int(60000 / bpm / 4 * 0.5), feedback=0.2, mix=0.15)
        stab = _apply_reverb(stab, decay=0.3, mix=0.1)

        # Fade out
        stab_fade = min(int(SAMPLE_RATE * 0.02), len(stab) // 2)
        for j in range(stab_fade):
            stab[-(j + 1)] *= j / stab_fade

        _write_wav(os.path.join(output_dir, f"stab-{i+1:02d}.wav"), stab)

    return key_name


def main():
    parser = argparse.ArgumentParser(description="cl4ud3-cr4ck acid 303 generator")
    parser.add_argument("--bpm", type=int, default=140, help="BPM (default: 140)")
    parser.add_argument("--output-dir", required=True, help="Output directory for WAVs")
    parser.add_argument("--duration", type=int, default=17, help="Target loop duration in seconds")
    args = parser.parse_args()

    key = generate(args.bpm, args.output_dir, target_duration=args.duration)
    print(f"key={key} bpm={args.bpm} dir={args.output_dir}")


if __name__ == "__main__":
    main()
