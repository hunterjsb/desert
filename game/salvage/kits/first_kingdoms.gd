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
			"brass": Paint.coat(BRASS, 0.0, 0.9, 0.32, 0.6), "copper": Paint.coat(Paint.COPPER, 0.0, 0.85, 0.4, 0.6),
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
	p.look = WorldLooks.site
	# Its hull-plate roof, and the brass where the pipe's lengths meet.
	StructureKit.glint(p, Vector3(0.5, 2.36, -1.2), Vector3(0.0, 1.0, 0.25), 4.0)
	StructureKit.glint(p, Vector3(1.0, 1.4, 3.05), Vector3(0.0, 0.3, 1.0), 5.0)
	return p


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
	p.look = WorldLooks.site
	return p


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
	p.look = WorldLooks.site
	return p


## A house's crest on a face turned to +Z: a shield in its colour on a brass
## plate, a bar across it.
static func crest(b: Paint.Pieces, at: Vector3, house: Paint.Coat, c: Dictionary) -> void:
	b.box(Vector3(0.42, 0.5, 0.03), at, c.brass, 0.02)
	b.box(Vector3(0.32, 0.38, 0.03), at + Vector3(0.0, 0.02, 0.012), house, 0.03)
	b.box(Vector3(0.32, 0.06, 0.03), at + Vector3(0.0, 0.05, 0.02), c.brass, 0.01)
