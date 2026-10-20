class_name WreckKit
extends RefCounted
## The wrecks out in the sand, of every era, in one file since they share
## their scrapping (WreckPlan): each a big structure from the moon's past,
## lying where history put it, its plates welded over what's worth having,
## its holds packed with storm sand, its modules held fast inside, some with
## a hazard riding on them.
##
## - The skimmer hull: a He-3 scoop ship of the skimmer era down nose first,
##   its tail torn open, its cargo bay packed through it, a hatch over its
##   starboard pod into the charger bay.
## - The tithe hauler: a Provisional armoured hauler from the war, listing on
##   its skirts, a plated cargo door, a requisition locker behind a plated
##   door inside, a cab the storms filled through a breach in the roof.
## - The freight pod: a colonial consignment pod; the old RMC name is a
##   legacy contractor placeholder, not its settled installer or OEM. Its
##   front hold is packed full through its open hatch, its rear behind a plate.
## - The lifeboat: one of a Tilg freighter's boats, down on its skids, its
##   boarding hatch fused shut, its cabin sanded through a cracked viewport,
##   its battery room behind an access panel.
## - The hopper: a colonial suborbital hopper the Knights Requisitioner flew
##   on the crusade for Port Morgan, down on its belly, a wing broken off,
##   its troop bay packed through the lowered ramp.
## - The nomad rig: a nomads' sailing rig wrecked out in the wilds, five
##   pieces of three eras' chassis, its mast down beside its snapped post
##   with its sail furled on it, a cloth locker packed with sand, a battery
##   rack they scavenged behind a scrap plate they welded on.
##
## The skimmer hull is master's wreck_hull, its look and far look as they
## were; what it holds is new.

const ARMOUR := Color(0.27, 0.29, 0.25)
const COBALT := Color(0.16, 0.24, 0.36)
const SEAT := Color(0.3, 0.27, 0.24)

static var _coats := {}


## The wrecks after the skimmer hull, which SkimmerKit lists among its era's
## pieces where it always stood.
static func pieces() -> Array[StructureKit.Piece]:
	return [_tithe_hauler(), _freight_pod(), _lifeboat(), _hopper(), _nomad_rig()]


## Every era's coats the wrecks are painted in, by name, and their own.
static func coats() -> Dictionary:
	if _coats.is_empty():
		_coats.merge(SkimmerKit.coats())
		_coats.merge(ColonialKit.coats())
		_coats.merge(SecondAgeKit.coats())
		_coats.merge(NomadLooks.coats())
		_coats["teal"] = Paint.coat(Paint.TEAL, 1.0, 0.3, 0.5)
		_coats["rail"] = Paint.coat(Paint.GUNMETAL, 1.0, 0.5, 0.5)
		_coats["armour"] = Paint.coat(ARMOUR, 1.0, 0.55, 0.55)
		_coats["cobalt"] = Paint.coat(COBALT, 1.0, 0.3, 0.45)
		_coats["seat"] = Paint.coat(SEAT, 0.3, 0.0, 0.9)
	return _coats


## A slab with a rectangular hole through it, as the boxes round the hole:
## `hole` spans the slab's two long axes; its thin axis is the slab's thinnest.
static func holed(p: StructureKit.Piece, lo: Vector3, hi: Vector3, hole_lo: Vector3, hole_hi: Vector3, coat: String) -> void:
	var size := hi - lo
	var thin := 0 if size.x <= size.y and size.x <= size.z else (1 if size.y <= size.z else 2)
	var a := (thin + 1) % 3
	var b := (thin + 2) % 3
	# Below and above the hole along b, full length along a; then either side along a.
	var parts: Array[Array] = []
	parts.append([lo, _with(hi, b, hole_lo[b])])
	parts.append([_with(lo, b, hole_hi[b]), hi])
	var mid_lo := _with(lo, b, hole_lo[b])
	var mid_hi := _with(hi, b, hole_hi[b])
	parts.append([mid_lo, _with(mid_hi, a, hole_lo[a])])
	parts.append([_with(mid_lo, a, hole_hi[a]), mid_hi])
	for part in parts:
		var from: Vector3 = part[0]
		var to: Vector3 = part[1]
		if to[a] - from[a] > 0.01 and to[b] - from[b] > 0.01:
			StructureKit.box(p, from, to, coat)


static func _with(v: Vector3, axis: int, value: float) -> Vector3:
	var out := v
	out[axis] = value
	return out


## A socket for a module: a small device on a rack (`module`) or a big one on
## a floor (`bay`).
static func module(p: StructureKit.Piece, at: Vector3, big := false) -> int:
	p.sockets.append(StructureKit.SiteSocket.new(at, SiteLoot.BAY if big else SiteLoot.MODULE))
	return p.sockets.size() - 1


# --- The skimmer hull: a skimmer down nose first, its tail torn open. ---

static func wreck_hull() -> StructureKit.Piece:
	var p := StructureKit.define(&"wreck_hull", Vector2(3.2, 6.2), Vector2(2.8, 2.8), Vector2(1.2, 1.2))
	p.apron = 5.0
	p.drift_reach = 2.0
	# Thin plate between the sand inside and out: none drifts against it.
	p.drift = PackedFloat32Array([0.0, 0.0, 0.0])
	p.survey = Vector2(1.0, 22.0)
	p.age = Vector2(0.75, 1.0)
	p.marks = 2
	p.slide = Vector2(0.0, 1.0)
	p.slide_m = 12.0
	# Down nose first: it pitches about its tail's floor, the nose into the
	# sand, half its site's lean, so the aft bay stays over the sand.
	p.lean = 0.5
	p.lean_axis = Vector3.LEFT
	p.lean_pivot = Vector3(0.0, 0.0, 6.0)
	# Inside, sand blown flat through the torn tail.
	p.rooms.append(StructureKit.room(Vector2(-2.0, -5.0), Vector2(2.0, 6.2)))
	p.solids = [[Vector2(-2.2, -6.2), Vector2(2.2, 6.0)], [Vector2(-3.2, 1.0), Vector2(3.2, 5.5)]]
	StructureKit.box(p, Vector3(-2.2, -0.25, -6.0), Vector3(2.2, 0.0, 6.0), "hull")
	StructureKit.box(p, Vector3(-2.2, 0.0, -6.0), Vector3(-2.0, 3.0, 6.0), "olive")
	# The starboard wall, a hatch through it over the engine pod.
	holed(p, Vector3(2.0, 0.0, -6.0), Vector3(2.2, 3.0, 6.0), Vector3(2.0, 2.05, 2.0), Vector3(2.2, 2.9, 4.0), "olive")
	StructureKit.box(p, Vector3(-2.2, 3.0, -6.0), Vector3(2.2, 3.25, 4.4), "hull")
	StructureKit.box(p, Vector3(-2.0, 0.0, -6.2), Vector3(2.0, 2.6, -5.0), "hull")
	StructureKit.box(p, Vector3(-0.12, 3.25, 2.4), Vector3(0.12, 4.6, 5.9), "")
	for side in [-1.0, 1.0]:
		StructureKit.box(p, Vector3(minf(side * 2.2, side * 3.2), 0.6, 1.0), Vector3(maxf(side * 2.2, side * 3.2), 1.8, 5.5), "")
	# The bulkhead closing the bay off from the nose, the racks down its
	# walls, and the partition walling the charger bay off to starboard.
	StructureKit.box(p, Vector3(-2.0, 0.0, 0.6), Vector3(2.0, 3.0, 0.8), "scrap")
	StructureKit.box(p, Vector3(-2.0, 1.45, 1.2), Vector3(-1.3, 1.55, 4.2), "steel")
	# The charger bay's shelf, up at the hatch's sill, so it's reached from the sand.
	StructureKit.box(p, Vector3(1.3, 2.0, 2.0), Vector3(2.0, 2.1, 4.0), "steel")
	StructureKit.box(p, Vector3(1.1, 0.0, 2.0), Vector3(1.3, 3.0, 4.0), "scrap")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-1.2, 0.0, 5.0), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.2, 0.0, 5.2), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.0, 0.8, 2.2), &"cache", 0.4))
	var aft := module(p, Vector3(-1.65, 1.55, 3.7))
	var fore := module(p, Vector3(-1.65, 1.55, 1.7))
	var charger := module(p, Vector3(1.65, 2.1, 2.6))
	var w := WreckPlan.new()
	w.armour = 1.0
	var hatch := w.plate(Vector3(2.02, 2.05, 2.0), Vector3(2.2, 2.9, 4.0), 0, 1.0, "starboard hatch")
	var bay := w.hold(Vector3(-1.98, 0.0, 0.82), Vector3(1.08, 2.98, 4.4), 3, Vector3.BACK, "cargo bay",
		"blown in through the torn tail")
	w.module(aft, [[&"hold", bay, 1]])
	w.module(fore, [[&"hold", bay, 3]])
	w.module(charger, [[&"plate", hatch]], Wreckage.ELECTRICAL, Vector3(1.65, 2.4, 3.55))
	p.wreck = w
	p.tour = PackedVector2Array([Vector2(0.0, 12.0), Vector2(0.0, 5.3), Vector2(0.0, 12.0)])
	p.approach = Vector2(6.0, 12.0)
	p.look = _hull_look
	# Its hull and fin over the dunes, and the glass and bare plate the sun catches.
	StructureKit.far_box(p, Vector3(-2.2, -0.25, -6.0), Vector3(2.2, 3.25, 6.0), coats().hull)
	StructureKit.far_box(p, Vector3(-0.12, 3.25, 2.4), Vector3(0.12, 4.6, 5.9), coats().olive)
	for side in [-1.0, 1.0]:
		StructureKit.far_box(p, Vector3(side * 2.7 - 0.6, 0.6, 1.0), Vector3(side * 2.7 + 0.6, 1.8, 5.5), coats().hull)
	StructureKit.glint(p, Vector3(0.0, 1.9, -6.22), Vector3(0.0, 0.3, -1.0), 3.0)
	StructureKit.glint(p, Vector3(2.21, 1.6, -1.5), Vector3(1.0, 0.25, 0.1), 3.0)
	StructureKit.glint(p, Vector3(0.6, 3.27, -2.0), Vector3(0.1, 1.0, -0.2), 4.0)
	StructureKit.glint(p, Vector3(0.0, 3.1, 5.1), Vector3(0.0, 0.7, 0.7), 6.0)
	return p


static func _hull_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.03)
	# Panels that don't match, patched over the sides, and the welds round them.
	for patch: Array in [[Vector3(-2.21, 1.6, -1.5), Vector3(0.02, 1.4, 2.2), c.red],
			[Vector3(2.21, 1.2, -2.5), Vector3(0.02, 1.0, 1.6), c.scrap], [Vector3(0.6, 3.26, -2.0), Vector3(1.8, 0.02, 2.4), c.scrap]]:
		b.box(patch[1], patch[0], patch[2], 0.005)
		var weld: Vector3 = patch[1] + Vector3(0.012, 0.012, 0.012)
		b.box(Vector3(weld.x, 0.04, weld.z) if weld.y > 0.1 else Vector3(weld.x, 0.03, 0.04), patch[0], c.black, 0.004)
	# Ribs left bare where the roof tore away.
	for v: float in [4.8, 5.4]:
		b.box(Vector3(4.4, 0.12, 0.12), Vector3(0.0, 3.1, v), c.steel, 0.02)
	# The cockpit's glass, the nose's hazard band.
	b.box(Vector3(3.2, 0.7, 0.04), Vector3(0.0, 1.9, -6.21), c.glass, 0.01)
	for k in 4:
		b.box(Vector3(0.5, 0.16, 0.03), Vector3(-1.5 + k * 1.0, 0.5, -6.21), c.yellow if k % 2 == 0 else c.black, 0.004)
	# A stencilled arrow and band by the starboard hatch: where the crew got
	# at the charger.
	b.box(Vector3(0.02, 0.12, 2.3), Vector3(2.21, 3.0, 3.0), c.yellow, 0.003)
	# Engine pods, and the fin with the crew's patch painted on it.
	for side in [-1.0, 1.0]:
		b.drum(0.6, 4.5, Vector3(side * 2.7, 1.2, 3.25), c.hull, Basis(Vector3.RIGHT, PI * 0.5), 12)
		b.drum(0.5, 0.2, Vector3(side * 2.7, 1.2, 5.55), c.black, Basis(Vector3.RIGHT, PI * 0.5), 12)
	b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(0.12, 4.0, 4.3), 1.3, Basis(Vector3.UP, PI * 0.5))
	b.box(Vector3(0.24, 1.35, 3.5), Vector3(0.0, 3.925, 4.15), c.olive, 0.02)
	# Rack uprights, and crates' straps left on the racks.
	for side in [-1.0, 1.0]:
		for v: float in [1.3, 2.7, 4.1]:
			b.box(Vector3(0.05, 1.5, 0.05), Vector3(side * 1.33, 0.75, v), c.steel, 0.005)


# --- The tithe hauler: a Provisional armoured hauler, listing on its skirts. ---

static func _tithe_hauler() -> StructureKit.Piece:
	var p := StructureKit.define(&"tithe_hauler", Vector2(2.6, 8.3), Vector2(2.6, 2.6), Vector2(1.1, 1.1))
	p.apron = 5.0
	p.drift_reach = 2.0
	p.drift = PackedFloat32Array([0.0, 0.0, 0.0])
	p.survey = Vector2(1.2, 22.0)
	p.age = Vector2(0.7, 0.95)
	p.marks = 2
	p.slide = Vector2(0.0, 1.0)
	p.slide_m = 14.0
	# It lists to port about its starboard skirt, its port side lifted on its
	# armour skirt: a third of its site's lean.
	p.lean = 0.35
	p.lean_axis = Vector3.FORWARD
	p.lean_pivot = Vector3(2.5, 0.0, 0.0)
	# Its deck stands on its skirts: inside them the sand lies under the deck,
	# which its lifted side stands clear of.
	p.rooms.append(StructureKit.room(Vector2(-2.3, -8.0), Vector2(2.3, 8.0)))
	StructureKit.box(p, Vector3(-2.5, 0.0, -8.0), Vector3(2.5, 0.25, 8.0), "armour")
	# Skirts down into the sand all round.
	StructureKit.box(p, Vector3(-2.5, -1.15, -8.2), Vector3(-2.3, 0.0, 8.2), "armour")
	StructureKit.box(p, Vector3(2.3, -0.45, -8.2), Vector3(2.5, 0.0, 8.2), "armour")
	StructureKit.box(p, Vector3(-2.3, -1.15, 7.9), Vector3(2.3, 0.0, 8.2), "armour")
	StructureKit.box(p, Vector3(-2.3, -1.15, -8.2), Vector3(2.3, 0.0, -7.9), "armour")
	StructureKit.box(p, Vector3(2.3, 0.25, -8.0), Vector3(2.5, 3.65, 8.0), "armour")
	# The port wall: the cargo door and the cab door through it.
	holed(p, Vector3(-2.5, 0.25, -8.0), Vector3(-2.3, 3.65, 3.0), Vector3(-2.5, 0.55, -6.0), Vector3(-2.3, 3.25, -2.0), "armour")
	holed(p, Vector3(-2.5, 0.25, 3.0), Vector3(-2.3, 3.65, 8.0), Vector3(-2.5, 0.55, 4.6), Vector3(-2.3, 2.55, 6.0), "armour")
	StructureKit.box(p, Vector3(-2.5, 0.25, -8.2), Vector3(2.5, 3.65, -8.0), "armour")
	StructureKit.box(p, Vector3(-2.5, 3.65, -8.2), Vector3(2.5, 3.85, 3.0), "olive")
	# The cab roof, torn open over its first metre: the breach the storms came in by.
	StructureKit.box(p, Vector3(-2.5, 3.65, 4.0), Vector3(2.5, 3.85, 8.0), "olive")
	StructureKit.box(p, Vector3(-2.5, 0.25, 8.0), Vector3(2.5, 3.25, 8.4), "armour")
	StructureKit.box(p, Vector3(-2.3, 0.25, 3.0), Vector3(2.3, 3.65, 3.2), "armour")
	# The requisition locker's wall, its door plated over.
	holed(p, Vector3(-2.3, 0.25, -1.1), Vector3(2.3, 3.65, -0.9), Vector3(-0.8, 0.5, -1.1), Vector3(0.8, 2.25, -0.9), "armour")
	StructureKit.box(p, Vector3(1.7, 1.1, -0.8), Vector3(2.3, 1.2, 2.9), "steel")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(2.0, 1.2, 0.4), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.6, 1.15, 7.4), &"cache", 0.3))
	var locker := module(p, Vector3(0.4, 0.25, 1.2), true)
	var cab := module(p, Vector3(1.4, 0.25, 6.4))
	var cargo := module(p, Vector3(-0.6, 0.25, -5.0), true)
	var w := WreckPlan.new()
	w.armour = 2.0
	var door := w.plate(Vector3(-2.5, 0.55, -6.0), Vector3(-2.32, 3.25, -2.0), 0, -1.0, "armoured cargo door")
	var locker_door := w.plate(Vector3(-0.8, 0.5, -1.1), Vector3(0.8, 2.25, -0.95), 2, -1.0, "locker door")
	var cab_door := w.plate(Vector3(-2.5, 0.55, 4.6), Vector3(-2.32, 2.55, 6.0), 0, -1.0, "cab door")
	var cab_sand := w.hold(Vector3(-2.28, 0.25, 3.22), Vector3(2.28, 3.63, 7.98), 3, Vector3.LEFT, "cab",
		"poured in through the roof breach")
	var floor_sand := w.hold(Vector3(-2.28, 0.25, -7.98), Vector3(2.28, 0.85, -1.12), 1, WreckPlan.TOP, "cargo deck",
		"sifted in round the door")
	w.module(locker, [[&"plate", door], [&"plate", locker_door]])
	w.module(cab, [[&"plate", cab_door], [&"hold", cab_sand, 3]])
	w.module(cargo, [[&"plate", door], [&"hold", floor_sand, 1]], Wreckage.BIO, Vector3(0.9, 0.55, -6.3))
	p.wreck = w
	p.tour = PackedVector2Array([Vector2(-8.0, -4.0), Vector2(-3.5, -4.0), Vector2(-8.0, -4.0)])
	p.approach = Vector2(-11.0, 2.0)
	p.look = _hauler_look
	# Its armoured body, the cab's lower front and the olive roof; the cab's
	# slit windows, the one in its door and its empty gun ring catch the sun.
	var c := coats()
	StructureKit.far_box(p, Vector3(-2.5, 0.0, -8.2), Vector3(2.5, 3.65, 8.0), c.armour)
	StructureKit.far_box(p, Vector3(-2.5, 0.0, 8.0), Vector3(2.5, 3.25, 8.4), c.armour)
	StructureKit.far_box(p, Vector3(-2.5, 3.65, -8.2), Vector3(2.5, 3.85, 8.0), c.olive)
	StructureKit.glint(p, Vector3(0.0, 2.65, 8.42), Vector3(0.0, 0.3, 1.0), 3.0)
	StructureKit.glint(p, Vector3(-2.54, 2.9, 5.3), Vector3(-1.0, 0.3, 0.0), 3.0)
	StructureKit.glint(p, Vector3(0.52, 3.89, -3.0), Vector3(0.1, 1.0, 0.1), 4.0)
	return p


static func _hauler_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.03)
	# The cab's slit windows behind their grilles, its ram plate and
	# headlamps, the member state's seal on each flank, hazard chevrons on the
	# skirts.
	b.box(Vector3(4.0, 0.35, 0.04), Vector3(0.0, 2.65, 8.41), c.glass, 0.01)
	for u: float in [-1.5, -0.5, 0.5, 1.5]:
		b.box(Vector3(0.05, 0.42, 0.05), Vector3(u, 2.65, 8.44), c.steel, 0.006)
	b.box(Vector3(4.6, 0.8, 0.12), Vector3(0.0, 0.85, 8.45), c.steel, 0.02)
	for u: float in [-1.9, 1.9]:
		b.drum(0.12, 0.08, Vector3(u, 1.5, 8.44), c.glass, Basis(Vector3.RIGHT, PI * 0.5), 10)
	for k in 6:
		b.box(Vector3(0.5, 0.25, 0.03), Vector3(-2.0 + k * 0.8, -0.5, 8.22), c.yellow if k % 2 == 0 else c.black, 0.004)
	for side in [-1.0, 1.0]:
		var turn := Basis(Vector3.UP, side * PI * 0.5)
		b.stamp(Paint.Mark.MEMBER_STATE, Vector3(side * 2.52, 2.2, 0.8), 1.4, turn)
		b.box(Vector3(0.02, 1.0, 1.8), Vector3(side * 2.51, 2.2, 0.8), c.panel, 0.005)
		# Its tracks' housings along the skirt, a run of road wheels showing under them.
		b.box(Vector3(0.12, 0.35, 15.6), Vector3(side * 2.58, 0.05, 0.0), c.olive, 0.01)
		for v: float in [-6.6, -4.4, -2.2, 0.0, 2.2, 4.4, 6.6]:
			b.drum(0.38, 0.14, Vector3(side * 2.6, -0.4, v), c.black, Basis(Vector3.BACK, PI * 0.5), 12)
	# Rivet rows down its armour, a slit window in the cab door, and chevrons
	# round the cargo door where the tithe went in and out.
	for v: float in [-7.0, -4.0, -1.0, 2.0, 5.0, 7.5]:
		b.box(Vector3(0.03, 3.0, 0.06), Vector3(2.52, 1.95, v), c.steel, 0.005)
	b.box(Vector3(0.03, 0.3, 0.8), Vector3(-2.52, 2.9, 5.3), c.glass, 0.004)
	for k in 5:
		b.box(Vector3(0.03, 0.22, 0.8), Vector3(-2.52, 3.38, -5.6 + k * 0.8), c.yellow if k % 2 == 0 else c.black, 0.003)
	# A roof ring where its gun was, its mount empty, and a snapped whip aerial.
	b.ring(0.45, 0.6, Vector3(0.0, 3.88, -3.0), c.dark, Basis.IDENTITY, 12)
	b.drum(0.03, 1.4, Vector3(1.8, 4.55, 6.8), c.steel, Basis(Vector3.BACK, 0.35), 6)
	# Inside: a stencilled tithe band over the locker door, and the cab's seats.
	b.box(Vector3(1.4, 0.2, 0.02), Vector3(0.0, 2.65, -1.12), c.yellow, 0.003)
	b.box(Vector3(1.4, 0.8, 0.8), Vector3(-1.0, 0.65, 7.3), c.seat, 0.03)


# --- The freight pod: a contractor's cargo pod, its hatch open to the storms. ---

static func _freight_pod() -> StructureKit.Piece:
	var p := StructureKit.define(&"freight_pod", Vector2(3.1, 6.1), Vector2(3.0, 3.0), Vector2(1.4, 1.4))
	p.apron = 5.0
	p.drift_reach = 2.0
	p.drift = PackedFloat32Array([0.0, 0.0, 0.0])
	p.survey = Vector2(1.2, 20.0)
	p.age = Vector2(0.2, 0.45)
	p.marks = 2
	p.slide = Vector2(0.0, 1.0)
	p.slide_m = 14.0
	# Inside, the floor swept bare once it's dug out; the sand drifts against its walls.
	p.rooms.append(StructureKit.room(Vector2(-2.8, -5.8), Vector2(2.8, 5.8)))
	StructureKit.box(p, Vector3(-3.0, -0.25, -6.0), Vector3(3.0, 0.0, 6.0), "grey")
	StructureKit.box(p, Vector3(-3.0, 0.0, -6.0), Vector3(-2.8, 4.0, 6.0), "panel")
	holed(p, Vector3(2.8, 0.0, -6.0), Vector3(3.0, 4.0, 6.0), Vector3(2.8, 0.3, -4.0), Vector3(3.0, 3.6, 0.0), "panel")
	# Its front hatch open: what blew in packed the hold behind it.
	holed(p, Vector3(-3.0, 0.0, 5.8), Vector3(3.0, 4.0, 6.0), Vector3(-1.5, 0.0, 5.8), Vector3(1.5, 3.2, 6.0), "panel")
	StructureKit.box(p, Vector3(-3.0, 0.0, -6.0), Vector3(3.0, 4.0, -5.8), "panel")
	StructureKit.box(p, Vector3(-3.0, 4.0, -6.0), Vector3(3.0, 4.2, 6.0), "grey")
	StructureKit.box(p, Vector3(-2.8, 0.0, -0.1), Vector3(2.8, 4.0, 0.1), "grey")
	StructureKit.box(p, Vector3(-2.8, 1.2, 3.8), Vector3(-2.2, 1.3, 5.6), "steel")
	# Its hatch, swung wide open on its hinge.
	StructureKit.box(p, Vector3(1.5, 0.0, 6.0), Vector3(1.62, 3.2, 9.0), "panel")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-2.5, 1.3, 4.6), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-0.8, 0.0, 7.6), &"floor"))
	var console := module(p, Vector3(1.6, 0.0, 4.2), true)
	var shield := module(p, Vector3(-1.6, 0.0, 1.6))
	var freight := module(p, Vector3(-1.2, 0.0, -3.0), true)
	var charger := module(p, Vector3(1.5, 0.0, -4.6))
	var w := WreckPlan.new()
	w.armour = 1.5
	var side := w.plate(Vector3(2.82, 0.3, -4.0), Vector3(3.0, 3.6, 0.0), 0, 1.0, "side panel")
	var front := w.hold(Vector3(-2.78, 0.0, 0.12), Vector3(2.78, 3.98, 5.78), 4, Vector3.BACK, "front hold",
		"blown in through its open hatch")
	var rear := w.hold(Vector3(-2.78, 0.0, -5.78), Vector3(2.78, 1.4, -0.12), 2, Vector3.RIGHT, "rear hold",
		"sifted in round the side panel")
	w.module(console, [[&"hold", front, 2]], Wreckage.ELECTRICAL, Vector3(2.4, 0.3, 3.2))
	w.module(shield, [[&"hold", front, 4]])
	w.module(freight, [[&"plate", side], [&"hold", rear, 2]], Wreckage.BIO, Vector3(-2.3, 0.3, -4.9))
	w.module(charger, [[&"plate", side], [&"hold", rear, 1]])
	p.wreck = w
	p.tour = PackedVector2Array([Vector2(0.0, 12.0), Vector2(0.0, 6.8), Vector2(0.0, 12.0)])
	p.approach = Vector2(7.0, 12.0)
	p.look = _pod_look
	# Its panelled body under its grey roof, its hatch swung wide; the roof,
	# its flank and the hatch's grab handles catch the sun.
	var c := coats()
	StructureKit.far_box(p, Vector3(-3.0, -0.25, -6.0), Vector3(3.0, 4.0, 6.0), c.panel)
	StructureKit.far_box(p, Vector3(-3.0, 4.0, -6.0), Vector3(3.0, 4.2, 6.0), c.grey)
	StructureKit.far_box(p, Vector3(1.5, 0.0, 6.0), Vector3(1.62, 3.2, 9.0), c.panel)
	StructureKit.glint(p, Vector3(0.0, 4.21, 2.0), Vector3(0.0, 1.0, 0.2), 4.0)
	StructureKit.glint(p, Vector3(-3.01, 3.0, -3.0), Vector3(-1.0, 0.3, 0.0), 3.0)
	StructureKit.glint(p, Vector3(1.7, 2.2, 8.4), Vector3(1.0, 0.35, 0.1), 5.0)
	return p


static func _pod_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.04)
	# Panel seams, the contractor's tag on each flank, an orange band, the
	# hatch's hinge and its grab handles.
	for v: float in [-4.0, -2.0, 2.0, 4.0]:
		if StructureKit.shows(p, state, 4.0):
			b.box(Vector3(0.02, 3.9, 0.04), Vector3(-3.01, 2.0, v), c.grey, 0.004)
	for side in [-1.0, 1.0]:
		var turn := Basis(Vector3.UP, side * PI * 0.5)
		b.stamp(Paint.Mark.CONTRACTOR, Vector3(side * 3.02, 2.8, 3.0), 1.6, turn)
		b.box(Vector3(0.02, 1.0, 2.2), Vector3(side * 3.01, 2.8, 3.0), c.panel, 0.005)
		# An orange band down its flank, broken where the side panel's welded in.
		if side < 0.0:
			b.box(Vector3(0.02, 0.3, 11.8), Vector3(side * 3.01, 1.1, 0.0), c.orange, 0.004)
		else:
			b.box(Vector3(0.02, 0.3, 1.9), Vector3(side * 3.01, 1.1, -4.95), c.orange, 0.004)
			b.box(Vector3(0.02, 0.3, 5.9), Vector3(side * 3.01, 1.1, 2.95), c.orange, 0.004)
	b.drum(0.08, 3.2, Vector3(1.56, 1.6, 6.02), c.steel, Basis.IDENTITY, 8)
	for y: float in [1.0, 2.2]:
		b.box(Vector3(0.06, 0.08, 0.5), Vector3(1.66, y, 8.4), c.steel, 0.01)
	# A cargo strap fallen loose across the front hold.
	b.box(Vector3(5.4, 0.04, 0.1), Vector3(0.0, 3.6, 5.6), c.orange, 0.004)


# --- The lifeboat: a freighter's boat, down on its skids. ---

static func _lifeboat() -> StructureKit.Piece:
	var p := StructureKit.define(&"lifeboat", Vector2(2.3, 4.7), Vector2(2.4, 2.4), Vector2(1.0, 1.0))
	p.apron = 4.5
	p.drift_reach = 2.0
	p.drift = PackedFloat32Array([0.0, 0.0, 0.0])
	p.survey = Vector2(1.0, 20.0)
	p.age = Vector2(0.15, 0.4)
	p.marks = 2
	p.slide = Vector2(0.0, 1.0)
	p.slide_m = 12.0
	p.rooms.append(StructureKit.room(Vector2(-1.8, -4.3), Vector2(1.8, 4.3)))
	StructureKit.box(p, Vector3(-2.0, -0.25, -4.5), Vector3(2.0, 0.0, 4.5), "grey")
	for side in [-1.0, 1.0]:
		StructureKit.box(p, Vector3(side * 2.0 - 0.2, -0.55, -4.0), Vector3(side * 2.0 + 0.2, -0.25, 4.0), "dark")
	# Port, the boarding hatch, fused shut as it came down.
	holed(p, Vector3(-2.0, 0.0, -4.5), Vector3(-1.8, 3.0, 4.5), Vector3(-2.0, 0.2, -1.0), Vector3(-1.8, 2.2, 0.6), "panel")
	StructureKit.box(p, Vector3(1.8, 0.0, -4.5), Vector3(2.0, 3.0, 4.5), "panel")
	StructureKit.box(p, Vector3(-2.0, 3.0, -4.5), Vector3(2.0, 3.2, 4.5), "cobalt")
	# The nose, its viewport cracked open: the storms' way in.
	holed(p, Vector3(-2.0, 0.0, 4.3), Vector3(2.0, 3.0, 4.5), Vector3(-1.2, 1.6, 4.3), Vector3(1.2, 2.6, 4.5), "panel")
	# The aft bulkhead to the battery room, and its access panel out the back.
	StructureKit.box(p, Vector3(-1.8, 0.0, -3.0), Vector3(1.8, 3.0, -2.8), "grey")
	holed(p, Vector3(-2.0, 0.0, -4.5), Vector3(2.0, 3.0, -4.3), Vector3(-1.0, 0.4, -4.5), Vector3(1.0, 2.2, -4.3), "panel")
	# Seats down the cabin, and a locker on the starboard wall.
	StructureKit.box(p, Vector3(-1.8, 0.0, 1.0), Vector3(-1.0, 0.9, 3.6), "seat")
	StructureKit.box(p, Vector3(1.0, 0.0, 1.0), Vector3(1.8, 0.9, 3.6), "seat")
	StructureKit.box(p, Vector3(1.2, 1.1, -2.6), Vector3(1.8, 1.2, 0.4), "steel")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.0, 0.0, 3.9), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.4, 1.2, -2.2), &"shelf"))
	var beacon := module(p, Vector3(1.5, 1.2, -0.9))
	var kit := module(p, Vector3(-1.4, 0.9, 2.6))
	var charger := module(p, Vector3(0.8, 0.0, -3.7))
	var w := WreckPlan.new()
	w.armour = 1.2
	var hatch := w.plate(Vector3(-2.0, 0.2, -1.0), Vector3(-1.82, 2.2, 0.6), 0, -1.0, "boarding hatch")
	var panel := w.plate(Vector3(-1.0, 0.4, -4.5), Vector3(1.0, 2.2, -4.32), 2, -1.0, "aft access panel")
	var cabin := w.hold(Vector3(-1.78, 0.0, -2.78), Vector3(1.78, 1.6, 4.28), 3, Vector3.LEFT, "cabin",
		"blown in through the cracked viewport")
	w.module(beacon, [[&"plate", hatch], [&"hold", cabin, 3]])
	w.module(kit, [[&"plate", hatch], [&"hold", cabin, 1]], Wreckage.BIO, Vector3(-1.4, 1.2, 1.5))
	w.module(charger, [[&"plate", panel]], Wreckage.ELECTRICAL, Vector3(-0.9, 0.3, -3.7))
	p.wreck = w
	p.tour = PackedVector2Array([Vector2(-7.0, 0.0), Vector2(-2.6, -0.2), Vector2(-7.0, 0.0)])
	p.approach = Vector2(-9.0, 4.0)
	p.look = _lifeboat_look
	# Its panelled body under its cobalt roof; the glass left in its viewport
	# and the roof catch the sun.
	var c := coats()
	StructureKit.far_box(p, Vector3(-2.0, -0.25, -4.5), Vector3(2.0, 3.0, 4.5), c.panel)
	StructureKit.far_box(p, Vector3(-2.0, 3.0, -4.5), Vector3(2.0, 3.2, 4.5), c.cobalt)
	StructureKit.glint(p, Vector3(0.8, 2.25, 4.45), Vector3(0.0, 0.3, 1.0), 3.0)
	StructureKit.glint(p, Vector3(1.0, 3.21, 0.0), Vector3(0.2, 1.0, 0.0), 4.0)
	return p


static func _lifeboat_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.05)
	# Rounded shoulders along its roof, its freighter's consignment stencil
	# and a cobalt band on each flank, the viewport's broken frame.
	for side in [-1.0, 1.0]:
		if StructureKit.shows(p, state, 3.2):
			b.drum(0.22, 9.0, Vector3(side * 1.85, 2.98, 0.0), c.panel, Basis(Vector3.RIGHT, PI * 0.5), 10)
		var turn := Basis(Vector3.UP, side * PI * 0.5)
		b.stamp(Paint.Mark.CONSIGNMENT, Vector3(side * 2.02, 2.3, 2.6), 1.3, turn)
		b.box(Vector3(0.02, 0.9, 1.8), Vector3(side * 2.01, 2.3, 2.6), c.panel, 0.005)
		# A cobalt band down its flank, broken at the boarding hatch.
		if side > 0.0:
			b.box(Vector3(0.02, 0.25, 9.0), Vector3(side * 2.01, 0.9, 0.0), c.cobalt, 0.004)
		else:
			b.box(Vector3(0.02, 0.25, 3.45), Vector3(side * 2.01, 0.9, -2.775), c.cobalt, 0.004)
			b.box(Vector3(0.02, 0.25, 3.85), Vector3(side * 2.01, 0.9, 2.625), c.cobalt, 0.004)
	b.box(Vector3(2.5, 0.08, 0.06), Vector3(0.0, 1.6, 4.52), c.dark, 0.01)
	b.box(Vector3(0.3, 0.6, 0.03), Vector3(0.8, 2.25, 4.42), c.glass, 0.004, Basis(Vector3.BACK, 0.4))
	# Thruster bells out the back, an orange flash round the access panel.
	for u: float in [-1.4, 1.4]:
		b.drum(0.3, 0.4, Vector3(u, 1.6, -4.7), c.dark, Basis(Vector3.RIGHT, PI * 0.5), 10, 0.2)
	b.box(Vector3(2.3, 0.08, 0.02), Vector3(0.0, 2.3, -4.52), c.orange, 0.003)
	b.box(Vector3(2.3, 0.08, 0.02), Vector3(0.0, 0.3, -4.52), c.orange, 0.003)


# --- The hopper: the Knights' suborbital hopper, down on its belly. ---

static func _hopper() -> StructureKit.Piece:
	var p := StructureKit.define(&"hopper", Vector2(5.6, 7.6), Vector2(1.8, 1.8), Vector2(0.8, 0.8))
	p.apron = 4.0
	p.drift_reach = 2.0
	p.drift = PackedFloat32Array([0.0, 0.0, 0.0])
	p.survey = Vector2(1.2, 20.0)
	p.age = Vector2(0.45, 0.75)
	p.marks = 1
	p.slide = Vector2(0.0, 1.0)
	p.slide_m = 14.0
	p.solids = [[Vector2(-1.7, -5.6), Vector2(1.7, 5.6)], [Vector2(-5.6, -4.0), Vector2(3.4, 1.0)]]
	# The troop bay and cockpit, their floors bare once dug out.
	p.rooms.append(StructureKit.room(Vector2(-1.4, -5.5), Vector2(1.4, 5.5)))
	StructureKit.box(p, Vector3(-1.6, -0.25, -5.5), Vector3(1.6, 0.0, 5.5), "grey")
	StructureKit.box(p, Vector3(-1.6, 0.0, -5.5), Vector3(-1.4, 2.6, 5.5), "lime")
	StructureKit.box(p, Vector3(1.4, 0.0, -5.5), Vector3(1.6, 2.6, 5.5), "lime")
	StructureKit.box(p, Vector3(-1.6, 2.6, -5.5), Vector3(1.6, 2.8, 4.0), "lime")
	# The nose and its canopy frame.
	StructureKit.box(p, Vector3(-1.6, 0.0, 5.5), Vector3(1.6, 1.6, 6.4), "lime")
	StructureKit.box(p, Vector3(-1.6, 2.2, 4.0), Vector3(1.6, 2.4, 5.5), "panel")
	# The ramp's doorway out the back, and the ramp lowered onto the sand.
	holed(p, Vector3(-1.6, 0.0, -5.7), Vector3(1.6, 2.8, -5.5), Vector3(-1.2, 0.0, -5.7), Vector3(1.2, 2.4, -5.5), "lime")
	StructureKit.box(p, Vector3(-1.2, -0.05, -7.6), Vector3(1.2, 0.08, -5.7), "grey")
	# The cockpit's bulkhead, its door plated shut.
	holed(p, Vector3(-1.4, 0.0, 1.0), Vector3(1.4, 2.6, 1.2), Vector3(-0.5, 0.3, 1.0), Vector3(0.5, 2.0, 1.2), "panel")
	# The port wing and its lift-fan nacelle on top of it, cowled at your
	# chest on its outer side over a lip; the starboard wing snapped short,
	# its end lying in the sand.
	StructureKit.box(p, Vector3(-5.6, 0.8, -4.0), Vector3(-1.6, 1.0, 1.0), "lime")
	StructureKit.box(p, Vector3(-4.0, 1.0, -3.5), Vector3(-1.6, 2.0, -3.3), "dark")
	StructureKit.box(p, Vector3(-4.0, 1.0, 0.3), Vector3(-1.6, 2.0, 0.5), "dark")
	StructureKit.box(p, Vector3(-4.0, 2.0, -3.5), Vector3(-1.6, 2.1, 0.5), "dark")
	StructureKit.box(p, Vector3(-4.0, 1.0, -3.3), Vector3(-3.82, 1.25, 0.3), "dark")
	StructureKit.box(p, Vector3(1.6, 0.8, -4.0), Vector3(3.4, 1.0, 0.0), "lime")
	StructureKit.box(p, Vector3(3.8, -0.1, -5.0), Vector3(5.4, 0.1, -2.2), "lime")
	StructureKit.box(p, Vector3(-0.12, 2.8, -5.5), Vector3(0.12, 4.2, -3.2), "lime")
	StructureKit.box(p, Vector3(-1.4, 0.0, 4.6), Vector3(1.4, 0.7, 5.5), "dark")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.0, 0.08, -6.6), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.0, 0.7, 5.1), &"shelf"))
	var flight := module(p, Vector3(0.0, 0.0, 3.4), true)
	var fan := module(p, Vector3(-2.8, 1.0, -1.5))
	var water := module(p, Vector3(-0.6, 0.0, -0.9), true)
	var stores := module(p, Vector3(0.5, 0.0, -3.9), true)
	var w := WreckPlan.new()
	w.armour = 1.0
	var door := w.plate(Vector3(-0.5, 0.3, 1.0), Vector3(0.5, 2.0, 1.15), 2, -1.0, "cockpit door")
	var cowl := w.plate(Vector3(-4.0, 1.25, -3.3), Vector3(-3.82, 1.95, 0.3), 0, -1.0, "fan cowling")
	var bay := w.hold(Vector3(-1.38, 0.0, -5.48), Vector3(1.38, 2.58, 0.98), 3, Vector3.FORWARD, "troop bay",
		"blown in up the lowered ramp")
	w.module(flight, [[&"hold", bay, 3], [&"plate", door]], Wreckage.ELECTRICAL, Vector3(0.9, 0.3, 2.0))
	w.module(fan, [[&"plate", cowl]])
	w.module(water, [[&"hold", bay, 3]])
	w.module(stores, [[&"hold", bay, 2]], Wreckage.BIO, Vector3(1.0, 0.3, -2.6))
	p.wreck = w
	p.tour = PackedVector2Array([Vector2(0.0, -12.0), Vector2(0.0, -6.0), Vector2(0.0, -12.0)])
	p.approach = Vector2(-8.0, -11.0)
	p.look = _hopper_look
	# Its limed body stepping down to the cockpit and nose, the port wing and
	# the starboard stub, the fan's dark nacelle and the fin; the canopy and
	# the broken wing's bare ribs catch the sun.
	var c := coats()
	StructureKit.far_box(p, Vector3(-1.6, -0.25, -5.5), Vector3(1.6, 2.8, 4.0), c.lime)
	StructureKit.far_box(p, Vector3(-1.6, -0.25, 4.0), Vector3(1.6, 2.6, 5.5), c.lime)
	StructureKit.far_box(p, Vector3(-1.6, -0.25, 5.5), Vector3(1.6, 1.6, 6.4), c.lime)
	StructureKit.far_box(p, Vector3(-5.6, 0.8, -4.0), Vector3(-1.6, 1.0, 1.0), c.lime)
	StructureKit.far_box(p, Vector3(1.6, 0.8, -4.0), Vector3(3.4, 1.0, 0.0), c.lime)
	StructureKit.far_box(p, Vector3(-4.0, 0.0, -3.5), Vector3(-1.6, 0.8, 0.5), c.dark)
	StructureKit.far_box(p, Vector3(-0.12, 2.8, -5.5), Vector3(0.12, 4.2, -3.2), c.lime)
	StructureKit.glint(p, Vector3(0.0, 2.41, 4.8), Vector3(0.0, 1.0, 0.5), 5.0)
	StructureKit.glint(p, Vector3(3.55, 0.95, -1.75), Vector3(0.5, 0.85, 0.0), 4.0)
	StructureKit.glint(p, Vector3(-3.0, 2.11, -1.5), Vector3(0.0, 1.0, 0.0), 4.0)
	return p


static func _hopper_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.03)
	# The canopy glass, the colonial maker's tag left under the lime wash, and
	# over it the Knights' daubed sign on the fin and both flanks.
	b.box(Vector3(2.9, 0.5, 1.4), Vector3(0.0, 2.0, 4.75), c.glass, 0.02, Basis(Vector3.RIGHT, -0.5))
	b.stamp(Paint.Mark.CONTRACTOR, Vector3(1.62, 1.0, 3.0), 1.0, Basis(Vector3.UP, PI * 0.5))
	b.box(Vector3(0.02, 0.5, 1.0), Vector3(1.61, 1.0, 3.0), c.panel, 0.004)
	for side in [-1.0, 1.0]:
		b.box(Vector3(0.02, 1.2, 0.22), Vector3(side * 1.62, 1.6, 0.0), c.daub, 0.004)
		b.box(Vector3(0.02, 0.22, 0.9), Vector3(side * 1.62, 1.8, 0.0), c.daub, 0.004)
	b.box(Vector3(0.26, 0.9, 0.2), Vector3(0.0, 3.6, -4.2), c.daub, 0.004)
	b.box(Vector3(0.26, 0.2, 0.8), Vector3(0.0, 3.8, -4.2), c.daub, 0.004)
	# Cord lashings the Knights tied round its broken wing, and the fan's
	# ring on top of its nacelle.
	for u: float in [2.6, 3.2]:
		b.box(Vector3(0.05, 0.3, 0.1), Vector3(u, 0.9, -2.0), c.cord, 0.004)
	b.ring(0.25, 0.32, Vector3(-2.8, 2.12, -1.5), c.steel, Basis.IDENTITY, 12)
	# Its main engines over the ramp, scorched; the burn it left down its
	# belly as it came in; the wing's torn root, its ribs bare.
	for u: float in [-0.8, 0.8]:
		b.drum(0.38, 0.6, Vector3(u, 2.3, -5.9), c.dark, Basis(Vector3.RIGHT, PI * 0.5), 12, 0.3)
		b.drum(0.28, 0.05, Vector3(u, 2.3, -6.2), c.black, Basis(Vector3.RIGHT, PI * 0.5), 12)
	for side in [-1.0, 1.0]:
		b.box(Vector3(0.012, 0.35, 7.0), Vector3(side * 1.607, 0.2, -1.0), Paint.coat(Paint.BLACK, 0.4, 0.0, 0.95, 1.4), 0.0)
	for v: float in [-3.4, -2.3, -1.2, -0.1]:
		b.box(Vector3(0.6, 0.08, 0.08), Vector3(3.5, 0.9, v), c.steel, 0.01)
	# Inside the troop bay, its benches down both walls.
	for side in [-1.0, 1.0]:
		b.box(Vector3(0.45, 0.45, 4.0), Vector3(side * 1.15, 0.22, -3.0), c.seat, 0.02)
	# The colonial hopper's own orange stripe, half under the lime wash.
	b.box(Vector3(0.02, 0.18, 6.0), Vector3(-1.61, 0.6, 2.0), c.orange, 0.003)


# --- The nomad rig: a nomads' sailing rig, wrecked, its mast down beside it. ---

static func _nomad_rig() -> StructureKit.Piece:
	var p := StructureKit.define(&"nomad_rig", Vector2(2.2, 1.6), Vector2(0.4, 0.4), Vector2(0.15, 0.15))
	p.apron = 3.5
	p.drift_reach = 1.5
	# Its thin deck has no wall to hold a drift above the plates.
	p.drift = PackedFloat32Array([0.0, 0.0, 0.0])
	p.survey = Vector2(1.0, 20.0)
	p.age = Vector2(0.35, 0.6)
	p.marks = 1
	p.slide = Vector2(0.0, 1.0)
	p.slide_m = 10.0
	p.solids = [[Vector2(-1.0, -1.5), Vector2(1.0, 1.5)], [Vector2(1.15, 0.55), Vector2(2.15, 1.55)]]
	# On its deck the sand lies under the plates, blown off it.
	p.rooms.append(StructureKit.room(Vector2(-1.0, -1.5), Vector2(1.0, 1.5)))
	# Five pieces of three eras' chassis, the sixth torn off and lying tipped
	# beside the gap it left.
	for piece: Array in [[Vector2(-1.0, -1.5), "teal"], [Vector2(0.0, -1.5), "olive"], [Vector2(-1.0, -0.5), "lime"],
			[Vector2(0.0, -0.5), "teal"], [Vector2(-1.0, 0.5), "olive"]]:
		var lo: Vector2 = piece[0]
		StructureKit.box(p, Vector3(lo.x, -0.06, lo.y), Vector3(lo.x + 1.0, 0.06, lo.y + 1.0), piece[1])
	StructureKit.box(p, Vector3(1.15, 0.0, 0.55), Vector3(2.15, 0.3, 1.55), "")
	# The locker: a frame on the middle piece walled in cloth on three sides,
	# a piece across its top for a shelf, packed with sand through its open side.
	for u: float in [-1.0, -0.05]:
		for v: float in [-0.5, 0.45]:
			StructureKit.box(p, Vector3(u, 0.06, v), Vector3(u + 0.05, 1.06, v + 0.05), "rail")
	StructureKit.box(p, Vector3(-1.0, 1.06, -0.5), Vector3(0.0, 1.18, 0.5), "lime")
	StructureKit.box(p, Vector3(-1.0, 0.06, -0.45), Vector3(-0.988, 1.06, 0.45), "ochre")
	StructureKit.box(p, Vector3(-0.95, 0.06, 0.488), Vector3(-0.05, 1.06, 0.5), "indigo")
	StructureKit.box(p, Vector3(-0.95, 0.06, -0.5), Vector3(-0.05, 1.06, -0.488), "indigo")
	# A skimmer crew's battery rack lashed at the bow, a scrap plate welded
	# across it between two posts to keep the sand out of its bays.
	for u: float in [-0.06, 1.01]:
		StructureKit.box(p, Vector3(u, 0.06, -1.3), Vector3(u + 0.05, 1.2, -1.2), "scrap")
	StructureKit.box(p, Vector3(-0.06, 1.15, -1.3), Vector3(1.06, 1.2, -1.2), "scrap")
	# The post their mast stood in, snapped off short, a pennant on it still.
	StructureKit.box(p, Vector3(-0.56, 0.06, 0.94), Vector3(-0.44, 2.5, 1.06), "scrap")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-0.5, 0.06, 0.72), SiteLoot.RIGGED))
	p.sockets[-1].turn = -PI * 0.5
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.5, 0.06, 0.0), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-0.5, 0.06, -1.0), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-0.5, 1.18, 0.0), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.6, 0.06, -0.15), &"cache", 0.4))
	var rack := module(p, Vector3(0.5, 0.06, -0.98), true)
	var near := module(p, Vector3(-0.27, 0.06, 0.0))
	var far := module(p, Vector3(-0.72, 0.06, 0.0))
	var w := WreckPlan.new()
	w.armour = 0.6
	var plate := w.plate(Vector3(0.0, 0.3, -1.3), Vector3(1.0, 1.1, -1.26), 2, -1.0, "scrap plate")
	var locker := w.hold(Vector3(-0.98, 0.06, -0.48), Vector3(-0.06, 1.04, 0.48), 2, Vector3.RIGHT, "locker",
		"drifted in through its open side")
	w.module(rack, [[&"plate", plate]], Wreckage.ELECTRICAL, Vector3(0.78, 0.36, -0.6))
	w.module(near, [[&"hold", locker, 1]])
	w.module(far, [[&"hold", locker, 2]])
	p.wreck = w
	p.tour = PackedVector2Array([Vector2(4.0, -0.2), Vector2(1.45, -0.2), Vector2(4.0, -0.2)])
	p.approach = Vector2(5.0, -4.0)
	p.look = _nomad_rig_look
	# Its post and pennant over the dunes, and the brass on the post the sun catches.
	var c := coats()
	StructureKit.far_box(p, Vector3(-1.0, -0.06, -1.5), Vector3(1.0, 0.06, 1.5), c.teal)
	StructureKit.far_box(p, Vector3(-1.0, 0.06, -0.5), Vector3(0.0, 1.18, 0.5), c.ochre)
	StructureKit.far_box(p, Vector3(-0.56, 0.06, 0.94), Vector3(-0.44, 2.5, 1.06), c.scrap)
	StructureKit.far_box(p, Vector3(-0.5, 2.05, 1.0), Vector3(-0.49, 2.45, 1.75), c.rust)
	for k in 3:
		var a := TAU * k / 3.0
		StructureKit.glint(p, Vector3(-0.5 + cos(a) * 0.07, 2.35, 1.0 + sin(a) * 0.07), Vector3(cos(a), 0.45, sin(a)), 7.0)
	return p


static func _nomad_rig_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.02)
	# Each piece's rails round its plate, black corner caps, a hazard band at
	# its rings: three eras' make, none of them the nomads'.
	for i in 5:
		var each := p.boxes[i]
		var mid := each.get_center()
		for s in [-1.0, 1.0]:
			b.box(Vector3(1.0, 0.05, 0.05), mid + Vector3(0.0, 0.04, s * 0.475), c.rail, 0.01)
			b.box(Vector3(0.05, 0.05, 0.9), mid + Vector3(s * 0.475, 0.04, 0.0), c.rail, 0.01)
	# The torn-off piece, tipped up on its edge against the dune, its rails
	# twisted, and a dead tray under it.
	var tipped := Basis(Vector3.BACK, 0.32)
	b.box(Vector3(1.0, 0.12, 1.0), Vector3(1.65, 0.17, 1.05), c.teal, 0.02, tipped)
	b.box(Vector3(1.0, 0.05, 0.05), Vector3(1.65, 0.24, 0.57), c.rail, 0.01, tipped * Basis(Vector3.UP, 0.08))
	b.box(Vector3(0.7, 0.05, 0.7), Vector3(1.62, 0.06, 1.05), Paint.coat(Color(0.25, 0.45, 0.6), 1.0, 0.4, 0.5), 0.01, tipped)
	# Cord lashed round the rack's posts and plate, and a cloth patch tied
	# over its top against the sand.
	for u: float in [-0.035, 1.035]:
		for y: float in [0.45, 0.85]:
			b.box(Vector3(0.08, 0.04, 0.14), Vector3(u, y, -1.25), c.cord, 0.005)
	b.box(Vector3(1.0, 0.02, 0.5), Vector3(0.5, 1.21, -1.05), c.rust, 0.0, Basis(Vector3.RIGHT, 0.12))
	# The locker's frame rails at its head, cord stitching its cloth walls, a
	# rope coil hung on its corner.
	for v: float in [-0.475, 0.475]:
		b.box(Vector3(1.0, 0.05, 0.05), Vector3(-0.5, 1.035, v), c.rail, 0.008)
	for y: float in [0.3, 0.6, 0.9]:
		b.box(Vector3(0.016, 0.03, 0.9), Vector3(-1.0, y, 0.0), c.cord, 0.004)
	b.ring(0.12, 0.17, Vector3(-0.02, 0.8, 0.52), c.cord, Basis(Vector3.RIGHT, PI / 2.0), 8)
	# The post: cord wound up it, a brass fitting the mast stood in, a guy
	# cord down to the deck's corner, and the pennant still flying from it.
	for y: float in [0.6, 1.4, 2.0]:
		b.drum(0.075, 0.08, Vector3(-0.5, y, 1.0), c.cord, Basis.IDENTITY, 8)
	b.drum(0.08, 0.12, Vector3(-0.5, 2.38, 1.0), c.brass, Basis.IDENTITY, 10)
	StructureKit.rod(b, Vector3(-0.5, 2.3, 1.0), Vector3(-0.98, 0.08, 1.46), 0.015, c.cord)
	for k in 4:
		var droop := Basis(Vector3.RIGHT, 0.08 * k) * Basis(Vector3.UP, 0.06 * (k % 2))
		b.box(Vector3(0.012, 0.32 - k * 0.05, 0.2), Vector3(-0.5, 2.28 - k * 0.025, 1.12 + k * 0.19), c.rust if k % 2 == 0 else c.ochre,
			0.0, droop)
	# Tassels and a bone toggle on the locker's open side: the nomads' own.
	for k in 3:
		b.box(Vector3(0.02, 0.18, 0.02), Vector3(-0.03, 0.92, -0.3 + k * 0.3), c.ochre, 0.0)
		b.box(Vector3(0.05, 0.03, 0.03), Vector3(-0.03, 1.02, -0.3 + k * 0.3), c.bone, 0.004)
