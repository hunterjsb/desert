extends SavesProbe
## Radio probe 75: a strung reel survives a save. An antenna reel clipped to a
## radio and set down ten metres off, its wire strung, is saved; resumed into
## a fresh world on the same seed, the reel is still clipped to that radio and
## the radio hears on its wire, and the run's frequency marks come back with it.


func run() -> void:
	saves = get_node("/root/Saves")
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter"], [0.0, 2.0]) as Radio
	var reel := Scenarios.standing(world, &"antenna_reel", [], [10.0, 2.0]) as AntennaReel
	await physics_frames(10)
	reel.clip(radio)
	DialMarks.add(world, 1040.0, "1040 kHz", Color.CYAN, 1.0)
	await physics_frames(60)
	print("saved: %.1f m strung, the radio's wire %.1f m" % [reel.strung(), radio.wire.x])
	check(reel.radio == radio and radio.wire.x > 5.0, "strung: the radio hears on the reel's wire")
	check(saves.save(world), "saved")

	check(await resume(), "resumed")
	await physics_frames(60)
	var radios := get_tree().get_nodes_in_group(Radio.GROUP)
	var reels := get_tree().get_nodes_in_group(AntennaReel.GROUP)
	check(radios.size() == 1 and reels.size() == 1, "one radio and one reel come back")
	if radios.size() != 1 or reels.size() != 1:
		return
	var back := reels[0] as AntennaReel
	var set := radios[0] as Radio
	print("resumed: %.1f m strung, the radio's wire %.1f m" % [back.strung(), set.wire.x])
	check(back.radio == set and set.wire.x > 5.0, "resumed, still clipped to its radio, which hears on its wire")
	check(DialMarks.all(world).size() == 1, "and the run's marks come back with it")
