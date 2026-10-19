class_name NomadKit
extends RefCounted
## The nomads' own (the chassis spec, "Nomad gear"): the moon is presumed
## empty, and nobody's ever home. A camp of theirs is kept, never ruined:
## a windbreak of cloth on posts against the wind, a sun shade over their
## bedrolls, a fire ring with its ashes still warm, a water cache, a table
## of gear, and the rig they sail on, kept up and ready, all of it any era's
## and all of it lootable; their tracks lead off across the sand. They've
## always just left. Their wrecked rigs are WreckKit's.

## The rigs a camp keeps, as Rig steps: a deck two by two on skates, its mast
## and sail on its front piece, a streamer up the mast, its ballast in a
## frame; or the yacht, floating on its trays, a keel under it and a helm
## seat aft, a crow's nest on its mast's head.
const MAST := [&"stick", Vector2i(0, 0), &"top", Vector2.ZERO, 180.0, [&"mast", [&"sail"]], &"mast"]
const RIGS := {
	&"runner": [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)],
		[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"skates"],
		[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"skates"],
		[&"stick", Vector2i(0, 1), &"bottom", Vector2.ZERO, 0.0, &"skates"],
		[&"stick", Vector2i(1, 1), &"bottom", Vector2.ZERO, 0.0, &"skates"],
		MAST,
		[&"up", &"mast", &"front", Vector2(0.0, 1.2), 0.0, &"streamer"],
		[&"frame", Vector2i(0, 1), 0],
		[&"stick", Vector2i(0, 1), &"top", Vector2(-0.25, 0.0), 0.0, &"big_battery"],
		[&"stick", Vector2i(0, 1), &"top", Vector2(0.2, 0.0), 0.0, &"battery"],
		[&"stick", Vector2i(1, 1), &"top", Vector2(0.0, 0.15), 0.0, &"bedroll"],
		[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.0), 0.0, &"coil"],
		[&"hook", Vector2i(0, 0), Vector2i(0, -1)]],
	&"yacht": [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(2, 0)], [&"piece", Vector2i(0, 1)],
		[&"piece", Vector2i(1, 1)], [&"piece", Vector2i(2, 1)],
		[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(2, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(0, 1), &"bottom", Vector2(0.0, 0.25), 0.0, &"hover_tray"],
		[&"stick", Vector2i(1, 1), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i(2, 1), &"bottom", Vector2.ZERO, 0.0, &"keel"],
		MAST,
		[&"up", &"mast", MASTHEAD, Vector2.ZERO, 0.0, &"crows_nest"],
		[&"up", &"mast", &"front", Vector2(0.0, 0.6), 0.0, &"streamer"],
		[&"stick", Vector2i(1, 1), &"top", Vector2.ZERO, 180.0, &"helm_seat"],
		[&"frame", Vector2i(0, 1), 0],
		[&"stick", Vector2i(0, 1), &"top", Vector2(-0.25, 0.0), 0.0, &"big_battery"],
		[&"stick", Vector2i(0, 1), &"top", Vector2(0.0, 0.0), 0.0, &"battery"],
		[&"stick", Vector2i(0, 1), &"top", Vector2(0.25, 0.0), 0.0, &"big_battery"],
		[&"stick", Vector2i(2, 0), &"top", Vector2(0.0, 0.1), 0.0, &"bedroll"]],
}
const MASTHEAD := &"head"

static var _coats := {}


static func pieces() -> Array[StructureKit.Piece]:
	return [_camp()]


static func coats() -> Dictionary:
	if _coats.is_empty():
		_coats.merge(NomadLooks.coats())
		_coats["stone"] = Paint.coat(Color(0.5, 0.42, 0.34), 0.6, 0.0, 0.95, 1.2)
		_coats["ash"] = Paint.coat(Color(0.2, 0.19, 0.18), 0.2, 0.0, 1.0, 0.4)
		_coats["ember"] = Paint.coat(Color(1.0, 0.36, 0.08), 0.0, 0.0, 0.6, 0.0, 3.0)
		_coats["clay"] = Paint.coat(Color(0.62, 0.38, 0.24), 0.8, 0.0, 0.9)
		_coats["teal"] = Paint.coat(Paint.TEAL, 1.0, 0.3, 0.5)
		_coats["rail"] = Paint.coat(Paint.GUNMETAL, 1.0, 0.5, 0.5)
		_coats["track"] = Paint.coat(Color(0.5, 0.38, 0.26), 0.0, 0.0, 1.0, 0.0)
	return _coats


# --- The camp: kept, and just left. ---

static func _camp() -> StructureKit.Piece:
	var p := StructureKit.define(&"nomad_camp", Vector2(7.0, 6.0), Vector2.ZERO, Vector2.ZERO)
	p.apron = 4.0
	p.drift_reach = 1.0
	p.drift = PackedFloat32Array([0.0, 0.0, 0.0])
	p.survey = Vector2(0.8, 16.0)
	p.age = Vector2(0.2, 0.45)
	p.marks = 1
	p.slide = Vector2(1.0, 0.0)
	p.slide_m = 14.0
	# The windbreak along its upwind side: cloth between saltbush posts.
	for u: float in [-1.0, 0.6, 2.2, 3.8, 5.4]:
		StructureKit.box(p, Vector3(u - 0.05, 0.0, 3.5), Vector3(u + 0.05, 1.6, 3.6), "wood")
	for k in 4:
		var u := -1.0 + k * 1.6
		StructureKit.box(p, Vector3(u + 0.05, 0.1, 3.53), Vector3(u + 1.55, 1.45, 3.57), "ochre" if k % 2 == 0 else "indigo")
	# The sun shade over where they slept, a crate of gear under it.
	for corner: Vector2 in [Vector2(0.8, -1.8), Vector2(3.6, -1.8), Vector2(0.8, -3.8), Vector2(3.6, -3.8)]:
		StructureKit.box(p, Vector3(corner.x - 0.04, 0.0, corner.y - 0.04), Vector3(corner.x + 0.04, 2.1, corner.y + 0.04), "wood")
	StructureKit.box(p, Vector3(0.7, 2.1, -3.9), Vector3(3.7, 2.13, -1.7), "rust")
	StructureKit.box(p, Vector3(1.9, 0.0, -3.7), Vector3(2.5, 0.45, -3.3), "wood")
	# The fire ring, its stones round the ashes.
	for k in 8:
		var a := TAU * k / 8.0
		var at := Vector2(2.0, 0.6) + Vector2(cos(a), sin(a)) * 0.55
		StructureKit.box(p, Vector3(at.x - 0.11, 0.0, at.y - 0.11), Vector3(at.x + 0.11, 0.2, at.y + 0.11), "stone")
	# A chassis piece on two stones for a table, its gear laid out on it.
	StructureKit.box(p, Vector3(4.6, 0.0, -0.1), Vector3(4.8, 0.25, 1.1), "stone")
	StructureKit.box(p, Vector3(5.6, 0.0, -0.1), Vector3(5.8, 0.25, 1.1), "stone")
	StructureKit.box(p, Vector3(4.5, 0.25, 0.0), Vector3(5.9, 0.37, 1.0), "teal")
	# Their water cache, a lid of plate on a stone-lined pit, and a saltbush
	# they keep in a pot.
	StructureKit.box(p, Vector3(5.6, 0.0, 2.3), Vector3(6.4, 0.12, 3.0), "rail")
	StructureKit.box(p, Vector3(3.9, 0.0, 2.3), Vector3(4.3, 0.36, 2.7), "clay")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-3.4, 0.0, -0.4), SiteLoot.RIG))
	p.sockets[-1].turn = 0.0
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.4, 0.0, -2.8), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(3.0, 0.0, -2.8), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.4, 0.0, 2.4), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(5.6, 0.0, -2.4), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-0.6, 0.0, -3.4), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(4.9, 0.37, 0.3), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(5.5, 0.37, 0.7), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(2.2, 0.45, -3.5), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(6.0, 0.12, 2.65), &"cache"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(2.0, 0.0, 1.9), &"cache"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(4.1, 0.36, 2.5), &"bed"))
	p.tour = PackedVector2Array([Vector2(9.0, -1.0), Vector2(4.2, -1.0), Vector2(9.0, -1.0)])
	p.approach = Vector2(10.0, -6.0)
	p.look = _camp_look
	# Its shade and windbreak over the dunes, and the mirror shards hung at
	# its shade the sun catches.
	var c := coats()
	StructureKit.far_box(p, Vector3(0.7, 2.1, -3.9), Vector3(3.7, 2.13, -1.7), c.rust)
	StructureKit.far_box(p, Vector3(-1.05, 0.0, 3.5), Vector3(5.45, 1.6, 3.6), c.ochre, 0.8)
	for k in 3:
		var a := TAU * k / 3.0 + 0.3
		StructureKit.glint(p, Vector3(3.6 + cos(a) * 0.1, 1.7, -1.8 + sin(a) * 0.1), Vector3(cos(a), 0.4, sin(a)), 8.0)
	return p


static func _camp_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.01)
	# Cord lashing the windbreak's cloth to its posts.
	for u: float in [-1.0, 0.6, 2.2, 3.8, 5.4]:
		for y: float in [0.4, 1.2]:
			b.drum(0.07, 0.05, Vector3(u, y, 3.55), c.cord, Basis.IDENTITY, 8)
	# The shade's cloth sagging between its poles, its edge fringed.
	for k in 6:
		b.box(Vector3(0.02, 0.18, 0.02), Vector3(0.9 + k * 0.55, 2.0, -1.72), c.ochre, 0.0)
	# The fire's ashes, its embers still glowing, half-burnt saltbush across it.
	b.drum(0.42, 0.04, Vector3(2.0, 0.02, 0.6), c.ash, Basis.IDENTITY, 12)
	for k in 5:
		var a := TAU * k / 5.0 + 0.7
		b.box(Vector3(0.06, 0.03, 0.06), Vector3(2.0 + cos(a) * 0.18, 0.05, 0.6 + sin(a) * 0.15), c.ember, 0.0)
	for k in 3:
		var a := PI * k / 3.0
		b.box(Vector3(0.6, 0.05, 0.05), Vector3(2.0, 0.07, 0.6), c.wood, 0.01, Basis(Vector3.UP, a))
	# A kettle on the stones, a bone-handled ladle.
	b.drum(0.1, 0.16, Vector3(2.5, 0.28, 0.6), Paint.coat(Paint.GUNMETAL, 1.2, 0.5, 0.6), Basis.IDENTITY, 10)
	b.box(Vector3(0.3, 0.02, 0.03), Vector3(1.7, 0.21, 1.05), c.bone, 0.004, Basis(Vector3.UP, 0.4))
	# Mirror shards strung at the shade's corner, catching the sun.
	StructureKit.rod(b, Vector3(3.6, 2.1, -1.8), Vector3(3.6, 1.55, -1.8), 0.006, c.cord)
	for k in 3:
		b.box(Vector3(0.08, 0.1, 0.008), Vector3(3.6, 1.62 + k * 0.12, -1.8), Paint.coat(Paint.STEEL, 0.2, 0.95, 0.1), 0.0,
			Basis(Vector3.UP, k * 1.1))
	# Their tracks, leaving: boards' runs and footprints off downwind of the
	# camp, the sand not yet over them.
	for k in 8:
		var v := -4.2 - k * 0.7
		var u := -1.2 + 0.25 * sin(k * 0.7)
		b.box(Vector3(0.12, 0.004, 0.26), Vector3(u + (0.14 if k % 2 == 0 else -0.14), 0.002, v), c.track, 0.0)
	for side in [-1.0, 1.0]:
		b.box(Vector3(0.05, 0.004, 7.5), Vector3(-3.4 + side * 0.4, 0.002, -5.6), c.track, 0.0)
