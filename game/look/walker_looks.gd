class_name WalkerLooks
extends RefCounted
## The Walker in the colonial survey style (art direction, shape by era):
## Tilg's survey walker, rounded rectangles and chamfered modular panels in
## off-white over grey alloy, safety orange at its corners and joints, its
## consignment stencil and unit number on its flank. Centuries out: one leg
## snapped short and dragged, a flank panel gone to its frame, its mast bent.
## Its front is -Z, its hips at y 0.

const OFF_WHITE := Color(0.84, 0.82, 0.76)
const ORANGE := Color(0.9, 0.42, 0.1)
## The hull's size, and how far its belly hangs under the hips, m.
const HULL := Vector3(1.4, 0.8, 2.8)
const BELLY := 0.25
## The legs' upper and lower lengths, m.
const UPPER := 1.15
const LOWER := 1.55
## The broken leg's lower, snapped short.
const STUMP := 0.7
## Where the mast stands and how tall, m; it kinks this far up, this much.
const MAST_AT := Vector3(0.0, 0.0, 0.75)
const MAST := 1.9
const KINK := 0.9
const KINK_TURN := 0.22
## The data port on its right flank, out along +X.
const PORT := Vector3(0.73, 0.25, -0.1)

static var _made := {}


static func _coats() -> Dictionary:
	return {"white": Paint.coat(OFF_WHITE, 1.0, 0.0, 0.55), "grey": Paint.coat(Paint.GUNMETAL, 0.8, 0.6, 0.45),
		"steel": Paint.coat(Paint.STEEL, 0.5, 0.85, 0.35), "orange": Paint.coat(ORANGE, 0.9, 0.0, 0.5),
		"black": Paint.coat(Paint.BLACK, 0.3, 0.2, 0.6), "lens": Paint.coat(Color(1.0, 0.6, 0.2), 0.0, 0.0, 0.3, 0.0, 2.0)}


## The hull, its head, mast and hips, in one mesh.
static func hull() -> ArrayMesh:
	if _made.has(&"hull"):
		return _made[&"hull"]
	var c := _coats()
	var b := Paint.Pieces.new()
	var h := HULL * 0.5
	var y := BELLY * 0.5
	# The belly pan in grey, the panelled shell over it.
	b.box(Vector3(HULL.x - 0.12, BELLY, HULL.z - 0.2), Vector3(0.0, -BELLY * 0.5, 0.0), c.grey, 0.04)
	b.box(Vector3(HULL.x, HULL.y - BELLY, HULL.z), Vector3(0.0, y + (HULL.y - BELLY) * 0.5 - 0.1, 0.0), c.white, 0.09)
	# Modular panels proud of the shell, a seam between each; the left's
	# middle one gone to its frame.
	for side in [-1, 1]:
		for k in 3:
			var z := (k - 1) * 0.86
			if side < 0 and k == 1:
				b.box(Vector3(0.04, 0.32, 0.7), Vector3(side * (h.x - 0.005), 0.2, z), c.black, 0.005)
				for bar in 3:
					b.box(Vector3(0.05, 0.04, 0.72), Vector3(side * (h.x + 0.005), 0.06 + bar * 0.14, z), c.grey, 0.008)
				continue
			b.box(Vector3(0.03, 0.34, 0.78), Vector3(side * (h.x + 0.01), 0.2, z), c.white, 0.012)
	for k in 2:
		b.box(Vector3(HULL.x - 0.2, 0.025, 1.2), Vector3(0.0, HULL.y - BELLY + 0.05, (k - 0.5) * 1.3), c.white, 0.01)
	# Safety orange on its corner caps.
	for x in [-1, 1]:
		for z in [-1, 1]:
			b.box(Vector3(0.18, 0.5, 0.18), Vector3(x * (h.x - 0.06), 0.18, z * (h.z - 0.06)), c.orange, 0.04)
	# Its consignment stencil and unit number on the right flank, under the port.
	b.stamp(Paint.Mark.CONSIGNMENT, Vector3(h.x + 0.03, 0.3, 0.6), 0.44, Basis(Vector3.UP, PI * 0.5), Paint.Ink.DARK, 2)
	b.box(Vector3(0.02, 0.3, 0.6), Vector3(h.x + 0.02, 0.3, 0.6), c.white, 0.004)
	var flank := Basis(Vector3.UP, PI * 0.5)
	b.numeral("05", Vector3(h.x + 0.035, 0.31, -0.65), 0.2, c.black, flank, 0.004)
	# The port's orange ring, where a Console plugs in.
	b.ring(0.05, 0.075, PORT + Vector3(0.0, 0.0, 0.0), c.orange, Basis(Vector3.BACK, PI * 0.5), 12)
	b.box(Vector3(0.03, 0.16, 0.16), PORT - Vector3(0.012, 0.0, 0.0), c.black, 0.01)
	# Its head: the survey block out front, a lens strip lit across it.
	b.box(Vector3(1.0, 0.42, 0.42), Vector3(0.0, 0.25, -h.z - 0.12), c.white, 0.08)
	b.box(Vector3(0.78, 0.07, 0.03), Vector3(0.0, 0.3, -h.z - 0.335), c.lens, 0.005)
	b.box(Vector3(1.04, 0.06, 0.36), Vector3(0.0, 0.03, -h.z - 0.12), c.orange, 0.01)
	# The mast, bent part way up, a dish on it and the cups on top.
	var top := Vector3(MAST_AT.x, HULL.y - BELLY + 0.06, MAST_AT.z)
	b.drum(0.1, 0.1, top + Vector3(0.0, 0.05, 0.0), c.grey, Basis.IDENTITY, 12)
	b.drum(0.035, KINK, top + Vector3(0.0, KINK * 0.5, 0.0), c.steel, Basis.IDENTITY, 8)
	var bend := Basis(Vector3.RIGHT, KINK_TURN)
	var knee := top + Vector3(0.0, KINK, 0.0)
	b.drum(0.03, MAST - KINK, knee + bend * Vector3(0.0, (MAST - KINK) * 0.5, 0.0), c.steel, bend, 8)
	b.ball(0.045, knee, c.orange)
	var dish := knee + bend * Vector3(0.0, 0.25, 0.0)
	b.drum(0.22, 0.04, dish + Vector3(0.0, 0.0, -0.12), c.white, Basis(Vector3.RIGHT, PI * 0.5 - 0.3), 16, 0.12)
	var head := knee + bend * Vector3(0.0, MAST - KINK, 0.0)
	for i in 3:
		var arm := Basis(Vector3.UP, i * TAU / 3.0)
		b.box(Vector3(0.008, 0.008, 0.16), head + arm * Vector3(0.0, 0.0, 0.08), c.steel, 0.0, arm)
		b.ball(0.035, head + arm * Vector3(0.0, 0.0, 0.16), c.grey)
	# A hip drum for each leg along its flanks.
	for hip in hips():
		b.drum(0.13, 0.16, hip, c.grey, Basis(Vector3.BACK, PI * 0.5), 12)
		b.ring(0.11, 0.14, hip + Vector3(signf(hip.x) * 0.07, 0.0, 0.0), c.orange, Basis(Vector3.BACK, PI * 0.5), 10)
	_made[&"hull"] = b.commit()
	return _made[&"hull"]


## A leg's upper segment along +Y from its hip, `long` m.
static func upper() -> ArrayMesh:
	return _segment(&"upper", UPPER, 0.13, true)


static func lower() -> ArrayMesh:
	return _segment(&"lower", LOWER, 0.08, false)


## The broken leg's lower: snapped, its end ragged.
static func stump() -> ArrayMesh:
	return _segment(&"stump", STUMP, 0.08, false, true)


static func _segment(key: StringName, long: float, wide: float, banded: bool, snapped := false) -> ArrayMesh:
	if _made.has(key):
		return _made[key]
	var c := _coats()
	var b := Paint.Pieces.new()
	b.box(Vector3(wide, long, wide * 1.2), Vector3(0.0, long * 0.5, 0.0), c.grey, wide * 0.25)
	b.box(Vector3(wide * 0.5, long * 0.8, wide * 1.3), Vector3(0.0, long * 0.5, 0.0), c.steel, 0.006)
	if banded:
		b.box(Vector3(wide + 0.02, 0.1, wide * 1.2 + 0.02), Vector3(0.0, long * 0.15, 0.0), c.orange, 0.01)
		b.ball(wide * 0.7, Vector3(0.0, long, 0.0), c.grey)
	elif snapped:
		for i in 3:
			b.box(Vector3(wide * 0.4, 0.12, wide * 0.5), Vector3((i - 1) * wide * 0.3, long + 0.03 * i, 0.0), c.steel,
				0.002, Basis(Vector3.BACK, (i - 1) * 0.4))
	else:
		b.drum(wide * 1.4, 0.06, Vector3(0.0, long, 0.0), c.black, Basis.IDENTITY, 10)
	_made[key] = b.commit()
	return _made[key]


## Where each leg's hip is on the hull: three a side, front to back, right first.
static func hips() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for side in [1, -1]:
		for k in 3:
			out.append(Vector3(side * (HULL.x * 0.5 + 0.08), 0.0, (k - 1) * 1.05))
	return out


## Its stand-in far off (Skyline's rules): a few boxes at its own size in its
## coats, as [size, middle, colour, metal, rough], its hips at y 0 over sand
## `stand` m below them.
static func far(stand: float) -> Array:
	return [[Vector3(HULL.x, HULL.y, HULL.z + 0.5), Vector3(0.0, 0.15, -0.2), OFF_WHITE, 0.0, 0.55],
		[Vector3(0.06, MAST, 0.06), Vector3(0.0, HULL.y - BELLY + MAST * 0.5, MAST_AT.z), Paint.STEEL, 0.85, 0.35],
		[Vector3(HULL.x + 1.8, 0.12, 0.12), Vector3(0.0, -stand * 0.5, -1.05), Paint.GUNMETAL, 0.6, 0.45],
		[Vector3(HULL.x + 1.8, 0.12, 0.12), Vector3(0.0, -stand * 0.5, 0.0), Paint.GUNMETAL, 0.6, 0.45],
		[Vector3(0.12, stand, HULL.z * 0.8), Vector3(HULL.x * 0.5 + 0.8, -stand * 0.5, 0.0), Paint.GUNMETAL, 0.6, 0.45],
		[Vector3(0.12, stand, HULL.z * 0.8), Vector3(-HULL.x * 0.5 - 0.8, -stand * 0.5, 0.2), Paint.GUNMETAL, 0.6, 0.45]]

