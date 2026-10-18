extends ShieldProbe
## Scratch: sleeping until a storm's called.
## Time limit: 300 s

func run() -> void:
	await load_world(1234, false)
	var f := world.weather.field
	var x := world.player_world_x()
	var z := world.player_world_z()
	var ahead := world.tuning.radio_forecast_minutes * 60.0
	# A clear moment with no storm in the station's sight.
	var t := 0.0
	var found := -1.0
	while t < 40000.0:
		var r := Radio.forecast(f, x, z, t, ahead, 5.0)
		if Transmissions.calm(r, t):
			found = t
			break
		t += 60.0
	print("clear for the station at %.0f" % found)
	world.time = found
	world.weather.forecast_now()
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	fit_part(radio, &"battery")
	var p := world.player.global_position
	radio.global_position = p + Vector3(1.0, 0.2, 0.0)
	await live(3.0, 1.0)
	world.time_warp = 1.0
	print("refusal '%s' radio %s clear %s" % [world.sleep.refusal(), world.sleep.radio(), world.sleep._station_clear(radio)])
	var from := world.time
	await world.sleep.fall_asleep(Sleep.STATION)
	var r2 := Radio.forecast(f, x, z, world.time, ahead, 5.0)
	print("slept %.0f s; %s; the station now: stormy %s, storm in %.0f s; on %s at %.0f kHz" % [world.time - from, " / ".join(world.sleep.said), r2.stormy, r2.change - world.time, radio.on, radio.frequency])
	await physics_frames(10)
	print("radio says '%s'" % radio.said)
