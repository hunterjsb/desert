extends MovementProbe
## Actual movement boards a freely supported craft at either rendering rate.
## Runs alone

var deck: Chassis
var samples: Array[Dictionary] = []
var render_rate := 60

func run() -> void:
	await load_moving()
	blow(Vector2.ZERO)
	var level := Scenarios.open_sand(world)
	await place(level.x, level.y, Vector2.LEFT)
	var previous_cap := Engine.max_fps
	for rate in [30, 60]:
		render_rate = rate
		Engine.max_fps = rate
		# Native craft physics stays at the game's normal fixed tick.
		set_rate(60)
		await physics_frames(2)
		# Construction falls clear of the active player's capsule, not through it.
		var beside := Vector3(world.engine_x(level.x) + 3.0, 0.0, world.engine_z(level.y))
		beside.y = world.height_under(beside) + 0.03
		world.teleport(player, Transform3D(player.global_basis, beside))
		player.velocity = Vector3.ZERO
		player.own = Vector2.ZERO
		var craft := Rig.build(world.content, [
			[&"piece", Vector2i(1, 0)],
			[&"stick", Vector2i.ZERO, Chassis.BOTTOM, Vector2.ZERO, 0.0, &"hover_tray"],
			[&"stick", Vector2i(1, 0), Chassis.BOTTOM, Vector2.ZERO, 0.0, &"hover_tray"],
			[&"stick", Vector2i.ZERO, Chassis.TOP, Vector2.ZERO, 0.0, &"battery"]])
		deck = craft.deck
		var at := Vector3(world.engine_x(level.x), 0.0, world.engine_z(level.y))
		at.y = world.height_under(at) + 1.5
		deck.global_position = at
		await simulate(4.0)
		var approach := deck.global_transform * Vector3(3.0, 0.0, 0.0)
		approach.y = world.height_under(approach) + 0.03
		var facing := Vector3(-deck.global_basis.x.x, 0, -deck.global_basis.x.z).normalized()
		world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-facing.x, -facing.z)), approach))
		player.velocity = Vector3.ZERO
		player.own = Vector2.ZERO
		await simulate(0.25)
		hold(["move_forward", "sprint"])
		await simulate(0.15)
		hold(["move_forward", "sprint", "jump"])
		var seen := {"vault":false,"height":0.0,"progress":0.0,"peak_step":0.0,"spin":0.0}
		await simulate(0.9, func() -> void:
			if player.vault.active:
				seen.vault = true
				seen.height = maxf(seen.height, player.vault.height)
				seen.progress = maxf(seen.progress, player.vault.progress)
				seen.peak_step = maxf(seen.peak_step, player.vault.last_step.length())
			seen.spin = maxf(seen.spin, deck.angular_velocity.length()))
		hold([])
		var feet := deck.to_local(player.global_position)
		var result := {"rate":rate,"seen":seen,"feet":feet,"floor":player.is_on_floor(),"hovering":deck.hovering(),
			"deck_height":deck.global_position.y-world.height_under(deck.global_position),"mass":deck.mass}
		print("POWERED_VAULT ", JSON.stringify(result))
		samples.append(result)
		check(seen.vault and deck.hovering() and player.is_on_floor() and absf(feet.y - Chassis.THICK * 0.5) < 0.08,
			"real sprint/jump boards the powered chassis within the original observation time")
		await captured(rate)
		world.teleport(player, Transform3D(player.global_basis, approach))
		player.velocity = Vector3.ZERO
		player.own = Vector2.ZERO
		deck.queue_free()
		await physics_frames(2)
	set_rate(60)
	Engine.max_fps = previous_cap


func captured(_rate: int) -> void:
	pass
