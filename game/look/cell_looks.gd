class_name CellLooks
extends RefCounted
## The company's commodity parts (Dress): cells, line ends, the water canister
## and the lamp, each standing out of its socket along +Z. One vocabulary on
## all of them: a moulded case, a collar in its socket kind's colour where it
## seats so it reads through dust and storm, moulded grips, capped terminals,
## and a window under each live charge light. Whose hands a find passed through
## shows in its shape (art direction, "Shape by era"): the company's issue in
## dark moulding, colonial make the same in bone with grey caps and safety
## orange, the First Kingdoms' kept clean with brass fittings, flared caps and
## filigree, a skimmer crew's painted rust, welded and lashed, and the second
## age's lost pieces rebuilt in ceramic, saltbush and cord.

const IDS: Array[StringName] = [&"battery", &"big_battery", &"plug", &"strong_plug", &"hose_end", &"hook", &"canister",
	&"lamp"]
const ALONG := Basis(Vector3.RIGHT, PI / 2.0)
const ACROSS := Basis(Vector3.BACK, PI / 2.0)
static var _eras := {}


static func part(b: Paint.Pieces, id: StringName, size: Vector3, era := Eras.NEW) -> bool:
	match id:
		&"battery": _battery(b, size, era)
		&"big_battery": _big_battery(b, size, era)
		&"plug": _plug(b, size, era)
		&"strong_plug": _strong_plug(b, size, era)
		&"hose_end": _hose_end(b, size, era)
		&"hook": _hook(b, size, era)
		&"canister": _canister(b, size, era)
		&"lamp": _lamp(b, size, era)
		_: return false
	return true


## A part's look in the shape its last hands' era gave it, made once, for its
## lineage's marks to go on (Dress); null for anything else.
static func lineage(id: StringName, line: Array) -> ArrayMesh:
	if not IDS.has(id):
		return null
	var key := [id, Eras.era_of(line)]
	if not _eras.has(key):
		var b := Paint.Pieces.new()
		part(b, id, Catalog.PARTS[id].size, key[1])
		_eras[key] = b.commit()
	return _eras[key]


## The moulded case: the company's dark composite, colonial bone (the First
## Kingdoms kept it clean), a skimmer crew's rust paint, bone long weathered.
static func _case(era: StringName) -> Paint.Coat:
	match era:
		Eras.COLONIAL, Eras.FIRST:
			return Paint.coat(Paint.BONE, 0.5, 0.1, 0.5)
		Eras.SKIMMER:
			return Paint.coat(Paint.RUST, 0.9, 0.0, 0.6)
		Eras.SECOND:
			return Paint.coat(Paint.BONE, 0.9, 0.0, 0.7)
	return Paint.coat(Paint.MOULDED, 0.5, 0.1, 0.65)


## Caps, lids and fittings: gunmetal, the First Kingdoms' brass, a crew's bare
## welded steel.
static func _fitting(era: StringName) -> Paint.Coat:
	match era:
		Eras.FIRST:
			return _brass()
		Eras.SKIMMER:
			return _steel()
	return Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5)


## Its socket kind's colour, kept bright under dust so a part reads by kind.
static func _collar(kind: StringName) -> Paint.Coat:
	return Paint.coat(Catalog.KINDS[kind], 0.3, 0.1, 0.45, 0.35)


static func _black() -> Paint.Coat:
	return Paint.coat(Paint.BLACK, 0.25, 0.1, 0.8)


static func _rubber() -> Paint.Coat:
	return Paint.coat(Paint.BLACK, 0.2, 0.0, 0.85)


static func _steel() -> Paint.Coat:
	return Paint.coat(Paint.STEEL, 0.6, 0.8, 0.45)


static func _brass() -> Paint.Coat:
	return Paint.coat(Paint.BRASS, 0.3, 0.9, 0.35, 0.5)


static func _orange() -> Paint.Coat:
	return Paint.coat(Paint.DROP_ORANGE, 0.6, 0.0, 0.5)


static func _ceramic() -> Paint.Coat:
	return Paint.coat(Paint.CERAMIC, 0.15, 0.0, 0.3, 0.6)


static func _cord() -> Paint.Coat:
	return Paint.coat(Paint.CORD, 0.0, 0.0, 0.95, 0.7)


static func _wood() -> Paint.Coat:
	return Paint.coat(Paint.SALTWOOD, 0.1, 0.0, 0.85, 0.6)


static func _rope() -> Paint.Coat:
	return Paint.coat(Paint.ROPE, 0.3, 0.0, 0.9)


## A straight length of bar or cord from one point to another.
static func _strand(b: Paint.Pieces, from: Vector3, to: Vector3, thick: float, look: Paint.Coat) -> void:
	var along := to - from
	var y := along.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	b.box(Vector3(thick, along.length() + thick, thick), (from + to) * 0.5, look, 0.0, Basis(x, y, x.cross(y)))


## A band laid round a box's sides at `z`: cord, rope or a crew's lashing.
static func _band(b: Paint.Pieces, half: Vector2, z: float, thick: float, look: Paint.Coat) -> void:
	for s in [-1.0, 1.0]:
		b.box(Vector3(half.x * 2.0 + thick * 2.0, thick, thick), Vector3(0.0, s * (half.y + thick * 0.5), z), look, 0.0)
		b.box(Vector3(thick, half.y * 2.0, thick), Vector3(s * (half.x + thick * 0.5), 0.0, z), look, 0.0)


## The window the live charge light sits over (ChargeLight, placed by the
## catalog proud of `at`): dark glass recessed in a raised rim, so it reads as
## a gauge lit or dark. The face it sits on stands at `at.z` - 0.008.
static func _window(b: Paint.Pieces, at: Vector3, wide: float, rim: Paint.Coat, glass: Paint.Coat) -> void:
	b.box(Vector3(wide + 0.012, 0.03, 0.004), at - Vector3(0.0, 0.0, 0.006), glass, 0.0)
	for s in [-1.0, 1.0]:
		b.box(Vector3(wide + 0.016, 0.006, 0.008), at + Vector3(0.0, s * 0.018, -0.004), rim, 0.002)
		b.box(Vector3(0.006, 0.042, 0.008), at + Vector3(s * (wide * 0.5 + 0.007), 0.0, -0.004), rim, 0.002)


static func _glass(era: StringName) -> Paint.Coat:
	return Paint.coat(Paint.SAND_GLASS if era == Eras.SECOND else Paint.CELL, 0.0, 0.3, 0.15, 0.3)


## A capped terminal on a face whose top is `at`: a shroud and its cap, the
## live one in safety yellow (colonial orange, First Kingdoms brass flared).
static func _terminal(b: Paint.Pieces, at: Vector3, era: StringName, live: bool) -> void:
	b.drum(0.017, 0.006, at - Vector3(0.0, 0.0, 0.005), _black(), ALONG, 12)
	match era:
		Eras.FIRST:
			b.drum(0.01, 0.006, at - Vector3(0.0, 0.0, 0.003), _brass(), ALONG, 12, 0.015)
		Eras.SKIMMER:
			# A cap long lost: the bare stud, a nut run down it.
			b.drum(0.005, 0.008, at - Vector3(0.0, 0.0, 0.004), _steel(), ALONG, 6)
			b.drum(0.009, 0.003, at - Vector3(0.0, 0.0, 0.0065), _steel(), ALONG, 6)
		Eras.SECOND:
			b.ball(0.011, at - Vector3(0.0, 0.0, 0.006), _ceramic(), Vector3(1.0, 1.0, 0.55))
		_:
			var cap := (_orange() if era == Eras.COLONIAL else Paint.coat(Paint.YELLOW, 0.5)) if live else _fitting(era)
			b.drum(0.012, 0.006, at - Vector3(0.0, 0.0, 0.003), cap, ALONG, 12)


## A filigree vent the First Kingdoms set in a face: a brass frame round a
## zigzag, in the face turned by `turn` at `at`.
static func _filigree(b: Paint.Pieces, at: Vector3, turn: Basis, wide: float, tall: float) -> void:
	var brass := _brass()
	for s in [-1.0, 1.0]:
		b.box(Vector3(wide, 0.004, 0.004), at + turn * Vector3(0.0, s * tall * 0.5, 0.0), brass, 0.001, turn)
		b.box(Vector3(0.004, tall, 0.004), at + turn * Vector3(s * wide * 0.5, 0.0, 0.0), brass, 0.001, turn)
	var n := 6
	for i in n:
		var x0 := -wide * 0.5 + wide * i / n
		var x1 := x0 + wide / n
		var y0 := tall * (0.38 if i % 2 == 0 else -0.38)
		_strand(b, at + turn * Vector3(x0, y0, 0.0), at + turn * Vector3(x1, -y0, 0.0), 0.003, brass)


## The cell: a slim moulded slab on its amber collar, moulded grip ribs at its
## ends, grey corner caps over a lid with its charge window and two capped
## terminals. Told from the big one by its flush face and slim edge.
static func _battery(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var face := size.z
	var case := _case(era)
	var fitting := _fitting(era)
	b.box(Vector3(size.x - 0.006, size.y - 0.006, 0.016), Vector3(0.0, 0.0, 0.008), _collar(&"battery"), 0.008)
	b.box(Vector3(size.x - 0.012, size.y - 0.012, 0.092), Vector3(0.0, 0.0, 0.062), case, 0.016)
	# The lid; a crew welded a plate where theirs was lost, the second age a board.
	match era:
		Eras.SKIMMER:
			b.box(Vector3(size.x - 0.03, size.y - 0.022, 0.006), Vector3(0.004, -0.002, 0.109), _steel(), 0.001,
				Basis(Vector3.BACK, 0.035))
			for at in [Vector2(-0.085, 0.045), Vector2(0.09, -0.05), Vector2(-0.08, -0.05)]:
				b.box(Vector3(0.012, 0.006, 0.004), Vector3(at.x, at.y, 0.112), _steel(), 0.001)
		Eras.SECOND:
			b.box(Vector3(size.x - 0.03, size.y - 0.03, 0.008), Vector3(0.0, 0.0, 0.108), _wood(), 0.003,
				Basis(Vector3.BACK, -0.02))
		_:
			b.box(Vector3(size.x - 0.026, size.y - 0.026, 0.008), Vector3(0.0, 0.0, 0.108), _black() if era == Eras.NEW
				else fitting, 0.005)
	_window(b, Vector3(0.0, size.y * 0.3, face), size.x * 0.7, _cord() if era == Eras.SECOND else _black(), _glass(era))
	for s in [-1.0, 1.0]:
		var at := Vector3(s * 0.064, -0.028, face)
		if era == Eras.SECOND and s < 0.0:
			# The lost cap rebuilt round in ceramic, off its axis, over this terminal.
			b.ball(1.0, Vector3(-0.05, -0.026, face - 0.011), _ceramic(), Vector3(0.05, 0.034, 0.011))
			continue
		_terminal(b, at, era, s > 0.0)
	# Corner caps over the lid; a crew lost two, the second age one.
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			if era == Eras.SKIMMER and sx < 0.0 or era == Eras.SECOND and sx < 0.0 and sy < 0.0:
				continue
			b.box(Vector3(0.022, 0.022, 0.02), Vector3(sx * (h.x - 0.011), sy * (h.y - 0.011), face - 0.01),
				_brass() if era == Eras.FIRST else Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5), 0.004)
	# Moulded grips at its ends; lashed in their place by a crew, corded on one by the second age.
	var grip := _rubber() if era == Eras.NEW else Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5)
	for s in [-1.0, 1.0]:
		if era == Eras.SKIMMER or era == Eras.SECOND and s < 0.0:
			continue
		for z in [0.042, 0.058, 0.074, 0.09]:
			b.box(Vector3(0.006, size.y - 0.05, 0.007), Vector3(s * (h.x - 0.003), 0.0, z), grip, 0.0015)
	# Its long sides: moulded grip ribs, a brass vent on a house's.
	for s in [-1.0, 1.0]:
		if era == Eras.FIRST:
			_filigree(b, Vector3(0.0, s * (h.y - 0.004), 0.066), Basis(Vector3.RIGHT, -s * PI / 2.0), 0.12, 0.05)
		elif era != Eras.SKIMMER:
			for z in [0.05, 0.066, 0.082]:
				b.box(Vector3(0.12, 0.005, 0.006), Vector3(0.0, s * (h.y - 0.0035), z), grip, 0.0015)
	match era:
		Eras.SKIMMER:
			for z in [0.05, 0.085]:
				_band(b, Vector2(h.x - 0.006, h.y - 0.006), z, 0.005, _rope())
		Eras.SECOND:
			for i in 3:
				_band(b, Vector2(h.x - 0.006, h.y - 0.006), 0.052 + i * 0.008, 0.004, _cord())


## The big pack: square-shouldered on a deeper collar, rubber bumpers down its
## four edges, cooling fins at its ends, a bail handle across its face beside
## the charge window, and its terminals in square shrouds.
static func _big_battery(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var face := size.z
	var case := _case(era)
	var fitting := _fitting(era)
	var metal := Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5)
	b.box(Vector3(size.x - 0.006, size.y - 0.006, 0.022), Vector3(0.0, 0.0, 0.011), _collar(&"battery"), 0.008)
	b.box(Vector3(size.x - 0.016, size.y - 0.016, 0.138), Vector3(0.0, 0.0, 0.091), case, 0.01)
	b.box(Vector3(size.x - 0.05, size.y - 0.04, 0.008), Vector3(0.0, 0.0, 0.158), _black() if era == Eras.NEW else metal, 0.004)
	# The window's boss, raised to the light.
	b.box(Vector3(0.21, 0.046, 0.012), Vector3(0.0, size.y * 0.3, 0.166), _black() if era == Eras.NEW else metal, 0.004)
	_window(b, Vector3(0.0, size.y * 0.3, face), size.x * 0.7, _cord() if era == Eras.SECOND else _black(), _glass(era))
	# Bumpers down its edges; a crew welded an angle where one went.
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var at := Vector3(sx * (h.x - 0.015), sy * (h.y - 0.015), 0.1)
			if era == Eras.SKIMMER and sx < 0.0 and sy > 0.0:
				b.box(Vector3(0.03, 0.006, 0.156), at + Vector3(0.0, 0.012, 0.0), _steel(), 0.001)
				b.box(Vector3(0.006, 0.03, 0.156), at + Vector3(-0.012, 0.0, 0.0), _steel(), 0.001)
				continue
			if era == Eras.SECOND and sx > 0.0 and sy > 0.0:
				# Rebuilt rounded in ceramic.
				b.drum(0.015, 0.156, at, _ceramic(), ALONG, 10)
				continue
			b.box(Vector3(0.03, 0.03, 0.156), at, _rubber() if era == Eras.NEW else metal, 0.006)
			if era == Eras.FIRST:
				b.drum(0.012, 0.008, Vector3(at.x, at.y, face - 0.004), _brass(), ALONG, 10, 0.0145)
	# Fins at its ends; a crew's scrap plate over one, the second age's limewash.
	for s in [-1.0, 1.0]:
		if era == Eras.SKIMMER and s < 0.0:
			b.box(Vector3(0.006, size.y - 0.07, 0.11), Vector3(s * (h.x - 0.006), 0.004, 0.094), Paint.coat(Paint.GUNMETAL, 1.0, 0.4, 0.6),
				0.001, Basis(Vector3.RIGHT, 0.06))
			continue
		if era == Eras.SECOND and s < 0.0:
			b.box(Vector3(0.006, size.y - 0.07, 0.1), Vector3(s * (h.x - 0.007), 0.0, 0.09), Paint.coat(Paint.LIMEWASH, 0.4, 0.0, 0.85, 0.8),
				0.002)
			continue
		for i in 6:
			b.box(Vector3(0.008, size.y - 0.07, 0.006), Vector3(s * (h.x - 0.004), 0.0, 0.05 + i * 0.018), metal, 0.0015)
		if era == Eras.FIRST:
			for z in [0.04, 0.148]:
				b.box(Vector3(0.006, size.y - 0.064, 0.006), Vector3(s * (h.x - 0.003), 0.0, z), _brass(), 0.001)
	# The bail handle over its face: safety orange for colonial make, a crew's
	# rope loop, the second age's saltbush bar corded on.
	var bar := Vector3(0.0, -0.035, face - (0.01 if era == Eras.SECOND else 0.008))
	match era:
		Eras.SKIMMER:
			for i in 5:
				var a0 := PI * i / 5.0
				var a1 := PI * (i + 1) / 5.0
				_strand(b, bar + Vector3(-cos(a0) * 0.07, 0.0, sin(a0) * 0.006 - 0.004),
					bar + Vector3(-cos(a1) * 0.07, 0.0, sin(a1) * 0.006 - 0.004), 0.008, _rope())
		Eras.SECOND:
			b.drum(0.008, 0.16, bar, _wood(), ACROSS, 8)
			for s in [-1.0, 1.0]:
				for i in 3:
					b.drum(0.0095, 0.004, bar + Vector3(s * (0.075 + (i - 1) * 0.006), 0.0, 0.0), _cord(), ACROSS, 6)
		_:
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.016, 0.02, 0.018), bar + Vector3(s * 0.08, 0.0, -0.001), fitting, 0.003)
			b.drum(0.008, 0.144, bar, _orange() if era == Eras.COLONIAL else _rubber(), ACROSS, 10)
	# Square terminal shrouds under the handle.
	for s in [-1.0, 1.0]:
		var at := Vector3(s * 0.05, -h.y + 0.024, face - 0.008)
		b.box(Vector3(0.03, 0.022, 0.01), at - Vector3(0.0, 0.0, 0.005), _black(), 0.003)
		_terminal(b, at + Vector3(0.0, 0.0, 0.006), era, s > 0.0)
	if era == Eras.SECOND:
		for i in 3:
			_band(b, Vector2(h.x - 0.008, h.y - 0.008), 0.06 + i * 0.008, 0.004, _cord())


## The plug: round, its seat in the port's orange, a fluted moulded grip
## tapering to a ringed strain-relief boot. Told from the strong plug by its
## round taper.
static func _plug(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var body := _rubber() if era == Eras.NEW or era == Eras.SECOND else _case(era)
	b.drum(size.x * 0.5, 0.014, Vector3(0.0, 0.0, 0.007), _collar(&"port"), ALONG, 16)
	b.drum(0.027, 0.004, Vector3(0.0, 0.0, 0.016), _fitting(era), ALONG, 16, 0.03 if era == Eras.FIRST else -1.0)
	b.drum(0.025, 0.04, Vector3(0.0, 0.0, 0.038), body, ALONG, 12, 0.021)
	for i in 6:
		var turn := Basis(Vector3.BACK, i * TAU / 6.0)
		if era == Eras.SECOND and i % 2 == 1:
			continue
		b.box(Vector3(0.006, 0.004, 0.036), turn * Vector3(0.0, 0.0245, 0.038), _black() if era != Eras.NEW else _rubber(), 0.001,
			turn * Basis(Vector3.RIGHT, 0.1))
	match era:
		Eras.FIRST:
			# A brass ferrule where its boot was.
			b.drum(0.017, 0.022, Vector3(0.0, 0.0, 0.069), _brass(), ALONG, 12, 0.012)
			b.drum(0.013, 0.01, Vector3(0.0, 0.0, 0.085), _rubber(), ALONG, 10)
		Eras.SECOND:
			b.drum(0.017, 0.026, Vector3(0.0, 0.0, 0.071), _ceramic(), ALONG, 12, 0.011)
			for z in [0.026, 0.034, 0.042]:
				b.drum(0.0245, 0.004, Vector3(0.0, 0.0, z), _cord(), ALONG, 10)
			b.drum(0.011, 0.006, Vector3(0.0, 0.0, 0.087), _rubber(), ALONG, 10)
		_:
			b.drum(0.017, 0.026, Vector3(0.0, 0.0, 0.071), _rubber(), ALONG, 12, 0.011)
			# Rings on the boot, or a crew's rope wound over it.
			for z in ([0.063, 0.07, 0.077] if era == Eras.SKIMMER else [0.064, 0.074]):
				b.drum(0.0182 - (z - 0.058) * 0.23, 0.005 if era == Eras.SKIMMER else 0.003, Vector3(0.0, 0.0, z),
					_rope() if era == Eras.SKIMMER else _rubber(), ALONG, 8 if era == Eras.SKIMMER else 12)
			b.drum(0.011, 0.006, Vector3(0.0, 0.0, 0.087), _rubber(), ALONG, 10)


## The strong plug: a square armoured housing on a square seat in a strong
## line's red, a steel bayonet ring with its lugs, banded grips, and a clamp
## plate where the heavy cable goes in.
static func _strong_plug(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var ring := _steel() if era == Eras.NEW else _fitting(era)
	b.box(Vector3(size.x, size.y, 0.016), Vector3(0.0, 0.0, 0.008), Paint.coat(Paint.STRONG_RED, 0.3, 0.1, 0.45, 0.35), 0.006)
	if era == Eras.SECOND:
		# Its lock ring long gone: cord bound where it was.
		for z in [0.019, 0.025]:
			b.drum(0.028, 0.006, Vector3(0.0, 0.0, z), _cord(), ALONG, 10)
	else:
		b.drum(0.031, 0.014, Vector3(0.0, 0.0, 0.023), ring, ALONG, 16, 0.034 if era == Eras.FIRST else -1.0)
		for s in [-1.0, 1.0]:
			b.box(Vector3(0.008, 0.012, 0.012), Vector3(s * 0.03, 0.0, 0.023), ring, 0.002)
	var body := _black() if era == Eras.NEW else _case(era)
	b.box(Vector3(size.x - 0.012, size.y - 0.012, 0.044), Vector3(0.0, 0.0, 0.052), body, 0.009)
	for z in [0.042, 0.054, 0.066]:
		b.box(Vector3(size.x - 0.008, size.y - 0.008, 0.004), Vector3(0.0, 0.0, z), _rubber() if era == Eras.NEW else _black(), 0.002)
	if era == Eras.SKIMMER:
		# A strap welded over its housing.
		b.box(Vector3(0.012, size.y - 0.002, 0.03), Vector3(0.012, 0.0, 0.052), _steel(), 0.001, Basis(Vector3.BACK, 0.12))
	b.box(Vector3(0.05, 0.05, 0.008), Vector3(0.0, 0.0, 0.078), _brass() if era == Eras.FIRST else _steel(), 0.003)
	if era == Eras.SECOND:
		b.drum(0.019, 0.016, Vector3(0.0, 0.0, 0.09), _ceramic(), ALONG, 12, 0.013)
	else:
		b.drum(0.018, 0.012, Vector3(0.0, 0.0, 0.088), _rubber(), ALONG, 12, 0.014)
		b.box(Vector3(0.046, 0.01, 0.008), Vector3(0.0, 0.0, 0.09), _steel(), 0.002)
		for s in [-1.0, 1.0]:
			b.drum(0.004, 0.006, Vector3(s * 0.018, 0.0, 0.097), _steel(), ALONG, 6)
		if era == Eras.SKIMMER:
			for z in [0.084, 0.091]:
				b.drum(0.017, 0.005, Vector3(0.0, 0.0, z), _rope(), ALONG, 8)
	b.drum(0.012, 0.006, Vector3(0.0, 0.0, size.z - 0.003), _rubber(), ALONG, 10)


## A hose's end: a water-blue seat and a hex coupling nut, a cast tee whose
## spout stands up where a canister or another end goes on, capped in blue,
## and the hose clamped on its barb.
static func _hose_end(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var water := _collar(&"water")
	var cast := _fitting(era) if era != Eras.COLONIAL else _case(era)
	var nut := _steel() if era == Eras.NEW else _fitting(era)
	var hose := Paint.coat(Paint.HOSE, 0.3, 0.0, 0.85)
	b.drum(h.x, 0.008, Vector3(0.0, 0.0, 0.004), water, ALONG, 16)
	b.drum(0.037, 0.022, Vector3(0.0, 0.0, 0.019), nut, ALONG, 6)
	b.drum(0.025, 0.056, Vector3(0.0, 0.0, 0.058), cast, ALONG, 12)
	if era == Eras.SECOND:
		# Its spout lost and thrown again in ceramic, a little off true.
		b.drum(0.019, 0.032, Vector3(0.003, 0.021, 0.075), _ceramic(), Basis.IDENTITY, 12, 0.015)
		b.drum(0.019, 0.005, Vector3(0.003, 0.0375, 0.075), water, Basis.IDENTITY, 12)
	else:
		b.drum(0.017, 0.03, Vector3(0.0, 0.022, 0.075), _brass() if era == Eras.FIRST else cast, Basis.IDENTITY, 12,
			0.021 if era == Eras.FIRST else -1.0)
		b.drum(0.021, 0.006, Vector3(0.0, 0.037, 0.075), water, Basis.IDENTITY, 12)
	b.drum(0.02, 0.008, Vector3(0.0, 0.0, 0.09), nut, ALONG, 12)
	b.drum(0.029, 0.026, Vector3(0.0, 0.0, 0.107), hose, ALONG, 14)
	b.drum(0.03, 0.004, Vector3(0.0, 0.0, 0.116), hose, ALONG, 14)
	match era:
		Eras.SKIMMER:
			for z in [0.098, 0.104]:
				b.drum(0.031, 0.005, Vector3(0.0, 0.0, z), _rope(), ALONG, 10)
			# A weld bead round the tee where it cracked.
			b.drum(0.027, 0.004, Vector3(0.0, 0.0, 0.05), _steel(), ALONG, 10)
		Eras.SECOND:
			for i in 3:
				b.drum(0.031, 0.004, Vector3(0.0, 0.0, 0.098 + i * 0.006), _cord(), ALONG, 10)
		_:
			b.drum(0.031, 0.007, Vector3(0.0, 0.0, 0.1), _steel(), ALONG, 14)
			b.box(Vector3(0.012, 0.008, 0.01), Vector3(0.0, -0.032, 0.1), _steel(), 0.002)


## The rope hook: a bolted flange and its collar in the ring's grey, a swivel
## boss, and a forged hook turned up, its gate sprung across its throat; the
## line's ring hangs at its nose (RopeHook).
static func _hook(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var forged := Paint.coat(Paint.STEEL, 0.5, 0.85, 0.4)
	var base := Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5)
	match era:
		Eras.FIRST: base = _brass()
		Eras.SECOND: base = _ceramic()
	if era == Eras.SKIMMER:
		# A square of scrap plate welded on for a flange.
		b.box(Vector3(0.066, 0.066, 0.008), Vector3(0.0, 0.0, 0.004), Paint.coat(Paint.GUNMETAL, 1.0, 0.4, 0.6), 0.001,
			Basis(Vector3.BACK, 0.2))
		b.drum(0.02, 0.006, Vector3(0.0, 0.0, 0.011), _steel(), ALONG, 8)
	else:
		b.drum(0.036, 0.01, Vector3(0.0, 0.0, 0.005), base, ALONG, 16, 0.03 if era == Eras.FIRST else -1.0)
		for i in 3:
			var turn := Basis(Vector3.BACK, PI / 2.0 + i * TAU / 3.0)
			b.drum(0.0055, 0.004, turn * Vector3(0.0, 0.027, 0.012), _black() if era == Eras.SECOND else _steel(), ALONG, 6)
	b.drum(0.023, 0.008, Vector3(0.0, 0.0, 0.014), _collar(&"ring"), ALONG, 16)
	b.drum(0.017, 0.016, Vector3(0.0, 0.0, 0.026), forged, ALONG, 12)
	# The shank out to the bend, the bend turned up and back to a point.
	var bend := Vector3(0.0, 0.0155, 0.072)
	var r := 0.0155
	var thick := 0.0072 if era == Eras.SKIMMER else 0.0085
	b.drum(thick + 0.0005, bend.z - 0.032, Vector3(0.0, 0.0, (bend.z + 0.032) * 0.5), forged, ALONG, 10)
	var steps := 8
	var last := Vector3(0.0, 0.0, bend.z)
	for i in steps:
		var a := -PI / 2.0 + (i + 1) * (PI * 4.0 / 3.0) / steps
		var at := bend + Vector3(0.0, sin(a) * r, cos(a) * r)
		var taper := lerpf(thick, 0.004, maxf(0.0, (i - 4.0) / (steps - 4.0)))
		var span := at - last
		b.drum(taper, span.length() + 0.004, (at + last) * 0.5, forged, Basis(Quaternion(Vector3.UP, span.normalized())), 10)
		last = at
	var tip := last
	match era:
		Eras.SKIMMER:
			# No gate: a lashing of rope round its throat.
			for i in 3:
				b.drum(0.0105, 0.004, Vector3(0.0, 0.0, 0.05 + i * 0.006), _rope(), ALONG, 8)
		Eras.SECOND:
			for i in 4:
				b.drum(0.011, 0.004, Vector3(0.0, 0.0, 0.04 + i * 0.006), _cord(), ALONG, 8)
			# A bead on a tail of the cord.
			_strand(b, Vector3(0.0, -0.01, 0.05), Vector3(0.012, -0.03, 0.054), 0.003, _cord())
			b.ball(0.006, Vector3(0.013, -0.033, 0.055), _ceramic())
		_:
			var gate := _orange() if era == Eras.COLONIAL else (_brass() if era == Eras.FIRST else Paint.coat(Paint.YELLOW, 0.6))
			_strand(b, Vector3(0.0, thick, bend.z - 0.026), tip, 0.0035, gate)
			b.box(Vector3(0.008, 0.006, 0.008), Vector3(0.0, thick + 0.002, bend.z - 0.026), forged, 0.001)


## The water canister: drawn alloy on its blue seat, rolled beads round it, a
## shoulder to a neck and a cap, and the fill gauge's saddle on top under its
## live light.
static func _canister(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var r := h.x * 0.92
	var shell := Paint.coat(Paint.ALLOY, 0.6 if era == Eras.NEW else 0.9, 0.5, 0.45)
	if era == Eras.COLONIAL or era == Eras.FIRST or era == Eras.SKIMMER:
		shell = _case(era)
	var bead := shell if era == Eras.NEW else _fitting(era)
	b.drum(h.x, 0.016, Vector3(0.0, 0.0, 0.008), _collar(&"water"), ALONG, 20)
	b.drum(r, 0.19, Vector3(0.0, 0.0, 0.111), shell, ALONG, 20)
	for z in [0.05, 0.1, 0.19]:
		if era == Eras.SECOND and z > 0.15:
			continue
		b.drum(r + 0.0025, 0.008, Vector3(0.0, 0.0, z), bead, ALONG, 20)
	b.drum(r, 0.022, Vector3(0.0, 0.0, 0.217), shell, ALONG, 20, 0.034)
	# The fill gauge under the light the catalog sets on its top.
	var gauge := Vector3(0.0, size.y * 0.5 + 0.005, size.z * 0.6)
	b.box(Vector3(0.1, 0.008, 0.026), Vector3(0.0, r - 0.002, gauge.z), _black(), 0.003)
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.006, 0.008, 0.022), Vector3(s * 0.047, r - 0.001, gauge.z), _fitting(era), 0.002)
	match era:
		Eras.SECOND:
			# Its cap lost: a ceramic stopper, corded down over the neck.
			b.drum(0.024, 0.012, Vector3(0.0, 0.0, 0.234), Paint.coat(Paint.GUNMETAL, 0.9, 0.6, 0.5), ALONG, 12)
			b.ball(1.0, Vector3(0.0, 0.0, 0.246), _ceramic(), Vector3(0.026, 0.026, 0.014))
			for a in [0.0, PI / 2.0]:
				var way := Vector3(cos(a), sin(a), 0.0)
				for s in [-1.0, 1.0]:
					_strand(b, way * s * 0.03 + Vector3(0.0, 0.0, 0.226), way * s * 0.012 + Vector3(0.0, 0.0, 0.255), 0.004, _cord())
			# A cord net's band round its middle, a saltbush toggle tied on to carry it.
			for z in [0.064, 0.071, 0.078]:
				b.drum(r + 0.002, 0.004, Vector3(0.0, 0.0, z), _cord(), ALONG, 14)
			b.box(Vector3(0.012, 0.06, 0.012), Vector3(-h.x + 0.006, 0.0, 0.071), _wood(), 0.003)
		_:
			b.drum(0.026, 0.01, Vector3(0.0, 0.0, 0.233), _fitting(era), ALONG, 14)
			var cap := Paint.coat(Paint.TEAL, 0.5)
			match era:
				Eras.COLONIAL: cap = _orange()
				Eras.FIRST: cap = _brass()
				Eras.SKIMMER: cap = _rubber()
			b.drum(0.03, 0.018, Vector3(0.0, 0.0, 0.247), cap, ALONG, 12, 0.034 if era == Eras.FIRST else -1.0)
			for i in 8:
				var turn := Basis(Vector3.BACK, i * TAU / 8.0)
				b.box(Vector3(0.004, 0.004, 0.014), turn * Vector3(0.0, 0.03, 0.247), cap, 0.0, turn)
			b.drum(0.01, 0.004, Vector3(0.0, 0.0, 0.258), _black(), ALONG, 8)
	if era == Eras.SKIMMER:
		# A rope sling for carrying, knotted round its neck and its foot.
		var side := Vector3(-h.x + 0.0035, 0.0, 0.0)
		_strand(b, side + Vector3(0.0, 0.0, 0.03), side + Vector3(0.0, 0.0, 0.21), 0.007, _rope())
		for z in [0.03, 0.21]:
			b.drum(r + 0.004, 0.006, Vector3(0.0, 0.0, z), _rope(), ALONG, 14)
		b.box(Vector3(0.008, 0.05, 0.04), Vector3(0.051, -0.008, 0.12), _steel(), 0.001)


## The lamp: a square foot that sticks on a top, a boss and stem to a hinge,
## and its head, hooded in safety yellow with cooling rings, a bezel, the lit
## lens and a guard across it.
static func _lamp(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var metal := _fitting(era)
	var hood := Paint.coat(Paint.YELLOW, 0.7)
	if era == Eras.SECOND:
		hood = _ceramic()
	elif era != Eras.NEW:
		hood = _case(era)
	b.box(Vector3(size.x - 0.01, size.y - 0.01, 0.012), Vector3(0.0, 0.0, 0.006), Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5), 0.005)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			b.drum(0.006, 0.004, Vector3(sx * (h.x - 0.017), sy * (h.y - 0.017), 0.014), _steel(), ALONG, 6)
	b.drum(0.03, 0.02, Vector3(0.0, 0.0, 0.022), metal, ALONG, 12)
	if era == Eras.SECOND:
		# Its stem rebuilt in saltbush, lashed at both ends.
		b.drum(0.016, 0.11, Vector3(0.0, 0.0, 0.087), _wood(), ALONG, 8)
		for z in [0.04, 0.046, 0.128, 0.134]:
			b.drum(0.018, 0.004, Vector3(0.0, 0.0, z), _cord(), ALONG, 8)
	else:
		b.drum(0.016, 0.11, Vector3(0.0, 0.0, 0.087), Paint.coat(Paint.STEEL, 0.4, 0.8, 0.4), ALONG, 12)
		if era == Eras.SKIMMER:
			for z in [0.07, 0.077, 0.084]:
				b.drum(0.018, 0.005, Vector3(0.0, 0.0, z), _rope(), ALONG, 8)
	# The hinge the head tilts on.
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.008, 0.03, 0.03), Vector3(s * 0.022, 0.0, 0.15), metal, 0.003)
	b.drum(0.012, 0.06, Vector3(0.0, 0.0, 0.152), metal, ACROSS, 10)
	b.drum(0.03, 0.012, Vector3(0.0, 0.0, 0.162), metal, ALONG, 12)
	# The head: round where a lineage's marks go (Catalog.ROUND).
	var r := h.x * 0.92
	if era == Eras.SECOND:
		b.drum(r - 0.004, 0.075, Vector3(-0.002, 0.003, 0.2025), hood, ALONG, 14, r)
	else:
		b.drum(r, 0.075, Vector3(0.0, 0.0, 0.2025), hood, ALONG, 16)
		for z in [0.174, 0.184]:
			b.drum(r + 0.003, 0.004, Vector3(0.0, 0.0, z), _black(), ALONG, 16)
	var bezel := _black()
	match era:
		Eras.COLONIAL: bezel = Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5)
		Eras.FIRST: bezel = _brass()
		Eras.SECOND: bezel = _cord()
	b.drum(h.x - 0.002, 0.008, Vector3(0.0, 0.0, 0.236), bezel, ALONG, 16, h.x - 0.002 if era != Eras.FIRST else h.x)
	b.drum(0.046, 0.008, Vector3(0.0, 0.0, 0.244), Paint.coat(Paint.LAMP, 0.0, 0.0, 0.2, 0.2, 3.0), ALONG, 16)
	match era:
		Eras.SKIMMER:
			# Its guard a welded grid of rod.
			for k in 2:
				for t in [-0.024, 0.0, 0.024]:
					var turn := Basis(Vector3.BACK, k * PI / 2.0)
					b.box(Vector3(0.096, 0.0035, 0.0035), turn * Vector3(0.0, t, 0.248), _steel(), 0.0, turn)
		Eras.SECOND:
			for a in [0.4, -0.4]:
				_strand(b, Vector3(-0.044, -0.044 * a, 0.248), Vector3(0.044, 0.044 * a, 0.248), 0.003, _cord())
		_:
			var guard := _orange() if era == Eras.COLONIAL else (_brass() if era == Eras.FIRST else _black())
			for y in [-0.02, 0.0, 0.02]:
				b.box(Vector3(0.092, 0.005, 0.004), Vector3(0.0, y, 0.248), guard, 0.001)
			if era == Eras.FIRST:
				b.ring(0.03, 0.034, Vector3(0.0, 0.0, 0.248), guard, ALONG, 6)
