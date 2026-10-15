extends LineProbe
## Rope & tethering probe 9: the long tow. You walk 5 km over the dunes at
## walking pace, towing a floating planter on a line in your hand through a
## gusting crosswind, crossing origin shifts and fresh ground all the way. It
## arrives with you, floating and on its line, and the line's pull never
## spikes past twice the hardest the wind and your pace could load it.

const DISTANCE := 5000.0
const CROSSWIND := 15.0
const SPIKE := 2.0


func run() -> void:
	# Ground to see is no part of this: only the ground under the tow.
	Tuning.current().view_radius = Tuning.current().near_radius + 1
	await load_lines()
	blow(Vector2(0.0, CROSSWIND), world.tuning.gust_storm_strength)
	var planter := floating(&"planter", spot(0.0, 4.0))
	await simulate(1.0)
	var line := await lead(planter)
	check(hands.held == line.ends[1], "you hold the planter's line")
	var catch := world.weather.catch_of(planter)
	var hardest := catch * (pow(CROSSWIND * (1.0 + world.tuning.gust_storm_strength), 2.0)
		+ pow(world.tuning.walk_speed, 2.0))
	speed_up(60)
	# An hour of ticks: the weather does only what the tow feels, its drag on
	# bodies, not the sky and walls nobody is here to see.
	world.weather.set_physics_process(false)
	var seen := {"pull": 0.0, "low": INF, "high": -INF, "far": 0.0, "walked": 0.0}
	var heading := Vector3(1.0, 0.0, 0.0)
	var started := Time.get_ticks_msec()
	while seen.walked < DISTANCE:
		var from := world.player.global_position
		await walk_to(from + heading * 50.0, func() -> void:
			world.weather._blow_loose_bodies()
			if line.rope != null and ropes.ropes.has(line.rope):
				seen.pull = maxf(seen.pull, line.rope.tension)
			var up := clearance(planter)
			seen.low = minf(seen.low, up)
			seen.high = maxf(seen.high, up)
			seen.far = maxf(seen.far, flat(planter.global_position - world.player.global_position).length()))
		seen.walked += 50.0
	speed_up(1)
	world.weather.set_physics_process(true)
	var reach := line.rope.length * (1.0 + world.tuning.rope_max_stretch) + 2.0 if line.rope != null else 0.0
	print("towed %.0f m in %.0f s: pull at most %.0f N (the wind and your pace load it %.0f N at hardest);"
		% [seen.walked, (Time.get_ticks_msec() - started) / 1000.0, seen.pull, hardest]
		+ " planter %.2f-%.2f m over the sand, at most %.1f m behind; %d origin shifts"
		% [seen.low, seen.high, seen.far, absi(world.origin_chunk.x) / world.tuning.origin_shift_chunks])
	check(line.rope != null and ropes.ropes.has(line.rope) and hands.held == line.ends[1], "the line held, in your hand")
	check(seen.far <= reach, "the planter followed on its line all the way (%.1f m of %.1f)" % [seen.far, reach])
	check(seen.low > 0.5 and planter.stats().hovering, "floating all the way, never down on the sand")
	check(seen.pull < SPIKE * hardest, "the pull never spiked (%.0f N)" % seen.pull)
