class_name World
extends Node3D
## Where everything is. Owns the run's seed and clock, the ground's one
## function, the floating origin and the player's point on the moon. Positions
## in the engine stay within a few hundred metres of the origin; true world
## coordinates are 64-bit and only ever computed here.

signal origin_shifted(by: Vector2i)

## Dev only: the console's warp steps the clock through these, so storms and
## days pass while you watch.
const TIME_WARPS: Array[float] = [1.0, 10.0, 60.0]
## Dev only: the console's gravity swaps to the body research's leaning, about
## 0.45 g, to feel it.
const LOW_GRAVITY := 4.4

var tuning := Tuning.current()
## The tuning's, or a fresh one each run when it's 0; a new run sets its own.
var run_seed := 0
## The origin chosen at New game, set before the world is made. None for a
## world that isn't a player's run, the menu's or a probe's, which starts
## where the tuning says with the standard kit.
var kit: Kit
var shape: TerrainShape
## Where the run began, in world metres: flat ground, never a slip face.
var spawn: Vector2
## Where on the moon it began, its kit's start (Starts): pure in the seed
## and the kit, so a resumed run finds it again.
var start: Vector3
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
@onready var wear: Wear = $Wear
@onready var ropes: Ropes = $Ropes
@onready var salvage: Salvage = $Salvage
@onready var farm: Farm = $Farm

var _last_x: float
var _last_z: float
## The chunk the sheet last followed you to, and the moon's jumps then; none
## forces it to follow again.
var _followed := Vector2i.MAX
var _followed_jumps := 0


func _ready() -> void:
	# Last in the tick: a shift or a moon step sees this frame's movement, and
	# the clock moves on only after everything has felt this moment's weather.
	process_physics_priority = 200
	if run_seed == 0:
		run_seed = tuning.run_seed if tuning.run_seed != 0 else randi()
	shape = TerrainShape.new(run_seed, tuning)
	Paint.face_wind(WeatherField.mean_heading(run_seed))
	start = Starts.find(shape.history, kit.start if kit != null else &"", tuning)
	moon = MoonPosition.new(tuning, start)
	player.world = self
	set_gravity(tuning.gravity)
	terrain.setup(self)
	weather.setup(self)
	power.setup(self)
	wear.setup(self)
	ropes.setup(self)
	salvage.setup(self)
	farm.setup(self)
	_set_scene()
	var half := tuning.chunk_size * 0.5
	spawn = _flat_near(half, half)
	player.global_position = Vector3(engine_x(spawn.x), height_at(spawn.x, spawn.y) + 0.1, engine_z(spawn.y))
	_last_x = player_world_x()
	_last_z = player_world_z()
	shape.sites.loaded = terrain.is_loaded_in
	shape.sites.rebuild = terrain.forget
	_follow_history()


## Puts the player down at a world place and run time, facing yaw, as a
## fresh spawn: distance from spawn and the moon position start over there,
## at the run's start on the moon.
func respawn(x: float, z: float, yaw: float, at_time: float) -> void:
	player.step_off()
	time = at_time
	time_warp = 1.0
	var at := Vector3(engine_x(x), height_at(x, z) + 0.1, engine_z(z))
	teleport(player, Transform3D(Basis(Vector3.UP, yaw), at))
	player.velocity = Vector3.ZERO
	player.camera.rotation.x = 0.0
	moon = MoonPosition.new(tuning, start)
	_last_x = x
	_last_z = z
	_followed = Vector2i.MAX
	weather.forecast_now()


## Dev: puts you at a point on the moon, degrees, facing yaw, as a fresh spawn
## there. You land on fresh ground well off any that's loaded, so the history
## laid round you there is laid on ground not yet built.
func travel(latitude_degrees: float, longitude_degrees: float, yaw: float) -> void:
	# Past where the history kept under the old ground could reach.
	var off := (tuning.history_lay_m + tuning.history_cell_m) * 2.0 + history_due()
	var at := _flat_near(player_world_x() + off, player_world_z())
	respawn(at.x, at.y, yaw, time)
	moon.place(latitude_degrees, longitude_degrees)


## How far round you history is laid before any ground is built there: past
## the farthest loaded chunk's far corner.
func history_due() -> float:
	return (tuning.view_radius + 2) * tuning.chunk_size * sqrt(2.0)


## The sheet follows you: it lays history from the point the moon position
## was last reckoned at, so laying is a pure function of the ticks.
func _follow_history() -> void:
	_followed = terrain.chunk_at(_last_x, _last_z)
	_followed_jumps = moon.jumps
	shape.sites.follow(_last_x, _last_z, moon.latitude, moon.longitude, -moon.north().z, history_due())
	var p := Sphere.point(moon.latitude, moon.longitude)
	var history := shape.history
	var near := history.nearest_landmark(p)
	Dev.put("world/zone", "%s, %s" % [history.region_of(p), history.tu_words(p)])
	Dev.put("world/hist", "%d units" % shape.sites.units().size())
	if not near.is_empty():
		# A bearing on the sphere is from the moon's north, as a compass reads.
		Dev.put("world/lmk", "%s %.1fkm %s" % [near.landmark.name, near.metres / 1000.0,
			Radio.compass(rad_to_deg(near.bearing))])


## A run starts on ground this flat: a camp-sized patch whose sand rises no
## more than FLAT_RISE m across FLAT_SPAN m, found within FLAT_SEARCH m, and
## never on a structure's ground.
const FLAT_SPAN := 10.0
const FLAT_RISE := 0.5
const FLAT_SEARCH := 300.0


## The nearest flat ground to a world place, looking outward in square rings;
## the place itself if there's none.
func _flat_near(x: float, z: float) -> Vector2:
	var from := Vector2(roundf(x), roundf(z))
	var step := FLAT_SPAN * 0.5
	for ring in int(FLAT_SEARCH / step) + 1:
		for dz in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dz)) == ring and _flat(from + Vector2(dx, dz) * step):
					return from + Vector2(dx, dz) * step
	return Vector2(x, z)


func _flat(at: Vector2) -> bool:
	if shape.sites.covering(at.x, at.y) != null:
		return false
	var low := INF
	var high := -INF
	for j in 3:
		for i in 3:
			var h := shape.height_at(at.x + (i - 1) * FLAT_SPAN * 0.5, at.y + (j - 1) * FLAT_SPAN * 0.5)
			low = minf(low, h)
			high = maxf(high, h)
	return high - low < FLAT_RISE


## Every device that's yours: those in the world, and those seated on them.
func devices() -> Array[Device]:
	var found: Array[Device] = []
	for node in content.get_children():
		if node is Device:
			_with_seated(node, found)
	return found


func _with_seated(device: Device, found: Array[Device]) -> void:
	found.append(device)
	for each in device.mounted():
		_with_seated(each, found)


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
	return terrain.height_at(x, z)


func height_under(engine_position: Vector3) -> float:
	return shape.held_height_at(world_x(engine_position.x), world_z(engine_position.z))


func has_ground_under(engine_position: Vector3) -> bool:
	return terrain.has_collision_at(world_x(engine_position.x), world_z(engine_position.z))


## A body whose middle sinks this far below the sand has gone through it.
const BELOW_SAND := 0.3
## How far a corner may rest in the sand: Jolt lets contacts sink 2 cm.
const SAND_SLOP := 0.04

## Bodies found below the sand and put back on top. Never zero means a bug:
## every world probe fails on it, and it's on the dev overlay.
var rescued := 0


## Moves the engine origin by whole chunks. Everything keeps its world position.
func shift_origin(by: Vector2i) -> void:
	origin_chunk += by
	var offset := Vector3(by.x * tuning.chunk_size, 0.0, by.y * tuning.chunk_size)
	for child in content.get_children():
		if child is PhysicsBody3D:
			teleport(child, child.global_transform.translated(-offset))
		elif child is Node3D:
			child.global_position -= offset
	# Seated devices follow their hosts, and are kinematic too.
	for device in devices():
		if device.host() != null:
			teleport(device, device.global_transform)
	terrain.reposition()
	origin_shifted.emit(by)


## Puts a body somewhere at once. Left to Jolt, a kinematic one (you, a ridden
## board) is carried there within a tick, throwing whatever it touched.
func teleport(body: PhysicsBody3D, to: Transform3D) -> void:
	body.global_transform = to
	var rid := body.get_rid()
	var mode := PhysicsServer3D.body_get_mode(rid)
	if mode == PhysicsServer3D.BODY_MODE_KINEMATIC:
		# Static for a moment it jumps there, and kinematic again it stays.
		PhysicsServer3D.body_set_mode(rid, PhysicsServer3D.BODY_MODE_STATIC)
		PhysicsServer3D.body_set_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM, to)
		PhysicsServer3D.body_set_mode(rid, mode)


func set_gravity(g: float) -> void:
	gravity = g
	PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, g)


func _physics_process(delta: float) -> void:
	var x := player_world_x()
	var z := player_world_z()
	moon.advance(x - _last_x, _last_z - z)
	_last_x = x
	_last_z = z
	if terrain.chunk_at(x, z) != _followed or moon.jumps != _followed_jumps or not shape.sites.anchored():
		_follow_history()

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
## frozen until it returns, and forgotten once its chunk is. That's as soon as
## you're too far for its chunk to be kept, not whenever streaming gets round
## to letting it go, so the camp is lost exactly where it's said to be.
func _keep_bodies_on_ground() -> void:
	var here := terrain.chunk_at(player_world_x(), player_world_z())
	var keep := tuning.view_radius + 1
	for child in content.get_children():
		var body := child as RigidBody3D
		# What's on you, or under you on a board, goes where you go.
		if body == null or body == player.board or ropes.on_you(body):
			continue
		var x := world_x(body.global_position.x)
		var z := world_z(body.global_position.z)
		var off := terrain.chunk_at(x, z) - here
		if not terrain.is_loaded_at(x, z) or maxi(absi(off.x), absi(off.y)) > keep:
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
	# A device clear of it as a whole, as one floating is, has no shape to look at.
	var device := body as Device
	if device != null and _clear_of_sand(body.global_transform * device.shape_bounds()):
		return
	var deepest := 0.0
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		# Any shape, by its bounds: a stake dragged by its line is a cylinder.
		if not shape.has_meta(&"sand_box"):
			shape.set_meta(&"sand_box", Catalog.bounds(shape.shape))
		var box: AABB = shape.get_meta(&"sand_box")
		var to_world := body.global_transform * shape.transform
		# Clear of the highest sand anywhere under it, no corner of it can be in:
		# a floating deck's dozens of shapes cost a few held points, not 8 reads each.
		var around := to_world * box
		if _clear_of_sand(around):
			continue
		for i in 8:
			var corner := to_world * box.get_endpoint(i)
			deepest = maxf(deepest, height_under(corner) - corner.y)
	if deepest > SAND_SLOP:
		body.global_position.y += deepest - SAND_SLOP * 0.5
		body.linear_velocity.y = maxf(body.linear_velocity.y, 0.0)


## Whether a box in the engine's frame is higher than SAND_SLOP below the
## highest sand under it, a millimetre to spare for rounding: then none of
## its corners can be deeper than that in it.
func _clear_of_sand(box: AABB) -> bool:
	var top := shape.highest_in(world_x(box.position.x) - 0.01, world_z(box.position.z) - 0.01,
		world_x(box.end.x) + 0.01, world_z(box.end.z) + 0.01)
	return top - box.position.y < SAND_SLOP - 0.001


func _set_scene() -> void:
	var environment: Environment = $WorldEnvironment.environment
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_depth_begin = tuning.haze_begin
	environment.fog_depth_end = tuning.haze_end
