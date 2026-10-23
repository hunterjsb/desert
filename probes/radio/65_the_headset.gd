extends ShieldProbe
## Radio probe 65: the headset (gonkhub, 2026-10-22: "just a headset item, that
## can attach a cable. The other end of the cable can attach to a radio misc mod
## slot"). On a cable from a radio's misc bay, worn in the suit, the set
## playing is in your ears from wherever it stands, with no panning, and the
## wind and storm turned down for you; worn with its cable plugged in, it goes
## in the suit; walk off past the cable's length and its plug pulls out, the
## set back where it stands, the weather as loud as ever.


func run() -> void:
	await load_storm(0.0)
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	radio.frequency = Radio.gods_of(world).carrier(&"walker", world.time)
	var headset := wire_headset(radio)
	var cable: Cable = headset.get_meta(&"cable")
	await physics_frames(10)
	check(not radio.headset_on(), "set down beside it, the headset does nothing")
	headset.global_position = world.player.global_position + Vector3.UP
	world.player.hands.hold(headset)
	await physics_frames(30)
	check(world.player.suit.put_in(), "worn, it goes in the suit with its cable plugged in")
	await physics_frames(30)
	var weather := AudioServer.get_bus_index(Sounds.WEATHER)
	print("worn: on its headset %s, the weather %.1f dB" % [radio.headset_on(), AudioServer.get_bus_volume_db(weather)])
	check(radio.headset_on() and radio.reader.panning_strength == 0.0, "worn, the set's in your ears")
	check(AudioServer.get_bus_volume_db(weather) <= tuning.headset_duck_db + 0.5, "the wind and storm turned down")
	var player := world.player
	var away := player.global_position + Vector3(cable.length + 3.0, 0.0, 0.0)
	for i in 60:
		player.global_position = player.global_position.lerp(away, 0.1)
		await get_tree().physics_frame
	print("walked off: the radio %.1f m away, on its headset %s" % [radio.global_position.distance_to(
		world.player.global_position), radio.headset_on()])
	check(not radio.headset_on() and radio.reader.panning_strength == 1.0, "past the cable's length its plug pulls out")
	await physics_frames(60)
	check(AudioServer.get_bus_volume_db(weather) > -0.5, "the weather as loud as ever")
	check(cable.joined().is_empty(), "a headset's cable carries no power")
