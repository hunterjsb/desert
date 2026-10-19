extends SavesProbe
## Profile & saves probe 14: a save from before the chassis rework is
## refused, plainly, and the profile carries on. A version 1 run save on disk
## isn't offered and says why in plain words, resuming it changes nothing,
## and the profile's deeds and unlocks are as they were.


func run() -> void:
	saves = get_node("/root/Saves")
	var profile := get_node("/root/Profile")
	profile.dir = user_dir
	await load_world(1234)
	profile.unlock("salvager")
	world.counts_deeds = true
	Deeds.done(world, &"port_morgan")
	check(saves.save(world), "saved")
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	SaveFile.write(saves.path(), saves.KIND, 1, data)
	check(not saves.has_run(), "a version 1 save isn't offered")
	check(saves.refused == saves.OLDER[1], "and says why, plainly (%s)" % saves.refused)
	var things := world.content.get_child_count()
	check(not saves.restore(world) and world.content.get_child_count() == things, "resuming it changes nothing")
	profile.dir = user_dir
	check(profile.has("salvager") and profile.did(&"port_morgan"), "the profile's unlocks and deeds carry on")
