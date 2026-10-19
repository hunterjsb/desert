extends MenuProbe
## Dev probe 6: the creative menu. Its action opens it over a run, which is a
## dev run from then on; a card picked puts a fresh one of its thing in your
## hands, and with them full in your suit. Every thing give makes is on it,
## once. Its action closes it again.


func run() -> void:
	await open_main(false)
	await started()
	var ui := main.ui
	var player := world.player
	check(world.counts_deeds, "a run counts deeds")
	press(&"creative")
	await get_tree().process_frame
	var grids := ui.top().find_children("*", "CreativeGrid", true, false) if ui.is_open() else []
	check(not grids.is_empty() and not world.counts_deeds, "its action opens it, and the run is a dev run")
	if grids.is_empty():
		return
	var grid: CreativeGrid = grids[0]
	grid._cards[&"battery"].grab_focus()
	press(&"ui_accept")
	await physics_frames(10)
	var held := player.hands.held as Battery
	check(held != null and held.get_meta(&"catalog") == &"battery" and held.charge_wh == held.capacity(),
		"a battery picked comes to your hands, fresh")
	grid._cards[&"radio"].grab_focus()
	press(&"ui_accept")
	check(player.hands.held == held and player.suit.carried.back() is Radio, "with your hands full, a radio goes in your suit")
	var on_it := Array(CreativeGrid.ids()).map(func(id: StringName) -> String: return str(id))
	var made := Array(DevConsole._give_ids())
	on_it.sort()
	made.sort()
	check(on_it == made, "every thing give makes is on it, once (%d of %d)" % [on_it.size(), made.size()])
	press(&"creative")
	check(not ui.is_open(), "its action closes it")
