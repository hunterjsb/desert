extends MenuProbe
## The system menu's controls reader and console show the current bindings.
## Rebinding a key or mouse action updates the open reader and the actions work.


func run() -> void:
	await open_main(false)
	var console := main.ui.dev_console
	press(&"ui_cancel")
	var system := main.ui.top()
	press(&"ui_down")
	press(&"ui_accept")
	for i in 3:
		await get_tree().process_frame
	var reader: ControlsPage = main.ui.top().find_children("*", "Control", true, false).filter(func(c: Control) -> bool: return c is ControlsPage)[0]
	var keys := reader.list.text
	check(_row(keys, "E", "take") and _row(keys, "click", "throw"),
		"the controls reader shows take and throw as bound, coloured")
	press(&"console")
	check(Controls.tint(Controls.key_for(&"console")) in console._head.text, "the console says what closes it")
	press(&"console")

	_rebind(&"hands_grab", _key(KEY_G))
	_rebind(&"console", _key(KEY_F10))
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	_rebind(&"hands_throw", right)
	for i in 2:
		await get_tree().process_frame
	keys = reader.list.text
	check(_row(keys, "G", "take") and _row(keys, "right click", "throw") and not _row(keys, "E", "take"),
		"the open reader follows rebound key and mouse actions")
	press(&"console")
	check(console.visible and Controls.tint("F10") in console._head.text, "the rebound console opens over the reader")
	press(&"console")
	press(&"ui_cancel")
	check(main.ui.top() == system and system.highlighted() == 1, "back restores the system menu's Controls selection")
	press(&"ui_cancel")
	check(not console.visible and not main.ui.is_open(), "closing the reader and its menu returns to play")


func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	return key


func _rebind(action: StringName, to: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, to)


## Whether the Controls reader has a row of this key, coloured, doing this.
func _row(keys: String, key: String, does: String) -> bool:
	return "%s[/right][/cell][cell]%s" % [Controls.tint(key), does] in keys
