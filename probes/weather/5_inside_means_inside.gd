extends WeatherProbe
## Wind & storms probe 5: walk the player across a front a metre at a time, in
## and back out. Darkness, visibility, the far ring and harm switch on exactly
## when the field at the player crosses the threshold, and off when it drops.


func run() -> void:
	await load_weather()
	var px := world.player_world_x()
	var pz := world.player_world_z()
	var start := find_time(func(t: float) -> bool:
		return player_storm_at(t) == 0.0 and not is_nan(_crossing(px, pz, t)))
	var crossing := _crossing(px, pz, start)
	world.time = start
	world.time_warp = 0.0
	await physics_frames(2)
	var environment: Environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var clear_light := environment.ambient_light_energy
	var haze_end := Tuning.current().haze_end
	var steps := 0
	var inside := 0
	var wrong := PackedStringArray()
	# Offsets sit half a metre off the crossing, so a shove of a few
	# centimetres can't change the side a step lands on.
	var offsets := range(-20, 21) + range(20, -21, -1)
	for offset: int in offsets:
		teleport(px + crossing + offset - 0.5, pz)
		await get_tree().physics_frame
		var harm := world.player.storm_harm
		await get_tree().physics_frame
		var at := Vector2(world.player_world_x(), world.player_world_z())
		var stormy := field.storm_at(at.x, at.y, world.time) > 0.0
		steps += 1
		if stormy:
			inside += 1
		var seen := {
			"in_storm": world.weather.in_storm,
			"fog closes in": environment.fog_depth_end < haze_end,
			"darkness": environment.ambient_light_energy < clear_light,
			"far ring hidden": not world.terrain.is_far_shown(),
			"harm": world.player.storm_harm > harm,
		}
		for what: String in seen:
			if seen[what] != stormy:
				wrong.append("%s was %s at %+d m" % [what, seen[what], offset])
	print("%d steps, %d inside the storm" % [steps, inside])
	check(inside > 20 and inside < steps - 20, "the walk crossed the front both ways")
	check(wrong.is_empty(), "everything switched exactly at the front: %s" % ", ".join(wrong))


## Metres east of (x, z) to the front, refined to a centimetre; NAN if not
## within 500 m.
func _crossing(x: float, z: float, t: float) -> float:
	var d := 25.0
	while d < 500.0:
		if field.raw_storm_at(x + d, z, t) > 0.0:
			var lo := d - 25.0
			while d - lo > 0.01:
				var mid := (lo + d) * 0.5
				if field.raw_storm_at(x + mid, z, t) > 0.0:
					d = mid
				else:
					lo = mid
			return d
		d += 25.0
	return NAN
