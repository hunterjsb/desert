class_name RadioKitLooks
extends RefCounted
## Radio equipment, modelled in the game's own kit (Paint.Pieces, the worn
## shader), as proposals: three tiers of set, five makers' looks of the one
## the game carries, its modular upgrades and the shortwave aerial's gear.
## Metres; a set's face is +Z, up +Y. Each builder returns one merged mesh,
## its moving parts (needle, knobs) cast in where they'd stand, for looking.
## Moved into the game from look/radio_kit (2026-10-21): the crystal set,
## the field radio's makers' looks, its bay cartridges, the antenna kite and the
## earth stake are catalog devices and parts.
##
## The tiers:
##   - crystal_set: passive AM with an accessory bay; scrap and spare parts,
##     held in the hand with its earpiece.
##   - field_radio: the set the game has, with its sockets made real: a
##     converter bays on its right cheek (FM and shortwave), a battery at its
##     back, a hook boss on top, a miscellaneous bay on its left cheek.
## Its band window glows the band it's scrubbing (bands.gd).

const BANDS := preload("res://game/look/radio_band_looks.gd")

const OFF_WHITE := Color(0.84, 0.82, 0.76)
const ORANGE := Color(0.9, 0.42, 0.1)
const GREY := Color(0.5, 0.52, 0.53)
const COPPER := Color(0.72, 0.38, 0.2)
const OLIVE := Color(0.33, 0.35, 0.24)
const PLATE_RED := Color(0.45, 0.2, 0.14)
const TAPE := Color(0.62, 0.57, 0.45)
const HARDWOOD := Color(0.34, 0.2, 0.11)
const ENAMEL_RED := Color(0.48, 0.08, 0.07)
const TIN := Color(0.66, 0.66, 0.62)
const INK := Color(0.12, 0.09, 0.07)
const RED_NEEDLE := Color(0.9, 0.12, 0.08)
const CANVAS := Color(0.55, 0.49, 0.36)

## The field radio's case.
const FIELD := Vector3(0.32, 0.22, 0.16)
## Its band window: middle height, width, height; the scale across these x.
const BAND_Y := 0.058
const BAND_W := 0.236
const BAND_H := 0.052
const BAND_X := Vector2(-0.105, 0.105)
const KNOB_AT := Vector3(0.06, -0.042, 0.084)
const VOLUME_AT := Vector3(0.11, -0.06, 0.084)
## A module cartridge, as it bolts on a cheek: thick, tall, deep.
const CART := Vector3(0.05, 0.17, 0.13)

## Makers' looks: case, cheeks, trim (bosses, handle), accent (stripes), and
## what the handle is.
const STYLES := {
	&"company": {"label": "Company issue", "case": Paint.TEAL, "cheek": Paint.GUNMETAL, "trim": Paint.GUNMETAL,
		"accent": Paint.YELLOW, "metal": Paint.STEEL},
	&"colonial": {"label": "Colonial survey", "case": OFF_WHITE, "cheek": GREY, "trim": GREY, "accent": ORANGE,
		"metal": Paint.STEEL},
	&"skimmer": {"label": "Skimmer crew", "case": OLIVE, "cheek": PLATE_RED, "trim": Color(0.3, 0.32, 0.31),
		"accent": TAPE, "metal": Paint.STEEL},
	&"kingdoms": {"label": "First Kingdoms", "case": ENAMEL_RED, "cheek": HARDWOOD, "trim": Paint.BRASS,
		"accent": Paint.BRASS, "metal": Paint.BRASS},
	&"second_age": {"label": "Second age", "case": Paint.CERAMIC, "cheek": Paint.SALTWOOD, "trim": Paint.CORD,
		"accent": Paint.GLAZE, "metal": Paint.BRASS},
}


static func coat(color: Color, rough := 0.6, metal := 0.0) -> Paint.Coat:
	return Paint.coat(color, 0.6, metal, rough)


static func glow(color: Color, amount := 1.0) -> Paint.Coat:
	return Paint.coat(color, 0.0, 0.0, 0.4, 0.0, amount)


# --- The field radio -------------------------------------------------------

## The set the game carries, in a maker's look, with what's fitted:
## {"converters": [&"fm", &"sw"] (its converter bay's two slots), or "bay":
## one cartridge; "misc": a module id, "hook": bool, "battery": bool},
## on `band` (lit if `lit`). `bare` is its body alone, for a set in the game:
## no needle, knob caps, signal lamps, band window or side bays, which the
## set's own live parts and sockets stand in for (window()).
static func field_radio(style: StringName, fit := {}, band := &"am", lit := true, bare := false) -> ArrayMesh:
	var b := Paint.Pieces.new()
	_field_radio(b, style, fit, band, lit, bare)
	return b.commit()


static func _field_radio(b: Paint.Pieces, style: StringName, fit: Dictionary, band: StringName, lit: bool,
		bare := false) -> void:
	var s: Dictionary = STYLES[style]
	var size := FIELD
	var h := size * 0.5
	var case := coat(s.case, 0.55)
	var cheek := coat(s.cheek, 0.5, 0.2 if style != &"kingdoms" and style != &"second_age" else 0.0)
	var trim := coat(s.trim, 0.4, 0.6 if s.trim == Paint.BRASS else 0.2)
	var black := coat(Paint.BLACK, 0.7)
	b.box(Vector3(size.x - 0.02, size.y - 0.02, size.z - 0.02), Vector3.ZERO, case, 0.02)
	for x in [-1, 1]:
		b.box(Vector3(0.03, size.y, size.z), Vector3(x * (h.x - 0.015), 0.0, 0.0), cheek, 0.008)
		b.box(Vector3(0.02, 0.04, 0.02), Vector3(x * 0.09, h.y + 0.02, 0.0), trim, 0.004)
	match style:
		&"kingdoms":
			# Restored, kept clean: a brass band round its waist, a fretwork
			# grille for its speaker, a hardwood handle.
			b.box(Vector3(size.x - 0.05, 0.012, size.z - 0.012), Vector3(0.0, 0.022, 0.0), trim, 0.002)
			for i in 6:
				b.box(Vector3(0.006, 0.07, 0.006), Vector3(-0.11 + i * 0.022, -0.045, h.z - 0.003), trim, 0.001)
			b.box(Vector3(0.135, 0.075, 0.004), Vector3(-0.055, -0.045, h.z - 0.006), black, 0.002)
			b.box(Vector3(0.2, 0.022, 0.03), Vector3(0.0, h.y + 0.045, 0.0), coat(HARDWOOD, 0.5), 0.008)
		&"second_age":
			# Rebuilt: its lost corners cast again in salt-glazed ceramic,
			# cord wound round its handle, a blue-glazed charm.
			for x in [-1, 1]:
				for y in [-1, 1]:
					b.ball(0.024, Vector3(x * (h.x - 0.01), y * (h.y - 0.01), h.z - 0.01), coat(Paint.CERAMIC, 0.3))
			for i in 4:
				b.box(Vector3(0.14, 0.01, 0.01), Vector3(-0.055, -0.075 + i * 0.02, h.z - 0.004), black, 0.002)
			b.box(Vector3(0.2, 0.02, 0.025), Vector3(0.0, h.y + 0.045, 0.0), coat(Paint.SALTWOOD, 0.7), 0.006)
			for i in 9:
				b.drum(0.016, 0.006, Vector3(-0.06 + i * 0.015, h.y + 0.045, 0.0), coat(Paint.CORD, 0.9),
					Basis(Vector3.BACK, PI / 2.0), 8)
			b.drum(0.002, 0.05, Vector3(0.09, h.y + 0.02, 0.012), coat(Paint.CORD, 0.9), Basis.IDENTITY, 4)
			b.ball(0.011, Vector3(0.09, h.y - 0.01, 0.014), coat(Paint.GLAZE, 0.2))
		&"skimmer":
			# Kept running by a crew: a plate riveted over a crack, tape round
			# the handle, the slats a bent sheet.
			for i in 4:
				b.box(Vector3(0.14, 0.01, 0.01), Vector3(-0.055, -0.075 + i * 0.02, h.z - 0.004), black, 0.002)
			b.box(Vector3(0.09, 0.06, 0.006), Vector3(-0.07, -0.02, -h.z - 0.001), coat(PLATE_RED, 0.6, 0.3), 0.002,
				Basis(Vector3.BACK, 0.12))
			for p: Vector2 in [Vector2(-0.105, 0.0), Vector2(-0.035, -0.01), Vector2(-0.1, -0.045), Vector2(-0.04, -0.04)]:
				b.drum(0.004, 0.006, Vector3(p.x, p.y, -h.z - 0.004), coat(Paint.STEEL, 0.4, 0.6), Basis(Vector3.RIGHT, PI / 2.0), 6)
			b.box(Vector3(0.2, 0.02, 0.025), Vector3(0.0, h.y + 0.045, 0.0), trim, 0.006)
			for x in [-0.05, 0.03]:
				b.box(Vector3(0.035, 0.026, 0.031), Vector3(x, h.y + 0.045, 0.0), coat(TAPE, 0.9), 0.003)
		_:
			for i in 4:
				b.box(Vector3(0.14, 0.01, 0.01), Vector3(-0.055, -0.075 + i * 0.02, h.z - 0.004), black, 0.002)
			b.box(Vector3(0.2, 0.02, 0.025), Vector3(0.0, h.y + 0.045, 0.0), trim, 0.006)
			if style == &"colonial":
				# Survey stock: an orange band along its top edge.
				b.box(Vector3(size.x - 0.05, 0.012, 0.004), Vector3(0.0, h.y - 0.014, h.z - 0.001), coat(ORANGE, 0.5), 0.001)
	if not bare:
		band_face(b, Vector3(0.0, BAND_Y, h.z), BAND_W, BAND_H, BANDS.of(band), lit, trim)
	for knob: Vector3 in [KNOB_AT, VOLUME_AT]:
		var big := knob == KNOB_AT
		b.drum(0.034 if big else 0.019, 0.016, knob + Vector3(0.0, 0.0, -0.008), trim, Basis(Vector3.RIGHT, PI / 2.0), 16)
		if not bare:
			_knob(b, knob, 1.0 if big else 0.55, 0.7 if big else -0.6, style)
	if not bare:
		_signal_lamps(b, Vector3(-0.1, 0.017, h.z), lit, 5)
		_band_tells(b, Vector3(0.035, 0.017, h.z), fit, band, lit)
	# Its aerial: a whip up from the back.
	b.drum(0.006, 0.3, Vector3(-h.x + 0.045, h.y + 0.15, -h.z + 0.03), coat(Paint.STEEL, 0.3, 0.6), Basis.IDENTITY, 8)
	if bare:
		return
	# The sockets, empty or filled.
	var right := Transform3D(Basis.IDENTITY, Vector3(h.x + CART.x * 0.5, 0.0, 0.0))
	if fit.has("converters"):
		# The converter bay: a half-height slot for each, FM over SW.
		for i in 2:
			var id: StringName = [&"fm", &"sw"][i]
			var slot := Transform3D(Basis.from_scale(Vector3(1.0, 0.5, 1.0)), right.origin + Vector3(0.0, (0.5 - i) * CART.y * 0.5, 0.0))
			if fit.converters.has(id):
				module(b, id, slot, fit.get("burnt", &"") == id)
			else:
				_bay_plate(b, slot, s)
	elif fit.has("bay"):
		module(b, fit.bay, right, fit.get("burnt", &"") == fit.bay)
		if fit.get("burnt", &"") == fit.bay:
			# Soot blown back over the case from the bay.
			for i in 5:
				b.box(Vector3(0.002, 0.02 + i * 0.008, 0.05 - i * 0.006), Vector3(h.x - 0.001, 0.03 - i * 0.012, 0.02 - i * 0.01),
					coat(Color(0.03, 0.03, 0.03), 1.0), 0.0, Basis(Vector3.RIGHT, 0.3 * i))
	else:
		_bay_plate(b, right, s)
	var left := Transform3D(Basis(Vector3.UP, PI), Vector3(-h.x - CART.x * 0.5, 0.0, 0.0))
	if fit.has("misc"):
		module(b, fit.misc, left, fit.get("burnt", &"") == fit.misc)
	else:
		_bay_plate(b, left, s)
	var top := Vector3(0.06, h.y, -0.045)
	if fit.get("hook", false):
		hook(b, Transform3D(Basis.IDENTITY, top))
	else:
		b.drum(0.016, 0.008, top + Vector3(0.0, 0.004, 0.0), trim, Basis.IDENTITY, 12)
		b.drum(0.006, 0.01, top + Vector3(0.0, 0.008, 0.0), black, Basis.IDENTITY, 8)
	if fit.get("battery", false):
		battery_pack(b, Transform3D(Basis.IDENTITY, Vector3(0.03, -0.02, -h.z - 0.03)))


## A field radio's band window and band tells alone, in a maker's look, on
## `band`, lit if `lit`, the tells dim on the other bands in `reach`: the live
## part of a set in the game, built again as it switches band (Radio).
static func window(style: StringName, band: StringName, lit: bool, reach: Array) -> ArrayMesh:
	var b := Paint.Pieces.new()
	var s: Dictionary = STYLES[style]
	var trim := coat(s.trim, 0.4, 0.6 if s.trim == Paint.BRASS else 0.2)
	var h := FIELD * 0.5
	band_face(b, Vector3(0.0, BAND_Y, h.z), BAND_W, BAND_H, BANDS.of(band), lit, trim, -1.0)
	_band_tells(b, Vector3(0.035, 0.017, h.z), {"built_in": reach}, band, lit)
	return b.commit()


## A bay with nothing in it: a cover plate, the cartridge's rails showing.
static func _bay_plate(b: Paint.Pieces, at: Transform3D, s: Dictionary) -> void:
	var dark := coat(Paint.BLACK, 0.7)
	b.box(Vector3(0.006, CART.y - 0.03, CART.z - 0.03), at * Vector3(-CART.x * 0.5 + 0.003, 0.0, 0.0), dark, 0.002, at.basis)
	for y in [-1, 1]:
		b.box(Vector3(0.012, 0.008, CART.z - 0.02), at * Vector3(-CART.x * 0.5 + 0.006, y * (CART.y * 0.5 - 0.01), 0.0),
			coat(s.trim, 0.4, 0.4), 0.002, at.basis)


## Its signal lamps: `n` across from `from`, green to amber, a few lit.
static func _signal_lamps(b: Paint.Pieces, from: Vector3, lit: bool, n: int) -> void:
	for i in 8:
		var c := Color(0.35, 1.0, 0.45).lerp(Color(1.0, 0.75, 0.2), i / 7.0)
		var on := lit and i < n
		b.box(Vector3(0.008, 0.006, 0.003), from + Vector3(i * 0.0115, 0.0, 0.0),
			glow(c, 1.4) if on else coat(c.darkened(0.75), 0.4), 0.0)


## The band tells: AM, FM, SW, each its band's colour; lit on the one it's
## on, dim on another it can reach, capped black where no converter is.
static func _band_tells(b: Paint.Pieces, at: Vector3, fit: Dictionary, band: StringName, lit: bool) -> void:
	for i in 3:
		var tell: Dictionary = BANDS.ALL[i]
		var reach: bool = tell.id == &"am" or fit.get("bay", &"") == tell.id or fit.get("misc", &"") == tell.id \
			or fit.get("built_in", []).has(tell.id) or fit.get("converters", []).has(tell.id)
		var where := at + Vector3(i * 0.022, 0.0, 0.0)
		b.box(Vector3(0.016, 0.01, 0.004), where + Vector3(0.0, 0.0, -0.001), coat(Paint.GUNMETAL, 0.5), 0.001)
		var look: Paint.Coat
		if not reach:
			look = coat(Paint.BLACK, 0.8)
		elif lit and tell.id == band:
			look = glow(tell.glow, 1.6)
		else:
			look = coat(tell.tell.darkened(0.35), 0.4)
		b.box(Vector3(0.012, 0.006, 0.003), where + Vector3(0.0, 0.0, 0.001), look, 0.0)


## A tuning knob: ridged, a cap, a pointer turned to `turn` rad.
static func _knob(b: Paint.Pieces, at: Vector3, scale: float, turn: float, style: StringName) -> void:
	var face := Basis(Vector3.RIGHT, PI / 2.0)
	var body := coat(Paint.BLACK, 0.6)
	var cap := coat(Paint.GUNMETAL, 0.4, 0.3)
	if style == &"kingdoms":
		body = coat(HARDWOOD, 0.4)
		cap = coat(Paint.BRASS, 0.3, 0.7)
	elif style == &"second_age":
		body = coat(Paint.CERAMIC, 0.3)
		cap = coat(Paint.GLAZE, 0.2)
	b.drum(0.026 * scale, 0.02, at + Vector3(0.0, 0.0, 0.002), body, face, 16)
	for i in 12:
		var a := TAU * i / 12.0
		b.box(Vector3(0.004, 0.004, 0.02) * Vector3(scale, scale, 1.0),
			at + Vector3(cos(a), sin(a), 0.0) * 0.026 * scale + Vector3(0.0, 0.0, 0.002), body, 0.0, Basis(Vector3.BACK, a))
	b.drum(0.018 * scale, 0.004, at + Vector3(0.0, 0.0, 0.013), cap, face, 16)
	b.box(Vector3(0.003, 0.016 * scale, 0.002), at + Vector3(-sin(turn), cos(turn), 0.0) * 0.009 * scale + Vector3(0.0, 0.0, 0.016),
		coat(Paint.BONE, 0.4), 0.0, Basis(Vector3.BACK, turn))


## A band window, its middle at `at` on a face turned to +Z: lit in its
## band's colour (or dark), a bezel round it, ticks along its foot, numbered
## for its band, and the needle a third of the way across.
static func band_face(b: Paint.Pieces, at: Vector3, wide: float, high: float, band: Dictionary, lit: bool,
		bezel_look: Paint.Coat, needle := 0.37) -> void:
	var window: Paint.Coat = glow(band.glow, 1.0) if lit else coat(band.dark, 0.5)
	b.box(Vector3(wide, high, 0.014), at + Vector3(0.0, 0.0, -0.005), window, 0.001)
	for s in [-1, 1]:
		b.box(Vector3(wide + 0.016, 0.008, 0.018), at + Vector3(0.0, s * (high * 0.5 + 0.004), -0.003), bezel_look, 0.002)
		b.box(Vector3(0.008, high, 0.018), at + Vector3(s * (wide * 0.5 + 0.004), 0.0, -0.003), bezel_look, 0.002)
	var ink := coat(INK, 0.7)
	var face := at.z + 0.0025
	var foot := -high * 0.3
	var span := wide * 0.89
	b.box(Vector3(span + 0.0014, 0.001, 0.001), Vector3(at.x, at.y + foot, face), ink, 0.0)
	for mark: Dictionary in BANDS.ticks(band):
		var x: float = at.x - span * 0.5 + span * mark.fraction
		var long: bool = not str(mark.label).is_empty()
		var tall := high * (0.21 if long else 0.11)
		b.box(Vector3(0.0014 if long else 0.001, tall, 0.001), Vector3(x, at.y + foot + tall * 0.5, face), ink, 0.0)
		if long:
			numeral(b, mark.label, Vector3(x, at.y + high * 0.15, face), high * 0.21, ink)
	# The band's name in the corner, so a glance says which.
	_letters(b, band.label, Vector3(at.x + wide * 0.5 - 0.016, at.y + high * 0.36, face), high * 0.13, ink)
	if needle < 0.0:
		return
	var nx := at.x - span * 0.5 + span * needle
	b.box(Vector3(0.0022, high - 0.008, 0.002), Vector3(nx, at.y, face + 0.001), glow(RED_NEEDLE, 1.2), 0.0)


## A number in block strokes, `tall` m high, its middle at `at`, facing +Z.
static func numeral(b: Paint.Pieces, text: String, at: Vector3, tall: float, look: Paint.Coat,
		turn := Basis.IDENTITY) -> void:
	# Strokes a to g: top, top right, bottom right, bottom, bottom left, top left, middle.
	const STROKES := {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
		"6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg"}
	const PLACES := {"a": Vector2(0.0, 0.5), "g": Vector2.ZERO, "d": Vector2(0.0, -0.5), "b": Vector2(0.5, 0.25),
		"c": Vector2(0.5, -0.25), "e": Vector2(-0.5, -0.25), "f": Vector2(-0.5, 0.25)}
	var wide := tall * 0.55
	var line := tall * 0.13
	var gap := wide * 0.45
	var widths: Array[float] = []
	var span := -gap
	for digit in text:
		widths.append(line if digit == "1" else wide)
		span += widths[-1] + gap
	var x := -span * 0.5
	for i in text.length():
		for stroke in STROKES[text[i]]:
			var where: Vector2 = PLACES[stroke]
			if text[i] == "1":
				where.x = 0.0
			var size := Vector3(wide + line, line, 0.001) if stroke in "adg" else Vector3(line, tall * 0.5 + line, 0.001)
			var local := Vector3(x + widths[i] * 0.5 + where.x * wide, where.y * tall, 0.0)
			b.box(size, at + turn * local, look, 0.0, turn)
		x += widths[i] + gap


## AM, FM, SW in block strokes: the few letters a band's name needs.
static func _letters(b: Paint.Pieces, text: String, at: Vector3, tall: float, look: Paint.Coat) -> void:
	# Each letter as strokes on a 2 x 4 grid: [x0, y0, x1, y1].
	const SHAPES := {"A": [[0, 0, 0, 3], [2, 0, 2, 3], [0, 4, 2, 4], [0, 2, 2, 2]],
		"M": [[0, 0, 0, 4], [2, 0, 2, 4], [0, 4, 2, 4], [1, 2, 1, 4]],
		"F": [[0, 0, 0, 4], [0, 4, 2, 4], [0, 2, 1.5, 2]],
		"S": [[0, 4, 2, 4], [0, 2, 0, 4], [0, 2, 2, 2], [2, 0, 2, 2], [0, 0, 2, 0]],
		"W": [[0, 0, 0, 4], [2, 0, 2, 4], [0, 0, 2, 0], [1, 0, 1, 2]]}
	var unit := tall / 4.0
	var line := unit * 0.6
	var x := at.x - (text.length() * 3 - 1) * unit * 0.5
	for letter in text:
		for st: Array in SHAPES[letter]:
			var a := Vector2(st[0], st[1]) * unit
			var c := Vector2(st[2], st[3]) * unit
			var mid := (a + c) * 0.5
			var size := Vector3(absf(c.x - a.x) + line, absf(c.y - a.y) + line, 0.001)
			b.box(size, Vector3(x + mid.x, at.y - tall * 0.5 + mid.y, at.z), look, 0.0)
		x += unit * 3.0


# --- Modules ---------------------------------------------------------------

## The modules a bay takes, by id: [label, its tell colour, what it does].
const MODULES := {
	&"fm": ["FM converter", Color(0.2, 0.75, 0.5), "Hears FM: near, clean, no sky wave; storm static barely touches it."],
	&"sw": ["Shortwave converter", Color(0.55, 0.32, 0.9), "Hears shortwave; takes the kite's aerial lead at its port."],
	&"bleed": ["Bleed resistor", Paint.YELLOW, "Bleeds static off the aerial to a trailing earth strap."],
	&"preamp": ["Valve preamp", ORANGE, "Lifts weak signals out of the hiss; draws three times the power."],
	&"loop": ["Direction loop", Paint.STEEL, "Turn it for the null: the carrier's bearing."],
	&"choke": ["Static choke", Color(0.3, 0.55, 0.85), "Takes the edge off a storm's hash, and a little of the signal."],
	&"logger": ["Wire logger", Paint.BONE, "Records what you're tuned to, to play back."],
	&"counter": ["Frequency counter", Color(0.9, 0.25, 0.15), "Reads the exact frequency in glowing digits."],
	&"headset": ["Headset jack", Paint.BLACK, "Listen close: wind and the storm can't drown it."],
	&"solar": ["Solar lid", Color(0.2, 0.3, 0.55), "Trickles a charge into its battery by day."],
}


## A module cartridge, bolted on a bay at `at` (its +X out from the case).
static func module(b: Paint.Pieces, id: StringName, at: Transform3D, burnt := false) -> void:
	var tell: Color = MODULES[id][1]
	var shell := coat(Paint.GUNMETAL, 0.45, 0.3)
	if burnt:
		# Burnt out: its stripe scorched brown, soot up its face, its
		# insides blistered.
		tell = Color(0.2, 0.12, 0.07)
		shell = coat(Color(0.07, 0.06, 0.055), 0.9)
	var dark := coat(Paint.BLACK, 0.7)
	var steel := coat(Paint.STEEL, 0.3, 0.6)
	var t := at.basis
	var p := func(v: Vector3) -> Vector3: return at * v
	var c := CART
	var out := c.x * 0.5
	# The cartridge: a shell, a tell stripe all round its face, two thumb
	# screws to hold it in.
	b.box(c, p.call(Vector3.ZERO), shell, 0.008, t)
	b.box(Vector3(0.004, c.y - 0.02, 0.014), p.call(Vector3(out, 0.0, c.z * 0.5 - 0.016)), coat(tell, 0.4), 0.001, t)
	if burnt:
		for i in 7:
			var y := -0.05 + i * 0.02
			b.box(Vector3(0.003, 0.03, 0.02 + (i % 3) * 0.012), p.call(Vector3(out + 0.002, y + 0.01, -0.02 + sin(i * 2.1) * 0.03)),
				coat(Color(0.02, 0.02, 0.02), 1.0), 0.0, t * Basis(Vector3.RIGHT, sin(i * 1.3) * 0.4))
		b.ball(0.012, p.call(Vector3(out + 0.002, 0.03, -0.01)), coat(Color(0.25, 0.18, 0.12), 0.8), Vector3(0.4, 1.0, 1.4), t)
	for y in [-1, 1]:
		b.drum(0.008, 0.008, p.call(Vector3(out + 0.002, y * (c.y * 0.5 - 0.016), -c.z * 0.5 + 0.018)), steel,
			t * Basis(Vector3.BACK, PI / 2.0), 10)
	match id:
		&"fm":
			# Fins to shed its heat; a stub of coax up from its top.
			for i in 7:
				b.box(Vector3(0.012, 0.003, c.z - 0.05), p.call(Vector3(out + 0.004, -0.06 + i * 0.016, -0.005)), shell, 0.0, t)
			b.drum(0.006, 0.04, p.call(Vector3(0.0, c.y * 0.5 + 0.02, -0.02)), dark, t, 8)
			b.drum(0.008, 0.012, p.call(Vector3(0.0, c.y * 0.5 + 0.04, -0.02)), steel, t, 8)
		&"sw":
			# A window on its toroid coil, and the aerial lead's port: a
			# ceramic standoff with a brass terminal, for the kite's line.
			b.box(Vector3(0.004, 0.07, 0.07), p.call(Vector3(out, 0.012, -0.01)), coat(Color(0.12, 0.14, 0.16), 0.1), 0.002, t)
			b.ring(0.016, 0.026, p.call(Vector3(out - 0.008, 0.012, -0.01)), coat(COPPER, 0.3, 0.7),
				t * Basis(Vector3.BACK, PI / 2.0), 10)
			b.drum(0.012, 0.03, p.call(Vector3(0.0, c.y * 0.5 + 0.015, 0.03)), coat(Paint.CERAMIC, 0.25), t, 10)
			b.drum(0.006, 0.014, p.call(Vector3(0.0, c.y * 0.5 + 0.036, 0.03)), coat(Paint.BRASS, 0.3, 0.7), t, 8)
		&"bleed":
			# A long finned ceramic resistor across its face, a neon that
			# flickers as it bleeds, an earth strap trailing off the bottom.
			b.drum(0.014, 0.12, p.call(Vector3(out + 0.012, 0.0, -0.005)), coat(Paint.CERAMIC, 0.3), t, 10)
			for i in 6:
				b.drum(0.02, 0.004, p.call(Vector3(out + 0.012, -0.045 + i * 0.018, -0.005)), coat(Paint.CERAMIC, 0.3), t, 12)
			b.ball(0.007, p.call(Vector3(out + 0.002, 0.065, 0.04)), glow(Color(1.0, 0.45, 0.2), 1.2))
			# The strap: braid off its foot, out to a clip you put on the earth stake.
			for i in 6:
				b.box(Vector3(0.012, 0.004, 0.03), p.call(Vector3(out + 0.006 + i * 0.012, -c.y * 0.5 + 0.004, 0.02 + i * 0.026)),
					coat(COPPER, 0.4, 0.7), 0.0, t * Basis(Vector3.UP, -0.4))
			b.box(Vector3(0.02, 0.012, 0.03), p.call(Vector3(out + 0.08, -c.y * 0.5 + 0.006, 0.18)), coat(Paint.YELLOW, 0.5), 0.002, t)
		&"preamp":
			# A valve in a cage, its filament glowing.
			b.drum(0.016, 0.012, p.call(Vector3(out + 0.006, -0.02, 0.0)), dark, t * Basis(Vector3.BACK, PI / 2.0), 12)
			b.drum(0.013, 0.07, p.call(Vector3(out + 0.045, -0.02, 0.0)), coat(Color(0.5, 0.55, 0.5), 0.05, 0.2), t * Basis(Vector3.BACK, PI / 2.0), 12)
			b.drum(0.004, 0.04, p.call(Vector3(out + 0.045, -0.02, 0.0)), glow(Color(1.0, 0.5, 0.15), 2.0), t * Basis(Vector3.BACK, PI / 2.0), 6)
			for i in 6:
				var a := TAU * i / 6.0
				b.box(Vector3(0.08, 0.003, 0.003), p.call(Vector3(out + 0.042, -0.02 + cos(a) * 0.02, sin(a) * 0.02)), steel, 0.0, t)
			b.drum(0.024, 0.004, p.call(Vector3(out + 0.082, -0.02, 0.0)), steel, t * Basis(Vector3.BACK, PI / 2.0), 12)
		&"loop":
			# A loop on a turning post, a bearing ring under it.
			b.drum(0.006, 0.05, p.call(Vector3(0.0, c.y * 0.5 + 0.025, 0.0)), steel, t, 8)
			b.ring(0.05, 0.058, p.call(Vector3(0.0, c.y * 0.5 + 0.11, 0.0)), coat(COPPER, 0.3, 0.7), t * Basis(Vector3.RIGHT, PI / 2.0) * Basis(Vector3.FORWARD, 0.4), 12)
			b.drum(0.03, 0.008, p.call(Vector3(0.0, c.y * 0.5 + 0.004, 0.0)), coat(Paint.BONE, 0.4), t, 16)
			for i in 12:
				var a := TAU * i / 12.0
				b.box(Vector3(0.002, 0.002, 0.006), p.call(Vector3(cos(a) * 0.027, c.y * 0.5 + 0.009, sin(a) * 0.027)), dark, 0.0, t * Basis(Vector3.UP, -a))
		&"choke":
			# A choke's can, its windings showing through a slot.
			b.drum(0.032, 0.09, p.call(Vector3(out + 0.02, 0.0, 0.0)), coat(Color(0.3, 0.55, 0.85).darkened(0.3), 0.3, 0.5), t, 14)
			for i in 6:
				b.ring(0.028, 0.034, p.call(Vector3(out + 0.02, -0.03 + i * 0.012, 0.0)), coat(COPPER, 0.3, 0.7), t, 12)
		&"logger":
			# Two reels of wire under a window, a red lamp while it records.
			b.box(Vector3(0.006, 0.11, 0.09), p.call(Vector3(out + 0.001, 0.0, 0.0)), coat(Color(0.12, 0.14, 0.16), 0.1), 0.002, t)
			for y in [-1, 1]:
				b.drum(0.024, 0.01, p.call(Vector3(out + 0.005, y * 0.03, 0.0)), coat(Paint.BONE, 0.4), t * Basis(Vector3.BACK, PI / 2.0), 14)
				b.drum(0.012, 0.012, p.call(Vector3(out + 0.006, y * 0.03, 0.0)), coat(COPPER, 0.3, 0.7), t * Basis(Vector3.BACK, PI / 2.0), 12)
			b.ball(0.006, p.call(Vector3(out + 0.004, 0.068, 0.04)), glow(Color(1.0, 0.2, 0.1), 1.5))
		&"counter":
			# Six glowing digits behind a dark window.
			b.box(Vector3(0.006, 0.05, 0.11), p.call(Vector3(out + 0.001, 0.03, 0.0)), coat(Color(0.05, 0.03, 0.03), 0.1), 0.002, t)
			numeral(b, "1020", p.call(Vector3(out + 0.0045, 0.03, 0.0)), 0.026, glow(Color(1.0, 0.35, 0.12), 2.0),
				t * Basis(Vector3.UP, PI / 2.0))
		&"headset":
			# A jack, and the headset hung on it by its cord.
			b.drum(0.008, 0.012, p.call(Vector3(out + 0.006, 0.04, 0.03)), steel, t * Basis(Vector3.BACK, PI / 2.0), 10)
			b.ring(0.05, 0.058, p.call(Vector3(out + 0.02, -0.02, 0.0)), dark, t * Basis(Vector3.BACK, PI / 2.0), 8)
			for z in [-1, 1]:
				b.drum(0.024, 0.02, p.call(Vector3(out + 0.02, -0.05, z * 0.05)), dark, t * Basis(Vector3.RIGHT, PI / 2.0), 14)
				b.drum(0.02, 0.006, p.call(Vector3(out + 0.02, -0.05, z * 0.062)), coat(Paint.BONE, 0.6), t * Basis(Vector3.RIGHT, PI / 2.0), 14)
		&"solar":
			# A lid of cells, hinged open over the bay.
			var lid := t * Basis(Vector3.BACK, -0.5)
			b.box(Vector3(0.006, c.y + 0.02, c.z), p.call(Vector3(out + 0.03, 0.02, 0.0)), shell, 0.003, lid)
			for i in 3:
				for j in 2:
					b.box(Vector3(0.003, 0.05, 0.055), p.call(Vector3(out + 0.035, 0.02, 0.0)) + lid * Vector3(0.0, -0.056 + i * 0.056, -0.029 + j * 0.058),
						coat(Paint.CELL, 0.2, 0.6), 0.0, lid)
		_:
			pass


## The kite's hook, on its insulator: a stack of ceramic discs (so the
## aerial's charge can't jump to the case) and a steel eye with a snap gate.
static func hook(b: Paint.Pieces, at: Transform3D) -> void:
	var steel := coat(Paint.STEEL, 0.3, 0.7)
	var ceramic := coat(Paint.CERAMIC, 0.25)
	var t := at.basis
	b.drum(0.016, 0.008, at * Vector3(0.0, 0.004, 0.0), coat(Paint.GUNMETAL, 0.4, 0.3), t, 12)
	for i in 3:
		b.drum(0.014, 0.008, at * Vector3(0.0, 0.012 + i * 0.012, 0.0), ceramic, t, 12)
		b.drum(0.009, 0.004, at * Vector3(0.0, 0.018 + i * 0.012, 0.0), ceramic, t, 10)
	b.drum(0.004, 0.02, at * Vector3(0.0, 0.054, 0.0), steel, t, 8)
	b.ring(0.012, 0.017, at * Vector3(0.0, 0.078, 0.0), steel, t * Basis(Vector3.RIGHT, PI / 2.0), 8)
	b.box(Vector3(0.003, 0.016, 0.003), at * Vector3(0.012, 0.074, 0.0), coat(Paint.YELLOW, 0.4), 0.0, t * Basis(Vector3.BACK, 0.4))


## Its battery, the game's own, in a pack at its back.
static func battery_pack(b: Paint.Pieces, at: Transform3D) -> void:
	var t := at.basis
	b.box(Vector3(0.12, 0.09, 0.05), at.origin, coat(Paint.BLACK, 0.6), 0.006, t)
	b.box(Vector3(0.122, 0.018, 0.052), at * Vector3(0.0, 0.02, 0.0), coat(Paint.YELLOW, 0.5), 0.002, t)
	for i in 4:
		b.box(Vector3(0.012, 0.006, 0.004), at * Vector3(-0.03 + i * 0.016, -0.025, -0.026), glow(Color(0.35, 1.0, 0.45), 1.0), 0.0, t)


# --- The crystal set -------------------------------------------------------

## A crystal set: no power, no slots, AM alone and faint. Built from scrap:
## a coil wound on a can, a slider down it to tune, a crystal in a cup
## touched by a cat's whisker, an earpiece on a cord, two posts for an aerial
## and an earth. Held in one hand. `style`: &"scrap" (a tin tray, a food
## can, bell wire) or &"second_age" (a saltwood board, a ceramic former,
## fern cord).
static func crystal_set(style := &"scrap") -> ArrayMesh:
	var b := Paint.Pieces.new()
	var aged := style == &"second_age"
	var base := coat(Paint.SALTWOOD, 0.8) if aged else coat(TIN, 0.4, 0.6)
	var former := coat(Paint.CERAMIC, 0.3) if aged else coat(Color(0.7, 0.62, 0.42), 0.5, 0.3)
	var brass := coat(Paint.BRASS, 0.3, 0.7)
	var copper := coat(COPPER, 0.35, 0.7)
	var dark := coat(Paint.BLACK, 0.7)
	# The tray, its edges turned up.
	b.box(Vector3(0.2, 0.012, 0.13), Vector3.ZERO, base, 0.003)
	if not aged:
		for s in [-1, 1]:
			b.box(Vector3(0.2, 0.014, 0.004), Vector3(0.0, 0.008, s * 0.064), base, 0.001)
			b.box(Vector3(0.004, 0.014, 0.13), Vector3(s * 0.098, 0.008, 0.0), base, 0.001)
	# The coil: wound along a can lying across the tray.
	var along := Basis(Vector3.BACK, PI / 2.0)
	b.drum(0.03, 0.11, Vector3(-0.02, 0.04, -0.02), former, along, 14)
	for i in 22:
		b.ring(0.029, 0.0315, Vector3(-0.07 + i * 0.0048, 0.04, -0.02), copper, along, 12)
	if not aged:
		# The can's rims, and its label's last scrap.
		for s in [-1, 1]:
			b.drum(0.032, 0.004, Vector3(-0.02 + s * 0.055, 0.04, -0.02), coat(TIN, 0.3, 0.7), along, 14)
		b.box(Vector3(0.02, 0.03, 0.002), Vector3(0.03, 0.045, 0.01), coat(Color(0.7, 0.2, 0.12), 0.6), 0.0)
	else:
		for i in 3:
			b.ring(0.03, 0.034, Vector3(-0.06 + i * 0.04, 0.04, -0.02), coat(Paint.CORD, 0.9), along, 10)
	# The slider: a rod over the coil, its wiper touching the turns, its
	# knob painted with a scrap of an AM band, the amber it reaches.
	for x in [-0.08, 0.04]:
		b.box(Vector3(0.006, 0.08, 0.006), Vector3(x, 0.045, 0.012), brass, 0.001)
	b.drum(0.003, 0.13, Vector3(-0.02, 0.083, 0.012), brass, along, 8)
	b.box(Vector3(0.012, 0.014, 0.016), Vector3(0.0, 0.076, 0.012), dark, 0.002)
	b.box(Vector3(0.003, 0.012, 0.003), Vector3(0.0, 0.069, 0.004), copper, 0.0)
	b.box(Vector3(0.1, 0.008, 0.002), Vector3(-0.02, 0.016, 0.06), coat(BANDS.AM.tell, 0.5), 0.0)
	for i in 5:
		b.box(Vector3(0.0012, 0.006, 0.001), Vector3(-0.065 + i * 0.022, 0.017, 0.0612), coat(INK, 0.7), 0.0)
	# The detector: a crystal in a cup, the whisker on an arm over it.
	b.drum(0.012, 0.012, Vector3(0.06, 0.012, 0.035), brass, Basis.IDENTITY, 12)
	b.ball(0.008, Vector3(0.06, 0.02, 0.035), coat(Color(0.25, 0.27, 0.3), 0.15, 0.8), Vector3(1.0, 0.7, 1.0))
	b.drum(0.004, 0.035, Vector3(0.085, 0.03, 0.035), brass, Basis.IDENTITY, 8)
	b.drum(0.002, 0.03, Vector3(0.072, 0.045, 0.035), brass, Basis(Vector3.BACK, PI / 2.0), 6)
	b.drum(0.0007, 0.024, Vector3(0.064, 0.034, 0.035), copper, Basis(Vector3.BACK, 0.5), 4)
	b.ball(0.008, Vector3(0.088, 0.05, 0.035), dark)
	# The binding posts: aerial and earth, bell wire coiled off one.
	for z in [-0.045, -0.02]:
		b.drum(0.006, 0.02, Vector3(0.08, 0.016, z), brass, Basis.IDENTITY, 8)
		b.drum(0.009, 0.006, Vector3(0.08, 0.026, z), dark, Basis.IDENTITY, 10)
	for i in 3:
		b.ring(0.018, 0.021, Vector3(0.115, 0.01 + i * 0.004, -0.045), copper, Basis(Vector3.RIGHT, 0.1), 10)
	# The earpiece, on its cord.
	b.drum(0.018, 0.014, Vector3(-0.055, 0.017, 0.045), dark, Basis.IDENTITY, 14)
	b.drum(0.012, 0.004, Vector3(-0.055, 0.026, 0.045), coat(Paint.BONE, 0.6), Basis.IDENTITY, 14)
	for i in 6:
		b.drum(0.002, 0.022, Vector3(-0.035 + i * 0.012, 0.009, 0.045 - sin(i * 0.9) * 0.012), dark,
			Basis(Vector3.BACK, PI / 2.0) * Basis(Vector3.RIGHT, cos(i * 0.9) * 0.6), 4)
	return b.commit()

