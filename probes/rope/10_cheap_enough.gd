extends LineProbe
## Rope & tethering probe 10: cheap enough. Thirty lines, fifteen floating
## devices each on two lines to stakes upwind, in a gusting storm, cost the
## rope system a small share of a 60 fps frame every tick: solving, bearing and
## drawing them, and pinning their ends each frame.
## Runs alone: it times real frames.

const DEVICES := 15
## A quarter of a 60 fps frame's 16.7 ms on average, and half of it in the
## worst hundredth of ticks.
const MEAN_MS := 4.2
const P99_MS := 8.3


func run() -> void:
	await load_lines()
	# Downwind is +x; each device's stakes stand upwind of it.
	blow(Vector2(wind.storm_speed(), 0.0), world.tuning.gust_storm_strength)
	for i in DEVICES:
		var at := spot((i % 5) * 9.0 - 14.0, (i / 5) * 10.0 - 10.0)
		var piece := floating(&"planter" if i % 2 == 0 else &"chassis", at)
		for side in [-2.0, 2.0]:
			var stake := driven_stake(at + Vector3(-6.0, 0.0, side))
			Line.between(world, piece.free_tie(stake.global_position), stake.free_tie(at), 0.3)
	await simulate(5.0)
	var costs := PackedFloat64Array()
	for i in 600:
		await get_tree().physics_frame
		var started := Time.get_ticks_usec()
		ropes._process(0.0)
		costs.append(ropes.tick_ms + (Time.get_ticks_usec() - started) / 1000.0)
	costs.sort()
	var mean := 0.0
	for c in costs:
		mean += c / costs.size()
	var loaded := ropes.ropes.filter(func(r: Rope) -> bool: return r.is_taut()).size()
	print("%d lines (%d pulling) in a %d m/s gusting storm: %.3f ms a tick on average, %.3f ms at the 99th percentile, %.3f at worst"
		% [ropes.ropes.size(), loaded, roundi(wind.storm_speed()), mean, costs[int(costs.size() * 0.99)], costs[-1]])
	check(ropes.ropes.size() == DEVICES * 2 and loaded == DEVICES * 2, "thirty lines, all of them pulling")
	check(mean < MEAN_MS, "they cost under %.1f ms a tick on average" % MEAN_MS)
	check(costs[int(costs.size() * 0.99)] < P99_MS, "and under %.1f ms in the worst hundredth" % P99_MS)
