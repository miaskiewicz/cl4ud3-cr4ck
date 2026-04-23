#!/usr/bin/env python3
"""
cl4ud3-cr4ck RAW WAV Generator
Generates ugly, raw, no-processing waveform sound effects.
Pure square/saw/triangle waves. No SoundFont. No reverb. No bullshit.
Uses only Python stdlib (wave + struct).
"""

import math
import os
import random
import struct
import wave

SOUNDS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "sounds")
SAMPLE_RATE = 22050  # Low sample rate = extra crunchy
BIT_DEPTH = 8  # 8-bit = maximum garbage


def _ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def _square(phase):
    """Raw square wave. No anti-aliasing. Pure digital."""
    return 1.0 if phase % (2 * math.pi) < math.pi else -1.0


def _saw(phase):
    """Raw sawtooth. Harsh harmonics."""
    return (phase % (2 * math.pi)) / math.pi - 1.0


def _triangle(phase):
    """Triangle wave. Slightly less harsh."""
    p = (phase % (2 * math.pi)) / (2 * math.pi)
    return 4 * abs(p - 0.5) - 1.0


def _noise():
    """White noise sample."""
    return random.uniform(-1.0, 1.0)


def _freq_to_phase_inc(freq):
    """Frequency to phase increment per sample."""
    return 2 * math.pi * freq / SAMPLE_RATE


def _write_wav(filepath, samples):
    """Write 8-bit mono WAV from float samples (-1.0 to 1.0)."""
    _ensure_dir(os.path.dirname(filepath))
    with wave.open(filepath, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(1)  # 8-bit
        w.setframerate(SAMPLE_RATE)

        data = bytearray()
        for s in samples:
            # Clip and convert to unsigned 8-bit (0-255, center at 128)
            s = max(-1.0, min(1.0, s))
            data.append(int((s + 1.0) * 127.5))

        w.writeframes(bytes(data))
    print(f"  [+] {filepath}")


def _generate_tone(freq, duration, waveform=_square, volume=0.35):
    """Generate a raw tone at given frequency and duration."""
    samples = []
    phase = 0.0
    phase_inc = _freq_to_phase_inc(freq)
    num_samples = int(SAMPLE_RATE * duration)

    for _ in range(num_samples):
        samples.append(waveform(phase) * volume)
        phase += phase_inc

    return samples


def _modem_scramble(duration, freq_range, change_speed, num_voices, noise_amt,
                     stutter_chance, waveforms=None):
    """Core modem scramble generator. Params control glitchiness."""
    if waveforms is None:
        waveforms = [_square]
    samples = []
    num_samples = int(SAMPLE_RATE * duration)

    # Init voices
    voices = []
    for v in range(num_voices):
        voices.append({
            "phase": 0.0,
            "freq": random.randint(*freq_range),
            "next_change": 0,
            "speed": (change_speed[0] + v * 5, change_speed[1] + v * 10),
            "wave": waveforms[v % len(waveforms)],
            "vol": 0.075 / num_voices,
        })

    for i in range(num_samples):
        s = 0.0
        for v in voices:
            if i >= v["next_change"]:
                v["freq"] = random.randint(*freq_range)
                v["next_change"] = i + random.randint(*v["speed"])
            v["phase"] += _freq_to_phase_inc(v["freq"])
            s += v["wave"](v["phase"]) * v["vol"]

        s += _noise() * noise_amt

        # Random stutters
        if random.random() < stutter_chance:
            gap = random.randint(5, 40)
            for _ in range(min(gap, num_samples - i)):
                samples.append(_noise() * 0.02)
            continue

        samples.append(s)

    return samples


def generate_modem_sounds():
    """5 modem variations — different durations and glitchiness levels."""
    modem_dir = os.path.join(SOUNDS_DIR, "modem")
    _ensure_dir(modem_dir)

    configs = [
        # 1: Light — ~0.75s, clean single voice
        {
            "name": "dialup-01-light.wav",
            "dial_dur": 0.03,
            "scramble_dur": 0.45,
            "freq_range": (400, 3000),
            "change_speed": (15, 60),
            "num_voices": 1,
            "noise_amt": 0.03,
            "stutter_chance": 0.003,
            "waveforms": [_square],
        },
        # 2: Medium — ~0.9s, 2 voices
        {
            "name": "dialup-02-medium.wav",
            "dial_dur": 0.03,
            "scramble_dur": 0.6,
            "freq_range": (300, 4000),
            "change_speed": (8, 35),
            "num_voices": 2,
            "noise_amt": 0.06,
            "stutter_chance": 0.005,
            "waveforms": [_square, _saw],
        },
        # 3: Heavy — ~1.1s, 3 voices, glitchy
        {
            "name": "dialup-03-heavy.wav",
            "dial_dur": 0.03,
            "scramble_dur": 0.8,
            "freq_range": (200, 5000),
            "change_speed": (4, 20),
            "num_voices": 3,
            "noise_amt": 0.1,
            "stutter_chance": 0.008,
            "waveforms": [_square, _square, _saw],
        },
        # 4: Chaos — ~1.3s, 4 voices, maximum glitch
        {
            "name": "dialup-04-chaos.wav",
            "dial_dur": 0.03,
            "scramble_dur": 1.0,
            "freq_range": (100, 6000),
            "change_speed": (3, 12),
            "num_voices": 4,
            "noise_amt": 0.12,
            "stutter_chance": 0.012,
            "waveforms": [_square, _saw, _square, _triangle],
        },
        # 5: Quick ping — ~0.75s, minimal
        {
            "name": "dialup-05-ping.wav",
            "dial_dur": 0.03,
            "scramble_dur": 0.45,
            "freq_range": (600, 3500),
            "change_speed": (10, 50),
            "num_voices": 1,
            "noise_amt": 0.03,
            "stutter_chance": 0.003,
            "waveforms": [_square],
        },
        # 6: Blip — ~0.8s, triangle, soft glitch
        {
            "name": "dialup-06-blip.wav",
            "dial_dur": 0.03,
            "scramble_dur": 0.5,
            "freq_range": (500, 2800),
            "change_speed": (8, 35),
            "num_voices": 1,
            "noise_amt": 0.04,
            "stutter_chance": 0.004,
            "waveforms": [_triangle],
        },
        # 7: Saw burst — ~0.9s, dirty saw wave
        {
            "name": "dialup-07-saw.wav",
            "dial_dur": 0.03,
            "scramble_dur": 0.6,
            "freq_range": (800, 4500),
            "change_speed": (4, 20),
            "num_voices": 2,
            "noise_amt": 0.08,
            "stutter_chance": 0.006,
            "waveforms": [_saw, _square],
        },
        # 8: Stutter — ~1.0s, lots of gaps
        {
            "name": "dialup-08-stutter.wav",
            "dial_dur": 0.03,
            "scramble_dur": 0.65,
            "freq_range": (300, 5000),
            "change_speed": (5, 25),
            "num_voices": 2,
            "noise_amt": 0.06,
            "stutter_chance": 0.015,
            "waveforms": [_square, _saw],
        },
    ]

    for cfg in configs:
        samples = []

        # Dial tone blip
        samples.extend(_generate_tone(1000, cfg["dial_dur"], _square, 0.5))
        samples.extend([0.0] * int(SAMPLE_RATE * 0.03))

        # Rising chirp
        phase = 0.0
        chirp_dur = min(0.08, cfg["dial_dur"])
        for i in range(int(SAMPLE_RATE * chirp_dur)):
            freq = 600 + (i / (SAMPLE_RATE * chirp_dur)) * 2000
            phase += _freq_to_phase_inc(freq)
            samples.append(_square(phase) * 0.3)
        samples.extend([0.0] * int(SAMPLE_RATE * 0.02))

        # Scramble — the meat
        samples.extend(_modem_scramble(
            cfg["scramble_dur"], cfg["freq_range"], cfg["change_speed"],
            cfg["num_voices"], cfg["noise_amt"], cfg["stutter_chance"],
            cfg["waveforms"],
        ))

        # Lock blip
        samples.extend(_generate_tone(2100, 0.08, _square, 0.25))

        # Fade out
        fade_len = min(300, len(samples))
        for i in range(fade_len):
            samples[-(i + 1)] *= i / fade_len

        _write_wav(os.path.join(modem_dir, cfg["name"]), samples)


def generate_error_wav():
    """Error sound — short glitch stab. <0.5s. Harsh freq jump."""
    samples = []

    # Rapid descending glitch — 3 quick freq jumps
    freqs = [1800, 600, 200]
    for f in freqs:
        phase = 0.0
        for _ in range(int(SAMPLE_RATE * 0.06)):
            phase += _freq_to_phase_inc(f)
            samples.append(_square(phase) * 0.3)

    # Tiny noise burst at end
    for _ in range(int(SAMPLE_RATE * 0.04)):
        samples.append(_noise() * 0.15)

    # Hard fade
    for i in range(100):
        samples[-(i + 1)] *= i / 100

    out = os.path.join(SOUNDS_DIR, "error", "error-ohshit.wav")
    _write_wav(out, samples)


def generate_error_critical_wav():
    """Win 3.1 critical error — three descending harsh tones."""
    samples = []

    freqs = [523, 370, 262]
    for f in freqs:
        samples.extend(_generate_tone(f, 0.15, _square, 0.6))
        samples.extend([0.0] * int(SAMPLE_RATE * 0.05))

    # Dissonant cluster at end
    phase_a, phase_b = 0.0, 0.0
    for _ in range(int(SAMPLE_RATE * 0.3)):
        phase_a += _freq_to_phase_inc(262)
        phase_b += _freq_to_phase_inc(277)  # Half step = nasty
        samples.append(_square(phase_a) * 0.2 + _square(phase_b) * 0.15)

    for i in range(300):
        samples[-(i + 1)] *= i / 300

    out = os.path.join(SOUNDS_DIR, "error", "error-critical.wav")
    _write_wav(out, samples)


def generate_glitch_wavs():
    """Video game glitch sounds — raw square wave."""
    glitch_dir = os.path.join(SOUNDS_DIR, "glitches")

    # Coin pickup — two notes
    samples = _generate_tone(988, 0.06, _square, 0.5)
    samples.extend(_generate_tone(1319, 0.12, _square, 0.5))
    _write_wav(os.path.join(glitch_dir, "glitch-01-coin.wav"), samples)

    # Power-up ascending sweep
    samples = []
    phase = 0.0
    for i in range(int(SAMPLE_RATE * 0.3)):
        freq = 400 + (i / (SAMPLE_RATE * 0.3)) * 1600
        phase += _freq_to_phase_inc(freq)
        vol = 0.25 * (1.0 - i / (SAMPLE_RATE * 0.3) * 0.3)
        samples.append(_square(phase) * vol)
    _write_wav(os.path.join(glitch_dir, "glitch-02-powerup.wav"), samples)

    # Blip — short high
    samples = _generate_tone(2093, 0.03, _square, 0.5)
    samples.extend(_generate_tone(1047, 0.06, _square, 0.4))
    _write_wav(os.path.join(glitch_dir, "glitch-03-blip.wav"), samples)

    # Chirp — rapid warble
    samples = []
    phase = 0.0
    for i in range(int(SAMPLE_RATE * 0.1)):
        freq = 1500 + math.sin(i * 0.05) * 800
        phase += _freq_to_phase_inc(freq)
        samples.append(_square(phase) * 0.22)
    _write_wav(os.path.join(glitch_dir, "glitch-04-chirp.wav"), samples)

    # Warp — descending sweep
    samples = []
    phase = 0.0
    for i in range(int(SAMPLE_RATE * 0.15)):
        freq = 3000 - (i / (SAMPLE_RATE * 0.15)) * 2500
        phase += _freq_to_phase_inc(freq)
        vol = 0.25 * (1.0 - i / (SAMPLE_RATE * 0.15) * 0.5)
        samples.append(_saw(phase) * vol)
    _write_wav(os.path.join(glitch_dir, "glitch-05-warp.wav"), samples)


def main():
    print("\n  cl4ud3-cr4ck RAW WAV g3n3r4t0r")
    print("  ================================\n")
    print("  8-bit · 22050Hz · pure garbage\n")

    print("  [*] Generating modem sounds (5 variations)...")
    generate_modem_sounds()

    print("  [*] Generating error sounds...")
    generate_error_wav()
    generate_error_critical_wav()

    print("  [*] Generating glitch notifications...")
    generate_glitch_wavs()

    print("\n  [!] All WAV files generated. R4w 4nd unf1lt3r3d.\n")


if __name__ == "__main__":
    main()
