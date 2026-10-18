extends MovementProbe
## Movement probe 22: catching an edge. A hockey stop loads the dug edge
## with dig times your way across it. Flat out, the same stop holds with the
## catch set just past its load and throws you off with it set just short;
## as tuned, from a cruise it holds and flat out it catches. Thrown off,
## you stumble on across the sand, a little knocked and winded, never
## killed, and the board tumbles behind you as a body.


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 200.0, 40.0)
	var tuning := world.tuning
	var catch := tuning.board_dig_catch
	tuning.board_dig_catch = INF
	var loaded := await _stop(flat, 6.0)
	print("a hockey stop from %.1f m/s loads the edge to %.2f m/s" % [loaded.from, loaded.load])
	tuning.board_dig_catch = loaded.load * 1.02
	var held := await _stop(flat, 6.0)
	tuning.board_dig_catch = loaded.load * 0.98
	var thrown := await _stop(flat, 6.0)
	check(not held.caught and thrown.caught, "it catches past the threshold and not below it (%s, %s)"
		% [held.caught, thrown.caught])

	tuning.board_dig_catch = catch
	var cruise := await _stop(flat, 1.5)
	var flat_out := await _stop(flat, 6.0)
	print("as tuned (%.1f): from %.1f m/s the edge loads to %.2f and %s; from %.1f m/s, %s"
		% [catch, cruise.from, cruise.load, "catches" if cruise.caught else "holds", flat_out.from,
			"catches" if flat_out.caught else "holds"])
	check(not cruise.caught and flat_out.caught, "from a cruise it holds, flat out it catches")
	print("thrown off at %.1f m/s: %.1f health and %.0f stamina lost, on foot at %.1f m/s, the board %.1f m away at %.1f m/s"
		% [flat_out.from, flat_out.hurt, flat_out.winded, flat_out.on_foot, flat_out.apart, flat_out.board_speed])
	check(flat_out.hurt > 0.0 and flat_out.hurt < tuning.board_wipeout_hurt + 0.5 and flat_out.winded > 0.0,
		"knocked and winded (%.1f health, %.0f stamina)" % [flat_out.hurt, flat_out.winded])
	check(flat_out.on_foot > 1.0 and flat_out.on_foot > flat_out.board_speed and flat_out.body,
		"you stumble on and the board tumbles behind you")

	await ride_here()
	player.vitals.health = 0.5
	player.wipe_out()
	check(player.board == null and player.vitals.health == 0.5 and not player.vitals.dead,
		"a knock never takes your last health (%.2f)" % player.vitals.health)
	player.vitals.health = player.vitals.FULL
	set_rate(60)


## Up to speed along +x for `push` s on a fresh board, then move back alone
## for 3 s: {from, load, caught}, and once you're thrown, {hurt, winded,
## on_foot, apart, board_speed, body} a moment later.
func _stop(flat: Dictionary, push: float) -> Dictionary:
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(flat.x - 60.0, flat.z, Vector2(1.0, 0.0))
	var board := await ride_here()
	hold(["move_forward"])
	await ride_for(push)
	var seen := {"from": flat_speed(), "load": 0.0, "caught": false}
	var health := player.vitals.health
	var stamina := player.stamina
	var ride := player.ride
	hold(["move_back"])
	await ride_for(3.0, func() -> void: seen.load = maxf(seen.load, ride.edge))
	seen.caught = player.ride == null
	if seen.caught:
		seen.hurt = health - player.vitals.health
		seen.winded = stamina - player.stamina
		hold([])
		await simulate(0.3)
		seen.on_foot = flat_speed()
		seen.board_speed = board.linear_velocity.length()
		seen.apart = board.global_position.distance_to(player.global_position)
		seen.body = not board.freeze and board.rider == null
	hold([])
	return seen
