"""Makes the living city's chatter (game/radio/city.gd): five motifs of
reed tones, no voices. Each tone is a soft reed: odd harmonics falling away
over the fundamental, a breath of air on its attack and a slow vibrato.
Synthesised here, numpy only, as 16-bit mono WAV at 22.05 kHz; CC0. Run
from anywhere:

    python assets/audio/make_city_motifs.py
"""
import os
import wave

import numpy as np

RATE = 22050
HERE = os.path.dirname(os.path.abspath(__file__))
# About as loud as the weather station's tones, -36 LUFS (CREDITS.md).
PEAK_DB = -31.0
GAP = 0.07
rng = np.random.default_rng(1019)

A4, C5, D5, E5, G5, A5 = 440.0, 523.25, 587.33, 659.25, 783.99, 880.0
# Each motif as [pitch, seconds], its contour the line's in view (LivingCity.SHAPES).
MOTIFS = {
    "storm": [[G5, 0.28], [E5, 0.28], [A4, 0.55]],
    "tether": [[A4, 0.2], [A4, 0.2], [D5, 0.3], [D5, 0.3]],
    "moving": [[A4, 0.3], [D5, 0.3], [G5, 0.45]],
    "clear": [[E5, 0.25], [A5, 0.3], [A5, 0.3], [E5, 0.4]],
    "position": [[A4, 0.18], [D5, 0.18], [G5, 0.18], [D5, 0.18], [A4, 0.18], [A5, 0.22], [E5, 0.18], [A5, 0.4]],
}


def reed(freq, seconds):
    """A reed tone: odd harmonics, a breathy attack, a slow vibrato."""
    x = np.arange(int(seconds * RATE)) / RATE
    wobble = 1.0 + 0.004 * np.sin(2 * np.pi * 5.2 * x)
    phase = 2 * np.pi * freq * np.cumsum(wobble) / RATE
    tone = np.zeros_like(x)
    for k, gain in zip([1, 3, 5, 7, 9], [1.0, 0.42, 0.22, 0.12, 0.06]):
        if freq * k < RATE * 0.45:
            tone += gain * np.sin(k * phase)
    breath = rng.standard_normal(len(x))
    spectrum = np.fft.rfft(breath)
    f = np.fft.rfftfreq(len(x), 1.0 / RATE)
    spectrum *= np.exp(-((f - freq * 2.0) / 900.0) ** 2)
    air = np.fft.irfft(spectrum, len(x))
    air /= np.max(np.abs(air)) + 1e-9
    attack = np.minimum(x / 0.035, 1.0)
    release = np.minimum((seconds - x) / 0.07, 1.0)
    puff = np.exp(-x / 0.06)
    return (tone + 0.35 * air * (0.3 + puff)) * attack * release


def motif(notes):
    parts = []
    for freq, seconds in notes:
        parts.append(reed(freq, seconds))
        parts.append(np.zeros(int(GAP * RATE)))
    signal = np.concatenate(parts)
    return signal / np.max(np.abs(signal)) * 10 ** (PEAK_DB / 20.0)


for name, notes in MOTIFS.items():
    data = (np.clip(motif(notes), -1.0, 1.0) * 32767).astype(np.int16)
    with wave.open(os.path.join(HERE, "city_%s.wav" % name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
