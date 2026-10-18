class_name GeologyKit
extends RefCounted
## The ground's own pieces: what geology leaves standing where a walker meets
## it. A live vent's mouth is a fissure along the rift, a pit with a rampart
## of dark spatter round it thrown out by its bursts, sulphur crusting its
## throat, on an apron of its own ash the dunes can't climb: the same in
## every exposure state, since a live vent keeps itself clear. It stands
## where geology put it, whatever the dunes (VentMouth); the ash fan downwind
## is the sand's look (Plume).

const BASALT := Color(0.13, 0.12, 0.12)
const SCORIA := Color(0.24, 0.13, 0.09)
const SULPHUR := Color(0.85, 0.76, 0.34)

## The mouth's plan, m: the pit's slot runs this far either way along the
## rift; its floor is this wide either side and this deep under the dunes'
## mean; the rampart's crest stands this far out and this high; its outer
## foot is here. Past the foot the dunes rise or fall from it no steeper than
## the apron's grade, and over its last stretch no steeper than sand banks,
## out to its edge, where they're their own again.
const SLOT := 6.0
const PIT := 1.5
const PIT_DEPTH := 1.2
const CREST := 9.5
const CREST_HEIGHT := 2.4
const FOOT := 18.0
const APRON := 56.0
const APRON_GRADE := 0.32
const BANK := 14.0
const BANK_GRADE := 0.6
## It looks along the rift this far either way, m, this often, for the place
## whose dunes its apron holds best.
const LOOK := 48.0
const LOOK_STEP := 12.0


## How far the dunes may stand above or below the mouth's ground `d` m from
## its slot, m.
static func band(d: float) -> float:
	var gentle := APRON - BANK
	return maxf(minf(d, gentle) - FOOT, 0.0) * APRON_GRADE + maxf(d - gentle, 0.0) * BANK_GRADE

static var _coats := {}


static func pieces() -> Array[StructureKit.Piece]:
	return [_vent_mouth()]


static func coats() -> Dictionary:
	if _coats.is_empty():
		_coats = {"basalt": Paint.coat(BASALT, 0.0, 0.0, 0.95, 0.6), "scoria": Paint.coat(SCORIA, 0.0, 0.0, 0.95, 0.5),
			"sulphur": Paint.coat(SULPHUR, 0.0, 0.0, 0.85, 0.2)}
	return _coats


## The mouth's ground over the dunes' mean, at `d` m from the slot: the pit's
## floor, up its throat to the crest and down the rampart to the dunes, every
## corner rounded, so nowhere steeper than its slopes (24° in, 16° out).
static func profile(d: float) -> float:
	var throat := -PIT_DEPTH - TerrainShape._rounded_min(0.0, -(d - PIT) * (CREST_HEIGHT + PIT_DEPTH) / (CREST - PIT), 0.8)
	var flank := CREST_HEIGHT - (d - CREST) * CREST_HEIGHT / (FOOT - CREST)
	var h := TerrainShape._rounded_min(throat, flank, 1.5)
	return TerrainShape._rounded_max0(h, 1.0) if d > CREST else h


## How far a plan point is from the slot, m.
static func from_slot(p: Vector2) -> float:
	return Vector2(p.x, maxf(absf(p.y) - SLOT, 0.0)).length()


static func _vent_mouth() -> StructureKit.Piece:
	var p := StructureKit.define(&"vent_mouth", Vector2(CREST, CREST + SLOT), Vector2.ZERO, Vector2.ZERO)
	p.builds = VentMouth
	p.apron = APRON + SLOT - Vector2(CREST, CREST + SLOT).length() + 0.5
	p.age = Vector2(0.0, 0.0)
	# Spatter on the crest, where the bursts threw it: lumps, each solid
	# inside its look.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var round := 2.0 * (SLOT * 2.0) + TAU * CREST
	var s := rng.randf() * 2.0
	while s < round:
		var at := _on_crest(s)
		var size := rng.randf_range(0.7, 1.5)
		var y := profile(from_slot(at)) - 0.25 * size
		var half := Vector3(size * 0.8, size * 0.45, size * 0.8)
		StructureKit.box(p, Vector3(at.x, y, at.y) - half, Vector3(at.x, y, at.y) + half, "")
		s += rng.randf_range(2.6, 5.0)
	p.approach = Vector2(0.0, 40.0)
	p.look = _mouth_look
	return p


## A point round the crest, `s` m from its start: along one side, round the
## far end, back along the other side and round the near end.
static func _on_crest(s: float) -> Vector2:
	var side := SLOT * 2.0
	var bend := PI * CREST
	if s < side:
		return Vector2(CREST, -SLOT + s)
	s -= side
	if s < bend:
		var a := s / CREST
		return Vector2(CREST * cos(a), SLOT + CREST * sin(a))
	s -= bend
	if s < side:
		return Vector2(-CREST, SLOT - s)
	var a := (s - side) / CREST
	return Vector2(-CREST * cos(a), -SLOT - CREST * sin(a))


static func _mouth_look(b: Paint.Pieces, p: StructureKit.Piece, _state: int) -> void:
	var c := coats()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for box in p.boxes:
		var middle := box.get_center()
		var turn := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3))
		b.ball(1.0, middle, c.basalt if rng.randf() < 0.7 else c.scoria, box.size * 0.62, turn)
	# Sulphur crusts the throat's upper slope, where the gas cools.
	for k in 9:
		var a := rng.randf() * TAU
		var d := rng.randf_range(3.5, 6.5)
		var at := Vector2(cos(a) * d, sin(a) * d)
		at.y += signf(at.y) * rng.randf() * SLOT
		var y := profile(from_slot(at))
		var down := (Vector2(at.x, signf(at.y) * maxf(absf(at.y) - SLOT, 0.0))).normalized()
		var tilt := Basis(Vector3(down.y, 0.0, -down.x).normalized(), -atan((CREST_HEIGHT + PIT_DEPTH) / (CREST - PIT)))
		b.box(Vector3(rng.randf_range(1.2, 2.4), 0.08, rng.randf_range(0.8, 1.6)), Vector3(at.x, y + 0.02, at.y),
			c.sulphur, 0.02, tilt * Basis(Vector3.UP, rng.randf() * TAU))
