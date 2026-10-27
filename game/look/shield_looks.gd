class_name ShieldLooks
extends RefCounted
## The shield generators (Dress): the shield maker's emitter, its lit collar
## the generator's own, between a housing and a cap. Whose hands the base
## shield passed through shows in its shape (art direction, "Shape by era").
## Colonial: a crisp, deep-chamfered housing, off-white panels in dark frames,
## grey corner caps and safety orange under a rounded-rectangle cap. The
## skimmer era's: the same, hand-painted crew red, taped, a scrap plate welded
## on and a guard over its lens. The First Kingdoms kept the housing whole and
## dressed it: brass rails and a filigree vent, a brim on brass posts crested
## at its corners, a flared copper cap. The second age lost the cap and rebuilt
## it round in salt-glazed ceramic, off its axis, bound it in fern cord and
## mended the housing in saltbush wood, ceramic and limewash. The light shield
## is the maker's own, bought new: round, bone white, finned, carried by its
## handle.

const IDS: Array[StringName] = [&"shield", &"light_shield"]

## The eras whose hands gave the base shield a shape of its own; any other is
## colonial make, the company's issue too.
const SHAPES := {Eras.SKIMMER: &"skimmer", Eras.FIRST: &"first", Eras.SECOND: &"second"}
const BACK := Basis(Vector3.UP, PI)
## The base shield's faces in turn from +Z, its port's (+X) second.
const FACES := 4
## The base shield's emitter neck, narrow enough that a lineage's band finds
## its deck (Paint.Shell): its collar rings it.
const NECK := 0.12


static var _eras := {}


## A thing's look in the shape the era of its last hands gave it, for its
## lineage's marks to go on (Dress); null where it keeps its own.
static func lineage(id: StringName, line: Array) -> ArrayMesh:
	var era := Eras.era_of(line)
	return look(id, era) if id == &"shield" and SHAPES.has(era) else null


## The base shield in an era's shape, made once.
static func look(id: StringName, era: StringName) -> ArrayMesh:
	var key := [id, era]
	if not _eras.has(key):
		var size: Vector3 = Catalog.DEVICES[id].size
		var b := Paint.Pieces.new(-size.y * 0.5)
		frame(b, id, size, era)
		_eras[key] = b.commit()
	return _eras[key]


## Draws a shield's look into its pieces, in an era's shape where it has one;
## false for an id that isn't one.
static func frame(b: Paint.Pieces, id: StringName, size: Vector3, era := Eras.NEW, _extra := 0.0) -> bool:
	match id:
		&"shield":
			var shape: StringName = SHAPES.get(era, &"")
			_housing(b, size, shape)
			match shape:
				&"first":
					_first(b, size)
				&"second":
					_second(b, size)
				&"skimmer":
					_skimmer(b, size)
				_:
					_colonial(b, size)
		&"light_shield":
			_light(b, size)
		_:
			return false
	return true


## A shield generator's lit collar (ShieldGenerator): its middle's height and
## its radius, a little proud of the body it rings.
static func collar(id: StringName, size: Vector3) -> Vector2:
	return Vector2(size.y * 0.2, (NECK if id == &"shield" else size.x * 0.44) + 0.006)


## The base shield's deck, under its collar.
static func _deck(size: Vector3) -> float:
	return collar(&"shield", size).x - 0.028


## Where its cap starts, over its collar.
static func _cap(size: Vector3) -> float:
	return collar(&"shield", size).x + 0.03


## The housing's body's half width, in from its box so what later hands
## bound on stays inside it.
static func _body(size: Vector3) -> float:
	return size.x * 0.5 - 0.016


## The housing's body, from over its skid to under its deck.
static func _span(size: Vector3) -> Vector2:
	return Vector2(-size.y * 0.5 + 0.032, _deck(size) - 0.02)


## Whether a housing panel, by face and side, is gone in this shape: the vent's
## front, the second age's slats on the left and its patch in front, by the port.
static func _lost(shape: StringName, k: int, side: float) -> bool:
	match shape:
		&"first":
			return k == 0
		&"second":
			return k == 3 or k == 0 and side > 0.0
	return false


## The housing every era kept: a skid on rubber feet, a deep-chamfered dark
## body framing modular panels, grey caps on its corners, a grey service pad
## behind its port and a deck under the collar. Its body's top and bottom are
## banded flat, so a lineage's plaque sits on its faces. The skimmer era
## painted its panels crew red with a pale stripe; the second age lost a
## corner cap.
static func _housing(b: Paint.Pieces, size: Vector3, shape: StringName) -> void:
	var h := size * 0.5
	var crew := shape == &"skimmer"
	var panel := Paint.coat(SkimmerKit.PLATE_RED, 0.9, 0.0, 0.55) if crew else Paint.coat(ColonialKit.PANEL, 0.5, 0.1, 0.5)
	var grey := Paint.coat(ColonialKit.GREY, 0.6, 0.4, 0.45)
	var dark := Paint.coat(ColonialKit.DARK, 0.4, 0.3, 0.5)
	var stripe := Paint.coat(Paint.BONE, 0.7) if crew else Paint.coat(ColonialKit.ORANGE, 0.7, 0.0, 0.5)
	var rubber := Paint.rubber()
	var lo := _span(size).x
	var hi := _span(size).y
	var w := _body(size)
	b.box(Vector3(size.x - 0.03, 0.026, size.z - 0.03), Vector3(0.0, -h.y + 0.02, 0.0), dark, 0.008)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(0.07, 0.02, 0.07), Vector3(sx * (h.x - 0.05), -h.y + 0.01, sz * (h.z - 0.05)), rubber, 0.005)
			for y in [lo + 0.022, hi - 0.022]:
				if shape == &"second" and sx < 0.0 and sz > 0.0 and y > 0.0:
					continue
				b.box(Vector3(0.07, 0.044, 0.07), Vector3(sx * (w - 0.03), y, sz * (w - 0.03)), grey, 0.012)
	b.box(Vector3(w * 2.0, hi - lo, w * 2.0), Vector3(0.0, (lo + hi) * 0.5, 0.0), dark, 0.03)
	for y in [lo + 0.015, hi - 0.015]:
		b.box(Vector3(w * 2.0, 0.03, w * 2.0), Vector3(0.0, y, 0.0), dark, 0.008)
	b.box(Vector3(size.x - 0.01, 0.022, size.z - 0.01), Vector3(0.0, _deck(size) - 0.011, 0.0), grey, 0.006)
	b.drum(NECK, 0.06, Vector3(0.0, _deck(size) + 0.028, 0.0), dark, Basis.IDENTITY, 16)
	# The panels between the corner caps, two a side, the port's pad between
	# narrow ones; a stripe over them.
	var mid := (lo + hi) * 0.5
	var tall := hi - lo - 0.1
	for k in FACES:
		var turn := Basis(Vector3.UP, k * PI * 0.5)
		if k == 1:
			b.box(Vector3(0.15, 0.15, h.x - w + 0.004), turn * Vector3(0.0, -0.05, (h.x + w - 0.004) * 0.5), grey, 0.004, turn)
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.062, tall, 0.01), turn * Vector3(s * 0.121, mid, w + 0.002), panel, 0.003, turn)
			continue
		for s in [-1.0, 1.0]:
			if _lost(shape, k, s):
				continue
			# The contractor's tag that fitted it, on its back.
			if k == 2 and s > 0.0:
				b.stamp(Paint.Mark.CONTRACTOR, turn * Vector3(s * 0.083, mid + 0.012, w + 0.007), 0.12, turn)
			# The crew's patch, painted by hand on its front.
			elif crew and k == 0 and s > 0.0:
				b.stamp(Paint.Mark.SKIMMER_CREW, turn * Vector3(s * 0.083, mid + 0.006, w + 0.007), 0.12, turn, Paint.Ink.PALE)
			b.box(Vector3(0.14, tall, 0.01), turn * Vector3(s * 0.083, mid, w + 0.002), panel, 0.003, turn)
		if not _lost(shape, k, 1.0):
			b.box(Vector3(0.24, 0.012, 0.006), turn * Vector3(0.0, hi - 0.039, w + 0.001), stripe, 0.002, turn)


## Colonial: a rounded-rectangle cap, off-white on a dark frame, with
## safety-orange ends and the maker's sign small on its back, the emitter's
## dark lens in a grey bezel on top.
static func _colonial(b: Paint.Pieces, size: Vector3, crew := false) -> void:
	var base := _cap(size)
	var panel := Paint.coat(SkimmerKit.PLATE_RED, 0.9, 0.0, 0.55) if crew else Paint.coat(ColonialKit.PANEL, 0.5, 0.1, 0.5)
	var ends := Paint.tape() if crew else Paint.coat(ColonialKit.ORANGE, 0.7, 0.0, 0.5)
	var dark := Paint.coat(ColonialKit.DARK, 0.4, 0.3, 0.5)
	var black := Paint.black()
	b.box(Vector3(0.31, 0.012, 0.23), Vector3(0.0, base + 0.004, 0.0), dark, 0.004)
	b.stamp(Paint.Mark.SHIELD_MAKER, Vector3(0.0, base + 0.034, -0.105), 0.075, BACK, Paint.Ink.PALE)
	b.box(Vector3(0.29, 0.05, 0.21), Vector3(0.0, base + 0.034, 0.0), panel, 0.014)
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.014, 0.036, 0.15), Vector3(s * 0.146, base + 0.034, 0.0), ends, 0.004)
		for i in 3:
			b.box(Vector3(0.008, 0.004, 0.12), Vector3(s * (0.096 + i * 0.014), base + 0.059, 0.0), black, 0.0)
	_lens(b, base + 0.059, 0.07, Paint.coat(ColonialKit.GREY, 0.6, 0.4, 0.45))


## The emitter's dark lens, domed, in a bezel.
static func _lens(b: Paint.Pieces, y: float, radius: float, bezel: Paint.Coat) -> void:
	b.drum(radius + 0.01, 0.01, Vector3(0.0, y + 0.002, 0.0), bezel, Basis.IDENTITY, 24)
	b.ball(radius, Vector3(0.0, y, 0.0), Paint.coat(Paint.CELL, 0.0, 0.4, 0.15, 0.4), Vector3(1.0, 0.48, 1.0))


## The skimmer era's: the colonial cap repainted crew red with its ends taped,
## tape round its corner caps, a scrap plate welded over its left side and a
## steel guard welded over its lens.
static func _skimmer(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var w := _body(size)
	var lo := _span(size).x
	var hi := _span(size).y
	var tape := Paint.tape()
	var scrap := Paint.scrap()
	var steel := Paint.coat(Paint.STEEL, 0.8, 0.7, 0.45)
	_colonial(b, size, true)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(0.074, 0.016, 0.074), Vector3(sx * (w - 0.03), hi - 0.024, sz * (w - 0.03)), tape, 0.004)
	var left := Basis(Vector3.UP, PI * 1.5)
	var plate := left * Basis(Vector3.BACK, -0.05)
	b.box(Vector3(0.22, 0.1, 0.006), left * Vector3(-0.02, (lo + hi) * 0.5 - 0.004, w + 0.01), scrap, 0.002, plate)
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.006, 0.1, 0.006), left * Vector3(-0.02 + s * 0.11, (lo + hi) * 0.5 - 0.004 + s * 0.005, w + 0.012),
			steel, 0.0, plate)
	var top := _cap(size) + 0.059
	for x in [-0.05, 0.05]:
		var foot := Vector3(x, top, 0.085)
		var crown := Vector3(x, top + 0.026, 0.0)
		b.strand(foot, crown, 0.008, steel)
		b.strand(crown, Vector3(x, top, -0.085), 0.008, steel)


## First Kingdoms: the colonial housing kept clean, brass rails up its edges
## and a brass filigree vent in its front, a square brim on brass posts crested
## at its corners where a house's enamel runs round its edge, and a flared
## copper cap.
static func _first(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var base := _cap(size)
	var panel := Paint.coat(ColonialKit.PANEL, 0.5, 0.1, 0.5)
	var brass := Paint.brass()
	var copper := Paint.coat(Paint.COPPER, 0.3, 0.85, 0.4, 0.5)
	var black := Paint.black()
	var w := _body(size)
	var lo := _span(size).x
	var hi := _span(size).y
	var mid := (lo + hi) * 0.5
	var tall := hi - lo - 0.094
	# The vent: a dark grille behind a brass frame, two diamond lattices and rosettes.
	var face := w + 0.004
	b.box(Vector3(0.29, tall - 0.008, 0.004), Vector3(0.0, mid, w + 0.001), black, 0.0)
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.3, 0.01, 0.008), Vector3(0.0, mid + s * (tall * 0.5 - 0.005), face), brass, 0.002)
		b.box(Vector3(0.01, tall, 0.008), Vector3(s * 0.145, mid, face), brass, 0.002)
		var half := Vector2(0.067, tall * 0.5 - 0.009)
		for way in [Vector2(1.0, 1.0), Vector2(1.0, -1.0)]:
			b.bars(Basis.IDENTITY, Vector3(s * 0.073, mid, face - 0.001), half, way.normalized(), 0.026, brass)
		b.drum(0.016, 0.006, Vector3(s * 0.073, mid, face + 0.003), brass, Basis(Vector3.RIGHT, PI / 2.0), 8)
	b.box(Vector3(0.008, tall, 0.008), Vector3(0.0, mid, face), brass, 0.002)
	# Brass rails up the chamfered edges between the corner caps, and posts
	# from the deck's corners to the brim's.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var turn := Basis(Vector3.UP, atan2(sx, sz))
			b.box(Vector3(0.016, hi - lo - 0.088, 0.008), Vector3(sx * (w - 0.013), mid, sz * (w - 0.013)), brass, 0.002, turn)
			b.box(Vector3(0.014, base - _deck(size), 0.014), Vector3(sx * (h.x - 0.03), (base + _deck(size)) * 0.5, sz * (h.z - 0.03)),
				brass, 0.003)
	# The brim, railed in brass under its edge, its corners crested.
	b.box(Vector3(size.x - 0.01, 0.016, size.z - 0.01), Vector3(0.0, base + 0.008, 0.0), panel, 0.005)
	for k in FACES:
		var turn := Basis(Vector3.UP, k * PI * 0.5)
		b.box(Vector3(size.x - 0.03, 0.008, 0.008), turn * Vector3(0.0, base - 0.002, h.z - 0.011), brass, 0.002, turn)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var corner := Vector3(sx * (h.x - 0.03), base + 0.016, sz * (h.z - 0.03))
			b.drum(0.016, 0.012, corner + Vector3.UP * 0.006, brass, Basis.IDENTITY, 8)
			b.drum(0.012, 0.04, corner + Vector3.UP * 0.032, brass, Basis.IDENTITY, 8, 0.0)
	b.drum(0.124, 0.008, Vector3(0.0, base + 0.02, 0.0), brass, Basis.IDENTITY, 24)
	b.drum(0.12, 0.046, Vector3(0.0, base + 0.047, 0.0), copper, Basis.IDENTITY, 24, 0.072)
	_lens(b, base + 0.07, 0.052, brass)


## Second age: the cap lost and rebuilt round in salt-glazed ceramic, off its
## axis, seated in a coil of bare ceramic with a sand-glass eye and corded
## down; the lost corner cap rebuilt rounded in ceramic, saltbush slats where
## the left side's panels were under a rounded saltbush rail lashed on,
## limewash where a front panel was with an oval ceramic-backed glass over a
## hole; cord wound round three sides and its edges, knotted at the
## port's corners, one charm of cord, bead and tassel hanging.
static func _second(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var base := _cap(size)
	var glazed := Paint.glazed()
	var bare := Paint.coat(Paint.CERAMIC, 0.1, 0.0, 0.85, 0.8)
	var cord := Paint.cord()
	var wood := Paint.saltwood()
	var lime := Paint.coat(Paint.LIMEWASH, 0.4, 0.0, 0.85, 0.8)
	var w := _body(size)
	var lo := _span(size).x
	var hi := _span(size).y
	# The dome, banded as it was coiled, leaning a little.
	var at := Vector3(-0.025, base, 0.02)
	var lean := Basis(Vector3(1.0, 0.0, 1.0).normalized(), 0.08)
	var radius := 0.148
	var high := h.y - base - 0.01
	var bands := 5
	for i in bands:
		var a0 := float(i) / bands * PI * 0.5
		var a1 := float(i + 1) / bands * PI * 0.5
		var y0 := sin(a0) * high
		var y1 := sin(a1) * high
		b.drum(cos(a0) * radius, y1 - y0, at + lean * Vector3(0.0, (y0 + y1) * 0.5, 0.0), glazed, lean, 20, cos(a1) * radius)
	b.ring(radius - 0.022, radius + 0.004, at + Vector3(0.0, 0.002, 0.0), bare, Basis.IDENTITY, 8)
	var eye := Vector2(-0.032, 0.018)
	var eye_y := sqrt(1.0 - eye.length_squared() / (radius * radius)) * high
	b.drum(0.022, 0.012, at + lean * Vector3(eye.x, eye_y, eye.y), Paint.coat(Paint.SAND_GLASS, 0.0, 0.2, 0.12, 0.3), lean, 12)
	for a in [PI * 0.25, PI * 0.75]:
		var out := Vector3(cos(a), 0.0, sin(a))
		var steps := 8
		for i in steps:
			var p0 := _over(at, lean, out, radius + 0.004, high + 0.004, PI * i / steps)
			var p1 := _over(at, lean, out, radius + 0.004, high + 0.004, PI * (i + 1) / steps)
			b.strand(p0, p1, 0.007, cord)
	# The lost corner cap, rebuilt rounded in glazed ceramic.
	var corner := Vector3(-(w - 0.03), hi - 0.026, w - 0.03)
	b.drum(0.036, 0.03, corner, glazed, Basis.IDENTITY, 12)
	b.drum(0.036, 0.02, corner + Vector3.UP * 0.025, glazed, Basis.IDENTITY, 12, 0.018)
	# Saltbush slats over the left side, each a little off true.
	var left := Basis(Vector3.UP, PI * 1.5)
	var slats := [[0.30, 0.0, 0.03], [0.27, 0.012, -0.04], [0.31, -0.006, 0.02], [0.26, 0.01, -0.025]]
	for i in slats.size():
		var slat: Array = slats[i]
		var y: float = lo + 0.056 + i * 0.027
		b.box(Vector3(slat[0], 0.023, 0.008), left * Vector3(slat[1], y, w + 0.004), wood, 0.003,
			left * Basis(Vector3.BACK, slat[2]))
	# A rounded saltbush rail over the slats, lashed on at its ends and middle.
	var rail := lo + 0.056 + (slats.size() - 1) * 0.027 + 0.0205
	var along := left * Basis(Vector3.BACK, PI / 2.0)
	b.drum(0.007, 0.33, left * Vector3(0.0, rail, w + 0.007), wood, along, 8)
	for z in [-0.14, 0.0, 0.14]:
		for i in 3:
			b.drum(0.0088, 0.005, left * Vector3(z + (i - 1) * 0.006, rail, w + 0.007), cord, along, 6)
	# Limewash where a front panel was, laid on by hand, and an oval of
	# sand-glass backed in ceramic over the hole under it.
	var mid := (lo + hi) * 0.5
	b.box(Vector3(0.15, 0.12, 0.004), Vector3(0.086, mid + 0.004, w + 0.002), lime, 0.0015, Basis(Vector3.BACK, -0.05))
	b.box(Vector3(0.09, 0.05, 0.005), Vector3(0.11, mid - 0.04, w + 0.0025), lime, 0.0015, Basis(Vector3.BACK, 0.12))
	var oval := Vector3(0.09, mid + 0.012, w + 0.002)
	b.ball(0.042, oval, glazed, Vector3(0.75, 1.0, 0.3))
	b.ball(0.03, oval + Vector3(0.0, 0.0, 0.005), Paint.coat(Paint.SAND_GLASS, 0.0, 0.2, 0.12, 0.3), Vector3(0.7, 1.0, 0.25))
	# Cord wound three times round the back, the left and the front, then round
	# the port's two edges and knotted there.
	for turn_i in 3:
		var y := lo + 0.048 + turn_i * 0.0075
		for k in [0, 2]:
			var face := Basis(Vector3.UP, k * PI * 0.5)
			b.box(Vector3(w * 2.0 - 0.056, 0.006, 0.006), face * Vector3(0.0, y, w + 0.011), cord, 0.0, face)
		b.box(Vector3(0.006, 0.006, w * 2.0 - 0.056), Vector3(-(w + 0.011), y, 0.0), cord, 0.0)
		for sz in [-1.0, 1.0]:
			b.strand(Vector3(-(w - 0.028), y, sz * (w + 0.011)), Vector3(-(w + 0.011), y, sz * (w - 0.028)), 0.006, cord)
	for sz in [-1.0, 1.0]:
		var edge := Vector3(w - 0.013, 0.0, sz * (w - 0.013))
		for i in 4:
			b.drum(0.026, 0.007, edge + Vector3.UP * (lo + 0.045 + i * 0.008), cord, Basis.IDENTITY, 6)
		var knot := Vector3(w - 0.006, lo + 0.08, sz * (w - 0.006))
		b.box(Vector3.ONE * 0.016, knot, cord, 0.004, Basis(Vector3.UP, PI * 0.25))
		if sz > 0.0:
			var bead := knot + Vector3(0.012, -0.04, 0.012)
			b.strand(knot, bead, 0.004, cord)
			b.ball(0.009, bead, glazed)
			for k in [-1.0, 0.0, 1.0]:
				b.strand(bead, bead + Vector3(k * 0.007, -0.035, k * -0.004), 0.003, cord)


## A point on a cord laid over the dome, `a` from one side round to the other.
static func _over(at: Vector3, lean: Basis, out: Vector3, radius: float, high: float, a: float) -> Vector3:
	return at + lean * (out * cos(a) * radius + Vector3.UP * sin(a) * high)


## The light shield, the maker's own: a gunmetal foot on rubber, a round bone
## body finned in gunmetal with its port on a pad, seamed, slotted under its
## shoulder, the maker's sign between two fins at its back, the emitter on top
## under a rubber-gripped carry handle. Its round body is where a lineage's
## marks go (Catalog.ROUND).
static func _light(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var r := h.x * 0.88
	var bone := Paint.coat(Paint.BONE, 0.4)
	var gun := Paint.coat(Paint.GUNMETAL)
	var black := Paint.black()
	var rubber := Paint.rubber()
	var foot := -h.y
	b.drum(h.x * 0.95, 0.028, Vector3(0.0, foot + 0.016, 0.0), gun, Basis.IDENTITY, 32, h.x * 0.9)
	for i in 4:
		var turn := Basis(Vector3.UP, PI * 0.25 + i * PI * 0.5)
		b.box(Vector3(0.04, 0.012, 0.03), turn * Vector3(0.0, foot + 0.006, h.x * 0.72), rubber, 0.003, turn)
	b.stamp(Paint.Mark.SHIELD_MAKER, Vector3(0.0, -0.02, -r), 0.09, BACK)
	b.drum(r, 0.104 - (foot + 0.028), Vector3(0.0, (0.104 + foot + 0.028) * 0.5, 0.0), bone, Basis.IDENTITY, 32)
	for y in [-0.105, 0.03]:
		b.drum(r + 0.0015, 0.003, Vector3(0.0, y, 0.0), black, Basis.IDENTITY, 32)
	for i in 8:
		var turn := Basis(Vector3.UP, i * TAU / 8.0 + PI / 8.0)
		b.box(Vector3(0.012, 0.13, 0.026), turn * Vector3(0.0, -0.03, r + 0.011), gun, 0.004, turn)
		b.box(Vector3(0.026, 0.012, 0.018), turn * Vector3(0.0, -0.1, r + 0.007), gun, 0.003, turn)
	b.box(Vector3(0.03, 0.1, 0.09), Vector3(h.x - 0.015, -0.04, 0.0), gun, 0.006)
	var top := collar(&"light_shield", size).x + 0.025
	for i in 16:
		var turn := Basis(Vector3.UP, i * TAU / 16.0)
		b.box(Vector3(0.016, 0.006, 0.004), turn * Vector3(0.0, top + 0.008, r + 0.001), black, 0.0, turn)
	b.drum(r, 0.02, Vector3(0.0, 0.114, 0.0), bone, Basis.IDENTITY, 32, r * 0.8)
	b.drum(0.098, 0.01, Vector3(0.0, 0.127, 0.0), gun, Basis.IDENTITY, 32)
	b.ball(0.07, Vector3(0.0, 0.128, 0.0), Paint.coat(Paint.CELL, 0.0, 0.4, 0.15, 0.4), Vector3(1.0, 0.26, 1.0))
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.014, 0.032, 0.022), Vector3(s * 0.088, 0.142, 0.0), bone, 0.004)
	b.box(Vector3(0.19, 0.012, 0.024), Vector3(0.0, 0.153, 0.0), rubber, 0.005)
