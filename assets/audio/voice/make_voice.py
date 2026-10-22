"""Renders the radio's voice: every phrase the weather station's spoken
reports are put together from (Radio.report in game/radio/radio.gd), and a
Console's battery warnings, one mono OGG each, named by its words. Piper with
the public-domain LJ Speech voice; the source and licences are in
assets/audio/CREDITS.md. Run once, offline, from a venv of its own, never the
repo's:

    uv venv --python 3.12 /tmp/voice-venv
    VIRTUAL_ENV=/tmp/voice-venv uv pip install "piper-tts[alignment]==1.8.0" faster-whisper==1.2.1 numpy
    curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ljspeech/high/en_US-ljspeech-high.onnx
    curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ljspeech/high/en_US-ljspeech-high.onnx.json
    /tmp/voice-venv/bin/python assets/audio/voice/make_voice.py en_US-ljspeech-high.onnx [phrase ...] [--out DIR]

Each phrase is said after "the", which is cut off, since this voice starts
an utterance from silence too softly ("battery" comes out "factory"). Piper's
takes vary, a word now and then slurred, so each is rendered up to TAKES
times and the one Whisper hears surest as its words through the radio's
small speaker is kept. Named phrases ("Wind speed forty.") are rendered
again alone. Encodes with ffmpeg, or soundfile without it.
"""
import argparse
import os
import re
import subprocess
import tempfile
import shutil
import wave

import numpy as np
from faster_whisper import WhisperModel
from piper import PiperVoice, SynthesisConfig

HERE = os.path.dirname(os.path.abspath(__file__))
# Every phrase sits at this loudness through its voiced part, so a report
# reads level, about -25 LUFS through the radio's speaker: a little over its
# music (-28), since it has to come through the static. Peaks stay under -6 dBFS.
VOICED_RMS_DB = -23.0
PEAK_DB = -6.0
# A touch slower than Piper's pace: a station reading a log, not chatting.
PACE = 1.08
TAKES = 4
# A take heard as said this surely (Whisper's mean log-probability) is kept at once.
SURE = -0.3
# The radio's speaker cuts everything under this, Hz (radio_highpass_hz).
SPEAKER_HZ = 400.0
ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
TENS = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
POINTS = ["north", "north-north-east", "north-east", "east-north-east", "east", "east-south-east",
          "south-east", "south-south-east", "south", "south-south-west", "south-west", "west-south-west",
          "west", "west-north-west", "north-west", "north-north-west"]
# What Piper is given for a phrase it says unclearly as written: alone, "Oh
# one." comes out "a what", "Eighty," "A.J." and "Schedule." "Tetra".
SAID = {"Oh one.": "Oh, one.", "Oh five.": "Oh, five.", "Eighty,": "Eightee.", "Metres a second.": "Meters a second.",
        "Schedule.": "Skejool."}
# What the station says numbers up to, exactly, and past it to the ten.
EXACT = 60


def words(n):
    if n == 100:
        return "a hundred"
    if n < 20:
        return ONES[n]
    return TENS[n // 10] + ("" if n % 10 == 0 else "-" + ONES[n % 10])


def phrases():
    numbers = list(range(EXACT + 1)) + [70, 80, 90, 100]
    out = ["Storm coming.", "Storm here.", "All clear.", "Long range.", "No reading.",
           "Clearing,", "No clearing,", "Next storm,", "No storms,", "Battery low.", "Battery critical."]
    out += ["From the %s." % p for p in POINTS]
    out += ["Wind speed %s." % words(n) for n in numbers]
    out += ["One minute."] + ["%s minutes." % words(n).capitalize() for n in numbers if n > 1]
    out += ["%s seconds." % words(n).capitalize() for n in range(10, 100, 10)]
    # The regular report and the advisories (gonkhub, 2026-10-20): the local
    # time, the temperature and the bare numbers they're read in.
    out += ["Weather station.", "Local time,", "Hundred.", "Temperature,", "Minus,", "Degrees.",
            "Weather advisory.", "Fast sandstorm,", "Large sandstorm,", "Fast and large sandstorm,", "On you now.",
            "Moving,", "Metres a second.", "Lasting,", "Lasting more than,", "Take shelter."]
    out += ["Oh %s." % ONES[n] for n in range(1, 10)]
    out += ["%s," % words(n).capitalize() for n in numbers]
    return out


def key(phrase):
    """The file a phrase is in, as Radio.clip names it."""
    return "_".join(re.findall(r"[a-z]+", phrase.lower()))


def render(voice, phrase):
    """A take of the phrase, said after "the" and cut where "the" ends."""
    said = next(iter(voice.synthesize("The " + phrase[0].lower() + phrase[1:], SynthesisConfig(length_scale=PACE),
                                      include_alignments=True)))
    cut = 0
    for each in said.phoneme_alignments:
        cut += each.num_samples
        if each.phoneme == " ":
            break
    return said.audio_float_array[cut:].astype(np.float64)


def canon(text):
    """Words as letters only, numbers spelt out, to compare what's heard."""
    text = re.sub(r"\d+", lambda m: words(int(m.group())) if int(m.group()) <= 100 else m.group(), text.lower())
    return re.sub(r"[^a-z]", "", text)


def heard(model, audio, rate):
    """What Whisper hears of a take through the radio's speaker, and how sure it is."""
    spectrum = np.fft.rfft(audio)
    spectrum[np.fft.rfftfreq(len(audio), 1.0 / rate) < SPEAKER_HZ] = 0.0
    n = len(audio) * 16000 // rate
    at = np.fft.irfft(spectrum[:n // 2 + 1], n) * n / len(audio)
    pad = np.zeros(8000)
    said, _ = model.transcribe(np.concatenate([pad, at, pad]).astype(np.float32), language="en", beam_size=5,
                               without_timestamps=True, condition_on_previous_text=False)
    said = list(said)
    return " ".join(s.text for s in said).strip(), np.mean([s.avg_logprob for s in said]) if said else -9.0


def score(phrase, text, sure):
    """2 heard as said, 1 near enough, 0 not; then how sure."""
    want, got = canon(phrase), canon(text)
    if got == want:
        return 2, sure
    # Alone, "wind speed" is now and then heard as "win speed"; its number has to be right.
    if phrase.startswith("Wind speed ") and re.fullmatch(r"[a-z]{0,12}?" + canon(phrase[11:]), got):
        return 1, sure
    # The minutes past ("Oh five.") are heard as 05 or O5, and the hour ("Hundred.") as 100.
    if phrase.startswith("Oh ") and re.fullmatch(r"(oh|o|zero)?" + canon(phrase[3:]), got):
        return 1, sure
    if phrase == "Metres a second." and got == "metersasecond":
        return 2, sure
    if phrase == "Hundred." and got == "ahundred":
        return 1, sure
    return 0, sure


def surest(voice, ears, phrase, rate):
    """The take Whisper hears surest as the phrase: (score, heard, audio, voiced)."""
    takes = []
    while len(takes) < TAKES and not (takes and takes[-1][0] >= (2, SURE)):
        audio, voiced = trimmed(render(voice, SAID.get(phrase, phrase)), rate)
        text, sure = heard(ears, audio, rate)
        takes.append((score(phrase, text, sure), text, audio, voiced))
    return max(takes, key=lambda take: take[0])


def trimmed(audio, rate):
    """Its voiced part, the silence either side cut down to a breath, eased in
    and out so phrases join without a click."""
    frame = rate // 100
    n = len(audio) // frame
    energy = np.sqrt(np.mean(audio[:n * frame].reshape(n, frame) ** 2, axis=1) + 1e-12)
    loud = np.flatnonzero(energy > max(energy.max() * 10 ** (-40 / 20), 10 ** (-55 / 20)))
    start = max(0, loud[0] * frame - rate * 20 // 1000)
    end = min(len(audio), (loud[-1] + 1) * frame + rate * 60 // 1000)
    out = audio[start:end].copy()
    fade_in = rate * 5 // 1000
    fade_out = rate * 30 // 1000
    out[:fade_in] *= np.linspace(0.0, 1.0, fade_in)
    out[-fade_out:] *= np.linspace(1.0, 0.0, fade_out)
    return out, energy[loud]


def levelled(audio, voiced):
    gain = 10 ** (VOICED_RMS_DB / 20) / np.sqrt(np.mean(voiced ** 2))
    peak = np.abs(audio).max() * gain
    gain *= min(1.0, 10 ** (PEAK_DB / 20) / peak)
    return audio * gain


def save(path, audio, rate):
    if not shutil.which("ffmpeg"):
        # Without ffmpeg, libsndfile's Vorbis at about the same rate, written
        # in blocks: it crashes taking a whole clip at once.
        import soundfile
        with soundfile.SoundFile(path, "w", rate, 1, format="OGG", subtype="VORBIS", compression_level=0.85) as out:
            data = np.clip(audio, -1.0, 1.0).astype(np.float32)
            for at in range(0, len(data), 4096):
                out.write(data[at:at + 4096])
        return
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        with wave.open(tmp.name, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(rate)
            w.writeframes((np.clip(audio, -1.0, 1.0) * 32767).astype(np.int16).tobytes())
        # Mono Vorbis at about 40 kbps: the radio's speaker cuts the lows anyway.
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp.name, "-c:a", "libvorbis", "-q:a", "1",
                        "-map_metadata", "-1", path], check=True)


def main():
    args = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    args.add_argument("model")
    args.add_argument("phrase", nargs="*")
    args.add_argument("--out", default=HERE)
    args = args.parse_args()
    voice = PiperVoice.load(args.model, include_alignments=True)
    ears = WhisperModel("small.en", device="cpu", compute_type="int8", cpu_threads=3)
    rate = voice.config.sample_rate
    for phrase in args.phrase or phrases():
        best, text, audio, voiced = surest(voice, ears, phrase, rate)
        save(os.path.join(args.out, key(phrase) + ".ogg"), levelled(audio, voiced), rate)
        print("%-28s %.2f s  heard %r%s" % (phrase, len(audio) / rate, text, "" if best[0] else "  NOT HEARD"),
              flush=True)


if __name__ == "__main__":
    main()
