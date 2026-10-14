class_name RopeStrand
extends MeshInstance3D
## The drawn rope: a hanging chain exactly as long as its rope, stepped at a
## fixed rate whatever the tick rate, so it can't overshoot at a low one. It
## sags, rests on the sand (height_at, never a raycast), stirs in the wind and
## lies straight the moment its rope is taut. It never pulls anything.

## Points stepped on the CPU; the shader draws a smooth curve through them.
const MAX_POINTS := 11
const SEGMENT := 0.9
const RINGS_PER_LINK := 4
const RADIUS := 0.024
const STEP := 1.0 / 60.0
const ITERATIONS := 4
## Real rope sags a long way until its last percent of slack, then goes
## straight; this is that last share, over which the drawn rope straightens.
const TAUT_BAND := 0.012
## How fast moving air drags slack rope to its own speed, and sand stops it, 1/s.
const AIR := 0.25
const SAND := 10.0
## How much the wind on slack rope wanders along it, as a share of its speed.
const STIR := 0.35
const SIDES := 6

static var _meshes := {}
static var _shader: Shader = preload("res://look/rope/rope.gdshader")

var world: World
var length: float
## The ends it hangs from; null is a free end, after a snap or a let-go.
var a: Node3D
var b: Node3D
var points := PackedVector3Array()
var _velocity := PackedVector3Array()
var _ground := PackedFloat32Array()
var _sampled := PackedVector2Array()
var _rest: float
var _phase: float
var _look: ShaderMaterial


func _init() -> void:
	top_level = true
	custom_aabb = AABB(Vector3(-4096, -1024, -4096), Vector3(8192, 2048, 8192))
	_look = ShaderMaterial.new()
	_look.shader = _shader
	_look.set_shader_parameter("radius", RADIUS)
	material_override = _look


## Hangs a fresh strand between two points, draped as a parabola of its length.
func hang(on: World, rope_length: float, end_a: Node3D, end_b: Node3D) -> void:
	world = on
	length = rope_length
	a = end_a
	b = end_b
	var from := a.global_position
	var to := b.global_position
	var segments := clampi(roundi(length / SEGMENT), 3, MAX_POINTS - 1)
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


func let_go(end: Node3D) -> void:
	if a == end:
		a = null
	if b == end:
		b = null


func shift(by: Vector3) -> void:
	for i in points.size():
		points[i] += by


## Arc length as drawn.
func drawn_length() -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	return total


## One physics tick: wind is the felt wind at the strand, t the run time.
func step(h: float, wind: Vector3, t: float) -> void:
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
	var straight := 0.0
	if held_a and held_b:
		straight = smoothstep(length * (1.0 - TAUT_BAND), length, from.distance_to(to))
	if straight >= 1.0:
		# Taut is straight, exactly: no chain to simulate.
		for i in range(1, last):
			var p := from.lerp(to, float(i) / last)
			_velocity[i] = (p - points[i]) / h
			points[i] = p
		points[0] = from
		points[last] = to
		_sand(0, n)
		_look.set_shader_parameter("points", points)
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
			if p.y <= _ground[i]:
				p.y = _ground[i]
				points[i] = p
				v.x *= sand
				v.z *= sand
				v.y = maxf(v.y, 0.0)
			_velocity[i] = v
		t += dt
	if straight > 0.0:
		# Within the last of its slack it is drawn onto the line between its ends.
		for i in range(1, last):
			var p := points[i].lerp(from.lerp(to, float(i) / last), straight)
			p.y = maxf(p.y, _ground[i])
			points[i] = p
			_velocity[i] *= 1.0 - straight
	_look.set_shader_parameter("points", points)


## Keeps points from first to stop on or above the sand. The ground is read
## again only under points near it that have moved, since reading it is the
## costly part and rope high in the air can't reach it within a tick.
func _sand(first: int, stop: int) -> void:
	var ox := world.world_x(0.0)
	var oz := world.world_z(0.0)
	for i in range(first, stop):
		var p := points[i]
		if p.y > _ground[i] + 0.3:
			continue
		var at := Vector2(p.x, p.z)
		if at.distance_squared_to(_sampled[i]) > 0.0004:
			_ground[i] = world.height_at(p.x + ox, p.z + oz) + RADIUS
			_sampled[i] = at
		if p.y < _ground[i]:
			p.y = _ground[i]
			points[i] = p


func _fit() -> void:
	var n := points.size()
	_rest = length / (n - 1)
	_velocity.resize(n)
	_ground.resize(n)
	_sampled.resize(n)
	# Unread: the first tick reads the ground under every point.
	_ground.fill(INF)
	_sampled.fill(Vector2(INF, INF))
	mesh = _tube(n)
	_look.set_shader_parameter("count", n)
	_look.set_shader_parameter("segment", _rest)
	_look.set_shader_parameter("points", points)


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
