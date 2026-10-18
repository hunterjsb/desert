class_name FirstKingdomsKit
extends RefCounted
## The First Kingdoms' pieces (part 4, read through part 2's age): pipe-wall
## huts built into colonial pipelines, cisterns where the colonial water lines
## ended, low stone walls round old field plots. Keepers of machines nobody
## could build any more: the colonial geometry kept intact and clean, brass
## and copper fittings, flared caps, a house's colour in enamel bands (deep
## red, ochre, teal) and its crest. Low foundations that lie deep: barely
## visible, found by surface signs; digging reveals a floor plan.

const STONE := Color(0.66, 0.55, 0.41)
const STONE_DARK := Color(0.5, 0.42, 0.33)
const PIPE := Color(0.71, 0.7, 0.65)
const HULL := Color(0.42, 0.44, 0.44)
const BRASS := Color(0.74, 0.57, 0.27)
const COPPER := Color(0.62, 0.36, 0.22)
const TIDE := Color(0.78, 0.74, 0.66)
## The great houses' enamel: deep red, ochre, teal; a site's look picks one.
const HOUSES: Array[Color] = [Color(0.5, 0.12, 0.1), Color(0.74, 0.53, 0.15), Color(0.1, 0.42, 0.42)]

static var _coats := {}


static func pieces() -> Array[StructureKit.Piece]:
	return [_pipe_wall_hut(), _cistern(), _low_wall()]


static func coats() -> Dictionary:
	if _coats.is_empty():
		_coats = {"stone": Paint.coat(STONE, 0.15, 0.0, 0.92), "stone_dark": Paint.coat(STONE_DARK, 0.15, 0.0, 0.95),
			"pipe": Paint.coat(PIPE, 0.6, 0.2, 0.55), "hull": Paint.coat(HULL, 0.9, 0.6, 0.5),
			"brass": Paint.coat(BRASS, 0.0, 0.9, 0.32, 0.6), "copper": Paint.coat(COPPER, 0.0, 0.85, 0.4, 0.6),
			"tide": Paint.coat(TIDE, 0.0, 0.0, 0.95, 0.5)}
		# Drawn in the first house's colour; each look swaps in its own.
		_coats["house"] = Paint.coat(HOUSES[0], 0.6, 0.1, 0.35)
	return _coats


# --- The pipe-wall hut: walls of colonial pipe laid in stone, a hull-plate roof. ---

static func _pipe_wall_hut() -> StructureKit.Piece:
	var p := StructureKit.define(&"pipe_wall_hut", Vector2(4.0, 3.0), Vector2(2.0, 2.0), Vector2(1.3, 1.3))
	p.lattice = true
	p.apron = 7.0
	p.drift_reach = 3.0
	p.drift = PackedFloat32Array([0.15, 0.35, 0.5])
	p.survey = Vector2(1.4, 20.0)
	p.age = Vector2(0.3, 0.55)
	p.variants = PackedColorArray(HOUSES)
	p.rooms.append(StructureKit.room(Vector2(-3.0, -2.0), Vector2(3.0, 2.0)))
	p.doors.append([Vector2(-1.5, 3.0), Vector2(0.0, 1.0), 1.4])
	var top := 2.2
	StructureKit.wall(p, true, 2.0, 3.0, -4.0, 4.0, -0.6, top, [-1.5], "")
	StructureKit.wall(p, true, -3.0, -2.0, -4.0, 4.0, -0.6, top, [], "")
	StructureKit.wall(p, false, -4.0, -3.0, -2.0, 2.0, -0.6, top, [], "")
	StructureKit.wall(p, false, 3.0, 4.0, -2.0, 2.0, -0.6, top, [], "")
	StructureKit.box(p, Vector3(-3.0, -0.3, -2.0), Vector3(3.0, 0.0, 2.0), "stone_dark")
	# Hull plate over the back of it; the front lies open.
	StructureKit.box(p, Vector3(-4.0, top, -3.0), Vector3(4.0, top + 0.14, 0.6), "hull")
	# The machine the house kept running, in the back corner.
	StructureKit.box(p, Vector3(1.6, 0.0, -2.0), Vector3(3.0, 1.1, -1.2), "")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-2.0, 0.0, -1.0), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.6, 0.0, 1.0), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(2.3, 1.1, -1.6), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-2.6, 0.3, -1.7), &"cache", 0.5))
	p.tour = PackedVector2Array([Vector2(-1.5, 8.0), Vector2(-1.5, 3.5), Vector2(-1.5, 0.5), Vector2(1.0, 0.8),
		Vector2(-1.5, 0.5), Vector2(-1.5, 3.5), Vector2(-1.5, 8.0)])
	p.approach = Vector2(-1.5, 12.0)
	p.look = _hut_look
	# Its hull-plate roof, and the brass where the pipe's lengths meet.
	StructureKit.glint(p, Vector3(0.5, 2.36, -1.2), Vector3(0.0, 1.0, 0.25), 4.0)
	StructureKit.glint(p, Vector3(1.0, 1.4, 3.05), Vector3(0.0, 0.3, 1.0), 5.0)
	return p


static func _hut_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	var house: Paint.Coat = c.house
	StructureKit.draw_boxes(b, p, state, c, 0.03)
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
		crest(b, Vector3(0.4, 1.35, 3.01), house, c)
	# The machine: a housing with a copper coil and a brass valve wheel.
	if StructureKit.shows(p, state, 1.1):
		b.box(Vector3(1.4, 1.1, 0.8), Vector3(2.3, 0.55, -1.6), c.pipe, 0.08)
		b.drum(0.3, 0.6, Vector3(2.3, 0.75, -1.15), c.copper, Basis(Vector3.RIGHT, PI * 0.5), 12)
		b.ring(0.16, 0.22, Vector3(1.75, 1.18, -1.6), c.brass, Basis.IDENTITY, 8)


# --- The cistern: a stone pit where a colonial water line ended. ---

static func _cistern() -> StructureKit.Piece:
	var p := StructureKit.define(&"cistern", Vector2(4.0, 4.0), Vector2(0.5, 0.5), Vector2(0.25, -1.0))
	p.lattice = true
	p.apron = 6.0
	p.drift_reach = 2.5
	p.drift = PackedFloat32Array([0.1, 0.3, 0.4])
	p.survey = Vector2(1.2, 20.0)
	p.age = Vector2(0.3, 0.55)
	p.variants = PackedColorArray(HOUSES)
	# Silted from its gap: the sand drifted in slopes down to the stone floor.
	p.rooms.append(StructureKit.room(Vector2(-3.0, -3.0), Vector2(3.0, 3.0), -2.0, Vector3(1.0, -1.5, 3.0)))
	p.doors.append([Vector2(0.0, 4.0), Vector2(0.0, 1.0), 2.0])
	var low := -2.4
	var top := 0.6
	StructureKit.wall(p, true, 3.0, 4.0, -4.0, 4.0, low, top, [0.0], "", 2.0, 9.0)
	StructureKit.wall(p, true, -4.0, -3.0, -4.0, 4.0, low, top, [], "")
	StructureKit.wall(p, false, -4.0, -3.0, -3.0, 3.0, low, top, [], "")
	StructureKit.wall(p, false, 3.0, 4.0, -3.0, 3.0, low, top, [], "")
	StructureKit.box(p, Vector3(-3.0, -2.3, -3.0), Vector3(3.0, -2.0, 3.0), "stone_dark")
	# The colonial line's end, where it comes through the back wall.
	StructureKit.box(p, Vector3(0.68, -0.92, -3.0), Vector3(1.32, -0.28, -2.5), "")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-1.5, -2.0, -2.3), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.5, -2.0, -2.3), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-2.3, -2.0, -2.2), &"bed"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(2.0, -1.2, -2.95), &"cache", 0.5))
	p.tour = PackedVector2Array([Vector2(0.0, 9.0), Vector2(0.0, 4.5), Vector2(0.0, 1.5), Vector2(0.0, -2.2),
		Vector2(0.0, 1.5), Vector2(0.0, 4.5), Vector2(0.0, 9.0)])
	p.approach = Vector2(0.0, 12.0)
	p.look = _cistern_look
	return p


static func _cistern_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
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


# --- The low stone wall: a field plot's corner, a gate in it. ---

static func _low_wall() -> StructureKit.Piece:
	var p := StructureKit.define(&"low_wall", Vector2(5.0, 1.9), Vector2(1.0, 1.0), Vector2(0.6, 0.6))
	p.apron = 3.5
	p.drift_reach = 1.5
	p.drift = PackedFloat32Array([0.1, 0.2, 0.3])
	p.survey = Vector2(0.8, 22.0)
	p.age = Vector2(0.3, 0.55)
	p.variants = PackedColorArray(HOUSES)
	p.wall = 0.7
	p.solids = [[Vector2(-5.0, -1.9), Vector2(0.6, -1.2)], [Vector2(2.2, -1.9), Vector2(5.0, -1.2)],
		[Vector2(-5.0, -1.2), Vector2(-4.3, 1.9)]]
	p.doors.append([Vector2(1.4, -1.2), Vector2(0.0, 1.0), 1.6])
	p.doors.append([Vector2(1.4, -1.9), Vector2(0.0, -1.0), 1.6])
	StructureKit.box(p, Vector3(-5.0, -0.4, -1.9), Vector3(0.3, 1.1, -1.2), "")
	StructureKit.box(p, Vector3(2.5, -0.4, -1.9), Vector3(5.0, 1.1, -1.2), "")
	StructureKit.box(p, Vector3(-5.0, -0.4, -1.2), Vector3(-4.3, 1.1, 1.9), "")
	# The gateposts, each a length of colonial pipe with a flared brass cap.
	StructureKit.box(p, Vector3(0.3, -0.4, -1.72), Vector3(0.6, 1.55, -1.38), "")
	StructureKit.box(p, Vector3(2.2, -0.4, -1.72), Vector3(2.5, 1.55, -1.38), "")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-4.0, 0.1, 1.5), &"cache", 0.6))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-2.5, 0.0, 0.3), &"bed"))
	p.tour = PackedVector2Array([Vector2(1.4, 4.0), Vector2(1.4, -1.55), Vector2(1.4, -5.0), Vector2(1.4, -1.55),
		Vector2(1.4, 4.0)])
	p.approach = Vector2(1.4, 8.0)
	p.look = _low_wall_look
	return p


static func _low_wall_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
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
	crest(b, Vector3(0.45, 0.75, -1.38), c.house, c)
	# Stones fallen from it, half in the sand.
	if StructureKit.shows(p, state, 0.2):
		b.box(Vector3(0.6, 0.4, 0.5), Vector3(-2.2, 0.05, -0.75), c.stone, 0.07, Basis(Vector3.UP, 0.4))
		b.box(Vector3(0.5, 0.35, 0.55), Vector3(3.6, 0.0, -0.8), c.stone_dark, 0.07, Basis(Vector3.UP, -0.3))


## A house's crest on a face turned to +Z: a shield in its colour on a brass
## plate, a bar across it.
static func crest(b: Paint.Pieces, at: Vector3, house: Paint.Coat, c: Dictionary) -> void:
	b.box(Vector3(0.42, 0.5, 0.03), at, c.brass, 0.02)
	b.box(Vector3(0.32, 0.38, 0.03), at + Vector3(0.0, 0.02, 0.012), house, 0.03)
	b.box(Vector3(0.32, 0.06, 0.03), at + Vector3(0.0, 0.05, 0.02), c.brass, 0.01)
