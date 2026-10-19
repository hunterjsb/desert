extends LineProbe
## Bubble shield probe 4: the moving bubble. Deep in a storm that never
## ends, in a gusting gale, you stick a shield by hand on a floating chassis
## and tow it 2 km at walking pace on a short line at your waist. The bubble
## goes with the deck, centred over the shield: it never feels the wind or
## the storm, never wears, and the shield runs all the way on the deck's
## batteries. Take lifts it off into your hands, where with no battery of its
## own it goes dark.

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
	# Still air while it's set up: the gale comes once the bubble's up.
	blow(Vector2.ZERO)
	var generator := device(&"shield", spot(-1.0, 1.2), 0.22) as ShieldGenerator
	check(await take(generator), "take picks the shield up")
	var floater := floating(&"chassis", spot(0.0, 2.5)) as Chassis
	fit_part(floater, &"big_battery")
	await simulate(1.0)
	for i in 20:
		# It floats in the gale, so you look again as it moves.
		var top := floater.global_transform * floater.face_frame(floater, Chassis.TOP) * Vector3(0.25, -0.25, 0.0)
		look(top + Vector3(0.0, 1.0, 1.0), top)
		await simulate(1.0 / 60.0)
	check(not hands.sticking.is_empty() and hands.grab() and generator.host() == floater, "take sticks it on the deck")
	check(generator.switch(true), "use switches it on")
	await simulate(1.0)
	blow(Vector2(0.0, GALE), tuning.gust_storm_strength)
	# Out in the storm until the bubble's up, it's worn a little already.
	var sound := [floater.durability, generator.durability]
	var line := await lead(floater)
	check(hands.interact() and world.player.waist.holds(line.ends[1]), "use puts the deck's line on your waist")
	var from := world.power.pool_wh(floater)
	speed_up(60)
	# The weather does only what's felt here: its drag on loose bodies.
	world.weather.set_physics_process(false)
	var seen := {"off": 0.0, "felt": 0.0, "dropped": 0, "walked": 0.0}
	_watched = [seen, generator, floater]
	var heading := Vector3(1.0, 0.0, 0.0)
	var started := Time.get_ticks_msec()
	while seen.walked < DISTANCE:
		await walk_to(world.player.global_position + heading * 50.0, _watch)
		seen.walked += 50.0
	speed_up(1)
	world.weather.set_physics_process(true)
	print("towed %.0f m in %.0f s: the bubble at most %.2f m off the shield, felt %.3f, wear %.4f; battery %.1f to %.1f Wh"
		% [seen.walked, (Time.get_ticks_msec() - started) / 1000.0, seen.off, seen.felt, 1.0 - floater.durability,
			from, world.power.pool_wh(floater)])
	check(world.weather.field_storm(floater.global_position) == 1.0
		and world.weather.field_wind(floater.global_position).length() > GALE * 0.5, "outside is a storm and a gale")
	check(seen.dropped == 0 and seen.felt == 0.0, "the shield ran all the way and the deck felt nothing")
	check(seen.off < 0.3, "the bubble went with the deck, centred on the shield (%.2f m off at worst)" % seen.off)
	check(floater.durability == sound[0] and generator.durability == sound[1], "nothing wore under the bubble")
	check(from - world.power.pool_wh(floater) > 1.0, "the shield ran on the deck's batteries (%.1f Wh drawn)"
		% (from - world.power.pool_wh(floater)))
	check(floater.stats().hovering and world.player.waist.holds(line.ends[1]), "the deck still floats on your line")
	await simulate(0.5)
	await _beside(floater, generator.global_position)
	var on := generator.global_transform * Vector3(0.0, 0.1, 0.0)
	look(_standing(), on)
	await simulate(1.0 / 60.0)
	var loaded := floater.mass
	check(hands.grab(), "take lifts the shield off")
	await simulate(1.0)
	check(hands.held == generator and floater.mounted().is_empty() and is_equal_approx(floater.mass, loaded - generator.mass),
		"it's in your hands again, and the deck is as it was")
	check(not generator.running(), "with no battery of its own, in your hands it goes dark")


## What the tow watches each tick: how far the bubble strays off the shield,
## what the deck feels, and whether the shield stays up.
var _watched := []


func _watch() -> void:
	var seen: Dictionary = _watched[0]
	var generator: ShieldGenerator = _watched[1]
	var floater: Chassis = _watched[2]
	world.weather._blow_loose_bodies()
	seen.off = maxf(seen.off, generator.shelter.global_position.distance_to(generator.global_position))
	seen.felt = maxf(seen.felt, world.weather.felt_wind(floater.global_position).length()
		+ world.weather.felt_storm(floater.global_position))
	seen.dropped += int(not generator.running())


## Walks you up beside a floating device, a step out past a point on it, so
## the line at your waist goes slack rather than jerking it.
func _beside(device: Device, point: Vector3) -> void:
	await walk_to(point + flat(point - device.global_position).normalized() * 0.9)


## Your eyes where you stand, standing.
func _standing() -> Vector3:
	var feet := world.player.global_position
	return Vector3(feet.x, world.height_under(feet), feet.z) + world.player.camera.position
