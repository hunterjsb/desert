extends MenuProbe
## Menus & UI probe 15: the console scrolls back. After help has said more
## than it shows, the wheel scrolls up to its first lines, and nothing of the
## game's on the wheel hears it: what you hold stays where it was. The page
## actions scroll a page each way, the line keeping its focus, and a command
## run shows at once.


func run() -> void:
	await open_main(false)
	await started()
	var console := main.ui.dev_console
	var hands := world.player.hands
	console.run("give battery")
	await physics_frames(30)
	press(&"console")
	console.run("help")
	var latest: String = console._out.text
	var away := hands._away
	for i in 20:
		_wheel(MOUSE_BUTTON_WHEEL_UP, true)
		_wheel(MOUSE_BUTTON_WHEEL_UP, false)
	await physics_frames(2)
	check(console._out.text.contains("help  these commands") and not console._out.text.contains("meltdown"),
		"the wheel scrolls up to help's first lines")
	check(hands.held != null and hands._away == away, "what you hold stays where it was (%.2f m, %.2f before)"
		% [hands._away, away])
	press(&"ui_page_down")
	press(&"ui_page_down")
	press(&"ui_page_down")
	check(console._out.text == latest, "the page actions bring it back down")
	press(&"ui_page_up")
	check(console._out.text != latest and console._line.has_focus(), "and back up, the line keeping its focus")
	console.run("warp 2")
	check(world.time_warp == 2.0 and console._out.text.ends_with("time x2"), "a command run shows at once")


## The wheel turned a notch with ctrl held, as bring-near is bound.
func _wheel(button: MouseButton, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = down
	event.ctrl_pressed = true
	event.position = get_viewport().get_visible_rect().size * 0.5
	event.global_position = event.position
	get_viewport().push_input(event)
