extends WeatherProbe
## Radio probe 15: storms tell you which way. Standing clear of a storm with
## one close by on one side, every god whose way runs through it is cut off
## entirely, while the gods whose way is clear come through exactly as they
## would under clear skies: which signals you lose says which way they lie.

const STEP := 10.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	await physics_frames(2)
	var tuning := Tuning.current()
	var gods := Radio.gods_of(world)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	# A moment clear where you stand, a storm close by one way, some gods behind it and some not.
	var found := NAN
	var t := 0.0
	while t < 2.0 * 24.0 * 3600.0 and is_nan(found):
		if field.storm_at(x, z, t) == 0.0:
			var blocked := 0
			var open := 0
			for id in Gods.ids():
				var storm := Interference.along(field, x, z, radio.god_way(id).bearing, INF, t, tuning)
				blocked += int(storm >= tuning.storm_blocks)
				open += int(storm == 0.0)
			if blocked > 0 and open > 0:
				found = t
		t += STEP
	check(not is_nan(found), "a moment clear where you stand, with a storm close by one way")
	if is_nan(found):
		return
	world.time = found
	var lost := []
	var heard := []
	for id in Gods.ids():
		radio.frequency = gods.carrier(id, found)
		var got := radio.receive(id, x, z, found)
		var way: float = got.bearing
		var clear := smoothstep(tuning.signal_floor, Radio.WHOLE, got.strength)
		if got.storm >= tuning.storm_blocks:
			lost.append("%s %.0f°" % [Gods.title(id), way])
			check(got.clean == 0.0, "%s, its way through the storm, is cut off entirely" % Gods.title(id))
		elif got.storm == 0.0:
			heard.append("%s %.0f°" % [Gods.title(id), way])
			check(is_equal_approx(got.clean, clear), "%s, its way clear, comes through as under clear skies" % Gods.title(id))
	print("at %.0f s: lost %s; heard %s" % [found, lost, heard])
