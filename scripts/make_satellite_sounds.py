#!/usr/bin/env python3
"""Original looping broadcasts for three satellites, so none borrows the Eye's
drones (the Eye's sound is the Eye's alone). Python, numpy and ffmpeg only; CC0.

    python3 scripts/make_satellite_sounds.py
"""

import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

RATE = 44100
FADE = 2.0
ROOT = Path(__file__).resolve().parents[1]


def looped(render, seconds, seed):
    """Renders `seconds` plus a fade's worth, then folds the tail over the head,
    so the loop's seam is a crossfade."""
    rng = np.random.default_rng(seed)
    t = np.arange(int(RATE * (seconds + FADE))) / RATE
    sound = render(t, rng)
    n, f = int(RATE * seconds), int(RATE * FADE)
    ramp = np.linspace(0.0, 1.0, f)
    out = sound[:n].copy()
    out[:f] = sound[:f] * ramp + sound[n:n + f] * (1.0 - ramp)
    return out


def lowpassed(x, hz):
    a = np.exp(-2.0 * np.pi * hz / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = acc * a + v * (1.0 - a)
        y[i] = acc
    return y


def drone(t, rng):
    # The deliveryship's turbines: a low hum, two engines beating slowly,
    # and the rush of air past its hull.
    hum = sum(np.sin(2 * np.pi * f * t) / k for k, f in enumerate([55.0, 110.0, 165.0, 220.0], 1))
    beat = sum(np.sin(2 * np.pi * f * 1.012 * t) / k for k, f in enumerate([55.0, 110.0], 1))
    air = lowpassed(rng.uniform(-1.0, 1.0, t.size), 600.0) * 3.0
    return hum + 0.6 * beat + air * (0.8 + 0.2 * np.sin(2 * np.pi * t / 6.0))


def choir(t, rng):
    # The colony's hymn: a slow swell between two chords, each voice a few soft
    # harmonics with its own vibrato.
    chords = [[261.6, 329.6, 392.0], [220.0, 277.2, 329.6]]
    out = np.zeros_like(t)
    swell = 0.5 + 0.5 * np.cos(2 * np.pi * t / 16.0)
    for c, chord in enumerate(chords):
        weight = swell if c == 0 else 1.0 - swell
        for v, f in enumerate(chord):
            wobble = 1.0 + 0.004 * np.sin(2 * np.pi * (4.7 + v * 0.3) * t + v)
            phase = 2 * np.pi * np.cumsum(f * wobble) / RATE
            out += weight * (np.sin(phase) + 0.3 * np.sin(2 * phase) + 0.12 * np.sin(3 * phase))
    return out


def ghost(t, rng):
    # Nobody knows whose: a whistle wandering up and down through hiss swept dark
    # and bright, as a carrier heard on a dying set.
    glide = 700.0 + 350.0 * np.sin(2 * np.pi * t / 5.0) + 120.0 * np.sin(2 * np.pi * t / 1.3)
    whistle = np.sin(2 * np.pi * np.cumsum(glide) / RATE)
    hiss = rng.uniform(-1.0, 1.0, t.size)
    dark = lowpassed(hiss, 400.0) * 4.0
    bright = hiss - lowpassed(hiss, 2500.0)
    sweep = 0.5 + 0.5 * np.sin(2 * np.pi * t / 7.0)
    return 0.5 * whistle * (0.6 + 0.4 * np.sin(2 * np.pi * t / 2.5)) + dark * sweep + 0.3 * bright * (1.0 - sweep)


def write(name, sound):
    sound = sound / np.max(np.abs(sound)) * 0.5
    with tempfile.TemporaryDirectory(prefix="desert-satellite-audio-") as tmp:
        source = Path(tmp) / "source.wav"
        with wave.open(str(source), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes((sound * 32767).astype("<i2").tobytes())
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source),
                        "-af", "loudnorm=I=-28:TP=-6:LRA=7", "-ar", str(RATE), "-ac", "1",
                        "-c:a", "libvorbis", "-q:a", "3", str(ROOT / "assets/audio" / name)], check=True)


if __name__ == "__main__":
    write("radio_sat_drone.ogg", looped(drone, 12.0, 1))
    write("radio_sat_choir.ogg", looped(choir, 16.0, 2))
    write("radio_sat_ghost.ogg", looped(ghost, 10.0, 3))
