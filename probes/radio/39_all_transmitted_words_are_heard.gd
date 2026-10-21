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
	check(await _heard(radio, func() -> String: return Radio.spoken_words(radio.reception.get("words", ""))),
		"the god's transmitted words reach speech")
	radio.frequency = Dial.BEACON_KHZ
	await physics_frames(2)
	radio.target = {"x": x + 100.0, "z": z, "coord": Vector2i.ZERO, "index": 0}
	check(await _heard(radio, func() -> String: return radio.say_point(radio.beacon_bearing()), true),
		"the beacon's actual bearing reaches speech too")


## Physics updates the receiver; its diagnostic consumer runs on process frames.
func _heard(radio: Radio, expected: Callable, contains := false) -> bool:
	await physics_frames(2)
	var broadcast := world.player.get_node(^"Broadcast") as Broadcast
	var until := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		var words := " ".join(radio.spoken)
		var wanted: String = expected.call()
		if words != "" and wanted != "" and broadcast.reading == words \
				and (words.contains(wanted) if contains else words == wanted):
			return true
	printerr("speech handoff: wanted '%s', spoken '%s', heard '%s'" % [expected.call(), " ".join(radio.spoken), broadcast.reading])
	return false
