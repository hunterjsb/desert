extends WeatherProbe
## Bubble shield probe 1, as far as the look-test reaches (the device, harm
## and power arrive with Stage 6): deep in a storm, a standing bubble is still,
## clear air, and everything that reads the weather switches exactly at its
## shell. Walk out through the shell and back a quarter metre at a time. The
## game reads it at your feet: the wind on you and the storm's harm. The senses
## read it at your eyes: seen_storm, the fog and the muffled roar. Light passes
## through, so the light doesn't switch at all. And the storm pass is told
## where the bubble is, through an origin shift.

const STEP := 0.25
## The bubble's centre stands this far over the sand, as on a generator.
const CORE := 0.25


func run() -> void:
	await load_weather()
	var place := Scenarios.find(world, Scenarios.by_key("deep"))
	check(not place.is_empty(), "a deep storm in this run's weather")
	if place.is_empty():
		return
	world.respawn(place.x, place.z, place.yaw, place.time)
	world.time_warp = 0.0
	await settle(true)
	var shelter := Shelter.new()
	world.content.add_child(shelter)
	shelter.global_position = Vector3(world.engine_x(place.x), world.height_at(place.x, place.z) + CORE,
		world.engine_z(place.z))
	shelter.radius = Tuning.current().shield_radius
	await physics_frames(3)
	check(world.weather.map.ready, "the storm map is ready")

	# The game, by the shell at your feet.
	var feet := func(at: Vector3) -> Vector3: return at
	var wrong := PackedStringArray()
	var inside := 0
	var steps := 0
	var cross := _crossing(place, shelter, feet)
	for offset: float in _there_and_back():
		teleport(place.x + cross + offset, place.z)
		await get_tree().physics_frame
		var harm := world.player.storm_harm
		await get_tree().physics_frame
		var at := world.player.global_position
		var sheltered := _inside(shelter, at)
		steps += 1
		inside += int(sheltered)
		var seen := {
			"no storm felt": world.weather.felt_storm(at) == 0.0,
			"no wind felt": world.weather.felt_wind(at) == Vector3.ZERO,
			"no harm": world.player.storm_harm == harm,
		}
		for what: String in seen:
			if seen[what] != sheltered:
				wrong.append("%s was %s at %+.2f m" % [what, seen[what], offset])
	check(inside > 5 and inside < steps - 5, "the walk crossed the shell at the feet both ways")
	check(wrong.is_empty(), "the game switched exactly at the shell: %s" % ", ".join(wrong))

	# The senses, by the shell at your eyes.
	var eyes := func(at: Vector3) -> Vector3: return at + world.player.camera.position
	var environment: Environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var haze_end := Tuning.current().haze_end
	var light := PackedFloat32Array()
	wrong.clear()
	inside = 0
	steps = 0
	cross = _crossing(place, shelter, eyes)
	for offset: float in _there_and_back():
		teleport(place.x + cross + offset, place.z)
		await physics_frames(2)
		var sheltered := _inside(shelter, world.player.camera.global_position)
		steps += 1
		inside += int(sheltered)
		light.append(environment.ambient_light_energy)
		var seen := {
			"clear air": world.weather.seen_storm == 0.0,
			"open fog": environment.fog_depth_end == haze_end,
			"muffled roar": world.weather.atmosphere.muffled() > 0.5,
		}
		for what: String in seen:
			if seen[what] != sheltered:
				wrong.append("%s was %s at %+.2f m" % [what, seen[what], offset])
	check(inside > 5 and inside < steps - 5, "the walk crossed the shell at the eyes both ways")
	check(wrong.is_empty(), "the senses switched exactly at the shell: %s" % ", ".join(wrong))
	var brightest: float = Array(light).max()
	var spread := (brightest - float(Array(light).min())) / brightest
	check(spread < 0.01, "the light passes through: the same either side of the shell (%.1f%% apart)" % (spread * 100.0))

	# The storm pass draws the bubble where it stands, through an origin shift.
	world.shift_origin(Vector2i(3, -2))
	await get_tree().process_frame
	await get_tree().process_frame
	var material := world.weather.face.material
	var told: PackedVector4Array = material.get_shader_parameter("shelters")
	var c := shelter.global_position
	check(material.get_shader_parameter("shelter_count") == 1
		and Vector3(told[0].x, told[0].y, told[0].z).distance_to(c) < 0.01 and told[0].w == shelter.radius,
		"the storm pass knows where the bubble is after a shift")


## Offsets half a step off the crossing, out and back, so a shove of a few
## centimetres can't change the side a step lands on.
func _there_and_back() -> Array:
	var out: Array = []
	for k in range(-12, 12):
		out.append((k + 0.5) * STEP)
	var back := out.duplicate()
	back.reverse()
	return out + back


func _inside(shelter: Shelter, at: Vector3) -> bool:
	return at.distance_to(shelter.global_position) < shelter.radius


## Metres east of place to where point(standing there) crosses the shell, to
## a millimetre. The player stands on the sand.
func _crossing(place: Dictionary, shelter: Shelter, point: Callable) -> float:
	var lo := 0.0
	var hi := shelter.radius + 2.0
	while hi - lo > 0.001:
		var mid := (lo + hi) * 0.5
		var x: float = place.x + mid
		var stand := Vector3(world.engine_x(x), world.height_at(x, place.z), world.engine_z(place.z))
		if _inside(shelter, point.call(stand)):
			lo = mid
		else:
			hi = mid
	return hi
