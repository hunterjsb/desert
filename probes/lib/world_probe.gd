class_name WorldProbe
extends Probe
## For probes that need the world: builds it on a fixed seed and waits for ground.

const WORLD_SCENE := preload("res://game/world/world.tscn")
const BOX_SIZE := 0.5
## A half-metre crate, not a cardboard box a breeze would carry off.
const BOX_MASS := 10.0

var world: World


## Ground probes run in still air, so the wind can't move what they measure,
## and without ruins and finds, so nothing found stands in it; salvage's own
## probes ask for them.
func load_world(run_seed := 1234, still_air := true, salvage := false) -> void:
	var tuning := Tuning.current()
	tuning.run_seed = run_seed
	tuning.salvage = salvage
	if still_air:
		tuning.prevailing_speed = 0.0
		tuning.prevailing_sway = 0.0
		tuning.storm_outflow_speed = 0.0
	world = WORLD_SCENE.instantiate()
	add_child(world)
	await settle()
	# The ground takes as long to build as the machine takes, and you can drift
	# and the clock runs meanwhile: every run starts at the spawn, at time zero.
	world.respawn(world.spawn.x, world.spawn.y, 0.0, 0.0)


## Starts the run beside a town where history's house ruins stand, the one
## nearest where it would have begun: that start is deep desert, where
## history left next to nothing. Asked before load_world.
func start_among(run_seed := 1234) -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var from := Sphere.point(deg_to_rad(tuning.spawn_latitude_degrees), deg_to_rad(tuning.spawn_longitude_degrees))
	var starts := StructureKit.starts_among(run_seed, tuning, from, Vector2.ONE * tuning.chunk_size * 0.5)
	check(not starts.is_empty(), "a start among history's house ruins")
	if not starts.is_empty():
		tuning.spawn_latitude_degrees = rad_to_deg(Sphere.latitude(starts[0]))
		tuning.spawn_longitude_degrees = rad_to_deg(Sphere.longitude(starts[0]))


## The structures of a kind laid round you that stand, nearest first, those
## within `radius` m; built and held as their ground was, or as they'd read now.
func structures_near(kind: StringName, radius := 1500.0) -> Array[Structure]:
	var x := world.player_world_x()
	var z := world.player_world_z()
	var found: Array[Structure] = []
	for unit in world.shape.sites.units():
		for site in unit.sites:
			if site.kind == kind and site is Structure and world.shape.sites.covering(site.x, site.z) == site \
					and site.distance_to(x, z) <= radius:
				found.append(site)
	found.sort_custom(func(a: Structure, b: Structure) -> bool: return a.distance_to(x, z) < b.distance_to(x, z))
	return found


## Waits until the ground round the player has collision and, unless only_near,
## until nothing is left to build either. A busy machine builds it slower but
## builds it, so the limit is time, not frames: frames come faster the less a
## frame has to do, and on CI 1,200 ran out while the ground was still coming.
func settle(only_near := false, max_seconds := 60.0) -> void:
	var until := Time.get_ticks_msec() + roundi(max_seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		if world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()) \
				and (only_near or world.terrain.is_idle()):
			return
	check(false, "terrain settled within %.0f s" % max_seconds)


## Nothing may ever have gone through the sand, in any world probe.
func before_finish() -> void:
	if world != null and is_instance_valid(world):
		check(world.rescued == 0, "nothing went through the sand (%d rescued)" % world.rescued)


## Puts the player on the sand at a world position.
func teleport(x: float, z: float) -> void:
	world.teleport(world.player, Transform3D(world.player.global_basis,
		Vector3(world.engine_x(x), world.height_at(x, z) + 0.1, world.engine_z(z))))
	world.player.velocity = Vector3.ZERO


func drop_box(x: float, z: float, above := 1.0) -> RigidBody3D:
	var body := RigidBody3D.new()
	var holder := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * BOX_SIZE
	holder.shape = box
	body.add_child(holder)
	body.mass = BOX_MASS
	world.content.add_child(body)
	body.global_position = Vector3(world.engine_x(x), world.height_at(x, z) + above, world.engine_z(z))
	return body


## How far a body's centre sits above the sand directly beneath it.
func clearance(body: Node3D) -> float:
	return body.global_position.y - world.height_under(body.global_position)


## Level open sand downwind of where the run began, out of any dune's lee:
## along the run's long-term wind and every heading up to `fan` degrees
## either side of it, nothing within `back` m upwind stands more than `rise`
## m above it. Read from the shape, so it needn't be loaded; NAN if none
## within 4 km.
func open_sand(fan := 0.0, back := 250.0, rise := 1.0) -> Vector2:
	var mean := WeatherField.mean_heading(world.run_seed)
	var down := Vector2.from_angle(mean)
	var headings := [mean] if fan == 0.0 else range(-3, 4).map(func(k: int) -> float: return mean + deg_to_rad(fan) * k / 3.0)
	for along in range(0, 4000, 20):
		var at := world.spawn + down * along
		var h := world.shape.height_at(at.x, at.y)
		var open := absf(world.shape.height_at(at.x + down.x * 4.0, at.y + down.y * 4.0) - h) < 0.2
		for heading: float in headings:
			var up := -Vector2.from_angle(heading)
			for d in range(4, int(back) + 1, 4):
				if not open:
					break
				open = world.shape.height_at(at.x + up.x * d, at.y + up.y * d) <= h + rise
		if open:
			return at
	return Vector2(NAN, NAN)
