extends LineProbe
## Bubble shield probe 4: the moving bubble. Deep in a storm that never ends,
## in a gusting gale, you pick up a running shield and walk 2 km at
## walking pace, a floating crate on a short line at your waist. The bubble
## goes with the generator in your hands: the crate never leaves it, never
## feels the wind or the storm, never wears, and the shield runs all the way.

const DISTANCE := 2000.0
const GALE := 25.0


func run() -> void:
	var tuning := Tuning.current()
	# Ground to see is no part of this: only the ground under the walk.
	tuning.view_radius = tuning.near_radius + 1
	await load_lines()
	# A storm everywhere, under the wind the probe blows.
	tuning.storm_threshold = -2.0
	wind = RopeWind.new(world.run_seed, tuning)
	world.weather.field = wind
	blow(Vector2(0.0, GALE), tuning.gust_storm_strength)
	var generator := device(&"shield", spot(-1.0, 1.2), 0.22) as ShieldGenerator
	fit_part(generator, &"battery")
	generator.stand(true)
	var crate := floating(&"crate_frame", spot(0.0, 2.5))
	await simulate(1.0)
	var line := await lead(crate)
	check(hands.interact() and world.player.waist.holds(line.ends[1]), "use puts the crate's line on your waist")
	check(await take(generator), "take picks the running shield up")
	await simulate(0.5)
	check(hands.held == generator, "you carry the shield")
	speed_up(60)
	# The weather does only what's felt here: its drag on loose bodies.
	world.weather.set_physics_process(false)
	var seen := {"out": -INF, "felt": 0.0, "dropped": 0, "walked": 0.0}
	var heading := Vector3(1.0, 0.0, 0.0)
	var started := Time.get_ticks_msec()
	while seen.walked < DISTANCE:
		await walk_to(world.player.global_position + heading * 50.0, func() -> void:
			world.weather._blow_loose_bodies()
			var shell := generator.shelter
			seen.out = maxf(seen.out, crate.global_position.distance_to(shell.global_position) - shell.radius)
			seen.felt = maxf(seen.felt, world.weather.felt_wind(crate.global_position).length()
				+ world.weather.felt_storm(crate.global_position))
			seen.dropped += int(not generator.running() or hands.held != generator))
		seen.walked += 50.0
	speed_up(1)
	world.weather.set_physics_process(true)
	print("carried %.0f m in %.0f s: the crate at most %.2f m inside the shell, felt %.3f, wear %.4f; %.1f Wh left"
		% [seen.walked, (Time.get_ticks_msec() - started) / 1000.0, -seen.out, seen.felt, 1.0 - crate.durability,
			generator.battery().charge_wh])
	check(world.weather.field_storm(crate.global_position) == 1.0
		and world.weather.field_wind(crate.global_position).length() > GALE * 0.5, "outside is a storm and a gale")
	check(seen.dropped == 0, "the shield ran in your hands all the way")
	check(seen.out < 0.0, "the crate never left the bubble (%.2f m inside at worst)" % -seen.out)
	check(seen.felt == 0.0, "and never felt the wind or the storm (%.3f)" % seen.felt)
	check(crate.durability == 1.0 and generator.durability == 1.0, "nothing wore")
	check(crate.stats().hovering and world.player.waist.holds(line.ends[1]), "the crate still floats on your line")
