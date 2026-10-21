extends WeatherProbe
## Radio probe 19: the music goes in a far-side storm. The "far_storm" scenario
## stands you on the far side at night with a radio on the music and a storm
## coming. With the storm still off, the port's AM comes round the moon to it
## past the skip, and the music comes in. Once the storm is over you, the music
## is cut off and the static is all there is.

const STEP := 5.0


func run() -> void:
	await load_weather()
	Scenarios.apply(world, Scenarios.by_key("far_storm"))
	var dropped := await _landed()
	check(not dropped.is_empty() and dropped[0] is Radio and dropped.any(func(n: Node) -> bool: return n is ShieldGenerator),
		"it sets a radio and a shield on its plate in front of you")
	if dropped.is_empty():
		return
	var radio: Radio = dropped[0]
	radio.freeze = true
	await physics_frames(10)
	var history := world.shape.history
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var first: Dictionary = radio.receive_music(x, z, world.time)
	print("far side, %.0f° from Tu, %.0f km from the port: clean %.2f, music %.1f dB" % [
		rad_to_deg(history.from_tu(p)), first.metres / 1000.0, first.clean, radio.music.volume_db])
	check(history.region_of(p) == &"far", "on the far side")
	check(radio.channel == Radio.MUSIC, "tuned to the music")
	check(first.clean > 0.0 and radio.music.volume_db > -30.0, "with the storm still off, the music comes in")

	var arrives := world.time
	while field.storm_at(x, z, arrives) < 0.9 and arrives < world.time + 900.0:
		arrives += STEP
	check(field.storm_at(x, z, arrives) >= 0.9, "the storm comes over")
	world.time = arrives
	await physics_frames(5)
	var under: Dictionary = radio.receive_music(x, z, arrives)
	print("the storm over you: clean %.2f, music %.1f dB, \"%s\"" % [under.clean,
		radio.music.volume_db, radio.said])
	check(under.clean == 0.0 and radio.music.volume_db < -40.0 and (radio.said.ends_with("static") or radio.said.ends_with("· · ·")),
		"once it's over you the music is cut off, and the static is all there is")


func _landed() -> Array:
	for i in 1200:
		if world.has_meta(&"scenario_kit"):
			return world.get_meta(&"scenario_kit")
		await get_tree().physics_frame
	return []
