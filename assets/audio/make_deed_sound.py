"""Makes a deed's sound (game/ui/deed_badge.gd): three soft bell notes
rising over a warm low swell, with a breath of shimmer on top. Synthesised
here, numpy only, as 16-bit mono WAV at 44.1 kHz; CC0. Run from anywhere:

    python assets/audio/make_deed_sound.py
"""
import os
import wave

import numpy as np

RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
SECONDS = 2.6
# Its loudest 400 ms comes to about -28 LUFS at this peak (CREDITS.md).
PEAK_DB = -18.0
rng = np.random.default_rng(1018)


def t(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def bell(freq, start, decay, gain):
    """A soft bell: a near-sine with a quiet octave and two inharmonic partials."""
    out = np.zeros(int(SECONDS * RATE))
    n = len(out) - int(start * RATE)
    x = t(n / RATE)
    tone = (np.sin(2 * np.pi * freq * x)
            + 0.22 * np.sin(2 * np.pi * freq * 2.0 * x) * np.exp(-x / (decay * 0.5))
            + 0.08 * np.sin(2 * np.pi * freq * 2.76 * x) * np.exp(-x / (decay * 0.25))
            + 0.03 * np.sin(2 * np.pi * freq * 5.4 * x) * np.exp(-x / (decay * 0.12)))
    attack = np.minimum(x / 0.006, 1.0)
    out[-n:] = tone * attack * np.exp(-x / decay) * gain
    return out


def swell(freq, gain):
    """A low warm hum that comes up under the notes and dies away."""
    x = t(SECONDS)
    shape = np.minimum(x / 0.25, 1.0) * np.exp(-np.maximum(x - 0.25, 0.0) / 0.7)
    return (np.sin(2 * np.pi * freq * x) + 0.3 * np.sin(2 * np.pi * freq * 1.5 * x)) * shape * gain


def shimmer(gain):
    """A breath of high air after the last note."""
    n = int(SECONDS * RATE)
    spectrum = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1.0 / RATE)
    spectrum *= np.exp(-((f - 7000.0) / 2500.0) ** 2)
    air = np.fft.irfft(spectrum, n)
    x = t(SECONDS)
    shape = np.clip((x - 0.22) / 0.15, 0.0, 1.0) * np.exp(-np.maximum(x - 0.37, 0.0) / 0.5)
    return air / np.max(np.abs(air)) * shape * gain


# A4, E5 and A5, a fifth then the octave, rising; the last rings longest.
signal = (bell(440.0, 0.0, 0.9, 0.55) + bell(659.25, 0.11, 1.0, 0.5) + bell(880.0, 0.22, 1.4, 0.6)
          + swell(220.0, 0.18) + shimmer(0.05))
fade = int(0.05 * RATE)
signal[-fade:] *= np.linspace(1.0, 0.0, fade)
signal = signal / np.max(np.abs(signal)) * 10 ** (PEAK_DB / 20.0)
data = (np.clip(signal, -1.0, 1.0) * 32767).astype(np.int16)
with wave.open(os.path.join(HERE, "deed.wav"), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes(data.tobytes())
