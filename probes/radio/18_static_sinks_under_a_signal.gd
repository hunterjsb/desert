extends ShieldProbe
## Radio probe 18: static sinks under a signal. Tuned to a god coming in clean,
## the hiss under it is far quieter, radio_static_duck_db under what it would
## be, than the static between stations, where there's nothing else to hear.
## A god whose way a storm blocks is nothing to hear, and its static is all
## there is again.


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var best := &""
	var cleanest := 0.0
	for id in Gods.ids():
		radio.frequency = gods.carrier(id, world.time)
		var got: float = radio.receive(id, x, z, world.time).clean
		if got > cleanest and id != &"stoker" and id != &"eye" and id != &"walker":
			cleanest = got
			best = id
	radio.frequency = gods.carrier(best, world.time)
	await physics_frames(5)
	var under := radio.hiss.volume_db
	var carriers := Dial.carriers(gods, world.time)
	radio.frequency = (carriers[2][0] + carriers[3][0]) * 0.5
	await physics_frames(5)
	var between := radio.hiss.volume_db
	print("static under %s (clean %.2f): %.1f dB; between stations: %.1f dB" % [Gods.title(best), cleanest, under, between])
	check(radio.channel == Radio.STATIC and between - under > 20.0,
		"under a clean signal the static sinks far below the static between stations (%.0f dB)" % (between - under))

	weather_everywhere(1.0)
	radio.frequency = gods.carrier(best, world.time)
	await physics_frames(5)
	print("its way blocked by a storm: %.1f dB, clean %.2f" % [radio.hiss.volume_db, radio.reception.clean])
	check(radio.reception.clean == 0.0 and radio.hiss.volume_db > under + 20.0, "with its way blocked, the static is all there is")
