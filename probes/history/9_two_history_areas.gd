extends Probe
## A marked region has independent history readiness without moving the player's anchor.

func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = false
	var shape := TerrainShape.new(1234, tuning)
	var sites := shape.sites
	sites.follow(0, 0, 0.3, 1.0, 1.0, 64)
	var home_anchor := sites.anchor()
	var home := Rect2(-64, -64, 128, 128)
	sites.retain(&"home", home, home_anchor)
	for i in 600:
		if sites.ready(home):
			break
		sites.step(Time.get_ticks_usec() + 1000)
		await get_tree().process_frame
	check(sites.ready(home), "the requested home region becomes ready")
	var kept := sites.units().filter(func(unit: Sites.Unit) -> bool: return unit.ground.intersects(home, true))
	var next := home_anchor.point_at(4000, 0)
	sites.follow(4000, 0, Sphere.latitude(next), Sphere.longitude(next), 1.0, 64)
	check(sites.anchor().x == 4000 and sites.follows == 2, "retention does not follow the global anchor twice")
	check(sites.ready(home) and sites.ready(Rect2(3980, -20, 40, 40)), "both player and remote home are ready")
	check(not sites.ready(Rect2(1900, 0, 20, 20)), "the gap between both areas is not admitted")
	check(not kept.is_empty() and kept.all(func(unit: Sites.Unit) -> bool: return sites.units().has(unit)),
		"the same home units survive player departure")
	sites.release(&"home")
	sites.follow(4000, 0, Sphere.latitude(next), Sphere.longitude(next), 1.0, 64)
	check(not sites.ready(home) and kept.all(func(unit: Sites.Unit) -> bool: return not sites.units().has(unit)),
		"releasing the mark retires distant home history")
	sites.finish()
