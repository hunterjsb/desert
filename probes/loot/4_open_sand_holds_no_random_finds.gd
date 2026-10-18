extends Probe
## Loot probe 4: open sand no longer holds random finds. Where a run begins,
## deep desert, the chunks within a kilometre hold next to none, where they
## once held one and a half each. There and round a town and the roads
## through it, every loose find lies on the way, within a path's corridor or
## among a settlement's sites, and on the way there are about a tenth as many
## as open sand held, in the hardest weather as in the calmest.

const SEED := 1234
const DESERT_M := 1000.0
## The most loose finds a chunk on the way holds on average: a tenth of the
## 1.5 open sand held, and a little.
const ON_THE_WAY := 0.2


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var ground := Vector2.ONE * tuning.chunk_size * 0.5
	var shape := TerrainShape.new(SEED, tuning)
	shape.sites.follow(ground.x, ground.y, deg_to_rad(tuning.spawn_latitude_degrees),
		deg_to_rad(tuning.spawn_longitude_degrees), 1.0, tuning.history_lay_m)
	var desert := _count(shape, ground, DESERT_M, tuning)
	var town := StructureKit.starts_among(SEED, tuning, Sphere.point(0.0, 0.0), ground)[0]
	var near := TerrainShape.new(SEED, tuning)
	near.sites.follow(ground.x, ground.y, Sphere.latitude(town), Sphere.longitude(town), 1.0, tuning.history_lay_m)
	var round_town := _count(near, ground, tuning.history_lay_m - 200.0, tuning)
	print("deep desert: %d finds in %d chunks; round a town: %d finds in %d chunks, %d of them on the way, %d off it"
		% [desert.finds, desert.chunks, round_town.finds, round_town.chunks, round_town.on_way, round_town.off_way])
	check(desert.chunks > 700 and desert.finds <= desert.chunks / 100,
		"next to no loose find in the deep desert round the start (%d)" % desert.finds)
	check(round_town.finds > 10 and desert.off_way + round_town.off_way == 0,
		"every loose find lies on the way (%d off it)" % (desert.off_way + round_town.off_way))
	var share := float(round_town.finds) / maxi(round_town.on_way, 1) / 2.0
	check(share <= ON_THE_WAY, "about a tenth as many as open sand held (%.2f a chunk on the way)" % share)


## Loose finds in the chunks within `radius` m of a place, in the calmest
## and the hardest weather: {chunks, finds, on_way (chunks), off_way (finds)}.
func _count(shape: TerrainShape, at: Vector2, radius: float, tuning: Tuning) -> Dictionary:
	var out := {"chunks": 0, "finds": 0, "on_way": 0, "off_way": 0}
	var on_way := func(x: float, z: float) -> bool: return Finds.on_way(shape.sites, x, z, tuning.finds_scatter_m)
	var reach := ceili(radius / tuning.chunk_size)
	var middle := Vector2i(floori(at.x / tuning.chunk_size), floori(at.y / tuning.chunk_size))
	for j in range(-reach, reach + 1):
		for i in range(-reach, reach + 1):
			var coord := middle + Vector2i(i, j)
			if (Vector2(coord) + Vector2.ONE * 0.5).distance_to(Vector2(middle) + Vector2.ONE * 0.5) * tuning.chunk_size > radius:
				continue
			out.chunks += 1
			var square := Rect2(Vector2(coord) * tuning.chunk_size, Vector2.ONE * tuning.chunk_size)
			out.on_way += int(_touches_way(shape, square, tuning))
			for exposed in [0.0, 1.0]:
				for spec in Finds.plan(SEED, coord, exposed, tuning, shape.height_at, on_way):
					out.finds += 1
					out.off_way += int(not on_way.call(spec.x, spec.z))
	return out


## Whether any of a chunk is on the way, sampled every 16 m.
func _touches_way(shape: TerrainShape, square: Rect2, tuning: Tuning) -> bool:
	for v in range(8, int(square.size.y), 16):
		for u in range(8, int(square.size.x), 16):
			if Finds.on_way(shape.sites, square.position.x + u, square.position.y + v, tuning.finds_scatter_m):
				return true
	return false
