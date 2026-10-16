class_name FarmProbe
extends ShieldProbe
## For farming probes: planters standing still on the sand with their crops
## sown, the felt temperature held where a probe wants it, and the world clock
## moved on exactly, tick by tick, with nothing else moving.


## A planter on the sand at a place, held still and kept from the weather's
## wear, these crops sown and its tank full, with a harvester if asked.
func planter_at(at: Vector3, crops: Array, harvester := false) -> Planter:
	var made := Catalog.device(&"planter") as Planter
	made.frame_stats["toughness"] = INF
	world.content.add_child(made)
	made.global_position = Vector3(at.x, world.height_under(at) + 0.2, at.z)
	made.freeze = true
	for crop: StringName in crops + ([&"harvester"] if harvester else []):
		fit_part(made, crop)
	made.tank_l = world.tuning.planter_tank_litres
	return made


## Puts your eyes at `eye`, looking at `target`, as the hands probes do.
func aim(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)


## Where a fitted part's middle sits, in the world.
func middle_of(socket: Socket) -> Vector3:
	var device := socket.get_parent() as Node3D
	return device.global_transform * socket.transform * Vector3(0.0, 0.0, socket.part.depth() * 0.5)


## Holds the felt temperature round a place at `celsius`: a test-only shelter
## that keeps out nothing but the temperature, and holds it there.
func hold_temperature(at: Vector3, celsius: float) -> Shelter:
	Tuning.current().sheltered_temperature = celsius
	var made := Shelter.new()
	made.blocks = {&"wind": 0.0, &"storm": 0.0, &"temperature": 1.0}
	made.radius = 30.0
	world.content.add_child(made)
	made.global_position = at
	return made


## The run time of a time of day (0 midnight, 0.5 noon) on a day, counting
## the first as 0.
func time_of(hour: float, day := 0) -> float:
	var tuning := Tuning.current()
	return (fposmod(hour - tuning.start_time_of_day, 1.0) + day) * tuning.day_minutes * 60.0


## Puts the clock at a run time with nothing lived through, the time warp
## off: by way of a jump back, which no tick lives through.
func clock_at(t: float) -> void:
	world.time_warp = 0.0
	world.time = t + 3600.0
	await physics_frames(2)
	world.time = t
	await physics_frames(2)


## Moves the clock on by `seconds`, lived through tick by tick; each() is
## called after every chunk.
func pass_time(seconds: float, each := Callable(), chunk := 50.0) -> void:
	world.time_warp = 0.0
	var end := world.time + seconds
	while world.time < end - 1e-9:
		world.time = minf(world.time + chunk, end)
		await physics_frames(2)
		if each.is_valid():
			each.call()
