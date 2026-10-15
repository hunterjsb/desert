class_name RopeStrand
extends MeshInstance3D
## The drawn rope: a hanging chain exactly as long as its rope, stepped at a
## fixed rate whatever the tick rate, so it can't overshoot at a low one. It
## sags, rests on the sand (height_at, never a raycast) and stirs in the wind.
## Held at both ends with a small sag, it hangs exactly as its rope's weight
## and pull say, so it straightens only as the load builds. It never pulls
## anything.

## Points stepped on the CPU; the shader draws a smooth curve through them.
const MAX_POINTS := 11
const SEGMENT := 0.9
const RINGS_PER_LINK := 4
const RADIUS := 0.024
const STEP := 1.0 / 60.0
const ITERATIONS := 4
## Sagging less than this share of its span it's drawn exactly as its rope
## hangs; more than the second, as a free chain; between, a blend. A chain this
## coarse can't show a sag much smaller than its links.
const HANG_TIGHT := 0.06
const HANG_LOOSE := 0.15
## How fast moving air drags slack rope to its own speed, and sand stops it, 1/s.
const AIR := 0.25
const SAND := 10.0
## How much the wind on slack rope wanders along it, as a share of its speed.
const STIR := 0.35
const SIDES := 6
## The ground under a point is read with its slope, and again only once the
## point has moved a hand's breadth; between reads it's the plane through the
## last read, true to well under a millimetre on any dune. A point further
## than CLEAR above it can't reach it within a tick, so isn't read at all,
## until it has gone REACH from the last read: past that the plane can miss a
## dune rising under it.
const RESAMPLE := 0.1
const CLEAR := 0.3
const REACH := 1.0

static var _meshes := {}
static var _shader: Shader = preload("res://game/rope/rope.gdshader")

var world: World
var length: float
## The ends it hangs from; null is a free end, after a snap or a let-go.
var a: Node3D
var b: Node3D
var points := PackedVector3Array()
var _velocity := PackedVector3Array()
var _ground := PackedFloat32Array()
var _slope := PackedVector2Array()
var _sampled := PackedVector2Array()
## How far the sand rises above the straight line between each link's two
## points at its middle: a rope lying over a crest is drawn over it. Only
## points near the sand can lie on it.
var _bulge := PackedFloat32Array()
var _near := PackedByteArray()
var _rest: float
var _phase: float
var _look: ShaderMaterial
## Hanging exactly as its rope says at the last tick, and how.
var _hanging := false
var _bow := Vector3.ZERO


func _init() -> void:
	top_level = true
	custom_aabb = AABB(Vector3(-4096, -1024, -4096), Vector3(8192, 2048, 8192))
	_look = ShaderMaterial.new()
	_look.shader = _shader
	_look.set_shader_parameter("radius", RADIUS)
	material_override = _look


## Hangs a fresh strand between two points, draped as a parabola of its
## length, in links of about SEGMENT unless told how many.
func hang(on: World, rope_length: float, end_a: Node3D, end_b: Node3D, segments := 0) -> void:
	world = on
	length = rope_length
	a = end_a
	b = end_b
	var from := a.global_position
	var to := b.global_position
	if segments <= 0:
		segments = clampi(roundi(length / SEGMENT), 3, MAX_POINTS - 1)
	var span := from.distance_to(to)
	var sag := sqrt(maxf(0.0, 3.0 * span * (length - span) / 8.0))
	points.resize(segments + 1)
	for i in segments + 1:
		var t := float(i) / segments
		var p := from.lerp(to, t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t)
		p.y = maxf(p.y, world.height_under(p) + RADIUS)
		points[i] = p
	_phase = randf() * TAU
	_fit()


## Splits at a point: this strand keeps end a, the returned one keeps end b.
func cut(at: int) -> RopeStrand:
	if points.size() < 3:
		# Too short to share: a point in the middle, so each half keeps two.
		points.insert(1, (points[0] + points[1]) * 0.5)
		_velocity.insert(1, (_velocity[0] + _velocity[1]) * 0.5)
		_rest *= 0.5
		at = 1
	at = clampi(at, 1, points.size() - 2)
	var tail := RopeStrand.new()
	tail.world = world
	tail.b = b
	tail.points = points.slice(at)
	tail._velocity = _velocity.slice(at)
	tail._phase = _phase + 1.0
	tail.length = _rest * (tail.points.size() - 1)
	tail._fit()
	points = points.slice(0, at + 1)
	_velocity = _velocity.slice(0, at + 1)
	length = _rest * (points.size() - 1)
	b = null
	_fit()
	return tail


## Draws an end exactly at a place this frame, ahead of the next tick: a held
## plug moves with your view between ticks, and the strand must meet it.
func pin(end: Node3D, at: Vector3) -> void:
	var i := 0 if a == end else (points.size() - 1 if b == end else -1)
	if i == -1:
		return
	points[i] = at
	_show()


## A line paying out: longer or shorter, with the same points.
func set_length(to: float) -> void:
	length = to
	_rest = length / (points.size() - 1)
	_look.set_shader_parameter("segment", _rest)


## Draws both ends exactly at their rings this frame; a line hanging as its
## rope says is hung again between them.
func pin_ends(at_a: Vector3, at_b: Vector3) -> void:
	var last := points.size() - 1
	points[0] = at_a
	points[last] = at_b
	if _hanging:
		for i in range(1, last):
			var p := _hung(at_a, at_b, _bow, float(i) / last)
			p.y = maxf(p.y, _floor(i, p))
			points[i] = p
	_show()


func let_go(end: Node3D) -> void:
	if a == end:
		a = null
	if b == end:
		b = null


func shift(by: Vector3) -> void:
	for i in points.size():
		points[i] += by
		# The ground read under a point stays where it was in the world.
		_sampled[i] += Vector2(by.x, by.z)


## Arc length as drawn.
func drawn_length() -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	return total


## One physics tick: wind is the felt wind at the strand, t the run time, sag
## how far its rope says its middle hangs (NAN: by its length alone).
func step(h: float, wind: Vector3, t: float, sag := NAN) -> void:
	var n := points.size()
	var last := n - 1
	var held_a := a != null
	var held_b := b != null
	var from := points[0]
	var to := points[last]
	if held_a:
		from = a.global_position
	if held_b:
		to = b.global_position
	var hung := 0.0
	var bow := Vector3.ZERO
	if held_a and held_b:
		var chord := from.distance_to(to)
		if is_nan(sag):
			sag = sqrt(maxf(0.0, 3.0 * chord * (length - chord) / 8.0))
		# It hangs across its span, so a line straight up and down shows none.
		var across := Vector3.DOWN
		if chord > 1e-4:
			var along := (to - from) / chord
			across -= along * along.dot(Vector3.DOWN)
		if across.length() > 0.05:
			bow = across.normalized() * sag
		hung = 1.0 - smoothstep(HANG_TIGHT, HANG_LOOSE, sag / maxf(chord, 1e-3))
	_hanging = hung >= 1.0
	_bow = bow
	if hung >= 1.0:
		# Hanging as its rope says, exactly: no chain to simulate.
		for i in range(1, last):
			var p := _hung(from, to, bow, float(i) / last)
			_velocity[i] = (p - points[i]) / h
			points[i] = p
		points[0] = from
		points[last] = to
		_sand(0, n)
		_show()
		return
	_sand(0, n)
	var first := 1 if held_a else 0
	var stop := last if held_b else n
	var subs := maxi(1, ceili(h / STEP - 0.001))
	var dt := h / subs
	var air := 1.0 - exp(-AIR * dt)
	var sand := exp(-SAND * dt)
	var fall := Vector3(0.0, -9.8 * dt, 0.0)
	var lift := wind.length() * 0.06
	var weight_a := 0.0 if held_a else 1.0
	var weight_b := 0.0 if held_b else 1.0
	for s in subs:
		points[0] = from
		points[last] = to
		var before := points.duplicate()
		for i in range(first, stop):
			var gust := wind * (1.0 + STIR * sin(t * 2.3 + i * 0.7 + _phase))
			gust.y = lift * sin(t * 4.1 + i * 1.3 + _phase)
			var v := _velocity[i] + fall
			points[i] += (v + (gust - v) * air) * dt
		for k in ITERATIONS:
			for j in last:
				var i := j if k % 2 == 0 else last - 1 - j
				var wa := weight_a if i == 0 else 1.0
				var wb := weight_b if i + 1 == last else 1.0
				var p0 := points[i]
				var p1 := points[i + 1]
				var link := p1 - p0
				var span := link.length()
				if span < 1e-6 or wa + wb == 0.0:
					continue
				var fix := link * ((span - _rest) / (span * (wa + wb)))
				points[i] = p0 + fix * wa
				points[i + 1] = p1 - fix * wb
		for i in range(first, stop):
			var p := points[i]
			var v := (p - before[i]) / dt
			var ground := _floor(i, p)
			if p.y <= ground:
				_near[i] = 1
				p.y = ground
				points[i] = p
				v.x *= sand
				v.z *= sand
				v.y = maxf(v.y, 0.0)
			_velocity[i] = v
		t += dt
	if hung > 0.0:
		# Nearly hanging as its rope says: drawn onto that shape.
		for i in range(1, last):
			var p := points[i].lerp(_hung(from, to, bow, float(i) / last), hung)
			p.y = maxf(p.y, _floor(i, p))
			points[i] = p
			_velocity[i] *= 1.0 - hung
	_show()


## Where the drawn tube's centre runs, t of the way along link i: the curve
## rope.gdshader draws through the points.
func drawn(i: int, t: float) -> Vector3:
	var n := points.size()
	var p0 := points[maxi(i - 1, 0)]
	var p1 := points[i]
	var p2 := points[i + 1]
	var p3 := points[mini(i + 2, n - 1)]
	var a := 2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3
	var b := -p0 + 3.0 * p1 - 3.0 * p2 + p3
	var p := 0.5 * (2.0 * p1 + (p2 - p0) * t + a * t * t + b * t * t * t)
	p.y = maxf(p.y, lerpf(p1.y, p2.y, t) + _bulge[i] * 4.0 * t * (1.0 - t))
	return p


## Hands the points to the shader, with how the sand bulges under each link:
## estimated from the ground read under its two points, whose planes overshoot
## a crest's middle by as much as the straight line between them undershoots it.
func _show() -> void:
	for i in points.size() - 1:
		_bulge[i] = 0.0
		if _near[i] == 0 or _near[i + 1] == 0:
			continue
		var p1 := points[i]
		var p2 := points[i + 1]
		var middle := (p1 + p2) * 0.5
		var planes := (_floor(i, middle) + _floor(i + 1, middle)) * 0.5
		var straight := (_floor(i, p1) + _floor(i + 1, p2)) * 0.5
		_bulge[i] = maxf(0.0, (planes + straight) * 0.5 - middle.y)
	_look.set_shader_parameter("points", points)
	_look.set_shader_parameter("bulge", _bulge)


## A point along a line hanging between two ends: the shallow catenary, a parabola.
static func _hung(from: Vector3, to: Vector3, bow: Vector3, t: float) -> Vector3:
	return from.lerp(to, t) + bow * 4.0 * t * (1.0 - t)


## Keeps points from first to stop on or above the sand, reading the ground
## under them only as RESAMPLE and CLEAR say: reading it is the costly part.
func _sand(first: int, stop: int) -> void:
	var ox := world.world_x(0.0)
	var oz := world.world_z(0.0)
	for i in range(first, stop):
		var p := points[i]
		var at := Vector2(p.x, p.z)
		var moved := at.distance_to(_sampled[i])
		_near[i] = 0
		if moved > RESAMPLE:
			if moved < REACH and is_finite(_ground[i]) and p.y > _ground[i] + _slope[i].length() * moved + CLEAR:
				continue
			var x := p.x + ox
			var z := p.z + oz
			var h := world.height_at(x, z)
			_ground[i] = h + RADIUS
			_slope[i] = Vector2(world.height_at(x + RESAMPLE, z) - h, world.height_at(x, z + RESAMPLE) - h) / RESAMPLE
			_sampled[i] = at
		var ground := _floor(i, p)
		_near[i] = 1 if p.y < ground + CLEAR else 0
		if p.y < ground:
			p.y = ground
			points[i] = p


## How high the tube's centre must stay over the sand under a point here.
func _floor(i: int, p: Vector3) -> float:
	return _ground[i] + _slope[i].dot(Vector2(p.x, p.z) - _sampled[i])


func _fit() -> void:
	var n := points.size()
	_rest = length / (n - 1)
	_velocity.resize(n)
	_ground.resize(n)
	_slope.resize(n)
	_sampled.resize(n)
	# Unread: the first tick reads the ground under every point.
	_ground.fill(INF)
	_slope.fill(Vector2.ZERO)
	_sampled.fill(Vector2(INF, INF))
	_bulge.resize(n - 1)
	_bulge.fill(0.0)
	_near.resize(n)
	_near.fill(0)
	mesh = _tube(n)
	_look.set_shader_parameter("count", n)
	_look.set_shader_parameter("segment", _rest)
	_look.set_shader_parameter("points", points)
	_look.set_shader_parameter("bulge", _bulge)


## A tube through `count` points; each ring carries where along the points it
## sits, and the shader places it on the curve through them.
static func _tube(count: int) -> ArrayMesh:
	if _meshes.has(count):
		return _meshes[count]
	var rings := (count - 1) * RINGS_PER_LINK + 1
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for r in rings:
		for s in SIDES + 1:
			vertices.append(Vector3.ZERO)
			uvs.append(Vector2(float(s) / SIDES, float(r) / RINGS_PER_LINK))
	for r in rings - 1:
		for s in SIDES:
			var i := r * (SIDES + 1) + s
			var j := i + SIDES + 1
			indices.append_array([i, i + 1, j, i + 1, j + 1, j])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var tube := ArrayMesh.new()
	tube.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[count] = tube
	return tube
