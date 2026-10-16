extends LineProbe
## Bubble shield probe 4: the moving bubble. Deep in a storm that never ends,
## in a gusting gale, you pick up a running shield and walk 2 km at
## walking pace, a floating crate on a short line at your waist. The bubble
## goes with the generator in your hands: the crate never leaves it, never
## feels the wind or the storm, never wears, and the shield runs all the way.
## Then, still in the storm, you seat the shield on the crate's top mount and
## tow the crate on: the bubble goes with the crate, the shield running on the
## crate's power, and take lifts it off again into your hands.

const DISTANCE := 2000.0
const TOWED := 200.0
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
	await _seated(generator, crate, line)


## The running shield seated on the crate's top mount and the crate towed on.
func _seated(generator: ShieldGenerator, crate: Device, line: Line) -> void:
	var top: Socket = null
	for socket in crate.sockets():
		if socket.kind == &"top" and socket.is_open():
			top = socket
	var crate_kg := crate.mass
	for i in 30:
		# It floats on your line, so you look again as it moves.
		var seat_at := seat(top).origin
		look(seat_at + Vector3(0.0, 1.0, -0.7), seat_at + Vector3(0.0, 0.2, 0.0))
		await simulate(1.0 / 60.0)
	check(hands.socket == top and hands.grab(), "the held shield leans toward the crate's top mount, and take seats it")
	await simulate(0.5)
	check(crate.mounted().has(generator) and generator.host() == crate and hands.held == null
		and is_equal_approx(crate.mass, crate_kg + generator.mass), "the shield is seated on the crate, its weight with it")
	var cell := crate.battery()
	var own := generator.battery().charge_wh
	var from := cell.charge_wh
	speed_up(60)
	world.weather.set_physics_process(false)
	var seen := {"off": 0.0, "felt": 0.0, "dropped": 0, "walked": 0.0}
	var heading := Vector3(0.0, 0.0, 1.0)
	while seen.walked < TOWED:
		await walk_to(world.player.global_position + heading * 50.0, func() -> void:
			world.weather._blow_loose_bodies()
			seen.off = maxf(seen.off, generator.shelter.global_position.distance_to(seat(top).origin))
			seen.felt = maxf(seen.felt, world.weather.felt_wind(crate.global_position).length()
				+ world.weather.felt_storm(crate.global_position))
			seen.dropped += int(not generator.running()))
		seen.walked += 50.0
	speed_up(1)
	world.weather.set_physics_process(true)
	print("towed the crate %.0f m with the shield seated: the bubble at most %.2f m from the crate, felt %.3f;"
		% [seen.walked, seen.off, seen.felt] + " the crate's battery %.1f to %.1f Wh, the shield's own %.1f to %.1f Wh"
		% [from, cell.charge_wh, own, generator.battery().charge_wh])
	check(seen.dropped == 0 and seen.felt == 0.0, "seated, the shield ran all the way and the crate felt nothing")
	check(seen.off < 0.3, "the bubble went with the crate, centred over its mount (%.2f m off at worst)" % seen.off)
	check(from - cell.charge_wh > 1.0, "the shield ran on the crate's battery too (%.1f Wh drawn)" % (from - cell.charge_wh))
	await simulate(0.5)
	var on := generator.global_transform * Vector3(0.0, 0.1, 0.0)
	look(on + Vector3(0.0, 0.9, -1.0), on)
	await simulate(1.0 / 60.0)
	check(hands.grab(), "take lifts the seated shield off")
	await simulate(0.6)
	check(hands.held == generator and crate.mounted().is_empty() and is_equal_approx(crate.mass, crate_kg)
		and generator.running(), "it's in your hands again, still running, and the crate is as it was")
