class_name Signature
extends RefCounted
## Each god's interval signal: the few notes it sends between its words, its
## own and nobody else's, so you learn who you've found by ear and the dial
## never has to name it. Old stations did the same, a tune or a call in Morse
## on the carrier so a listener knew whom they'd tuned. Made here in code,
## mono, and levelled as the tones they replace (radio_tones.ogg: peak -25 dBFS).
##
## - The Quartermaster: its call in Morse, Q M, keyed hard.
## - The Walker: four steps at its pace, heel and toe.
## - Mother Cistern: three drops falling into a basin.
## - The Almanac: the market bell, rising.
## - The Ledger: a tally of five, and the till.
## - The Stoker: a boiler alarm, two tones, three times.
## - The Eye: nothing. It never announces itself.

const RATE := 22050
## Its loudest, of full scale: -25 dBFS.
const PEAK := 0.056
## A Morse dot, s; a dash is three, the gap between marks one, between letters three.
const DOT := 0.07

## Each god's notes: [start s, length s, Hz, wave, Hz it glides to (0 holds)].
## Waves: &"sine", &"square", &"triangle".
static var NOTES := {
	&"quartermaster": _morse("--.- --", 760.0),
	&"walker": [[0.0, 0.09, 520.0, &"triangle", 0.0], [0.33, 0.09, 390.0, &"triangle", 0.0],
		[0.66, 0.09, 520.0, &"triangle", 0.0], [0.99, 0.09, 390.0, &"triangle", 0.0]],
	&"cistern": [[0.0, 0.32, 1240.0, &"sine", 620.0], [0.55, 0.32, 1100.0, &"sine", 560.0],
		[1.2, 0.5, 980.0, &"sine", 490.0]],
	&"almanac": [[0.0, 0.5, 523.25, &"triangle", 0.0], [0.18, 0.5, 659.25, &"triangle", 0.0],
		[0.36, 0.5, 783.99, &"triangle", 0.0], [0.54, 0.8, 1046.5, &"triangle", 0.0]],
	&"ledger": [[0.0, 0.04, 1500.0, &"square", 0.0], [0.16, 0.04, 1500.0, &"square", 0.0],
		[0.32, 0.04, 1500.0, &"square", 0.0], [0.48, 0.04, 1500.0, &"square", 0.0],
		[0.64, 0.04, 1500.0, &"square", 0.0], [0.95, 0.12, 880.0, &"sine", 0.0], [1.07, 0.45, 1318.5, &"sine", 0.0]],
	&"stoker": [[0.0, 0.18, 620.0, &"square", 0.0], [0.2, 0.18, 460.0, &"square", 0.0],
		[0.4, 0.18, 620.0, &"square", 0.0], [0.6, 0.18, 460.0, &"square", 0.0],
		[0.8, 0.18, 620.0, &"square", 0.0], [1.0, 0.18, 460.0, &"square", 0.0]],
	&"eye": [],
}

static var _made := {}


## A god's interval signal as a sound, or null for a god that sends none.
static func of(id: StringName) -> AudioStreamWAV:
	if not NOTES.has(id) or (NOTES[id] as Array).is_empty():
		return null
	if not _made.has(id):
		_made[id] = _render(NOTES[id])
	return _made[id]


## How long a god's signal runs, s: to the end of its last note.
static func length(id: StringName) -> float:
	var out := 0.0
	for note: Array in NOTES.get(id, []):
		out = maxf(out, note[0] + note[1])
	return out


## Morse marks as notes, dots and dashes keyed at `hz`; a space between letters.
static func _morse(marks: String, hz: float) -> Array:
	var out := []
	var at := 0.0
	for mark in marks:
		if mark == " ":
			at += DOT * 2.0
			continue
		var long := DOT * (3.0 if mark == "-" else 1.0)
		out.append([at, long, hz, &"square", 0.0])
		at += long + DOT
	return out


static func _render(notes: Array) -> AudioStreamWAV:
	var end := 0.0
	for note: Array in notes:
		end = maxf(end, note[0] + note[1])
	var frames := ceili((end + 0.05) * RATE)
	var mix := PackedFloat32Array()
	mix.resize(frames)
	for note: Array in notes:
		var from := roundi(note[0] * RATE)
		var count := roundi(note[1] * RATE)
		var phase := 0.0
		for i in count:
			if from + i >= frames:
				break
			var share := float(i) / count
			var hz: float = note[2] if note[4] <= 0.0 else lerpf(note[2], note[4], share)
			phase = fposmod(phase + hz / RATE, 1.0)
			mix[from + i] += _wave(note[3], phase) * _envelope(note[3], i, count)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		data.encode_s16(i * 2, roundi(clampf(mix[i] * PEAK, -1.0, 1.0) * 32767.0))
	var out := AudioStreamWAV.new()
	out.format = AudioStreamWAV.FORMAT_16_BITS
	out.mix_rate = RATE
	out.stereo = false
	out.data = data
	return out


static func _wave(wave: StringName, phase: float) -> float:
	match wave:
		&"square":
			# Softened, the way a small speaker rounds a keyed tone.
			return clampf(sin(phase * TAU) * 3.0, -1.0, 1.0)
		&"triangle":
			return 1.0 - 4.0 * absf(phase - 0.5)
	return sin(phase * TAU)


## Struck notes ring down; keyed ones start and stop with a click's worth of ramp.
static func _envelope(wave: StringName, i: int, count: int) -> float:
	var ramp := minf(1.0, minf(i, count - i) / (0.004 * RATE))
	if wave == &"square":
		return ramp
	return ramp * exp(-4.0 * float(i) / count)
