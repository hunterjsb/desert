class_name DeliveryshipLooks
extends RefCounted
## Frontier Ag's deliveryship (Constellation &"deliveryship"), the deliveryship that fires
## the care packages, modelled: drawn in the sky by Deliveryship. The colonial
## survey style (art direction, shape by era: rounded, chamfered, modular;
## off-white, grey and safety orange) in the game's own kit, so it wears the
## worn shader like every device. Seen from the ground it's an H: two long
## nacelles, sharp at both ends, joined by a thin hull.
##
## Each nacelle is a faceted hexagonal hull with a keel along its belly, so
## a low sun splits it into a lit plane and a shaded one. It's built in
## stages like a rocket's, each its own tone (an off-white nose, a grey body
## panelled in two greys, a dark aft section, a steel tail with three
## engine bells), orange bands at the joins. Under each keel runs the
## survey fairing, its row of lenses looking down at the crops; outboard, a
## pair of tanks in a cradle steps its outline; on top, a swept fin and a
## sensor dome. The hull between the nacelles is a ribbed spine flanked by
## open trusses (the sky shows through them), with four solar arrays, and
## at its heart the care-package cannon: a drum ringed with the packages it
## fires, its barrel pointing at the ground. Off to one side an uplink dish
## hangs on a boom, turned to the ground it reports on.
##
## Against the bright day sky it's a dark shape; what tells you it's built
## is the paint's big blocks of tone and the sun on its facets.
## Metres; front -Z, up +Y, across +X. Its middle is at the origin.

## Half the span between the nacelles' centre lines, and its whole span.
const APART := 160.0
const SPAN := 410.0
## A nacelle's sections from nose to tail: [z, half-width, stage]. Sharp at both ends.
const NACELLE := [[-150.0, 0.0, &"white"], [-112.0, 13.0, &"hull"], [-60.0, 24.0, &"panels"],
	[30.0, 24.0, &"dark"], [95.0, 18.0, &"steel"], [138.0, 9.0, &""]]
## Hexagonal section, flattened: wider than it's deep.
const FLAT := 0.62
## The cannon drum's radius and depth, and the barrel's length below it.
const DRUM := 40.0
const DRUM_DEEP := 28.0
const BARREL := 30.0
## Where the muzzle is, for the flash.
const MUZZLE := Vector3(0.0, -DRUM_DEEP * 0.5 - BARREL - 2.0, 0.0)

static var _made := {}
static var _flash: ArrayMesh


## The kit, built near or far. Far, for when the whole craft is a couple of
## hundred pixels across or less: no chamfers (a chamfered box is 44
## triangles, a plain one 12), round things with half their sides, and the
## parts smaller than a pixel left off (b.fine). What still shows that far
## (the panelling's two greys, the arrays' white grid) stays.
class CraftKit:
	var b := Paint.Pieces.new()
	var fine := true

	func box(size: Vector3, at: Vector3, look: Paint.Coat, cut := 0.01, turn := Basis.IDENTITY) -> void:
		b.box(size, at, look, cut if fine else 0.0, turn)

	func drum(radius: float, height: float, at: Vector3, look: Paint.Coat, turn := Basis.IDENTITY, sides := 16,
			top := -1.0) -> void:
		b.drum(radius, height, at, look, turn, sides if fine else maxi(5, sides / 2), top)

	func ball(radius: float, at: Vector3, look: Paint.Coat, scale := Vector3.ONE, turn := Basis.IDENTITY) -> void:
		if fine:
			b.ball(radius, at, look, scale, turn)
		else:
			b.drum(radius, radius * 2.0 * scale.y, at, look, turn, 6)


static func _coats() -> Dictionary:
	return {"hull": Paint.coat(Paint.HULL_PALE, 0.3, 0.0, 0.7), "hull_2": Paint.coat(Paint.HULL_MID, 0.3, 0.0, 0.7),
		"dark": Paint.coat(Paint.CHARCOAL, 0.3, 0.0, 0.65), "shade": Paint.coat(Paint.HULL_SHADE, 0.2, 0.0, 0.8),
		"white": Paint.coat(Paint.OFF_WHITE, 0.4, 0.0, 0.5), "grey": Paint.coat(Paint.GUNMETAL.lightened(0.25), 0.4, 0.2, 0.5),
		"orange": Paint.coat(Paint.SAFETY_ORANGE, 0.4, 0.0, 0.5), "black": Paint.coat(Paint.BLACK, 0.1, 0.2, 0.6),
		"steel": Paint.coat(Paint.STEEL, 0.3, 0.45, 0.32),
		"lens": Paint.coat(Paint.CELL, 0.0, 0.4, 0.12, 0.0),
		"cells": Paint.coat(Paint.CELL.lightened(0.08), 0.0, 0.3, 0.25, 0.0)}


## The whole craft in one mesh, near or far (CraftKit).
static func craft(far := false) -> ArrayMesh:
	if _made.has(far):
		return _made[far]
	var c := _coats()
	var b := CraftKit.new()
	b.fine = not far
	for side in [-1.0, 1.0]:
		_nacelle(b, c, side)
	_hull(b, c)
	_arrays(b, c)
	_cannon(b, c)
	_dish(b, c)
	_made[far] = b.b.commit()
	return _made[far]


## The muzzle flash, on its own so it can light alone: a white disc.
static func flash() -> ArrayMesh:
	if _flash != null:
		return _flash
	var b := Paint.Pieces.new()
	b.drum(9.0, 1.0, MUZZLE, Paint.coat(Color.WHITE, 0.0, 0.0, 0.3, 0.0, 6.0), Basis.IDENTITY, 12)
	_flash = b.commit()
	return _flash


## A frustum along z from section a to section b: hexagonal, flattened,
## turned so a corner points down (the keel) and one up (the spine).
static func _frustum(b: CraftKit, x: float, za: float, wa: float, zb: float, wb: float, look: Paint.Coat) -> void:
	var turn := Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, PI / 6.0 + PI * 0.5)
	turn = Basis.from_scale(Vector3(1.0, FLAT, 1.0)) * turn
	b.drum(maxf(wa, 0.05), zb - za, Vector3(x, 0.0, (za + zb) * 0.5), look, turn, 6, maxf(wb, 0.05))


static func _width_at(z: float) -> float:
	for i in NACELLE.size() - 1:
		var a: Array = NACELLE[i]
		var n: Array = NACELLE[i + 1]
		if z >= a[0] and z <= n[0]:
			return lerpf(a[1], n[1], (z - a[0]) / (n[0] - a[0]))
	return 0.0


static func _nacelle(b: CraftKit, c: Dictionary, side: float) -> void:
	var x := side * APART
	# The stages, the middle one panelled in two greys, 18 m a panel.
	for i in NACELLE.size() - 1:
		var a: Array = NACELLE[i]
		var n: Array = NACELLE[i + 1]
		if a[2] == &"panels":
			var panels := 5
			for k in panels:
				var z0: float = lerpf(a[0], n[0], float(k) / panels)
				var z1: float = lerpf(a[0], n[0], float(k + 1) / panels)
				_frustum(b, x, z0, _width_at(z0), z1, _width_at(z1), c.hull if k % 2 == 0 else c.hull_2)
		else:
			_frustum(b, x, a[0], a[1], n[0], n[1], c.hull if a[2] == &"panels" else c[a[2]])
	# Orange bands at the joins, a little proud.
	for z in [-112.0, -60.0, 30.0, 95.0]:
		var w := _width_at(z) + 0.8
		_frustum(b, x, z - 2.5, w, z + 2.5, _width_at(z + 2.5) + 0.8, c.orange)
	# The off-white dorsal spine, the swept fin with an orange tip, the dome.
	b.box(Vector3(4.0, 2.4, 210.0), Vector3(x, 24.0 * FLAT - 0.4, -10.0), c.white, 0.8)
	var fin := Basis(Vector3.RIGHT, -0.5)
	b.box(Vector3(2.4, 30.0, 44.0), Vector3(x, 24.0 * FLAT + 12.0, 72.0), c.white, 1.0, fin)
	b.box(Vector3(2.6, 6.0, 44.0), Vector3(x, 24.0 * FLAT + 12.0, 72.0) + fin * Vector3(0.0, 13.0, 0.0), c.orange, 0.6, fin)
	if b.fine:
		b.ball(7.0, Vector3(x, 24.0 * FLAT + 1.0, -40.0), c.white, Vector3(1.0, 0.6, 1.0))
	# Outboard, a pair of long tanks in an orange cradle: they step its outline.
	for z in [-34.0, 34.0]:
		var at := Vector3(x + side * 30.0, -3.0, z)
		b.drum(8.0, 60.0, at, c.white, Basis(Vector3.RIGHT, PI * 0.5), 10)
		for e in [-1.0, 1.0]:
			b.drum(8.0, 4.0, at + Vector3(0.0, 0.0, e * 31.0), c.orange, Basis(Vector3.RIGHT, PI * 0.5), 10, 4.0)
		for k in ([-1.0, 0.0, 1.0] if b.fine else [0.0]):
			b.box(Vector3(18.0, 3.0, 3.0), Vector3(x + side * 21.0, -4.0, z + k * 20.0), c.grey, 0.6)
	# The survey fairing under the keel: a long dark pod, its lenses looking down.
	var keel := -24.0 * FLAT
	b.box(Vector3(11.0, 6.0, 150.0), Vector3(x, keel - 1.5, -20.0), c.shade, 2.0)
	for i in (9 if b.fine else 0):
		var z := -85.0 + i * 16.0
		b.drum(2.6, 1.2, Vector3(x, keel - 4.6, z), c.lens, Basis.IDENTITY, 10)
		b.drum(3.3, 0.8, Vector3(x, keel - 4.3, z), c.steel, Basis.IDENTITY, 10)
	# The engines at the tail: three bells in a steel collar, dark inside.
	b.drum(9.0, 6.0, Vector3(x, 0.0, 141.0), c.steel, Basis(Vector3.RIGHT, PI * 0.5), 12)
	for k in (3 if b.fine else 0):
		var off := Vector3(cos(k * TAU / 3.0 + 0.5) * 4.6, sin(k * TAU / 3.0 + 0.5) * 4.6 * FLAT, 0.0)
		b.drum(3.4, 9.0, Vector3(x, 0.0, 148.0) + off, c.grey, Basis(Vector3.RIGHT, PI * 0.5), 10, 4.4)
		b.drum(3.0, 0.5, Vector3(x, 0.0, 152.6) + off, c.black, Basis(Vector3.RIGHT, PI * 0.5), 10)
	# Thruster blocks at the nose and the tail, either side.
	for z in ([-95.0, 110.0] if b.fine else []):
		for s in [-1.0, 1.0]:
			b.box(Vector3(5.0, 5.0, 8.0), Vector3(x + s * (_width_at(z) + 1.5), 0.0, z), c.dark, 0.8)
			b.box(Vector3(1.0, 2.0, 2.0), Vector3(x + s * (_width_at(z) + 4.2), 0.0, z), c.black, 0.0)
	# Intakes at the nose's shoulders, and a probe out ahead of it.
	b.box(Vector3(2.0, 6.0, 30.0), Vector3(x - side * 17.0, 1.0, -84.0), c.black, 0.4,
		Basis(Vector3.UP, side * 0.22))
	if b.fine:
		b.drum(0.9, 50.0, Vector3(x, 0.0, -172.0), c.steel, Basis(Vector3.RIGHT, PI * 0.5), 6, 0.3)
	b.drum(3.2, 9.0, Vector3(x, 0.0, -146.0), c.black, Basis(Vector3.RIGHT, PI * 0.5), 8, 0.6)
	# An aerial trailing off the tail, swept out and down: it shows which
	# way it flies.
	_beam(b, Vector3(x + side * 6.0, -3.0, 150.0), Vector3(x + side * 26.0, -12.0, 205.0), 1.0, c.steel)
	b.ball(2.2, Vector3(x + side * 26.0, -12.0, 205.0), c.orange)


static func _hull(b: CraftKit, c: Dictionary) -> void:
	var inner := APART - 20.0
	# The spine: grey, an off-white strip along its back, dark ribs.
	b.box(Vector3(inner * 2.0, 12.0, 26.0), Vector3.ZERO, c.hull, 2.5)
	b.box(Vector3(inner * 2.0, 1.2, 7.0), Vector3(0.0, 6.5, 0.0), c.white, 0.4)
	for i in (10 if b.fine else 5):
		var x := -inner + 14.0 + i * (inner * 2.0 - 28.0) / (9.0 if b.fine else 4.0)
		b.box(Vector3(3.5, 14.0, 28.0), Vector3(x, 0.0, 0.0), c.dark, 0.8)
	# Open trusses fore and aft: off-white rails, grey braces in a zigzag, so
	# the sky shows through them.
	for zs in [-1.0, 1.0]:
		var z: float = zs * 26.0
		for y in [-3.0, 3.0]:
			b.box(Vector3(inner * 2.0 - 10.0, 2.4, 2.4), Vector3(0.0, y, z), c.white, 0.4)
		var bays := 12 if b.fine else 6
		for i in bays:
			var x0 := -inner + 5.0 + i * (inner * 2.0 - 10.0) / bays
			var x1 := x0 + (inner * 2.0 - 10.0) / bays
			_beam(b, Vector3(x0, 3.0, z), Vector3(x1, -3.0, z), 1.4, c.grey)
			_beam(b, Vector3(x1, 3.0, z), Vector3(x1, -3.0, z), 1.4, c.grey)
		for i in (6 if b.fine else 0):
			var x := -inner + 20.0 + i * (inner * 2.0 - 40.0) / 5.0
			_beam(b, Vector3(x, -2.0, zs * 9.0), Vector3(x, 0.0, z), 1.6, c.grey)
	# Braces out to each nacelle, and an orange mount where each meets it.
	for side in [-1.0, 1.0]:
		for zs in [-1.0, 1.0]:
			_beam(b, Vector3(side * (inner - 30.0), -2.0, zs * 26.0), Vector3(side * (APART - 22.0), -2.0, zs * 60.0), 2.4, c.dark)
			b.box(Vector3(8.0, 8.0, 8.0), Vector3(side * (APART - 22.0), -2.0, zs * 60.0), c.orange, 1.0)
		b.box(Vector3(12.0, 14.0, 32.0), Vector3(side * (APART - 18.0), 0.0, 0.0), c.orange, 1.5)


## Four solar arrays between the trusses: deep blue cells in a white frame,
## tilted a little to the sun. The one patch of colour on it besides orange.
static func _arrays(b: CraftKit, c: Dictionary) -> void:
	for side in [-1.0, 1.0]:
		for zs in [-1.0, 1.0]:
			var mid := Vector3(side * 92.0, -4.0, zs * 47.0)
			var tilt := Basis(Vector3.RIGHT, zs * 0.18)
			b.box(Vector3(72.0, 0.8, 32.0), mid, c.white, 0.3, tilt)
			# The cells' white grid still shows far off: kept, they're plain boxes.
			for row in 2:
				for col in 4:
					var at := mid + tilt * Vector3(-27.0 + col * 18.0, -0.5, -7.5 + row * 15.0)
					b.box(Vector3(16.5, 0.8, 13.5), at, c.cells, 0.0, tilt)
			_beam(b, mid + tilt * Vector3(0.0, 0.0, -zs * 16.0), Vector3(side * 92.0, 0.0, zs * 26.0), 1.4, c.grey)


## The uplink dish on its boom off the spine, turned down toward the ground
## it reports on: the one round thing on it, off to one side.
static func _dish(b: CraftKit, c: Dictionary) -> void:
	var root := Vector3(-40.0, -6.0, 12.0)
	var head := Vector3(-46.0, -24.0, 92.0)
	_beam(b, root, head, 3.0, c.grey)
	b.ball(4.0, head, c.orange)
	# Its wide face down, tipped a little back along the track.
	var face := Basis(Vector3.RIGHT, 0.4) * Basis(Vector3.UP, 0.3)
	var at := head + face * Vector3(0.0, -4.0, 0.0)
	b.drum(26.0, 3.0, at, c.white, face, 18, 18.0)
	b.drum(17.0, 1.0, at + face * Vector3(0.0, -2.0, 0.0), c.hull_2, face, 18)
	b.drum(1.4, 16.0, at + face * Vector3(0.0, -9.0, 0.0), c.steel, face, 6)
	b.ball(2.4, at + face * Vector3(0.0, -17.0, 0.0), c.dark)


static func _cannon(b: CraftKit, c: Dictionary) -> void:
	# The drum, its orange band and an off-white cap on top.
	b.drum(DRUM, DRUM_DEEP, Vector3.ZERO, c.hull, Basis.IDENTITY, 16)
	b.drum(DRUM + 0.8, 4.0, Vector3(0.0, 4.0, 0.0), c.orange, Basis.IDENTITY, 16)
	b.drum(DRUM * 0.7, 3.0, Vector3(0.0, DRUM_DEEP * 0.5 + 1.5, 0.0), c.white, Basis.IDENTITY, 16, DRUM * 0.55)
	# The care packages, racked round the drum's underside: orange and white.
	for i in 12:
		var a := i * TAU / 12.0
		var at := Vector3(cos(a), 0.0, sin(a)) * (DRUM - 9.0) + Vector3(0.0, -DRUM_DEEP * 0.5 - 5.0, 0.0)
		b.box(Vector3(11.0, 10.0, 15.0), at, c.orange if i % 2 == 0 else c.white, 1.0, Basis(Vector3.UP, -a))
	b.drum(DRUM - 2.0, 2.0, Vector3(0.0, -DRUM_DEEP * 0.5 - 0.5, 0.0), c.shade, Basis.IDENTITY, 16)
	# The barrel, pointing at the ground, an orange ring at its muzzle.
	b.drum(7.0, BARREL, Vector3(0.0, -DRUM_DEEP * 0.5 - BARREL * 0.5, 0.0), c.steel, Basis.IDENTITY, 12, 5.5)
	b.drum(7.5, 3.0, MUZZLE + Vector3(0.0, 2.5, 0.0), c.orange, Basis.IDENTITY, 12)
	b.drum(4.5, 0.6, MUZZLE + Vector3(0.0, 1.0, 0.0), c.black, Basis.IDENTITY, 12)


static func _beam(b: CraftKit, from: Vector3, to: Vector3, wide: float, look: Paint.Coat) -> void:
	var d := to - from
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var turn := Basis(x, y, x.cross(y))
	b.box(Vector3(wide, d.length(), wide), (from + to) * 0.5, look, wide * 0.15, turn)
