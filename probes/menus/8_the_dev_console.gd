extends MenuProbe
## Menus & UI probe 8: the dev console. Its action opens it over a run, and
## while it's up what you type goes to it and nothing reaches the game: the
## move action held doesn't move you, and the inventory and keys list stay
## shut. warp 4 confirmed runs the clock four times as fast; scenario dusk
## puts you at dusk, in a run that's never saved from then on. Up brings back
## what was typed. Back closes it and nothing else, and then the same hold
## walks you; the console action closes it too.


func run() -> void:
	await open_main(false)
	await started()
	var player := world.player
	var console := main.ui.console
	press(&"console")
	check(console.visible and main.ui.holds_input() and Controls.mouse_free, "the console action opens it")

	Input.action_press(&"move_forward")
	type("warp 4")
	press(&"inventory")
	press(&"toggle_keys")
	await physics_frames(30)
	check(player.own.length() < 0.01 and player.mode == "stand" and not player.suit.open and not Dev._keys_layer.visible,
		"typing reaches only the console: held, the move action doesn't move you (%.2f m/s, %s)" % [player.own.length(), player.mode])
	press(&"ui_text_submit")
	check(world.time_warp == 4.0, "warp 4 runs the clock four times as fast (x%.1f)" % world.time_warp)

	type("scenario dusk")
	press(&"ui_text_submit")
	var hour := world.weather.day.time_of_day(world.time)
	var dusk: Dictionary = Scenarios.by_key("dusk")
	check(Dev.read("world/scn") == "dusk" and hour >= dusk.day[0] and hour <= dusk.day[1] and main.saves() == null,
		"scenario dusk puts you at dusk (%.3f of the day), a run that's never saved" % hour)
	press(&"ui_up")
	check(console._line.text == "scenario dusk", "up brings back what was typed")

	press(&"ui_cancel")
	check(not console.visible and not main.ui.is_open() and not Controls.mouse_free,
		"back closes it, and nothing else opens")
	await physics_frames(30)
	check(player.own.length() > 1.0, "closed, the same hold walks you (%.2f m/s)" % player.own.length())
	Input.action_release(&"move_forward")
	press(&"console")
	press(&"console")
	check(not console.visible and console._line.text == "", "the console action closes it too, typing nothing")


## Each character typed, as its key pressed and let go.
func type(text: String) -> void:
	for c in text:
		var key := InputEventKey.new()
		key.keycode = KEY_SPACE if c == " " else OS.find_keycode_from_string(c.to_upper())
		key.physical_keycode = key.keycode
		key.unicode = c.unicode_at(0)
		key.pressed = true
		get_viewport().push_input(key)
		key = key.duplicate()
		key.pressed = false
		get_viewport().push_input(key)
