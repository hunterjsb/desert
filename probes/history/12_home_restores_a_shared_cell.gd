extends Probe
## A saved camp and player can contain the same landmark key in separate sheets.

func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var shape := TerrainShape.new(1234, tuning)
	var sites := shape.sites
	var landmark := shape.history.landmark(&"halloran")
	var crossing: Dictionary = landmark.parts.filter(func(part: Dictionary) -> bool: return part.id == &"crossing")[0]
	var key := -1 - shape.history.landmarks.find(landmark)
	var home_anchor := Sites.Anchor.new(4000, 0, crossing.p, 1, shape.history.radius)
	var near_anchor := Sites.Anchor.new(0, 0, crossing.p, 1, shape.history.radius)
	var memories := []
	for anchor in [near_anchor, home_anchor]:
		memories.append([key, anchor.x, anchor.z, Sphere.latitude(anchor.p), Sphere.longitude(anchor.p), anchor.facing])
	sites.recall(memories)
	var home := Rect2(3936, -64, 128, 128)
	sites.retain(&"home", home, home_anchor)
	var homes := sites.query(home).filter(func(site: Site) -> bool: return site.id == -7001)
	var near := sites.query(Rect2(-64, -64, 128, 128)).filter(func(site: Site) -> bool: return site.id == -7001)
	check(homes.size() == 1 and near.size() == 1 and homes[0] != near[0],
		"both saved placements of the same geographic structure exist once")
	if homes.is_empty():
		sites.finish()
		return
	var structure := homes[0] as Structure
	structure.dug_m = 0.4
	structure.sifted_m3 = 1.25
	structure.hold_ground()
	structure.keep(structure.taken() + 0.5)
	var excavation := sites.dug_memories()
	var exposure := sites.held()
	var saved := sites.memories()
	var resumed := TerrainShape.new(1234, tuning)
	resumed.sites.recall(saved)
	resumed.sites.recall_dug(excavation, [])
	resumed.sites.recall_held(exposure)
	resumed.sites.retain(&"home", home, home_anchor)
	resumed.sites.hold(Vector2i(floori(structure.x / sites._size), floori(structure.z / sites._size)))
	var found := resumed.sites.query(home).filter(func(site: Site) -> bool: return site.id == -7001)
	check(found.size() == 1 and found[0] is Structure and found[0].dug_m == 0.4
		and found[0].sifted_m3 == 1.25 and is_equal_approx(found[0].held_sand(), structure.held_sand()),
		"the far structure restores excavation and exposed ground with a duplicate cell key")
	resumed.sites.recall(saved)
	check(resumed.sites.query(home).has(found[0]), "recalling identical memories keeps the far object identity")
	sites.finish()
	resumed.sites.finish()
