extends SavesProbe
## Profile & saves probe 48: a worn headset survives a save. Worn in the suit on
## its cable from a radio's misc bay, it resumes still worn and still on that
## radio's cable, the set in your ears.


func run() -> void:
	saves = get_node("/root/Saves")
	await load_world(1234)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	var headset := wire_headset(radio)
	headset.global_position = world.player.global_position + Vector3.UP
	world.player.hands.hold(headset)
	await physics_frames(30)
	check(world.player.suit.put_in(), "worn in the suit")
	await physics_frames(10)
	check(radio.listened_close(), "the set's in your ears")
	check(saves.save(world), "saved")
	check(await resume(), "resumed")
	var back: Radio = null
	for body in world.content.get_children():
		if body is Radio:
			back = body
	var worn := world.player.suit.carried.filter(func(thing: Node) -> bool:
		return thing.get_meta(&"catalog", &"") == &"headset")
	print("resumed: %d headset worn, the radio's headset %s" % [worn.size(), back.headset() if back else null])
	check(worn.size() == 1 and back != null and back.headset() == worn[0], "still worn, on that radio's cable")
	check(back != null and back.listened_close(), "the set still in your ears")
