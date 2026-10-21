extends WeatherProbe
## Radio probe 54: the antenna reel. Used on a radio, its wire clips to the
## set; carried off, the wire pays out with it; past the end of its wire the
## clip pops off; used again, it reels in.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	var reel := Scenarios.standing(world, &"antenna_reel", [], [0.6, 2.0]) as AntennaReel
	reel.freeze = true
	await physics_frames(2)
	check(reel.use(world.player, radio.global_position) and reel.radio == radio, "used on a radio, it clips to it")
	reel.global_position = radio.global_position + Vector3(12.0, 0.0, 0.0)
	await physics_frames(40)
	print("12 m off: %.1f m strung, the radio's wire %.1f m" % [reel.strung(), radio.wire.x])
	check(absf(radio.wire.x - reel.strung()) < 0.5 and reel.strung() > 11.0, "carried off, its wire pays out")
	reel.use(world.player, reel.global_position)
	check(reel.radio == null, "used again, it reels in")
	reel.clip(radio)
	reel.global_position = radio.global_position + Vector3(Tuning.current().antenna_reel_m + 2.0, 0.0, 0.0)
	await physics_frames(3)
	check(reel.radio == null, "past the end of its wire the clip pops off")
