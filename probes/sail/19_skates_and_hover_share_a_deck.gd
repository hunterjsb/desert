extends SailProbe
## Sailing probe 19: a deck can carry skates and hover parts together.
## Clear mounts and joins work through the hands; airborne blades exert no
## sand grip, while a real hover fin still resists sideways motion.


func run() -> void:
	await load_sailing()
	blow(Vector2.ZERO)
	deck = piece(open)
	deck.freeze = true
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.25, 0.25), 0.0, Catalog.part(&"battery"))
	Stick.put(deck, deck, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	var blades := piece(open + Vector3(3.0, 0.0, 0.0))
	Stick.put(blades, blades, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"skates"))
	var joined := await join_by_hand(deck, blades, ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
	check(joined, "a piece with skates joins a deck with a tray through the hands")
	if not joined:
		return
	var aft := piece(open + Vector3(0.0, 0.0, 3.0))
	deck.join(aft, ring(deck, Vector2i.ZERO, Vector2i(0, 1)), 0)
	check(deck.has_tray() and deck.glider != null and Runners.keels(deck).is_empty(),
		"the hybrid has lift and runners, without mistaking blade penetration for a hover fin")
	deck.axis_lock_angular_x = true
	deck.axis_lock_angular_z = true
	deck.freeze = false
	deck.global_position += Vector3.UP
	await simulate(3.0, func() -> void: follow(deck.global_position))
	check(deck.hovering() and deck.glider.touching == 0 and deck.glider.pressed_n == 0.0,
		"powered lift raises the blades clear, with no runner load (%.2f m, %.2f N)" % [clearance(deck), deck.glider.pressed_n])
	deck.linear_velocity = Vector3(4.0, 0.0, 0.0)
	await simulate(0.5, func() -> void: follow(deck.global_position))
	var free_speed := absf(deck.linear_velocity.x)
	deck.freeze = true
	var fin := Catalog.part(&"keel")
	world.content.add_child(fin)
	fin.global_position = deck.global_position + Vector3.UP * 2.0
	var fitted := await stick_by_hand(fin, on_face(deck, aft, Chassis.TOP), Vector3(0.0, 1.5, 1.2))
	check(fitted and fin.socket != null and deck.own_piece(fin.socket) == aft,
		"a hover keel aimed at the remaining piece fits under a deck already carrying skates")
	if not fitted:
		return
	check(Runners.keels(deck).size() == 1, "only the real hover fin contributes airborne grip")
	deck.linear_velocity = Vector3.ZERO
	deck.freeze = false
	await simulate(2.0, func() -> void: follow(deck.global_position))
	deck.linear_velocity = Vector3(4.0, 0.0, 0.0)
	await simulate(0.5, func() -> void: follow(deck.global_position))
	var fin_speed := absf(deck.linear_velocity.x)
	print("Hybrid sideways: blades clear %.3f m/s, real fin %.3f m/s, runner support %.3f N" % [free_speed, fin_speed, deck.glider.pressed_n])
	check(free_speed > 3.9 and fin_speed < free_speed - 0.5 and deck.glider.pressed_n == 0.0,
		"clear blades don't plough in air, while a real fin holds the supported load")
