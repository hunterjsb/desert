extends DeviceProbe
## Power probe 2: the same camp run at 30, 60 and 120 physics ticks a second
## ends with the same charge in every battery, because power ticks on the world
## clock, not the frame. The camp is pinned to the same places and the same
## stretch of world time, so only the tick rate differs.

const START := 100.0
const END := 1000.0
## Staked where it stands, in world metres: a solar charger, a lamp on a crate, a turbine.
const PLACES := {&"charger": Vector2(36.0, 30.0), &"crate_frame": Vector2(28.0, 30.0), &"turbine": Vector2(32.0, 36.0)}


func run() -> void:
	var results := {}
	for rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		await load_world(1234, false)
		world.player.set_physics_process(false)
		world.moon.latitude = 0.0
		world.time_warp = 0.0
		world.time = START
		await physics_frames(2)
		var cells: Array[Battery] = []
		for id: StringName in PLACES:
			var device := spawn_device(id, 0.0, 0.2, false)
			var at: Vector2 = PLACES[id]
			device.global_position = Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 0.2, world.engine_z(at.y))
			device.freeze = true
			if id == &"charger":
				fit_part(device, &"solar_panel")
			elif id == &"crate_frame":
				fit_part(device, &"lamp")
			var cell: Battery = fit_part(device, &"battery")
			cell.charge_wh = 10.0
			cells.append(cell)
		world.time_warp = 30.0
		var step: float = 30.0 / rate
		while world.time + step <= END:
			await get_tree().physics_frame
		# Land exactly on the end, then let power catch up to it.
		world.time_warp = 0.0
		world.time = END
		await physics_frames(2)
		results[rate] = cells.map(func(c: Battery) -> float: return c.charge_wh)
		print("%d ticks/s: %s" % [rate, results[rate]])
		world.queue_free()
		await get_tree().process_frame
	Engine.physics_ticks_per_second = 60
	for rate in [30, 120]:
		for i in results[60].size():
			check(absf(results[rate][i] - results[60][i]) < 1e-9,
				"%d ticks/s gives the same charge as 60 (battery %d: %.9f vs %.9f Wh)" % [rate, i, results[rate][i], results[60][i]])
	check(results[60][0] > 10.0 and results[60][1] < 10.0 and results[60][2] > 10.0,
		"the charger and turbine charged and the lamp drew")
