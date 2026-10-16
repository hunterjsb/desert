extends MenuProbe
## Menus & UI probe 3: the menu's default. With no save, Resume is absent, New
## game is highlighted, and confirm starts a run. Save & quit from that run
## makes a save, and back on the menu Resume is there and highlighted; confirm
## resumes it: a world built on the saved run's seed, put back once the sand
## round you has settled. The saves here are a stand-in.


func run() -> void:
	await open_main()
	var menu := main.ui.top()
	check(menu.words() == PackedStringArray(["NEW GAME", "OPTIONS", "QUIT"]) and menu.highlighted() == 0,
		"with no save, Resume is absent and New game is highlighted (%s)" % ", ".join(menu.words()))
	press(&"ui_accept")
	await faded_in()
	check(main.in_run() and main.view == null and not main.ui.is_open() and not Controls.mouse_free,
		"confirm starts a run, the menu's world gone and the mouse captured")

	var saves := await fake_saves(false)
	var played := main.world()
	press(&"ui_cancel")
	check(main.ui.top().words() == PackedStringArray(["OPTIONS", "SAVE & QUIT"]), "the system menu holds Options and Save & quit")
	press(&"ui_down")
	press(&"ui_accept")
	await faded_in()
	menu = main.ui.top()
	check(saves.saved == played and not main.in_run() and menu != null and menu.root,
		"Save & quit saves the run and goes back to the main menu")
	check(menu.words() == PackedStringArray(["RESUME", "NEW GAME", "OPTIONS", "QUIT"]) and menu.highlighted() == 0,
		"with a save, Resume is there and highlighted (%s)" % ", ".join(menu.words()))
	press(&"ui_accept")
	await faded_in()
	check(main.in_run() and saves.restored == main.world() and main.world().run_seed == FakeSaves.SEED,
		"confirm resumes it, on the saved run's seed")
	check(saves.settled_then and saves.deleted == 0, "put back on settled sand, and never deleted")
	saves.free()
