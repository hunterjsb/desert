extends MenuProbe
## Profile & saves probe 17: a deed is kept. In a run, reaching Port Morgan
## records The Old City there and then, with its run: the seed, the origin and
## not Ironman. The next session's profile, read back from its file, still
## has it.


func run() -> void:
	await open_main(false)
	await started()
	main.ui.dev_console.run("goto port_morgan")
	await physics_frames(5)
	var profile := get_node(^"/root/Profile")
	var kept: Dictionary = profile.deeds().get("port_morgan", {})
	check(kept.get("seed") == world.run_seed and kept.get("origin") == "surveyor" and kept.get("ironman") == false,
		"reaching Port Morgan records it with its run (%s)" % kept)
	profile.dir = user_dir
	check(profile.did("port_morgan"), "the next session's profile still has it")
