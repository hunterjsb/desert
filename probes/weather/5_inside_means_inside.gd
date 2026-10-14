extends WeatherProbe
## Wind & storms probe 5: inside is a place, computed from where you are, never
## an event. Walk the player across a front a metre at a time, in and back
## out. The game's storm (in_storm, the far ring, harm) switches exactly where
## the field crosses its threshold; the senses (fog, light) switch exactly
## where the drawn face swallows the camera, by the face's own twin.


func run() -> void:
	await load_weather()
	var px := world.player_world_x()
	var pz := world.player_world_z()
	var start := find_time(func(t: float) -> bool:
		return player_storm_at(t) == 0.0 and not is_nan(_crossing(px, pz, t, _field_side)))
	world.time = start
	world.time_warp = 0.0
	await physics_frames(3)
	check(world.weather.map.ready, "the storm map is ready")

	# The game: by the field at the player.
	var wrong := PackedStringArray()
	var inside := 0
	var steps := 0
	for offset: int in _there_and_back():
		teleport(px + _crossing(px, pz, start, _field_side) + offset - 0.5, pz)
		await get_tree().physics_frame
		var harm := world.player.storm_harm
		await get_tree().physics_frame
		var stormy := field.storm_at(world.player_world_x(), world.player_world_z(), world.time) > 0.0
		steps += 1
		inside += int(stormy)
		var seen := {
			"in_storm": world.weather.in_storm,
			"far ring hidden": not world.terrain.is_far_shown(),
			"harm": world.player.storm_harm > harm,
		}
		for what: String in seen:
			if seen[what] != stormy:
				wrong.append("%s was %s at %+d m" % [what, seen[what], offset])
	check(inside > 20 and inside < steps - 20, "the walk crossed the field's front both ways")
	check(wrong.is_empty(), "the game switched exactly at the field's front: %s" % ", ".join(wrong))

	# The senses: by the drawn face at the camera.
	var face_at := _crossing(px, pz, start, _face_side)
	check(not is_nan(face_at), "the drawn face is within reach")
	if is_nan(face_at):
		return
	var environment: Environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var haze_end := Tuning.current().haze_end
	var clear_light := INF
	wrong.clear()
	inside = 0
	steps = 0
	for offset: int in _there_and_back():
		teleport(px + face_at + offset - 0.5, pz)
		await physics_frames(2)
		var swallowed := world.weather.face.seen_at(world.player.camera.global_position) > 0.0
		steps += 1
		inside += int(swallowed)
		if offset == -20:
			clear_light = minf(clear_light, environment.ambient_light_energy)
		var seen := {
			"seen_storm": world.weather.seen_storm > 0.0,
			"fog closes in": environment.fog_depth_end < haze_end,
		}
		for what: String in seen:
			if seen[what] != swallowed:
				wrong.append("%s was %s at %+d m" % [what, seen[what], offset])
	check(inside > 5 and inside < steps - 5, "the walk crossed the drawn face both ways")
	check(wrong.is_empty(), "the senses switched exactly at the drawn face: %s" % ", ".join(wrong))
	# Deep in the dust: on past the face until it has swallowed you whole. The
	# face's skin and billows can take more than the walk's 20 m to get there.
	var darkest := INF
	for d in range(25, 205, 5):
		teleport(px + face_at + d, pz)
		await physics_frames(2)
		if world.weather.seen_storm >= 0.99:
			darkest = environment.ambient_light_energy
			break
	check(darkest < clear_light, "deep in the dust is darker than outside (%.2f vs %.2f)" % [darkest, clear_light])


## Offsets sit half a metre off the crossing, so a shove of a few centimetres
## can't change the side a step lands on.
func _there_and_back() -> Array:
	return range(-20, 21) + range(20, -21, -1)


func _field_side(x: float, z: float, t: float) -> bool:
	return field.raw_storm_at(x, z, t) > 0.0


## The camera stands at eye height over the sand.
func _face_side(x: float, z: float, _t: float) -> bool:
	var eye := Vector3(world.engine_x(x), world.height_at(x, z) + world.player.camera.position.y,
		world.engine_z(z))
	return world.weather.face.seen_at(eye) > 0.0


## Metres east of (x, z) to where inside(x, z, t) first turns true, refined to
## a centimetre; NAN if not within 500 m.
func _crossing(x: float, z: float, t: float, inside: Callable) -> float:
	var d := 25.0
	while d < 500.0:
		if inside.call(x + d, z, t):
			var lo := d - 25.0
			while d - lo > 0.01:
				var mid := (lo + d) * 0.5
				if inside.call(x + mid, z, t):
					d = mid
				else:
					lo = mid
			return d
		d += 25.0
	return NAN
