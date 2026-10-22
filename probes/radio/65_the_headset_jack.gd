extends ShieldProbe
## Radio probe 65: the headset jack. In the radio's misc bay, with the set
## playing and you within its cord, it's in your ears from wherever it stands,
## with no panning, and the wind and storm turned down for you; walk past its
## cord and it's back on the set, the weather as loud as ever.


func run() -> void:
	await load_storm(0.0)
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"headset_jack"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	radio.frequency = Radio.gods_of(world).carrier(&"walker", world.time)
	await physics_frames(30)
	var weather := AudioServer.get_bus_index(Sounds.WEATHER)
	print("within its cord: on its headset %s, the weather %.1f dB" % [radio.headset_on(),
		AudioServer.get_bus_volume_db(weather)])
	check(radio.headset_on() and radio.reader.panning_strength == 0.0, "within its cord it's in your ears")
	check(AudioServer.get_bus_volume_db(weather) <= tuning.headset_duck_db + 0.5, "the wind and storm turned down")
	radio.global_position += Vector3(tuning.headset_cord_m + 2.0, 0.0, 0.0)
	await physics_frames(30)
	check(not radio.headset_on() and radio.reader.panning_strength == 1.0, "past its cord it's back on the set")
	check(AudioServer.get_bus_volume_db(weather) > -0.5, "the weather as loud as ever")
