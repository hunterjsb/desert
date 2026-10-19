"""Makes the vents' felt sounds (game/weather/rumbles.gd): a live vent's deep
build before a burst, looped, and the long low roll a burst's boom rolls on
with. Synthesised here with numpy, then encoded to Ogg Vorbis and levelled by
ffmpeg's EBU R128 meter (a loop by its integrated loudness, a one-shot by its
loudest 400 ms), true peaks under -6 dBTP; CC0. The loop is whole cycles of
everything in it, so it repeats without a seam. Needs ffmpeg. Run from anywhere:

    python assets/audio/make_rumble_sounds.py
"""
import os
import re
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
PEAK = -6.0
rng = np.random.default_rng(1019)


def t(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def shaped(n, lo, hi, brown=True):
    """Noise kept to lo..hi Hz, falling 6 dB an octave if brown; by FFT, so
    it's periodic over its length."""
    spectrum = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1.0 / RATE)
    gain = 1.0 / (1.0 + (f / hi) ** 8) * (1.0 - 1.0 / (1.0 + (f / lo) ** 6))
    if brown:
        gain /= np.maximum(f, lo)
    out = np.fft.irfft(spectrum * gain, n)
    return out / np.max(np.abs(out))


def wobble(n, under_hz):
    """A slow wander, 0 to 1, periodic over its length."""
    spectrum = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1.0 / RATE)
    spectrum[f > under_hz] = 0.0
    spectrum[0] = 0.0
    out = np.fft.irfft(spectrum, n)
    out -= out.min()
    return out / out.max()


def build():
    """The ground groaning as a burst nears: a harmonic tremor at 31 Hz, its
    harmonics carrying it to small speakers, wandering in pitch and swelling
    slowly over brown rumble, and stones rattling faintly in it. Eight
    seconds, every tone a whole number of cycles."""
    seconds = 8.0
    n = int(seconds * RATE)
    x = t(seconds)
    swell = wobble(n, 0.6)
    drift = wobble(n, 0.4) - 0.5
    tremor = np.zeros(n)
    for k, a in enumerate([1.0, 0.55, 0.32, 0.16], start=1):
        tremor += a * np.sin(2.0 * np.pi * 31.0 * k * x + k * 2.4 * drift + k * 0.9)
    tremor /= np.max(np.abs(tremor))
    rumble = shaped(n, 18.0, 110.0)
    rattle = shaped(n, 300.0, 1400.0, brown=False) * wobble(n, 9.0) ** 5
    out = (0.55 * tremor * (0.45 + 0.55 * swell) + 0.75 * rumble * (0.7 + 0.3 * swell)
           + 0.12 * rattle * (0.3 + 0.7 * swell))
    # Driven softly into saturation: its peaks rounded off, so it carries
    # louder under the same peak, and its harmonics reach small speakers.
    out /= np.max(np.abs(out))
    return np.tanh(2.2 * out) / np.tanh(2.2)


def roll():
    """A burst's blast rolling on after its thump, low and long: brown
    rumble surging back off the rift's walls and the dunes nine times over a
    steady floor, a growl under it falling from 40 to 28 Hz, dying over
    sixteen seconds."""
    seconds = 16.0
    n = int(seconds * RATE)
    x = t(seconds)
    surges = np.zeros(n)
    at = 0.0
    for i, peak in enumerate([1.0, 0.85, 0.95, 0.7, 0.62, 0.5, 0.42, 0.3, 0.22]):
        rise = rng.uniform(0.2, 0.4)
        fall = rng.uniform(0.5, 1.1)
        since = x - at
        shape = np.where(since < 0.0, 0.0, np.where(since < rise, (since / rise) ** 2,
                         np.exp(-(since - rise) / fall)))
        surges += peak * rng.uniform(0.85, 1.0) * shape
        at += rng.uniform(0.9, 1.6) if i < 4 else rng.uniform(1.3, 2.2)
    surges = (surges + 0.35) * np.exp(-x / 6.0)
    surges /= np.max(surges)
    rumble = shaped(n, 20.0, 140.0)
    growl = np.sin(2.0 * np.pi * np.cumsum(28.0 + 12.0 * np.exp(-x / 4.0)) / RATE)
    out = (0.8 * rumble + 0.35 * growl) * surges
    fade_in = int(0.05 * RATE)
    out[:fade_in] *= np.linspace(0.0, 1.0, fade_in)
    fade_out = int(1.0 * RATE)
    out[-fade_out:] *= np.linspace(1.0, 0.0, fade_out)
    return out


def write_wav(path, signal):
    data = (np.clip(signal, -1.0, 1.0) * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def measure(path):
    """Integrated LUFS, the loudest momentary (400 ms) LUFS, true peak dBTP."""
    out = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "ebur128=peak=true",
                          "-f", "null", "-"], capture_output=True, text=True).stderr
    momentary = [float(m) for m in re.findall(r"M:\s*(-?[\d.]+)", out)]
    whole = float(re.findall(r"I:\s*(-?[\d.]+) LUFS", out)[-1])
    peak = float(re.findall(r"Peak:\s*(-?[\d.]+|-inf) dBFS", out)[-1])
    return whole, max(momentary), peak


def make(name, signal, loop, target):
    """Levelled to `target` LUFS, its peak never past PEAK, as Ogg Vorbis."""
    signal = signal / np.max(np.abs(signal)) * 0.25
    ogg = os.path.join(HERE, name)
    with tempfile.TemporaryDirectory() as work:
        wav = os.path.join(work, "take.wav")
        for _ in range(3):
            write_wav(wav, signal)
            subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis",
                            "-q:a", "5", ogg], check=True)
            whole, loudest, peak = measure(ogg)
            got = whole if loop else loudest
            gain = min(target - got, PEAK - 0.2 - peak)
            if abs(gain) < 0.1:
                break
            signal = signal * 10.0 ** (gain / 20.0)
    print("%s: %.1f LUFS integrated, %.1f loudest 400 ms, peak %.1f dBTP" % (name, whole, loudest, peak))


make("vent_build.ogg", build(), True, -21.0)
make("boom_roll.ogg", roll(), False, -24.5)
