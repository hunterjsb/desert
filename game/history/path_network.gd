class_name PathNetwork
extends RefCounted
## History's paths, as a graph on the sphere. A place is a node: a landmark,
## a settlement, a junction, a gate on the Rim. A path joins two and carries
## its kind, the eras it was used in, what ran along it and how built up it
## was. Its line is a spline kept as points at most STEP m apart with their
## running length, and nothing else is the line. Paths are never seen: they
## are where history placed things.

## What ran along a path, as bits.
const ROAD := 1
const RAIL := 2
const WATER := 4
const PIPE := 8
const POWER := 16
const TRACK := 32
## Metres between a line's points.
const STEP := 250.0
## Things placed along a path stand within this either side of it, m. Default.
const CORRIDOR := 60.0
## A wandering path bends about this often, m.
const BEND := 1500.0


class Place:
	var id: int
	var p: Vector3
	var kind: StringName
	var era: StringName
	var name: String


class Path:
	var id: int
	var a: int
	var b: int
	var kind: StringName
	## Eras it was used in, as Eras.BITS.
	var eras: int
	var carries: int
	## How built up it was, on top of the ground's richness, 0 to 1.
	var richness: float
	var seed: int
	var points := PackedVector3Array()
	## Running length at each point, m.
	var lengths := PackedFloat64Array()

	func length() -> float:
		return lengths[lengths.size() - 1]

	func used_in(era: StringName) -> bool:
		return eras & Eras.BITS[era] != 0

	## The place `s` m along it.
	func at(s: float) -> Vector3:
		var i := segment(s)
		var span := lengths[i + 1] - lengths[i]
		return points[i].slerp(points[i + 1], clampf((s - lengths[i]) / span, 0.0, 1.0) if span > 0.0 else 0.0)

	## Which way it runs `s` m along, rad clockwise from north there.
	func bearing_at(s: float) -> float:
		var i := segment(s)
		var here := at(s)
		if here.distance_squared_to(points[i + 1]) < 1e-14:
			return Sphere.bearing(points[i], points[i + 1])
		return Sphere.bearing(here, points[i + 1])

	## The stretch between two of its points that `s` m along falls in.
	func segment(s: float) -> int:
		return clampi(lengths.bsearch(s, false) - 1, 0, points.size() - 2)


var radius: float
var places: Array[Place] = []
var paths: Array[Path] = []


func _init(moon_radius: float) -> void:
	radius = moon_radius


func place(p: Vector3, kind: StringName, era: StringName, name := "") -> int:
	var made := Place.new()
	made.id = places.size()
	made.p = p.normalized()
	made.kind = kind
	made.era = era
	made.name = name
	places.append(made)
	return made.id


## A path from place a to place b. `wander` bends it off the great circle
## between them by up to that share of each stretch; colonial lines run
## straight.
func join(a: int, b: int, kind: StringName, eras: Array, carries: int, richness: float, wander: float,
		path_seed: int) -> Path:
	var made := Path.new()
	made.id = paths.size()
	made.a = a
	made.b = b
	made.kind = kind
	for era: StringName in eras:
		made.eras |= Eras.BITS[era]
	made.carries = carries
	made.richness = richness
	made.seed = path_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = path_seed
	made.points = _line(places[a].p, places[b].p, wander, rng)
	var run := 0.0
	made.lengths.append(0.0)
	for i in range(1, made.points.size()):
		run += Sphere.angle(made.points[i - 1], made.points[i]) * radius
		made.lengths.append(run)
	paths.append(made)
	return made


## The spline: control points wandered off the great circle, their corners
## cut twice on the sphere, then points at most STEP m apart.
func _line(a: Vector3, b: Vector3, wander: float, rng: RandomNumberGenerator) -> PackedVector3Array:
	var span := Sphere.angle(a, b)
	var controls: Array[Vector3] = [a]
	if wander > 0.0:
		var bends := clampi(roundi(span * radius / BEND), 1, 40)
		for i in range(1, bends):
			var on := a.slerp(b, float(i) / bends)
			var aside := rng.randf_range(-1.0, 1.0) * wander * span / bends
			controls.append(Sphere.toward(on, Sphere.bearing(on, b) + PI * 0.5, aside))
	controls.append(b)
	if controls.size() > 2:
		for cut in 2:
			var cutting: Array[Vector3] = [controls[0]]
			for i in controls.size() - 1:
				cutting.append(controls[i].slerp(controls[i + 1], 0.25))
				cutting.append(controls[i].slerp(controls[i + 1], 0.75))
			cutting.append(controls[-1])
			controls = cutting
	var out := PackedVector3Array()
	for i in controls.size() - 1:
		var steps := maxi(1, ceili(Sphere.angle(controls[i], controls[i + 1]) * radius / STEP))
		for j in steps:
			out.append(controls[i].slerp(controls[i + 1], float(j) / steps).normalized())
	out.append(controls[-1])
	return out
