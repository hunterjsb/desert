class_name NomadLooks
extends RefCounted
## The nomads' own gear in their coats (Dress): made from what's left, and
## kept. Saltbush wood and fern cord, dyed cloth faded by the sun (ochre,
## rust and an indigo gone grey), bone toggles, and scrap from every era
## lashed in where it fits. Their rigs and camps use the same coats.

static var _cloth: ArrayMesh
static var _ladder: ArrayMesh


static func coats() -> Dictionary:
	return {"ochre": Paint.coat(Paint.OCHRE_DYE, 1.2, 0.0, 0.95, 1.2), "rust": Paint.coat(Paint.RUST_DYE, 1.2, 0.0, 0.95, 1.2),
		"indigo": Paint.coat(Paint.INDIGO_DYE, 1.2, 0.0, 0.95, 1.2), "wood": Paint.coat(Paint.NOMAD_WOOD, 1.0, 0.0, 0.85),
		"cord": Paint.coat(Paint.ROPE, 0.6, 0.0, 0.95), "bone": Paint.coat(Paint.NOMAD_BONE, 0.6, 0.0, 0.7),
		"scrap": Paint.coat(Paint.GUNMETAL.darkened(0.1), 1.4, 0.6, 0.6), "brass": Paint.coat(Paint.BRASS, 0.6, 0.9, 0.35)}


## One piece of a streamer's cloth: a strip along its own y, centred.
static func cloth() -> ArrayMesh:
	if _cloth == null:
		var b := Paint.Pieces.new()
		b.box(Vector3(Streamer.WIDE, Streamer.PIECE + 0.004, 0.004), Vector3.ZERO, coats().rust, 0.0)
		_cloth = b.commit()
	return _cloth


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
