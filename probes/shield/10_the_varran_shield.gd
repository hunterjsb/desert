extends SailProbe
## Bubble shield probe 10: the Varran settler's personal shield. His kit's
## shield rides in your suit with a battery of its own; used there, its
## bubble stands round you on that battery alone, in no other pool. Raised
## round you while his rig tows you across a steady 10 m/s, it blocks none
## of the sail's wind, which stands outside it, and the rig sails on; you
## feel what the bubble lets through, and its battery pays its draw.

const WIND := 10.0


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	world.kit = Kit.named(&"varran")
	player.suit.restock()
	await physics_frames(2)
	var shield: ShieldGenerator = player.suit.carried.filter(func(b: Node) -> bool: return b is ShieldGenerator)[0]
	var cell := shield.batteries()[0]
	check(shield.get_parent() == player and cell.charge_wh == cell.capacity(), "it rides in your suit, its battery full")
	check(shield.interact(player) and shield.on, "used in your suit, it switches on")
	await physics_frames(60)
	check(shield.running() and world.power.pool_of(shield) == [shield], "it runs on its own battery, in no other pool")
	check(shield.shelter.radius > 2.4 and shield.global_position.distance_to(player.global_position) < 1.5,
		"its bubble stands round you (%.1f m)" % shield.shelter.radius)
	speed_up(4)
	var way := heading(1)
	await varran(way, 1)
	check(shield.running(), "riding, it's up round you still")
	blow(downwind * WIND)
	tending = deg_to_rad(15.0)
	var held := cell.charge_wh
	var t0 := world.time
	var seen := {"t": 0, "sail": 0.0, "you": 0.0, "across": 0.0}
	await simulate(25.0, func() -> void:
		player.rotation.y = atan2(-way.x, -way.y)
		_steer()
		seen.t += 1
		if seen.t == 120:
			Input.action_press("move_forward", 1.0)
			Input.action_press("move_back", 0.25)
		if seen.t > 900:
			seen.sail += mast._wind.length() / 600.0
			seen.you += world.weather.felt_wind(player.global_position).length() / 600.0
			seen.across += Vector2(player.velocity.x, player.velocity.z).dot(way) / 600.0)
	Input.action_release("move_forward")
	Input.action_release("move_back")
	speed_up(1)
	var drawn := (held - cell.charge_wh) / ((world.time - t0) / 3600.0)
	var stats := shield.frame_stats
	print("riding at %.2f m/s, the sail feels %.2f m/s, you %.2f; the shield drew %.2f W: a battery lasts %.0f h in the clear, %.0f min in a full storm" % [
		seen.across, seen.sail, seen.you, drawn, cell.capacity() / stats.clear_w, cell.capacity() / stats.storm_w * 60.0])
	check(seen.sail > WIND * 0.97 and seen.across > 3.0, "the sail feels the whole wind and the rig sails on (%.2f m/s)" % seen.across)
	check(seen.you < WIND * 0.2, "you feel what the bubble lets through (%.2f m/s)" % seen.you)
	check(absf(drawn / stats.clear_w - 1.0) < 0.05, "its battery pays its own draw (%.2f W)" % drawn)
