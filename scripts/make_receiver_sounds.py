#!/usr/bin/env python3
"""Original mono field-instrument sounds; only Python and ffmpeg are needed."""

import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

RATE = 48000
ROOT = Path(__file__).resolve().parents[1]


def render(name, sample):
    rng = random.Random(20261020)
    samples = []
    low = 0.0
    for i in range(int(RATE * 0.45)):
        t = i / RATE
        noise = rng.uniform(-1.0, 1.0)
        low += (noise - low) * 0.16
        samples.append(sample(t, low))
    peak = max(abs(v) for v in samples)
    data = b"".join(struct.pack("<h", int(v / peak * 0.25 * 32767)) for v in samples)
    with tempfile.TemporaryDirectory(prefix="desert-receiver-audio-") as tmp:
        source = Path(tmp) / "source.wav"
        with wave.open(str(source), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes(data)
        target = ROOT / "assets" / "audio" / (name + ".wav")
        subprocess.run([
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source),
            "-af", "loudnorm=I=-34:TP=-9:LRA=7,aresample=48000", "-c:a", "pcm_s16le",
            str(target),
        ], check=True)
        print(target.name)


def switch(t, noise):
    value = 0.0
    for start, amount in ((0.0, 1.0), (0.043, 0.48)):
        age = t - start
        if age >= 0.0:
            value += amount * (
                noise * math.exp(-age / 0.005)
                + 0.28 * math.sin(math.tau * 430 * age) * math.exp(-age / 0.019)
                + 0.12 * math.sin(math.tau * 1120 * age) * math.exp(-age / 0.008)
            )
    return value


def tick(t, noise):
    return (
        noise * math.exp(-t / 0.003)
        + 0.16 * math.sin(math.tau * 1390 * t) * math.exp(-t / 0.009)
        + 0.2 * math.sin(math.tau * 350 * t) * math.exp(-t / 0.012)
    )


def pulse(t, noise):
    if t >= 0.20:
        return 0.0
    envelope = (1.0 - math.exp(-t / 0.006)) * math.exp(-t / 0.042)
    tone = math.sin(math.tau * (780 * t - 95 * t * t))
    harmonic = 0.13 * math.sin(math.tau * 1560 * t) * math.exp(-t / 0.02)
    return (tone + harmonic + noise * 0.035) * envelope


if __name__ == "__main__":
    for name, fn in (("receiver_switch", switch), ("receiver_tick", tick), ("receiver_pulse", pulse)):
        render(name, fn)
