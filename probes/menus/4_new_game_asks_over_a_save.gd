extends MenuProbe
## Menus & UI probe 4: New game asks over a save, and declining leaves the
## save untouched. The question comes with the safe answer highlighted;
## confirming that, or back, declines, and the save file is just as it was.
## Accepting asks the mode, and then deletes the save and starts a fresh run,
## not the saved one.


func run() -> void:
	await open_main(false)
	# A run lived in for a while, saved and quit.
	world.time += 600.0
	press(&"ui_cancel")
	press(&"ui_down")
	press(&"ui_down")
	press(&"ui_accept")
	await faded_in()
	var kept := FileAccess.get_file_as_bytes(saves().path())
	check(saves().has_run() and not kept.is_empty(), "a saved run to start from")

	var menu := main.ui.top()
	press(&"ui_down")
	check(menu.highlighted() == 1 and menu.words()[1] == "NEW GAME", "menu down highlights New game")
	press(&"ui_accept")
	var ask := main.ui.top()
	check(ask != menu and ask.highlighted() == 0 and not main.in_run(),
		"New game over a save asks first, the safe answer highlighted (%s)" % ", ".join(ask.words()))
	press(&"ui_accept")
	check(main.ui.top() == menu and menu.highlighted() == 1 and _untouched(kept),
		"declining goes back to the menu, the save untouched")
	press(&"ui_accept")
	press(&"ui_cancel")
	check(main.ui.top() == menu and _untouched(kept), "back declines too")
	press(&"ui_accept")
	press(&"ui_down")
	press(&"ui_accept")
	check(main.ui.top().words() == PackedStringArray(["NORMAL", "IRONMAN"]) and _untouched(kept),
		"accepting asks the mode, the save still untouched")
	press(&"ui_accept")
	await faded_in()
	check(main.in_run() and not saves().has_run() and not world.has_meta(&"resumed"),
		"then the save is deleted and a fresh run starts")


func _untouched(kept: PackedByteArray) -> bool:
	return saves().has_run() and FileAccess.get_file_as_bytes(saves().path()) == kept and not main.in_run()
