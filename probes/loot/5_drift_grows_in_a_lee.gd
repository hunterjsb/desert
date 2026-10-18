extends HandsProbe
## Loot probe 5: drift is caught at a camp in a storm and grows in a lee. A
## line strung between two stakes across the run's wind, at the foot of a
## tall slip face and out on open sand: over three days its storms would
## leave several times as much on the line in the lee as on the open one,
## and the clear none. In the world, through a storm, what the lee's line
## catches lies on the sand just downwind of it, held there, a surface find,
## its pile never more than a line holds; taken up, it's yours.

const SEED := 1234
## A catch line's span, m, and how far apart in time its rate is read, s.
const SPAN := 8.0
const EVERY := 300.0
## The lee's line catches at least this many times the open one's.
const LEE := 2.5
## For the world's storm, drift this many times as thick, so a few minutes catch a pile.
const THICK := 20.0


func run() -> void:
	var tuning := Tuning.current()
	await load_world(SEED, false, true)
	hands = world.player.hands
	world.player.set_physics_process(false)
	world.player.collision_layer = 0
	world.player.collision_mask = 0
	var mean := WeatherField.mean_heading(SEED)
	var across := Vector2.from_angle(mean).orthogonal() * SPAN * 0.5
	var lee := Vector2(NAN, NAN)
	for foot in Scenarios.feet(world, mean):
		if world.weather.lee.share(foot.x, foot.y, mean) >= Scenarios.LEE_SHARE:
			lee = foot
			break
	var open := open_sand(30.0)
	check(lee.is_finite() and open.is_finite(), "a slip face's foot and open sand near the start")
	if not lee.is_finite() or not open.is_finite():
		return
	var caught := [0.0, 0.0]
	var clear := 0.0
	var t := 0.0
	while t < 3.0 * 24.0 * 3600.0:
		for k in 2:
			var at: Vector2 = [lee, open][k]
			var hourly := Drift.rate(world, at - across, at + across, t)
			caught[k] += hourly * EVERY / 3600.0
			if world.weather.field.raw_storm_at(at.x, at.y, t) <= 0.0 \
					and world.weather.field.wind_at(at.x, at.y, t).length() <= tuning.exposure_calm_wind:
				clear += hourly
		t += EVERY
	print("over three days a %.0f m line would catch %.1f things in the lee, %.1f on open sand" % [SPAN, caught[0], caught[1]])
	check(caught[1] > 0.5 and caught[0] >= caught[1] * LEE, "a lee catches %.1f times what open sand does (%.1f)"
		% [LEE, caught[0] / maxf(caught[1], 0.01)])
	check(clear == 0.0, "the clear carries none")
	await _through_a_storm(lee, across)


## A line in the lee through a storm's hard hours, drift thick enough to pile.
func _through_a_storm(at: Vector2, across: Vector2) -> void:
	var tuning := Tuning.current()
	tuning.drift_per_m_hour *= THICK
	world.time_warp = 0.0
	teleport(at.x, at.y)
	await settle(true)
	var stakes: Array[Stake] = []
	for end in [at - across, at + across]:
		var stake := Catalog.stake()
		world.content.add_child(stake)
		var place := Vector3(world.engine_x(end.x), 0.0, world.engine_z(end.y))
		stake.drive(place, world.height_under(place))
		stakes.append(stake)
	var line := Line.between(world, stakes[0].free_tie(stakes[1].global_position),
		stakes[1].free_tie(stakes[0].global_position), 0.3)
	var storm := _storm_at(at)
	check(storm >= 0.0, "a storm comes over the foot within three days")
	if storm < 0.0:
		return
	world.time = storm
	await physics_frames(2)
	var before := world.salvage.caught
	for k in 30:
		world.time += tuning.drift_tick_s
		await physics_frames(1)
	var piled := world.content.get_children().filter(func(n: Node) -> bool: return n.has_meta(&"drift"))
	var wind := world.weather.field.wind_at(at.x, at.y, world.time).normalized()
	var astray := 0
	for body: RigidBody3D in piled:
		var p := Vector2(world.world_x(body.global_position.x), world.world_z(body.global_position.z))
		var off := Geometry2D.get_closest_point_to_segment(p, at - across, at + across)
		if not body.freeze or not body.has_meta(&"buried") or p.distance_to(off) > Drift.PILE \
				or (p - off).dot(wind) < 0.0 or body.get_meta(&"layer") != Finds.SURFACE:
			astray += 1
	print("caught in the world: %d, lying in the line's pile %d" % [world.salvage.caught - before, piled.size()])
	check(not piled.is_empty() and astray == 0, "what it catches lies just downwind of it, held there (%d astray)" % astray)
	check(piled.size() <= tuning.drift_most, "never more than a line holds (%d)" % piled.size())
	var find: RigidBody3D = piled[0] if not piled.is_empty() else null
	if find != null:
		var middle_at := find.global_transform * Finds.bounds(find).get_center()
		look(middle_at + Vector3(0.0, 1.2, 0.8), middle_at)
		await simulate(1.0 / 60.0)
		check(hands.grab() and not find.has_meta(&"buried") and not find.has_meta(&"drift"), "taken up, it's yours")
	tuning.drift_per_m_hour /= THICK
	line.queue_free()


## The first moment in three days the storm blows its hardest over a place,
## on a tick; -1 if never.
func _storm_at(at: Vector2) -> float:
	var tuning := Tuning.current()
	var t := 0.0
	while t < 3.0 * 24.0 * 3600.0:
		if Exposure.reading(world.weather.field, at.x, at.y, t, tuning) >= 0.9:
			return floorf(t / tuning.drift_tick_s) * tuning.drift_tick_s
		t += 60.0
	return -1.0
