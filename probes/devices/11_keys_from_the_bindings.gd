extends Probe
## Devices & mods probe 11: keys on screen come from the bindings. The keys
## list, its hint and the scenario menu show each action's key as it's bound,
## coloured. Rebind take, throw (to a mouse button), the keys list and the
## scenario menu, and every one of them follows, and the new keys work.

const MENU := preload("res://game/dev/scenario_menu.gd")


func run() -> void:
	var menu: CanvasLayer = MENU.new()
	add_child(menu)
	await get_tree().process_frame
	_press(&"toggle_keys")
	_press(&"dev_scenarios")
	await get_tree().process_frame
	var keys: String = Dev._keys.text
	print("take %s, throw %s, keys %s" % [Controls.key_for(&"hands_grab"), Controls.key_for(&"hands_throw"),
		Controls.key_for(&"toggle_keys")])
	check(Controls.tint("E") + "  pick up" in keys and Controls.tint("click") + "  throw" in keys,
		"the keys list shows take and throw as bound, coloured")
	check(Controls.tint("F2") in menu._list.text, "and the scenario menu says what closes it")

	_rebind(&"hands_grab", _key(KEY_G))
	_rebind(&"toggle_keys", _key(KEY_F9))
	_rebind(&"dev_scenarios", _key(KEY_F10))
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	_rebind(&"hands_throw", right)
	await get_tree().process_frame
	keys = Dev._keys.text
	print("rebound: take %s, throw %s, keys %s" % [Controls.key_for(&"hands_grab"), Controls.key_for(&"hands_throw"),
		Controls.key_for(&"toggle_keys")])
	check(Controls.tint("G") + "  pick up" in keys and Controls.tint("right click") + "  throw" in keys
		and not Controls.tint("E") + "  " in keys, "rebound, the keys list follows, a mouse button too")
	check(Controls.tint("F9") in Dev._hint.text, "and so does its hint")
	_press(&"dev_scenarios")
	_press(&"dev_scenarios")
	check(menu.visible and Controls.tint("F10") in menu._list.text, "and the scenario menu, opened by its new key")
	_press(&"toggle_keys")
	check(not Dev._keys_layer.visible, "the keys list closes on its new key")


func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	return key


func _rebind(action: StringName, to: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, to)


## The key bound to an action, pressed and let go.
func _press(action: StringName) -> void:
	var key: InputEvent = InputMap.action_get_events(action)[0].duplicate()
	key.pressed = true
	get_viewport().push_input(key)
	key = key.duplicate()
	key.pressed = false
	get_viewport().push_input(key)
