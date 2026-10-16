extends MovementProbe
## Movement probe 1: the long ride. 20 km flat out on a board over the run's
## dunes: half across the ridges, with the wind and against it, up and down
## their slip faces, and half wandering, over every chunk seam on the way. The
## board never dips below the sand. It never launches but where a crest falls
## away under it, and then not far. It never judders: the facets of the
## ground's lattice never reach you, and it never slams. It rides far faster
## than a game runs, so where the ground ahead isn't solid yet it waits for it,
## which changes when it gets there, never where it goes; probe 7 rides at a
## game's pace and holds streaming to keeping up.
## Time limit: 600 s (about 70 s alone; a busy machine stretches it past 300)

const DISTANCE := 20000.0
const LEG := 2500.0
const WANDER := 500.0
## Over its ride height by more than this, m, it has left the sand.
const LAUNCH := 0.5
## Off a crest: in the half second before, the sand along your way stopped
## rising and fell away by this much, m/s.
const FELL_AWAY := 2.0
const HIGHEST := 3.0
## The hardest the ride may move you up or down, m/s²: about 6 g, the worst
## of it climbing flat out straight into a slip face's foot, as hard as the
## ground gets; a slam onto the sand would be several times it. And a judder:
## up, down and up again tick by tick, each harder than this, m/s².
const HARDEST := 60.0
const JUDDER := 8.0


func run() -> void:
	var tuning := Tuning.current()
	# Ground to see is no part of this, near or far: only the ground under the
	# ride. Nor are storms, which would wear the board out over a ride this long.
	tuning.view_radius = tuning.near_radius
	tuning.far_radius = (tuning.view_radius + 1) * tuning.chunk_size
	tuning.storm_threshold = 2.0
	await load_moving()
	set_rate(60, 16)
	# The weather does only what the ride feels: nothing, in still air.
	world.weather.set_physics_process(false)
	var board := await ride_here(&"big_battery")
	var ride := player.ride
	var down := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	var start_wh := board.battery().charge_wh
	var seen := {"ridden": 0.0, "lowest": INF, "highest": 0.0, "launches": 0, "astray": 0, "hardest": 0.0,
		"judders": 0, "seams": 0, "ys": [], "rises": [], "ticks": 0, "fastest": 0.0}
	var last := {"at": where(), "chunk": _chunk(), "sand": _sand(where()), "airborne": false}
	var heading := down
	var leg_left := LEG
	var rng := RandomNumberGenerator.new()
	rng.seed = 10
	face(heading)
	hold(["move_forward"])
	while seen.ridden < DISTANCE and player.board == board:
		await ride_for(1.0, func() -> void: _watch(seen, last), false)
		leg_left -= seen.ridden - seen.get("counted", 0.0)
		seen.counted = seen.ridden
		if leg_left <= 0.0:
			if seen.ridden < DISTANCE * 0.5:
				heading = -heading
				leg_left = LEG
			else:
				heading = Vector2.from_angle(rng.randf() * TAU)
				leg_left = WANDER
			face(heading)
	hold([])
	var used := start_wh - board.battery().charge_wh
	print("%.1f km in %.0f s, %.1f m/s on average and %.1f at most, over %d chunk seams; %.0f Wh"
		% [seen.ridden / 1000.0, seen.ticks / 60.0, seen.ridden / (seen.ticks / 60.0), seen.fastest, seen.seams, used])
	print("underside at least %.3f m over the sand; %d launches off crests, the highest %.2f m over its ride height, %d elsewhere"
		% [seen.lowest, seen.launches, seen.highest, seen.astray])
	print("hardest %.1f m/s² (%.1f g), %d judders, bottomed %d times"
		% [seen.hardest, seen.hardest / 9.8, seen.judders, ride.bottomed])
	check(seen.ridden >= DISTANCE and seen.seams > 250, "20 km over the chunk seams (%d crossed)" % seen.seams)
	check(seen.lowest >= 0.0, "the board never dipped below the sand (%.3f m at least)" % seen.lowest)
	check(seen.astray == 0, "it never launched but off a crest (%d elsewhere)" % seen.astray)
	check(seen.highest < HIGHEST, "and never far off one (%.2f m over its ride height)" % seen.highest)
	check(seen.hardest < HARDEST, "it never slammed: nothing harder than %d m/s² (%.1f)" % [HARDEST, seen.hardest])
	check(seen.judders == 0, "it never juddered (%d)" % seen.judders)
	set_rate(60)


## One tick of the ride: the board's underside over the sand at each corner,
## how high it floats and whether the sand fell away under it, and how hard
## you were moved up and down.
func _watch(seen: Dictionary, last: Dictionary) -> void:
	var ride := player.ride
	var at := where()
	seen.ticks += 1
	seen.ridden += Vector2(at.x - last.at.x, at.z - last.at.z).length()
	seen.fastest = maxf(seen.fastest, flat_speed())
	last.at = at
	var chunk := _chunk()
	if chunk != last.chunk:
		seen.seams += 1
		last.chunk = chunk
	var pose := ride.board_pose(false)
	var size: Vector3 = Catalog.DEVICES[&"board"].size
	for corner: Vector3 in [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(-1, -1, 1), Vector3(1, -1, 1)]:
		var c := pose * (corner * size * 0.5)
		seen.lowest = minf(seen.lowest, c.y - world.height_at(world.world_x(c.x), world.world_z(c.z)))
	# The sand's own rise along your way, tick by tick, over the last half second.
	var sand := _sand(at)
	seen.rises.append((sand - last.sand) * 60.0)
	last.sand = sand
	if seen.rises.size() > 30:
		seen.rises.pop_front()
	var airborne: bool = ride.gap > LAUNCH
	if airborne and not last.airborne:
		var peak: float = seen.rises.max()
		if peak - seen.rises[-1] >= FELL_AWAY:
			seen.launches += 1
		else:
			seen.astray += 1
			printerr("launched with no crest under it at %.0f,%.0f" % [at.x, at.z])
	last.airborne = airborne
	seen.highest = maxf(seen.highest, ride.gap)
	seen.ys.append(at.y)
	if seen.ys.size() > 5:
		seen.ys.pop_front()
	if seen.ys.size() == 5:
		var a: Array[float] = []
		for k in 3:
			a.append((seen.ys[k + 2] - 2.0 * seen.ys[k + 1] + seen.ys[k]) * 3600.0)
		seen.hardest = maxf(seen.hardest, absf(a[2]))
		if a.all(func(each: float) -> bool: return absf(each) > JUDDER) and signf(a[0]) != signf(a[1]) \
				and signf(a[1]) != signf(a[2]):
			seen.judders += 1


func _chunk() -> Vector2i:
	return world.terrain.chunk_at(world.player_world_x(), world.player_world_z())


func _sand(at: Vector3) -> float:
	return world.height_at(at.x, at.z)
