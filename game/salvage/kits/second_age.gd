class_name SecondAgeKit
extends RefCounted
## The second age's pieces (part 4): wayshrines on the pilgrim roads,
## watchtowers, house ruins. Kingdoms dying of thirst built in what they could
## make: mud render and lime wash, fired clay, saltbush wood, fern cord, a
## round ceramic cap on a square housing; bone, sand, rust and clay, and the
## deep water-blue glaze only on what the Cistern touched (part 5). Shallowest
## of the eras: most often exposed, and towers stand out of the dunes.

const RENDER := Color(0.71, 0.6, 0.46)
const LIME := Color(0.82, 0.78, 0.68)
const CLAY := Color(0.6, 0.38, 0.26)
const EARTH := Color(0.42, 0.35, 0.28)
const WOOD := Color(0.47, 0.41, 0.33)
const CORD := Color(0.58, 0.47, 0.31)
const DAUB := Color(0.5, 0.2, 0.1)
const GLAZE := Color(0.12, 0.3, 0.5)
const WATER := Color(0.05, 0.12, 0.16)

## The house ruin's bench, plan m, clear of the way through the back room.
const BENCH := AABB(Vector3(6.0, 0.0, -1.1), Vector3(2.0, 0.45, 0.9))

static var _coats := {}


static func pieces() -> Array[StructureKit.Piece]:
	return [_house_ruin(), _wayshrine(), _watchtower()]


static func coats() -> Dictionary:
	if _coats.is_empty():
		_coats = {"render": Paint.coat(RENDER, 0.3, 0.0, 0.92), "lime": Paint.coat(LIME, 0.35, 0.0, 0.88),
			"clay": Paint.coat(CLAY, 0.3, 0.0, 0.85), "floor": Paint.coat(EARTH, 0.1, 0.0, 0.95),
			"wood": Paint.coat(WOOD, 0.2, 0.0, 0.8, 0.8), "cord": Paint.coat(CORD, 0.1, 0.0, 0.9, 0.5),
			"daub": Paint.coat(DAUB, 0.5, 0.0, 0.9, 0.8), "glaze": Paint.coat(GLAZE, 0.25, 0.0, 0.25, 0.4),
			"bone": Paint.coat(LIME, 0.2, 0.0, 0.3, 0.6), "water": Paint.coat(WATER, 0.0, 0.0, 0.1, 0.1)}
	return _coats


# --- The house ruin: today's three-room ruin, now where history put it. ---

static func _house_ruin() -> StructureKit.Piece:
	var p := StructureKit.define(&"house_ruin", Vector2(Ruin.HALF), Vector2(2.6, 2.6), Vector2(1.6, 1.6))
	p.builds = Ruin
	p.lattice = true
	p.apron = Ruin.APRON
	p.drift_reach = Ruin.DRIFT_REACH
	p.drift = PackedFloat32Array([0.2, 0.45, Ruin.DRIFT])
	p.survey = Vector2(3.0, 20.0)
	p.age = Vector2(0.45, 0.8)
	var f := Vector2(Ruin.HALF)
	var inner := f - Vector2.ONE * Ruin.WALL
	p.rooms.append(StructureKit.room(-inner, inner))
	for door: Array in Ruin.DOORS:
		p.doors.append([door[0], door[1], Ruin.DOOR_WIDTH])
	StructureKit.box(p, Vector3(-f.x, -Ruin.SLAB, -f.y), Vector3(f.x, 0.0, f.y), "floor")
	var low := -Ruin.FOOT
	var high := Ruin.HEIGHT
	StructureKit.wall(p, true, inner.y, f.y, -f.x, f.x, low, high, [Ruin.DOORS[0][0].x], "render")
	StructureKit.wall(p, true, -f.y, -inner.y, -f.x, f.x, low, high, [Ruin.DOORS[1][0].x], "render")
	StructureKit.wall(p, false, -f.x, -inner.x, -inner.y, inner.y, low, high, [], "render")
	StructureKit.wall(p, false, inner.x, f.x, -inner.y, inner.y, low, high, [], "render")
	StructureKit.wall(p, false, 1.8, 2.2, -inner.y, inner.y, low, high, [-2.5, 2.5], "render")
	StructureKit.wall(p, true, -0.2, 0.2, 2.2, inner.x, low, high, [5.0], "render")
	StructureKit.box(p, Vector3(1.8, high, -f.y), Vector3(f.x, high + Ruin.ROOF, f.y), "render")
	# A sleeping bench of saltbush wood in the back room, against its wall.
	StructureKit.bed(p, BENCH.position, BENCH.end, "wood")
	# The water jar on the front corner, solid where it stands out of the sand.
	StructureKit.box(p, Vector3(-f.x, high, f.y - 1.0), Vector3(-f.x + 1.0, high + 0.95, f.y), "")
	for k in Ruin.SPOTS.size():
		var spot: Vector2 = Ruin.SPOTS[k]
		p.sockets.append(StructureKit.SiteSocket.new(Vector3(spot.x, 0.0, spot.y), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(7.6, 0.4, -4.6), &"cache", 0.5))
	p.tour = PackedVector2Array(Ruin.TOUR)
	p.approach = Ruin.APPROACH
	p.look = _house_look
	return p


static func _house_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.06)
	var f := Vector2(Ruin.HALF)
	# Lime wash along the walls' tops, a centimetre proud of the render.
	if StructureKit.shows(p, state, Ruin.HEIGHT):
		for side in [-1.0, 1.0]:
			b.box(Vector3(f.x * 2.0, 0.28, 0.02), Vector3(0.0, Ruin.HEIGHT - 0.14, side * (f.y + 0.01)), c.lime, 0.005)
			b.box(Vector3(0.02, 0.28, f.y * 2.0), Vector3(side * (f.x + 0.01), Ruin.HEIGHT - 0.14, 0.0), c.lime, 0.005)
	# Saltbush beams over the doors and under the roof's edge, their ends out.
	for door: Array in Ruin.DOORS:
		var at: Vector2 = door[0]
		var out: Vector2 = door[1]
		for k in 3:
			var u := at.x + (k - 1) * 0.55
			b.box(Vector3(0.14, 0.14, Ruin.WALL + 0.5), Vector3(u, Ruin.DOOR_HEIGHT + 0.12, at.y - out.y * 0.5),
				c.wood, 0.02)
	var u := 2.4
	while u < f.x:
		for side in [-1.0, 1.0]:
			b.box(Vector3(0.13, 0.13, 0.32), Vector3(u, Ruin.HEIGHT + 0.12, side * (f.y + 0.1)), c.wood, 0.02)
		u += 0.9
	# The water jar, a round cap on a square house.
	var jar := Vector3(-f.x + 0.5, Ruin.HEIGHT, f.y - 0.5)
	if StructureKit.shows(p, state, Ruin.HEIGHT + 0.95):
		b.drum(0.36, 0.45, jar + Vector3(0.0, 0.22, 0.0), c.clay, Basis.IDENTITY, 12)
		b.ball(0.42, jar + Vector3(0.0, 0.58, 0.0), c.bone, Vector3(1.0, 0.85, 1.0))
		b.drum(0.16, 0.12, jar + Vector3(0.0, 0.95, 0.0), c.clay, Basis.IDENTITY, 10)
	# A dyed mat woven of fern cord on the bench.
	var mat := BENCH.get_center() + Vector3(0.0, BENCH.size.y * 0.5, 0.0)
	if StructureKit.shows(p, state, mat.y, Vector2(mat.x, mat.z)):
		b.box(Vector3(BENCH.size.x - 0.12, 0.04, BENCH.size.z - 0.12), mat + Vector3(0.0, 0.02, 0.0), c.daub, 0.01)
	# Tu, half risen over the horizon, daubed by the front door; charms on a
	# cord over it.
	if StructureKit.shows(p, state, 2.1):
		tu(b, Vector3(-6.2, 1.75, f.y + 0.012), Basis.IDENTITY, 0.36, c.daub)
	var door: Vector2 = Ruin.DOORS[0][0]
	if StructureKit.shows(p, state, Ruin.DOOR_HEIGHT):
		charms(b, Vector3(door.x - 0.85, Ruin.DOOR_HEIGHT - 0.04, f.y + 0.12),
			Vector3(door.x + 0.85, Ruin.DOOR_HEIGHT - 0.04, f.y + 0.12), 4, c)


# --- The wayshrine: a small Cistern shrine on the pilgrim roads. ---

static func _wayshrine() -> StructureKit.Piece:
	var p := StructureKit.define(&"wayshrine", Vector2(1.1, 0.8), Vector2(1.75, 1.75), Vector2(0.8, 0.8))
	p.apron = 4.0
	p.drift_reach = 1.5
	p.drift = PackedFloat32Array([0.15, 0.25, 0.35])
	p.survey = Vector2(0.9, 24.0)
	p.slide_m = 10.0
	p.age = Vector2(0.4, 0.7)
	StructureKit.box(p, Vector3(-1.1, -0.45, -0.8), Vector3(1.1, 0.45, 0.8), "")
	StructureKit.box(p, Vector3(-0.85, 0.45, -0.8), Vector3(0.85, 2.0, -0.35), "")
	StructureKit.box(p, Vector3(-0.5, 0.45, -0.3), Vector3(0.5, 0.8, 0.5), "")
	StructureKit.box(p, Vector3(-0.32, 2.0, -0.8), Vector3(0.74, 2.48, -0.35), "")
	# Offerings in the basin and the niche, and a cache in the plinth's side.
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.0, 0.8, 0.1), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.0, 0.9, -0.5), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.1, 0.15, 0.0), &"cache", 0.5))
	p.approach = Vector2(0.0, 5.0)
	p.look = _wayshrine_look
	# The water in its basin, and its glazed cap.
	StructureKit.glint(p, Vector3(0.0, 0.8, 0.1), Vector3(0.0, 1.0, 0.0), 3.0)
	StructureKit.glint(p, Vector3(0.6, 2.2, -0.4), Vector3(0.85, 0.4, 0.35), 5.0)
	StructureKit.glint(p, Vector3(-0.1, 2.2, -0.2), Vector3(-0.5, 0.4, 0.75), 5.0)
	return p


static func _wayshrine_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	# The plinth of fired brick, in courses.
	for k in 3:
		var y := -0.45 + k * 0.3
		if StructureKit.shows(p, state, y + 0.3):
			b.box(Vector3(2.2 - k * 0.04, 0.29, 1.6 - k * 0.04), Vector3(0.0, y + 0.15, 0.0), c.clay, 0.04)
	# The niche's housing, lime washed: back, cheeks, sill and lintel.
	b.box(Vector3(1.7, 1.55, 0.2), Vector3(0.0, 1.225, -0.7), c.lime, 0.04)
	for side in [-1.0, 1.0]:
		b.box(Vector3(0.3, 1.55, 0.27), Vector3(side * 0.7, 1.225, -0.475), c.lime, 0.04)
	b.box(Vector3(1.1, 0.45, 0.27), Vector3(0.0, 0.675, -0.475), c.lime, 0.03)
	b.box(Vector3(1.1, 0.42, 0.27), Vector3(0.0, 1.79, -0.475), c.lime, 0.03)
	# The round ceramic cap, off true on its square housing.
	b.ball(0.5, Vector3(0.21, 2.06, -0.58), c.bone, Vector3(1.0, 0.82, 0.92))
	b.drum(0.1, 0.18, Vector3(0.21, 2.5, -0.58), c.clay, Basis.IDENTITY, 8)
	# The basin, glazed the Cistern's blue, with water's dark in it.
	if StructureKit.shows(p, state, 0.8):
		b.drum(0.46, 0.34, Vector3(0.0, 0.62, 0.1), c.glaze, Basis.IDENTITY, 14)
		b.drum(0.38, 0.02, Vector3(0.0, 0.79, 0.1), c.water, Basis.IDENTITY, 14)
		# Offerings: two pots and a water vial.
		b.drum(0.07, 0.14, Vector3(0.62, 0.52, 0.45), c.clay, Basis.IDENTITY, 8)
		b.ball(0.06, Vector3(-0.66, 0.51, 0.4), c.glaze)
	b.drum(0.04, 0.16, Vector3(0.0, 0.98, -0.5), c.glaze, Basis.IDENTITY, 8)
	# A saltbush post at its side, cord wound round it and a tassel hanging.
	var post := Vector3(-1.0, 0.45, 0.55)
	if StructureKit.shows(p, state, 1.7):
		b.box(Vector3(0.08, 1.25, 0.08), post + Vector3(0.0, 0.62, 0.0), c.wood, 0.01)
		for k in 4:
			b.drum(0.052, 0.04, post + Vector3(0.0, 0.7 + k * 0.07, 0.0), c.cord, Basis.IDENTITY, 8)
		b.box(Vector3(0.025, 0.22, 0.025), post + Vector3(0.06, 1.05, 0.0), c.cord, 0.004)
		b.ball(0.035, post + Vector3(0.06, 0.92, 0.0), c.glaze)
	tu(b, Vector3(0.0, 1.32, -0.586), Basis.IDENTITY, 0.18, c.daub)


# --- The watchtower: tall, the most visible thing on a road. ---

static func _watchtower() -> StructureKit.Piece:
	var p := StructureKit.define(&"watchtower", Vector2(3.0, 3.0), Vector2(7.5, 7.5), Vector2(3.6, 3.6))
	p.lattice = true
	p.apron = 8.0
	p.drift_reach = 3.0
	p.drift = PackedFloat32Array([0.0, 0.4, 0.6])
	p.survey = Vector2(1.7, 20.0)
	p.age = Vector2(0.45, 0.8)
	p.rooms.append(StructureKit.room(Vector2(-2.0, -2.0), Vector2(2.0, 2.0)))
	p.doors.append([Vector2(0.0, 3.0), Vector2(0.0, 1.0), 1.4])
	var top := 7.2
	StructureKit.wall(p, true, 2.0, 3.0, -3.0, 3.0, -0.6, top, [0.0], "render")
	StructureKit.wall(p, true, -3.0, -2.0, -3.0, 3.0, -0.6, top, [], "render")
	StructureKit.wall(p, false, 2.0, 3.0, -2.0, 2.0, -0.6, top, [], "render")
	# The left wall with its window slit.
	StructureKit.box(p, Vector3(-3.0, -0.6, -2.0), Vector3(-2.0, 4.2, 2.0), "render")
	StructureKit.box(p, Vector3(-3.0, 4.2, -2.0), Vector3(-2.0, 5.0, -0.3), "render")
	StructureKit.box(p, Vector3(-3.0, 4.2, 0.3), Vector3(-2.0, 5.0, 2.0), "render")
	StructureKit.box(p, Vector3(-3.0, 5.0, -2.0), Vector3(-2.0, top, 2.0), "render")
	# The platform, and its parapet with a gap at the front.
	StructureKit.box(p, Vector3(-3.0, top, -3.0), Vector3(3.0, 7.5, 3.0), "wood")
	StructureKit.box(p, Vector3(-3.0, 7.5, 2.6), Vector3(-0.7, 8.5, 3.0), "lime")
	StructureKit.box(p, Vector3(0.7, 7.5, 2.6), Vector3(3.0, 8.7, 3.0), "lime")
	StructureKit.box(p, Vector3(-3.0, 7.5, -3.0), Vector3(3.0, 8.6, -2.6), "lime")
	StructureKit.box(p, Vector3(-3.0, 7.5, -2.6), Vector3(-2.6, 8.4, 2.6), "lime")
	StructureKit.box(p, Vector3(2.6, 7.5, -2.6), Vector3(3.0, 8.8, 2.6), "lime")
	# The turret on its back corner, solid.
	StructureKit.box(p, Vector3(1.2, 7.5, -2.8), Vector3(2.8, 9.5, -1.2), "")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-1.0, 0.0, -1.0), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.0, 0.0, 0.8), &"floor"))
	# The late wars' weapons cache, up on the platform.
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-1.8, 7.5, -1.8), &"cache"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.6, 0.3, -1.7), &"cache", 0.6))
	p.tour = PackedVector2Array([Vector2(0.0, 9.0), Vector2(0.0, 3.6), Vector2(0.0, 0.0), Vector2(0.0, 3.6),
		Vector2(0.0, 9.0)])
	p.approach = Vector2(0.0, 16.0)
	p.look = _watchtower_look
	# Its rendered walls limed high up, the platform's beams and the limed
	# parapet, the clay turret and its glazed dome.
	var c := coats()
	StructureKit.far_box(p, Vector3(-3.0, -0.6, -3.0), Vector3(3.0, 4.5, 3.0), c.render)
	StructureKit.far_box(p, Vector3(-3.0, 4.5, -3.0), Vector3(3.0, 7.0, 3.0), c.lime)
	StructureKit.far_box(p, Vector3(-3.1, 7.0, -3.1), Vector3(3.1, 7.5, 3.1), c.wood)
	StructureKit.far_box(p, Vector3(-3.0, 7.5, -3.0), Vector3(3.0, 8.5, 3.0), c.lime)
	StructureKit.far_box(p, Vector3(1.22, 7.5, -2.78), Vector3(2.78, 8.8, -1.22), c.clay)
	StructureKit.far_box(p, Vector3(1.25, 8.8, -2.75), Vector3(2.75, 9.45, -1.25), c.lime)
	StructureKit.glint(p, Vector3(2.7, 9.0, -1.7), Vector3(0.85, 0.4, 0.35), 5.0)
	StructureKit.glint(p, Vector3(1.6, 9.0, -1.3), Vector3(-0.5, 0.4, 0.75), 5.0)
	return p


static func _watchtower_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.07)
	# Lime wash high on the walls, over the render.
	for side in [-1.0, 1.0]:
		b.box(Vector3(6.0, 2.6, 0.02), Vector3(0.0, 5.8, side * 3.01), c.lime, 0.005)
	b.box(Vector3(0.02, 2.6, 6.0), Vector3(3.01, 5.8, 0.0), c.lime, 0.005)
	b.box(Vector3(0.02, 1.0, 6.0), Vector3(-3.01, 6.6, 0.0), c.lime, 0.005)
	# Beam ends under the platform, all round.
	for k in 4:
		var along := -2.25 + k * 1.5
		for side in [-1.0, 1.0]:
			b.box(Vector3(0.16, 0.16, 0.4), Vector3(along, 7.0, side * 3.15), c.wood, 0.02)
			b.box(Vector3(0.4, 0.16, 0.16), Vector3(side * 3.15, 7.0, along), c.wood, 0.02)
	# The turret: a clay drum under a glazed dome.
	b.drum(0.78, 1.3, Vector3(2.0, 8.15, -2.0), c.clay, Basis.IDENTITY, 14)
	b.ball(0.82, Vector3(2.0, 8.8, -2.0), c.bone, Vector3(1.0, 0.8, 1.0))
	b.drum(0.12, 0.25, Vector3(2.0, 9.45, -2.0), c.clay, Basis.IDENTITY, 8)
	# Charms down the front, and Tu over the door.
	charms(b, Vector3(-2.9, 8.3, 3.12), Vector3(-1.0, 8.3, 3.12), 3, c)
	if StructureKit.shows(p, state, 4.0):
		tu(b, Vector3(0.0, 3.3, 3.012), Basis.IDENTITY, 0.5, c.daub)


# --- Small things the second age hung on everything. ---

## Tu half risen over the horizon: a ring with a line through it, daubed on a
## face turned to `facing`'s +Z.
static func tu(b: Paint.Pieces, at: Vector3, facing: Basis, size: float, look: Paint.Coat) -> void:
	var flat := facing * Basis(Vector3.RIGHT, PI * 0.5)
	b.ring(size * 0.78, size, at, look, flat, 16)
	b.box(Vector3(size * 2.6, size * 0.16, 0.012), at - facing.y * size * 0.15, look, 0.002, facing)


## A cord between two points with `count` charms hanging from it: beads,
## glazed or clay, on short tails.
static func charms(b: Paint.Pieces, from: Vector3, to: Vector3, count: int, c: Dictionary) -> void:
	StructureKit.rod(b, from, to, 0.025, c.cord)
	for k in count:
		var at := from.lerp(to, (k + 0.5) / count)
		var tail := 0.12 + 0.07 * (k % 2)
		b.box(Vector3(0.016, tail, 0.016), at - Vector3(0.0, tail * 0.5, 0.0), c.cord, 0.003)
		b.ball(0.045, at - Vector3(0.0, tail + 0.03, 0.0), c.glaze if k % 2 == 0 else c.clay)
