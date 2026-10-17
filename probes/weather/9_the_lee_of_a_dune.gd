extends WeatherProbe
## Wind & storms probe 9: a dune breaks the wind. A steady gale blows along
## the dunes' own heading. At the foot of a tall slip face the wind is cut by
## the lee's full share. Up the same dune's windward slope, and out on open
## sand, nothing is cut. With the wind from the other side the foot is
## exposed, and so is the foot of the steepest windward slope round about:
## too gentle to throw the wind clear. A box resting at the foot stays put where the same box on
## open sand slides off downwind.

const GALE := 25.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.storm_threshold = 2.0
	tuning.prevailing_speed = GALE
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0
	await load_world(1234, false)
	world.time_warp = 0.0
	world.player.set_physics_process(false)
	var heading := WeatherField.mean_heading(world.run_seed)
	var down := Vector2.from_angle(heading)
	var feet := Scenarios.feet(world, heading)
	var open := open_sand()
	check(not feet.is_empty() and not is_nan(open.x), "a tall slip face and open sand near where the run began")
	if feet.is_empty() or is_nan(open.x):
		return
	var foot: Vector2 = feet[0]
	var windward: Vector2 = _windward(foot, down)[0]
	# Only its steepness would let a windward slope throw a lee back the other way.
	var steep: Array = feet.map(_windward.bind(down)).reduce(func(a: Array, b: Array) -> Array: return a if a[2] >= b[2] else b)
	var toe: Vector2 = steep[1]
	print("foot %s, windward %s, open %s, steepest windward slope %.1f° with its foot at %s" % [foot, windward, open, steep[2], toe])
	check(steep[2] > rad_to_deg(atan(1.0 / tuning.lee_heights.y)),
		"a windward slope steep enough that its foot is within a lee's reach of its crest (%.1f°)" % steep[2])
	check(_cut(foot) > tuning.lee_wind * 0.9 and _cut(foot) <= tuning.lee_wind,
		"at the foot of a tall slip face the wind is cut by about its lee's %d%% (%.3f)" % [roundi(tuning.lee_wind * 100.0), _cut(foot)])
	check(_cut(windward) == 0.0, "up its windward slope nothing is cut (%.3f)" % _cut(windward))
	check(_cut(open) == 0.0, "nor out on open sand (%.3f)" % _cut(open))

	tuning.prevailing_speed = -GALE
	world.weather.field = WeatherField.new(world.run_seed, tuning)
	check(_cut(foot) == 0.0 and _cut(toe) == 0.0, "with the wind from the other side the foot is exposed (%.3f), and so is the windward slope's (%.3f)"
		% [_cut(foot), _cut(toe)])
	tuning.prevailing_speed = GALE
	world.weather.field = WeatherField.new(world.run_seed, tuning)

	var sheltered := await _slide(foot, down)
	var exposed := await _slide(open, down)
	check(exposed > 1.0 and sheltered < exposed * 0.1, "a box resting at the foot stays put (%.2f m) where one on open sand slides (%.2f m)"
		% [sheltered, exposed])


## The share of the field's wind kept from a place on the sand.
func _cut(at: Vector2) -> float:
	var p := Vector3(world.engine_x(at.x), world.height_at(at.x, at.y), world.engine_z(at.y))
	return 1.0 - world.weather.felt_wind(p).length() / world.weather.field_wind(p).length()


## Up the windward slope of the dune whose slip face this is the foot of:
## [halfway up, its own foot where it levels out, how steeply it climbs
## between, degrees].
func _windward(foot: Vector2, down: Vector2) -> Array:
	var base := world.shape.height_at(foot.x, foot.y)
	var crest := base
	var crest_at := foot
	var halfway := Vector2(NAN, NAN)
	var last := base
	var d := 0.0
	while d < 400.0:
		d += 2.0
		var at := foot - down * d
		var h := world.shape.height_at(at.x, at.y)
		if h > crest:
			crest = h
			crest_at = at
		if crest - base > Scenarios.LEE_TALL and h < (crest + base) * 0.5:
			if is_nan(halfway.x):
				halfway = at
			if absf(last - h) < 0.1:
				return [halfway, at, rad_to_deg(atan((crest - h) / at.distance_to(crest_at)))]
		last = h
	return [foot, foot, 0.0]


## How far a box resting on the sand at a place slides in three seconds of gale.
func _slide(at: Vector2, down: Vector2) -> float:
	# You stand upwind, out of its way.
	teleport(at.x - down.x * 5.0, at.y - down.y * 5.0)
	await settle(true)
	var box := drop_box(at.x, at.y, 0.3)
	await physics_frames(30)
	var from := box.global_position
	await physics_frames(3 * Engine.physics_ticks_per_second)
	var moved := Vector2(box.global_position.x - from.x, box.global_position.z - from.z).length()
	box.queue_free()
	return moved
