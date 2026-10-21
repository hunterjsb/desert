extends MenuProbe
## Home navigation opens from carry view without changing gear or selected lines.

class HomeSignal extends Node:
	var state := {"marked": true, "supported": false, "live": false, "metres": 1240.0, "bearing": PI * 0.25, "status": "Beacon out of range"}
	var refused := true
	func nav() -> Dictionary:
		return state
	func unmark() -> String:
		if refused:
			return "Return near Home before unmarking"
		state = {"marked": false}
		return ""


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
	check(suit._home_view.is_visible_in_tree() and not suit._home_view._unmark.visible,
		"the carry entry opens safely before a Home service exists")
	await get_tree().process_frame
	await get_tree().process_frame
	check(suit._home_view.get_viewport_rect().encloses(suit._home_view._panel.get_global_rect()),
		"the empty Home panel fits the viewport")
	var home_signal := HomeSignal.new()
	add_child(home_signal)
	suit._home_view.source = func() -> Object: return home_signal
	suit._home_view.refresh()
	check(suit._home_view._reception.text.contains("Last-known") and suit._home_view._support.text.contains("pending"),
		"a missing beacon fix cannot claim live reception or ready support")
	suit._home_view._forget()
	check(home_signal.state.marked and suit._home_view._message.text == "Return near Home before unmarking",
		"a refused unmark keeps Home and explains the refusal")
	home_signal.state.live = true
	home_signal.state.supported = true
	suit._home_view.refresh()
	check(not suit._home_view._reception.text.contains("Last-known") and not suit._home_view._support.text.contains("pending"),
		"current service state replaces the stale fix")
	home_signal.state.metres = NAN
	home_signal.state.bearing = NAN
	suit._home_view.refresh()
	check(not suit._home_view._direction.visible and not suit._home_view._facing.visible,
		"missing coordinates cannot invent a direction or distance")
	home_signal.refused = false
	suit._home_view._forget()
	check(not suit._home_view._unmark.visible and not home_signal.state.marked, "a safe explicit unmark clears the entry")
	check(suit.close() and suit.open and not suit._home_view.visible, "Back returns to carried gear")
	press(&"inventory")
	check(not suit.open and suit.carried == before, "closing navigation preserves carried equipment")
