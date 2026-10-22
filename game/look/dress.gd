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


## One shared winding mesh; each gathered display selects continuous poses.
static func coil() -> ArrayMesh:
	return _cached(&"coil", &"winding", func() -> ArrayMesh: return CoilLooks.make())


static func halyard_block() -> ArrayMesh:
	return _cached(&"fitting", &"halyard_block", func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		var steel := Paint.coat(Paint.STEEL, 0.2, 0.7)
		for x in [-0.027, 0.027]:
			b.box(Vector3(0.012, 0.12, 0.10), Vector3(x, 0, 0), steel, 0.006)
		b.drum(0.043, 0.045, Vector3.ZERO, Paint.coat(Paint.YELLOW), Basis(Vector3.BACK, PI / 2.0), 16)
		return b.commit())


static func halyard_mount() -> ArrayMesh:
	return _cached(&"fitting", &"halyard_mount", func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		var steel := Paint.coat(Paint.STEEL, 0.2, 0.7)
		b.box(Vector3(0.16, 0.025, 0.10), Vector3(-0.06, 0.04, 0.025), steel, 0.003)
		b.drum(0.016, 0.05, Vector3(0, 0.06, 0), steel, Basis.IDENTITY, 10)
		return b.commit())


static func winch_wheel() -> ArrayMesh:
	return _cached(&"moving", &"winch_wheel", func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		var steel := Paint.coat(Paint.STEEL, 0.12, 0.8)
		var paint := Paint.coat(Paint.YELLOW)
		var turn := Basis(Vector3.RIGHT, PI / 2.0)
		b.ring(0.115, 0.14, Vector3(0, 0, 0.17), steel, turn, 20)
		for i in 3:
			var a := i * TAU / 3.0
			b.box(Vector3(0.012, 0.11, 0.016), Vector3(sin(a) * 0.055, cos(a) * 0.055, 0.17),
				steel, 0.003, Basis(Vector3.BACK, -a))
		b.drum(0.02, 0.06, Vector3(0.0, 0.12, 0.205), paint, turn, 10)
		b.drum(0.025, 0.035, Vector3(0, 0, 0.16), steel, turn, 12)
		return b.commit())


## A compass's needle, its north tip along +Y: red, and lit so it glows a
## little, over a steel south half on a black pivot.
static func needle() -> ArrayMesh:
	return _cached(&"needle", &"compass", func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		b.box(Vector3(0.008, 0.042, 0.003), Vector3(0.0, 0.021, 0.0), Paint.coat(Color(0.85, 0.16, 0.08), 0.0, 0.0, 0.4, 0.0, 1.2), 0.001)
		b.box(Vector3(0.008, 0.036, 0.003), Vector3(0.0, -0.018, 0.0), Paint.coat(Paint.STEEL, 0.0, 0.6, 0.4, 0.0), 0.001)
		b.drum(0.005, 0.005, Vector3.ZERO, Paint.coat(Paint.BLACK, 0.0, 0.3), Basis(Vector3.RIGHT, PI / 2.0), 10)
		return b.commit())


## A bedroll unrolling, `open` of the way from rolled to flat, in its own
## frame: its head stays where the roll lay and the pad lies out flat along
## +X behind the roll as it rolls away, thinner as it goes, to its foot; the
## pillow at its head plumps up as the roll leaves it, and the straps lie
## undone beside it. Stepped, each step made once.
static func bedroll(open: float) -> ArrayMesh:
	var step := clampi(roundi(open * BEDROLL_STEPS), 1, BEDROLL_STEPS)
	return _cached(&"bedroll", StringName(str(step)), func() -> ArrayMesh: return _bedroll(float(step) / BEDROLL_STEPS))


## Its head to its foot, laid, m; the pad's thickness and the foot's hem.
const BEDROLL_LENGTH := 1.9
const BEDROLL_PAD := 0.03
const BEDROLL_HEM := 0.03
const BEDROLL_STEPS := 40


static func _bedroll(open: float) -> ArrayMesh:
	var size: Vector3 = Catalog.DEVICES[&"bedroll"].size
	var h := size * 0.5
	var b := Paint.Pieces.new(-h.y)
	var canvas := Paint.coat(Paint.TEAL, 0.0, 0.0, 0.95)
	var lining := Paint.coat(Paint.BONE, 0.0, 0.0, 0.95)
	var along := Basis(Vector3.RIGHT, PI / 2.0)
	var wide := size.z - 0.04
	var foot := -h.y
	var head := -h.x
	var r0 := h.x - 0.005
	# What lies out has left the roll, which thins by the area it gave.
	var r := sqrt(r0 * r0 * (1.0 - open) + BEDROLL_HEM * BEDROLL_HEM * open)
	var x := head + r0 + open * (BEDROLL_LENGTH - r0 - BEDROLL_HEM)
	var laid := x - head
	b.box(Vector3(laid, BEDROLL_PAD, wide), Vector3(head + laid * 0.5, foot + BEDROLL_PAD * 0.5, 0.0), canvas, 0.006)
	var seam := 0.45
	while head + seam < x - r:
		b.box(Vector3(0.014, 0.004, wide - 0.05), Vector3(head + seam, foot + BEDROLL_PAD + 0.001, 0.0),
			Paint.coat(Paint.TEAL.darkened(0.35), 0.0, 0.0, 0.95), 0.0)
		seam += 0.3
	if x - r > head + 0.5:
		# Its top turned back at the head, the lining showing.
		b.box(Vector3(0.2, 0.012, wide - 0.02), Vector3(head + 0.38, foot + BEDROLL_PAD + 0.006, 0.0), lining, 0.004)
	var plump := smoothstep(0.0, 0.25, open)
	b.ball(1.0, Vector3(head + 0.13, foot + BEDROLL_PAD + 0.07 * plump, 0.0), lining,
		Vector3(0.12, 0.07 * plump + 0.005, 0.36))
	for z in [-1, 1]:
		b.box(Vector3(0.34, 0.004, 0.035), Vector3(head - 0.02, foot + 0.002, z * 0.26), Paint.coat(Paint.BLACK, 0.3, 0.3, 0.6), 0.0)
	b.drum(r, wide, Vector3(x, foot + r, 0.0), canvas, along, 18)
	for z in [-1, 1]:
		b.drum(maxf(r - 0.025, r * 0.5), 0.02, Vector3(x, foot + r, z * wide * 0.5), lining, along, 18)
	return b.commit()


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
	for step in BEDROLL_STEPS:
		bedroll((step + 1.0) / BEDROLL_STEPS)
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
		&"home_beacon":
			var bone := Paint.coat(Paint.BONE)
			var brass := Paint.coat(Paint.BRASS, 0.5, 0.65)
			b.box(Vector3(0.27, 0.035, 0.21), Vector3(0, -0.1625, 0), gun, 0.008)
			b.box(Vector3(0.235, 0.22, 0.18), Vector3(0, -0.035, 0), bone, 0.022)
			b.box(Vector3(0.17, 0.15, 0.018), Vector3(0, -0.035, 0.088), teal, 0.006)
			for x in [-0.10, 0.10]:
				for z in [-0.075, 0.075]:
					b.box(Vector3(0.035, 0.032, 0.035), Vector3(x, -0.14, z), black, 0.006)
				b.drum(0.007, 0.006, Vector3(x, 0.079, 0.05), brass, Basis.IDENTITY, 8)
			b.box(Vector3(0.09, 0.042, 0.013), Vector3(0, 0.008, 0.103), black, 0.004)
			b.box(Vector3(0.067, 0.022, 0.006), Vector3(0, 0.008, 0.112),
				Paint.coat(Paint.YELLOW, 0.0, 0.0, 0.35, 0.0, 1.8), 0.003)
			for y in [-0.045, -0.062, -0.079]:
				b.box(Vector3(0.087, 0.006, 0.006), Vector3(-0.012, y, 0.101), black, 0.001)
			b.drum(0.024, 0.018, Vector3(0, 0.083, 0), brass, Basis.IDENTITY, 12)
			b.drum(0.015, 0.072, Vector3(0, 0.125, 0), black, Basis.IDENTITY, 10)
			for y in [0.10, 0.115, 0.13, 0.145]:
				b.drum(0.019, 0.006, Vector3(0, y, 0), gun, Basis.IDENTITY, 10)
			b.ball(0.018, Vector3(0, 0.161, 0), bone)
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
		&"sailing_notes", &"surveyor_guide":
			var cover := Paint.coat(Paint.BONE) if id == &"surveyor_guide" else teal
			# A salt-stained field booklet, pale pages held by a dark cloth spine.
			b.box(Vector3(size.x, 0.008, size.z), Vector3(0.0, -h.y + 0.004, 0.0), cover, 0.003)
			b.box(Vector3(size.x - 0.015, size.y - 0.016, size.z - 0.012), Vector3.ZERO, Paint.coat(Paint.BONE), 0.002)
			b.box(Vector3(size.x, 0.008, size.z), Vector3(0.0, h.y - 0.006, 0.0), cover, 0.003)
			b.box(Vector3(0.022, size.y, size.z), Vector3(-h.x + 0.011, 0.0, 0.0), black, 0.003)
			if id == &"surveyor_guide":
				# A survey cross and ruled field lines on the company's pale cover.
				b.box(Vector3(0.12, 0.002, 0.009), Vector3(0.0, h.y - 0.001, -0.05), black, 0.0)
				b.box(Vector3(0.009, 0.002, 0.12), Vector3(0.0, h.y - 0.001, -0.05), black, 0.0)
				for z in [0.05, 0.08, 0.11]:
					b.box(Vector3(0.16, 0.002, 0.006), Vector3(0.0, h.y - 0.001, z), teal, 0.0)
			else:
				# A pale sail and its mast identify it even before the look-at label.
				b.box(Vector3(0.008, 0.002, 0.18), Vector3(-0.025, h.y - 0.001, 0.0), Paint.coat(Paint.BONE), 0.0)
				for i in 8:
					var width := 0.02 + i * 0.009
					b.box(Vector3(width, 0.002, 0.017), Vector3(-0.02 + width * 0.5, h.y - 0.001, -0.07 + i * 0.02), Paint.coat(Paint.BONE), 0.0)
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
		&"survey_receiver":
			return SurveyReceiverLooks.frame()
		&"antenna_kite":
			return KiteLooks.packed(size)
		&"radio", &"radio_colonial", &"radio_skimmer", &"radio_kingdoms", &"radio_second_age":
			# The field radio in its maker's look, its body alone: its needle,
			# knobs, lamps and band window are the radio's own, live.
			return RadioKitLooks.field_radio(Catalog.DEVICES[id].style, {}, &"am", false, true)
		&"crystal_set":
			return RadioKitLooks.crystal_set()
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
			b.box(Vector3(size.x - 2.0 * Chassis.PANEL_INSET, 0.03, size.z - 2.0 * Chassis.PANEL_INSET),
				Vector3(0.0, h.y - Chassis.PANEL_DROP - 0.015, 0.0), teal, 0.006)
			for z in [-0.2, 0.2]:
				b.box(Vector3(size.x - 0.18, 0.006, 0.014), Vector3(0.0, h.y - 0.017, z), black, 0.002)
			b.box(Vector3(size.x - 0.16, 0.05, 0.06), Vector3(0.0, -h.y + 0.045, 0.0), gun, 0.008)
			b.box(Vector3(0.06, 0.05, size.z - 0.16), Vector3(0.0, -h.y + 0.048, 0.0), gun, 0.008)
			for side in 4:
				var turn := Basis(Vector3.UP, side * PI * 0.5)
				for x in [-0.22, 0.22]:
					_hazard(b, Vector3(0.2, 0.03, 0.012), turn * Vector3(x, 0.0, h.z - 0.004), turn)
		&"hand_winch":
			b.box(Vector3(0.31, 0.04, 0.28), Vector3(0, -0.16, 0), gun, 0.014)
			for x in [-0.12, 0.12]:
				b.box(Vector3(0.035, 0.22, 0.18), Vector3(x, -0.02, 0), teal, 0.012)
			var axle := Basis(Vector3.RIGHT, PI / 2.0)
			b.drum(0.087, 0.21, Vector3(0, 0.035, 0), black, axle, 16)
			for z in [-0.105, 0.105]:
				b.drum(0.11, 0.018, Vector3(0, 0.035, z), gun, axle, 20)
			for z in [-0.07, -0.035, 0.0, 0.035, 0.07]:
				b.ring(0.083, 0.092, Vector3(0, 0.035, z), Paint.coat(Color(0.42, 0.31, 0.2)), axle, 16)
			for x in [-0.12, 0.12]:
				for z in [-0.1, 0.1]:
					b.drum(0.014, 0.012, Vector3(x, -0.115, z), gun, Basis.IDENTITY, 6)
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
		&"coalcane_bundle":
			for x in [-0.12, 0.0, 0.12]:
				for y in [-0.07, 0.07]:
					b.drum(0.065, size.z, Vector3(x, y, h.z), Paint.coat(Color(0.24, 0.15, 0.07), 0.7), along, 8)
			for z in [0.12, size.z - 0.12]:
				b.box(Vector3(size.x, size.y, 0.045), Vector3(0, 0, z), Paint.coat(Paint.CORD, 0.7), 0.025)
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
		&"flare":
			# A red tube with a black striker cap at its tip, where it burns.
			b.drum(h.x, size.z - 0.04, Vector3(0.0, 0.0, (size.z - 0.04) * 0.5), Paint.coat(Color(0.75, 0.12, 0.08), 0.5), along, 10)
			b.drum(h.x * 1.05, 0.04, Vector3(0.0, 0.0, size.z - 0.02), Paint.coat(Color(0.08, 0.08, 0.08), 0.3), along, 10)
		&"cargo":
			# A drop container: an orange shell banded in black, its ends capped.
			b.box(Vector3(size.x, size.y, size.z - 0.12), Vector3(0.0, 0.0, size.z * 0.5), Paint.coat(Color(0.85, 0.45, 0.12), 0.45, 0.2), 0.04)
			for z in [0.03, size.z - 0.03]:
				b.box(Vector3(size.x + 0.02, size.y + 0.02, 0.06), Vector3(0.0, 0.0, z), Paint.coat(Color(0.08, 0.08, 0.08), 0.4, 0.3), 0.02)
			for z in [size.z * 0.35, size.z * 0.65]:
				b.box(Vector3(size.x + 0.01, size.y + 0.01, 0.05), Vector3(0.0, 0.0, z), Paint.coat(Color(0.1, 0.1, 0.1), 0.4, 0.3), 0.01)
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
		&"rope_end":
			# Three laid cords and a small whipping explain the end without a metal block.
			var rules := Tuning.current().rope_coil_visual
			var fibre := Paint.coat(Paint.ROPE.lightened(0.14), 0.0, 0.0, 0.95, 0.35)
			var binding := Paint.coat(Paint.TEAL.darkened(0.24), 0.0, 0.0, 0.95, 0.25)
			var radius: float = rules.end_strand_radius
			for strand in int(rules.end_strands):
				var phase := float(strand) * TAU / float(rules.end_strands)
				for i in int(rules.end_sections):
					var points: Array[Vector3] = []
					for t in [float(i) / float(rules.end_sections), float(i + 1) / float(rules.end_sections)]:
						var angle: float = phase + t * float(rules.end_twists) * TAU
						points.append(Vector3(cos(angle) * float(rules.end_strand_orbit), sin(angle) * float(rules.end_strand_orbit),
							lerpf(radius, size.z - radius, t)))
					var span := points[1] - points[0]
					b.drum(radius, span.length(), (points[0] + points[1]) * 0.5, fibre,
						Basis(Quaternion(Vector3.UP, span.normalized())), int(rules.sides))
			for i in int(rules.end_wraps):
				b.drum(float(rules.end_wrap_radius), float(rules.end_wrap_width),
					Vector3(0.0, 0.0, float(rules.end_wrap_start) + i * float(rules.end_wrap_spacing)), binding, along, int(rules.sides))
		&"coil":
			return coil()
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
		&"fm_converter":
			# Its whip up from the top's outer back corner on a chromed swivel,
			# leaning out from the set, drawn out in three lengths to a ball tip.
			var chrome := _converter(b, size, FM_TEAL, "FM")
			var lean := Basis(Vector3.RIGHT, 0.14)
			var foot := Vector3(-h.x + 0.024, h.y - 0.005, size.z - 0.018)
			b.drum(0.0065, 0.005, foot + Vector3(0.0, 0.0025, 0.0), chrome, Basis.IDENTITY, 10)
			b.ball(0.0045, foot + Vector3(0.0, 0.007, 0.0), chrome)
			var up := 0.009
			for each: Vector2 in [Vector2(0.0028, 0.08), Vector2(0.0021, 0.075), Vector2(0.0015, 0.07)]:
				b.drum(each.x, each.y, foot + lean * Vector3(0.0, up + each.y * 0.5, 0.0), chrome, lean, 6)
				up += each.y - 0.004
			b.ball(0.003, foot + lean * Vector3(0.0, up + 0.002, 0.0), chrome)
		&"sw_converter":
			# Two binding posts on its top for a long wire, short enough to clear
			# the converter over it: the aerial's on red, the ground's on black.
			_converter(b, size, SW_AMBER, "SW")
			var brass := Paint.coat(Paint.BRASS, 0.6, 0.8, 0.35)
			for post: Array in [[-0.014, Color(0.55, 0.1, 0.07)], [0.014, Paint.BLACK]]:
				var at := Vector3(post[0], h.y - 0.005, size.z * 0.55)
				b.drum(0.0055, 0.003, at + Vector3(0.0, 0.0015, 0.0), Paint.coat(post[1], 0.3, 0.0, 0.35), Basis.IDENTITY, 10)
				b.drum(0.0022, 0.006, at + Vector3(0.0, 0.005, 0.0), brass, Basis.IDENTITY, 8)
				b.drum(0.0042, 0.0028, at + Vector3(0.0, 0.0068, 0.0), brass, Basis.IDENTITY, 8)
		&"bleed_resistor", &"valve_preamp", &"direction_loop", &"static_choke", &"wire_logger", &"frequency_counter", &"headset_jack", &"solar_lid":
			_module(b, size, id)
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
## gunmetal bezel ruled in three rows, one a band, each spread across the
## window as the needle spreads it: FM over the top in MHz, shortwave under
## it in MHz, and the AM dial at the foot numbered in hundreds of kHz as old
## sets were. A tick at each step, a long one at each number.
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
	# Each row: its foot above the window's middle, m; the band's ends and its
	# first and last steps in the units it's numbered in; a number every so
	# many steps from the first; and a gap with no steps in it, AM's between
	# longwave and mediumwave.
	for row: Array in [
			[0.0025, Fm.LOWEST, Fm.HIGHEST, 88, 108, 4, Vector2.ZERO],
			[-0.011, Shortwave.LOWEST / 1000.0, Shortwave.HIGHEST / 1000.0, 2, 30, 4, Vector2.ZERO],
			[-0.0245, Dial.LOWEST / 100.0, Dial.HIGHEST / 100.0, 2, 17, 4,
				Vector2(Dial.LW_TOP, Dial.MW_BOTTOM) / 100.0]]:
		var foot: float = at.y + row[0]
		b.box(Vector3(Radio.BAND.y - Radio.BAND.x + 0.0014, 0.0008, 0.001), Vector3(at.x, foot, face), ink, 0.0)
		for step in range(row[3], row[4] + 1):
			if step > row[6].x and step < row[6].y:
				continue
			var x := lerpf(Radio.BAND.x, Radio.BAND.y, inverse_lerp(row[1], row[2], step))
			var long: bool = (step - row[3]) % row[5] == 0
			var tall := 0.0038 if long else 0.0022
			b.box(Vector3(0.0012 if long else 0.0008, tall, 0.001), Vector3(x, foot + tall * 0.5, face), ink, 0.0)
			if long:
				_numeral(b, str(step), Vector3(x, foot + 0.0079, face), 0.0062, ink)


## The strip under the band window that its lamps sit in: the signal lamps,
## then a dark glass seat for the band lamp by each band's name, faintly
## lit with the set so the names read in the dark.
static func _lamp_strip(b: Paint.Pieces, face: float) -> void:
	var y := Radio.LAMP_FROM.y
	b.box(Vector3(0.232, 0.012, 0.01), Vector3(0.004, y, face - 0.005), Paint.coat(Paint.BLACK, 0.4, 0.3, 0.5), 0.002)
	var bone := Paint.coat(Paint.BONE, 0.0, 0.0, 0.6, 0.0, 0.6)
	var glass := Paint.coat(Color(0.05, 0.05, 0.05), 0.0, 0.0, 0.15, 0.0)
	for i in Radio.BANDS.size():
		var at := Radio.BAND_LAMP_FROM + Vector3(i * Radio.BAND_LAMP_GAP, 0.0, face)
		b.drum(0.0034, 0.0012, at + Vector3(0.0, 0.0, 0.0006), glass, Basis(Vector3.RIGHT, PI / 2.0), 10)
		_numeral(b, String(Radio.BANDS[i]).to_upper(), at + Vector3(0.0115, 0.0, 0.0006), 0.0055, bone)


## A radio's band lamp, set in the strip by the band it's on and lit in its
## colour: the AM dial's own warm light, the FM converter's teal, the
## shortwave converter's amber.
static func band_lamp(band: StringName) -> ArrayMesh:
	return _cached(&"band_lamp", band, func() -> ArrayMesh:
		var colour: Color = {Radio.AM_BAND: Color(1.0, 0.82, 0.55), Radio.FM_BAND: FM_TEAL.lightened(0.35),
			Radio.SW_BAND: SW_AMBER}[band]
		var b := Paint.Pieces.new()
		b.drum(0.0032, 0.0016, Vector3(0.0, 0.0, 0.0008), Paint.coat(colour, 0.0, 0.0, 0.3, 0.0, 1.4),
			Basis(Vector3.RIGHT, PI / 2.0), 10)
		return b.commit())


## The converters' bands: what tells one from the other on a set's side.
const FM_TEAL := Color(0.25, 0.62, 0.62)
const SW_AMBER := Color(0.95, 0.55, 0.12)


## A colonial converter for a set's side, as 1960s car radios took them, a
## different maker's than the set: a black enamel box on a flange bolted to
## the side, a chromed bone face with its own small dial, a tuning knob and a
## throw between AM and its band, the band's colour and name along the face's
## foot and on its front end. Kept shorter than its socket so the converter
## over or under it clears what stands on its top. Returns its chrome.
static func _converter(b: Paint.Pieces, size: Vector3, band: Color, name: String) -> Paint.Coat:
	var h := size * 0.5
	var along := Basis(Vector3.RIGHT, PI / 2.0)
	var enamel := Paint.coat(Color(0.07, 0.07, 0.075), 0.7, 0.2, 0.35)
	var chrome := Paint.coat(Color(0.78, 0.78, 0.76), 0.3, 0.95, 0.18)
	var ink := Paint.coat(Color(0.12, 0.09, 0.07), 0.0, 0.0, 0.7, 0.0)
	var colour := Paint.coat(band, 0.5, 0.0, 0.5)
	var tall := size.y - 0.01
	b.box(Vector3(size.x - 0.002, tall, 0.004), Vector3(0.0, 0.0, 0.002), enamel, 0.001)
	for x in [-1, 1]:
		for y in [-1, 1]:
			b.drum(0.0035, 0.003, Vector3(x * (h.x - 0.0065), y * (tall * 0.5 - 0.007), 0.0055), chrome, along, 6)
	var body := Vector3(size.x - 0.024, tall, size.z - 0.012)
	b.box(body, Vector3(0.0, 0.0, 0.004 + body.z * 0.5), enamel, 0.006)
	var front := 0.004 + body.z
	# Its band on the front end, toward the set's face, where you see it.
	b.box(Vector3(0.002, tall - 0.024, body.z - 0.014), Vector3(body.x * 0.5 + 0.0005, 0.0, 0.004 + body.z * 0.5), colour, 0.0005)
	# The face: a chrome rim round bone.
	b.box(Vector3(body.x - 0.006, tall - 0.014, 0.003), Vector3(0.0, 0.0, front + 0.0005), chrome, 0.001)
	b.box(Vector3(body.x - 0.012, tall - 0.02, 0.002), Vector3(0.0, 0.0, front + 0.002), Paint.coat(Paint.BONE, 0.4, 0.0, 0.5), 0.0005)
	var on := front + 0.0035
	# Its own small dial: a pale window ruled across, a red needle.
	var window := Vector3(-0.011, 0.016, on)
	b.box(Vector3(0.05, 0.013, 0.001), window, Paint.coat(Color(0.93, 0.84, 0.62), 0.0, 0.0, 0.25, 0.0), 0.0)
	for i in 11:
		var long := i % 5 == 0
		var tick := 0.006 if long else 0.0035
		b.box(Vector3(0.0007, tick, 0.001), window + Vector3(-0.022 + i * 0.0044, -0.0065 + tick * 0.5, 0.0005), ink, 0.0)
	b.box(Vector3(0.0012, 0.012, 0.001), window + Vector3(0.004, 0.0, 0.001), Paint.coat(Color(0.8, 0.12, 0.06), 0.0, 0.0, 0.4), 0.0)
	# Its tuning knob toward the set's face, black, a chrome cap.
	var knob := Vector3(0.029, 0.01, on)
	b.drum(0.0105, 0.007, knob + Vector3(0.0, 0.0, 0.0035), Paint.coat(Paint.BLACK, 0.3, 0.3, 0.5), along, 14)
	b.drum(0.0075, 0.0015, knob + Vector3(0.0, 0.0, 0.0075), chrome, along, 14)
	# The throw, between AM and its band, thrown to the band.
	var throw := Vector3(-0.021, -0.006, on)
	b.box(Vector3(0.007, 0.011, 0.0015), throw + Vector3(0.0, 0.0, 0.00075), chrome, 0.0005)
	var thrown := Basis(Vector3.UP, 0.45) * along
	b.drum(0.0016, 0.009, throw + thrown * Vector3(0.0, 0.0045, 0.0) + Vector3(0.0, 0.0, 0.0015), chrome, thrown, 6)
	_numeral(b, "AM", throw + Vector3(-0.011, 0.0, 0.0005), 0.004, ink)
	_numeral(b, name, throw + Vector3(0.011, 0.0, 0.0005), 0.004, ink)
	# Its band and name along the face's foot.
	var foot := Vector3(0.0, -tall * 0.5 + 0.0165, on)
	b.box(Vector3(body.x - 0.012, 0.009, 0.001), foot, colour, 0.0)
	_numeral(b, name, foot + Vector3(0.0, 0.0, 0.0006), 0.0058, Paint.coat(Paint.BLACK, 0.0, 0.0, 0.6, 0.0))
	return chrome


## A misc bay module, the converters' maker's: the same enamel body on a
## chromed flange, its colour along its front end, and on its face what it does
## (from the radio kit lab's cartridges, look/radio_kit). Its +Z is out from the set.
static func _module(b: Paint.Pieces, size: Vector3, id: StringName) -> void:
	var h := size * 0.5
	var along := Basis(Vector3.RIGHT, PI / 2.0)
	var enamel := Paint.coat(Color(0.07, 0.07, 0.075), 0.7, 0.2, 0.35)
	var chrome := Paint.coat(Color(0.78, 0.78, 0.76), 0.3, 0.95, 0.18)
	var copper := Paint.coat(Color(0.72, 0.38, 0.2), 0.6, 0.7, 0.35)
	var ceramic := Paint.coat(Paint.CERAMIC, 0.4, 0.0, 0.3)
	var steel := Paint.coat(Paint.STEEL, 0.6, 0.6, 0.3)
	var colour := Paint.coat(Catalog.PARTS[id].color, 0.5, 0.0, 0.5)
	var tall := size.y - 0.01
	b.box(Vector3(size.x - 0.002, tall, 0.004), Vector3(0.0, 0.0, 0.002), enamel, 0.001)
	for x in [-1, 1]:
		for y in [-1, 1]:
			b.drum(0.0035, 0.003, Vector3(x * (h.x - 0.0065), y * (tall * 0.5 - 0.007), 0.0055), chrome, along, 6)
	var body := Vector3(size.x - 0.024, tall, size.z - 0.012)
	b.box(body, Vector3(0.0, 0.0, 0.004 + body.z * 0.5), enamel, 0.006)
	var front := 0.004 + body.z
	b.box(Vector3(0.002, tall - 0.024, body.z - 0.014), Vector3(body.x * 0.5 + 0.0005, 0.0, 0.004 + body.z * 0.5), colour, 0.0005)
	b.box(Vector3(body.x - 0.006, tall - 0.014, 0.003), Vector3(0.0, 0.0, front + 0.0005), chrome, 0.001)
	b.box(Vector3(body.x - 0.012, tall - 0.02, 0.002), Vector3(0.0, 0.0, front + 0.002), Paint.coat(Paint.BONE, 0.4, 0.0, 0.5), 0.0005)
	var on := front + 0.0035
	# Its colour in a band along the face's foot.
	b.box(Vector3(body.x - 0.012, 0.009, 0.001), Vector3(0.0, -tall * 0.5 + 0.0165, on), colour, 0.0)
	match id:
		&"bleed_resistor":
			# A finned ceramic resistor across its face, a neon that flickers as it bleeds.
			b.drum(0.008, 0.07, Vector3(0.0, 0.012, on + 0.008), ceramic, Basis(Vector3.BACK, PI / 2.0), 10)
			for i in 6:
				b.drum(0.012, 0.0025, Vector3(-0.028 + i * 0.0112, 0.012, on + 0.008), ceramic, Basis(Vector3.BACK, PI / 2.0), 12)
			b.ball(0.004, Vector3(0.036, -0.012, on + 0.003), Paint.coat(Color(1.0, 0.45, 0.2), 0.0, 0.0, 0.3, 0.0, 1.2))
		&"valve_preamp":
			# A valve in a cage, its filament glowing.
			b.drum(0.01, 0.006, Vector3(0.0, 0.006, on + 0.003), Paint.coat(Paint.BLACK, 0.5), along, 12)
			b.drum(0.008, 0.04, Vector3(0.0, 0.006, on + 0.026), Paint.coat(Color(0.5, 0.55, 0.5), 0.2, 0.2, 0.05), along, 12)
			b.drum(0.0025, 0.024, Vector3(0.0, 0.006, on + 0.026), Paint.coat(Color(1.0, 0.5, 0.15), 0.0, 0.0, 0.3, 0.0, 2.0), along, 6)
			for i in 6:
				var a := TAU * i / 6.0
				b.box(Vector3(0.0018, 0.0018, 0.046), Vector3(cos(a) * 0.012, 0.006 + sin(a) * 0.012, on + 0.024), steel, 0.0)
			b.drum(0.015, 0.0025, Vector3(0.0, 0.006, on + 0.047), steel, along, 12)
		&"direction_loop":
			# A copper loop up off its top on a turning post, a bearing ring under it.
			b.drum(0.016, 0.004, Vector3(0.0, h.y + 0.002, size.z * 0.5), Paint.coat(Paint.BONE, 0.4), Basis.IDENTITY, 16)
			b.drum(0.003, 0.03, Vector3(0.0, h.y + 0.017, size.z * 0.5), steel, Basis.IDENTITY, 8)
			b.ring(0.03, 0.035, Vector3(0.0, h.y + 0.065, size.z * 0.5), copper, Basis(Vector3.UP, 0.4) * Basis(Vector3.RIGHT, PI / 2.0) * Basis(Vector3.RIGHT, PI / 2.0), 14)
		&"static_choke":
			# A choke's can, its windings showing through a slot.
			b.drum(0.017, 0.03, Vector3(0.0, 0.006, on + 0.015), Paint.coat(Color(0.2, 0.38, 0.6), 0.5, 0.5, 0.3), along, 14)
			for i in 5:
				b.ring(0.0155, 0.0185, Vector3(0.0, 0.006, on + 0.004 + i * 0.006), copper, along, 12)
		&"wire_logger":
			# Two reels of wire under a window, a red lamp while it records.
			b.box(Vector3(0.07, 0.04, 0.002), Vector3(-0.004, 0.008, on + 0.001), Paint.coat(Color(0.12, 0.14, 0.16), 0.0, 0.0, 0.1), 0.001)
			for x in [-0.02, 0.012]:
				b.drum(0.013, 0.004, Vector3(x, 0.008, on + 0.004), Paint.coat(Paint.BONE, 0.4), along, 14)
				b.drum(0.006, 0.005, Vector3(x, 0.008, on + 0.005), copper, along, 12)
			b.ball(0.003, Vector3(0.04, 0.024, on + 0.002), Paint.coat(Color(1.0, 0.2, 0.1), 0.0, 0.0, 0.3, 0.0, 1.5))
		&"frequency_counter":
			# Glowing digits behind a dark window.
			b.box(Vector3(0.076, 0.026, 0.002), Vector3(0.0, 0.012, on + 0.001), Paint.coat(Color(0.05, 0.03, 0.03), 0.0, 0.0, 0.1), 0.001)
			_numeral(b, "1020", Vector3(0.0, 0.012, on + 0.0025), 0.016, Paint.coat(Color(1.0, 0.35, 0.12), 0.0, 0.0, 0.3, 0.0, 2.0))
		&"headset_jack":
			# A jack, and the headset hung on it by its cord.
			b.drum(0.005, 0.008, Vector3(-0.03, 0.02, on + 0.004), steel, along, 10)
			b.ring(0.026, 0.03, Vector3(0.006, 0.0, on + 0.012), Paint.coat(Paint.BLACK, 0.6), Basis.IDENTITY, 10)
			for x in [-1, 1]:
				b.drum(0.012, 0.01, Vector3(0.006 + x * 0.028, -0.004, on + 0.012), Paint.coat(Paint.BLACK, 0.6), Basis(Vector3.BACK, PI / 2.0), 14)
				b.drum(0.01, 0.003, Vector3(0.006 + x * 0.034, -0.004, on + 0.012), Paint.coat(Paint.BONE, 0.6), Basis(Vector3.BACK, PI / 2.0), 14)
		&"solar_lid":
			# A lid of cells, hinged open off its top.
			var lid := Basis(Vector3.RIGHT, -0.5)
			var hinge := Vector3(0.0, h.y, front)
			b.box(Vector3(body.x, 0.004, 0.07), hinge + lid * Vector3(0.0, 0.0, 0.035), enamel, 0.002, lid)
			for i in 3:
				for j in 2:
					b.box(Vector3(0.026, 0.002, 0.03), hinge + lid * Vector3(-0.03 + i * 0.03, 0.003, 0.018 + j * 0.033),
						Paint.coat(Paint.CELL, 0.6, 0.6, 0.2), 0.0, lid)


## A number or a name in block strokes, `tall` m high, its middle at `at`,
## facing +Z.
static func _numeral(b: Paint.Pieces, text: String, at: Vector3, tall: float, look: Paint.Coat) -> void:
	# Strokes a to g: top, top right, bottom right, bottom, bottom left, top
	# left, middle; and h to k, from the corners top left, top right, bottom
	# left and bottom right in to the middle, for an M and a W.
	const STROKES := {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd",
		"6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg", "A": "abcefg", "F": "aefg", "S": "afgcd",
		"M": "bcefhi", "W": "bcefjk"}
	const PLACES := {"a": Vector2(0.0, 0.5), "g": Vector2.ZERO, "d": Vector2(0.0, -0.5), "b": Vector2(0.5, 0.25),
		"c": Vector2(0.5, -0.25), "e": Vector2(-0.5, -0.25), "f": Vector2(-0.5, 0.25)}
	const CORNERS := {"h": Vector2(-0.5, 0.5), "i": Vector2(0.5, 0.5), "j": Vector2(-0.5, -0.5), "k": Vector2(0.5, -0.5)}
	var wide := tall * 0.55
	var line := tall * 0.13
	var gap := wide * 0.5
	# A 1 is one stroke, as narrow as it; an M and a W want more room.
	var widths: Array[float] = []
	var span := -gap
	for digit in text:
		widths.append(line if digit == "1" else (wide * 1.35 if digit in "MW" else wide))
		span += widths[-1] + gap
	var x := at.x - span * 0.5
	for i in text.length():
		var w := widths[i] if text[i] in "MW" else wide
		var middle := Vector3(x + widths[i] * 0.5, at.y, at.z)
		for stroke in STROKES[text[i]]:
			if CORNERS.has(stroke):
				var from: Vector2 = CORNERS[stroke] * Vector2(w, tall)
				b.box(Vector3(line, from.length(), 0.001), middle + Vector3(from.x, from.y, 0.0) * 0.5, look, 0.0,
					Basis(Vector3.BACK, atan2(from.x, -from.y)))
				continue
			var where: Vector2 = PLACES[stroke]
			if text[i] == "1":
				where.x = 0.0
			var size := Vector3(w + line, line, 0.001) if stroke in "adg" else Vector3(line, tall * 0.5 + line, 0.001)
			b.box(size, middle + Vector3(where.x * w, where.y * tall, 0.0), look, 0.0)
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
