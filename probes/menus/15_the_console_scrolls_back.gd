extends MenuProbe
## Menus & UI probe 15: the console scrolls back. After it has said more than
## it shows, the wheel scrolls up to its first line, and nothing of the game's
## on the wheel hears it: what you hold stays where it was. The page actions
## scroll a page each way, the line keeping its focus. Its bar tracks each
## scroll, and dragged to its top shows the first line again. A command run
## shows at once.


func run() -> void:
	get_window().size = Vector2i(1920, 1080)
	await open_main(false)
	await started()
	var console := main.ui.dev_console
	var bar: PageBar = console._bar
	var hands := world.player.hands
	console.run("give battery")
	await physics_frames(30)
	press(&"console")
	for i in 4:
		console.run("help")
	await get_tree().process_frame
	var first: String = console._said[0]
	var latest := console.shown()
	check(bar.whole > bar.shown and bar.at + bar.shown == bar.whole,
		"it says more than shows, its bar at the foot (%d lines of %d)" % [bar.shown, bar.whole])
	var away := hands._away
	for i in 60:
		_wheel(MOUSE_BUTTON_WHEEL_UP, true)
		_wheel(MOUSE_BUTTON_WHEEL_UP, false)
	await physics_frames(2)
	check(console.shown().begins_with(first) and bar.at == 0.0, "the wheel scrolls up to its first line, its bar to the top")
	check(hands.held != null and hands._away == away, "what you hold stays where it was (%.2f m, %.2f before)"
		% [hands._away, away])
	for i in 6:
		press(&"ui_page_down")
	check(console.shown() == latest and bar.at + bar.shown == bar.whole, "the page actions bring it back down, its bar too")
	press(&"ui_page_up")
	check(console.shown() != latest and bar.at == maxf(bar.whole - 2.0 * bar.shown + 1.0, 0.0)
		and console._line.has_focus(), "and back up a page, its bar too, the line keeping its focus")
	var thumb: Vector2 = bar._thumb()
	var held := bar.global_position + Vector2(bar.size.x * 0.5, thumb.x + thumb.y * 0.5)
	drag(held, held - Vector2(0.0, bar.size.y))
	check(console.shown().begins_with(first) and bar.at == 0.0, "its bar dragged to the top shows the first line")
	console.run("warp 2")
	check(world.time_warp == 2.0 and console.shown().ends_with("time x2"), "a command run shows at once")


## The wheel turned a notch with ctrl held, as bring-near is bound.
func _wheel(button: MouseButton, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = down
	event.ctrl_pressed = true
	event.position = get_viewport().get_visible_rect().size * 0.5
	event.global_position = event.position
	get_viewport().push_input(event)
