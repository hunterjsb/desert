extends MenuProbe
## Menus & UI probe 1: never paused. The same run twice from the same moment,
## once with the system menu open throughout and once with it closed: world
## time, the weather and the physics (a crate tumbling over the sand, and you
## standing in the wind) come out exactly the same, and nothing is paused.

const TICKS := 600


func run() -> void:
	var open := await _measure(true)
	var closed := await _measure(false)
	print("menu open:   ", open)
	print("menu closed: ", closed)
	check(open[0] == closed[0] and open[0] > 9.9, "world time ran on the same (%.2f s, %.2f s)" % [open[0], closed[0]])
	check(open[1] == closed[1] and open[2] == closed[2], "the weather ran on the same")
	check(open[3].distance_to(closed[3]) < 1e-4 and open[4].distance_to(closed[4]) < 1e-4,
		"the physics ran on the same (crate %.5f m apart, you %.5f m)"
		% [open[3].distance_to(closed[3]), open[4].distance_to(closed[4])])
	check(open[3].distance_to(open[5]) > 1.0, "and the crate really moved (%.2f m)" % open[3].distance_to(open[5]))


## [time, storm, wind, crate, you, where the crate began], from the spawn, after
## TICKS ticks from the run's beginning.
func _measure(menu: bool) -> Array:
	await open_main(false)
	# Nothing left to build, so the ground can't differ between the two by load,
	# and no kit, which lands whenever the sand is ready.
	await settle()
	while not world.has_meta(&"kit"):
		await get_tree().physics_frame
	for body in world.get_meta(&"kit", []):
		if is_instance_valid(body):
			body.free()
	world.remove_meta(&"kit")
	world.respawn(world.spawn.x, world.spawn.y, 0.0, 0.0)
	var crate := drop_box(world.spawn.x + 2.0, world.spawn.y - 3.0, 0.6)
	# Heavy enough that the storm can't carry it off past the ground's collision.
	crate.mass = 80.0
	crate.linear_velocity = Vector3(3.0, 1.0, -2.0)
	crate.angular_velocity = Vector3(2.0, 0.0, 1.0)
	var start := _from_spawn(crate.global_position)
	if menu:
		press(&"ui_cancel")
	var paused := false
	for i in TICKS:
		await get_tree().physics_frame
		paused = paused or get_tree().paused or (menu != main.ui.is_open())
	check(not paused, "the menu stayed %s and nothing paused" % ("open" if menu else "closed"))
	var out := [snappedf(world.time, 0.001), snappedf(world.weather.storm, 0.001),
		world.weather.wind.snappedf(0.001), _from_spawn(crate.global_position),
		_from_spawn(world.player.global_position), start]
	check(world.rescued == 0, "nothing went through the sand")
	main.free()
	world = null
	return out


func _from_spawn(at: Vector3) -> Vector3:
	return Vector3(world.world_x(at.x) - world.spawn.x, at.y, world.world_z(at.z) - world.spawn.y).snappedf(0.0001)
