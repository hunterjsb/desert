class_name World
extends Node3D
## Where everything is. Owns the run's seed and clock, the ground's one
## function, the floating origin and the player's point on the moon. Positions
## in the engine stay within a few hundred metres of the origin; true world
## coordinates are 64-bit and only ever computed here.

signal origin_shifted(by: Vector2i)

## Dev only: F5 runs the clock faster so storms and days pass while you watch.
const TIME_WARPS: Array[float] = [1.0, 10.0, 60.0]
## Dev only: F6 swaps to the body research's leaning, about 0.45 g, to feel it.
const LOW_GRAVITY := 4.4

var tuning := Tuning.current()
var run_seed: int
var shape: TerrainShape
var moon: MoonPosition
## The chunk the engine origin sits on. Engine position + this = world position.
var origin_chunk := Vector2i.ZERO
## Seconds since the run began. Weather and the day are pure functions of it.
var time := 0.0
## How many seconds the clock moves per second; 0 stops it.
var time_warp := 1.0
## m/s², for everything here: bodies through the physics space, the player directly.
var gravity: float

@onready var terrain: Terrain = $Terrain
@onready var content: Node3D = $Content
@onready var player: Player = $Content/Player
@onready var weather: Weather = $Weather
@onready var power: Power = $Power

var _last_x: float
var _last_z: float


func _ready() -> void:
	# Last in the tick: a shift or a moon step sees this frame's movement, and
	# the clock moves on only after everything has felt this moment's weather.
	process_physics_priority = 200
	run_seed = tuning.run_seed if tuning.run_seed != 0 else randi()
	shape = TerrainShape.new(run_seed, tuning)
	moon = MoonPosition.new(tuning)
	player.world = self
	set_gravity(tuning.gravity)
	terrain.setup(self)
	weather.setup(self)
	power.setup(self)
	_set_scene()
	var half := tuning.chunk_size * 0.5
	player.global_position = Vector3(half, shape.height_at(half, half) + 0.1, half)
	_last_x = player_world_x()
	_last_z = player_world_z()


## Dev: puts the player down at a world place and run time, facing yaw, as a
## fresh spawn: distance from spawn and the moon position start over there.
func respawn(x: float, z: float, yaw: float, at_time: float) -> void:
	time = at_time
	time_warp = 1.0
	player.global_position = Vector3(engine_x(x), height_at(x, z) + 0.1, engine_z(z))
	player.velocity = Vector3.ZERO
	player.rotation.y = yaw
	player.camera.rotation.x = 0.0
	moon = MoonPosition.new(tuning)
	_last_x = x
	_last_z = z
	weather.forecast_now()


## The World a node lives in, found by climbing its parents.
static func of(node: Node) -> World:
	while node != null and not node is World:
		node = node.get_parent()
	return node


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


## A body whose middle sinks this far below the sand has gone through it.
const BELOW_SAND := 0.3
## How far a corner may rest in the sand: Jolt lets contacts sink 2 cm.
const SAND_SLOP := 0.04

## Bodies found below the sand and put back on top. Never zero means a bug:
## every world probe fails on it, and it's on F3.
var rescued := 0


## Moves the engine origin by whole chunks. Everything keeps its world position.
func shift_origin(by: Vector2i) -> void:
	origin_chunk += by
	var offset := Vector3(by.x * tuning.chunk_size, 0.0, by.y * tuning.chunk_size)
	for child in content.get_children():
		if child is Node3D:
			child.global_position -= offset
	terrain.reposition()
	origin_shifted.emit(by)


func set_gravity(g: float) -> void:
	gravity = g
	PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, g)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_time_warp"):
		time_warp = TIME_WARPS[(TIME_WARPS.find(time_warp) + 1) % TIME_WARPS.size()]
	elif event.is_action_pressed("dev_gravity"):
		set_gravity(LOW_GRAVITY if gravity == tuning.gravity else tuning.gravity)


func _physics_process(delta: float) -> void:
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
	time += delta * time_warp

	Dev.put("world/seed", "%d" % run_seed)
	if rescued > 0:
		Dev.put("world/RESCUED", "%d" % rescued)
	Dev.put("world/g", "%.2fg" % (gravity / 9.8))
	Dev.put("world/pos", "%.0f,%.0f" % [x, z])
	Dev.put("world/ll", "%.3f,%.3f" % [rad_to_deg(moon.latitude), rad_to_deg(moon.longitude)])
	Dev.put("world/dist", "%.2fkm" % (moon.distance_from_spawn() / 1000.0))
	Dev.put("world/orig", "%d,%d" % [origin_chunk.x, origin_chunk.y])


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
		elif not body.freeze and body.global_position.y < height_under(body.global_position) - BELOW_SAND:
			# Sand Game died of things falling through; here it's caught, put back and counted.
			body.global_position.y = height_under(body.global_position) + 0.5
			body.linear_velocity = Vector3.ZERO
			body.angular_velocity = Vector3.ZERO
			rescued += 1
			push_warning("rescued %s from below the sand" % (body.get("label") if "label" in body else body.name))
		elif not body.freeze:
			_hold_above_sand(body)


## The sand is the ground's one function, so it's also a hard floor: no corner
## of a loose body may sink more than SAND_SLOP into it. Jolt's heightmap is a
## skin with no inside, so a thin part pressed past halfway (a crate that lost
## power dropping onto a panel) would otherwise go out the bottom.
func _hold_above_sand(body: RigidBody3D) -> void:
	var deepest := 0.0
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or not shape.shape is BoxShape3D:
			continue
		var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
		var to_world := body.global_transform * shape.transform
		for i in 8:
			var corner := to_world * Vector3(half.x * (1 - (i & 1) * 2), half.y * (1 - (i & 2)), half.z * (1 - (i & 4) / 2))
			deepest = maxf(deepest, height_under(corner) - corner.y)
	if deepest > SAND_SLOP:
		body.global_position.y += deepest - SAND_SLOP * 0.5
		body.linear_velocity.y = maxf(body.linear_velocity.y, 0.0)


func _set_scene() -> void:
	var environment: Environment = $WorldEnvironment.environment
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_depth_begin = tuning.haze_begin
	environment.fog_depth_end = tuning.haze_end
