extends Probe
## A stale safe flag cannot authorize an obstructed or foreign-sheet destination.
func run() -> void:
	var tuning := Tuning.current()
	var shape := TerrainShape.new(1234, tuning)
	var point := Starts.find(shape, &"artery", tuning)
	var ground := Starts.ground(shape, tuning, &"artery", point)
	var anchor := Sites.Anchor.new(ground.x, ground.y, point, 1.0, shape.history.radius)
	shape.landforms.follow(anchor)
	var plan := LandingPlan.build(shape, anchor)
	check(not LandingPlan.selected(plan).is_empty(), "a safe departure exists before checking refusal")
	if LandingPlan.selected(plan).is_empty():
		return
	var wrong := plan.duplicate(true)
	wrong.seed += 1
	check(not LandingPlan.validate(shape, anchor, wrong), "a plan from another run cannot authorize launch")
	var shifted := Sites.Anchor.new(anchor.x + 100.0, anchor.z, anchor.p, anchor.facing, anchor.radius)
	check(not LandingPlan.validate(shape, shifted, plan), "a different sheet cannot reinterpret the saved geography")
	check(LandingPlan.select(plan, &"missing", 0.0, &"standard").is_empty()
		and LandingPlan.select(plan, plan.selected_id, NAN, &"standard").is_empty(), "unknown destination and nonfinite approach are refused")
	var records: Array[Dictionary] = []
	for cell in shape.history.cells.within(point, LandingPlan.RULES.corridor_radius_m):
		records.append_array(shape.history.sites_in_cell(cell))
	for record: Dictionary in records:
		var at := anchor.place(record.p)
		if at.distance_to(ground) > LandingPlan.RULES.corridor_radius_m:
			continue
		wrong = plan.duplicate(true)
		for candidate: Dictionary in wrong.candidates:
			if candidate.id == wrong.selected_id:
				candidate.landing_world = at
				candidate.point = anchor.point_at(at.x, at.y)
		check(not LandingPlan.validate(shape, anchor, wrong), "a saved safe flag cannot bypass the actual structure footprint")
		return
	check(false, "the obstructed-destination case found a real history site")
