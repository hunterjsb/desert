extends Probe
## The landmark survives the flat sheet being laid elsewhere, including a
## reversed north after crossing a pole. No duplicate or seed-dependent omission.

func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	for seed_value in [1234, 7, 99]:
		var shape := TerrainShape.new(seed_value, tuning)
		var history := shape.history
		var hall := history.landmark(&"halloran")
		var crossing: Dictionary = hall.parts.filter(func(p: Dictionary) -> bool: return p.id == &"crossing")[0]
		var key := -1 - history.landmarks.find(hall)
		var identity := 0
		for facing in [1.0, -1.0]:
			var anchor := Sites.Anchor.new(80000 * facing, -42000, crossing.p, facing, history.radius)
			var unit := shape.sites._begun(key, anchor)
			check(unit.sites.size() == 1, "exactly one Halloran encounter on each sheet")
			var site := unit.sites[0] as HalloranSite
			site.place()
			check(site.stands() and site.point.is_equal_approx(crossing.p), "the city stands at its seeded moon position")
			check(Vector2(site.x, site.z).distance_to(Vector2(anchor.x, anchor.z)) < 0.01,
				"the city follows the sheet's world origin")
			check(identity == 0 or identity == site.id, "the encounter retains its identity after circumnavigation")
			identity = site.id
			var forward := site.to_world(Vector2(300, 0)) - Vector2(site.x, site.z)
			check(forward.length() > 299.9 and unit.ground.has_point(site.to_world(Vector2(-330, 0)))
				and unit.ground.has_point(site.to_world(Vector2(330, 0))), "the connected route fits inside its landmark")
