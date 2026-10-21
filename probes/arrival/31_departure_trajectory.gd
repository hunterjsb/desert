extends Probe
## A committed pulse must predict the same real safe point after reload and drag.
func run() -> void:
	var tuning := Tuning.current()
	var shape := TerrainShape.new(1234, tuning)
	var point := Starts.find(shape, &"artery", tuning)
	var ground := Starts.ground(shape, tuning, &"artery", point)
	var anchor := Sites.Anchor.new(ground.x, ground.y, point, 1.0, shape.history.radius)
	shape.landforms.follow(anchor)
	var plan := LandingPlan.build(shape, anchor)
	var model := DepartureTrajectory.build(plan, 123.0, tuning)
	check(not model.is_empty(), "the initial pulse reaches the known regional start")
	if model.is_empty():
		return
	var first := DepartureTrajectory.resolve(shape, plan, model, 123.0, tuning)
	print("DEPARTURE status=", first.status, " flight=", first.sample.flight_s, " point=", first.sample.landing_world)
	check(first.safe and LandingPlan.validate(shape, anchor, first.plan), "the default forecast passes actual seeded footprint validation")
	for delay in [5.0, 10.0, 20.0]:
		var walking := DepartureTrajectory.resolve(shape, plan, model, 123.0 + delay, tuning)
		print("WALK_FORECAST ", delay, " ", walking.status)
		check(walking.safe, "the initial course stays actually launchable while boarding")
	var loaded: Dictionary = bytes_to_var(var_to_bytes(model))
	var forecast := DepartureTrajectory.sample(loaded, 123.0, tuning)
	check(forecast == first.sample, "save and resume preserve the whole timed path")
	var later := DepartureTrajectory.sample(model, 183.0, tuning)
	check(later.landing_world.distance_to(forecast.landing_world) > 2.0, "actual launch time changes the forecast")
	check(later.camera_transform == forecast.camera_transform and later.body_basis != forecast.body_basis,
		"the inertial overview shows geography rotating while the carrier tracks it")
	var path: PackedVector3Array = forecast.path
	var times: PackedFloat32Array = forecast.path_times
	check(path.size() == times.size() and times[0] == 0.0 and absf(times[-1] - forecast.flight_s) < 0.0001,
		"flight playback has the exact integration timestamps including impact")
	var arrival_frame := DepartureTrajectory.sample(model, forecast.arrival_time, tuning)
	check((arrival_frame.body_basis * forecast.landing_point).distance_to(path[-1]) < 0.000001,
		"the timed inertial path intersects its rotating body-fixed landing point")
	var wanted := model.duplicate(true)
	wanted.pulse = Vector2(0.5, 0.1)
	var changed := DepartureTrajectory.sample(wanted, 123.0, tuning)
	var camera: Vector3 = forecast.camera_transform.origin
	var dragged := DepartureTrajectory.drag(model, 123.0, camera, (changed.pulse_handle - camera).normalized(), tuning)
	check((dragged.pulse as Vector2).distance_to(wanted.pulse) < 0.00001 and model.pulse != dragged.pulse,
		"dragging the rendered handle edits only the actual single pulse")
	var foreign := model.duplicate(true)
	foreign.seed += 1
	check(not DepartureTrajectory.resolve(shape, plan, foreign, 123.0, tuning).safe, "a foreign survey cannot authorize launch")
	for clock in [123.0, 423.0, 723.0, 1023.0, 1323.0, 3723.0]:
		var future := DepartureTrajectory.sample(model, clock, tuning)
		check(future.get("inside_survey", false), "regulated loiter does not permanently strand a reader outside the corridor")
