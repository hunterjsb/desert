extends MenuProbe
## A navigation source must agree with live planning and its streamed body.
## Spatial availability fixture; it does not drive the expedition.
## The launch choice is the untouched default pulse at departure clock zero.
## Time limit: 600 s

const SEEDS := [1234, 1, 2]
const ACQUISITION_M := 6000.0
var candidates := {}

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
			if body.get_meta(&"catalog", &"") != &"home_beacon":
				_record(body.get_meta(&"catalog", &""), 0.0, available)
		await _audit(run_seed, available)
		main.queue_free()
		world = null
		await get_tree().process_frame
		await get_tree().process_frame


func _audit(run_seed: int, available: Dictionary) -> void:
	# The broad index guides the search; only live witnesses can satisfy it.
	candidates.clear()
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
				var candidate := spec.duplicate(true)
				candidate.site = site.id
				_offer(candidate, distance)
		if fresh != null:
			fresh.free()
	if not _planned(available):
		_loose(shape, ground, flight.arrival_time, rules, available)
	world.arrival.cancel()
	world.arrival_state = {}
	world.counts_deeds = false
	world.player.set_physics_process(false)
	for id: StringName in REQUIRED:
		if not available.has(id):
			var choices: Array = candidates.get(id, [])
			choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)
			for candidate: Dictionary in choices:
				await _visit(flight, Vector2(candidate.x, candidate.z))
				var read := NavigationWitness.read(world, candidate)
				if read.matches:
					_record_body(read.body, ground, available)
				else:
					for replacement: Dictionary in NavigationWitness.observed(world, candidate.id, ground, ACQUISITION_M):
						_record_body(NavigationWitness.read(world, replacement).body, ground, available)
				if available.has(id):
					break
		check(available.has(id), "seed %d supplies a witnessed %s or physical ship store within %.0f m" % [run_seed, id, ACQUISITION_M])
		if available.has(id):
			metric("seed %d %s witness" % [run_seed, id], available[id], "m")
	await _visit(flight, ground)
	var taken := func(site: int, index: int) -> bool: return world.salvage.taken(site, index)
	var target := Finds.beacon(run_seed, world.shape.sites, ground.x, ground.y, rules, taken, ACQUISITION_M)
	check(await _real_target(flight, area, target), "seed %d has a real unclaimed loot target within acquisition range" % run_seed)
	if run_seed == 1:
		var rig := shape.sites.nearest(ground.x, ground.y, ACQUISITION_M, func(site: Site) -> bool: return site.kind == &"nomad_rig")
		var encountered := false
		if rig != null:
			var toward := Vector2(rig.x, rig.z)
			for step in ceili(ground.distance_to(toward) / 100.0) + 1:
				var at := ground.move_toward(toward, step * 100.0)
				await _visit(flight, at)
				var heard := Finds.beacon(run_seed, world.shape.sites, at.x, at.y, rules, taken, rules.receiver_reach_m)
				if await _real_target(flight, area, heard):
					encountered = true
					metric("seed 1 walk before receiver pickup", ground.distance_to(at), "m")
					break
		check(encountered, "seed 1's ordinary walk toward the nearest nomad rig acquires a real beacon")
	shape.sites.finish()


func _planned(available: Dictionary) -> bool:
	return REQUIRED.all(func(id: StringName) -> bool: return available.has(id) or candidates.has(id))


func _offer(spec: Dictionary, metres: float) -> void:
	var id := _kind(spec.id)
	if id not in REQUIRED:
		return
	spec.distance = metres
	if not candidates.has(id):
		candidates[id] = []
	candidates[id].append(spec)


func _visit(flight: Dictionary, at: Vector2) -> void:
	world.respawn(at.x, at.y, 0.0, flight.arrival_time)
	var origin: Vector2 = flight.landing_world
	var anchor := Sites.Anchor.new(origin.x, origin.y, flight.landing_point, 1.0, world.shape.history.radius)
	var here := anchor.point_at(at.x, at.y)
	world.moon.place(rad_to_deg(Sphere.latitude(here)), rad_to_deg(Sphere.longitude(here)))
	await physics_frames(3)
	await settle(true)
	for tick in 6000:
		if world.salvage.is_idle():
			return
		await get_tree().process_frame
	check(false, "ordinary salvage finishes streaming at the witness")


func _record_body(body: RigidBody3D, origin: Vector2, available: Dictionary) -> void:
	var at := Vector2(world.world_x(body.global_position.x), world.world_z(body.global_position.z))
	var metres := origin.distance_to(at)
	if metres <= ACQUISITION_M:
		_record(body.get_meta(&"catalog", &""), metres, available)


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
				var candidate := spec.duplicate(true)
				candidate.coord = coord
				_offer(candidate, distance)
		if _planned(available):
			return


func _kind(id: StringName) -> StringName:
	var definition: Dictionary = Catalog.DEVICES.get(id, {})
	if definition.get("radio", false) and not definition.get("receiver", false) and not definition.get("crystal", false):
		return &"radio"
	return id


func _record(id: StringName, metres: float, available: Dictionary) -> void:
	id = _kind(id)
	if id in REQUIRED and (not available.has(id) or metres < available[id]):
		available[id] = metres


func _real_target(flight: Dictionary, area: Rect2, target: Dictionary) -> bool:
	if target.is_empty():
		return false
	for site: Site in world.shape.sites.query(area, false):
		if site.id != target.site or not site is Structure:
			continue
		for spec: Dictionary in SiteLoot.plan(site, world.height_at):
			if spec.index != target.index:
				continue
			var candidate := spec.duplicate(true)
			candidate.site = site.id
			await _visit(flight, Vector2(spec.x, spec.z))
			var read := NavigationWitness.read(world, candidate)
			# A receiver can advertise a real locked hold; taking it may still need a tool.
			return read.body != null and read.actual.get("id", &"") == spec.id \
				and read.body.get_meta(&"catalog", &"") == spec.id
	return false
