extends SailProbe
## Sailing probe 4: overpowered, it heels and tips. On a beam reach in a
## steady 10 m/s wind the camp leans a little, its runners down. A 12.5 m/s
## gust with its sheet made fast lifts its windward runners and heels it
## hard, and it comes back down onto them as the gust passes. In an 18 m/s
## blast it goes over, smoothly, and comes to rest lying on its edge and its
## mast: nothing flung, nothing it carries through the sand.


func run() -> void:
	await load_sailing()
	rig(open, heading())
	blow(downwind * 10.0)
	hoist(60.0)
	course = heading()
	tending = deg_to_rad(15.0)
	speed_up(4)
	await sail_for(20.0)
	var lean := roll()
	print("at 10 m/s: leaning %.1f°, %d of 16 corners on the sand, going %.2f m/s" % [lean, deck.glider.touching, way().length()])
	check(lean < 4.0 and deck.glider.touching >= 8, "in a breeze it leans a little, its runners down (%.1f°)" % lean)
	# The sheet made fast as the gust comes: no one eases it.
	tending = 0.0
	# Lambdas copy what they're given: what they change lives in here.
	var seen := {"most": 0.0, "lifted": 16, "spin": 0.0, "fastest": 0.0, "jolt": 0.0, "was": deck.linear_velocity, "jolt_state": {}}
	var watch := func() -> void:
		seen.most = maxf(seen.most, roll())
		seen.lifted = mini(seen.lifted, deck.glider.touching)
		seen.spin = maxf(seen.spin, deck.angular_velocity.length())
		seen.fastest = maxf(seen.fastest, deck.linear_velocity.length())
		var jolt: float = (deck.linear_velocity - seen.was).length()
		if jolt > seen.jolt:
			seen.jolt = jolt
			seen.jolt_state = {"time": world.time, "position": deck.global_position,
				"before": seen.was, "after": deck.linear_velocity,
				"spin": deck.angular_velocity, "heel": heel(), "roll": roll(),
				"support": deck.glider.pressed_n, "touching": deck.glider.touching,
				"boom": mast.boom, "boom_spin": mast.boom_spin,
				"boom_velocity": mast._boom_body.linear_velocity,
				"sheet_spring": mast.sheet().spring_impulse if mast.sheet() != null else 0.0,
				"sheet_stop": mast.sheet().stop_impulse if mast.sheet() != null else 0.0,
				"frozen": deck.freeze, "collision": world.terrain.has_collision_at(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))}
		seen.was = deck.linear_velocity
	blow(downwind * 12.5)
	await sail_for(3.0, watch)
	blow(downwind * 10.0)
	await sail_for(6.0, watch)
	print("a 12.5 m/s gust: heeling at most %.1f°, as few as %d corners down, then %.1f° with %d down" % [seen.most, seen.lifted, roll(), deck.glider.touching])
	check(seen.most > 2.0 and seen.lifted < 8, "a gust heels it hard, its windward runners lifting (%.1f°)" % seen.most)
	check(roll() < 4.0 and deck.glider.touching >= 8, "and it comes back down onto them (%.1f°)" % roll())
	seen.most = 0.0
	seen.jolt = 0.0
	seen["sunk"] = -INF
	blow(downwind * 18.0)
	await sail_for(10.0, func() -> void:
		watch.call()
		seen.sunk = maxf(seen.sunk, sunk()))
	print("an 18 m/s blast: over, spinning at most %.2f rad/s, at most %.2f m/s, the most a tick changed it %.2f m/s, in the sand at most %.3f m; lying at %.0f°" % [
		seen.spin, seen.fastest, seen.jolt, seen.sunk, heel()])
	print("largest tipping jolt: ", seen.jolt_state)
	check(heel() > 60.0, "a blast puts it over")
	check(seen.spin < 6.0 and seen.fastest < 12.0 and seen.jolt < 1.0,
		"smoothly, nothing flung (%.2f rad/s, %.2f m/s, %.2f m/s in a tick)" % [seen.spin, seen.fastest, seen.jolt])
	check(seen.sunk < 0.2, "nothing it carries through the sand, a hand's depth at most going over (%.3f m in)" % seen.sunk)
	check(deck.angular_velocity.length() < 0.5, "and it comes to rest lying over (%.2f rad/s)" % deck.angular_velocity.length())
	speed_up(1)
