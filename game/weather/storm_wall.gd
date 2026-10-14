class_name StormWall
extends MeshInstance3D
## The crude wall: a dark curtain standing on the front. Rays march out from
## the player to where the storm field crosses zero. A few rays are resampled
## each physics frame, and each remembers where and when it was cast, so the
## curtain is always the field's own answer.

## Per ray: metres from its origin to the front, -1 if there's none within
## reach, 0 if the origin was already inside a storm.
var distances := PackedFloat64Array()
var origins_x := PackedFloat64Array()
var origins_z := PackedFloat64Array()
var cast_at := PackedFloat64Array()

var _world: World
var _field: WeatherField
var _tuning: Tuning
var _next := 0
var _material := ShaderMaterial.new()


func setup(world: World, field: WeatherField) -> void:
	_world = world
	_field = field
	_tuning = world.tuning
	var count := _tuning.wall_directions
	for array in [distances, origins_x, origins_z, cast_at]:
		array.resize(count)
	distances.fill(-1.0)
	_material.shader = preload("res://game/weather/storm_wall.gdshader")
	_material.set_shader_parameter("reach", _tuning.wall_reach)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The curtain is rebuilt round the player and is never small enough to cull.
	extra_cull_margin = 16384.0
	world.origin_shifted.connect(func(_by: Vector2i) -> void: rebuild())


## Recasts the next few rays from the player, then redraws.
func step(x: float, z: float, t: float) -> void:
	for i in _tuning.wall_directions_per_frame:
		_cast(_next, x, z, t)
		_next = (_next + 1) % distances.size()
	rebuild()


func ray(i: int) -> Vector2:
	return Vector2.from_angle(TAU * i / distances.size())


## Where ray i met the front, in world metres.
func front_point(i: int) -> Vector2:
	return Vector2(origins_x[i], origins_z[i]) + ray(i) * distances[i]


func set_light(brightness: float, color: Color) -> void:
	_material.set_shader_parameter("color", color * brightness)


func _cast(i: int, x: float, z: float, t: float) -> void:
	origins_x[i] = x
	origins_z[i] = z
	cast_at[i] = t
	if _field.raw_storm_at(x, z, t) > 0.0:
		distances[i] = 0.0
		return
	var dir := ray(i)
	var step_length := _tuning.wall_march_step
	var d := step_length
	while d <= _tuning.wall_reach:
		if _field.raw_storm_at(x + dir.x * d, z + dir.y * d, t) > 0.0:
			var lo := d - step_length
			while d - lo > 0.5:
				var mid := (lo + d) * 0.5
				if _field.raw_storm_at(x + dir.x * mid, z + dir.y * mid, t) > 0.0:
					d = mid
				else:
					lo = mid
			distances[i] = d
			return
		d += step_length
	distances[i] = -1.0


## Neighbouring rays are joined only where they plausibly hit the same front,
## and each run of joined rays fades out over its end steps, so the curtain
## never ends in a hard edge.
func rebuild() -> void:
	var count := distances.size()
	var joined: Array[bool] = []
	for i in count:
		var a := distances[i]
		var b := distances[(i + 1) % count]
		joined.append(a > 0.0 and b > 0.0 and absf(a - b) <= maxf(300.0, 0.35 * minf(a, b)))
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var up := Vector3(0.0, _tuning.wall_height, 0.0)
	for i in count:
		if not joined[i]:
			continue
		var j := (i + 1) % count
		var bottom_a := _base(front_point(i))
		var bottom_b := _base(front_point(j))
		var u_a := float(i) / count * 40.0
		var u_b := float(i + 1) / count * 40.0
		var fade_a := Color(1, 1, 1, 1.0 if joined[(i - 1 + count) % count] else 0.0)
		var fade_b := Color(1, 1, 1, 1.0 if joined[j] else 0.0)
		vertices.append_array([bottom_a, bottom_b, bottom_b + up, bottom_a, bottom_b + up, bottom_a + up])
		uvs.append_array([Vector2(u_a, 0), Vector2(u_b, 0), Vector2(u_b, 1), Vector2(u_a, 0),
			Vector2(u_b, 1), Vector2(u_a, 1)])
		colors.append_array([fade_a, fade_b, fade_b, fade_a, fade_b, fade_a])
	if vertices.is_empty():
		mesh = null
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	var built := ArrayMesh.new()
	built.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	built.surface_set_material(0, _material)
	mesh = built


## The curtain's foot sits a little into the sand so no gap shows under it.
func _base(point: Vector2) -> Vector3:
	return Vector3(_world.engine_x(point.x), _world.height_at(point.x, point.y) - 5.0,
		_world.engine_z(point.y))
