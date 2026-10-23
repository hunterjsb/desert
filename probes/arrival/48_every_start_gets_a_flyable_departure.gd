extends Probe
## Every start gets a departure the station can fly, its default pulse landing on
## the surveyed site; launch time moves the landing; another run's survey is refused.

func run() -> void:
	var tuning := Tuning.current()
	for run_seed in [1234, 42, 9876, 7, 2024]:
		var shape := TerrainShape.new(run_seed, tuning)
		var point := Starts.find(shape, &"artery", tuning)
		var ground := Starts.ground(shape, tuning, &"artery", point)
		var anchor := Sites.Anchor.new(ground.x, ground.y, point, 1.0, shape.history.radius)
		shape.landforms.follow(anchor)
		var plan := LandingPlan.build(shape, anchor, tuning)
		var model := DepartureTrajectory.build(plan, 123.0, tuning)
		check(DepartureTrajectory.valid(model), "seed %d calibrates a flyable departure" % run_seed)
		if not DepartureTrajectory.valid(model):
			continue
		var target: Vector2 = LandingPlan.selected(plan).get("landing_world", anchor.place(anchor.p))
		var now := DepartureTrajectory.resolve(shape, plan, model, 123.0, tuning)
		var miss := (now.sample.landing_world as Vector2).distance_to(target)
		check(miss <= tuning.arrival_calibration_m * 2.0, "seed %d's default pulse lands on its site (%.2f m off)" % [run_seed, miss])
		var later := DepartureTrajectory.resolve(shape, plan, model, 183.0, tuning)
		check((later.sample.landing_world as Vector2).distance_to(now.sample.landing_world) > 1.0, "launching later lands elsewhere")
		if run_seed == 1234:
			check(now.safe, "the default forecast is clear ground")
			var foreign := model.duplicate(true)
			foreign.seed = 4321
			check(DepartureTrajectory.resolve(shape, plan, foreign, 123.0, tuning).status == &"foreign_survey",
				"another run's survey cannot authorise a landing")
