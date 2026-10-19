class_name NomadLooks
extends RefCounted
## The nomads' own gear in their coats (Dress): made from what's left, and
## kept. Saltbush wood and fern cord, dyed cloth faded by the sun (ochre,
## rust and an indigo gone grey), bone toggles, and scrap from every era
## lashed in where it fits. Their rigs and camps use the same coats.

const OCHRE := Color(0.72, 0.52, 0.24)
const RUST := Color(0.56, 0.24, 0.14)
const INDIGO := Color(0.28, 0.32, 0.42)
const WOOD := Color(0.62, 0.5, 0.34)
const CORD := Color(0.42, 0.31, 0.2)
const BONE := Color(0.86, 0.82, 0.7)

static var _cloth: ArrayMesh
static var _ladder: ArrayMesh


static func coats() -> Dictionary:
	return {"ochre": Paint.coat(OCHRE, 1.2, 0.0, 0.95, 1.2), "rust": Paint.coat(RUST, 1.2, 0.0, 0.95, 1.2),
		"indigo": Paint.coat(INDIGO, 1.2, 0.0, 0.95, 1.2), "wood": Paint.coat(WOOD, 1.0, 0.0, 0.85),
		"cord": Paint.coat(CORD, 0.6, 0.0, 0.95), "bone": Paint.coat(BONE, 0.6, 0.0, 0.7),
		"scrap": Paint.coat(Paint.GUNMETAL.darkened(0.1), 1.4, 0.6, 0.6), "brass": Paint.coat(Paint.BRASS, 0.6, 0.9, 0.35)}


## Draws a nomad thing's look into its pieces; false for an id that isn't one.
static func frame(b: Paint.Pieces, id: StringName, size: Vector3) -> bool:
	match id:
		&"streamer":
			_wand(b, size)
		&"crows_nest":
			_nest(b, size)
		_:
			return false
	return true


## One piece of a streamer's cloth: a strip along its own y, centred.
static func cloth() -> ArrayMesh:
	if _cloth == null:
		var b := Paint.Pieces.new()
		b.box(Vector3(Streamer.WIDE, Streamer.PIECE + 0.004, 0.004), Vector3.ZERO, coats().rust, 0.0)
		_cloth = b.commit()
	return _cloth


## A wand of saltbush wood whipped with cord, a brass ring at its tip the
## cloth is tied through, a bone toggle at its foot to clip it on.
static func _wand(b: Paint.Pieces, size: Vector3) -> void:
	var c := coats()
	var h := size * 0.5
	b.drum(0.012, size.y - 0.03, Vector3(0.0, 0.0, 0.0), c.wood, Basis.IDENTITY, 8)
	for y in [-h.y + 0.06, 0.0, h.y - 0.06]:
		b.drum(0.015, 0.03, Vector3(0.0, y, 0.0), c.cord, Basis.IDENTITY, 8)
	b.ring(0.01, 0.018, Vector3(0.0, h.y - 0.01, 0.0), c.brass, Basis(Vector3.RIGHT, PI / 2.0), 8)
	b.box(Vector3(size.x, 0.03, size.z), Vector3(0.0, -h.y + 0.015, 0.0), c.bone, 0.006)


## A lookout's basket: a floor of planks on a hoop of scrap, a rail of bent
## pipe lashed to wooden posts, cloth wound on the rail against the wind, and
## its rope ladder hung down the mast with wooden rungs.
static func _nest(b: Paint.Pieces, size: Vector3) -> void:
	var c := coats()
	var h := size * 0.5
	b.box(Vector3(size.x - 0.04, 0.05, size.z - 0.04), Vector3(0.0, -h.y + 0.025, 0.0), c.wood, 0.01)
	for i in 5:
		var z := -h.z + 0.1 + i * (size.z - 0.2) / 4.0
		b.box(Vector3(size.x - 0.06, 0.012, 0.02), Vector3(0.0, -h.y + 0.056, z), c.cord, 0.003)
	b.ring(h.x - 0.05, h.x - 0.01, Vector3(0.0, -h.y + 0.03, 0.0), c.scrap, Basis.IDENTITY, 16)
	for k in 6:
		var a := TAU * k / 6.0
		var at := Vector3(cos(a) * (h.x - 0.04), 0.0, sin(a) * (h.z - 0.04))
		b.box(Vector3(0.04, size.y - 0.06, 0.04), at, c.wood, 0.008)
		b.drum(0.025, 0.04, at + Vector3(0.0, h.y - 0.12, 0.0), c.cord, Basis.IDENTITY, 8)
	b.ring(h.x - 0.04, h.x - 0.01, Vector3(0.0, h.y - 0.04, 0.0), c.scrap, Basis.IDENTITY, 16)
	# Cloth wound round the lower rail, two colours, a windbreak at your knees.
	for k in 3:
		var a := TAU * k / 3.0 + 0.4
		var turn := Basis(Vector3.UP, -a)
		b.box(Vector3(0.7, 0.32, 0.012), turn * Vector3(0.0, -h.y + 0.25, h.z - 0.03), c.ochre if k != 1 else c.indigo,
			0.0, turn)


## Deployed only on a standing mast; loose, the basket carries its ladder folded.
static func ladder() -> ArrayMesh:
	if _ladder != null:
		return _ladder
	var b := Paint.Pieces.new()
	var c := coats()
	var top: float = -Catalog.DEVICES[&"crows_nest"].size.y * 0.5
	for x in [-0.13, 0.13]:
		b.drum(0.008, CrowsNest.LADDER, Vector3(x, top - CrowsNest.LADDER * 0.5, -0.15), c.cord, Basis.IDENTITY, 6)
	var rungs := floori(CrowsNest.LADDER / 0.32)
	for i in rungs:
		b.box(Vector3(0.3, 0.025, 0.03), Vector3(0.0, top - 0.2 - i * 0.32, -0.15), c.wood, 0.004)
	_ladder = b.commit()
	return _ladder
