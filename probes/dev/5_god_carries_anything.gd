extends MovementProbe
## Dev probe 5: god carries anything. Past twice what you carry easily, as
## god you walk at your full pace standing tall; and a 200 kg condenser on
## the sand, one a mortal can't drag, follows you as you back away.

const AHEAD := Vector2(1.0, 0.0)


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var suit := player.suit
	while suit.kg() <= world.tuning.carry_sunk_kg:
		suit.carried.append(Catalog.part(&"battery"))
	check(suit.burden() > 1.0, "mortal, %.1f kg is past what you carry easily" % suit.kg())
	player.vitals.god = true
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 10.0)
	await place(flat.x, flat.z, AHEAD)
	hold(["move_forward"])
	await simulate(2.0)
	var pace := player.own.length()
	hold([])
	print("as god with %.1f kg: %.2f m/s, sunk %.2f" % [suit.kg(), pace, player.sink])
	check(absf(pace - world.tuning.walk_speed) < 0.02 and player.sink < 0.02,
		"as god you walk at your full pace, standing tall (%.2f m/s)" % pace)

	await place(flat.x, flat.z, AHEAD)
	var heavy := Catalog.device(&"condenser")
	heavy.frame_mass = 200.0
	world.content.add_child(heavy)
	var at := player.global_position - player.global_basis.z * 1.6
	heavy.global_position = Vector3(at.x, world.height_under(at) + Catalog.DEVICES[&"condenser"].size.y * 0.5 + 0.02, at.z)
	await simulate(1.0)
	var to := heavy.global_position - player.camera.global_position
	player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())
	check(player.hands.grab() and player.hands.grasp.body == heavy, "you take hold of the condenser")
	var from := heavy.global_position
	hold(["move_back"])
	await simulate(3.0)
	hold([])
	var dragged := (heavy.global_position - from).length()
	print("a 200 kg condenser dragged %.2f m as god" % dragged)
	check(dragged > 2.0 and player.hands.grasp.body == heavy, "it follows as you back away (%.2f m)" % dragged)
	set_rate(60)
