extends MenuProbe
## Devices & mods probe 11: keys on screen come from the bindings. The keys
## list, its hint and the dev console show each action's key as it's bound,
## coloured. Rebind take, throw (to a mouse button), the keys list and the
## console, and every one of them follows, and the new keys work.


func run() -> void:
	await open_main(false)
	var console := main.ui.console
	press(&"toggle_keys")
	await get_tree().process_frame
	var keys: String = Dev._keys.text
	print("take %s, throw %s, keys %s, console %s" % [Controls.key_for(&"hands_grab"), Controls.key_for(&"hands_throw"),
		Controls.key_for(&"toggle_keys"), Controls.key_for(&"console")])
	check(Controls.tint("E") + "  pick up" in keys and Controls.tint("click") + "  throw" in keys,
		"the keys list shows take and throw as bound, coloured")
	press(&"console")
	check(Controls.tint(Controls.key_for(&"console")) in console._out.text, "and the console says what closes it")
	press(&"console")

	_rebind(&"hands_grab", _key(KEY_G))
	_rebind(&"toggle_keys", _key(KEY_F11))
	_rebind(&"console", _key(KEY_F10))
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	_rebind(&"hands_throw", right)
	await get_tree().process_frame
	keys = Dev._keys.text
	print("rebound: take %s, throw %s, keys %s, console %s" % [Controls.key_for(&"hands_grab"),
		Controls.key_for(&"hands_throw"), Controls.key_for(&"toggle_keys"), Controls.key_for(&"console")])
	check(Controls.tint("G") + "  pick up" in keys and Controls.tint("right click") + "  throw" in keys
		and not Controls.tint("E") + "  " in keys, "rebound, the keys list follows, a mouse button too")
	check(Controls.tint("F11") in Dev._hint.text, "and so does its hint")
	press(&"console")
	check(console.visible and Controls.tint("F10") in console._out.text, "and the console, opened by its new key")
	press(&"console")
	press(&"toggle_keys")
	check(not console.visible and not Dev._keys_layer.visible, "both close on their new keys")


func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	return key


func _rebind(action: StringName, to: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, to)
