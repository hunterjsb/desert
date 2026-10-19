"""Makes scrapping's sounds (game/salvage): the heat cutter's roar, a plate
coming free and landing, a capacitor bank's crackle and its shock, a breached
store's hiss, the scoop's scrape and the sealant's spray. Synthesised here,
numpy only, as 16-bit mono WAV at 44.1 kHz; CC0. Run from anywhere:

    python assets/audio/make_scrap_sounds.py
"""
import os
import wave

import numpy as np

RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
rng = np.random.default_rng(1234)


def band(signal, lo, hi):
    """Keeps lo..hi Hz, by FFT."""
    spectrum = np.fft.rfft(signal)
    f = np.fft.rfftfreq(len(signal), 1.0 / RATE)
    gain = ((f >= lo) & (f <= hi)).astype(float)
    # Soft edges, a sixth of an octave.
    gain = np.convolve(gain, np.ones(31) / 31.0, mode="same")
    return np.fft.irfft(spectrum * gain, len(signal))


def noise(seconds):
    return rng.standard_normal(int(seconds * RATE))


def t(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def envelope(n, attack, release):
    e = np.ones(n)
    a = max(1, int(attack * RATE))
    r = max(1, int(release * RATE))
    e[:a] = np.linspace(0.0, 1.0, a)
    e[-r:] *= np.linspace(1.0, 0.0, r)
    return e


def crackles(seconds, per_second, width=0.002, seed=0):
    out = np.zeros(int(seconds * RATE))
    count = int(seconds * per_second)
    local = np.random.default_rng(seed)
    for at in local.integers(0, len(out) - int(width * RATE * 4), count):
        n = int(width * RATE * local.uniform(0.5, 2.0))
        out[at:at + n] += local.standard_normal(n) * np.exp(-np.linspace(0, 6, n)) * local.uniform(0.3, 1.0)
    return out


def loop(signal, fade=0.15):
    """Crossfades the end into the start so it repeats without a seam."""
    n = int(fade * RATE)
    head = signal[:n].copy()
    tail = signal[-n:].copy()
    ramp = np.linspace(0.0, 1.0, n)
    out = signal[n:].copy()
    out[-n:] = tail * (1.0 - ramp) + head * ramp
    return out


def save(name, signal, peak_db):
    signal = signal / max(np.max(np.abs(signal)), 1e-9) * 10 ** (peak_db / 20.0)
    data = (np.clip(signal, -1.0, 1.0) * 32767).astype(np.int16)
    with wave.open(os.path.join(HERE, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


# The cutter: a torch's roar, its hiss on top, a hum under it and the
# crackle of metal giving way.
d = 2.0
roar = band(noise(d), 200, 1400) * 0.6
hiss = band(noise(d), 3000, 9000) * 0.5
hum = np.sin(2 * np.pi * 110 * t(d)) * 0.12 + np.sin(2 * np.pi * 220 * t(d)) * 0.06
flutter = 1.0 + 0.15 * np.sin(2 * np.pi * 7.3 * t(d))
save("cutter.wav", loop((roar + hiss + hum) * flutter + band(crackles(d, 40, seed=1), 1500, 12000) * 0.8), -12)

# A plate coming free: a groan of metal, then the snap of its last weld.
d = 0.7
groan_f = 70 + 40 * t(d)
groan = np.sin(2 * np.pi * np.cumsum(groan_f) / RATE) * envelope(int(d * RATE), 0.05, 0.3) * 0.5
groan += band(noise(d), 300, 900) * 0.2 * envelope(int(d * RATE), 0.1, 0.3)
snap = np.zeros(int(d * RATE))
at = int(0.45 * RATE)
n = int(0.08 * RATE)
snap[at:at + n] = band(noise(0.08), 800, 8000) * np.exp(-np.linspace(0, 8, n))
save("plate_free.wav", groan + snap * 1.5, -9)

# A plate landing: a dull clang into the sand, its ring of uneven partials
# soon dead.
d = 1.2
x = t(d)
ring = sum(a * np.sin(2 * np.pi * f * x) * np.exp(-x * k)
	for f, a, k in [(143, 1.0, 5.0), (387, 0.6, 7.0), (712, 0.4, 9.0), (1131, 0.25, 12.0), (1660, 0.15, 16.0)])
thud = band(noise(d), 40, 300) * np.exp(-x * 18.0) * 2.0
save("plate_land.wav", ring * 0.6 + thud, -8)

# A live capacitor bank: a mains buzz and the crackle of a leak across its
# terminals, looped.
d = 1.6
x = t(d)
buzz = sum(np.sin(2 * np.pi * 100 * h * x) / h for h in range(1, 9)) * 0.12
arcs = band(crackles(d, 18, width=0.004, seed=2), 600, 10000)
save("arc_loop.wav", loop(buzz * (0.7 + 0.3 * np.sin(2 * np.pi * 1.7 * x)) + arcs), -14)

# A shock: the crack of a discharge, a burst of buzz falling away.
d = 0.6
x = t(d)
crack = band(noise(d), 500, 14000) * np.exp(-x * 40.0) * 1.5
fall = sum(np.sin(2 * np.pi * 100 * h * x) / h for h in range(1, 12)) * np.exp(-x * 6.0) * 0.4
save("zap.wav", crack + fall + band(crackles(d, 60, seed=3), 1000, 12000) * np.exp(-x * 5.0), -6)

# A breached store: a thin, steady hiss of something escaping, looped.
d = 2.0
x = t(d)
seep = band(noise(d), 2500, 11000) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.6 * x))
save("hiss_loop.wav", loop(seep + band(noise(d), 600, 1500) * 0.1), -18)

# The scoop: a blade dragged through packed sand, and the throw.
d = 0.45
x = t(d)
drag = band(noise(d), 700, 6000) * np.minimum(x / 0.05, 1.0) * np.exp(-np.maximum(x - 0.25, 0) * 14.0)
grains = band(crackles(d, 300, width=0.001, seed=4), 2000, 12000) * 0.5
save("scoop.wav", drag + grains, -14)

# Sealant sprayed over a breach: a hiss, then the plop of it setting.
d = 0.8
x = t(d)
spray = band(noise(d), 2000, 9000) * envelope(int(d * RATE), 0.02, 0.25) * np.where(x < 0.55, 1.0, 0.0)
plop = np.sin(2 * np.pi * (260 - 160 * np.clip((x - 0.6) / 0.1, 0, 1)) * x) * np.exp(-np.maximum(x - 0.6, 0) * 25.0) \
	* (x > 0.6) * 0.5
save("seal.wav", spray + plop, -14)
