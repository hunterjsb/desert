class_name HeldLooks
extends RefCounted
## What you hold and eat, in B's kit: company tools with moulded grips,
## bezels, brass and steel fittings and their kind's colour, and food that
## looks like the crops it came from. Big in your hands, so each is a real
## model, one merged mesh inside its catalog box. A part stands out from its
## socket along +Z; the cutter is centred on its box, its nozzle to -Z.
## Whose hands a tool passed through shows in its shape (art direction, "Shape
## by era"): colonial make is crisp and squared, off-white with safety
## orange; the First Kingdoms kept it clean and fitted it in brass and bone;
## the skimmer era repainted it crew red, taped it and welded scrap on; the
## second age mended it in glazed ceramic, saltwood and cord, with a charm.

const IDS: Array[StringName] = [&"cutter", &"compass", &"sand_scoop", &"flare", &"sealant", &"med_kit", &"ration", &"tubers", &"fungus_caps", &"salt", &"saltbush_leaves", &"coalcane_bundle"]

## The tools whose last hands give them a shape, and the eras that do; any
## other is the company's issue.
const SHAPED: Array[StringName] = [&"cutter", &"compass", &"sand_scoop", &"sealant", &"med_kit"]
const SHAPES: Array[StringName] = [Eras.COLONIAL, Eras.FIRST, Eras.SKIMMER, Eras.SECOND]
## A drum's axis along +Z, and along -Z (a taper's narrow end forward).
const ALONG := Basis(Vector3.RIGHT, PI / 2.0)
const FORE := Basis(Vector3.RIGHT, -PI / 2.0)
const ACROSS := Basis(Vector3.BACK, PI / 2.0)
## The cutter's lance axis, m above its middle (Cutter.NOZZLE).
const LANCE := 0.01

static var _eras := {}


static func frame(b: Paint.Pieces, id: StringName, _size: Vector3, era := Eras.NEW) -> bool:
	if id != &"cutter":
		return false
	_cutter(b, era)
	return true


## Draws a held thing or food into its pieces; food in pieces drawn with
## `count` of them left. False for an id that isn't one.
static func part(b: Paint.Pieces, id: StringName, size: Vector3, count := -1, era := Eras.NEW) -> bool:
	match id:
		&"compass":
			_compass(b, era)
		&"sand_scoop":
			_scoop(b, era)
		&"flare":
			_flare(b, size)
		&"sealant":
			_sealant(b, size, era)
		&"med_kit":
			_med_kit(b, era)
		&"ration":
			_ration(b, count)
		&"tubers":
			_tubers(b, count)
		&"fungus_caps":
			_caps(b, count)
		&"salt":
			_salt(b)
		&"saltbush_leaves":
			_leaves(b, count)
		&"coalcane_bundle":
			_bundle(b, size)
		_:
			return false
	return true


## A tool in the shape its last hands' era gave it, made once, for its
## lineage's marks to go on (Dress); null where it keeps the company's issue.
static func lineage(id: StringName, line: Array) -> ArrayMesh:
	var era := Eras.era_of(line)
	if not SHAPED.has(id) or not SHAPES.has(era):
		return null
	var key := [id, era]
	if not _eras.has(key):
		var b: Paint.Pieces
		if Catalog.DEVICES.has(id):
			var size: Vector3 = Catalog.DEVICES[id].size
			b = Paint.Pieces.new(-size.y * 0.5)
			frame(b, id, size, era)
		else:
			b = Paint.Pieces.new()
			part(b, id, Catalog.PARTS[id].size, -1, era)
		_eras[key] = b.commit()
	return _eras[key]


## A compass's needle, its north tip along +Y: a luminous red blade over a
## steel south one, on a brass jewel.
static func needle() -> ArrayMesh:
	var b := Paint.Pieces.new()
	var up := Basis.from_scale(Vector3(1.0, 1.0, 0.35))
	b.drum(0.0055, 0.042, Vector3(0.0, 0.021, 0.0), Paint.coat(Paint.NEEDLE_RED, 0.0, 0.0, 0.4, 0.0, 1.2), up, 4, 0.0)
	b.drum(0.0055, 0.036, Vector3(0.0, -0.018, 0.0), Paint.coat(Paint.STEEL, 0.0, 0.6, 0.4, 0.0),
		Basis(Vector3.BACK, PI) * up, 4, 0.0)
	b.drum(0.0045, 0.005, Vector3.ZERO, _brass(), ALONG, 10)
	return b.commit()


# --- The era's finishes ---------------------------------------------------

## A tool's painted body: the company's teal, colonial off-white (the First
## Kingdoms' too), crew red, second-age limewash.
static func _body(era: StringName) -> Paint.Coat:
	match era:
		Eras.COLONIAL, Eras.FIRST:
			return Paint.coat(ColonialKit.PANEL, 0.5, 0.1, 0.5)
		Eras.SKIMMER:
			return Paint.coat(SkimmerKit.PLATE_RED, 0.9, 0.0, 0.55)
		Eras.SECOND:
			return Paint.coat(Paint.LIMEWASH, 0.4, 0.0, 0.85, 0.8)
	return Paint.coat(Paint.TEAL, 0.6, 0.2, 0.6)


## Its frame and fittings' metal.
static func _metal(era: StringName) -> Paint.Coat:
	match era:
		Eras.COLONIAL, Eras.FIRST:
			return Paint.coat(ColonialKit.DARK, 0.4, 0.3, 0.5)
		Eras.SKIMMER:
			return Paint.coat(SkimmerKit.GUNMETAL, 0.8, 0.5, 0.6)
	return Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5)


## Its accent: safety yellow, safety orange, brass, tape, cord.
static func _accent(era: StringName) -> Paint.Coat:
	match era:
		Eras.COLONIAL:
			return Paint.coat(ColonialKit.ORANGE, 0.7, 0.0, 0.5)
		Eras.FIRST:
			return _brass()
		Eras.SKIMMER:
			return _tape()
		Eras.SECOND:
			return _cord()
	return Paint.coat(Paint.YELLOW, 0.7, 0.0, 0.5)


## What you hold it by: moulded rubber, a bone handle, saltwood.
static func _grip(era: StringName) -> Paint.Coat:
	match era:
		Eras.FIRST:
			return Paint.coat(Paint.BONE, 0.2, 0.0, 0.45, 0.6)
		Eras.SECOND:
			return _wood()
	return _rubber()


static func _rubber() -> Paint.Coat:
	return Paint.coat(Paint.BLACK, 0.25, 0.0, 0.88)


static func _steel() -> Paint.Coat:
	return Paint.coat(Paint.STEEL, 0.4, 0.8, 0.4)


static func _brass() -> Paint.Coat:
	return Paint.coat(Paint.BRASS, 0.3, 0.85, 0.38, 0.5)


static func _tape() -> Paint.Coat:
	return Paint.coat(SkimmerKit.TAPE, 0.2, 0.0, 0.8, 0.6)


static func _cord() -> Paint.Coat:
	return Paint.coat(Paint.CORD, 0.0, 0.0, 0.95, 0.7)


static func _glazed() -> Paint.Coat:
	return Paint.coat(Paint.CERAMIC, 0.15, 0.0, 0.3, 0.6)


static func _wood() -> Paint.Coat:
	return Paint.coat(Paint.SALTWOOD, 0.1, 0.0, 0.85, 0.6)


static func _ink() -> Paint.Coat:
	return Paint.coat(Paint.BLACK, 0.0, 0.0, 0.8, 0.3)


# --- Shared fittings ------------------------------------------------------

## A slotted screw head, its axis along the turn's y.
static func _screw(b: Paint.Pieces, at: Vector3, radius: float, turn := Basis.IDENTITY, look: Paint.Coat = null) -> void:
	b.drum(radius, radius * 0.6, at, look if look != null else _steel(), turn, 6)
	b.box(Vector3(radius * 1.5, radius * 0.3, radius * 0.25), at + turn.y.normalized() * radius * 0.3, _ink(), 0.0, turn)


## A straight bar or cord from one point to another.
static func _strand(b: Paint.Pieces, from: Vector3, to: Vector3, thick: float, look: Paint.Coat) -> void:
	var along := to - from
	if along.length() < 1e-5:
		return
	var y := along.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	b.box(Vector3(thick, along.length() + thick, thick), (from + to) * 0.5, look, 0.0, Basis(x, y, x.cross(y)))


## Turns of tape or cord round a round thing, along the turn's y from `from`
## to `to` past `at`, a little uneven as a hand winds them.
static func _wraps(b: Paint.Pieces, at: Vector3, turn: Basis, radius: float, from: float, to: float, count: int,
		look: Paint.Coat) -> void:
	var step := (to - from) / count
	for i in count:
		var tilt := Basis(turn.x.normalized(), 0.06 * (1 if i % 2 == 0 else -1))
		b.drum(radius, step * 0.82, at + turn.y.normalized() * (from + step * (i + 0.5)), look, tilt * turn, 10)


## A second-age charm: a cord from `at` along `out` to a glazed bead, three
## strands of tassel past it.
static func _charm(b: Paint.Pieces, at: Vector3, out: Vector3, long: float) -> void:
	var cord := _cord()
	var bead := at + out * long
	_strand(b, at, bead, 0.0025, cord)
	b.ball(0.0055, bead, _glazed())
	var side := out.cross(Vector3.UP if absf(out.y) < 0.9 else Vector3.BACK).normalized()
	for k in [-1.0, 0.0, 1.0]:
		_strand(b, bead, bead + out * long * 0.8 + side * k * 0.004, 0.0018, cord)


## A skimmer-era repair: a scrap plate welded on along two edges, facing the
## turn's +Z.
static func _patch(b: Paint.Pieces, wide: Vector2, at: Vector3, turn: Basis) -> void:
	b.box(Vector3(wide.x, wide.y, 0.003), at, Paint.coat(SkimmerKit.SCRAP, 1.0, 0.5, 0.6), 0.001, turn)
	var weld := Paint.coat(Paint.STEEL, 0.6, 0.7, 0.75)
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.0028, wide.y + 0.002, 0.0028), at + turn * Vector3(s * wide.x * 0.5, 0.0, 0.0006), weld, 0.0, turn)


# --- Tools ----------------------------------------------------------------

## A heat lance on its own cell: a copper nozzle in a brass collar behind a
## heat shield, a finned barrel under the cell's saddle, and a power unit
## with a gauge, a moulded pistol grip under it where the hand takes it
## (Body._grips) and a rubber butt.
static func _cutter(b: Paint.Pieces, era: StringName) -> void:
	var body := _body(era)
	var metal := _metal(era)
	var accent := _accent(era)
	var rubber := _rubber()
	var steel := _steel()
	var brass := _brass()
	var axis := Vector3(0.0, LANCE, 0.0)
	# The barrel, finned where the lance runs hot under the cell.
	b.drum(0.03, 0.27, axis + Vector3(0.0, 0.0, -0.07), metal, ALONG, 16)
	for i in 5:
		b.drum(0.041, 0.006, axis + Vector3(0.0, 0.0, -0.163 + i * 0.022), metal, ALONG, 16)
	# The cell's saddle, flat under its socket, on two struts; a clamp at its front.
	b.box(Vector3(0.1, 0.022, 0.15), Vector3(0.0, 0.067, -0.1), metal, 0.006)
	for x in [-0.03, 0.03]:
		b.box(Vector3(0.012, 0.032, 0.12), Vector3(x, 0.042, -0.1), metal, 0.003)
	b.box(Vector3(0.08, 0.018, 0.008), Vector3(0.0, 0.066, -0.178), steel, 0.002)
	b.box(Vector3(0.06, 0.004, 0.01), Vector3(0.0, 0.0775, -0.032), Paint.coat(Catalog.KINDS[&"battery"], 0.3, 0.3, 0.5), 0.001)
	b.drum(0.008, 0.04, Vector3(0.025, 0.06, -0.012), rubber, ALONG, 8)
	# The heat shield, bolted, and the nozzle through it.
	var shield := accent if era != Eras.FIRST else Paint.coat(Paint.COPPER, 0.3, 0.85, 0.4, 0.5)
	if era == Eras.SECOND:
		shield = _glazed()
	b.drum(0.052, 0.01, axis + Vector3(0.0, 0.0, -0.19), shield, ALONG, 24)
	for i in 4:
		var turn := Basis(Vector3.BACK, PI * 0.25 + i * PI * 0.5)
		_screw(b, axis + turn * Vector3(0.0, 0.042, -0.196), 0.0045, FORE)
	b.drum(0.026, 0.009, axis + Vector3(0.0, 0.0, -0.199), brass, ALONG, 16)
	if era == Eras.FIRST:
		# A flared brass bell where the company's copper cone was.
		b.drum(0.016, 0.05, axis + Vector3(0.0, 0.0, -0.228), brass, FORE, 16, 0.027)
		b.drum(0.028, 0.004, axis + Vector3(0.0, 0.0, -0.253), brass, ALONG, 16)
	else:
		b.drum(0.022, 0.05, axis + Vector3(0.0, 0.0, -0.228), Paint.coat(Paint.COPPER, 0.5, 0.9, 0.35), FORE, 16, 0.011)
		b.drum(0.012, 0.01, axis + Vector3(0.0, 0.0, -0.255), Paint.coat(Paint.BLACK, 0.1, 0.0, 0.7), ALONG, 12)
	b.drum(0.006, 0.004, axis + Vector3(0.0, 0.0, -0.2605), Paint.coat(Paint.BLACK, 0.0, 0.0, 1.0, 0.0), ALONG, 8)
	if era == Eras.SKIMMER:
		# A ring guard welded round the nozzle on three struts.
		b.ring(0.026, 0.031, axis + Vector3(0.0, 0.0, -0.245), steel, ALONG, 6)
		for i in 3:
			var turn := Basis(Vector3.BACK, i * TAU / 3.0)
			_strand(b, axis + turn * Vector3(0.0, 0.03, -0.244), axis + turn * Vector3(0.0, 0.04, -0.2), 0.004, steel)
	# The power unit: its body in the era's paint over dark side panels.
	var unit := Vector3(0.0, 0.022, 0.1)
	if era == Eras.SECOND:
		# Its casing lost; the works bound in limewashed clay under a round glazed cap.
		b.box(Vector3(0.104, 0.09, 0.15), unit + Vector3(0.0, 0.0, -0.02), body, 0.03)
		b.ball(0.05, Vector3(0.0, 0.02, 0.215), _glazed(), Vector3(1.0, 0.9, 0.95))
		for z in [0.03, 0.045, 0.06]:
			b.box(Vector3(0.108, 0.094, 0.006), unit + Vector3(0.0, 0.0, z - 0.1), _cord(), 0.03)
		_charm(b, Vector3(0.045, -0.02, 0.06), Vector3(0.05, -0.97, 0.2).normalized(), 0.025)
	else:
		b.box(Vector3(0.11, 0.096, 0.19), unit, body, 0.016 if era == Eras.COLONIAL or era == Eras.FIRST else 0.012)
		for x in [-1.0, 1.0]:
			b.box(Vector3(0.004, 0.056, 0.13), unit + Vector3(x * 0.0555, 0.002, -0.005), metal, 0.002)
		if era == Eras.SKIMMER:
			_patch(b, Vector2(0.07, 0.05), unit + Vector3(-0.0565, -0.01, 0.03), Basis(Vector3.UP, -PI * 0.5) * Basis(Vector3.BACK, 0.12))
			b.stamp(Paint.Mark.SKIMMER_CREW, unit + Vector3(0.0, 0.049, 0.04), 0.05, Basis(Vector3.RIGHT, -PI * 0.5), Paint.Ink.PALE)
			b.box(Vector3(0.05, 0.002, 0.028), unit + Vector3(0.0, 0.0485, 0.04), body, 0.0)
		else:
			b.stamp(Paint.Mark.CONTRACTOR, unit + Vector3(0.0575, 0.002, -0.005), 0.075, Basis(Vector3.UP, PI * 0.5))
			b.box(Vector3(0.002, 0.04, 0.09), unit + Vector3(0.0574, 0.002, -0.005), metal, 0.0)
		# The safety stripe, its gauge and the vents along its top.
		if era == Eras.NEW:
			Dress._hazard(b, Vector3(0.09, 0.016, 0.004), unit + Vector3(0.0, 0.049, 0.075), Basis(Vector3.RIGHT, -PI * 0.5))
		else:
			b.box(Vector3(0.112, 0.098, 0.012), unit + Vector3(0.0, 0.0, 0.075), accent, 0.004)
		var gauge := unit + Vector3(0.022, 0.049, 0.0)
		b.drum(0.021, 0.006, gauge, brass if era == Eras.FIRST else metal, Basis.IDENTITY, 20)
		b.drum(0.017, 0.002, gauge + Vector3(0.0, 0.0035, 0.0), Paint.coat(Paint.BONE, 0.1, 0.0, 0.5), Basis.IDENTITY, 20)
		b.box(Vector3(0.002, 0.0008, 0.013), gauge + Vector3(0.003, 0.0048, -0.005), Paint.coat(Paint.NEEDLE_RED, 0.0, 0.0, 0.4),
			0.0, Basis(Vector3.UP, 0.6))
		for i in 4:
			b.box(Vector3(0.026, 0.003, 0.006), unit + Vector3(-0.025, 0.0485, -0.06 + i * 0.016), rubber, 0.001)
		for x in [-1.0, 1.0]:
			for z in [-0.08, 0.06]:
				_screw(b, unit + Vector3(x * 0.042, 0.048, z), 0.004)
		if era == Eras.FIRST:
			for x in [-1.0, 1.0]:
				b.box(Vector3(0.008, 0.008, 0.18), unit + Vector3(x * 0.051, 0.044, 0.0), brass, 0.002)
		# The rubber butt, banded.
		b.box(Vector3(0.1, 0.086, 0.07), Vector3(0.0, 0.02, 0.235), rubber, 0.018)
		for z in [0.218, 0.236, 0.254]:
			b.box(Vector3(0.102, 0.088, 0.004), Vector3(0.0, 0.02, z), metal if era != Eras.SKIMMER else _tape(), 0.012)
	# The pistol grip, finger-moulded, its guard and trigger in front of it.
	var hold := Vector3(0.0, -0.04, 0.16)
	var lean := Basis(Vector3.RIGHT, 0.25)
	var grip := _grip(era)
	b.box(Vector3(0.032, 0.07, 0.04), hold, grip, 0.01, lean)
	for y in [-0.018, 0.0, 0.018]:
		b.box(Vector3(0.034, 0.007, 0.006), hold + lean * Vector3(0.0, y, -0.019), grip, 0.002, lean)
	if era == Eras.SKIMMER:
		_wraps(b, hold, lean, 0.026, -0.03, 0.025, 3, _tape())
	elif era == Eras.SECOND:
		_wraps(b, hold, lean, 0.025, -0.025, 0.02, 4, _cord())
	elif era == Eras.FIRST:
		b.box(Vector3(0.036, 0.008, 0.044), hold + lean * Vector3(0.0, 0.028, 0.0), brass, 0.002, lean)
	b.box(Vector3(0.036, 0.007, 0.044), hold + lean * Vector3(0.0, -0.0315, 0.0), metal, 0.002, lean)
	_strand(b, Vector3(0.0, -0.026, 0.06), Vector3(0.0, -0.068, 0.072), 0.007, metal)
	_strand(b, Vector3(0.0, -0.068, 0.072), Vector3(0.0, -0.072, 0.13), 0.007, metal)
	b.box(Vector3(0.008, 0.026, 0.01), Vector3(0.0, -0.042, 0.11), accent if era != Eras.SECOND else _wood(), 0.002,
		Basis(Vector3.RIGHT, 0.35))


## A compass: a case with a moulded grip, a brass ring under a ticked bezel,
## a bone card with north in the accent and its points in black, a lubber
## line, and a lug at one corner with its lanyard ring. Colonial make is a
## rounded square with guarded corners; the First Kingdoms flared its bezel in
## brass and put a crest on its lug; the second age cast its case in glazed
## ceramic, corded it and hung a charm on it.
static func _compass(b: Paint.Pieces, era: StringName) -> void:
	var metal := _metal(era)
	var accent := _accent(era)
	var brass := _brass()
	var square := era == Eras.COLONIAL or era == Eras.FIRST
	var corner := Basis(Vector3.BACK, -PI * 0.25)
	if square:
		b.box(Vector3(0.112, 0.112, 0.019), Vector3(0.0, 0.0, 0.0095), _body(era), 0.02)
		b.box(Vector3(0.1, 0.1, 0.004), Vector3(0.0, 0.0, 0.0195), metal, 0.016)
		for x in [-1.0, 1.0]:
			for y in [-1.0, 1.0]:
				var turn := Basis(Vector3.BACK, atan2(y, x) - PI * 0.25)
				b.box(Vector3(0.022, 0.022, 0.021), Vector3(x * 0.043, y * 0.043, 0.0105), accent, 0.006, turn)
	else:
		var shell := _glazed() if era == Eras.SECOND else (_body(era) if era == Eras.SKIMMER else metal)
		b.drum(0.049, 0.004, Vector3(0.0, 0.0, 0.002), metal, ALONG, 32)
		b.drum(0.053, 0.017, Vector3(0.0, 0.0, 0.0125), shell, ALONG, 32)
		match era:
			Eras.SKIMMER:
				_wraps(b, Vector3.ZERO, ALONG, 0.0565, 0.006, 0.02, 3, _tape())
			Eras.SECOND:
				for z in [0.008, 0.013, 0.018]:
					b.ring(0.052, 0.0565, Vector3(0.0, 0.0, z), _cord(), ALONG, 6)
			_:
				b.drum(0.0565, 0.012, Vector3(0.0, 0.0, 0.012), _rubber(), ALONG, 32)
				for i in 24:
					var turn := Basis(Vector3.BACK, TAU * i / 24.0)
					b.box(Vector3(0.004, 0.004, 0.012), turn * Vector3(0.0, 0.0575, 0.012), _rubber(), 0.001, turn)
	# The bezel over a brass ring, the card proud of it.
	b.drum(0.0545, 0.002, Vector3(0.0, 0.0, 0.021), brass, ALONG, 32)
	var bezel := _steel() if era == Eras.NEW or era == Eras.SKIMMER else metal
	if era == Eras.FIRST:
		b.drum(0.05, 0.007, Vector3(0.0, 0.0, 0.0245), brass, ALONG, 32, 0.056)
	elif era == Eras.SECOND:
		b.drum(0.054, 0.007, Vector3(0.0, 0.0, 0.0245), _glazed(), ALONG, 32)
	else:
		b.drum(0.054, 0.007, Vector3(0.0, 0.0, 0.0245), bezel, ALONG, 32)
		for i in 36:
			var turn := Basis(Vector3.BACK, TAU * i / 36.0)
			b.box(Vector3(0.0028, 0.0018, 0.006), turn * Vector3(0.0, 0.0548, 0.0245), metal, 0.0, turn)
	var card := Paint.coat(Paint.LIMEWASH if era == Eras.SECOND else Paint.BONE, 0.15, 0.0, 0.5, 0.3)
	b.drum(0.0445, 0.0012, Vector3(0.0, 0.0, 0.0286), card, ALONG, 32)
	var north := Paint.coat(Paint.RUST if era == Eras.SECOND else (ColonialKit.ORANGE if square else Paint.YELLOW), 0.1, 0.0, 0.5)
	for i in 16:
		var turn := Basis(Vector3.BACK, TAU * i / 16.0)
		var long := 0.01 if i % 4 == 0 else (0.006 if i % 2 == 0 else 0.004)
		var wide := 0.004 if i % 4 == 0 else 0.0014
		b.box(Vector3(wide, long, 0.0006), turn * Vector3(0.0, 0.0425 - long * 0.5, 0.0295), north if i == 0 else _ink(), 0.0, turn)
	b.box(Vector3(0.008, 0.008, 0.0006), Vector3(0.0, 0.03, 0.0295), north, 0.0, Basis(Vector3.BACK, PI * 0.25))
	# The lubber line, luminous, where you sight.
	b.box(Vector3(0.003, 0.006, 0.0008), Vector3(0.0, 0.051, 0.0284), Paint.coat(Paint.LAMP, 0.0, 0.0, 0.4, 0.0, 1.0), 0.0)
	# The lug and its lanyard ring, out at a corner where the box has room.
	var lug := corner * Vector3(0.0, 0.058, 0.01)
	if square:
		# Its corner guard is its lug; the First Kingdoms put a crest on it.
		if era == Eras.FIRST:
			var crest := Vector3(0.043, 0.043, 0.0225)
			b.box(Vector3(0.016, 0.018, 0.003), crest, brass, 0.003, corner)
			b.box(Vector3(0.009, 0.011, 0.003), crest + Vector3(0.0, 0.0, 0.0015), Paint.coat(Paint.COPPER, 0.2, 0.8, 0.4), 0.002, corner)
	elif era == Eras.SECOND:
		b.box(Vector3(0.012, 0.016, 0.01), lug, _wood(), 0.003, corner)
		_charm(b, corner * Vector3(0.0, 0.064, 0.012), corner * Vector3(0.0, 1.0, 0.0), 0.006)
	else:
		b.box(Vector3(0.016, 0.016, 0.008), lug, metal if era != Eras.SKIMMER else _steel(), 0.003, corner)
		b.ring(0.0035, 0.0068, corner * Vector3(0.0, 0.0675, 0.01), _steel(), ALONG, 6)
		for s in [-1.0, 1.0]:
			_screw(b, lug + corner * Vector3(s * 0.004, 0.0, 0.004), 0.0018, ALONG, brass)


## A sand scoop: a pressed blade dished between its walls, its ribs, rolled
## rims and a bright edge worn by the sand, on a tube shaft in a riveted
## socket, a rubber sleeve and a moulded D-grip at the end you hold.
static func _scoop(b: Paint.Pieces, era: StringName) -> void:
	var body := _body(era)
	if era == Eras.SKIMMER:
		body = Paint.coat(SkimmerKit.OLIVE, 1.0, 0.3, 0.6)
	var metal := _metal(era)
	var accent := _accent(era)
	var steel := _steel()
	var blade := Vector3(0.0, 0.0, 0.445)
	var long := 0.29
	# The dish: a flat floor and two sides turned up to the walls, scoured
	# too often to hold the sand.
	var dish := Paint.coat(body.color, body.share, body.metal, body.rough, 0.25)
	b.box(Vector3(0.17, 0.006, long), blade + Vector3(0.0, -0.027, 0.0), dish, 0.002)
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.068, 0.006, long), blade + Vector3(s * 0.112, -0.019, 0.0), dish, 0.002, Basis(Vector3.BACK, s * 0.26))
		b.box(Vector3(0.008, 0.058, long), blade + Vector3(s * 0.145, -0.008, 0.0), body, 0.003)
		b.drum(0.005, long, blade + Vector3(s * 0.144, 0.022, 0.0), steel, ALONG, 8)
	b.box(Vector3(0.292, 0.066, 0.01), Vector3(0.0, -0.005, 0.297), body, 0.004)
	for x in [-0.055, 0.0, 0.055]:
		b.box(Vector3(0.012, 0.005, 0.22), blade + Vector3(x, -0.0225, 0.01), metal, 0.002)
	# The edge, worn bright, and its corners.
	b.box(Vector3(0.298, 0.008, 0.026), Vector3(0.0, -0.034, 0.586), Paint.coat(Paint.STEEL, 1.0, 0.9, 0.3), 0.003)
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.012, 0.03, 0.03), Vector3(s * 0.143, -0.022, 0.583), steel, 0.004)
	# The back wall's stripe and stamp, toward you as you dig.
	if era == Eras.NEW:
		Dress._hazard(b, Vector3(0.2, 0.018, 0.004), Vector3(0.0, 0.016, 0.2915), Basis(Vector3.UP, PI))
		b.stamp(Paint.Mark.CONTRACTOR, Vector3(-0.1, -0.012, 0.2915), 0.05, Basis(Vector3.UP, PI))
		b.box(Vector3(0.06, 0.03, 0.002), Vector3(-0.1, -0.012, 0.2915), body, 0.0)
	elif era == Eras.SKIMMER:
		_patch(b, Vector2(0.09, 0.12), blade + Vector3(0.04, -0.0195, 0.04), Basis(Vector3.RIGHT, -PI * 0.5) * Basis(Vector3.BACK, 0.2))
		b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(0.08, -0.006, 0.2915), 0.05, Basis(Vector3.UP, PI), Paint.Ink.PALE)
		b.box(Vector3(0.06, 0.03, 0.002), Vector3(0.08, -0.006, 0.2915), body, 0.0)
	elif era != Eras.SECOND:
		b.box(Vector3(0.28, 0.012, 0.004), Vector3(0.0, 0.018, 0.2915), accent, 0.002)
	# The socket the shaft is riveted into.
	var socket := Paint.coat(Paint.BRASS, 0.3, 0.85, 0.4) if era == Eras.FIRST else metal
	b.box(Vector3(0.07, 0.05, 0.006), Vector3(0.0, -0.004, 0.289), socket, 0.003)
	for x in [-0.025, 0.025]:
		for y in [-0.02, 0.012]:
			_screw(b, Vector3(x, y, 0.2855), 0.0035, FORE, _brass() if era == Eras.FIRST else steel)
	b.drum(0.024, 0.06, Vector3(0.0, 0.0, 0.255), socket, ALONG, 12, 0.017)
	# The shaft and what you hold.
	if era == Eras.SECOND:
		b.drum(0.017, 0.22, Vector3(0.0, 0.0, 0.135), _wood(), ALONG, 8)
		_wraps(b, Vector3.ZERO, ALONG, 0.026, 0.2, 0.25, 4, _cord())
		_wraps(b, Vector3.ZERO, ALONG, 0.02, 0.09, 0.12, 3, _cord())
	else:
		b.drum(0.0145, 0.2, Vector3(0.0, 0.0, 0.145), steel, ALONG, 12)
		if era == Eras.SKIMMER:
			_wraps(b, Vector3.ZERO, ALONG, 0.019, 0.1, 0.21, 4, _tape())
		else:
			b.drum(0.0185, 0.1, Vector3(0.0, 0.0, 0.165), _grip(era), ALONG, 12)
			for z in [0.123, 0.144, 0.165, 0.186, 0.207]:
				b.drum(0.0205, 0.006, Vector3(0.0, 0.0, z), _grip(era), ALONG, 12)
	match era:
		Eras.SKIMMER:
			# A steel rod bent to a T and welded on.
			b.drum(0.008, 0.13, Vector3(0.0, 0.0, 0.025), steel, ACROSS, 8)
			_strand(b, Vector3(0.0, 0.0, 0.05), Vector3(0.0, 0.0, 0.025), 0.012, steel)
			_wraps(b, Vector3(0.0, 0.0, 0.025), ACROSS, 0.012, -0.055, 0.055, 4, _tape())
		Eras.SECOND:
			# A saltwood crosspiece lashed on, and a charm.
			b.drum(0.013, 0.13, Vector3(0.0, 0.0, 0.03), _wood(), ACROSS * Basis(Vector3.RIGHT, 0.1), 8)
			_strand(b, Vector3(-0.012, 0.0, 0.016), Vector3(0.012, 0.0, 0.044), 0.006, _cord())
			_strand(b, Vector3(0.012, 0.0, 0.016), Vector3(-0.012, 0.0, 0.044), 0.006, _cord())
			_charm(b, Vector3(0.05, 0.0, 0.03), Vector3(0.0, -0.3, 1.0).normalized(), 0.03)
		_:
			# The moulded D: two arms out from the shaft to a rubber crossbar.
			var frame := accent if era != Eras.FIRST else _brass()
			for s in [-1.0, 1.0]:
				_strand(b, Vector3(s * 0.012, 0.0, 0.085), Vector3(s * 0.062, 0.0, 0.021), 0.016, frame)
			b.drum(0.016, 0.12, Vector3(0.0, 0.0, 0.021), _grip(era), ACROSS, 12)
			for s in [-1.0, 1.0]:
				b.drum(0.019, 0.012, Vector3(s * 0.064, 0.0, 0.021), frame, ACROSS, 12)
			b.drum(0.017, 0.016, Vector3(0.0, 0.0, 0.088), frame, ALONG, 12)


## A signal flare: a red tube, ribbed rubber at its foot, the company drop's
## orange round a printed label, a crimped shoulder, and the black striker
## cap at its tip, where it burns, with its tear strip.
static func _flare(b: Paint.Pieces, size: Vector3) -> void:
	var red := Paint.coat(Paint.FLARE_RED, 0.5, 0.0, 0.55)
	var rubber := _rubber()
	var orange := Paint.coat(Paint.DROP_ORANGE, 0.5, 0.0, 0.5)
	b.drum(0.0235, 0.03, Vector3(0.0, 0.0, 0.015), rubber, ALONG, 16)
	for i in 12:
		var turn := Basis(Vector3.BACK, TAU * i / 12.0)
		b.box(Vector3(0.004, 0.003, 0.026), turn * Vector3(0.0, 0.0232, 0.015), rubber, 0.001, turn)
	b.drum(0.012, 0.002, Vector3(0.0, 0.0, 0.0011), _steel(), ALONG, 12)
	b.drum(0.022, 0.226, Vector3(0.0, 0.0, 0.143), red, ALONG, 16)
	b.drum(0.0226, 0.07, Vector3(0.0, 0.0, 0.15), Paint.coat(Paint.BONE, 0.3, 0.0, 0.6), ALONG, 16)
	b.stamp(Paint.Mark.CONSIGNMENT, Vector3(0.0, 0.0235, 0.15), 0.034, Basis(Vector3.BACK, Vector3.RIGHT, Vector3.UP))
	b.box(Vector3(0.026, 0.002, 0.052), Vector3(0.0, 0.0222, 0.15), Paint.coat(Paint.BONE, 0.3, 0.0, 0.6), 0.0)
	for z in [0.112, 0.188]:
		b.drum(0.0229, 0.007, Vector3(0.0, 0.0, z), orange, ALONG, 16)
	for z in [0.128, 0.172]:
		b.drum(0.0228, 0.0015, Vector3(0.0, 0.0, z), _ink(), ALONG, 16)
	b.drum(0.0236, 0.006, Vector3(0.0, 0.0, 0.257), _steel(), ALONG, 16)
	b.drum(0.0245, 0.038, Vector3(0.0, 0.0, 0.279), Paint.coat(Paint.BLACK, 0.3, 0.0, 0.7), ALONG, 16, 0.023)
	b.drum(0.0249, 0.004, Vector3(0.0, 0.0, 0.265), Paint.coat(Paint.YELLOW, 0.4, 0.0, 0.5), ALONG, 16)
	b.box(Vector3(0.006, 0.002, 0.012), Vector3(0.0, 0.0238, 0.262), Paint.coat(Paint.YELLOW, 0.4, 0.0, 0.5), 0.001)
	b.drum(0.017, 0.003, Vector3(0.0, 0.0, size.z - 0.0016), Paint.coat(SkimmerKit.RUBBER, 0.0, 0.0, 1.0, 0.2), ALONG, 12)


## A sealant canister: a steel-rimmed can in the era's paint with a printed
## label and a ribbed grip, a domed shoulder, a valve collar and a moulded
## head with its trigger, a nozzle up out of it in the seal's red and a
## safety clip.
static func _sealant(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var can := Paint.coat(Paint.YELLOW, 0.6, 0.3, 0.5) if era == Eras.NEW else _body(era)
	var metal := _metal(era)
	var steel := _steel()
	var head := _rubber() if era != Eras.FIRST else _brass()
	b.drum(0.0445, 0.012, Vector3(0.0, 0.0, 0.006), steel, ALONG, 24, 0.0455)
	b.drum(0.044, 0.139, Vector3(0.0, 0.0, 0.0815), can, ALONG, 24)
	b.drum(0.0458, 0.006, Vector3(0.0, 0.0, 0.151), steel, ALONG, 24)
	b.drum(0.042, 0.018, Vector3(0.0, 0.0, 0.163), steel, ALONG, 24, 0.024)
	b.drum(0.019, 0.008, Vector3(0.0, 0.0, 0.176), metal, ALONG, 16)
	# The label, banded in the company's teal over a black line.
	if era == Eras.SECOND:
		# A cord net over the can and a saltwood lever lashed to the head.
		for z in [0.03, 0.07, 0.11, 0.145]:
			b.ring(0.043, 0.0475, Vector3(0.0, 0.0, z), _cord(), ALONG, 6)
		for i in 6:
			var turn := Basis(Vector3.BACK, TAU * i / 6.0)
			_strand(b, turn * Vector3(0.0, 0.0458, 0.03), turn * Vector3(0.0, 0.0458, 0.145), 0.0025, _cord())
		_charm(b, Vector3(0.0, -0.04, 0.15), Vector3(0.0, -0.05, -1.0).normalized(), 0.035)
	else:
		var label := Paint.coat(Paint.BONE, 0.3, 0.0, 0.6)
		b.drum(0.0446, 0.036, Vector3(0.0, 0.0, 0.088), label, ALONG, 24)
		b.drum(0.0447, 0.008, Vector3(0.0, 0.0, 0.114), _accent(era) if era != Eras.NEW else Paint.coat(Paint.TEAL, 0.4, 0.0, 0.6), ALONG, 24)
		b.drum(0.0447, 0.002, Vector3(0.0, 0.0, 0.068), _ink(), ALONG, 24)
		b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.0, -0.0452, 0.088), 0.044, Basis(Vector3.RIGHT, PI * 0.5))
		b.box(Vector3(0.046, 0.002, 0.024), Vector3(0.0, -0.0446, 0.088), label, 0.0)
		for i in 3:
			b.box(Vector3(0.026 - i * 0.006, 0.0015, 0.002), Vector3(0.0, 0.0447, 0.096 - i * 0.007), _ink(), 0.0)
		if era == Eras.SKIMMER:
			_wraps(b, Vector3.ZERO, ALONG, 0.0462, 0.02, 0.05, 2, _tape())
			_wraps(b, Vector3.ZERO, ALONG, 0.0462, 0.132, 0.146, 1, _tape())
		else:
			for i in 16:
				var turn := Basis(Vector3.BACK, TAU * i / 16.0)
				b.box(Vector3(0.005, 0.003, 0.03), turn * Vector3(0.0, 0.045, 0.034), _grip(era), 0.001, turn)
	# The head, its trigger toward you, the nozzle up out of it.
	if era == Eras.SECOND:
		b.ball(0.022, Vector3(0.004, 0.0, 0.19), _glazed(), Vector3(1.0, 1.1, 0.75))
		_strand(b, Vector3(0.0, -0.012, 0.19), Vector3(0.0, -0.04, 0.16), 0.007, _wood())
		_wraps(b, Vector3(0.0, 0.0, 0.18), Basis.IDENTITY * ALONG, 0.02, -0.004, 0.006, 2, _cord())
	else:
		b.box(Vector3(0.034, 0.05, 0.026), Vector3(0.0, 0.002, 0.192), head, 0.008)
		b.box(Vector3(0.022, 0.008, 0.05), Vector3(0.0, -0.032, 0.17), head, 0.003, Basis(Vector3.RIGHT, -0.25))
		b.box(Vector3(0.036, 0.004, 0.012), Vector3(0.0, 0.014, 0.2), Paint.coat(Paint.YELLOW, 0.4, 0.0, 0.5), 0.001)
	var nozzle := Paint.coat(Paint.COPPER, 0.3, 0.85, 0.4) if era == Eras.FIRST else Paint.coat(Paint.FLARE_RED, 0.5, 0.0, 0.5)
	b.drum(0.008, 0.022, Vector3(0.0, 0.0, size.z - 0.012), nozzle, ALONG, 10, 0.0035)
	if era == Eras.SKIMMER:
		# A steel tube wired on to reach into a seam.
		b.drum(0.0035, 0.016, Vector3(0.0, 0.0, size.z - 0.008), steel, ALONG, 6)
		b.drum(0.0095, 0.004, Vector3(0.0, 0.0, size.z - 0.019), steel, ALONG, 8)


## A med kit of the colony clinic's issue: a moulded case in two halves on a
## gasket, rubber corner guards, a hinge, two latches either side of the
## medicine-red seal, and its teal cross on a raised panel. Colonial make is
## guarded in grey with orange latches; the First Kingdoms capped its corners
## and clasp in brass; the skimmer era's is a canvas pouch strapped in tape
## with a cross painted by hand; the second age's lost its lid and laid
## saltwood slats over it, corded, a water vial hung on it.
static func _med_kit(b: Paint.Pieces, era: StringName) -> void:
	var seal := Paint.coat(Catalog.KINDS[&"medicine"], 0.2, 0.0, 0.5)
	var teal := Paint.coat(Paint.TEAL, 0.2, 0.0, 0.5)
	if era == Eras.SKIMMER:
		var canvas := Paint.coat(SkimmerKit.CANVAS, 0.0, 0.0, 0.95, 0.8)
		b.box(Vector3(0.174, 0.112, 0.05), Vector3(0.0, 0.0, 0.026), canvas, 0.022)
		b.box(Vector3(0.16, 0.06, 0.012), Vector3(0.0, 0.025, 0.052), canvas, 0.006, Basis(Vector3.RIGHT, -0.06))
		for x in [-0.055, 0.055]:
			b.box(Vector3(0.024, 0.116, 0.054), Vector3(x, 0.0, 0.027), _tape(), 0.008)
		var painted := Basis(Vector3.RIGHT, -0.06) * Basis(Vector3.BACK, 0.05)
		b.box(Vector3(0.032, 0.01, 0.001), Vector3(0.0, 0.025, 0.0585), Paint.coat(SkimmerKit.PLATE_RED, 0.2), 0.0, painted)
		b.box(Vector3(0.01, 0.032, 0.001), Vector3(0.0, 0.025, 0.0585), Paint.coat(SkimmerKit.PLATE_RED, 0.2), 0.0, painted)
		b.box(Vector3(0.02, 0.01, 0.004), Vector3(0.0, 0.054, 0.04), seal, 0.001)
		# Its seams stitched round, and a steel buckle on its flap's strap.
		for y in [-0.054, 0.054]:
			b.box(Vector3(0.12, 0.0015, 0.0015), Vector3(0.0, y, 0.044), _ink(), 0.0)
		b.box(Vector3(0.014, 0.05, 0.003), Vector3(0.0, -0.022, 0.052), _tape(), 0.001)
		b.box(Vector3(0.018, 0.012, 0.004), Vector3(0.0, -0.002, 0.0545), _steel(), 0.002)
		return
	var shell := _body(era) if era != Eras.NEW else Paint.coat(Paint.BONE, 0.4, 0.0, 0.7)
	var guard := _rubber()
	match era:
		Eras.COLONIAL:
			guard = Paint.coat(ColonialKit.GREY, 0.6, 0.4, 0.45)
		Eras.FIRST:
			guard = _brass()
		Eras.SECOND:
			guard = _glazed()
	b.box(Vector3(0.172, 0.112, 0.03), Vector3(0.0, 0.0, 0.016), shell, 0.012)
	b.box(Vector3(0.166, 0.106, 0.006), Vector3(0.0, 0.0, 0.034), _rubber(), 0.002)
	if era == Eras.SECOND:
		for i in 4:
			var y := -0.039 + i * 0.026
			b.box(Vector3(0.168, 0.024, 0.01), Vector3(0.002 * (i % 2), y, 0.042), _wood(), 0.003, Basis(Vector3.BACK, 0.015 * (i - 1.5)))
		for x in [-0.05, 0.05]:
			b.box(Vector3(0.006, 0.112, 0.006), Vector3(x, 0.0, 0.049), _cord(), 0.0)
		b.ball(0.012, Vector3(0.0, 0.0, 0.052), Paint.coat(Paint.GLAZE, 0.1, 0.0, 0.25, 0.4), Vector3(1.4, 1.0, 0.8))
		_charm(b, Vector3(-0.05, 0.05, 0.05), Vector3(-0.5, -0.2, -0.2).normalized(), 0.02)
	else:
		b.box(Vector3(0.172, 0.112, 0.028), Vector3(0.0, 0.0, 0.051), shell, 0.012)
		b.box(Vector3(0.11, 0.072, 0.004), Vector3(0.0, -0.004, 0.0655), shell, 0.003)
		b.box(Vector3(0.05, 0.016, 0.004), Vector3(0.0, -0.004, 0.0675), teal, 0.001)
		b.box(Vector3(0.016, 0.05, 0.004), Vector3(0.0, -0.004, 0.0675), teal, 0.001)
		# Screws at the panel's corners, and the clinic's printed label by the latches.
		for x in [-0.049, 0.049]:
			for y in [-0.034, 0.026]:
				_screw(b, Vector3(x, y, 0.0675), 0.003, ALONG)
		b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.0, 0.043, 0.0651), 0.04)
		b.box(Vector3(0.06, 0.016, 0.002), Vector3(0.0, 0.043, 0.0645), Paint.coat(Paint.BONE, 0.2, 0.0, 0.7), 0.0)
		# A finger groove along the lid's edge where you lift it.
		b.box(Vector3(0.13, 0.003, 0.004), Vector3(0.0, 0.0555, 0.043), _rubber(), 0.0)
		# The latches either side of its seal, on the edge you open.
		var latch := Paint.coat(ColonialKit.ORANGE, 0.6, 0.0, 0.5) if era == Eras.COLONIAL else (_brass() if era == Eras.FIRST else _steel())
		for x in [-0.045, 0.045]:
			b.box(Vector3(0.022, 0.006, 0.026), Vector3(x, 0.0565, 0.038), latch, 0.002)
			b.box(Vector3(0.016, 0.004, 0.008), Vector3(x, 0.0575, 0.046), _rubber(), 0.001)
		b.box(Vector3(0.018, 0.004, 0.012), Vector3(0.0, 0.0575, 0.036), seal, 0.001)
		# The hinge on the far edge.
		for x in [-0.05, 0.0, 0.05]:
			b.drum(0.005, 0.03, Vector3(x, -0.0545, 0.037), _steel(), ACROSS, 8)
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			b.box(Vector3(0.026, 0.026, 0.062), Vector3(x * 0.076, y * 0.046, 0.033), guard, 0.008)


# --- Food -----------------------------------------------------------------

## A field ration: three meal bars sealed in tan foil, crimped at their
## ends and printed in food's colour, two side by side and one across them,
## loose as they're packed, never a cell's box. Eaten from, the top bar goes
## first and the next has its foil torn back from its meal; empty, only its
## foil is left.
static func _ration(b: Paint.Pieces, count: int) -> void:
	var foil := Paint.coat(Paint.RATION_FOIL, 0.15, 0.35, 0.45, 0.6)
	if count == 0:
		b.box(Vector3(0.11, 0.04, 0.005), Vector3(0.0, 0.0, 0.0025), foil, 0.002, Basis(Vector3.BACK, 0.2))
		return
	var food := Paint.coat(Catalog.KINDS[&"food"], 0.2, 0.0, 0.6)
	var bars := [Vector3(-0.002, -0.021, 0.0145), Vector3(0.002, 0.021, 0.0145), Vector3(0.0, 0.0, 0.0405)]
	var turns := [-0.04, 0.04, 0.1]
	var left := 3 if count < 0 else count
	for i in left:
		var opened := count > 0 and count < 3 and i == left - 1
		var long := 0.1 if opened else 0.124
		var turn := Basis(Vector3.BACK, turns[i])
		var at: Vector3 = bars[i] + turn * Vector3(-0.012 if opened else 0.0, 0.0, 0.0)
		b.box(Vector3(long, 0.04, 0.025), at, foil, 0.01, turn)
		for s in ([-1.0] if opened else [-1.0, 1.0]):
			var end := at + turn * Vector3(s * (long * 0.5 + 0.006), 0.0, 0.0)
			b.box(Vector3(0.014, 0.036, 0.004), end, foil, 0.001, turn)
			for k in 5:
				b.box(Vector3(0.012, 0.0025, 0.0055), end + turn * Vector3(0.0, -0.014 + k * 0.007, 0.0), foil, 0.0, turn)
		# Printed on its foil: food's stripe by one end and its lines.
		var top := at + turn * Vector3(0.0, 0.0, 0.0125)
		b.box(Vector3(0.012, 0.036, 0.0012), top + turn * Vector3(-long * 0.5 + 0.022, 0.0, 0.0), food, 0.0, turn)
		for k in 3:
			b.box(Vector3(0.03 - k * 0.007, 0.0016, 0.001), top + turn * Vector3(0.012, 0.008 - k * 0.005, 0.0), _ink(), 0.0, turn)
		if i == 2 and not opened:
			b.stamp(Paint.Mark.CONTRACTOR, top + turn * Vector3(0.012, -0.007, 0.0004), 0.026, turn)
			b.box(Vector3(0.028, 0.013, 0.0008), top + turn * Vector3(0.012, -0.007, 0.0), foil, 0.0, turn)
		if opened:
			for k in 3:
				b.box(Vector3(0.008, 0.014, 0.022), at + turn * Vector3(long * 0.5 + 0.002, -0.013 + k * 0.013, 0.0), foil, 0.0,
					turn * Basis(Vector3.UP, 0.35 * (k - 1)) * Basis(Vector3.BACK, 0.2 * (1 - k)))
			b.box(Vector3(0.034, 0.032, 0.019), at + turn * Vector3(long * 0.5 + 0.017, 0.0, -0.001),
				Paint.coat(Paint.RATION_BAR, 0.0, 0.0, 0.85, 0.4), 0.006, turn)


## Tubers as dug, washed of most of their soil: lumpy and eyed, three under
## and two over, the top ones eaten first.
static func _tubers(b: Paint.Pieces, count: int) -> void:
	var skin: Paint.Coat = Dress.TUBER
	var eye := Paint.coat(Dress.TUBER.color.darkened(0.3), 0.0, 0.0, 0.9, 0.6)
	var soil := Paint.coat(Paint.SOIL.lightened(0.1), 0.0, 0.0, 1.0, 0.8)
	var at := [Vector3(-0.044, -0.02, 0.024), Vector3(0.0, 0.016, 0.024), Vector3(0.045, -0.016, 0.024),
		Vector3(-0.021, 0.004, 0.052), Vector3(0.024, 0.002, 0.053)]
	var turns := [0.3, -0.5, 1.2, 1.9, -0.2]
	for i in (count if count >= 0 else 5):
		var turn := Basis(Vector3.BACK, turns[i]) * Basis(Vector3.RIGHT, 0.08 * (i - 2))
		var middle: Vector3 = at[i]
		b.ball(0.026, middle, skin, Vector3(1.22, 0.86, 0.78), turn)
		b.ball(0.014, middle + turn * Vector3(0.022, 0.006, 0.004), skin, Vector3(1.0, 0.9, 0.85), turn)
		for k in 3:
			var on := turn * Vector3(-0.022 + k * 0.016, 0.019 - (k % 2) * 0.004, 0.012)
			b.box(Vector3(0.003, 0.0025, 0.003), middle + on, eye, 0.0, turn)
		b.box(Vector3(0.012, 0.008, 0.002), middle + turn * Vector3(-0.006, -0.012, 0.019), soil, 0.001, turn)


## Oyster caps cut as they grew, a cluster a piece: three grey-brown fans
## shelved out from a stub of stem over cream gills, the top one eaten first.
static func _caps(b: Paint.Pieces, count: int) -> void:
	var cap: Paint.Coat = Dress.CAP
	var gills: Paint.Coat = Dress.GILLS
	var roots := [Vector3(-0.036, -0.03, 0.013), Vector3(0.036, -0.032, 0.013), Vector3(0.0, 0.03, 0.024)]
	var ways := [0.15, -0.15, PI]
	for i in (count if count >= 0 else 3):
		var root: Vector3 = roots[i]
		var way: float = ways[i]
		var back := Vector3(sin(way), -cos(way), 0.0)
		b.drum(0.007, 0.018, root + back * 0.004, gills, Basis(Vector3.BACK, way) * Basis(Vector3.RIGHT, -1.1), 8, 0.005)
		for k in 3:
			var a := way + (k - 1) * 0.6
			var out := Vector3(-sin(a), cos(a), 0.0)
			var side := Vector3.BACK.cross(out)
			var shelf := Basis(side, -0.32 + 0.08 * k) * Basis(side, Vector3.BACK, out)
			var r := 0.022 - absf(k - 1) * 0.003
			var at := root + out * r * 0.75 + Vector3(0.0, 0.0, 0.008 + 0.004 * k)
			b.ball(1.0, at, cap, Vector3(r * 0.9, r * 0.2, r), shelf)
			b.drum(r * 0.82, 0.006, at - shelf.y * 0.004, gills, shelf, 6, r * 0.25)


## A cake of pan salt, crusted with cubic crystals, tied with cord.
static func _salt(b: Paint.Pieces) -> void:
	var cake := Dress.SALT
	var crystal := Paint.coat(Dress.SALT.color, 0.0, 0.0, 0.22, 0.1)
	var cord := Paint.coat(Paint.ROPE, 0.0, 0.0, 1.0, 0.4)
	var turn := Basis(Vector3.BACK, 0.12)
	b.box(Vector3(0.054, 0.048, 0.024), Vector3(0.0, 0.0, 0.012), cake, 0.006, turn)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 11:
		var wide := rng.randf_range(0.007, 0.015)
		var at := turn * Vector3(rng.randf_range(-0.019, 0.019), rng.randf_range(-0.016, 0.016), 0.024 + wide * 0.3)
		var spin := Basis(Vector3(rng.randf() - 0.5, rng.randf() - 0.5, 1.0).normalized(), rng.randf() * TAU)
		b.box(Vector3.ONE * wide, at, crystal, wide * 0.12, spin)
	for s in [-1.0, 1.0]:
		b.box(Vector3(0.004, 0.003, 0.023), turn * Vector3(0.008, s * 0.0255, 0.0125), cord, 0.0, turn)
	_strand(b, turn * Vector3(0.008, -0.025, 0.0245), turn * Vector3(0.008, 0.025, 0.0245), 0.004, cord)
	b.box(Vector3.ONE * 0.008, turn * Vector3(0.008, 0.0, 0.028), cord, 0.002, Basis(Vector3.BACK, 0.7))


## Sprigs of saltbush cut and tied: woody stems, each with small oval leaves
## silvered by their salt, fanned from the cord at their foot.
static func _leaves(b: Paint.Pieces, count: int) -> void:
	var leaf: Paint.Coat = Dress.SALTBUSH
	var wood: Paint.Coat = Dress.WOOD
	var foot := Vector3(0.0, -0.0295, 0.016)
	var shown := count if count >= 0 else 5
	for i in shown:
		var a := (i - 2) * 0.33
		var d := Vector3(sin(a), cos(a), 0.0)
		var z := 0.012 + (i % 3) * 0.006
		var base := foot + Vector3(0.0, 0.0, z - foot.z)
		_strand(b, base, base + d * 0.046, 0.0026, wood)
		for k in 5:
			var side := 0.0 if k == 4 else (0.6 if k % 2 == 0 else -0.6)
			var out := Basis(Vector3.BACK, -side) * d
			var at := base + d * 0.046 * (0.3 + 0.175 * k) + out * 0.009 + Vector3(0.0, 0.0, 0.003 * (k % 2))
			var lean := Vector3.BACK.cross(out).normalized()
			b.drum(0.5, 0.0024, at, leaf, Basis(lean * 0.01, Vector3.BACK, out * 0.02), 8)
	if shown > 0:
		var cord := Paint.coat(Paint.ROPE, 0.0, 0.0, 1.0, 0.4)
		b.drum(0.008, 0.012, foot + Vector3(0.0, 0.004, 0.0), cord, Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, 0.4), 8)
		_strand(b, foot + Vector3(0.006, 0.0, 0.0), foot + Vector3(0.012, -0.008, -0.004), 0.003, cord)


## A bundle of cut coalcane, its dark stalks ringed at their nodes and their
## cut ends pale, lashed in two places with cord.
static func _bundle(b: Paint.Pieces, size: Vector3) -> void:
	var stalk := Paint.coat(Paint.CANE, 0.0, 0.0, 0.8, 0.6)
	var node: Paint.Coat = Dress.WOOD
	var pith := Paint.coat(Paint.CANE_PITH, 0.0, 0.0, 0.9, 0.3)
	var cord := Paint.coat(Paint.CORD, 0.0, 0.0, 0.95, 0.6)
	var r := 0.047
	var rows := [[-0.082, [-0.094, 0.0, 0.094]], [0.0, [-0.141, -0.047, 0.047, 0.141]], [0.082, [-0.094, 0.0, 0.094]]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for row: Array in rows:
		for x: float in row[1]:
			var y: float = row[0]
			var from := rng.randf_range(0.004, 0.03)
			var to := size.z - rng.randf_range(0.004, 0.03)
			var radius := r * rng.randf_range(0.9, 1.0)
			b.drum(radius, to - from, Vector3(x, y, (from + to) * 0.5), stalk, ALONG, 8)
			for z in [from - 0.0015, to + 0.0015]:
				b.drum(radius * 0.84, 0.003, Vector3(x, y, z), pith, ALONG, 6)
			for k in (2 if absf(x) > 0.05 else 1):
				var at := lerpf(from, to, rng.randf_range(0.2, 0.4) + k * 0.4)
				b.drum(radius * 1.1, 0.016, Vector3(x, y, at), node, ALONG, 6)
	# Two lashings round the bundle, each knotted on top.
	var hull := [Vector2(-0.188, 0.0), Vector2(-0.14, 0.13), Vector2(0.0, 0.13), Vector2(0.14, 0.13),
		Vector2(0.188, 0.0), Vector2(0.14, -0.13), Vector2(0.0, -0.13), Vector2(-0.14, -0.13)]
	for z in [0.17, 0.48]:
		for turn in 1:
			var dz: float = z + turn * 0.011
			for i in hull.size():
				var p: Vector2 = hull[i]
				var q: Vector2 = hull[(i + 1) % hull.size()]
				_strand(b, Vector3(p.x, p.y, dz), Vector3(q.x, q.y, dz), 0.009, cord)
		b.box(Vector3(0.022, 0.014, 0.024), Vector3(0.03, 0.135, z + 0.006), cord, 0.005)
