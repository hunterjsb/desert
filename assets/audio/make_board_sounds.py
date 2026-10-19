"""Makes the ride's sounds (game/board): a carve's hiss, the wind's rush, a
pop off a lip, a landing and a hard one, a crash's knock, a skid biting
again, three makes' hums, and the battery's low and critical cues. Synthesised here, numpy only, as 16-bit mono
WAV at 44.1 kHz; CC0. Loops are whole cycles of everything in them, so they
repeat without a seam. Run from anywhere:

    python assets/audio/make_board_sounds.py
"""
import os
import wave

import numpy as np

RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
rng = np.random.default_rng(2026)


def band(signal, lo, hi):
    """Keeps lo..hi Hz, by FFT, with soft edges."""
    spectrum = np.fft.rfft(signal)
    f = np.fft.rfftfreq(len(signal), 1.0 / RATE)
    gain = ((f >= lo) & (f <= hi)).astype(float)
    gain = np.convolve(gain, np.ones(31) / 31.0, mode="same")
    return np.fft.irfft(spectrum * gain, len(signal))


def noise(seconds):
    return rng.standard_normal(int(seconds * RATE))


def t(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def decay(seconds, length, attack=0.002):
    x = t(length)
    e = np.exp(-x / seconds)
    a = max(1, int(attack * RATE))
    e[:a] *= np.linspace(0.0, 1.0, a)
    return e


def glide(f0, f1, length, over):
    """A sine sliding from f0 to f1 Hz over `over` s, then holding."""
    x = t(length)
    f = f1 + (f0 - f1) * np.exp(-x / max(over, 1e-3))
    return np.sin(2.0 * np.pi * np.cumsum(f) / RATE)


def level(signal, loop):
    """Its level, dBFS RMS: a loop's whole, a one-shot's loudest 400 ms."""
    if loop:
        return 10.0 * np.log10(np.mean(signal ** 2) + 1e-12)
    n = int(0.4 * RATE)
    if len(signal) <= n:
        return 10.0 * np.log10(np.mean(signal ** 2) + 1e-12)
    power = np.convolve(signal ** 2, np.ones(n) / n, mode="valid")
    return 10.0 * np.log10(np.max(power) + 1e-12)


def save(name, signal, at_db, loop=False):
    """Levelled to `at_db`, peaks held at -6 dBFS."""
    signal = signal - np.mean(signal)
    signal = signal * 10 ** ((at_db - level(signal, loop)) / 20.0)
    peak = np.max(np.abs(signal))
    if peak > 10 ** (-6.0 / 20.0):
        signal *= 10 ** (-6.0 / 20.0) / peak
    if not loop:
        fade = int(0.01 * RATE)
        signal[-fade:] *= np.linspace(1.0, 0.0, fade)
    data = (np.clip(signal, -1.0, 1.0) * 32767).astype(np.int16)
    with wave.open(os.path.join(HERE, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print("%-14s %5.1f dB, peak %5.1f dBFS, %.2f s" % (name, level(signal, loop),
          20.0 * np.log10(np.max(np.abs(signal))), len(signal) / RATE))


def circular(signal, lo, hi):
    """Band-limited noise that wraps: the FFT's own is periodic."""
    return band(signal, lo, hi)


# A carve's hiss: the field combing the sand, airy and smooth, a faint
# rustle under it, breathing a little. 2 s, whole cycles.
d = 2.0
x = t(d)
hiss = circular(noise(d), 1800, 7500) * (1.0 + 0.15 * np.sin(2 * np.pi * 3.0 * x))
rustle = circular(noise(d), 400, 1200) * 0.35 * (1.0 + 0.3 * np.sin(2 * np.pi * 5.0 * x + 1.0))
save("board_carve.wav", hiss + rustle, -36.0, loop=True)

# The wind's rush at speed: wide, low noise, gusting slowly, and a thin
# whistle over it. 4 s.
d = 4.0
x = t(d)
gust = 1.0 + 0.25 * np.sin(2 * np.pi * 0.5 * x) + 0.12 * np.sin(2 * np.pi * 1.25 * x + 0.7)
rush = circular(noise(d), 120, 1600) * gust
rush += circular(noise(d), 1600, 4200) * 0.25 * (1.0 + 0.4 * np.sin(2 * np.pi * 0.75 * x + 2.0))
save("board_rush.wav", rush, -33.0, loop=True)

# A pop off a lip: the field letting go, a soft low thup and a fwip of air.
d = 0.4
thup = glide(150.0, 55.0, d, 0.05) * decay(0.07, d, 0.003)
fwip = band(noise(d), 300, 3500) * decay(0.06, d, 0.012) * 0.5
save("board_pop.wav", thup + fwip, -33.0)

# A landing: the field pressed flat, a muffled whumph, and sand thrown off.
d = 0.7
whumph = glide(90.0, 45.0, d, 0.08) * decay(0.12, d, 0.004)
press = band(noise(d), 150, 600) * decay(0.1, d, 0.006) * 0.6
sand = band(noise(d), 900, 6500) * decay(0.22, d, 0.01) * 0.35
save("board_land.wav", whumph + press + sand, -31.0)

# A hard landing: the field slammed through, a deeper thud, a bigger burst of
# sand and the deck's rattle.
d = 1.0
thud = glide(75.0, 34.0, d, 0.1) * decay(0.2, d, 0.003)
press = band(noise(d), 120, 700) * decay(0.14, d, 0.004) * 0.8
sand = band(noise(d), 700, 7000) * decay(0.3, d, 0.008) * 0.5
rattle = np.zeros(int(d * RATE))
for k, at in enumerate([0.012, 0.045, 0.07, 0.11, 0.16]):
    i = int(at * RATE)
    n = int(0.05 * RATE)
    f = [1150.0, 1720.0, 980.0, 2300.0, 1400.0][k]
    ring = np.sin(2 * np.pi * f * t(0.05)) * np.exp(-t(0.05) / 0.012) * (0.5 - 0.07 * k)
    rattle[i:i + n] += ring
save("board_slam.wav", thud + press + sand + rattle * 0.6, -27.0)

# A crash's knock: the board's hollow body struck, its modes ringing short,
# a second knock as it comes back, and your weight's thud under it.
d = 0.9


def knock(strength):
    out = band(noise(d), 1500, 6000) * decay(0.004, d, 0.0005) * 0.6
    for f, s, tau in [(170.0, 1.0, 0.11), (410.0, 0.7, 0.07), (745.0, 0.5, 0.05), (1310.0, 0.3, 0.03)]:
        out += np.sin(2 * np.pi * f * t(d)) * decay(tau, d, 0.0008) * s
    return out * strength


hit = knock(1.0)
again = np.zeros_like(hit)
i = int(0.13 * RATE)
again[i:] = knock(0.45)[:len(hit) - i]
body = glide(70.0, 40.0, d, 0.06) * decay(0.16, d, 0.006) * 0.9
save("board_knock.wav", hit + again + body, -27.0)

# A skid biting again: a short scuff of sand and the field's chirp as it takes hold.
d = 0.3
scuff = band(noise(d), 2000, 8000) * decay(0.035, d, 0.004)
chirp = np.sin(2 * np.pi * np.cumsum(np.linspace(300.0, 520.0, int(d * RATE))) / RATE) * decay(0.05, d, 0.01) * 0.3
save("board_bite.wav", scuff + chirp, -36.0)

# The makes' hums, each 2 s of whole cycles. The skimmer racer's: a thin
# bright whine with a buzz in it, a little vibrato. Played up to 1.75 times.
d = 2.0
x = t(d)
vib = 1.0 + 0.004 * np.sin(2 * np.pi * 6.0 * x)
phase = 2 * np.pi * 330.0 * np.cumsum(vib) / RATE
whine = sum(a * np.sin(k * phase) for k, a in [(1, 1.0), (2, 0.5), (3, 0.35), (5, 0.15), (7, 0.07)])
buzz = np.tanh(3.0 * np.sin(phase)) * 0.12
air = circular(noise(d), 3000, 8000) * 0.05
save("hum_racer.wav", whine + buzz + air, -35.0, loop=True)

# The Knights' patrol board's: a deep steady thrum, pulsing like a heavy
# rotor, a growl under it.
phase = 2 * np.pi * 110.0 * x
thrum = sum(a * np.sin(k * phase) for k, a in [(1, 1.0), (2, 0.6), (3, 0.3), (4, 0.15), (6, 0.06)])
thrum *= 1.0 + 0.22 * np.sin(2 * np.pi * 4.0 * x)
growl = circular(noise(d), 60, 320) * 0.25
save("hum_patrol.wav", thrum + growl, -34.0, loop=True)

# The temple board's: a soft hum with a ceramic ring over it, two of its
# partials beating slowly, and a breath of air.
hum = np.sin(2 * np.pi * 196.0 * x) + 0.2 * np.sin(2 * np.pi * 392.0 * x)
ring = 0.16 * np.sin(2 * np.pi * 541.0 * x) + 0.16 * np.sin(2 * np.pi * 543.0 * x) \
    + 0.08 * np.sin(2 * np.pi * 1058.0 * x) + 0.04 * np.sin(2 * np.pi * 1750.0 * x)
breath = circular(noise(d), 400, 2500) * 0.12 * (1.0 + 0.5 * np.sin(2 * np.pi * 0.5 * x))
save("hum_temple.wav", hum + ring + breath, -35.0, loop=True)

# The battery's two cues, each a soft two-note fall, "do-doo": low, once,
# about a minute from flat, and critical, once more, lower and more urgent.


def note(f, length, bright, tau):
    x = t(length)
    tone = np.sin(2 * np.pi * f * x) + 0.3 * np.sin(2 * np.pi * 2 * f * x) + bright * np.sin(2 * np.pi * 3 * f * x)
    return tone * decay(tau, length, 0.006)


def do_doo(high, low, gap, length, bright, tau):
    out = np.zeros(int((gap + length) * RATE))
    first = note(high, length, bright, tau)
    second = note(low, length, bright, tau)
    out[:len(first)] += first
    i = int(gap * RATE)
    out[i:i + len(second)] += second
    return out


save("battery_low.wav", do_doo(659.3, 523.3, 0.2, 0.6, 0.05, 0.16), -34.0)
save("battery_critical.wav", do_doo(440.0, 329.6, 0.14, 0.5, 0.25, 0.1)
     * (1.0 + 0.25 * np.sin(2 * np.pi * 18.0 * t(0.64))), -30.0)
