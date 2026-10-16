extends SavesProbe
## Profile & saves probe 4: versions. A save or a profile from a version this
## build doesn't know, or a file that isn't one at all, is refused with a
## message saying why, and nothing of it is loaded: the world stays as it
## was, and a refused profile is never written over except by a reset.


func run() -> void:
	saves = get_node("/root/Saves")
	var profile := get_node("/root/Profile")
	await load_world(1234)
	check(saves.save(world), "saved")
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION + 1, data)
	check(not saves.has_run(), "a save from an unknown version isn't offered")
	check(str(saves.refused).contains("version %d" % (saves.VERSION + 1)), "and says why (%s)" % saves.refused)
	world.time = 77.0
	var things := world.content.get_child_count()
	check(not saves.restore(world), "resuming it is refused")
	check(world.time == 77.0 and world.content.get_child_count() == things and not saves.restoring,
		"and nothing of it was loaded")
	_garbage(saves.path())
	check(not saves.has_run() and saves.refused.contains("isn't"), "a file that isn't a save is refused (%s)" % saves.refused)

	profile.dir = user_dir
	SaveFile.write(profile.path(), profile.KIND, profile.VERSION + 1, {"unlocks": {"old": 1.0}, "found": {}})
	profile.dir = user_dir
	check(not profile.has("old"), "a profile from an unknown version isn't read")
	check(str(profile.refused).contains("version %d" % (profile.VERSION + 1)), "and says why (%s)" % profile.refused)
	profile.discover("turbine")
	var kept: Dictionary = SaveFile.read(profile.path(), profile.KIND, profile.VERSION + 1).data
	check(kept.get("unlocks", {}).has("old"), "nor written over")
	profile.reset()
	profile.dir = user_dir
	check(profile.refused == "" and not profile.has("old"), "until a reset starts it afresh")


func _garbage(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not a save at all")
	file.close()
