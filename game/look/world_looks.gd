class_name WorldLooks
extends RefCounted
## The historical sites keep their own era; sailing kit takes its last hands' shape.
const IDS: Array[StringName] = [&"streamer", &"fabric", &"crows_nest"]
const SITES: Array[StringName] = [&"pipe_wall_hut", &"cistern", &"low_wall", &"vent_mouth", &"fuel_bladder", &"pipeline_segment"]
const ALONG := Basis(Vector3.RIGHT, PI / 2.0)
static var _eras := {}

static func site(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	match p.kind:
		&"pipe_wall_hut": _hut(b, p, state)
		&"cistern": _cistern(b, p, state)
		&"low_wall": _wall(b, p, state)
		&"vent_mouth": _vent(b, p, state)
		&"fuel_bladder": _bladder(b, p, state)
		&"pipeline_segment": _pipe(b, p, state)

static func frame(b: Paint.Pieces, id: StringName, size: Vector3, era := Eras.NEW, _extra := 0.0) -> bool:
	match id:
		&"streamer": _wand(b, size, era)
		&"crows_nest": _nest(b, size, era)
		_: return false
	return true

static func part(b: Paint.Pieces, id: StringName, size: Vector3, era := Eras.NEW, _count := -1) -> bool:
	if id != &"fabric": return false
	_fabric(b, size, era)
	return true

static func lineage(id: StringName, line: Array) -> ArrayMesh:
	if not IDS.has(id): return null
	var era := Eras.era_of(line)
	var key := [id, era]
	if not _eras.has(key):
		var is_part := Catalog.PARTS.has(id)
		var size: Vector3 = (Catalog.PARTS[id] if is_part else Catalog.DEVICES[id]).size
		var b := Paint.Pieces.new(0.0 if is_part else -size.y * 0.5)
		if is_part: part(b, id, size, era)
		else: frame(b, id, size, era)
		_eras[key] = b.commit()
	return _eras[key]

static func _hut(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := FirstKingdomsKit.coats()
	var house: Paint.Coat = c.house
	# Separate salvaged roof sheets keep the solid slab's exact outer profile.
	for i in p.shown(state):
		var coat: String = p.coats[i]
		if coat.is_empty(): continue
		var solid: AABB = p.boxes[i]
		if coat == "hull":
			for panel in 4:
				var width := solid.size.x / 4.0
				var at := solid.position + Vector3((panel + 0.5) * width, solid.size.y * 0.5, solid.size.z * 0.5)
				b.box(Vector3(width - 0.025, solid.size.y, solid.size.z), at, c.hull if panel % 2 else c.pipe, 0.025)
		else:
			b.box(solid.size, solid.get_center(), c[coat], 0.03)
	# Each wall: a stone core with two courses of colonial pipe laid along it.
	var runs := [[Vector2(-4.0, 2.5), Vector2(-2.2, 2.5)], [Vector2(-0.8, 2.5), Vector2(4.0, 2.5)],
		[Vector2(-4.0, -2.5), Vector2(4.0, -2.5)], [Vector2(-3.5, -2.0), Vector2(-3.5, 2.0)],
		[Vector2(3.5, -2.0), Vector2(3.5, 2.0)]]
	for run: Array in runs:
		var a: Vector2 = run[0]
		var e: Vector2 = run[1]
		var mid := (a + e) * 0.5
		var along := e - a
		var turn := Basis(Vector3.FORWARD, PI * 0.5) if absf(along.x) > 0.01 else Basis(Vector3.RIGHT, PI * 0.5)
		var size := Vector3(absf(along.x), 2.6, 0.8) if absf(along.x) > 0.01 else Vector3(0.8, 2.6, absf(along.y))
		b.box(size, Vector3(mid.x, 0.7, mid.y), c.stone, 0.05)
		for k in 2:
			var y := 0.45 + k * 0.95
			if StructureKit.shows(p, state, y + 0.48):
				b.drum(0.48, along.length(), Vector3(mid.x, y, mid.y), c.pipe, turn, 14)
				# Brass flanges where the lengths of pipe meet, a flared cap at each end.
				var joints := maxi(1, roundi(along.length() / 3.0))
				for j in joints + 1:
					var at := a.lerp(e, float(j) / joints)
					b.drum(0.53, 0.09, Vector3(at.x, y, at.y), c.brass if j > 0 and j < joints else c.copper, turn, 14)
		if StructureKit.shows(p, state, 2.2):
			b.box(size - Vector3(0.0, 2.25, 0.0) + Vector3(0.1, 0.0, 0.1), Vector3(mid.x, 2.025, mid.y), c.stone_dark, 0.04)
	# The house's colour round the pipe by the door, its crest on the wall beside it.
	if StructureKit.shows(p, state, 1.9):
		b.drum(0.5, 0.35, Vector3(-3.3, 1.4, 2.5), house, Basis(Vector3.FORWARD, PI * 0.5), 14)
		FirstKingdomsKit.crest(b, Vector3(0.4, 1.35, 3.01), house, c)
	# The machine: a housing with a copper coil and a brass valve wheel.
	if StructureKit.shows(p, state, 1.1):
		b.box(Vector3(1.4, 1.1, 0.8), Vector3(2.3, 0.55, -1.6), c.pipe, 0.08)
		b.drum(0.3, 0.6, Vector3(2.3, 0.75, -1.15), c.copper, Basis(Vector3.RIGHT, PI * 0.5), 12)
		b.ring(0.16, 0.22, Vector3(1.75, 1.18, -1.6), c.brass, Basis.IDENTITY, 8)


	# Folded seams catch the light without raising the solid roof.
	if StructureKit.shows(p, state, 2.3):
		for x: float in [-3.8, -2.3, -0.8, 0.7, 2.2, 3.7]:
			b.box(Vector3(0.04, 0.04, 3.5), Vector3(x, 2.315, -1.2), c.pipe, 0.005)
		for z: float in [-2.92, 0.52]:
			b.box(Vector3(7.9, 0.09, 0.04), Vector3(0, 2.26, z), c.brass, 0.007)
	for x: float in [-3.5, 3.5]:
		for y: float in [-0.25, 0.35, 0.95, 1.55]:
			if StructureKit.shows(p, state, y + 0.25):
				b.box(Vector3(0.78, 0.54, 0.04), Vector3(x, y, 2.98), c.stone_dark if y < 0 else c.stone, 0.015)


static func _cistern(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := FirstKingdomsKit.coats()
	StructureKit.draw_boxes(b, p, state, c, 0.03)
	# Dressed coping stones round the rim, each its own block.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for side in 4:
		var turn := Basis(Vector3.UP, side * PI * 0.5)
		# Front and back run corner to corner; the sides between them.
		var reach := 4.0 if side % 2 == 0 else 3.0
		var u := -reach
		while u < reach - 0.01:
			var at := turn * Vector3(u + 0.5, 0.3, 3.5)
			var gap := side == 0 and absf(u + 0.5) < 1.0
			if not gap:
				var look: Paint.Coat = c.stone if rng.randf() < 0.6 else c.stone_dark
				b.box(Vector3(0.96, 0.6, 0.98).abs(), at, look, 0.06, turn)
			u += 1.0
		# The walls down to the floor, in courses, stained where the water stood.
		if StructureKit.shows(p, state, 0.0, Vector2.ZERO):
			b.box(Vector3(6.0, 2.4, 0.02), turn * Vector3(0.0, -1.2, 2.99), c.stone_dark, 0.005, turn)
			b.box(Vector3(6.0, 0.12, 0.025), turn * Vector3(0.0, -0.75, 2.985), c.tide, 0.004, turn)
	# Where the colonial line came in: its pipe through the back wall, a brass
	# flange and valve wheel, the house's colour round it.
	b.drum(0.32, 1.4, Vector3(1.0, -0.6, -3.2), c.pipe, Basis(Vector3.RIGHT, PI * 0.5), 14)
	b.drum(0.4, 0.1, Vector3(1.0, -0.6, -2.5), c.brass, Basis(Vector3.RIGHT, PI * 0.5), 14)
	b.drum(0.34, 0.2, Vector3(1.0, -0.6, -2.85), c.house, Basis(Vector3.RIGHT, PI * 0.5), 14)
	b.ring(0.2, 0.26, Vector3(1.0, -0.15, -2.75), c.brass, Basis(Vector3.RIGHT, PI * 0.5), 8)


	# Broad courses make the pit read as masonry rather than smooth panels.
	for side in 4:
		var turn := Basis(Vector3.UP, side * PI / 2)
		for row in 3:
			var y := -1.65 + row * 0.7
			if not StructureKit.shows(p, state, y + 0.34, Vector2.ZERO): continue
			for column in 6:
				var u := -2.5 + column
				b.box(Vector3(0.97, 0.67, 0.025), turn * Vector3(u, y, 2.965), c.stone if (row + column) % 3 else c.stone_dark, 0.0, turn)
	if StructureKit.shows(p, state, -0.1, Vector2.ZERO):
		b.box(Vector3(0.07, 1.2, 0.025), Vector3(1.7, -0.7, -2.95), c.brass, 0.005)
		for i in 7:
			b.box(Vector3(0.14 if i % 2 == 0 else 0.09, 0.025, 0.03), Vector3(1.68, -1.2 + i * 0.17, -2.93), c.house, 0.0)


static func _wall(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := FirstKingdomsKit.coats()
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	# Dry stone in courses: each block its own, a little off true.
	for solid: Array in [[Vector2(-5.0, -1.9), Vector2(0.3, -1.2)], [Vector2(2.5, -1.9), Vector2(5.0, -1.2)],
			[Vector2(-5.0, -1.2), Vector2(-4.3, 1.9)]]:
		var lo: Vector2 = solid[0]
		var hi: Vector2 = solid[1]
		var long_u := hi.x - lo.x > hi.y - lo.y
		for course in 3:
			var y := -0.35 + course * 0.48
			if not StructureKit.shows(p, state, y + 0.48):
				continue
			var at := (lo.x if long_u else lo.y) + (0.35 if course % 2 == 1 else 0.0)
			var end := hi.x if long_u else hi.y
			while at < end - 0.05:
				var size := minf(rng.randf_range(0.55, 0.9), end - at)
				var mid := Vector3(at + size * 0.5, y + 0.23, (lo.y + hi.y) * 0.5) if long_u \
					else Vector3((lo.x + hi.x) * 0.5, y + 0.23, at + size * 0.5)
				var dims := Vector3(size - 0.04, 0.46, 0.7) if long_u else Vector3(0.7, 0.46, size - 0.04)
				var look: Paint.Coat = c.stone if rng.randf() < 0.65 else c.stone_dark
				b.box(dims, mid + Vector3(0.0, rng.randf_range(-0.02, 0.02), 0.0), look, 0.07,
					Basis(Vector3.UP, rng.randf_range(-0.04, 0.04)))
				at += size
	# The gateposts and their caps, the house's colour on one, its crest below.
	for u: float in [0.45, 2.35]:
		b.drum(0.16, 1.95, Vector3(u, 0.58, -1.55), c.pipe, Basis.IDENTITY, 12)
		b.drum(0.21, 0.12, Vector3(u, 1.57, -1.55), c.brass, Basis.IDENTITY, 12, 0.14)
	b.drum(0.17, 0.22, Vector3(0.45, 1.2, -1.55), c.house, Basis.IDENTITY, 12)
	FirstKingdomsKit.crest(b, Vector3(0.45, 0.75, -1.38), c.house, c)
	# Stones fallen from it, half in the sand.
	if StructureKit.shows(p, state, 0.2):
		b.box(Vector3(0.6, 0.4, 0.5), Vector3(-2.2, 0.05, -0.75), c.stone, 0.07, Basis(Vector3.UP, 0.4))
		b.box(Vector3(0.5, 0.35, 0.55), Vector3(3.6, 0.0, -0.8), c.stone_dark, 0.07, Basis(Vector3.UP, -0.3))


	for u: float in [0.45, 2.35]:
		for y: float in [0.25, 1.02]:
			if StructureKit.shows(p, state, y + 0.08):
				b.drum(0.19, 0.07, Vector3(u, y, -1.55), c.brass, Basis.IDENTITY, 12, 0.16)
		if StructureKit.shows(p, state, 0.75):
			b.box(Vector3(0.04, 0.26, 0.04), Vector3(u, 0.6, -1.36), c.copper, 0.005)


static func _vent(b: Paint.Pieces, p: StructureKit.Piece, _state: int) -> void:
	var c := GeologyKit.coats()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for box: AABB in p.boxes:
		var middle := box.get_center()
		var turn := Basis(Vector3.UP, rng.randf() * TAU)
		var seam := rng.randf_range(-0.3, 0.3)
		var stone: Paint.Coat = c.basalt if rng.randf() < 0.7 else c.scoria
		b.drum(box.size.x * 0.42, box.size.y * 0.88, middle, stone, turn, 5, box.size.x * 0.24)
		for side: float in [-1, 1]:
			var at := middle + turn * Vector3(side * box.size.x * 0.22, -box.size.y * 0.2, seam * box.size.z * 0.1)
			b.drum(box.size.x * 0.22, box.size.y * 0.5, at, c.scoria if side > 0 else c.basalt, turn, 5, box.size.x * 0.13)
	# Sulphur crusts the throat's upper slope, where the gas cools.
	for k in 9:
		var a := rng.randf() * TAU
		var d := rng.randf_range(3.5, 6.5)
		var at := Vector2(cos(a) * d, sin(a) * d)
		at.y += signf(at.y) * rng.randf() * GeologyKit.SLOT
		var y := GeologyKit.profile(GeologyKit.from_slot(at))
		var down := (Vector2(at.x, signf(at.y) * maxf(absf(at.y) - GeologyKit.SLOT, 0.0))).normalized()
		var tilt := Basis(Vector3(down.y, 0.0, -down.x).normalized(), -atan((GeologyKit.CREST_HEIGHT + GeologyKit.PIT_DEPTH) / (GeologyKit.CREST - GeologyKit.PIT)))
		var width := rng.randf_range(1.2, 2.4)
		var depth := rng.randf_range(0.8, 1.6)
		var turn := tilt * Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(width, 1, depth))
		b.drum(0.5, 0.025, Vector3(at.x, y + 0.02, at.y), c.sulphur, turn, 6, 0.44)


static func _bladder(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := SkimmerKit.coats()
	StructureKit.draw_boxes(b, p, state, c, 0.03)
	# The bag itself, flattened by its own weight, and the tape over its leaks.
	b.ball(1.0, Vector3(0.0, 0.66, 0.0), c.rubber, Vector3(2.4, 0.58, 1.42))
	for patch: Array in [[Vector3(-0.9, 1.22, 0.3), 0.5], [Vector3(1.1, 1.12, -0.6), 0.3], [Vector3(0.2, 0.9, 1.25), 0.4]]:
		b.box(Vector3(patch[1], 0.03, patch[1] * 0.6), patch[0], c.tape, 0.005)
	# Straps over it to the pallet, a valve with its wheel, the crew's patch.
	for u: float in [-1.4, 0.0, 1.4]:
		var section := sqrt(1.0 - u * u / (2.4 * 2.4))
		var last := Vector3(u, 0.13, -1.45 * section)
		for step in 13:
			var angle := PI - step * PI / 12.0
			var at := Vector3(u, 0.66 + sin(angle) * 0.59 * section, cos(angle) * 1.45 * section)
			StructureKit.rod(b, last, at, 0.055, c.olive)
			last = at
		StructureKit.rod(b, last, Vector3(u, 0.13, 1.45 * section), 0.055, c.olive)
		for v: float in [-1.48, 1.48]:
			b.box(Vector3(0.18, 0.08, 0.1), Vector3(u, 0.17, v), c.steel, 0.01)
	b.ring(0.12, 0.17, Vector3(2.8, 0.58, 0.0), c.red, Basis(Vector3.FORWARD, PI * 0.5), 8)
	b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(0.0, 0.25, 1.62), 0.7)
	b.box(Vector3(1.0, 0.3, 0.04), Vector3(0.0, 0.0, 1.6), c.scrap, 0.01)


static func _pipe(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := ColonialKit.coats()
	StructureKit.draw_boxes(b, p, state, c, 0.05)
	var along := Basis(Vector3.RIGHT, PI * 0.5)
	if StructureKit.shows(p, state, 1.8):
		b.drum(0.7, 12.0, Vector3(0.0, 1.1, 0.0), c.panel, along, 18)
		# Bolted flanges at its ends and middle, a band and the contractor's tag.
		for v: float in [-5.95, 0.0, 5.95]:
			b.drum(0.8, 0.14, Vector3(0.0, 1.1, v), c.grey, along, 18)
		b.drum(0.71, 0.4, Vector3(0.0, 1.1, 4.4), c.orange, along, 18)
		b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.71, 1.1, -2.0), 0.9, Basis(Vector3.UP, PI * 0.5))
		b.box(Vector3(0.02, 0.5, 1.0), Vector3(0.7, 1.1, -2.0), c.panel, 0.002)
		# The inspection hatch on its back.
		b.box(Vector3(0.6, 0.06, 0.8), Vector3(0.0, 1.8, 2.0), c.dark, 0.02)


	if StructureKit.shows(p, state, 1.8):
		for z: float in [-5.92, 0.0, 5.92]:
			for i in 10:
				var angle := i * TAU / 10
				var at := Vector3(cos(angle) * 0.75, 1.1 + sin(angle) * 0.75, z)
				b.drum(0.035, 0.18, at, c.dark, ALONG, 6)
		for z: float in [-3.5, 3.5]:
			b.ring(0.705, 0.745, Vector3(0, 1.1, z), c.grey, ALONG, 8)
			for x: float in [-0.77, 0.77]:
				b.box(Vector3(0.07, 0.3, 0.25), Vector3(x, 0.45, z), c.dark, 0.01)
		for x: float in [-0.24, 0.24]:
			b.box(Vector3(0.04, 0.035, 0.48), Vector3(x, 1.86, 2.0), c.grey, 0.006)


## The same small kit, rebuilt by the hands that kept it.
static func _coats(era: StringName) -> Dictionary:
	var c := NomadLooks.coats().duplicate()
	match era:
		Eras.COLONIAL:
			c.wood = Paint.coat(Paint.BONE, 0.5, 0.2, 0.5)
			c.scrap = Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5)
			c.ochre = Paint.coat(Paint.DROP_ORANGE, 0.5, 0.0, 0.85)
		Eras.FIRST:
			c.wood = Paint.coat(Paint.BONE, 0.4, 0.1, 0.5)
			c.scrap = Paint.coat(Paint.BRASS, 0.3, 0.9, 0.35)
		Eras.SKIMMER:
			c.wood = Paint.coat(Paint.STRONG_RED, 0.9, 0.2, 0.7)
			c.scrap = Paint.coat(Paint.STEEL, 0.6, 0.8, 0.5)
		Eras.SECOND:
			c.wood = Paint.coat(Paint.SALTWOOD, 0.5, 0.0, 0.8)
			c.bone = Paint.coat(Paint.CERAMIC, 0.2, 0.0, 0.35)
			c.cord = Paint.coat(Paint.CORD, 0.0, 0.0, 0.9)
	return c


static func _wand(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var c := _coats(era)
	var h := size * 0.5
	b.drum(0.009, size.y - 0.04, Vector3.ZERO, c.wood, Basis.IDENTITY, 8, 0.006)
	b.box(Vector3(size.x, 0.026, size.z), Vector3(0, -h.y + 0.013, 0), c.bone, 0.005)
	for y in [-h.y + 0.05, h.y - 0.055]:
		for i in 3:
			b.drum(0.011, 0.004, Vector3(0, y + i * 0.005, 0), c.cord, Basis.IDENTITY, 8)
	b.ring(0.007, 0.014, Vector3(0, h.y - 0.016, 0), c.brass, ALONG, 8)
	if era == Eras.FIRST:
		b.drum(0.013, 0.04, Vector3(0, -0.07, 0), c.brass, Basis.IDENTITY, 8, 0.009)
	elif era == Eras.SECOND:
		b.ball(0.006, Vector3(0.012, -0.1, 0.004), c.bone)
		StructureKit.rod(b, Vector3(0, -0.08, 0), Vector3(0.012, -0.1, 0.004), 0.002, c.cord)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.015, 0.1, 0.012), Vector3(0.004, -0.07, 0), c.scrap, 0.002)


static func _nest(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var c := _coats(era)
	var h := size * 0.5
	# Separate planks sit on a square frame; their top is still the real seat floor.
	for x in [-1.0, 1.0]:
		b.box(Vector3(0.032, 0.04, size.z - 0.04), Vector3(x * (h.x - 0.04), -h.y + 0.02, 0), c.scrap, 0.005)
	for i in 7:
		var z := -h.z + 0.07 + i * (size.z - 0.14) / 6.0
		b.box(Vector3(size.x - 0.06, 0.024, 0.102), Vector3(0, -h.y + 0.052, z), c.wood, 0.003)
	for k in 8:
		var angle := k * TAU / 8.0
		var at := Vector3(cos(angle) * 0.39, 0, sin(angle) * 0.39)
		var remade := era == Eras.SECOND and k == 4
		b.drum(0.024 if remade else 0.015, size.y - 0.08, at, c.bone if remade else c.wood,
			Basis.IDENTITY, 8, 0.017 if remade else -1.0)
		for y in [-h.y + 0.1, h.y - 0.07]:
			for j in 3:
				b.drum(0.021, 0.006, at + Vector3(0, y + j * 0.008, 0), c.cord, Basis.IDENTITY, 8)
		var next := Vector3(cos(angle + TAU / 8) * 0.39, 0, sin(angle + TAU / 8) * 0.39)
		StructureKit.rod(b, at + Vector3(0, h.y - 0.025, 0), next + Vector3(0, h.y - 0.025, 0), 0.019, c.scrap)
		if k != 1 and k != 2:
			# Short panels follow the basket instead of cutting through its corners.
			var middle := (at + next) * 0.5 + Vector3(0, -h.y + 0.25, 0)
			var along := (next - at).normalized()
			var turn := Basis(along, Vector3.UP, along.cross(Vector3.UP))
			b.box(Vector3(at.distance_to(next) - 0.025, 0.32, 0.009), middle, c.indigo if k == 4 else c.ochre, 0.0, turn)
			for y in [-0.147, 0.147]:
				b.box(Vector3(at.distance_to(next) - 0.03, 0.012, 0.012), middle + Vector3(0,y,0), c.cord, 0.001, turn)
	if era == Eras.SECOND:
		b.ball(0.026, Vector3(-0.33, 0.22, 0.09), c.bone)
		StructureKit.rod(b, Vector3(-0.34, 0.35, 0.09), Vector3(-0.33, 0.22, 0.09), 0.007, c.cord)
	elif era == Eras.FIRST:
		for x in [-0.26, 0.26]:
			b.drum(0.026, 0.06, Vector3(x, 0.43, -0.26), c.brass, Basis.IDENTITY, 8, 0.018)
	elif era == Eras.COLONIAL:
		b.box(Vector3(0.32, 0.07, 0.016), Vector3(0, -0.12, -0.36), c.wood, 0.008)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.18, 0.16, 0.014), Vector3(0.22, -0.23, -0.25), c.scrap, 0.005, Basis(Vector3.UP, PI / 4))


static func _fabric(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var c := _coats(era)
	var h := size * 0.5
	for sign_: float in [-1, 1]:
		b.box(Vector3(size.x, 0.025, size.z), Vector3(0, sign_ * (h.y - 0.0125), h.z), c.cord, 0.001)
		b.box(Vector3(0.025, size.y, size.z), Vector3(sign_ * (h.x - 0.0125), 0, h.z), c.cord, 0.001)
	for x: float in [-1, 1]:
		for y: float in [-1, 1]:
			var at := Vector3(x * (h.x - 0.04), y * (h.y - 0.04), h.z)
			b.box(Vector3(0.07, 0.07, size.z), at, c.wood, 0.003)
			b.drum(0.018, size.z, at, c.brass, ALONG, 10)
	# Paired stitches and a repair seam remain visible when the canvas bellies.
	for i in 13:
		var at := (i - 6) * (size.x - 0.12) / 12.0
		for sign_: float in [-1, 1]:
			b.box(Vector3(0.009, 0.018, 0.002), Vector3(at, sign_ * (h.y - 0.03), size.z - 0.001), c.bone, 0.0)
