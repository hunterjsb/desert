extends DeckProbe
## Devices & mods probe 31: where it won't go, it says so. A battery held to
## a deck's top right where another stands is shown there tinted red, the
## readout says "blocked", and take keeps it in your hands with a knock;
## moved clear along the face it loses the tint and take sticks it. Held to a
## floating piece whose keel can't carry a big battery more, it's shown
## amber, "too heavy", and still sticks: the piece no longer floats.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	await simulate(0.5)
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.0, 0.0), 0.0, Catalog.part(&"battery"))
	var cell := Catalog.part(&"battery")
	await hold_at(cell, on_face(deck, deck, Chassis.TOP, Vector2(0.02, 0.01)), Vector3(0.0, 1.2, 1.0))
	check(hands.sticking.get("why", "") == "blocked" and hands.line() == "blocked", "where another stands it's blocked")
	check(_tint(cell) == Hands.BLOCKED, "and shown red")
	check(hands.grab() and hands.held == cell and hands._sound.stream == Sounds.REFUSE,
		"take keeps it in your hands, with a knock")
	await hold_at(cell, on_face(deck, deck, Chassis.TOP, Vector2(0.3, 0.3)), Vector3(0.0, 1.2, 1.0))
	check(hands.sticking.get("why", "?") == "" and _tint(cell).a == 0.0, "moved clear, it's not red")
	check(hands.grab() and cell.socket != null, "and take sticks it")

	var light := piece(spot(3.0, 4.0))
	Stick.put(light, light, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"keel"))
	for at: Vector2 in [Vector2(-0.3, 0.3), Vector2(0.3, 0.3), Vector2(-0.3, -0.3), Vector2(0.0, 0.0)]:
		Stick.put(light, light, Chassis.TOP, at, 0.0, Catalog.part(&"big_battery"))
	await simulate(2.0)
	check(light.hovering(), "a piece floats on its keel with four big batteries")
	var more := Catalog.part(&"big_battery")
	await hold_at(more, on_face(light, light, Chassis.TOP, Vector2(0.3, -0.3)), Vector3(0.0, 1.2, 1.0))
	check(hands.sticking.get("warn", "") == "too heavy" and hands.line() == "too heavy" and _tint(more) == Hands.WARNED,
		"a fifth is too heavy for it, and shown amber")
	check(hands.grab() and more.socket != null, "it sticks all the same")
	await simulate(1.0)
	check(not light.hovering(), "and the piece no longer floats")


## The tint on what you hold, or none.
func _tint(body: Node) -> Color:
	for mesh: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		var look := mesh.material_overlay as StandardMaterial3D
		if look != null:
			return look.albedo_color
	return Color(0.0, 0.0, 0.0, 0.0)
