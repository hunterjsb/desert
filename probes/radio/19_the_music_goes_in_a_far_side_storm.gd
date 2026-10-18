extends WeatherProbe
## Radio probe 19: the music goes in a far-side storm. The "far_storm" scenario
## stands you on the far side with a radio on the music, the relay well up and
## a storm coming. With the storm still off, the music comes in; its pitch
## slides with the relay's coming and going. Once the storm is over you, the
## music is cut off and the static is all there is.

const STEP := 5.0


func run() -> void:
	await load_weather()
	Scenarios.apply(world, Scenarios.by_key("far_storm"))
	var dropped := await _landed()
	check(dropped.size() == 2 and dropped[0] is Radio, "it sets a radio and a shield in front of you")
	if dropped.is_empty():
		return
	var radio: Radio = dropped[0]
	radio.freeze = true
	await physics_frames(10)
	var history := world.shape.history
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var first := radio.receive_relay(x, z, world.time)
	print("far side, %.0f° from Tu: the relay %.0f° up, clean %.2f, pitch %.3f, music %.1f dB" % [
		rad_to_deg(history.from_tu(p)), rad_to_deg(first.elevation), first.clean, radio.music.pitch_scale,
		radio.music.volume_db])
	check(history.region_of(p) == &"far", "on the far side")
	check(radio.channel == Radio.MUSIC and first.elevation >= deg_to_rad(55.0), "tuned to the music, the relay well up")
	check(first.clean > 0.0 and radio.music.volume_db > -30.0, "with the storm still off, the music comes in")
	check(not is_equal_approx(radio.music.pitch_scale, 1.0), "its pitch sliding with the relay's coming and going")

	var arrives := world.time
	while field.storm_at(x, z, arrives) < 0.9 and arrives < world.time + 900.0:
		arrives += STEP
	check(field.storm_at(x, z, arrives) >= 0.9, "the storm comes over")
	world.time = arrives
	await physics_frames(5)
	var under := radio.receive_relay(x, z, arrives)
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
