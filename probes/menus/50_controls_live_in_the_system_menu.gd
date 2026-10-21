extends MenuProbe
## The controls reader belongs to menus, fits the screen and holds gameplay input.


func run() -> void:
	get_window().size = Vector2i(1280, 720)
	await open_main(false)
	check(not InputMap.has_action(&"toggle_keys"), "the removed overlay has no toggle action")
	press(&"ui_cancel")
	var system := main.ui.top()
	_select("CONTROLS")
	await _layout()
	var reader := _reader()
	if reader == null:
		return
	var screen := get_viewport().get_visible_rect()
	check(screen.encloses(reader.get_global_rect()) and screen.encloses(main.ui.top()._items[0].button.get_global_rect()),
		"the page and Back fit at 720p")
	check(reader.bar.visible, "the long controls list has a page bar")
	var clock := world.time
	Input.action_press(&"move_forward")
	await physics_frames(60)
	check(world.time - clock > 0.9 and world.player.own.length() < 0.01 and not Controls.playing(),
		"the controls menu holds movement while the world advances")
	Input.action_release(&"move_forward")
	press(&"ui_down")
	check(reader.scroll > 0.0, "menu navigation scrolls the reader")
	var wheeled_from := reader.scroll
	_wheel(reader)
	check(reader.scroll > wheeled_from, "the wheel reaches further bindings")
	var before := reader.scroll
	var bar := reader.bar.get_global_rect()
	drag(Vector2(bar.get_center().x, bar.position.y + 2.0), Vector2(bar.get_center().x, bar.end.y - 2.0))
	check(reader.scroll > before, "dragging the page bar reaches the end")
	Dev.set_scene_keys([["H", "fixture control"]])
	await _layout()
	check(Controls.tint("H") in reader.list.text and "fixture control" in reader.list.text,
		"scene-specific controls join the same reader")
	var bindings := reader.list.text
	press(&"ui_cancel")
	check(main.ui.top() == system and system.highlighted() == system.words().find("CONTROLS"),
		"Back restores the exact system menu selection")
	_select("OPTIONS")
	var options := main.ui.top()
	_select("CONTROLS")
	await _layout()
	check(_reader() != null and _reader().list.text == bindings,
		"Options opens the same bindings reader")
	Dev.set_scene_keys([])
	press(&"ui_accept")
	check(main.ui.top() == options, "confirming Back returns to Options")
	for i in 2:
		press(&"ui_cancel")
	check(not main.ui.is_open() and Controls.playing(), "closing the menus restores play")


func _select(word: String) -> void:
	var menu := main.ui.top()
	var wanted := menu.words().find(word)
	check(wanted >= 0, "the menu offers " + word)
	if wanted < 0:
		return
	for i in menu.words().size():
		if menu.highlighted() == wanted:
			break
		press(&"ui_down")
	press(&"ui_accept")


func _reader() -> ControlsPage:
	for child in main.ui.top().find_children("*", "Control", true, false):
		if child is ControlsPage:
			return child
	return null


func _wheel(reader: ControlsPage) -> void:
	var wheel := InputEventMouseButton.new()
	wheel.position = reader.get_global_rect().get_center()
	wheel.global_position = wheel.position
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.factor = 1.0
	wheel.pressed = true
	get_viewport().push_input(wheel)
	wheel = wheel.duplicate()
	wheel.pressed = false
	get_viewport().push_input(wheel)


func _layout() -> void:
	for i in 4:
		await get_tree().process_frame
