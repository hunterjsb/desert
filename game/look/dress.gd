class_name Dress
extends RefCounted
## What each frame and part looks like in B's paint, inside its own box so
## nothing it touches changes: one merged mesh per catalog id, shared by every
## copy. A frame is centred on its box; a part stands out from its socket
## along +Z. Shapes are placeholders like the boxes were; only the finish is
## meant.

static var _made := {}
## A lineage's looks, let go once nothing wears them; and each thing's shell.
static var _lines := {}
static var _shells := {}
static var _marks := {}


## A frame's look, or null to keep a grey box. `extra` is its mast's height.
static func frame(id: StringName, size: Vector3, extra := 0.0) -> ArrayMesh:
	return _cached(&"frame", id, func() -> ArrayMesh: return _frame(id, size, extra))


## A part's look, or null to keep a grey box; food in pieces drawn with
## `count` of them left.
static func part(id: StringName, size: Vector3, count := -1) -> ArrayMesh:
	var key := id if count < 0 else StringName("%s:%d" % [id, count])
	return _cached(&"part", key, func() -> ArrayMesh: return _part(id, size, count))


## A compass's needle, its north tip along +Y: red, and lit so it glows a
## little, over a steel south half on a black pivot.
static func needle() -> ArrayMesh:
	return _cached(&"needle", &"compass", func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		b.box(Vector3(0.008, 0.042, 0.003), Vector3(0.0, 0.021, 0.0), Paint.coat(Color(0.85, 0.16, 0.08), 0.0, 0.0, 0.4, 0.0, 1.2), 0.001)
		b.box(Vector3(0.008, 0.036, 0.003), Vector3(0.0, -0.018, 0.0), Paint.coat(Paint.STEEL, 0.0, 0.6, 0.4, 0.0), 0.001)
		b.drum(0.005, 0.005, Vector3.ZERO, Paint.coat(Paint.BLACK, 0.0, 0.3), Basis(Vector3.RIGHT, PI / 2.0), 10)
		return b.commit())


## A radio's needle, standing up its own +Y across the band: thin, red, and
## lit while it plays.
static func dial_needle() -> ArrayMesh:
	return _cached(&"needle", &"radio", func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		b.box(Vector3(0.0022, Radio.BAND_HEIGHT - 0.008, 0.0016), Vector3.ZERO,
			Paint.coat(Color(0.85, 0.12, 0.06), 0.0, 0.0, 0.4, 0.0, 1.2), 0.0005)
		return b.commit())


## A radio's knob, facing out along its own +Z from its back at the origin:
## black and ridged for the grip, with a bone line to show how far it's
## turned, faintly lit so it reads in the dark.
static func knob() -> ArrayMesh:
	return _cached(&"knob", &"radio", func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		var black := Paint.coat(Paint.BLACK, 0.3, 0.3, 0.6)
		var r := 0.026
		var out := Basis(Vector3.RIGHT, PI / 2.0)
		b.drum(r, 0.02, Vector3(0.0, 0.0, 0.01), black, out, 18)
		for i in 12:
			var turn := Basis(Vector3.BACK, i * TAU / 12.0)
			b.box(Vector3(0.005, 0.004, 0.018), turn * Vector3(0.0, r, 0.0) + Vector3(0.0, 0.0, 0.01), black, 0.001, turn)
		b.drum(r * 0.8, 0.004, Vector3(0.0, 0.0, 0.021), Paint.coat(Paint.GUNMETAL, 0.4, 0.5, 0.45), out, 18)
		b.box(Vector3(0.004, r * 0.75, 0.002), Vector3(0.0, r * 0.42, 0.0235), Paint.coat(Paint.BONE, 0.0, 0.0, 0.6, 0.0, 0.6), 0.0005)
		return b.commit())


## What turns on a frame's mast head, about its own +Z, or null for none: a
## turbine's hub and blades, something to see turn into the wind, not to touch.
static func rotor(id: StringName) -> ArrayMesh:
	return _cached(&"rotor", id, func() -> ArrayMesh:
		if id != &"turbine":
			return null
		var b := Paint.Pieces.new()
		b.drum(0.06, 0.08, Vector3(0.0, 0.0, 0.04), Paint.coat(Paint.BLACK, 0.3, 0.3, 0.6), Basis(Vector3.RIGHT, PI / 2.0), 12)
		for s in [-1, 1]:
			b.box(Vector3(0.55, 0.08, 0.02), Vector3(s * 0.32, 0.0, 0.06), Paint.coat(Paint.BONE, 0.8), 0.006)
			b.box(Vector3(0.08, 0.082, 0.022), Vector3(s * 0.56, 0.0, 0.06), Paint.coat(Paint.YELLOW, 0.6), 0.004)
		return b.commit())


## A free socket's tell: a dark bezel with a tab in its kind's colour.
static func tell(kind: StringName) -> ArrayMesh:
	return _cached(&"tell", kind, func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		var bezel := Paint.coat(Paint.BLACK, 0.6, 0.3, 0.5, 0.6)
		for s in [-1, 1]:
			b.box(Vector3(0.13, 0.022, 0.012), Vector3(0.0, s * 0.054, 0.006), bezel, 0.004)
			b.box(Vector3(0.022, 0.086, 0.012), Vector3(s * 0.054, 0.0, 0.006), bezel, 0.004)
		b.box(Vector3(0.088, 0.088, 0.006), Vector3(0.0, 0.0, 0.003), Paint.coat(Color(0.04, 0.04, 0.04), 0.0, 0.0, 0.7, 0.3))
		b.box(Vector3(0.084, 0.04, 0.008), Vector3(0.0, 0.022, 0.005), Paint.coat(Catalog.KINDS[kind], 0.0, 0.0, 0.5, 0.15, 0.35), 0.002)
		return b.commit())


## A thing's look with its lineage's marks over it (Paint.Shell), merged into
## one mesh: each entry's marks are made once a thing, each lineage's look
## once while anything wears it. Null where it has no look to mark.
static func lineage(id: StringName, line: Array) -> ArrayMesh:
	var key := [id, Eras.key(line)]
	var kept: WeakRef = _lines.get(key)
	var made: ArrayMesh = kept.get_ref() if kept != null else null
	if made == null:
		made = _lineage(id, line)
		if made != null:
			_lines[key] = weakref(made)
	return made


static func _lineage(id: StringName, line: Array) -> ArrayMesh:
	var own := _own(id)
	var shell := shell(id)
	if own == null or own.get_surface_count() == 0 or shell == null:
		return own
	var overs := []
	for entry: Array in line:
		var key := [id, Eras.entry_key(entry)]
		if not _marks.has(key):
			var marks := Paint.Over.new()
			shell.layer(marks, entry)
			_marks[key] = marks.arrays()
		if not _marks[key].is_empty():
			overs.append(_marks[key])
	return own if overs.is_empty() else Paint.merged(own, overs)


## Where a lineage's marks go on a thing, or null where they don't: worked
## out once from its look, clear of its sockets, its charge light, its mast
## and its stamps.
static func shell(id: StringName) -> Paint.Shell:
	if _shells.has(id):
		return _shells[id]
	var made: Paint.Shell = null
	var own := _own(id)
	if Catalog.lineal(id) and not id in Catalog.BARE and own != null and own.get_surface_count() > 0:
		var avoid := PackedVector3Array()
		var box: AABB
		if Catalog.PARTS.has(id):
			var size: Vector3 = Catalog.PARTS[id].size
			box = AABB(Vector3(-size.x * 0.5, -size.y * 0.5, 0.0), size)
		else:
			var spec: Dictionary = Catalog.DEVICES.get(id, {"size": Vector3(0.06, Stake.LENGTH, 0.06), "sockets": []})
			var h: Vector3 = spec.size * 0.5
			box = AABB(-h, spec.size)
			for entry: Array in spec.sockets:
				avoid.append(entry[1])
			if spec.sockets.any(func(e: Array) -> bool: return e[0] == &"battery"):
				avoid.append(Vector3(h.x, h.y - 0.05, h.z - 0.05))
			if spec.has("mast"):
				avoid.append(Vector3(0.0, h.y, 0.0))
		made = Paint.Shell.new(own, box, Catalog.PARTS.has(id), Catalog.ROUND.get(id, []), avoid, hash(id))
		# Too small to read, marks or not.
		if made.unit < 0.012:
			made = null
	_shells[id] = made
	return made


## A thing's own look by its catalog id, as the catalog makes it.
static func _own(id: StringName) -> ArrayMesh:
	if id == &"stake":
		return frame(&"stake", Vector3(0.06, Stake.LENGTH, 0.06))
	if Catalog.DEVICES.has(id):
		var spec: Dictionary = Catalog.DEVICES[id]
		return frame(id, spec.size, spec.get("mast", 0.0))
	if Catalog.PARTS.has(id):
		return part(id, Catalog.PARTS[id].size)
	return null


## Builds every look now, while the world loads: the first of a kind costs
## up to a dozen milliseconds, too long for a find laid out while streaming.
## Each thing's shell too, where its lineage's marks would go: a few ms a thing.
static func prepare() -> void:
	for id: StringName in Catalog.DEVICES:
		Catalog.device(id).free()
		shell(id)
	Catalog.stake().free()
	shell(&"stake")
	for id: StringName in Catalog.PARTS:
		Catalog.part(id).free()
		shell(id)
		var grows: Dictionary = Catalog.PARTS[id].get("crop", {})
		if grows.is_empty():
			continue
		var stages := [Plant.SEEDLING, Plant.YOUNG, Plant.RIPE] + ([Plant.MATURE] if grows.stages.has("bursts") else [])
		var steps := Plant.FOLD_STEPS if grows.stages.has("folds") else 0
		for stage: StringName in stages:
			for step in steps + 1:
				crop(id, stage, step / float(maxi(steps, 1)))


static func _cached(group: StringName, id: StringName, build: Callable) -> ArrayMesh:
	var key := [group, id]
	if not _made.has(key):
		_made[key] = build.call()
	return _made[key]


static func _frame(id: StringName, size: Vector3, extra: float) -> ArrayMesh:
	var h := size * 0.5
	var b := Paint.Pieces.new(-h.y)
	var gun := Paint.coat(Paint.GUNMETAL)
	var teal := Paint.coat(Paint.TEAL)
	var black := Paint.coat(Paint.BLACK, 0.3, 0.3, 0.6)
	if PowerLooks.frame(b, id, size) or VarranLooks.frame(b, id, size) or NomadLooks.frame(b, id, size):
		return b.commit()
	match id:
		&"planter":
			# Another maker's growing tub, bone white on gunmetal skids.
			# Its top sits under the rim, and the rim's rails meet rather than cross.
			b.box(Vector3(size.x - 0.02, size.y - 0.054, size.z - 0.02), Vector3(0.0, 0.023, 0.0), Paint.coat(Paint.BONE), 0.03)
			b.box(Vector3(size.x - 0.08, 0.02, size.z - 0.08), Vector3(0.0, h.y - 0.012, 0.0), Paint.coat(Paint.SOIL, 0.0, 0.0, 1.0, 0.0), 0.004)
			for s in [-1, 1]:
				b.box(Vector3(size.x, 0.05, 0.05), Vector3(0.0, h.y - 0.025, s * (h.z - 0.025)), teal)
				b.box(Vector3(0.05, 0.05, size.z - 0.1), Vector3(s * (h.x - 0.025), h.y - 0.025, 0.0), teal)
				b.box(Vector3(0.12, 0.06, size.z - 0.06), Vector3(s * (h.x - 0.16), -h.y + 0.03, 0.0), gun)
			b.box(Vector3(size.x - 0.12, 0.012, 0.004), Vector3(0.0, -0.03, h.z - 0.009), black, 0.001)
		&"turbine":
			b.box(Vector3(size.x, size.y - 0.04, size.z), Vector3(0.0, -0.02, 0.0), gun, 0.03)
			b.box(Vector3(size.x - 0.06, 0.04, size.z - 0.06), Vector3(0.0, h.y - 0.02, 0.0), Paint.coat(Paint.YELLOW, 0.8), 0.01)
			for side in 4:
				var turn := Basis(Vector3.UP, side * PI * 0.5)
				# Its maker's sign on the side nothing plugs into.
				if side == 2:
					b.stamp(Paint.Mark.WIND_MAKER, turn * Vector3(0.0, -0.02, h.z), 0.24, turn, Paint.Ink.PALE)
				b.box(Vector3(size.x - 0.12, size.y - 0.14, 0.012), turn * Vector3(0.0, -0.02, h.z - 0.004), teal, 0.004, turn)
			# The mast; its hub and blades are its rotor, on the mast's head.
			b.drum(0.04, extra, Vector3(0.0, h.y + extra * 0.5, 0.0), gun, Basis.IDENTITY, 12, 0.03)
		&"condenser":
			for x in [-1, 1]:
				for z in [-1, 1]:
					b.box(Vector3(0.06, size.y, 0.06), Vector3(x * (h.x - 0.03), 0.0, z * (h.z - 0.03)), gun, 0.01)
			# The contractor's tag that set it up, under the louvres on its free side.
			b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.0, -0.12, -h.z + 0.02), 0.2, Basis(Vector3.UP, PI), Paint.Ink.PALE)
			b.box(Vector3(size.x - 0.04, size.y - 0.06, size.z - 0.04), Vector3.ZERO, teal, 0.01)
			# Louvres the night air comes in through.
			for side in 4:
				var turn := Basis(Vector3.UP, side * PI * 0.5)
				for i in 5:
					b.box(Vector3(size.x - 0.16, 0.014, 0.016), turn * Vector3(0.0, 0.08 + i * 0.045, h.z - 0.012), black, 0.003, turn)
			b.box(Vector3(size.x + 0.006, 0.056, size.z + 0.006), Vector3(0.0, h.y - 0.025, 0.0), gun, 0.012)
			# Its fan's ring, under the top mount's tell and over the lid.
			b.drum(0.2, 0.008, Vector3(0.0, h.y + 0.001, 0.0), black, Basis.IDENTITY, 20)
			_hazard(b, Vector3(size.x * 0.7, 0.035, 0.012), Vector3(0.0, -h.y + 0.05, h.z - 0.006), Basis.IDENTITY)
		&"shield", &"light_shield":
			# A different maker: bone white, round, finned, on pads for its sockets.
			# Bought new, it carries its maker's sign on its back; a deep one wears
			# the tag of the contractor who fitted it there, its maker's only on
			# the emitter.
			var r := h.x * 0.88
			var back := Basis(Vector3.UP, PI)
			var fitted := id == &"shield"
			b.drum(h.x * 0.98, size.y * 0.24, Vector3(0.0, -h.y + size.y * 0.12, 0.0), gun, Basis.IDENTITY, 20)
			b.stamp(Paint.Mark.CONTRACTOR if fitted else Paint.Mark.SHIELD_MAKER, Vector3(0.0, -h.y + size.y * 0.52, -r),
				0.12 if fitted else 0.16, back)
			b.drum(r, size.y * 0.6, Vector3(0.0, -h.y + size.y * 0.5, 0.0), Paint.coat(Paint.BONE, 0.4), Basis.IDENTITY, 24)
			for i in 8:
				var turn := Basis(Vector3.UP, i * TAU / 8.0 + PI / 8.0)
				b.box(Vector3(0.015, size.y * 0.4, h.x * 0.25), turn * Vector3(0.0, -0.02, r + h.x * 0.06), gun, 0.004, turn)
			for turn: Basis in [Basis.IDENTITY, Basis(Vector3.UP, PI * 0.5), Basis(Vector3.UP, -PI * 0.5)]:
				b.box(Vector3(0.13, 0.13, h.x - r + 0.02), turn * Vector3(0.0, -0.05 * size.y / 0.42, h.x - (h.x - r + 0.02) * 0.5), gun, 0.01, turn)
			if fitted:
				b.stamp(Paint.Mark.SHIELD_MAKER, Vector3(0.0, h.y - size.y * 0.14, -h.x * 0.65), 0.1, back, Paint.Ink.PALE)
			b.drum(h.x * 0.65, size.y * 0.12, Vector3(0.0, h.y - size.y * 0.14, 0.0), gun, Basis.IDENTITY, 20)
			b.ball(h.x * 0.5, Vector3(0.0, h.y - size.y * 0.13, 0.0), Paint.coat(Paint.CELL, 0.0, 0.4, 0.15, 0.4), Vector3(1.0, 0.55, 1.0))
			# A bracket out to the box's corner, where every frame's charge light sits.
			b.box(Vector3(0.09, 0.07, 0.09), Vector3(h.x - 0.045, h.y - 0.05, h.z - 0.05), gun, 0.01)
		&"light_panel":
			b.box(Vector3(size.x - 0.006, 0.03, size.z - 0.06), Vector3(0.0, -0.01, 0.0), Paint.coat(Paint.STEEL, 0.4, 0.5), 0.006)
			for s in [-1, 1]:
				b.box(Vector3(size.x, size.y, 0.03), Vector3(0.0, 0.0, s * (h.z - 0.015)), gun, 0.006)
			_cells(b, Vector2(size.x - 0.04, size.z - 0.08), 4, 2, Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0.0, 0.008, 0.0))
		&"bedroll":
			# Company canvas rolled tight on its pad, the pale lining showing at
			# each end, two black straps round it.
			var along := Basis(Vector3.RIGHT, PI / 2.0)
			b.drum(h.x - 0.005, size.z - 0.04, Vector3.ZERO, Paint.coat(Paint.TEAL, 0.0, 0.0, 0.95), along, 18)
			for z in [-1, 1]:
				b.drum(h.x - 0.03, 0.02, Vector3(0.0, 0.0, z * (h.z - 0.02)), Paint.coat(Paint.BONE, 0.0, 0.0, 0.95), along, 18)
				b.drum(h.x + 0.002, 0.04, Vector3(0.0, 0.0, z * 0.26), black, along, 18)
		&"survival_kit":
			# Packed to be found: the brightest thing on the sand.
			b.box(Vector3(size.x - 0.02, size.y - 0.02, size.z - 0.02), Vector3.ZERO, Paint.coat(Paint.YELLOW, 0.7), 0.03)
			b.box(Vector3(size.x - 0.01, 0.014, size.z - 0.01), Vector3(0.0, h.y - 0.07, 0.0), black, 0.003)
			for x in [-1, 1]:
				for y in [-1, 1]:
					for z in [-1, 1]:
						b.box(Vector3(0.06, 0.06, 0.06), Vector3(x * (h.x - 0.03), y * (h.y - 0.03), z * (h.z - 0.03)), gun, 0.01)
				b.box(Vector3(0.03, 0.06, 0.012), Vector3(x * (h.x - 0.03), h.y - 0.07, h.z - 0.003), black, 0.004)
		&"board":
			# Tilg & Standard's issue in the company's paint: its batch stencil
			# on the tail, the company's consignment code on a deep one.
			var tail := Basis(Vector3.LEFT, Vector3.BACK, Vector3.UP)
			b.stamp(Paint.Mark.CONSIGNMENT, Vector3(0.0, h.y, h.z - 0.1), 0.26, tail, Paint.Ink.PALE)
			b.box(Vector3(size.x, 0.03, size.z), Vector3(0.0, h.y - 0.015, 0.0), teal, 0.01)
			b.box(Vector3(size.x - 0.06, 0.006, size.z * 0.55), Vector3(0.0, h.y, 0.08), Paint.coat(Color(0.05, 0.05, 0.05), 0.2, 0.0, 0.95, 1.0), 0.002)
			b.box(Vector3(size.x - 0.04, size.y - 0.03, size.z - 0.1), Vector3(0.0, -0.015, 0.0), gun, 0.012)
			_hazard(b, Vector3(size.x + 0.004, 0.05, 0.034), Vector3(0.0, h.y - 0.015, -h.z + 0.06), Basis(Vector3.RIGHT, -PI / 2.0))
			for z in [-0.35, 0.35]:
				b.drum(0.07, 0.012, Vector3(0.0, -h.y + 0.005, z), Paint.coat(Color(0.45, 0.8, 1.0), 0.0, 0.0, 0.3, 0.3, 2.0), Basis.IDENTITY, 16)
		&"racer_board":
			# The skimmer era's racer: narrow, a pointed nose and a kicked tail,
			# in its crew's hand-painted red with a pale stripe, tape round its
			# rails, three small pads, and the crew's patch on its tail.
			var red := Paint.coat(SkimmerKit.PLATE_RED, 0.9, 0.0, 0.55)
			var tape := Paint.coat(SkimmerKit.TAPE, 0.2, 0.0, 0.8, 0.6)
			b.box(Vector3(0.26, size.y - 0.035, size.z - 0.2), Vector3(0.0, -0.012, 0.04), gun, 0.01)
			b.box(Vector3(0.3, 0.024, 0.86), Vector3(0.0, h.y - 0.018, 0.05), red, 0.008)
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.17, 0.024, 0.3), Vector3(s * 0.055, h.y - 0.018, -h.z + 0.19), red, 0.008,
					Basis(Vector3.UP, s * 0.42))
			b.box(Vector3(0.28, 0.024, 0.2), Vector3(0.0, h.y - 0.004, h.z - 0.1), red, 0.008, Basis(Vector3.RIGHT, -0.22))
			b.box(Vector3(0.035, 0.004, 1.0), Vector3(0.0, h.y - 0.005, -0.02), Paint.coat(Paint.BONE, 0.7), 0.001)
			b.box(Vector3(0.2, 0.004, 0.4), Vector3(0.0, h.y - 0.004, -0.1), Paint.coat(Color(0.05, 0.05, 0.05), 0.2, 0.0, 0.95, 1.0), 0.001)
			for z in [-0.24, 0.3]:
				b.box(Vector3(0.31, 0.032, 0.04), Vector3(0.0, h.y - 0.018, z), tape, 0.004)
			b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(0.0, h.y + 0.001, h.z - 0.32), 0.22, Basis(Vector3.LEFT, Vector3.BACK, Vector3.UP),
				Paint.Ink.PALE)
			b.box(Vector3(0.24, 0.004, 0.13), Vector3(0.0, h.y - 0.001, h.z - 0.32), red, 0.001)
			for z in [-0.42, 0.0, 0.4]:
				b.drum(0.055, 0.012, Vector3(0.0, -h.y + 0.006, z), Paint.coat(Color(0.45, 0.8, 1.0), 0.0, 0.0, 0.3, 0.3, 2.0), Basis.IDENTITY, 14)
			b.box(Vector3(0.012, 0.04, 0.12), Vector3(0.0, -h.y + 0.01, h.z - 0.12), gun, 0.004)
		&"patrol_board":
			# The Knights' patrol board: wide and plated, a steel bumper on its
			# nose lashed with cord, armour down its rails, its deck the order's
			# grey with their daubed sign and, every crate accounted for, its
			# stencil on the tail; four dim pads under its weight.
			var grey := Paint.coat(Color(0.46, 0.46, 0.44), 0.6, 0.0, 0.85)
			var cord := Paint.coat(Paint.CORD, 0.1, 0.0, 0.9, 0.5)
			var daub := Paint.coat(SecondAgeKit.DAUB, 0.5, 0.0, 0.9, 0.8)
			var plate := Paint.coat(SkimmerKit.OLIVE, 1.0, 0.4, 0.6)
			var steel := Paint.coat(Paint.STEEL, 0.6, 0.8, 0.45)
			b.box(Vector3(size.x - 0.02, size.y - 0.03, size.z - 0.08), Vector3(0.0, -0.015, 0.0), gun, 0.012)
			b.stamp(Paint.Mark.CONSIGNMENT, Vector3(0.0, h.y, h.z - 0.1), 0.24, Basis(Vector3.LEFT, Vector3.BACK, Vector3.UP),
				Paint.Ink.PALE)
			b.box(Vector3(size.x - 0.04, 0.03, size.z - 0.06), Vector3(0.0, h.y - 0.015, 0.01), grey, 0.01)
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.03, size.y - 0.01, size.z - 0.18), Vector3(s * (h.x - 0.015), -0.005, 0.03), plate, 0.008)
			b.box(Vector3(size.x + 0.02, 0.045, 0.045), Vector3(0.0, -0.005, -h.z + 0.02), steel, 0.01)
			for s in [-1.0, 1.0]:
				b.box(Vector3(0.03, 0.03, 0.1), Vector3(s * 0.12, -0.01, -h.z + 0.08), steel, 0.006)
				b.box(Vector3(0.04, 0.04, 0.02), Vector3(s * 0.12, -0.01, -h.z + 0.07), cord, 0.004)
			b.box(Vector3(0.04, 0.004, 0.34), Vector3(0.0, h.y + 0.001, 0.18), daub, 0.001)
			b.box(Vector3(0.22, 0.004, 0.04), Vector3(0.0, h.y + 0.001, 0.09), daub, 0.001)
			b.box(Vector3(size.x - 0.1, 0.004, 0.36), Vector3(0.0, h.y + 0.0005, -0.28), Paint.coat(Color(0.05, 0.05, 0.05), 0.2, 0.0, 0.95, 1.0), 0.001)
			for z in [-0.48, -0.16, 0.16, 0.48]:
				b.drum(0.06, 0.012, Vector3(0.0, -h.y + 0.005, z), Paint.coat(Color(0.45, 0.8, 1.0), 0.0, 0.0, 0.3, 0.3, 1.1), Basis.IDENTITY, 14)
		&"temple_board":
			# Made at Mother Cistern's temple: an old hover core under a deck of
			# saltbush planks lashed with fern cord, a round ceramic cap on its
			# nose in her blue glaze, the sign of Tu on a limewashed patch, a
			# water vial tied at one side and a tassel at the tail.
			var wood := Paint.coat(Paint.SALTWOOD, 0.2, 0.0, 0.8, 0.8)
			var cord := Paint.coat(Paint.CORD, 0.1, 0.0, 0.9, 0.5)
			var lime := Paint.coat(Paint.LIMEWASH, 0.35, 0.0, 0.88)
			var glaze := Paint.coat(Paint.GLAZE, 0.25, 0.0, 0.25, 0.4)
			var ceramic := Paint.coat(Paint.CERAMIC, 0.5, 0.0, 0.35, 0.7)
			b.box(Vector3(0.24, size.y - 0.035, size.z - 0.4), Vector3(0.0, -0.014, 0.02), gun, 0.01)
			var planks := [[-0.115, 1.18], [0.0, 1.24], [0.115, 1.14]]
			for k in planks.size():
				var x: float = planks[k][0]
				b.box(Vector3(0.104, 0.022, planks[k][1]), Vector3(x, h.y - 0.014, 0.02 + k * 0.012), wood, 0.006)
			for z in [-0.44, -0.12, 0.2, 0.48]:
				b.box(Vector3(size.x + 0.008, 0.03, 0.022), Vector3(0.0, h.y - 0.016, z), cord, 0.004)
			b.ball(0.1, Vector3(0.0, -0.004, -h.z + 0.02), ceramic, Vector3(1.7, 0.5, 0.6))
			b.box(Vector3(size.x - 0.02, 0.036, 0.03), Vector3(0.0, -0.004, -h.z + 0.07), glaze, 0.006)
			b.stamp(Paint.Mark.TU, Vector3(0.0, h.y + 0.0, 0.3), 0.18, Basis(Vector3.LEFT, Vector3.BACK, Vector3.UP))
			b.box(Vector3(0.2, 0.004, 0.11), Vector3(0.0, h.y - 0.002, 0.3), lime, 0.001)
			b.drum(0.022, 0.09, Vector3(h.x + 0.01, -0.005, 0.05), Paint.coat(Paint.SAND_GLASS, 0.3, 0.2, 0.1, 0.4),
				Basis(Vector3.RIGHT, PI / 2.0), 10)
			b.box(Vector3(0.03, 0.045, 0.02), Vector3(h.x + 0.005, -0.005, 0.05), cord, 0.003)
			for i in 3:
				b.box(Vector3(0.008, 0.07, 0.008), Vector3(-h.x + 0.05 + i * 0.012, -0.02, h.z + 0.012),
					Paint.coat(Paint.DYED, 0.3, 0.0, 0.85), 0.0, Basis(Vector3.BACK, (i - 1) * 0.12))
			for z in [-0.3, 0.32]:
				b.drum(0.075, 0.014, Vector3(0.0, -h.y + 0.004, z), ceramic, Basis.IDENTITY, 16)
				b.drum(0.055, 0.016, Vector3(0.0, -h.y + 0.004, z), Paint.coat(Color(0.45, 0.8, 1.0), 0.0, 0.0, 0.3, 0.3, 1.6), Basis.IDENTITY, 14)
		&"radio":
			# A set made to carry: across the top of its face a band scale that
			# lights while it plays, under it a speaker's slats and the bosses
			# its knobs turn on; a handle, an aerial up from the back. The
			# needle and knobs are the radio's own, to turn.
			b.box(Vector3(size.x - 0.02, size.y - 0.02, size.z - 0.02), Vector3.ZERO, teal, 0.02)
			for x in [-1, 1]:
				b.box(Vector3(0.03, size.y, size.z), Vector3(x * (h.x - 0.015), 0.0, 0.0), gun, 0.008)
				b.box(Vector3(0.02, 0.04, 0.02), Vector3(x * 0.09, h.y + 0.02, 0.0), gun, 0.004)
			for i in 4:
				b.box(Vector3(0.14, 0.01, 0.01), Vector3(-0.055, -0.075 + i * 0.02, h.z - 0.004), black, 0.002)
			_band(b, Vector3(0.0, Radio.BAND_Y, h.z))
			for knob: Vector3 in [Radio.KNOB_AT, Radio.VOLUME_AT]:
				var r := 0.034 if knob == Radio.KNOB_AT else 0.019
				b.drum(r, 0.016, knob + Vector3(0.0, 0.0, -0.008), gun, Basis(Vector3.RIGHT, PI / 2.0), 16)
			b.box(Vector3(0.2, 0.02, 0.025), Vector3(0.0, h.y + 0.045, 0.0), gun, 0.006)
			b.drum(0.006, 0.3, Vector3(-h.x + 0.045, h.y + 0.15, -h.z + 0.03), Paint.coat(Paint.STEEL, 0.8, 0.6), Basis.IDENTITY, 8)
		&"chassis":
			# A flatbed's section: rails round a ribbed plate, sticky top and
			# bottom, caps at the corners where it meets the next, and hazard
			# bands either side of each ring, so a deck's outer edge reads. The
			# consignee's stencil is on its top. Rails sit inside the caps' faces.
			for s in [-1, 1]:
				b.box(Vector3(size.x - 0.16, size.y - 0.02, 0.08), Vector3(0.0, 0.0, s * (h.z - 0.045)), gun, 0.01)
				b.box(Vector3(0.08, size.y - 0.02, size.z - 0.16), Vector3(s * (h.x - 0.045), 0.0, 0.0), gun, 0.01)
			for x in [-1, 1]:
				for z in [-1, 1]:
					b.box(Vector3(0.16, size.y, 0.16), Vector3(x * (h.x - 0.08), 0.0, z * (h.z - 0.08)),
						Paint.coat(Paint.BLACK, 0.7, 0.3), 0.02)
			b.stamp(Paint.Mark.CONSIGNMENT, Vector3(0.16, h.y - 0.02, 0.31), 0.22, Basis(Vector3.RIGHT, -PI / 2.0), Paint.Ink.PALE)
			b.box(Vector3(size.x - 0.16, 0.03, size.z - 0.16), Vector3(0.0, h.y - 0.035, 0.0), teal, 0.006)
			for z in [-0.2, 0.2]:
				b.box(Vector3(size.x - 0.18, 0.006, 0.014), Vector3(0.0, h.y - 0.017, z), black, 0.002)
			b.box(Vector3(size.x - 0.16, 0.05, 0.06), Vector3(0.0, -h.y + 0.045, 0.0), gun, 0.008)
			b.box(Vector3(0.06, 0.05, size.z - 0.16), Vector3(0.0, -h.y + 0.048, 0.0), gun, 0.008)
			for side in 4:
				var turn := Basis(Vector3.UP, side * PI * 0.5)
				for x in [-0.22, 0.22]:
					_hazard(b, Vector3(0.2, 0.03, 0.012), turn * Vector3(x, 0.0, h.z - 0.004), turn)
		&"mast":
			# A stowed pole, its upper reach telescoped inside, a collar at its
			# foot and the gooseneck the boom swings on.
			b.drum(0.05, size.y, Vector3.ZERO, Paint.coat(Paint.STEEL, 0.8, 0.6, 0.45))
			b.drum(0.07, 0.08, Vector3(0.0, -h.y + 0.04, 0.0), Paint.coat(Paint.BLACK, 0.7, 0.3))
			b.drum(0.062, 0.05, Vector3(0.0, Mast.BOOM_AT.y, 0.0), gun)
			b.box(Vector3(0.05, 0.05, 0.1), Vector3(0.0, Mast.BOOM_AT.y, -0.07), gun, 0.008)
			b.drum(0.058, 0.03, Vector3(0.0, h.y - 0.015, 0.0), Paint.coat(Paint.BLACK, 0.7, 0.3))
		&"mast_top":
			# Its upper reach, up from the stowed pole, and a cap at the masthead.
			b.drum(size.x * 0.5, size.y, Vector3(0.0, h.y, 0.0), Paint.coat(Paint.STEEL, 0.8, 0.6, 0.45), Basis.IDENTITY, 12)
			b.drum(size.x * 0.6, 0.06, Vector3(0.0, size.y - 0.03, 0.0), Paint.coat(Paint.BLACK, 0.7, 0.3), Basis.IDENTITY, 12)
		&"boom":
			b.drum(size.x * 0.5, size.z, Vector3(0.0, 0.0, h.z), Paint.coat(Paint.STEEL, 0.8, 0.6, 0.45), Basis(Vector3.RIGHT, PI / 2.0), 10)
			b.drum(size.x * 0.75, 0.05, Vector3(0.0, 0.0, size.z - 0.03), Paint.coat(Paint.BLACK, 0.7, 0.3), Basis(Vector3.RIGHT, PI / 2.0), 10)
		&"console":
			# A rack: four rails on a plinth, a cap, teal side panels vented in two
			# columns either side of their computer-mod ports, its back panel with
			# the fitter's tag over a fan, and on its front bolted rack ears either
			# side of the screen, a black bezel bar over and under it, a hazard
			# strip along the plinth.
			for x in [-1, 1]:
				for z in [-1, 1]:
					b.box(Vector3(0.05, size.y - 0.04, 0.05), Vector3(x * (h.x - 0.025), 0.0, z * (h.z - 0.025)), gun, 0.01)
			b.box(Vector3(size.x, 0.09, size.z), Vector3(0.0, -h.y + 0.045, 0.0), Paint.coat(Paint.BLACK, 0.7, 0.3), 0.015)
			for x in [-1, 1]:
				for z in [-1, 1]:
					b.box(Vector3(0.1, 0.03, 0.1), Vector3(x * (h.x - 0.06), -h.y + 0.015, z * (h.z - 0.06)), black, 0.008)
			b.box(Vector3(size.x, 0.04, size.z), Vector3(0.0, h.y - 0.02, 0.0), gun, 0.01)
			b.box(Vector3(size.x - 0.12, 0.012, size.z - 0.12), Vector3(0.0, h.y + 0.002, 0.0), teal, 0.003)
			for x in [-1, 1]:
				var turn := Basis(Vector3.UP, x * PI * 0.5)
				b.box(Vector3(size.z - 0.08, size.y - 0.16, 0.02), turn * Vector3(0.0, 0.01, h.x - 0.02), teal, 0.006, turn)
				for column in [-1, 1]:
					for i in 14:
						b.box(Vector3(0.11, 0.012, 0.024), turn * Vector3(column * 0.19, -0.5 + i * 0.08, h.x - 0.012), black,
							0.002, turn)
			var back := Basis.IDENTITY
			b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.0, 0.42, h.z - 0.01), 0.22, back, Paint.Ink.PALE)
			b.box(Vector3(size.x - 0.08, size.y - 0.16, 0.02), Vector3(0.0, 0.01, h.z - 0.02), teal, 0.006)
			b.ring(0.08, 0.12, Vector3(0.0, 0.15, h.z - 0.004), black, Basis(Vector3.RIGHT, PI / 2.0), 12)
			# The front: rack ears bolted either side, the screen's bezel between.
			var front := Basis(Vector3.UP, PI)
			b.box(Vector3(size.x - 0.06, size.y - 0.14, 0.02), Vector3(0.0, 0.0, -h.z + 0.02), Paint.coat(Paint.BLACK, 0.4, 0.3, 0.5), 0.004)
			for x in [-1, 1]:
				b.box(Vector3(0.04, size.y - 0.1, 0.035), Vector3(x * (h.x - 0.02), 0.0, -h.z - 0.0175), gun, 0.006, front)
				for i in 7:
					b.drum(0.008, 0.008, Vector3(x * (h.x - 0.02), -0.54 + i * 0.18, -h.z - 0.038), Paint.coat(Paint.STEEL, 0.8, 0.6),
						Basis(Vector3.RIGHT, PI / 2.0), 8)
			b.box(Vector3(size.x - 0.08, 0.04, 0.03), Vector3(0.0, h.y - 0.06, -h.z - 0.015), black, 0.005, front)
			_hazard(b, Vector3(size.x * 0.8, 0.03, 0.012), Vector3(0.0, -h.y + 0.045, -h.z - 0.004), front)
		&"helm_seat":
			# A skimmer pilot's seat on its pedestal: an olive cushion and back,
			# armrests, a hazard band round the post and the crew's patch on its back.
			var olive := Paint.coat(SkimmerKit.OLIVE, 1.0, 0.4, 0.6)
			var canvas := Paint.coat(SkimmerKit.CANVAS, 0.2, 0.0, 0.95)
			b.box(Vector3(size.x, 0.05, size.z), Vector3(0.0, -h.y + 0.025, 0.0), gun, 0.01)
			b.drum(0.07, h.y - 0.1, Vector3(0.0, -h.y * 0.5 - 0.05, 0.0), gun, Basis.IDENTITY, 12)
			_hazard(b, Vector3(0.15, 0.04, 0.012), Vector3(0.0, -0.17, 0.073), Basis.IDENTITY)
			b.box(Vector3(size.x - 0.04, 0.08, size.z - 0.06), Vector3(0.0, -0.04, 0.03), olive, 0.02)
			b.box(Vector3(size.x - 0.1, 0.03, size.z - 0.16), Vector3(0.0, 0.01, 0.05), canvas, 0.01)
			b.box(Vector3(size.x - 0.04, h.y, 0.07), Vector3(0.0, h.y * 0.5, -h.z + 0.035), olive, 0.02)
			b.box(Vector3(size.x - 0.12, h.y - 0.08, 0.02), Vector3(0.0, h.y * 0.5, -h.z + 0.08), canvas, 0.006)
			b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(0.0, h.y * 0.5, -h.z - 0.002), 0.2, Basis(Vector3.UP, PI), Paint.Ink.PALE)
			for x in [-1, 1]:
				b.box(Vector3(0.04, 0.04, size.z * 0.6), Vector3(x * (h.x - 0.02), 0.08, 0.0), gun, 0.008)
				b.box(Vector3(0.03, 0.08, 0.03), Vector3(x * (h.x - 0.02), 0.03, 0.12), gun, 0.006)
		&"stake":
			var iron := Paint.coat(Paint.RUST.lightened(0.1), 1.4, 0.3, 0.8)
			b.box(Vector3(0.05, Stake.LENGTH - 0.12, 0.05), Vector3(0.0, 0.03, 0.0), iron, 0.01)
			b.drum(0.035, 0.12, Vector3(0.0, -h.y + 0.06, 0.0), iron, Basis(Vector3.RIGHT, PI), 4, 0.0)
			b.box(Vector3(0.09, 0.05, 0.09), Vector3(0.0, Stake.RING.y - 0.06, 0.0), iron, 0.012)
		&"cutter":
			# A heat lance: its barrel and heat shield, a copper nozzle out the
			# front (-z), a grip under the back, hazard yellow on its housing.
			var along := Basis(Vector3.RIGHT, PI / 2.0)
			b.drum(0.045, 0.36, Vector3(0.0, 0.01, 0.05), gun, along, 12)
			b.drum(0.052, 0.06, Vector3(0.0, 0.01, -0.12), Paint.coat(Paint.YELLOW, 0.8, 0.3), along, 12)
			b.drum(0.03, 0.08, Vector3(0.0, 0.01, -0.19), Paint.coat(Color(0.72, 0.42, 0.22), 0.6, 0.9, 0.35), along, 10, 0.016)
			b.drum(0.012, 0.03, Vector3(0.0, 0.01, -0.245), black, along, 8)
			b.box(Vector3(0.04, 0.09, 0.05), Vector3(0.0, -h.y + 0.04, 0.16), black, 0.01, Basis(Vector3.RIGHT, 0.25))
			b.box(Vector3(0.012, 0.04, 0.03), Vector3(0.0, -0.05, 0.1), Paint.coat(Paint.YELLOW, 0.6), 0.003)
			for z in [0.0, 0.12]:
				b.drum(0.048, 0.012, Vector3(0.0, 0.01, z), black, along, 12)
		_:
			return null
	return b.commit()


static func _part(id: StringName, size: Vector3, count := -1) -> ArrayMesh:
	var b := Paint.Pieces.new()
	var h := size * 0.5
	var gun := Paint.coat(Paint.GUNMETAL)
	var steel := Paint.coat(Paint.STEEL, 0.8, 0.6)
	var black := Paint.coat(Paint.BLACK, 0.4, 0.2)
	var along := Basis(Vector3.RIGHT, PI / 2.0)
	match id:
		&"battery", &"big_battery":
			# Commodity: no maker's mark, only safety yellow on its terminals.
			b.box(size - Vector3(0.01, 0.01, 0.01), Vector3(0.0, 0.0, h.z), Paint.coat(Color(0.2, 0.21, 0.19), 0.6), 0.012)
			b.box(Vector3(size.x - 0.03, 0.03, size.z * 0.6), Vector3(0.0, h.y - 0.012, h.z), Paint.coat(Paint.YELLOW, 0.6), 0.006)
			b.box(Vector3(size.x * 0.5, 0.025, 0.02), Vector3(0.0, -h.y * 0.35, size.z + 0.002), black, 0.006)
		&"hook":
			b.drum(0.035, 0.02, Vector3(0.0, 0.0, 0.01), Paint.coat(Paint.GUNMETAL, 0.6, 0.3), along)
			b.drum(0.014, 0.12, Vector3(0.0, 0.0, 0.08), steel, along, 10)
		&"hover_tray":
			b.box(Vector3(size.x, size.y, 0.06), Vector3(0.0, 0.0, 0.03), gun, 0.015)
			for side in 4:
				var turn := Basis(Vector3.BACK, side * PI * 0.5)
				_hazard(b, Vector3(size.x * 0.82, 0.035, 0.012), turn * Vector3(0.0, h.y - 0.04, 0.062), turn)
			for x in [-1, 1]:
				for y in [-1, 1]:
					b.drum(0.08, 0.02, Vector3(x * 0.18, y * 0.18, 0.065), Paint.coat(Paint.BLACK, 0.3, 0.3), along, 16)
					b.drum(0.06, 0.012, Vector3(x * 0.18, y * 0.18, 0.074), Paint.coat(Color(0.45, 0.8, 1.0), 0.0, 0.0, 0.3, 0.3, 2.0), along, 16)
		&"keel":
			# A skimmer's ventral strake: a narrow olive plate, the fin under it
			# tapering fore and aft, its field's emitter glowing down its edge.
			b.box(Vector3(size.x, size.y, 0.025), Vector3(0.0, 0.0, 0.0125), Paint.coat(SkimmerKit.OLIVE, 1.0, 0.4, 0.6), 0.008)
			b.box(Vector3(0.05, size.y - 0.12, size.z - 0.03), Vector3(0.0, 0.0, 0.025 + (size.z - 0.03) * 0.5), gun, 0.008)
			for y in [-1, 1]:
				b.box(Vector3(0.05, 0.1, size.z - 0.04), Vector3(0.0, y * (h.y - 0.1), 0.02 + (size.z - 0.04) * 0.5), gun, 0.006,
					Basis(Vector3.RIGHT, y * 0.5))
			b.box(Vector3(0.02, size.y - 0.18, 0.008), Vector3(0.0, 0.0, size.z - 0.002),
				Paint.coat(Color(0.45, 0.8, 1.0), 0.0, 0.0, 0.3, 0.3, 2.0), 0.002)
			for x in [-1, 1]:
				_hazard(b, Vector3(size.y * 0.5, 0.03, 0.01), Vector3(x * (h.x - 0.02), 0.0, 0.03), Basis(Vector3.BACK, PI * 0.5))
		&"skates":
			# Two long blades below a frame across them, reaching past it to the
			# sand, their noses turned up so a crest's lip never digs one in.
			var keel: float = Catalog.PARTS[id].stats.keel
			var reach := size.z + keel
			for x in [-1, 1]:
				var blade := Vector3(x * (h.x - 0.05), 0.0, 0.0)
				b.box(Vector3(0.025, size.y - 0.12, 0.05), blade + Vector3(0.0, 0.0, reach - 0.025), steel, 0.006)
				for y in [-1, 1]:
					b.box(Vector3(0.025, 0.09, 0.04), blade + Vector3(0.0, y * (h.y - 0.05), reach - 0.045),
						steel, 0.006, Basis(Vector3.RIGHT, y * 0.5))
				b.box(Vector3(0.05, size.y - 0.2, keel), blade + Vector3(0.0, 0.0, size.z + keel * 0.5 - 0.01), gun, 0.008)
			for y in [-0.28, 0.28]:
				b.box(Vector3(size.x - 0.04, 0.06, size.z), Vector3(0.0, y, size.z * 0.5), gun, 0.008)
			_hazard(b, Vector3(size.x * 0.6, 0.035, 0.012), Vector3(0.0, 0.0, size.z + 0.002), Basis.IDENTITY)
		&"board_plate":
			# One wide plate on struts below its frame, its nose and tail
			# turned up like a sled's.
			var keel: float = Catalog.PARTS[id].stats.keel
			b.box(Vector3(size.x, size.y - 0.12, size.z), Vector3(0.0, 0.0, h.z), gun, 0.01)
			for x in [-1, 1]:
				for y in [-1, 1]:
					b.box(Vector3(0.05, 0.05, keel), Vector3(x * (h.x - 0.1), y * (h.y - 0.15), size.z + keel * 0.5), gun, 0.006)
			b.box(Vector3(size.x, size.y - 0.12, 0.02), Vector3(0.0, 0.0, size.z + keel - 0.01), gun, 0.006)
			for y in [-1, 1]:
				b.box(Vector3(size.x, 0.1, 0.02), Vector3(0.0, y * (h.y - 0.04), size.z + keel - 0.025), gun, 0.006,
					Basis(Vector3.RIGHT, y * 0.45))
			b.box(Vector3(size.x - 0.08, size.y - 0.2, 0.006), Vector3(0.0, 0.0, size.z + keel + 0.002), Paint.coat(Paint.STEEL, 0.5, 0.7, 0.3), 0.002)
			for x in [-1, 1]:
				_hazard(b, Vector3(0.05, size.y * 0.6, 0.012), Vector3(x * (h.x - 0.06), 0.0, -0.004), Basis.IDENTITY)
		&"sail":
			# Furled on its boom, lashed every so often.
			b.drum(0.035, size.z, Vector3(0.0, 0.0, h.z), steel, along, 10)
			b.drum(0.08, size.z - 0.3, Vector3(0.0, 0.0, h.z + 0.05), Paint.coat(Color(0.86, 0.8, 0.68), 0.5, 0.0, 0.95), along, 12)
			for i in 5:
				b.drum(0.084, 0.03, Vector3(0.0, 0.0, 0.35 + i * 0.38), Paint.coat(Paint.ROPE, 0.4, 0.0, 0.9), along, 12)
		&"solar_panel":
			b.box(Vector3(size.x, size.y, 0.03), Vector3(0.0, 0.0, 0.015), Paint.coat(Paint.STEEL, 0.4, 0.5), 0.006)
			_cells(b, Vector2(size.x - 0.04, size.y - 0.04), 4, 2, Basis.IDENTITY, Vector3(0.0, 0.0, 0.032))
		&"lamp":
			b.drum(0.03, 0.17, Vector3(0.0, 0.0, 0.085), gun, along, 10)
			b.drum(0.055, 0.08, Vector3(0.0, 0.0, 0.205), Paint.coat(Paint.YELLOW, 0.7), along, 16)
			b.drum(0.045, 0.01, Vector3(0.0, 0.0, size.z - 0.003), Paint.coat(Color(1.0, 0.85, 0.6), 0.0, 0.0, 0.2, 0.2, 3.0), along, 16)
		&"plug", &"strong_plug":
			var collar := Paint.coat(Color(1.0, 0.5, 0.1) if id == &"plug" else Color(0.7, 0.15, 0.1), 0.5)
			b.drum(h.x * 0.95, 0.025, Vector3(0.0, 0.0, 0.0125), collar, along, 12)
			b.drum(h.x * 0.8, size.z - 0.025, Vector3(0.0, 0.0, 0.025 + (size.z - 0.025) * 0.5), Paint.coat(Color(0.06, 0.06, 0.06), 0.2, 0.0, 0.85), along, 10, h.x * 0.55)
		&"hose_end":
			# A steel coupling on the hose's rubber, a spout on top where another goes on.
			b.drum(h.x * 0.95, 0.03, Vector3(0.0, 0.0, 0.015), steel, along, 12)
			b.drum(h.x * 0.7, size.z - 0.03, Vector3(0.0, 0.0, 0.03 + (size.z - 0.03) * 0.5),
				Paint.coat(Paint.HOSE, 0.3, 0.0, 0.85), along, 10)
			b.drum(0.016, 0.03, Vector3(0.0, h.y, 0.075), steel, Basis.IDENTITY, 10)
			b.drum(0.02, 0.008, Vector3(0.0, h.y + 0.011, 0.075), Paint.coat(Catalog.KINDS[&"water"], 0.3), Basis.IDENTITY, 10)
		&"coil":
			b.ring(0.09, 0.17, Vector3(0.0, 0.0, size.z * 0.5), Paint.coat(Paint.ROPE, 0.0, 0.0, 1.0, 0.6), along)
			b.box(Vector3(0.05, 0.1, 0.05), Vector3(0.13, 0.0, size.z * 0.5), Paint.coat(Paint.GUNMETAL, 0.6, 0.3), 0.008)
		&"canister":
			b.drum(h.x * 0.92, size.z - 0.04, Vector3(0.0, 0.0, (size.z - 0.04) * 0.5), Paint.coat(Color(0.55, 0.62, 0.68), 0.6, 0.5, 0.45), along, 16)
			b.drum(h.x * 0.5, 0.04, Vector3(0.0, 0.0, size.z - 0.02), Paint.coat(Paint.TEAL, 0.5), along, 12)
			for z in [0.06, size.z - 0.08]:
				b.drum(h.x * 0.95, 0.015, Vector3(0.0, 0.0, z), black, along, 16)
			b.box(Vector3(0.1, 0.012, 0.03), Vector3(0.0, h.y * 0.9, size.z * 0.6), black, 0.003)
		&"ration":
			b.box(size - Vector3(0.006, 0.006, 0.006), Vector3(0.0, 0.0, h.z), Paint.coat(Color(0.45, 0.42, 0.25), 0.3, 0.3, 0.5), 0.01)
			b.box(Vector3(size.x * 0.3, size.y + 0.002, size.z + 0.002), Vector3(-size.x * 0.2, 0.0, h.z), Paint.coat(Paint.YELLOW, 0.3), 0.004)
		&"compass":
			# Company issue: a gunmetal case and lug, a bone card under a black
			# bezel, north marked on the card's top in safety yellow and the
			# other three points in black. The needle is a piece of its own.
			b.drum(h.x, size.z - 0.003, Vector3(0.0, 0.0, (size.z - 0.003) * 0.5), gun, along, 24)
			b.drum(h.x * 0.8, 0.002, Vector3(0.0, 0.0, size.z - 0.002), Paint.coat(Paint.BONE, 0.2, 0.0, 0.5, 0.3), along, 24)
			b.ring(h.x * 0.8, h.x * 0.98, Vector3(0.0, 0.0, size.z - 0.001), Paint.coat(Paint.BLACK, 0.5, 0.3, 0.5), along, 10)
			b.box(Vector3(0.012, 0.014, 0.003), Vector3(0.0, h.y * 0.62, size.z), Paint.coat(Paint.YELLOW, 0.2), 0.001)
			for turn in [PI * 0.5, PI, PI * 1.5]:
				b.box(Vector3(0.004, 0.01, 0.003), Basis(Vector3.BACK, turn) * Vector3(0.0, h.y * 0.64, size.z), black,
					0.0005, Basis(Vector3.BACK, turn))
			b.box(Vector3(0.022, 0.016, 0.012), Vector3(0.0, h.y + 0.004, size.z * 0.4), gun, 0.003)
		&"harvester":
			b.box(Vector3(size.x, size.y, size.z * 0.6), Vector3(0.0, 0.0, size.z * 0.3), Paint.coat(Paint.TEAL), 0.012)
			b.box(Vector3(size.x - 0.02, size.y - 0.04, size.z * 0.4), Vector3(0.0, 0.0, size.z * 0.8), Paint.coat(Paint.YELLOW, 0.7), 0.008)
			for i in 5:
				b.box(Vector3(0.012, size.y * 0.5, 0.01), Vector3(-0.07 + i * 0.035, 0.0, size.z), black, 0.002)
		&"screen":
			# Glass that shows black until its Console draws on it.
			b.box(Vector3(size.x, size.y, 0.02), Vector3(0.0, 0.0, 0.01), gun, 0.006)
			b.box(Vector3(size.x - 0.03, size.y - 0.03, 0.01), Vector3(0.0, 0.0, 0.025),
				Paint.coat(Color(0.02, 0.03, 0.03), 0.0, 0.2, 0.08, 0.15), 0.002)
		&"anemometer":
			# Three cups on a spindle, turned to catch the wind from the port's side.
			b.box(Vector3(size.x, size.y, 0.05), Vector3(0.0, 0.0, 0.025), gun, 0.01)
			b.drum(0.008, 0.08, Vector3(0.0, 0.0, 0.09), steel, along, 8)
			b.drum(0.016, 0.015, Vector3(0.0, 0.0, 0.13), black, along, 10)
			for i in 3:
				var turn := Basis(Vector3.BACK, i * TAU / 3.0)
				b.box(Vector3(0.005, 0.045, 0.005), turn * Vector3(0.0, 0.025, 0.13), steel, 0.001, turn)
				b.ball(0.018, turn * Vector3(0.0, 0.05, 0.13), Paint.coat(Paint.YELLOW, 0.6), Vector3(1.0, 1.0, 0.7))
		&"barometer":
			# A round dial on a gunmetal case, its needle and a yellow mark at storm.
			b.drum(h.x * 0.95, 0.04, Vector3(0.0, 0.0, 0.02), gun, along, 20)
			b.drum(h.x * 0.78, 0.004, Vector3(0.0, 0.0, 0.042), Paint.coat(Paint.BONE, 0.2, 0.0, 0.5, 0.3), along, 20)
			b.ring(h.x * 0.78, h.x * 0.95, Vector3(0.0, 0.0, 0.043), Paint.coat(Paint.BLACK, 0.5, 0.3, 0.5), along, 10)
			var tilt := Basis(Vector3.BACK, 0.5)
			b.box(Vector3(0.004, 0.05, 0.003), tilt * Vector3(0.0, 0.018, 0.0) + Vector3(0.0, 0.0, 0.046), black, 0.0005, tilt)
			b.box(Vector3(0.012, 0.008, 0.003), Vector3(-0.035, 0.035, 0.045), Paint.coat(Paint.YELLOW, 0.2), 0.001)
		&"hygrometer":
			b.box(Vector3(size.x, size.y, 0.06), Vector3(0.0, 0.0, 0.03), Paint.coat(Paint.TEAL), 0.01)
			for i in 4:
				b.box(Vector3(size.x - 0.03, 0.012, 0.012), Vector3(0.0, -0.045 + i * 0.03, 0.065), black, 0.002)
			b.box(Vector3(0.05, 0.02, 0.006), Vector3(0.0, h.y - 0.02, 0.062), Paint.coat(Paint.BONE, 0.3), 0.002)
		&"particle_sensor":
			# An intake the sand is drawn in through, ringed in yellow.
			b.box(Vector3(size.x, size.y, 0.06), Vector3(0.0, 0.0, 0.03), gun, 0.01)
			b.drum(0.035, 0.07, Vector3(0.0, 0.0, 0.095), Paint.coat(Paint.BLACK, 0.4, 0.3, 0.5), along, 14, 0.03)
			b.drum(0.037, 0.012, Vector3(0.0, 0.0, 0.125), Paint.coat(Paint.YELLOW, 0.6), along, 14)
			b.drum(0.02, 0.006, Vector3(0.0, 0.0, size.z - 0.003), Paint.coat(Color(0.03, 0.03, 0.03), 0.0, 0.0, 0.9), along, 12)
		&"ground_radar":
			# A sealed survey set off the port: its antenna's face turned down to
			# the sand, the contractor's amber band, three pilot lights.
			var deep := size.z - 0.05
			b.box(Vector3(size.x, size.y, 0.05), Vector3(0.0, 0.0, 0.025), gun, 0.01)
			b.box(Vector3(size.x - 0.02, size.y - 0.02, deep), Vector3(0.0, 0.0, 0.05 + deep * 0.5),
				Paint.coat(Paint.BONE, 0.4, 0.1, 0.6), 0.012)
			b.box(Vector3(size.x - 0.006, 0.025, deep * 0.9), Vector3(0.0, h.y * 0.45, 0.05 + deep * 0.5),
				Paint.coat(Paint.YELLOW, 0.6), 0.004)
			b.box(Vector3(size.x - 0.04, 0.012, deep - 0.02), Vector3(0.0, -h.y + 0.006, 0.05 + deep * 0.5), black, 0.003)
			for i in 3:
				b.drum(0.008, 0.006, Vector3(-0.04 + i * 0.04, -0.02, size.z + 0.002),
					Paint.coat(Paint.TEAL, 0.0, 0.0, 0.4, 0.3, 1.5), along, 8)
		&"radar":
			# A dish on a post, up from the Console's top.
			b.drum(0.07, 0.04, Vector3(0.0, 0.0, 0.02), gun, along, 16)
			b.drum(0.02, 0.11, Vector3(0.0, 0.0, 0.095), steel, along, 10)
			b.drum(0.095, 0.025, Vector3(0.0, 0.02, 0.16), Paint.coat(Paint.BONE, 0.5), Basis.IDENTITY, 20, 0.07)
			b.drum(0.012, 0.06, Vector3(0.0, 0.055, 0.16), Paint.coat(Paint.BLACK, 0.4, 0.3), Basis.IDENTITY, 8)
			b.box(Vector3(0.06, 0.012, 0.012), Vector3(0.0, 0.0, 0.215), Paint.coat(Paint.YELLOW, 0.6), 0.002)
		&"root_tuber", &"vat_fungus", &"saltbush":
			return crop(id, Plant.RIPE)
		&"tubers":
			for i in (count if count >= 0 else 5):
				var at := Vector3(-0.05 + i * 0.025, (i % 2) * 0.025 - 0.012, 0.03 + (i % 3) * 0.006)
				b.ball(0.026, at, TUBER, Vector3(1.0, 0.85, 0.8))
		&"fungus_caps":
			for i in (count if count >= 0 else 3):
				b.ball(0.05, Vector3(-0.03 + i * 0.03, (i - 1) * 0.012, 0.02 + i * 0.012), CAP, Vector3(1.0, 0.75, 0.22))
		&"saltbush_leaves":
			for i in (count if count >= 0 else 5):
				b.ball(0.5, Vector3((i - 2) * 0.012, 0.0, 0.03), SALTBUSH, Vector3(0.04, 0.11, 0.012),
					Basis(Vector3.BACK, (i - 2) * 0.3))
			b.drum(0.012, 0.014, Vector3(0.0, -0.03, 0.03), Paint.coat(Paint.ROPE, 0.0, 0.0, 1.0, 0.4), Basis.IDENTITY, 8)
		&"salt":
			# A cloth twist of it, tied at the neck.
			b.ball(0.034, Vector3(0.0, 0.0, 0.022), SALT, Vector3(1.0, 1.0, 0.65))
			b.drum(0.012, 0.02, Vector3(0.0, 0.0, 0.046), SALT, along, 8, 0.004)
			b.drum(0.008, 0.006, Vector3(0.0, 0.0, 0.04), Paint.coat(Paint.ROPE, 0.0, 0.0, 1.0, 0.4), along, 8)
		&"sand_scoop":
			# A broad dished blade on a short shaft, its edge worn bright.
			b.box(Vector3(size.x, 0.012, size.z * 0.5), Vector3(0.0, -h.y + 0.02, size.z * 0.72), Paint.coat(Paint.GUNMETAL, 0.8, 0.5), 0.004)
			for x in [-1, 1]:
				b.box(Vector3(0.012, size.y * 0.8, size.z * 0.5), Vector3(x * (h.x - 0.006), -0.005, size.z * 0.72), gun, 0.003)
			b.box(Vector3(size.x, 0.006, 0.02), Vector3(0.0, -h.y + 0.02, size.z - 0.01), steel, 0.002)
			b.drum(0.016, size.z * 0.5, Vector3(0.0, 0.0, size.z * 0.25), Paint.coat(Paint.ROPE, 0.0, 0.0, 1.0, 0.4), along, 8)
			b.box(Vector3(0.1, 0.03, 0.03), Vector3(0.0, 0.0, 0.02), black, 0.006)
		&"sieve":
			# A riddle: a saltwood hoop rimmed in steel, its mesh worn bright
			# where the sand ran through.
			var wood := Paint.coat(Paint.SALTWOOD, 0.2, 0.0, 0.85)
			for z in [0.012, size.z - 0.012]:
				b.ring(h.x - 0.026, h.x, Vector3(0.0, 0.0, z), wood, along, 28)
			b.ring(h.x - 0.012, h.x + 0.004, Vector3(0.0, 0.0, size.z * 0.5), steel, along, 28)
			var mesh := Paint.coat(Paint.STEEL, 0.9, 0.7, 0.35)
			for i in 9:
				var across := (i - 4) * (h.x - 0.03) / 4.5
				var long := 2.0 * sqrt(maxf(pow(h.x - 0.02, 2.0) - across * across, 0.0))
				b.box(Vector3(0.004, long, 0.004), Vector3(across, 0.0, 0.03), mesh, 0.0)
				b.box(Vector3(long, 0.004, 0.004), Vector3(0.0, across, 0.034), mesh, 0.0)
		&"sealant":
			b.drum(h.x * 0.95, size.z * 0.75, Vector3(0.0, 0.0, size.z * 0.375), Paint.coat(Paint.YELLOW, 0.5, 0.2), along, 14)
			b.drum(h.x * 0.6, size.z * 0.12, Vector3(0.0, 0.0, size.z * 0.81), black, along, 12)
			b.drum(0.008, size.z * 0.14, Vector3(0.0, 0.0, size.z * 0.93), Paint.coat(Color(0.75, 0.2, 0.08), 0.5), along, 6)
			b.box(Vector3(h.x * 1.2, 0.03, size.z * 0.4), Vector3(0.0, h.y * 0.92, size.z * 0.4), Paint.coat(Paint.BONE, 0.3), 0.003)
		&"med_kit":
			# A sealed pouch of the colony clinic's issue: pale, its cross in teal.
			b.box(Vector3(size.x, size.y, size.z - 0.005), Vector3(0.0, 0.0, size.z * 0.5), Paint.coat(Paint.BONE, 0.4, 0.0, 0.8), 0.012)
			b.box(Vector3(0.05, 0.016, 0.004), Vector3(0.0, 0.0, size.z + 0.001), Paint.coat(Paint.TEAL, 0.2), 0.0)
			b.box(Vector3(0.016, 0.05, 0.004), Vector3(0.0, 0.0, size.z + 0.001), Paint.coat(Paint.TEAL, 0.2), 0.0)
			b.box(Vector3(size.x + 0.004, 0.012, size.z * 0.3), Vector3(0.0, h.y - 0.01, size.z * 0.5), black, 0.002)
		&"hull_plate":
			b.box(size, Vector3(0.0, 0.0, h.z), Paint.coat(Wreckage.PLATE, 1.0, 0.55, 0.62), 0.008)
			for x in [-1, 1]:
				for y in [-1, 1]:
					b.box(Vector3(0.04, 0.04, 0.012), Vector3(x * (h.x - 0.06), y * (h.y - 0.06), size.z + 0.004), steel, 0.004)
		&"frame":
			# Gunmetal rails along a cube's edges, black caps where they meet and
			# a hazard band low on each post, so a frame reads from across a camp.
			var r := Frame.RAIL
			var e := h.x - r * 0.5
			var caps := Paint.coat(Paint.BLACK, 0.7, 0.3)
			for x in [-1, 1]:
				for y in [-1, 1]:
					b.box(Vector3(r, r, size.z - 0.04), Vector3(x * e, y * e, h.z), gun, 0.008)
					for z in [0.03, size.z - 0.03]:
						b.box(Vector3(r + 0.016, r + 0.016, 0.06), Vector3(x * e, y * e, z), caps, 0.01)
					_hazard(b, Vector3(r + 0.004, 0.08, r + 0.004), Vector3(x * e, y * e, 0.16), Basis(Vector3.RIGHT, PI / 2.0))
			for z in [r * 0.5, size.z - r * 0.5]:
				for s in [-1, 1]:
					b.box(Vector3(size.x - 2.0 * r - 0.01, r * 0.9, r * 0.9), Vector3(0.0, s * e, z), gun, 0.006)
					b.box(Vector3(r * 0.9, size.y - 2.0 * r - 0.01, r * 0.9), Vector3(s * e, 0.0, z), gun, 0.006)
		&"fabric":
			# Its hem stitched and its corners grommeted; the canvas is its own
			# cloth, which bellies and flutters (Faces).
			for s in [-1, 1]:
				b.box(Vector3(size.x, 0.025, size.z + 0.004), Vector3(0.0, s * (h.y - 0.0125), h.z), Paint.coat(Color(0.62, 0.55, 0.42), 0.0, 0.0, 0.95), 0.001)
				b.box(Vector3(0.025, size.y, size.z + 0.004), Vector3(s * (h.x - 0.0125), 0.0, h.z), Paint.coat(Color(0.62, 0.55, 0.42), 0.0, 0.0, 0.95), 0.001)
			for x in [-1, 1]:
				for y in [-1, 1]:
					b.drum(0.018, size.z + 0.008, Vector3(x * (h.x - 0.04), y * (h.y - 0.04), h.z), steel, along, 10)
		_:
			return null
	return b.commit()


## A crop's look at a stage of Plant's, ripe for the look of one whose ripe
## isn't its mature, and its leaves folded this share shut. It grows up its
## +Z out of its slot, as every part stands; it's drawn upright in its own
## frame and turned onto that.
static func crop(id: StringName, stage: StringName, fold := 0.0) -> ArrayMesh:
	return _cached(&"crop", StringName("%s/%s/%.2f" % [id, stage, fold]), func() -> ArrayMesh: return _crop(id, stage, fold))


## Plants wear no paint, so nothing of them chips; they hold a little sand.
## Saltbush is silvered by the salt in its leaves.
static var TUBER := Paint.coat(Color(0.74, 0.6, 0.4), 0.0, 0.0, 0.8, 0.4)
static var CAP := Paint.coat(Color(0.52, 0.48, 0.43), 0.0, 0.0, 0.7, 0.3)
static var GILLS := Paint.coat(Color(0.88, 0.84, 0.74), 0.0, 0.0, 0.8, 0.1)
static var MYCELIUM := Paint.coat(Color(0.9, 0.88, 0.82), 0.0, 0.0, 0.95, 0.3)
static var POTATO_LEAF := Paint.coat(Color(0.26, 0.46, 0.18), 0.0, 0.0, 0.7, 0.3)
static var POTATO_STEM := Paint.coat(Color(0.36, 0.48, 0.24), 0.0, 0.0, 0.8, 0.3)
static var FADING := Paint.coat(Color(0.5, 0.52, 0.22), 0.0, 0.0, 0.75, 0.4)
static var FLOWER := Paint.coat(Color(0.86, 0.82, 0.9), 0.0, 0.0, 0.6, 0.1)
static var SALTBUSH := Paint.coat(Color(0.6, 0.69, 0.68), 0.0, 0.25, 0.4, 0.2)
static var WOOD := Paint.coat(Color(0.42, 0.37, 0.3), 0.0, 0.0, 0.9, 0.5)
static var SALT := Paint.coat(Color(0.9, 0.89, 0.84), 0.0, 0.0, 0.9, 0.2)
static var MOUND := Paint.coat(Paint.SOIL.lightened(0.04), 0.0, 0.0, 1.0, 0.8)
## Upright, y up, onto a part's +Z.
const UP := Basis(Vector3.RIGHT, PI / 2.0)


## Solar cells in a grid over `area`, facing +Z of `turn`.
static func _cells(b: Paint.Pieces, area: Vector2, cols: int, rows: int, turn: Basis, at: Vector3) -> void:
	var cell := Vector2(area.x / cols, area.y / rows)
	for i in cols:
		for j in rows:
			var middle := Vector3(-area.x * 0.5 + (i + 0.5) * cell.x, -area.y * 0.5 + (j + 0.5) * cell.y, 0.0)
			b.box(Vector3(cell.x - 0.01, cell.y - 0.01, 0.006), at + turn * middle, Paint.coat(Paint.CELL, 0.2, 0.6, 0.18, 0.3), 0.001, turn)


## Black and yellow: the bands a safety officer would sign off.
## A radio's band scale, its middle at `at` on the face: a lit window in a
## gunmetal bezel, a tick every 100 kHz and a long one every 500, numbered in
## hundreds as old sets were.
static func _band(b: Paint.Pieces, at: Vector3) -> void:
	var gun := Paint.coat(Paint.GUNMETAL)
	var ink := Paint.coat(Color(0.12, 0.09, 0.07), 0.0, 0.0, 0.7, 0.0)
	var wide := Radio.BAND_WIDTH
	var high := Radio.BAND_HEIGHT
	# Set into the case, the bezel standing proud of the window.
	b.box(Vector3(wide, high, 0.014), at + Vector3(0.0, 0.0, -0.005), Paint.coat(Color(1.0, 0.82, 0.55), 0.0, 0.0, 0.5, 0.0, 1.0), 0.001)
	for s in [-1, 1]:
		b.box(Vector3(wide + 0.016, 0.008, 0.018), at + Vector3(0.0, s * (high * 0.5 + 0.004), -0.003), gun, 0.002)
		b.box(Vector3(0.008, high, 0.018), at + Vector3(s * (wide * 0.5 + 0.004), 0.0, -0.003), gun, 0.002)
	var face := at.z + 0.0025
	var foot := -0.016
	b.box(Vector3(Radio.BAND.y - Radio.BAND.x + 0.0014, 0.001, 0.001), at + Vector3(0.0, foot, face - at.z), ink, 0.0)
	for i in 21:
		var x := lerpf(Radio.BAND.x, Radio.BAND.y, i / 20.0)
		var long := i % 5 == 0
		var tall := 0.011 if long else 0.006
		b.box(Vector3(0.0014 if long else 0.001, tall, 0.001), Vector3(x, at.y + foot + tall * 0.5, face), ink, 0.0)
		if long:
			_numeral(b, str(i), Vector3(x, at.y + 0.008, face), 0.011, ink)


## A number in block strokes, `tall` m high, its middle at `at`, facing +Z.
static func _numeral(b: Paint.Pieces, text: String, at: Vector3, tall: float, look: Paint.Coat) -> void:
	# Strokes a to g: top, top right, bottom right, bottom, bottom left, top left, middle.
	const STROKES := {"0": "abcdef", "1": "bc", "2": "abged", "5": "afgcd"}
	const PLACES := {"a": Vector2(0.0, 0.5), "g": Vector2.ZERO, "d": Vector2(0.0, -0.5), "b": Vector2(0.5, 0.25),
		"c": Vector2(0.5, -0.25), "e": Vector2(-0.5, -0.25), "f": Vector2(-0.5, 0.25)}
	var wide := tall * 0.55
	var line := tall * 0.13
	var gap := wide * 0.5
	# A 1 is one stroke, as narrow as it.
	var widths: Array[float] = []
	var span := -gap
	for digit in text:
		widths.append(line if digit == "1" else wide)
		span += widths[-1] + gap
	var x := at.x - span * 0.5
	for i in text.length():
		for stroke in STROKES[text[i]]:
			var where: Vector2 = PLACES[stroke]
			if text[i] == "1":
				where.x = 0.0
			var size := Vector3(wide + line, line, 0.001) if stroke in "adg" else Vector3(line, tall * 0.5 + line, 0.001)
			b.box(size, Vector3(x + widths[i] * 0.5 + where.x * wide, at.y + where.y * tall, at.z), look, 0.0)
		x += widths[i] + gap


static func _hazard(b: Paint.Pieces, size: Vector3, at: Vector3, turn: Basis) -> void:
	b.box(size, at, Paint.coat(Paint.YELLOW, 0.75), 0.003, turn)
	var n := int(size.x / (size.y * 1.6))
	for i in n:
		var x := -size.x * 0.5 + (i + 0.5) * size.x / n
		b.box(Vector3(size.y * 0.55, size.y * 1.05, size.z + 0.002), at + turn * Vector3(x, 0.0, 0.0), Paint.coat(Paint.BLACK, 0.6), 0.001,
			turn * Basis(Vector3.BACK, 0.7))


static func _crop(id: StringName, stage: StringName, fold: float) -> ArrayMesh:
	var b := Paint.Pieces.new()
	# The same plant each time it's drawn, its own shape.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var young := stage == Plant.SEEDLING
	match id:
		&"root_tuber":
			# A potato's leafy top over tubers swelling in the soil; ripe, the
			# top yellows and flowers, and the tubers show at the mound.
			var ripe := stage == Plant.RIPE or stage == Plant.MATURE
			var stems := 3 if young else (5 if stage == Plant.YOUNG else 6)
			var tall := 0.05 if young else (0.13 if stage == Plant.YOUNG else 0.19)
			var leaf := 0.035 if young else 0.05
			_up_drum(b, 0.05 if young else 0.07, 0.01, Vector3(0.0, 0.004, 0.0), MOUND, 0.035 if young else 0.05)
			for i in stems:
				var a := TAU * i / stems + rng.randf_range(-0.3, 0.3)
				var lean := rng.randf_range(0.25, 0.5)
				var top := Vector3(sin(a) * tall * lean, tall * rng.randf_range(0.8, 1.0), cos(a) * tall * lean)
				_stem(b, Vector3(0.0, 0.01, 0.0), top, 0.005, POTATO_STEM)
				for k in (2 if young else 4):
					var on := top * (0.45 + 0.18 * k)
					var side := a + (1.2 if k % 2 == 0 else -1.2)
					_leaf(b, on, side, rng.randf_range(0.1, 0.5), leaf, leaf * 0.6, FADING if ripe and k == 0 else POTATO_LEAF)
				_leaf(b, top, a, 0.6, leaf * 0.9, leaf * 0.55, POTATO_LEAF)
				if ripe and i % 2 == 0:
					_ball(b, 0.009, top + Vector3(0.0, 0.012, 0.0), FLOWER)
					_ball(b, 0.004, top + Vector3(0.0, 0.02, 0.0), Paint.coat(Paint.YELLOW, 0.0))
			if not young:
				for i in (4 if ripe else 2):
					var a := TAU * (i + 0.5) / 4.0
					var r := 0.05 if ripe else 0.035
					_ball(b, 0.024 if ripe else 0.016, Vector3(sin(a) * r, 0.01, cos(a) * r), TUBER, Vector3(1.2, 0.8, 1.0))
		&"vat_fungus":
			# A white mat of mycelium, pinning as it matures; fruited, a cluster
			# of oyster caps fanned out from one stem, cream gills under them.
			var mat := 0.035 if young else (0.052 if stage == Plant.YOUNG else 0.064)
			_ball(b, mat, Vector3(0.0, 0.004, 0.0), MYCELIUM, Vector3(1.0, 0.18, 1.0))
			if stage == Plant.RIPE:
				_up_drum(b, 0.016, 0.06, Vector3(0.0, 0.03, 0.0), GILLS, 0.01)
				for i in 9:
					# Three tiers of fans, each shelf flaring out and up from the stem.
					var a := TAU * i / 3.0 + (i / 3) * 0.9 + rng.randf_range(-0.2, 0.2)
					var tier := 0.022 + (i / 3) * 0.022
					var out := Vector3(sin(a), 0.0, cos(a))
					var tilt := Basis(out.cross(Vector3.UP).normalized(), 0.3) * Basis(Vector3.UP, a)
					var r := rng.randf_range(0.045, 0.058) * (1.0 - (i / 3) * 0.12)
					var at := out * r * 0.95 + Vector3(0.0, tier, 0.0)
					_ball(b, r, at, CAP, Vector3(1.0, 0.16, 0.85), tilt)
					_ball(b, r * 0.94, at - Vector3(0.0, r * 0.05, 0.0), GILLS, Vector3(1.0, 0.1, 0.8), tilt)
			elif not young:
				for i in (5 if stage == Plant.YOUNG else 11):
					var a := rng.randf() * TAU
					var r := rng.randf_range(0.0, mat * 0.7)
					var pin := 0.006 if stage == Plant.YOUNG else 0.01
					_ball(b, pin, Vector3(sin(a) * r, 0.01 + pin * 0.6, cos(a) * r), GILLS, Vector3(1.0, 1.3, 1.0))
		&"saltbush":
			# Woody stems branching low into a mound of small silvery leaves, held
			# level to the sun; folded, they close up against their stems.
			var stems := 2 if young else (4 if stage == Plant.YOUNG else 7)
			var tall := 0.06 if young else (0.12 if stage == Plant.YOUNG else 0.17)
			var per := 5 if young else (8 if stage == Plant.YOUNG else 10)
			var leaf := 0.03 if young else 0.042
			for i in stems:
				var a := TAU * i / stems + rng.randf_range(-0.3, 0.3)
				var lean := rng.randf_range(0.2, 0.45) if young else rng.randf_range(0.5, 0.95)
				var top := Vector3(sin(a) * tall * lean, tall * rng.randf_range(0.75, 1.0), cos(a) * tall * lean)
				_stem(b, Vector3.ZERO, top, 0.005, WOOD)
				for k in per:
					var on := top * (0.2 + 0.8 * (k + 1) / per)
					var side := a + k * 2.4 + rng.randf_range(-0.3, 0.3)
					var open := rng.randf_range(-0.1, 0.3)
					_leaf(b, on, side, lerpf(open, 1.3, fold), leaf * rng.randf_range(0.8, 1.1), leaf * lerpf(0.5, 0.32, fold),
						SALTBUSH)
		_:
			return null
	return b.commit()


## A leaf from `at` out along a bearing `a` round the stem, `e` above level:
## long, and wide flat across.
static func _leaf(b: Paint.Pieces, at: Vector3, a: float, e: float, long: float, wide: float, look: Paint.Coat) -> void:
	var d := Vector3(cos(e) * sin(a), sin(e), cos(e) * cos(a))
	var x := Vector3(cos(a), 0.0, -sin(a))
	b.ball(0.5, UP * (at + d * long * 0.5), look, Vector3(wide, wide * 0.16, long), UP * Basis(x, d.cross(x), d))


static func _stem(b: Paint.Pieces, from: Vector3, to: Vector3, radius: float, look: Paint.Coat) -> void:
	var y := (to - from).normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	b.drum(radius, from.distance_to(to), UP * (from + to) * 0.5, look, UP * Basis(x, y, x.cross(y)), 6)


static func _ball(b: Paint.Pieces, radius: float, at: Vector3, look: Paint.Coat, scale := Vector3.ONE,
		turn := Basis.IDENTITY) -> void:
	b.ball(radius, UP * at, look, scale, UP * turn)


static func _up_drum(b: Paint.Pieces, radius: float, height: float, at: Vector3, look: Paint.Coat, top := -1.0) -> void:
	b.drum(radius, height, UP * at, look, UP, 12, top)
