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


## A compass's needle (HeldLooks), lit so it glows a little.
static func needle() -> ArrayMesh:
	return _cached(&"needle", &"compass", HeldLooks.needle)


## A bedroll unrolling, `open` of the way from rolled to flat, in its own
## frame: its head stays where the roll lay and the pad lies out flat along
## +X behind the roll as it rolls away, thinner as it goes, to its foot; the
## pillow at its head plumps up as the roll leaves it, and the straps lie
## undone beside it. Stepped, each step made once.
static func bedroll(open: float, line: Array = []) -> ArrayMesh:
	var step := clampi(roundi(open * BEDROLL_STEPS), 1, BEDROLL_STEPS)
	var era := Eras.era_of(line)
	return _cached(&"bedroll", StringName("%s:%d" % [era, step]), func() -> ArrayMesh: return CampLooks.unroll(float(step) / BEDROLL_STEPS, era))


## Its head to its foot, laid, m; the pad's thickness and the foot's hem.
const BEDROLL_LENGTH := 1.9
const BEDROLL_PAD := 0.03
const BEDROLL_HEM := 0.03
const BEDROLL_STEPS := 40




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
	var own := ChassisLooks.lineage(id, line)
	if own == null:
		own = ShieldLooks.lineage(id, line)
	if own == null:
		own = CampLooks.lineage(id, line)
	if own == null:
		own = CellLooks.lineage(id, line)
	if own == null:
		own = BoardLooks.lineage(id, line)
	if own == null:
		own = StationLooks.lineage(id, line)
	if own == null:
		own = HeldLooks.lineage(id, line)
	if own == null:
		own = WorldLooks.lineage(id, line)
	var shape := own.get_instance_id() if own != null else 0
	if own == null:
		own = _own(id)
	var shell := shell(id, own) if shape != 0 else shell(id)
	if own == null or own.get_surface_count() == 0 or shell == null:
		return own
	var overs := []
	for entry: Array in line:
		var key := [id, shape, Eras.entry_key(entry)]
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
static func shell(id: StringName, own: ArrayMesh = null) -> Paint.Shell:
	# Repairs follow the era's rebuilt surfaces, including its missing corners.
	var key: Variant = [id, own.get_instance_id()] if own != null else id
	if _shells.has(key):
		return _shells[key]
	var made: Paint.Shell = null
	if own == null:
		own = _own(id)
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
	_shells[key] = made
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
	for era: StringName in ShieldLooks.SHAPES:
		shell(&"shield", ShieldLooks.look(&"shield", era))
	for era: StringName in BoardLooks.SHAPES:
		shell(&"board", BoardLooks.look(&"board", era))
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
	if CampLooks.frame(b, id, size, extra) or ChassisLooks.frame(b, id, size) or PowerLooks.frame(b, id, size) or VarranLooks.frame(b, id, size) or WorldLooks.frame(b, id, size):
		return b.commit()
	if BoardLooks.frame(b, id, size):
		return b.commit()
	if HeldLooks.frame(b, id, size):
		return b.commit()
	if ShieldLooks.frame(b, id, size):
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
		&"survey_receiver":
			return SurveyReceiverLooks.frame()
		&"antenna_kite":
			return KiteLooks.packed(size)
		&"salvage_kite":
			return KiteLooks.packed(size, KiteLooks.SALVAGE_CLOTH, KiteLooks.SALVAGE_TRIM)
		&"radio", &"radio_colonial", &"radio_skimmer", &"radio_kingdoms", &"radio_second_age":
			# The field radio in its maker's look, its body alone: its needle,
			# knobs, lamps and band window are the radio's own, live.
			return RadioKitLooks.field_radio(Catalog.DEVICES[id].style, {}, &"am", false, true)
		&"crystal_set":
			return RadioKitLooks.crystal_set()
		&"headset":
			# Two padded cups on a sprung steel band, the jack on the left cup.
			var pad := Paint.coat(Paint.BLACK, 0.7)
			var band := Paint.coat(Paint.STEEL, 0.6, 0.6, 0.3)
			var sideways := Basis(Vector3.BACK, PI / 2.0)
			var cups := -h.y + 0.04
			for x in [-1, 1]:
				b.drum(0.035, 0.03, Vector3(x * (h.x - 0.015), cups, 0.0), pad, sideways, 14)
				b.drum(0.028, 0.006, Vector3(x * (h.x - 0.033), cups, 0.0), Paint.coat(Paint.BONE, 0.6), sideways, 14)
			var reach := Vector2(h.x - 0.015, size.y - 0.05)
			for i in 9:
				var a0 := PI * i / 9.0
				var a1 := PI * (i + 1) / 9.0
				var p0 := Vector2(-cos(a0) * reach.x, sin(a0) * reach.y)
				var p1 := Vector2(-cos(a1) * reach.x, sin(a1) * reach.y)
				var mid := (p0 + p1) * 0.5
				b.box(Vector3(p0.distance_to(p1) + 0.004, 0.006, 0.022), Vector3(mid.x, cups + mid.y, 0.0), band, 0.002,
					Basis(Vector3.BACK, (p1 - p0).angle()))
			b.drum(0.006, 0.012, Vector3(-h.x - 0.004, cups, 0.0), Paint.coat(Paint.STEEL, 0.3, 0.9, 0.2), sideways, 10)
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
	if ChassisLooks.part(b, id, size):
		return b.commit()
	if CellLooks.part(b, id, size) or StationLooks.part(b, id, size) or WorldLooks.part(b, id, size):
		return b.commit()
	if BoardLooks.part(b, id, size):
		return b.commit()
	if HeldLooks.part(b, id, size, count):
		return b.commit()
	match id:
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
		&"bleed_resistor", &"valve_preamp", &"static_choke", &"wire_logger", &"solar_lid":
			_module(b, size, id)
		&"root_tuber", &"vat_fungus", &"saltbush":
			return crop(id, Plant.RIPE)
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
		&"coalcane":
			# Ringed woody stalks repeat the cut bundle's six stems, with long cane leaves.
			var tall := 0.18 if young else (0.65 if stage == Plant.YOUNG else 1.2)
			var wood := Paint.coat(Color(0.24, 0.15, 0.07), 0.7)
			for i in 6:
				var a := TAU * i / 6.0
				var foot := Vector3(sin(a) * 0.14, 0, cos(a) * 0.14)
				var height := tall * rng.randf_range(0.8, 1.0)
				_stem(b, foot, foot + Vector3.UP * height, 0.025 if young else 0.045, wood)
				for k in 4:
					var at := foot + Vector3.UP * height * (k + 1) / 5.0
					_up_drum(b, 0.029 if young else 0.05, 0.018, at, WOOD)
					_leaf(b, at, a + k * 2.4, 0.3, tall * 0.45, 0.075, POTATO_LEAF)
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
