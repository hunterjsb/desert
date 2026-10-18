class_name Geology
extends RefCounted
## Zan's ground as the tides left it, made once a run from the seed before the
## colonial layer reads it. The heat peaks at the two tidal bulges, so it holds
## what the landmarks there stand on: Halloran's rift across the axis near the
## point under Tu, its vents, and the far-side volcano's summit vent, capped by
## the elevator's anchor. The colony tapped the rift's vents that were live
## then; at the fall the heat moved on along the rift, past where the pipes
## reached, and one vent there is live still. Its own streams, so drawing
## anything here never moves history; and what a vent is doing at a moment is
## a pure function of the time, as the weather is.

## The rift runs this far either way along its floor from Aitch, m (default).
const REACH := Vector2(8000.0, 11000.0)
## Its floor's half-width, and how far its walls climb from its middle, m:
## Aitch's floor is 600 m across and the black site is in the wall (default).
const FLOOR := 300.0
const WALLS := 1600.0
## Its floor's line is kept as points no further apart than this, m.
const STEP := 250.0
## The vents the colony tapped, one each way, m along the floor from Aitch
## (default, the vent stations' old rule).
const TAPPED := Vector2(1500.0, 3000.0)
## The live vent, m along the floor one way: past the farthest pipe (default).
const LIVE := Vector2(5000.0, 7500.0)
## A live vent seeps, breathing over these two periods, s, by this share.
const BREATH := Vector3(170.0, 410.0, 0.2)
## It bursts: each slot of this many s holds one this often, at a time the
## slot draws. A burst rises over the first s, holds the second and fades by e
## every third, at this many times the seep, least and most (defaults).
const BURST_SLOT := 1800.0
const BURST_ODDS := 0.55
const BURST_SHAPE := Vector3(25.0, 40.0, 180.0)
const BURST_SIZE := Vector2(4.0, 7.0)
## The share of what it carries that's ash: seeping, and at a burst's peak.
const ASH := Vector2(0.2, 0.85)
## Lava cooled in the old field stays magnetized: the rift's dykes, across its
## walls and fading this far past its ends, m, and the far-side volcano's
## flows over its footprint, gone by this far from its summit, m (defaults).
const MAGNETIC_ENDS := 2000.0
const VOLCANO := Vector2(3000.0, 6000.0)

enum { TAPPED_VENT, LIVE_VENT, CAPPED_VENT }

var radius: float
## The rift floor's middle line, from one end to the other, through Aitch.
var rift := PackedVector3Array()
## Its bearing at Aitch, rad clockwise from north.
var rift_bearing: float
## Each vent: {id, name, state, p, bearing (along the rift there, rad), along
## (m from Aitch, signed), seed}. The tapped ones first, in the order history
## builds their stations.
var vents: Array[Dictionary] = []

var _seed: int
var _bursts := {}
## The rift's great circle: its pole, its middle at Aitch, and how far it runs
## each way from there, m; and the volcano's summit.
var _pole: Vector3
var _middle: Vector3
var _ends: Vector2
var _summit: Vector3


## From the seed and the landmarks it explains: Halloran's (its heading is
## the rift's, Aitch on its floor) and the observatory's.
func _init(run_seed: int, moon_radius: float, halloran: Dictionary, observatory: Dictionary) -> void:
	_seed = run_seed
	radius = moon_radius
	var aitch: Vector3 = _part(halloran, &"aitch")
	rift_bearing = halloran.bearing
	var rng := _stream(["rift"])
	var ends := Vector2(rng.randf_range(REACH.x, REACH.y), rng.randf_range(REACH.x, REACH.y))
	var count := ceili((ends.x + ends.y) / STEP)
	for k in count + 1:
		rift.append(_on_rift(aitch, lerpf(-ends.y, ends.x, float(k) / count)))
	_middle = aitch
	_ends = ends
	_pole = rift[0].cross(rift[rift.size() - 1]).normalized()
	_summit = observatory.p
	var taps := _stream(["tapped"])
	for way in [1.0, -1.0]:
		_vent(&"tapped_vent" if way > 0.0 else &"tapped_vent_2", "a tapped vent", TAPPED_VENT, aitch,
			way * taps.randf_range(TAPPED.x, TAPPED.y))
	var live := _stream(["live"])
	var side := 1.0 if live.randf() < 0.5 else -1.0
	_vent(&"live_vent", "the rift's live vent", LIVE_VENT, aitch,
		side * minf(live.randf_range(LIVE.x, LIVE.y), (ends.x if side > 0.0 else ends.y) - FLOOR))
	vents.append({"id": &"vent_cap", "name": "the volcano's capped summit vent", "state": CAPPED_VENT,
		"p": _part(observatory, &"vent_cap"), "bearing": 0.0, "along": 0.0, "seed": hash([_seed, "geology", "cap"])})


## How strongly magnetized the crust is at a place, 0 to 1: the rift's dykes
## and the far-side volcano's flows, cooled in the old field; 0 on ordinary
## ground. What a compass's needle feels off true.
func magnetized(p: Vector3) -> float:
	var across := asin(clampf(p.dot(_pole), -1.0, 1.0)) * radius
	var flat := (p - _pole * p.dot(_pole)).normalized()
	var along := atan2(flat.dot(_pole.cross(_middle)), flat.dot(_middle)) * radius
	var past := maxf(along - _ends.x, -along - _ends.y)
	var rift_rock := exp(-pow(across / WALLS, 2.0)) * exp(-pow(maxf(past, 0.0) / MAGNETIC_ENDS, 2.0))
	var lavas := 1.0 - smoothstep(VOLCANO.x, VOLCANO.y, Sphere.angle(p, _summit) * radius)
	return maxf(rift_rock, lavas)


func live() -> Array[Dictionary]:
	return vents.filter(func(v: Dictionary) -> bool: return v.state == LIVE_VENT)


func tapped() -> Array[Dictionary]:
	return vents.filter(func(v: Dictionary) -> bool: return v.state == TAPPED_VENT)


## How a vent is venting at world time t: how hard, as a share of its seep
## (a live one breathes round 1 and bursts; a quiet or capped one, none), and
## the share of ash in what it carries, more the harder it bursts.
func venting(each: Dictionary, t: float) -> Vector2:
	if each.state != LIVE_VENT:
		return Vector2.ZERO
	var phase := float(each.seed & 0xffff) / 65536.0 * TAU
	var breath := 1.0 + BREATH.z * 0.5 * (sin(TAU * t / BREATH.x + phase) + sin(TAU * t / BREATH.y + phase * 1.7))
	var over := _burst(each, t)
	return Vector2(breath + over, lerpf(ASH.x, ASH.y, clampf(over / (BURST_SIZE.x - 1.0), 0.0, 1.0)))


## When a vent's next burst begins after t, world s; INF if it never does.
func next_burst(each: Dictionary, t: float) -> float:
	if each.state != LIVE_VENT:
		return INF
	var slot := floori(t / BURST_SLOT)
	for k in range(slot, slot + 64):
		var at := _burst_at(each, k)
		if at.y > 0.0 and at.x > t:
			return at.x
	return INF


## A burst's push over the seep at t: the slot it's in and the one before,
## whose fade may run on into it.
func _burst(each: Dictionary, t: float) -> float:
	var slot := floori(t / BURST_SLOT)
	var over := 0.0
	for k in [slot - 1, slot]:
		var at := _burst_at(each, k)
		var since := t - at.x
		if at.y <= 0.0 or since < 0.0:
			continue
		var rise := smoothstep(0.0, BURST_SHAPE.x, since)
		over += (at.y - 1.0) * rise * exp(-maxf(since - BURST_SHAPE.x - BURST_SHAPE.y, 0.0) / BURST_SHAPE.z)
	return over


## Slot k's burst: when it begins and how big, or none (0). Drawn once.
func _burst_at(each: Dictionary, k: int) -> Vector2:
	var key: int = ((each.seed & 0xffffffff) << 24) ^ (k & 0xffffff)
	var known: Variant = _bursts.get(key)
	if known != null:
		return known
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([each.seed, "burst", k])
	var when := (k + rng.randf()) * BURST_SLOT
	var size := rng.randf_range(BURST_SIZE.x, BURST_SIZE.y)
	var made := Vector2(when, size if rng.randf() < BURST_ODDS else 0.0)
	if _bursts.size() > 256:
		_bursts.clear()
	_bursts[key] = made
	return made


func _vent(id: StringName, name: String, state: int, aitch: Vector3, along: float) -> void:
	var p := _on_rift(aitch, along)
	vents.append({"id": id, "name": name, "state": state, "p": p,
		"bearing": Sphere.bearing(p, _on_rift(aitch, along + 1.0)), "along": along,
		"seed": hash([_seed, "geology", id])})


## The point `along` m down the floor's line from Aitch: a great circle.
func _on_rift(aitch: Vector3, along: float) -> Vector3:
	return Sphere.toward(aitch, rift_bearing, along / radius)


static func _part(landmark: Dictionary, id: StringName) -> Vector3:
	for part: Dictionary in landmark.parts:
		if part.id == id:
			return part.p
	return landmark.p


func _stream(parts: Array) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_seed, "geology"] + parts)
	return rng
