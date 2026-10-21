extends Probe
## A saved regional choice cannot reroll with unrelated random calls or reload.
func run() -> void:
	var tuning := Tuning.current()
	for run_seed in [1234, 42, 9876]:
		var shape := TerrainShape.new(run_seed, tuning)
		var point := Starts.find(shape, &"artery", tuning)
		var ground := Starts.ground(shape, tuning, &"artery", point)
		var anchor := Sites.Anchor.new(ground.x, ground.y, point, 1.0, shape.history.radius)
		shape.landforms.follow(anchor)
		var plan := LandingPlan.build(shape, anchor)
		print("LANDING_PLAN ", run_seed, " ", plan.candidates.size(), " candidates")
		check(plan.candidates.size() >= 3 and plan.candidates.size() <= 5, "the drop corridor has several actual choices")
		if plan.candidates.is_empty():
			continue
		for candidate: Dictionary in plan.candidates:
			var chosen := LandingPlan.select(plan, candidate.id, 1.3, &"shallow")
			check(LandingPlan.validate(shape, anchor, chosen), "each proposed footprint remains valid on its real sheet")
			if candidate.id != &"fallback":
				check(not candidate.signals.is_empty(), "an alternative offers a nearby real exposed salvage structure")
		var chosen := LandingPlan.select(plan, plan.candidates[-1].id, 1.3, &"steep")
		var loaded: Dictionary = bytes_to_var(var_to_bytes(chosen))
		for i in 100:
			randi()
		check(LandingPlan.build(shape, anchor) == plan and LandingPlan.selected(loaded) == plan.candidates[-1],
			"reloading and unrelated random draws preserve the selected geographic destination")
		check(loaded.profile == &"steep" and is_equal_approx(loaded.heading, 1.3), "trajectory and approach survive loading")
