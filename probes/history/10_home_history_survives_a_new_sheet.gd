extends Probe
## Real remote structures retain their excavation and exposed ground across a player sheet change.

func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var shape := TerrainShape.new(1234, tuning)
	var sites := shape.sites
	sites.follow(0, 0, 0.0, 0.0, 1.0, 64)
	var halloran := shape.history.landmark(&"halloran")
	var crossing: Dictionary = halloran.parts.filter(func(part: Dictionary) -> bool: return part.id == &"crossing")[0]
	var home_anchor := Sites.Anchor.new(4000, 0, crossing.p, 1.0, shape.history.radius)
	var home := Rect2(3936, -64, 128, 128)
	sites.retain(&"home", home, home_anchor)
	check(not sites.ready(home), "an unsurveyed remote area is not ready")
	check(sites.ready(Rect2(-20, -20, 40, 40)), "remote work does not block ready player ground")
	var until := Time.get_ticks_msec() + 10000
	while not sites.ready(home) and Time.get_ticks_msec() < until:
		sites.step(Time.get_ticks_usec() + 1000)
		await get_tree().process_frame
	check(sites.ready(home), "the real camp anchor schedules and surveys its own history")
	var found := sites.query(home).filter(func(site: Site) -> bool: return site.id == -7001)
	check(found.size() == 1 and found[0] is Structure, "the actual Crossing structure is laid once")
	if found.is_empty():
		sites.finish()
		return
	var structure := found[0] as Structure
	structure.dug_m = 0.4
	structure.sifted_m3 = 1.25
	structure.hold_ground()
	structure.keep(structure.taken() + 0.5)
	var exposed := structure.held_sand()
	var before := Vector2(structure.x, structure.z)
	sites.follow(9000, 0, -0.4, 2.0, 1.0, 64)
	check(sites.ready(home) and sites.anchor().x == 9000 and sites.follows == 2,
		"a player sheet jump retains remote readiness without changing the home anchor")
	check(sites.query(home).has(structure) and Vector2(structure.x, structure.z) == before
		and structure.dug_m == 0.4 and structure.sifted_m3 == 1.25 and structure.held_sand() == exposed,
		"the same exposed, excavated structure survives unchanged")
	check(sites.memories().any(func(entry: Array) -> bool: return entry[1] == home_anchor.x),
		"retained orphan units keep their geographic anchors in history memories")
	sites.release(&"home")
	sites.follow(9000, 0, -0.4, 2.0, 1.0, 64)
	check(not sites.query(home).has(structure), "unmarked remote history retires normally")
	sites.finish()
