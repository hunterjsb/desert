extends WorldProbe
## Loot probe 8: light loot falls in a crest's lee near camp, no line needed.
## Through a storm's hour round its heart, you camped at the foot of a tall
## slip face would have a few light things fall out of the wind round you,
## and on open sand none; in the world they lie on the sand round you, each
## where the lee is deep, a surface find held there, never more than a
## pile's worth.

const SEED := 1234
## For the world's storm, the wind this many times as thick with what it carries.
const THICK := 10.0


func run() -> void:
	var tuning := Tuning.current()
	await load_world(SEED, false, true)
	world.time_warp = 0.0
	world.player.set_physics_process(false)
	var mean := WeatherField.mean_heading(SEED)
	var lee := Vector2(NAN, NAN)
	for foot in Scenarios.feet(world, mean):
		if world.weather.lee.share(foot.x, foot.y, mean) >= Scenarios.LEE_SHARE:
			lee = foot
			break
	var open := open_sand(30.0)
	check(lee.is_finite() and open.is_finite(), "a slip face's foot and open sand near the start")
	if not lee.is_finite() or not open.is_finite():
		return
	var field := world.weather.field
	var heart := -1.0
	var t := 0.0
	while t < 3.0 * 24.0 * 3600.0 and heart < 0.0:
		if field.raw_storm_at(lee.x, lee.y, t) >= tuning.exposure_storm_full \
				and field.raw_storm_at(open.x, open.y, t) >= tuning.exposure_storm_full:
			heart = t
		t += 300.0
	check(heart >= 0.0, "a storm's heart over both")
	if heart < 0.0:
		return
	var expected := [0.0, 0.0]
	for k in 2:
		_put([lee, open][k])
		await settle()
		var tick := floori((heart - 1800.0) / tuning.drift_tick_s)
		while tick * tuning.drift_tick_s < heart + 1800.0:
			for ground in Drift.lee_ground(world, tick * tuning.drift_tick_s):
				var mid: Vector2 = ground[1]
				expected[k] += tuning.drift_lee_fall * Drift.LEE_CELL * Drift.LEE_CELL / 100.0 * ground[2] \
					* Exposure.reading(field, mid.x, mid.y, tick * tuning.drift_tick_s, tuning) * tuning.drift_tick_s / 3600.0
			tick += 1
	print("through a storm's hour round its heart, light things to fall round you: %.1f under a slip face, %.1f on open sand"
		% expected)
	check(expected[0] >= 1.0 and expected[1] == 0.0, "a few in a crest's lee, none on open sand")

	tuning.drift_lee_fall *= THICK
	_put(lee)
	await settle()
	world.time = heart - 1800.0
	world.salvage._drift_tick = floori(world.time / tuning.drift_tick_s)
	await physics_frames(2)
	world.time = heart
	await physics_frames(2)
	var fallen: Array[RigidBody3D] = []
	for node in world.content.get_children():
		if node is RigidBody3D and node.has_meta(&"drift"):
			fallen.append(node)
	var deep := fallen.filter(func(body: RigidBody3D) -> bool:
		var at := Vector2(world.world_x(body.global_position.x), world.world_z(body.global_position.z))
		return at.distance_to(lee) <= tuning.drift_lee_fall_m + Drift.LEE_CELL \
			and world.weather.lee.share(at.x, at.y, field.wind_at(at.x, at.y, heart).angle()) >= Drift.LEE_LEAST * 0.6 \
			and body.freeze)
	print("in the world, %d fell round you, %d of them in the lee and held there" % [fallen.size(), deep.size()])
	check(not fallen.is_empty() and deep.size() == fallen.size(), "they lie round you in the lee, held on the sand")
	check(fallen.size() <= tuning.drift_most, "never more than a pile's worth")


func _put(at: Vector2) -> void:
	world.player.global_position = Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 1.0, world.engine_z(at.y))
