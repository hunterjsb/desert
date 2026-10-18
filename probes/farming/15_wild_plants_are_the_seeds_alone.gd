extends Probe
## Farming probe 15: wild plants are the seed's and history's alone. Laid from
## the same point, two builds of one seed grow the very same wild plants round
## a pilgrim road; laid from a point 400 m off, the same plants grow there,
## each where it was but for the seam between the two sheets, no farther off
## than the road's own line moved; another seed grows others.

const AROUND := 6


func run() -> void:
	var first := _laid(1234, Vector2.ZERO)
	var again := _laid(1234, Vector2.ZERO)
	check(first[0].size() > 100 and first[0] == again[0], "one seed, laid alike, grows the same wild plants (%d)"
		% first[0].size())
	var off := _laid(1234, Vector2(400.0, 0.0))
	var by_id := {}
	for each: Dictionary in off[0]:
		by_id[each.id] = each
	var shared := 0
	var worst := 0.0
	for each: Dictionary in first[0]:
		if by_id.has(each.id):
			shared += 1
			worst = maxf(worst, Vector2(each.x, each.z).distance_to(Vector2(by_id[each.id].x, by_id[each.id].z)))
	var seam := 0.0
	for key: Vector2i in first[1]:
		if off[1].has(key):
			seam = maxf(seam, (first[1][key] as Vector2).distance_to(off[1][key]))
	print("laid from 400 m off: %d of %d the same plants, the farthest %.2f m apart; the road's line %.2f m" % [shared,
		first[0].size(), worst, seam])
	check(shared >= first[0].size() * 0.95 and worst <= seam + 0.1,
		"laid from elsewhere, the same plants stand where they did, moved no more than the road's line")
	var other := _laid(77, Vector2.ZERO)
	check(other[0] != first[0], "another seed grows others (%d)" % other[0].size())


## The wild plants of the chunks round a pilgrim road's middle, the sheet laid
## from a point `from` m off it in world metres, and where that sheet laid
## the line of every path through them, by [path, point].
func _laid(run_seed: int, from: Vector2) -> Array:
	var tuning := Tuning.current()
	var ground := TerrainShape.new(run_seed, tuning)
	var history := ground.history
	var road: PathNetwork.Path = null
	for path in history.network.paths:
		if path.kind == &"pilgrim_road":
			road = path
			break
	var at := road.at(road.length() * 0.5)
	var anchor := Sites.Anchor.new(0.0, 0.0, at, 1.0, history.radius)
	var p := anchor.point_at(from.x, from.y)
	ground.sites.follow(from.x, from.y, Sphere.latitude(p), Sphere.longitude(p), 1.0, 1300.0)
	var out := []
	var size := tuning.chunk_size
	for j in range(-AROUND, AROUND):
		for i in range(-AROUND, AROUND):
			out.append_array(Feral.plan(history, ground.sites, Vector2i(i, j), size))
	var line := {}
	for piece in ground.sites.paths_in(Rect2(Vector2.ONE * -AROUND * size, Vector2.ONE * AROUND * 2 * size)):
		for k in piece.points.size():
			line[Vector2i(piece.path, piece.first + k)] = piece.points[k]
	return [out, line]
