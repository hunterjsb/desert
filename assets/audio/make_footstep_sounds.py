"""Makes the footsteps on what isn't sand (game/player/footing.gd): metal
plate underfoot (a deck, a wreck's hull), stone (rock, concrete, render,
clay) and wood (a rig's planks, a second-age floor). Each is a heel and then
a toe a moment later, with a little of the desert's grit ground under the
boot. Synthesised here, numpy only, as 16-bit mono WAV at 44.1 kHz; CC0.
Levelled like the sand's steps, by their loudest 400 ms unweighted, an
estimate short of LUFS. Run from anywhere:

    python assets/audio/make_footstep_sounds.py
"""
import os
import wave

import numpy as np

RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
rng = np.random.default_rng(1025)
LENGTH = 0.5
# Sand's steps are heard at -36 walking (CREDITS.md); these match them.
HEARD = -36.0


def band(signal, lo, hi):
    """Keeps lo..hi Hz, by FFT, with soft edges."""
    spectrum = np.fft.rfft(signal)
    f = np.fft.rfftfreq(len(signal), 1.0 / RATE)
    gain = ((f >= lo) & (f <= hi)).astype(float)
    gain = np.convolve(gain, np.ones(31) / 31.0, mode="same")
    return np.fft.irfft(spectrum * gain, len(signal))


def noise():
    return rng.standard_normal(int(LENGTH * RATE))


def t():
    return np.arange(int(LENGTH * RATE)) / RATE


def decay(seconds, attack=0.001):
    e = np.exp(-t() / seconds)
    a = max(1, int(attack * RATE))
    e[:a] *= np.linspace(0.0, 1.0, a)
    return e


def later(signal, seconds):
    """The same sound, `seconds` on."""
    n = int(seconds * RATE)
    return np.concatenate([np.zeros(n), signal[:len(signal) - n]])


def modes(partials, strength):
    """Struck partials, each (Hz, share, decay s), each a little off its pitch."""
    out = np.zeros(int(LENGTH * RATE))
    for f, share, tau in partials:
        f *= rng.uniform(0.96, 1.04)
        out += np.sin(2 * np.pi * f * t() + rng.uniform(0, 2 * np.pi)) * decay(tau) * share
    return out * strength


def grit(strength):
    """Desert grit ground under the boot: a short scatter of tiny ticks."""
    out = np.zeros(int(LENGTH * RATE))
    for _ in range(rng.integers(6, 14)):
        at = int(rng.uniform(0.0, 0.06) * RATE)
        n = int(rng.uniform(0.0008, 0.002) * RATE)
        out[at:at + n] += rng.standard_normal(n) * np.exp(-np.linspace(0, 5, n)) * rng.uniform(0.3, 1.0)
    return band(out, 2500, 9000) * strength


def level(signal):
    """Its level, dBFS RMS over its loudest 400 ms."""
    n = int(0.4 * RATE)
    power = np.convolve(signal ** 2, np.ones(n) / n, mode="valid")
    return 10.0 * np.log10(np.max(power) + 1e-12)


def save(name, signal):
    """Levelled to HEARD, peaks held at -6 dBFS."""
    signal = signal - np.mean(signal)
    signal = signal * 10 ** ((HEARD - level(signal)) / 20.0)
    peak = np.max(np.abs(signal))
    if peak > 10 ** (-6.0 / 20.0):
        signal *= 10 ** (-6.0 / 20.0) / peak
    fade = int(0.01 * RATE)
    signal[-fade:] *= np.linspace(1.0, 0.0, fade)
    data = (np.clip(signal, -1.0, 1.0) * 32767).astype(np.int16)
    with wave.open(os.path.join(HERE, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print("%-18s %5.1f dB, peak %5.1f dBFS" % (name, level(signal), 20.0 * np.log10(np.max(np.abs(signal)))))


def footfall(hit):
    """A heel, then the toe rolling down after it, softer."""
    gap = rng.uniform(0.045, 0.085)
    return hit(1.0) + later(hit(rng.uniform(0.35, 0.55)), gap)


# Metal plate: the boot's click, the plate's damped ring (a weight on it
# stops it quickly) and the hollow under it.
def metal(strength):
    click = band(noise(), 2000, 9000) * decay(0.003) * 0.7
    ring = modes([(rng.uniform(380, 460), 0.5, 0.05), (rng.uniform(910, 1050), 0.35, 0.04),
                  (rng.uniform(1650, 1900), 0.25, 0.03), (rng.uniform(2700, 3100), 0.15, 0.02)], 1.0)
    hollow = modes([(rng.uniform(110, 140), 1.0, 0.035)], 0.8)
    return (click + ring + hollow + grit(0.3)) * strength


# Stone: a dull thud with no ring, the scuff of a sole and more grit.
def stone(strength):
    thud = modes([(rng.uniform(85, 110), 1.0, 0.02)], 0.9)
    scuff = band(noise(), 500, 5000) * decay(0.012, 0.002) * 0.8
    return (thud + scuff + grit(0.6)) * strength


# Wood: a hollow knock, its few low modes ringing short, and a creak of give.
def wood(strength):
    knock = band(noise(), 800, 4000) * decay(0.004) * 0.5
    body = modes([(rng.uniform(190, 240), 1.0, 0.04), (rng.uniform(420, 520), 0.5, 0.03),
                  (rng.uniform(780, 900), 0.25, 0.02)], 1.0)
    return (knock + body + grit(0.25)) * strength


for name, hit in [("metal", metal), ("stone", stone), ("wood", wood)]:
    for k in "abcd":
        save("step_%s_%s.wav" % (name, k), footfall(hit))
