extends MenuProbe
## Home navigation opens from carry view without changing gear or selected lines.

class HomeSignal extends Node:
	var state := {"marked": true, "supported": false, "live": false, "metres": 1240.0, "bearing": PI * 0.25}
	func nav() -> Dictionary:
		return state


func run() -> void:
	get_window().size = Vector2i(1280, 720)
	await open_main(false)
	var suit := world.player.suit
	var before := suit.carried.duplicate()
	check(not suit._home_view.is_visible_in_tree(), "Home navigation is hidden during play")
	press(&"inventory")
	await physics_frames(2)
	suit._home_button.pressed.emit()
	await physics_frames(2)
	check(suit._home_view.is_visible_in_tree(), "the carry entry opens safely before a Home service exists")
	await get_tree().process_frame
	await get_tree().process_frame
	check(suit._home_view.get_viewport_rect().encloses(suit._home_view._panel.get_global_rect()),
		"the empty Home panel fits the viewport")
	var home_signal := HomeSignal.new()
	add_child(home_signal)
	suit._home_view.source = func() -> Object: return home_signal
	suit._home_view.refresh()
	var stale := suit._home_view._reception.text
	home_signal.state.live = true
	suit._home_view.refresh()
	check(suit._home_view._direction.visible and suit._home_view._reception.text != stale,
		"a live fix reads differently from a stale one")
	home_signal.state.metres = NAN
	home_signal.state.bearing = NAN
	suit._home_view.refresh()
	check(not suit._home_view._direction.visible and not suit._home_view._facing.visible,
		"missing coordinates cannot invent a direction or distance")
	check(suit.close() and suit.open and not suit._home_view.visible, "Back returns to carried gear")
	press(&"inventory")
	check(not suit.open and suit.carried == before, "closing navigation preserves carried equipment")
