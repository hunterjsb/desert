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


## Waits until the ground round the player has collision and, unless only_near,
## until nothing is left to build either.
func settle(only_near := false, max_frames := 1200) -> void:
	for i in max_frames:
		await get_tree().process_frame
		if world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()) \
				and (only_near or world.terrain.is_idle()):
			return
	check(false, "terrain settled within %d frames" % max_frames)


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
