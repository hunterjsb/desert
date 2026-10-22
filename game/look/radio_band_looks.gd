class_name RadioBandLooks
extends RefCounted
## The three bands a radio can scrub, each its own colour, so you can tell at
## a glance which you're on: the band window glows it, the needle's scale is
## numbered for it, and a converter's tell stripe wears it. Moved into the
## game from look/radio_kit (2026-10-21).
##
## AM carries far gods, beacons and distress calls. FM carries nearby
## stations, music and the tower: short-range and clean, line of sight,
## no sky wave, so a station is loud near and gone past the horizon, and
## storm static barely touches it (it's frequency, not amplitude). Shortwave
## bounces off the sky: far voices, faint and fading, heard best from an
## aerial flown high (the antenna kite).

## [id, label, lowest, highest, unit, scale numbers, glow colour (the window),
## tell colour (stripes, switch), dark colour (the window when off)]
const AM := {"id": &"am", "label": "AM", "low": Dial.LOWEST, "high": Dial.HIGHEST, "unit": "kHz",
	"numbers": ["150", "530", "1100", "1700"], "per": 1.0,
	"glow": Color(1.0, 0.82, 0.55), "tell": Color(0.95, 0.62, 0.18), "dark": Color(0.42, 0.33, 0.2)}
const FM := {"id": &"fm", "label": "FM", "low": Fm.LOWEST, "high": Fm.HIGHEST, "unit": "MHz",
	"numbers": ["88", "92", "96", "100", "104", "108"], "per": 1.0,
	"glow": Color(0.62, 1.0, 0.78), "tell": Color(0.2, 0.75, 0.5), "dark": Color(0.2, 0.36, 0.28)}
const SW := {"id": &"sw", "label": "SW", "low": Shortwave.LOWEST / 1000.0, "high": Shortwave.HIGHEST / 1000.0, "unit": "MHz",
	"numbers": ["2", "6", "10", "14", "18", "22", "26", "30"], "per": 1.0,
	"glow": Color(0.8, 0.66, 1.0), "tell": Color(0.55, 0.32, 0.9), "dark": Color(0.3, 0.24, 0.4)}
const ALL := [AM, FM, SW]


static func of(id: StringName) -> Dictionary:
	for band: Dictionary in ALL:
		if band.id == id:
			return band
	return AM


## Printed frequencies occupy the same fraction of travel as the live needle.
static func ticks(band: Dictionary) -> Array[Dictionary]:
	var marks: Array[Dictionary] = []
	var numbers: Array = band.numbers
	for i in numbers.size():
		var value := float(numbers[i]) * float(band.per)
		var fraction := inverse_lerp(float(band.low), float(band.high), value)
		marks.append({"fraction": fraction, "label": numbers[i]})
		if i + 1 == numbers.size():
			continue
		var next := float(numbers[i + 1]) * float(band.per)
		for minor in range(1, 4):
			marks.append({"fraction": inverse_lerp(float(band.low), float(band.high),
				lerpf(value, next, minor / 4.0)), "label": ""})
	return marks
