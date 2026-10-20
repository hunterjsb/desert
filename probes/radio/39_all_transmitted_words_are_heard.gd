extends ShieldProbe
## Sound-only radio must deliver a god's words and a beacon's bearing to speech.

func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	var gods := Radio.gods_of(world)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var best := &""
	var strongest := 0.0
	for id in Gods.ids():
		if id in [&"walker", &"eye", &"stoker"]:
			continue
		radio.frequency = gods.carrier(id, world.time)
		var strength: float = radio.receive(id, x, z, world.time).clean
		if strength > strongest:
			strongest = strength
			best = id
	check(best != &"", "a god's real signal reaches the fixture")
	radio.frequency = gods.carrier(best, world.time)
	await physics_frames(5)
	await get_tree().process_frame
	var broadcast := world.player.get_node(^"Broadcast") as Broadcast
	check(" ".join(radio.spoken) != "" and " ".join(radio.spoken) == Radio.spoken_words(radio.reception.words)
		and broadcast.reading == " ".join(radio.spoken), "the god's transmitted words reach speech")
	radio.frequency = Dial.BEACON_KHZ
	await physics_frames(2)
	radio.target = {"x": x + 100.0, "z": z, "coord": Vector2i.ZERO, "index": 0}
	await physics_frames(5)
	await get_tree().process_frame
	check(" ".join(radio.spoken).contains(radio.say_point(radio.beacon_bearing())) and broadcast.reading == " ".join(radio.spoken),
		"the beacon's actual bearing reaches speech too")
