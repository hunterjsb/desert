extends MenuProbe
## Menus & UI probe 4: New game asks over a save, and declining leaves the
## save untouched. The question comes with the safe answer highlighted;
## confirming that, or back, declines, and the save is neither deleted nor
## replaced. Accepting deletes it and starts a fresh run, not the saved one.
## The saves here are a stand-in.


func run() -> void:
	var saves := await fake_saves(true)
	await open_main()
	var menu := main.ui.top()
	press(&"ui_down")
	check(menu.highlighted() == 1 and menu.words()[1] == "NEW GAME", "menu down highlights New game")
	press(&"ui_accept")
	var ask := main.ui.top()
	check(ask != menu and ask.highlighted() == 0 and not main.in_run(),
		"New game over a save asks first, the safe answer highlighted (%s)" % ", ".join(ask.words()))
	press(&"ui_accept")
	check(main.ui.top() == menu and menu.highlighted() == 1 and _untouched(saves),
		"declining goes back to the menu, the save untouched")
	press(&"ui_accept")
	press(&"ui_cancel")
	check(main.ui.top() == menu and _untouched(saves), "back declines too")
	press(&"ui_accept")
	press(&"ui_down")
	press(&"ui_accept")
	await faded_in()
	check(main.in_run() and saves.deleted == 1 and saves.restored == null and main.world().run_seed != FakeSaves.SEED,
		"accepting deletes the save and starts a fresh run")
	saves.free()


func _untouched(saves: FakeSaves) -> bool:
	return saves.has and saves.deleted == 0 and saves.saved == null and saves.restored == null and not main.in_run()
