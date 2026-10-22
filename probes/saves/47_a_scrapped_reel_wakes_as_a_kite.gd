extends SavesProbe
## Profile & saves probe 47: a scrapped reel wakes as a kite. The antenna reel
## was scrapped (gonkhub, 2026-10-22), so a save holding one is still offered
## and resumes with the antenna kite in its place.


func run() -> void:
	saves = get_node("/root/Saves")
	await load_world(1234)
	var set_down := Scenarios.standing(world, &"antenna_kite", [], [2.0, 2.0])
	set_down.freeze = true
	await physics_frames(2)
	check(saves.save(world), "saved")
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	var reels := 0
	for rec: Dictionary in data.things:
		if rec.id == &"antenna_kite":
			rec.id = &"antenna_reel"
			reels += 1
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION, data)
	check(reels == 1 and saves.has_run(), "a save holding a reel is still offered")
	check(await resume(), "it resumes")
	var kites := world.content.get_children().filter(func(body: Node) -> bool: return body is AntennaKite).size()
	print("after resume: %d antenna kite" % kites)
	check(kites == 1, "the reel wakes as an antenna kite")
