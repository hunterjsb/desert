extends "res://probes/movement/36_ground_rest_and_crawl.gd"
## Runs alone
## Low postures must not anchor the player against the world.

class MovingFloor extends RigidBody3D:
	var pace := 0.0
	func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
		state.linear_velocity = Vector3(pace, 0.0, 0.0)
		state.angular_velocity = Vector3.ZERO


func run() -> void:
	await load_moving()
	set_rate(60, 2)
	blow(Vector2.ZERO)
	world.tuning.lee_wind = 0.0
	world.tuning.lee_storm = 0.0
	var base := player.global_position + Vector3.UP * 5.0
	var support := MovingFloor.new()
	support.gravity_scale = 0.0
	support.mass = 1000.0
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30.0, 0.2, 30.0)
	collision.shape = box
	support.add_child(collision)
	support.position = world.content.to_local(base - Vector3.UP * 0.1)
	world.content.add_child(support)
	player.global_position = base + Vector3.UP * 0.03
	await simulate(0.7)
	_action("lie_down")
	await simulate(0.2)
	var from := player.global_position
	support.pace = 1.0
	await simulate(1.0)
	print("moving platform ",player.global_position-from," floor=",player.is_on_floor(), " pose=",player.ground_pose," support=",support.position.x)
	check(player.ground_pose == &"prone" and player.global_position.x - from.x > 0.7,
		"prone player stays aboard a moving support")
	support.pace = 0.0
	blow(Vector2(40.0, 0.0))
	from = player.global_position
	await simulate(0.7)
	check(player.global_position.x - from.x > 0.15, "wind still pushes the smaller prone catch")
	blow(Vector2.ZERO)
	world.ropes.set_physics_process(false)
	player.set_meta(&"rope_drag", Vector3(2.0, 0.0, 0.0))
	from = player.global_position
	await simulate(0.5)
	check(player.global_position.x - from.x > 0.7, "rope solver's real motion input still carries a prone player")
	player.set_meta(&"rope_drag", Vector3.ZERO)
	world.ropes.set_physics_process(true)
	# On an actual dune, lowering yourself must not bypass passive slipping.
	support.queue_free()
	var hill := slope_between(world.player_world_x(), world.player_world_z(), 250.0,
		world.tuning.slip_angle + 2.0, 40.0, 4.0)
	check(not hill.is_empty(), "a real slip face exists for resting")
	if hill.is_empty():
		return
	await place(hill.x, hill.z, hill.downhill)
	teleport(hill.x, hill.z)
	await get_tree().physics_frame
	from = player.global_position
	await simulate(1.5)
	var travel := Vector2(player.global_position.x - from.x, player.global_position.z - from.z).dot(hill.downhill)
	print("prone slip face ",hill.degrees," degrees, travel ",travel)
	check(travel > 1.0 and player.ground_pose == &"prone",
		"prone player slides down a real steep dune")
	set_rate(60)
