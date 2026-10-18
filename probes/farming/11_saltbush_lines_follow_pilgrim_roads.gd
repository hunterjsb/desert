extends FeralProbe
## Farming probe 11: saltbush lines follow the pilgrim roads. Stood on a
## pilgrim road out of Sister, every saltbush of the pilgrim roads' habitat
## stands within a few metres of a pilgrim road's line, far inside its
## corridor; and the road reads as a line: most of every ten metres of it
## through loaded ground has a bush on either side.

## The habitat's own band, its side and its jitter along, with room.
const NEAR := 4.0
const LINED := 0.75
const STEP := 10.0


func run() -> void:
	await load_world(1234, true, true)
	await on_path(&"pilgrim_road")
	var pieces := pieces_for(Feral.HABITATS[0])
	var lining := planned().filter(func(each: Dictionary) -> bool: return each.row == 0)
	var worst := 0.0
	for each: Dictionary in lining:
		worst = maxf(worst, off_line(Vector2(each.x, each.z), pieces))
	check(lining.size() > 100, "saltbush lines the pilgrim road (%d bushes)" % lining.size())
	check(worst <= NEAR, "every one within %.0f m of a pilgrim road's line, inside its %.0f m corridor (%.1f m)"
		% [NEAR, PathNetwork.CORRIDOR, worst])
	var spots := 0
	var lined := 0
	for piece in pieces:
		for i in piece.points.size() - 1:
			var a := piece.points[i]
			var b := piece.points[i + 1]
			var run := (b - a).normalized()
			for k in floori(a.distance_to(b) / STEP):
				var at := a + run * (k + 0.5) * STEP
				if not world.terrain.is_loaded_at(at.x, at.y):
					continue
				spots += 1
				var sides := {}
				for each: Dictionary in lining:
					var off := Vector2(each.x, each.z) - at
					if absf(off.dot(run)) <= STEP * 0.5 and off.length() <= NEAR:
						sides[signf(run.cross(off))] = true
				lined += 1 if sides.size() == 2 else 0
	var share := float(lined) / maxi(spots, 1)
	print("%d bushes, the farthest %.2f m off the road; %d of %d ten-metre spans lined both sides" % [lining.size(),
		worst, lined, spots])
	check(spots > 30 and share >= LINED, "the road reads as a line: %d%% of its spans lined both sides"
		% roundi(share * 100.0))
