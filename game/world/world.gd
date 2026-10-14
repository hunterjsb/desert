class_name World
extends Node3D
## Where everything is. Owns the run's seed, the ground's one function, the
## floating origin and the player's point on the moon. Positions in the engine
## stay within a few hundred metres of the origin; true world coordinates are
## 64-bit and only ever computed here.

signal origin_shifted(by: Vector2i)

var tuning := Tuning.current()
var run_seed: int
var shape: TerrainShape
var moon: MoonPosition
## The chunk the engine origin sits on. Engine position + this = world position.
var origin_chunk := Vector2i.ZERO

@onready var terrain: Terrain = $Terrain
@onready var content: Node3D = $Content
@onready var player: Player = $Content/Player

var _last_x: float
var _last_z: float


func _ready() -> void:
	# After the player, so a shift or a moon step sees this frame's movement.
	process_physics_priority = 100
	run_seed = tuning.run_seed if tuning.run_seed != 0 else randi()
	shape = TerrainShape.new(run_seed, tuning)
	moon = MoonPosition.new(tuning)
	player.world = self
	terrain.setup(self)
	_set_scene()
	var half := tuning.chunk_size * 0.5
	player.global_position = Vector3(half, shape.height_at(half, half) + 0.1, half)
	_last_x = player_world_x()
	_last_z = player_world_z()


func world_x(engine_x: float) -> float:
	return origin_chunk.x * tuning.chunk_size + engine_x


func world_z(engine_z: float) -> float:
	return origin_chunk.y * tuning.chunk_size + engine_z


func engine_x(x: float) -> float:
	return x - origin_chunk.x * tuning.chunk_size


func engine_z(z: float) -> float:
	return z - origin_chunk.y * tuning.chunk_size


func player_world_x() -> float:
	return world_x(player.global_position.x)


func player_world_z() -> float:
	return world_z(player.global_position.z)


func height_at(x: float, z: float) -> float:
	return shape.height_at(x, z)


func height_under(engine_position: Vector3) -> float:
	return shape.height_at(world_x(engine_position.x), world_z(engine_position.z))


func has_ground_under(engine_position: Vector3) -> bool:
	return terrain.has_collision_at(world_x(engine_position.x), world_z(engine_position.z))


## Moves the engine origin by whole chunks. Everything keeps its world position.
func shift_origin(by: Vector2i) -> void:
	origin_chunk += by
	var offset := Vector3(by.x * tuning.chunk_size, 0.0, by.y * tuning.chunk_size)
	for child in content.get_children():
		if child is Node3D:
			child.global_position -= offset
	terrain.reposition()
	origin_shifted.emit(by)


func _physics_process(_delta: float) -> void:
	var x := player_world_x()
	var z := player_world_z()
	moon.advance(x - _last_x, _last_z - z)
	_last_x = x
	_last_z = z

	var stray := Vector2i(floori(player.global_position.x / tuning.chunk_size),
		floori(player.global_position.z / tuning.chunk_size))
	if absi(stray.x) >= tuning.origin_shift_chunks or absi(stray.y) >= tuning.origin_shift_chunks:
		shift_origin(stray)

	_keep_bodies_on_ground()

	Dev.put("world/seed", run_seed)
	Dev.put("world/x", snappedf(x, 0.1))
	Dev.put("world/z", snappedf(z, 0.1))
	Dev.put("world/origin_chunk", origin_chunk)
	Dev.put("world/latitude", snappedf(rad_to_deg(moon.latitude), 0.0001))
	Dev.put("world/longitude", snappedf(rad_to_deg(moon.longitude), 0.0001))
	Dev.put("world/from_spawn_km", moon.distance_from_spawn() / 1000.0)


## Nothing physical is ever outside collision: a body whose ground is gone is
## frozen until it returns, and forgotten once its chunk is.
func _keep_bodies_on_ground() -> void:
	for child in content.get_children():
		var body := child as RigidBody3D
		if body == null:
			continue
		var x := world_x(body.global_position.x)
		var z := world_z(body.global_position.z)
		if not terrain.is_loaded_at(x, z):
			body.queue_free()
		elif not terrain.has_collision_at(x, z):
			if not body.freeze:
				body.freeze = true
				body.set_meta(&"frozen_by_world", true)
		elif body.get_meta(&"frozen_by_world", false):
			body.freeze = false
			body.remove_meta(&"frozen_by_world")


func _set_scene() -> void:
	var environment: Environment = $WorldEnvironment.environment
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_depth_begin = tuning.haze_begin
	environment.fog_depth_end = tuning.haze_end
	$Sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
