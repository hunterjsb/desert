extends RefCounted
## The three bands a radio can scrub, each its own colour, so you can tell at
## a glance which you're on: the band window glows it, the needle's scale is
## numbered for it, and a converter's tell stripe wears it. (A proposal: the
## game's dial today is AM alone, 0 to 2000 kHz.)
##
## AM is the dial the game has: the gods, the music, the beacon, the
## satellites' own carriers. FM is short-range and clean: line of sight,
## no sky wave, so a station is loud near and gone past the horizon, and
## storm static barely touches it (it's frequency, not amplitude). Shortwave
## bounces off the sky: far voices, faint and fading, heard best from an
## aerial flown high (the antenna kite).
## (No class_name: the lab keeps out of the game's global classes.)

## [id, label, lowest, highest, unit, scale numbers, glow colour (the window),
## tell colour (stripes, switch), dark colour (the window when off)]
const AM := {"id": &"am", "label": "AM", "low": 0.0, "high": 2000.0, "unit": "kHz",
	"numbers": ["0", "5", "10", "15", "20"], "per": 100.0,
	"glow": Color(1.0, 0.82, 0.55), "tell": Color(0.95, 0.62, 0.18), "dark": Color(0.42, 0.33, 0.2)}
const FM := {"id": &"fm", "label": "FM", "low": 88.0, "high": 108.0, "unit": "MHz",
	"numbers": ["88", "92", "96", "100", "104", "108"], "per": 1.0,
	"glow": Color(0.62, 1.0, 0.78), "tell": Color(0.2, 0.75, 0.5), "dark": Color(0.2, 0.36, 0.28)}
const SW := {"id": &"sw", "label": "SW", "low": 2.0, "high": 26.0, "unit": "MHz",
	"numbers": ["2", "6", "10", "14", "18", "22", "26"], "per": 1.0,
	"glow": Color(0.8, 0.66, 1.0), "tell": Color(0.55, 0.32, 0.9), "dark": Color(0.3, 0.24, 0.4)}
const ALL := [AM, FM, SW]


static func of(id: StringName) -> Dictionary:
	for band: Dictionary in ALL:
		if band.id == id:
			return band
	return AM
