extends MenuProbe
## Ordinary Surveyor stores and exposed salvage supply the expedition chain.
## The launch choice is the untouched default pulse at departure clock zero.
## Time limit: 600 s

const SEEDS := [1234, 1, 2]
const ACQUISITION_M := 6000.0
const REQUIRED := [&"survey_receiver", &"radio", &"console", &"home_beacon", &"salvage_kite"]


func run() -> void:
	for run_seed: int in SEEDS:
		Tuning.current().run_seed = run_seed
		Tuning.current().salvage = true
		main = MAIN.instantiate()
		main.opens_on_menu = true
		add_child(main)
		await main.new_game(false, false, Kit.standard())
		world = main.world()
		var prep := await cabin()
		if prep == null:
			return
		var available := {}
		for body: Node in world.arrival_nodes.values():
			_record(body.get_meta(&"catalog", &""), 0.0, available)
		_audit(run_seed, available)
		main.queue_free()
		world = null
		await get_tree().process_frame
		await get_tree().process_frame


func _audit(run_seed: int, available: Dictionary) -> void:
	# Lay the future exploration area in the index, without loading its chunks.
	# Only index coverage changes; terrain, weather and loot use ordinary rules.
	var rules := Tuning.current().duplicate() as Tuning
	rules.history_lay_m = ACQUISITION_M + rules.history_cell_m
	rules.history_lift_m = rules.history_lay_m + rules.history_cell_m
	var shape := TerrainShape.new(run_seed, rules)
	var point := Starts.find(shape, Kit.standard().start, rules)
	var ground := Starts.ground(shape, rules, Kit.standard().start, point)
	var anchor := Sites.Anchor.new(ground.x, ground.y, point, 1.0, shape.history.radius)
	var plan := LandingPlan.build(shape, anchor, rules)
	var flight := DepartureTrajectory.sample(DepartureTrajectory.build(plan, 0.0, rules), 0.0)
	check(flight.get("inside_survey", false), "seed %d has an ordinary default departure" % run_seed)
	if not flight.has("landing_world"):
		shape.sites.finish()
		return
	ground = flight.landing_world
	point = flight.landing_point
	shape.sites.set_clock(func() -> float: return flight.arrival_time)
	shape.sites.follow(ground.x, ground.y, Sphere.latitude(point), Sphere.longitude(point), 1.0, ACQUISITION_M)
	var area := Rect2(ground - Vector2.ONE * ACQUISITION_M, Vector2.ONE * ACQUISITION_M * 2.0)
	for site: Site in shape.sites.query(area, false):
		if not site is Structure or site.distance_to(ground.x, ground.y) > ACQUISITION_M:
			continue
		var fresh: Wreckage = Wreckage.new(site, {}, shape.height_at) if site.piece.wreck != null else null
		for spec: Dictionary in SiteLoot.plan(site, shape.height_at):
			if fresh != null and fresh.held_fast(spec.index) != "":
				continue
			var distance := ground.distance_to(Vector2(spec.x, spec.z))
			if distance <= ACQUISITION_M:
				_record(spec.id, distance, available)
		if fresh != null:
			fresh.free()
	if not _complete(available):
		_loose(shape, ground, flight.arrival_time, rules, available)
	for id: StringName in REQUIRED:
		check(available.has(id), "seed %d supplies %s through physical stores or exposed salvage within %.0f m" % [run_seed, id, ACQUISITION_M])
		if available.has(id):
			metric("seed %d %s acquisition" % [run_seed, id], available[id], "m")
	var untouched := func(_site: int, _index: int) -> bool: return false
	var target := Finds.beacon(run_seed, shape.sites, ground.x, ground.y, rules, untouched, ACQUISITION_M)
	check(_real_target(shape.sites, area, target), "seed %d has a real unclaimed loot target within acquisition range" % run_seed)
	if run_seed == 1:
		var rig := shape.sites.nearest(ground.x, ground.y, ACQUISITION_M, func(site: Site) -> bool: return site.kind == &"nomad_rig")
		var encountered := false
		if rig != null:
			var toward := Vector2(rig.x, rig.z)
			for step in ceili(ground.distance_to(toward) / 100.0) + 1:
				var at := ground.move_toward(toward, step * 100.0)
				var heard := Finds.beacon(run_seed, shape.sites, at.x, at.y, rules, untouched, rules.receiver_reach_m)
				if _real_target(shape.sites, area, heard):
					encountered = true
					metric("seed 1 walk before receiver pickup", ground.distance_to(at), "m")
					break
		check(encountered, "seed 1's ordinary walk toward the nearest nomad rig acquires a real beacon")
	shape.sites.finish()


func _complete(available: Dictionary) -> bool:
	return REQUIRED.all(func(id: StringName) -> bool: return available.has(id))


func _loose(shape: TerrainShape, ground: Vector2, t: float, rules: Tuning, available: Dictionary) -> void:
	var size := float(rules.chunk_size)
	var near := Vector2i(floori(ground.x / size), floori(ground.y / size))
	var n := ceili(ACQUISITION_M / size)
	var chunks: Array[Vector2i] = []
	for x in range(-n, n + 1):
		for z in range(-n, n + 1):
			chunks.append(near + Vector2i(x, z))
	chunks.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.distance_squared_to(near) < b.distance_squared_to(near))
	var field := WeatherField.new(shape.history.run_seed, rules)
	var way := func(x: float, z: float) -> bool: return Finds.on_way(shape.sites, x, z, rules.finds_scatter_m)
	var on := func(x: float, z: float) -> bool: return shape.sites.covering(x, z) != null
	for coord: Vector2i in chunks:
		var exposed := Finds.exposure(field, (coord.x + 0.5) * size, (coord.y + 0.5) * size, t, rules)
		for spec: Dictionary in Finds.plan(shape.history.run_seed, coord, exposed, rules, shape.height_at, way, on):
			var distance := ground.distance_to(Vector2(spec.x, spec.z))
			if distance <= ACQUISITION_M:
				_record(spec.id, distance, available)
		if _complete(available):
			return


func _record(id: StringName, metres: float, available: Dictionary) -> void:
	var definition: Dictionary = Catalog.DEVICES.get(id, {})
	if definition.get("radio", false) and not definition.get("receiver", false) and not definition.get("crystal", false):
		id = &"radio"
	if id in REQUIRED and (not available.has(id) or metres < available[id]):
		available[id] = metres


func _real_target(sites: Sites, area: Rect2, target: Dictionary) -> bool:
	if target.is_empty():
		return false
	for site: Site in sites.query(area, false):
		if site.id == target.site and site is Structure:
			return target.index >= 0 and target.index < site.piece.sockets.size() \
				and not SiteLoot.draw(site, target.index).is_empty()
	return false
