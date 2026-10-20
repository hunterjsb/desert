extends Probe
## A mountain approach stays fixed under streamed ground and restored camps.
func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	for id in [&"starcom", &"observatory"]:
		var shape := TerrainShape.new(1234, tuning)
		var mark := shape.history.landmark(id)
		var anchor := Sites.Anchor.new(64000, -32000, mark.p, -1.0, shape.history.radius)
		shape.landforms.follow(anchor)
		var hill := shape.landforms.get_hill(id)
		var worst := 0.0
		# Radial approaches sample actual dunes too, not just the analytic slope.
		for k in 8:
			var way := Vector2.from_angle(TAU * k / 8)
			for r in range(100, int(hill.radius * 0.75), 8):
				var at := hill.at + way * r
				var ahead := at + way
				worst = maxf(worst, absf(shape.dunes(at.x, at.y) - shape.dunes(ahead.x, ahead.y)))
		print("%s: radial slope %.3f, summit %.1fm" % [id, worst, shape.dunes(hill.at.x, hill.at.y)])
		check(worst < tan(deg_to_rad(tuning.slip_angle)), "a gentle approach reaches the summit")
		var at := hill.at + Vector2(700, 200)
		var before := shape.height_at(at.x, at.y)
		shape.landforms.follow(Sites.Anchor.new(64100, -32000, anchor.point_at(64100, -32000), -1, shape.history.radius))
		check(shape.height_at(at.x, at.y) == before, "walking never moves loaded mountain ground")
		var saved := shape.landforms.memories()
		var restored := TerrainShape.new(1234, tuning)
		restored.landforms.recall(saved)
		check(restored.height_at(at.x, at.y) == before, "a resumed camp keeps its exact ground")
		var coord := Vector2i(floori(at.x / tuning.chunk_size), floori(at.y / tuning.chunk_size))
		var build := ChunkBuild.make(shape, coord, tuning.chunk_size, 1, 0, ChunkBuild.indices_for(tuning.chunk_size))
		check(absf(build.heights[0] - shape.height_at(coord.x * tuning.chunk_size, coord.y * tuning.chunk_size)) < 0.001,
			"rendered and collision samples include the mountain")
		var unit := shape.sites._begun(-1 - shape.history.landmarks.find(mark), anchor)
		Sites._survey(unit.sites)
		check(unit.sites.size() == 1 and (unit.sites[0] as Structure).stands(), "the summit has actual colonial ground")
		var site := unit.sites[0] as Structure
		check(absf(site.pad() - hill.height) < 10 and site.piece.sockets.size() > 0 and not site.piece.beds.is_empty(),
			"arrival has shelter, a resting place and salvage at the summit")

		for seed in shape.sites.dunes.cells_near(hill.at, 200):
			shape.sites.dunes.locate(seed)
			check(seed.site == null, "a mountain summit is not a wind-excavatable dune")

		for loot_seed in 12:
			site.loot = loot_seed
			site.depth = 0
			site.decide(0)
			var drawn := 0
			for socket in site.piece.sockets.size():
				drawn += int(not SiteLoot.draw(site, socket).is_empty())
			check(SiteLoot.plan(site, shape.height_at).size() == drawn, "every surviving summit supply is within reach")
			site.forget()
