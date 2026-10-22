"""Renders the radio's word bank: every word and fragment in words.txt that the
radio puts readouts together from (RadioSpeech.plan) when no whole phrase is
recorded, in the same LJ Speech voice as make_voice.py, from its venv:

    python make_words.py MODEL --root REPOSITORY --cache DIR [--godot GODOT]

words.txt is kept by hand: only what the radio says, since every entry ships.
Each piece is kept in DIR as 16-bit WAV, so only new entries are rendered and
the bank is compressed once, never twice. pack_words.gd then packs them into
word_bank.res, one QOA clip each.
"""
import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import wave

sys.dont_write_bytecode = True
import numpy as np
from faster_whisper import WhisperModel
from piper import PiperVoice

from make_voice import levelled, surest


def write(path, audio, rate):
    with wave.open(str(path), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(rate)
        out.writeframes((np.clip(audio, -1.0, 1.0) * 32767).astype(np.int16).tobytes())


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('model')
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--cache', type=Path)
    parser.add_argument('--godot', default='godot')
    args = parser.parse_args()
    if hasattr(os, 'sched_getaffinity'):
        os.sched_setaffinity(0, sorted(os.sched_getaffinity(0))[:2])
    entries = [line for line in (args.root / 'assets/audio/voice/words.txt').read_text().splitlines() if line]
    with tempfile.TemporaryDirectory() as temporary:
        pieces = args.cache or Path(temporary)
        pieces.mkdir(parents=True, exist_ok=True)
        missing = [word for word in entries if not (pieces / (word.replace(' ', '_') + '.wav')).exists()]
        if missing:
            voice = PiperVoice.load(args.model, include_alignments=True)
            ears = WhisperModel('small.en', device='cpu', compute_type='int8', cpu_threads=2)
            rate = voice.config.sample_rate
            for word in missing:
                best, text, audio, voiced = surest(voice, ears, word.capitalize() + '.', rate)
                write(pieces / (word.replace(' ', '_') + '.wav'), levelled(audio, voiced), rate)
                print('%-28s %.2f s  heard %r%s' % (word, len(audio) / rate, text, '' if best[0] else '  NOT HEARD'),
                      flush=True)
        subprocess.run([args.godot, '--headless', '--path', str(args.root), '-s',
                        'res://assets/audio/voice/pack_words.gd', '--', str(pieces.resolve())], check=True)


if __name__ == '__main__':
    main()
