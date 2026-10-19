extends MenuProbe
## Menus & UI probe 18: console access from nested menus and search fields.
## Closing restores the same menu and its focused card or field; unlocking
## starts updates their already-open menu.


func run() -> void:
	await open_main()
	var ui := main.ui
	ui.open(ui.origins())
	press(&"console")
	check(ui.dev_console.visible, "console opens over New game")
	type("unlockall")
	press(&"ui_text_submit")
	press(&"console")
	check(not ui.dev_console.visible and ui.top().words().size() == Kit.origins().size()
		and not "????" in ui.top().words() and ui.top().highlighted() == 0,
		"unlockall refreshes the covered origins and restores its selection")
	ui.close_top()
	ui.open(ui.options())
	await _restored("options")
	ui.close_top()
	ui.open(ui.deeds())
	await get_tree().process_frame
	var deeds: DeedsGrid = ui.top().find_children("*", "DeedsGrid", true, false)[0]
	deeds._cards[&"board_distance"].grab_focus()
	await _restored("deed card")
	ui.close_top()
	await main.new_game()
	await faded_in()
	await started()
	ui.open(ui.system_menu())
	await _restored("system menu")
	ui.open(ui.options())
	await _restored("nested run options")
	ui.close_top()
	ui.close_top()
	ui.open_creative()
	var creative: CreativeGrid = ui.top().find_children("*", "CreativeGrid", true, false)[0]
	creative._search.grab_focus()
	creative._search.edit()
	type("mast")
	await _restored("creative search")
	check(creative._search.text == "mast", "console action does not type into search")


func _restored(label: String) -> void:
	var ui := main.ui
	var menu := ui.top()
	var focused := get_viewport().gui_get_focus_owner()
	press(&"console")
	await get_tree().process_frame
	check(ui.dev_console.visible and ui.dev_console._line.has_focus() and not menu.visible,
		"console owns input over " + label)
	press(&"ui_cancel")
	await get_tree().process_frame
	check(not ui.dev_console.visible and ui.top() == menu and menu.visible
		and get_viewport().gui_get_focus_owner() == focused and Controls.mouse_free,
		"closing restores " + label)
