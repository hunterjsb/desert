class_name SkimmerKit
extends RefCounted
## The skimmer era's pieces (part 4): fuel bladders and deserters' dugouts;
## its wrecks, the skimmer hull and the tithe hauler, are WreckKit's. A short era with little architecture of its own, light, cheap
## and fragile, put together in a hurry: gunmetal and olive plate, panels
## that don't match, welds, hazard stripes, a crew's patch painted by hand.
## Shallow and lying at an angle: exposed and reburied fast. Loot it now.

const GUNMETAL := Color(0.3, 0.32, 0.31)
const OLIVE := Color(0.33, 0.35, 0.24)
const SCRAP := Color(0.44, 0.38, 0.32)
const PLATE_RED := Color(0.45, 0.2, 0.14)
const RUBBER := Color(0.12, 0.13, 0.11)
const CANVAS := Color(0.55, 0.49, 0.36)
const TAPE := Color(0.62, 0.57, 0.45)
const GLASS := Color(0.07, 0.1, 0.11)

static var _coats := {}


static func pieces() -> Array[StructureKit.Piece]:
	return [WreckKit.wreck_hull(), _fuel_bladder(), _dugout()]


static func coats() -> Dictionary:
	if _coats.is_empty():
		_coats = {"hull": Paint.coat(GUNMETAL, 1.0, 0.5, 0.55), "olive": Paint.coat(OLIVE, 1.0, 0.4, 0.6),
			"scrap": Paint.coat(SCRAP, 1.0, 0.6, 0.6), "red": Paint.coat(PLATE_RED, 1.0, 0.5, 0.6),
			"rubber": Paint.coat(RUBBER, 0.2, 0.0, 0.7, 0.7), "canvas": Paint.coat(CANVAS, 0.2, 0.0, 0.95),
			"tape": Paint.coat(TAPE, 0.2, 0.0, 0.8, 0.6), "glass": Paint.coat(GLASS, 0.3, 0.2, 0.1, 0.4),
			"yellow": Paint.coat(Paint.YELLOW, 1.0, 0.3, 0.55), "black": Paint.coat(Paint.BLACK, 1.0, 0.3, 0.6),
			"steel": Paint.coat(Paint.STEEL, 0.6, 0.8, 0.45)}
	return _coats


# --- The fuel bladder: a soft tank slumped on a scrap pallet. ---

static func _fuel_bladder() -> StructureKit.Piece:
	var p := StructureKit.define(&"fuel_bladder", Vector2(2.75, 1.7), Vector2(0.9, 0.9), Vector2(0.55, 0.55))
	p.apron = 3.5
	p.drift_reach = 1.5
	p.drift = PackedFloat32Array([0.15, 0.25, 0.3])
	p.survey = Vector2(0.8, 22.0)
	p.age = Vector2(0.75, 1.0)
	p.marks = 2
	p.slide_m = 10.0
	# Slumped to one side, that side's edge in the sand.
	p.lean = 0.5
	p.lean_axis = Vector3.LEFT
	p.lean_pivot = Vector3(0.0, 0.12, 1.6)
	StructureKit.box(p, Vector3(-2.6, -0.3, -1.6), Vector3(2.6, 0.12, 1.6), "scrap")
	StructureKit.box(p, Vector3(-2.35, 0.12, -1.4), Vector3(2.35, 1.25, 1.4), "")
	StructureKit.box(p, Vector3(2.35, 0.35, -0.2), Vector3(2.75, 0.8, 0.2), "steel")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(2.75, 0.6, 0.0), &"cache"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-2.3, 0.12, 1.3), &"floor"))
	p.approach = Vector2(0.0, 7.0)
	p.look = _bladder_look
	return p


static func _bladder_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.03)
	# The bag itself, flattened by its own weight, and the tape over its leaks.
	b.ball(1.0, Vector3(0.0, 0.66, 0.0), c.rubber, Vector3(2.4, 0.58, 1.42))
	for patch: Array in [[Vector3(-0.9, 1.22, 0.3), 0.5], [Vector3(1.1, 1.12, -0.6), 0.3], [Vector3(0.2, 0.9, 1.25), 0.4]]:
		b.box(Vector3(patch[1], 0.03, patch[1] * 0.6), patch[0], c.tape, 0.005)
	# Straps over it to the pallet, a valve with its wheel, the crew's patch.
	for u: float in [-1.4, 0.0, 1.4]:
		b.box(Vector3(0.1, 0.03, 2.9), Vector3(u, 1.26, 0.0), c.olive, 0.005)
	b.ring(0.12, 0.17, Vector3(2.8, 0.58, 0.0), c.red, Basis(Vector3.FORWARD, PI * 0.5), 8)
	b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(0.0, 0.25, 1.62), 0.7)
	b.box(Vector3(1.0, 0.3, 0.04), Vector3(0.0, 0.0, 1.6), c.scrap, 0.01)


# --- The dugout: a deserters' pit, sandbagged, roofed with scrap. ---

static func _dugout() -> StructureKit.Piece:
	var p := StructureKit.define(&"dugout", Vector2(3.0, 4.0), Vector2(0.5, 0.5), Vector2(0.2, -0.7))
	p.lattice = true
	p.apron = 6.0
	p.drift_reach = 2.5
	p.drift = PackedFloat32Array([0.15, 0.3, 0.4])
	p.survey = Vector2(1.2, 20.0)
	p.age = Vector2(0.75, 1.0)
	p.marks = 2
	# Sand drifted in down its way in, to the boards of its floor.
	p.rooms.append(StructureKit.room(Vector2(-2.0, -3.0), Vector2(2.0, 3.0), -1.4, Vector3(1.0, 0.0, 3.0)))
	p.doors.append([Vector2(0.0, 4.0), Vector2(0.0, 1.0), 1.4])
	var low := -1.8
	var top := 0.8
	StructureKit.wall(p, true, 3.0, 4.0, -3.0, 3.0, low, top, [0.0], "", 1.4, 9.0)
	StructureKit.wall(p, true, -4.0, -3.0, -3.0, 3.0, low, top, [], "")
	StructureKit.wall(p, false, -3.0, -2.0, -3.0, 3.0, low, top, [], "")
	StructureKit.wall(p, false, 2.0, 3.0, -3.0, 3.0, low, top, [], "")
	StructureKit.box(p, Vector3(-2.0, -1.7, -3.0), Vector3(2.0, -1.4, 3.0), "scrap")
	StructureKit.box(p, Vector3(-3.0, top, -4.0), Vector3(3.0, top + 0.12, 0.2), "")
	# An ammunition crate in the back corner.
	StructureKit.box(p, Vector3(-2.0, -1.4, -3.0), Vector3(-1.1, -0.8, -2.3), "olive")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-1.2, -1.4, -1.4), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.2, -1.4, -2.3), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-1.55, -0.8, -2.65), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.6, -1.0, -2.95), &"cache", 0.5))
	p.tour = PackedVector2Array([Vector2(0.0, 9.0), Vector2(0.0, 4.5), Vector2(0.0, 2.0), Vector2(0.4, -1.8),
		Vector2(0.0, 2.0), Vector2(0.0, 4.5), Vector2(0.0, 9.0)])
	p.approach = Vector2(0.0, 12.0)
	p.look = _dugout_look
	return p


static func _dugout_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.03)
	# Sandbags in rows round the rim and down the pit, the rows offset.
	# Each row with the point of the pit beside it, whose sand it shows over.
	var rows := [[Vector2(-3.0, 3.5), Vector2(-0.7, 3.5), Vector2(-1.5, 2.5)],
		[Vector2(0.7, 3.5), Vector2(3.0, 3.5), Vector2(1.5, 2.5)],
		[Vector2(-3.0, -3.5), Vector2(3.0, -3.5), Vector2(0.0, -2.5)],
		[Vector2(-2.5, -3.0), Vector2(-2.5, 3.0), Vector2(-1.5, -1.0)],
		[Vector2(2.5, -3.0), Vector2(2.5, 3.0), Vector2(1.5, -1.0)]]
	for row: Array in rows:
		var a: Vector2 = row[0]
		var e: Vector2 = row[1]
		var long_u := absf(e.x - a.x) > absf(e.y - a.y)
		for course in 7:
			var y := -1.75 + course * 0.37
			if not StructureKit.shows(p, state, y + 0.37, row[2]):
				continue
			var span := (e - a).length()
			var count := maxi(1, roundi(span / 0.7))
			for k in count:
				var t := (k + (0.5 if course % 2 == 0 else 0.25)) / count
				if t > 1.0:
					continue
				var at := a.lerp(e, minf(t, 1.0))
				var size := Vector3(span / count - 0.03, 0.34, 0.95) if long_u else Vector3(0.95, 0.34, span / count - 0.03)
				b.box(size, Vector3(at.x, y + 0.18, at.y), c.canvas, 0.12)
	# The roof: scrap plates laid over, one gone askew, the crew's patch on it.
	if StructureKit.shows(p, state, 0.95):
		b.box(Vector3(3.1, 0.06, 4.3), Vector3(-1.5, 0.84, -1.9), c.scrap, 0.01)
		b.box(Vector3(3.0, 0.06, 4.0), Vector3(1.5, 0.86, -1.95), c.red, 0.01, Basis(Vector3.FORWARD, 0.06))
		b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(1.5, 0.9, -1.0), 0.9, Basis(Vector3.RIGHT, -PI * 0.5))
		b.box(Vector3(1.0, 0.03, 0.8), Vector3(1.5, 0.9, -1.0), c.olive, 0.005)
