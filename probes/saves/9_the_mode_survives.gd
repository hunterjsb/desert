extends MenuProbe
## Profile & saves probe 9: the mode survives. Ironman chosen at New game,
## saved and quit, and resumed, the run is Ironman's still: no Save in its
## system menu, and dying deletes its save and begins a new run in place, on
## a new seed. A save from before there were modes resumes as Normal's.


func run() -> void:
	await open_main()
	press(&"ui_accept")
	press(&"ui_accept")
	press(&"ui_down")
	press(&"ui_accept")
	await faded_in()
	check(main.in_run() and main.ironman(), "Ironman chosen at New game")
	press(&"ui_cancel")
	check(main.ui.top().words() == PackedStringArray(["OPTIONS", "SAVE & QUIT"]),
		"an Ironman run's system menu has no Save (%s)" % ", ".join(main.ui.top().words()))
	press(&"ui_down")
	press(&"ui_accept")
	await faded_in()
	check(saves().has_run() and saves().ironman(), "Save & quit keeps the run's mode in its save")
	# Resume, then carry on.
	press(&"ui_accept")
	press(&"ui_accept")
	await faded_in()
	check(main.in_run() and world.has_meta(&"resumed") and main.ironman(), "resumed, it's Ironman's still")
	press(&"ui_cancel")
	check(main.ui.top().words() == PackedStringArray(["OPTIONS", "SAVE & QUIT"]), "and its system menu has no Save")
	press(&"ui_cancel")

	var old := world
	var old_seed := world.run_seed
	var player := world.player
	for part in player.suit.carried:
		if part is Supply and part.kind == &"water":
			part.drain(INF)
	player.vitals.thirst = 0.0
	player.vitals.health = 0.01
	for i in 120:
		await get_tree().physics_frame
		if main.world() != old:
			break
	world = main.world()
	check(world != old and world.run_seed != old_seed and not saves().has_run() and not main.ui.is_open()
		and main.ironman(), "dying deletes its save and begins a new Ironman run in place, no screen asking")

	# A save as an older build wrote it: no mode in it.
	check(main.save_run(), "the new run saved")
	var data: Dictionary = SaveFile.read(saves().path(), saves().KIND, saves().VERSION).data
	check(data.get("ironman") == true, "its save says Ironman")
	data.erase("ironman")
	SaveFile.write(saves().path(), saves().KIND, saves().VERSION, data)
	main.resume()
	await faded_in()
	check(main.in_run() and world.has_meta(&"resumed") and not main.ironman(), "a save with no mode resumes as Normal")
	press(&"ui_cancel")
	check(main.ui.top().words() == PackedStringArray(["OPTIONS", "SAVE", "SAVE & QUIT"]), "with Save in its system menu")
