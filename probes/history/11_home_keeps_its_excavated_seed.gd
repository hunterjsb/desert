extends Probe
## Remote camp excavation survives the dune seed cache's ordinary far-cell eviction.

func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var shape := TerrainShape.new(1234, tuning)
	var sites := shape.sites
	var dunes := sites.dunes
	var kept: DuneRuins.Seed
	for seed in dunes.cells_near(Vector2.ZERO, 1500):
		dunes.locate(seed)
		if seed.site != null:
			kept = seed
			break
	check(kept != null, "a real dune seed has a ruin")
	if kept == null:
		return
	kept.dug = 0.35
	kept.sifted = 1.25
	kept.site.dug_m = kept.dug
	kept.site.sifted_m3 = kept.sifted
	var home := Rect2(kept.site.x - 64, kept.site.z - 64, 128, 128)
	sites.retain(&"home", home, Sites.Anchor.new(0, 0, Sphere.point(0, 0), 1, shape.history.radius))
	for i in 300:
		var filler := DuneRuins.Seed.new()
		filler.key = Vector2i(10000 + i, 10000)
		dunes._cells[filler.key] = filler
	dunes._forget(Vector2(20000, 20000))
	check(dunes._cells.get(kept.key) == kept and kept.site.dug_m == 0.35
		and dunes.memories().any(func(entry: Array) -> bool: return entry[0] == kept.key.x \
			and entry[1] == kept.key.y and entry[2] == 0.35 and entry[4] == 1.25),
		"the same marked seed and its excavation remain in save memory")
	sites.release(&"home")
	for i in 300:
		var filler := DuneRuins.Seed.new()
		filler.key = Vector2i(10000 + i, 10000)
		dunes._cells[filler.key] = filler
	dunes._forget(Vector2(20000, 20000))
	check(not dunes._cells.has(kept.key), "an unmarked far seed can retire again")
	sites.finish()
