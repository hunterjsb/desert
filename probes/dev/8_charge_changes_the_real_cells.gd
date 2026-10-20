extends MenuProbe
## Dev probe 8: charge changes the held cell or the targeted power pool's real cells.


func run() -> void:
	await open_main(false)
	await started()
	var console := main.ui.dev_console
	var cell := Catalog.part(&"battery") as Battery
	world.content.add_child(cell)
	world.player.hands.hold(cell)
	console.run("charge 0")
	check(cell.charge_wh == 0.0, "charge empties the held battery")
	console.run("charge 100")
	check(cell.charge_wh == cell.capacity(), "charge refills the real held battery")
	world.player.hands.stow()
	var deck := Catalog.device(&"chassis")
	world.content.add_child(deck)
	for x in [-0.2, 0.2]:
		deck.stick(Catalog.part(&"battery"), Transform3D(Basis.IDENTITY, Vector3(x, 0.1, 0.0)), Vector3.UP)
	world.player.hands.look_device = deck
	console.run("charge 0")
	check(deck.batteries().size() == 2 and deck.batteries().all(func(b: Battery) -> bool: return b.charge_wh == 0.0),
		"charge empties every actual cell in the targeted deck pool")
	check(not world.counts_deeds, "changing battery charge marks the run as dev")
