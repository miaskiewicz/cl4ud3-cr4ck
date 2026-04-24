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
        # 1: Light — clean single voice, high chirp intro
        {
            "name": "dialup-01-light.wav",
            "scramble_dur": 0.45,
            "freq_range": (400, 3000),
            "change_speed": (15, 60),
            "num_voices": 1,
            "noise_amt": 0.03,
            "stutter_chance": 0.003,
            "waveforms": [_square],
            "intro": "chirp_up",
            "outro": "lock",
            "dial_freq": 1000,
            "dial_dur": 0.03,
        },
        # 2: Medium — 2 voices, descending screech intro, noise burst outro
        {
            "name": "dialup-02-medium.wav",
            "scramble_dur": 0.6,
            "freq_range": (300, 4000),
            "change_speed": (8, 35),
            "num_voices": 2,
            "noise_amt": 0.06,
            "stutter_chance": 0.005,
            "waveforms": [_square, _saw],
            "intro": "screech_down",
            "outro": "noise_burst",
            "dial_freq": 1400,
            "dial_dur": 0.06,
        },
        # 3: Heavy — 3 voices, dual-tone intro, long lock
        {
            "name": "dialup-03-heavy.wav",
            "scramble_dur": 0.8,
            "freq_range": (200, 5000),
            "change_speed": (4, 20),
            "num_voices": 3,
            "noise_amt": 0.1,
            "stutter_chance": 0.008,
            "waveforms": [_square, _square, _saw],
            "intro": "dual_tone",
            "outro": "long_lock",
            "dial_freq": 800,
            "dial_dur": 0.08,
        },
        # 4: Chaos — 4 voices, no intro, stutter outro
        {
            "name": "dialup-04-chaos.wav",
            "scramble_dur": 1.0,
            "freq_range": (100, 6000),
            "change_speed": (3, 12),
            "num_voices": 4,
            "noise_amt": 0.12,
            "stutter_chance": 0.012,
            "waveforms": [_square, _saw, _square, _triangle],
            "intro": "none",
            "outro": "stutter_stop",
            "dial_freq": 0,
            "dial_dur": 0,
        },
        # 5: Quick ping — fast warble intro, clean lock
        {
            "name": "dialup-05-ping.wav",
            "scramble_dur": 0.45,
            "freq_range": (600, 3500),
            "change_speed": (10, 50),
            "num_voices": 1,
            "noise_amt": 0.03,
            "stutter_chance": 0.003,
            "waveforms": [_square],
            "intro": "warble",
            "outro": "lock",
            "dial_freq": 2400,
            "dial_dur": 0.02,
        },
        # 6: Blip — triangle wave, fade-in intro, fade outro
        {
            "name": "dialup-06-blip.wav",
            "scramble_dur": 0.5,
            "freq_range": (500, 2800),
            "change_speed": (8, 35),
            "num_voices": 1,
            "noise_amt": 0.04,
            "stutter_chance": 0.004,
            "waveforms": [_triangle],
            "intro": "fade_in",
            "outro": "fade",
            "dial_freq": 0,
            "dial_dur": 0,
        },
        # 7: Saw burst — dirty, screech up intro, noise burst outro
        {
            "name": "dialup-07-saw.wav",
            "scramble_dur": 0.6,
            "freq_range": (800, 4500),
            "change_speed": (4, 20),
            "num_voices": 2,
            "noise_amt": 0.08,
            "stutter_chance": 0.006,
            "waveforms": [_saw, _square],
            "intro": "chirp_up",
            "outro": "stutter_stop",
            "dial_freq": 1800,
            "dial_dur": 0.04,
        },
        # 8: Stutter — lots of gaps, dual tone intro, long lock
        {
            "name": "dialup-08-stutter.wav",
            "scramble_dur": 0.65,
            "freq_range": (300, 5000),
            "change_speed": (5, 25),
            "num_voices": 2,
            "noise_amt": 0.06,
            "stutter_chance": 0.015,
            "waveforms": [_square, _saw],
            "intro": "screech_down",
            "outro": "long_lock",
            "dial_freq": 600,
            "dial_dur": 0.05,
        },
        # 9: Corrupt — bit-crushed feel, sample drops, heavy noise
        {
            "name": "dialup-09-corrupt.wav",
            "scramble_dur": 0.7,
            "freq_range": (150, 5500),
            "change_speed": (2, 10),
            "num_voices": 3,
            "noise_amt": 0.14,
            "stutter_chance": 0.02,
            "waveforms": [_square, _square, _square],
            "intro": "dual_tone",
            "outro": "noise_burst",
            "dial_freq": 950,
            "dial_dur": 0.07,
        },
        # 10: Surge — power surge, extreme freq range, saw+triangle
        {
            "name": "dialup-10-surge.wav",
            "scramble_dur": 0.55,
            "freq_range": (80, 7000),
            "change_speed": (2, 8),
            "num_voices": 2,
            "noise_amt": 0.1,
            "stutter_chance": 0.007,
            "waveforms": [_saw, _triangle],
            "intro": "chirp_up",
            "outro": "stutter_stop",
            "dial_freq": 2200,
            "dial_dur": 0.04,
        },
        # 11: Fracture — broken connection, extreme stutter, big gaps
        {
            "name": "dialup-11-fracture.wav",
            "scramble_dur": 0.85,
            "freq_range": (250, 4500),
            "change_speed": (3, 15),
            "num_voices": 2,
            "noise_amt": 0.08,
            "stutter_chance": 0.025,
            "waveforms": [_square, _saw],
            "intro": "warble",
            "outro": "long_lock",
            "dial_freq": 1600,
            "dial_dur": 0.03,
        },
        # 12: Overdrive — clipping, 4 voices, narrow band, loud
        {
            "name": "dialup-12-overdrive.wav",
            "scramble_dur": 0.75,
            "freq_range": (800, 2200),
            "change_speed": (6, 18),
            "num_voices": 4,
            "noise_amt": 0.15,
            "stutter_chance": 0.01,
            "waveforms": [_saw, _saw, _square, _triangle],
            "intro": "screech_down",
            "outro": "stutter_stop",
            "dial_freq": 1200,
            "dial_dur": 0.05,
        },
        # 13: Glitch — maximum chaos, 3 voices, wild freq, high stutter
        {
            "name": "dialup-13-glitch.wav",
            "scramble_dur": 0.9,
            "freq_range": (100, 8000),
            "change_speed": (1, 6),
            "num_voices": 3,
            "noise_amt": 0.16,
            "stutter_chance": 0.018,
            "waveforms": [_square, _triangle, _saw],
            "intro": "none",
            "outro": "noise_burst",
            "dial_freq": 0,
            "dial_dur": 0,
        },
    ]

    for cfg in configs:
        samples = []
        intro = cfg.get("intro", "chirp_up")
        outro = cfg.get("outro", "lock")

        # Per-run jitter so no two runs produce identical output
        freq_jitter = random.uniform(-80, 80)
        dur_jitter = random.uniform(-0.008, 0.008)
        vol_jitter = random.uniform(-0.04, 0.04)

        def _jf(f):
            """Jitter a frequency."""
            return max(50, f + freq_jitter + random.uniform(-20, 20))

        def _jd(d):
            """Jitter a duration (keep positive)."""
            return max(0.005, d + dur_jitter + random.uniform(-0.003, 0.003))

        def _jv(v):
            """Jitter a volume (keep 0.05-0.7)."""
            return max(0.05, min(0.7, v + vol_jitter * random.uniform(0.3, 1.0)))

        # --- INTRO: each sound starts differently ---
        if intro == "chirp_up" and cfg["dial_dur"] > 0:
            # Dial tone + rising chirp
            samples.extend(_generate_tone(_jf(cfg["dial_freq"]), _jd(cfg["dial_dur"]), _square, _jv(0.5)))
            samples.extend([0.0] * int(SAMPLE_RATE * _jd(0.03)))
            phase = 0.0
            chirp_dur = _jd(0.08)
            chirp_base = _jf(600)
            chirp_range = 2000 + random.uniform(-200, 200)
            for i in range(int(SAMPLE_RATE * chirp_dur)):
                freq = chirp_base + (i / (SAMPLE_RATE * chirp_dur)) * chirp_range
                phase += _freq_to_phase_inc(freq)
                samples.append(_square(phase) * _jv(0.3))
            samples.extend([0.0] * int(SAMPLE_RATE * _jd(0.02)))
        elif intro == "screech_down":
            # High-to-low screech — sounds like modem answering
            samples.extend(_generate_tone(_jf(cfg["dial_freq"]), _jd(cfg["dial_dur"]), _saw, _jv(0.4)))
            phase = 0.0
            screech_dur = _jd(0.12)
            screech_hi = _jf(4000)
            screech_range = 3200 + random.uniform(-300, 300)
            for i in range(int(SAMPLE_RATE * screech_dur)):
                freq = screech_hi - (i / (SAMPLE_RATE * screech_dur)) * screech_range
                phase += _freq_to_phase_inc(freq)
                samples.append(_saw(phase) * _jv(0.35))
            samples.extend([0.0] * int(SAMPLE_RATE * _jd(0.03)))
        elif intro == "dual_tone":
            # Two simultaneous tones — DTMF-style
            phase_a, phase_b = 0.0, 0.0
            dt_freq_a = _jf(cfg["dial_freq"])
            dt_ratio = 1.5 + random.uniform(-0.08, 0.08)
            for i in range(int(SAMPLE_RATE * _jd(cfg["dial_dur"]))):
                phase_a += _freq_to_phase_inc(dt_freq_a)
                phase_b += _freq_to_phase_inc(dt_freq_a * dt_ratio)
                samples.append(_square(phase_a) * _jv(0.2) + _triangle(phase_b) * _jv(0.2))
            samples.extend([0.0] * int(SAMPLE_RATE * _jd(0.04)))
        elif intro == "warble":
            # Rapid frequency wobble
            phase = 0.0
            warble_rate = 0.08 + random.uniform(-0.02, 0.02)
            warble_depth = 600 + random.uniform(-100, 100)
            for i in range(int(SAMPLE_RATE * _jd(0.1))):
                freq = _jf(cfg["dial_freq"]) + math.sin(i * warble_rate) * warble_depth
                phase += _freq_to_phase_inc(freq)
                samples.append(_square(phase) * _jv(0.3))
            samples.extend([0.0] * int(SAMPLE_RATE * _jd(0.02)))
        elif intro == "fade_in":
            # No intro blip — scramble fades in from silence
            pass
        # intro == "none": jump straight to scramble

        # --- SCRAMBLE: the meat ---
        scramble = _modem_scramble(
            cfg["scramble_dur"], cfg["freq_range"], cfg["change_speed"],
            cfg["num_voices"], cfg["noise_amt"], cfg["stutter_chance"],
            cfg["waveforms"],
        )

        # Apply fade-in envelope if requested
        if intro == "fade_in":
            fade_in_len = min(int(SAMPLE_RATE * 0.15), len(scramble))
            for i in range(fade_in_len):
                scramble[i] *= i / fade_in_len

        samples.extend(scramble)

        # --- OUTRO: each sound ends differently ---
        if outro == "lock":
            # Standard lock blip
            samples.extend(_generate_tone(_jf(2100), _jd(0.08), _square, _jv(0.25)))
        elif outro == "long_lock":
            # Extended lock tone — sounds like connection established
            samples.extend(_generate_tone(_jf(1800), _jd(0.04), _square, _jv(0.2)))
            samples.extend([0.0] * int(SAMPLE_RATE * _jd(0.02)))
            samples.extend(_generate_tone(_jf(2100), _jd(0.12), _square, _jv(0.25)))
        elif outro == "noise_burst":
            # White noise burst — like static discharge
            burst_len = int(SAMPLE_RATE * _jd(0.06))
            burst_vol = _jv(0.2)
            for _ in range(burst_len):
                samples.append(_noise() * burst_vol)
        elif outro == "stutter_stop":
            # Rapid on-off stuttering to silence
            stutter_count = random.choice([4, 5, 6])
            stutter_freq = _jf(1500)
            for j in range(stutter_count):
                vol = _jv(0.25) * (1 - j / stutter_count)
                samples.extend(_generate_tone(stutter_freq, _jd(0.015), _square, vol))
                samples.extend([0.0] * int(SAMPLE_RATE * _jd(0.015)))
        # outro == "fade": just fade out (handled below)

        # Fade out (all sounds get this, but length varies)
        fade_len = min(600 if outro == "fade" else 300, len(samples))
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

    print("  [*] Generating modem sounds (13 variations)...")
    generate_modem_sounds()

    print("  [*] Generating error sounds...")
    generate_error_wav()
    generate_error_critical_wav()

    print("  [*] Generating glitch notifications...")
    generate_glitch_wavs()

    print("\n  [!] All WAV files generated. R4w 4nd unf1lt3r3d.\n")


if __name__ == "__main__":
    main()
