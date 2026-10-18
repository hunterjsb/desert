extends SalvageProbe
## Salvage & ruins probe 1: the same seed, chunk and weather always give the
## same finds. Planned twice from scratch, history's house ruins stand in the
## same places round a town and every chunk's loose finds there come out the
## same; any moment within one tick of the weather's record reads the same
## exposure; the weather changes what a find is, never where it lies. In the
## world, a chunk's finds come back as they were when its ground does, less
## what you took; once the chunk has been forgotten its loose finds come back
## whole, and what you took from a site stays taken while the site is laid.

const SEED := 77
const CHUNKS := 12


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var one := TerrainShape.new(SEED, tuning)
	var two := TerrainShape.new(SEED, tuning)
	var field := WeatherField.new(SEED, tuning)
	var ground := Vector2.ONE * tuning.chunk_size * 0.5
	var at := StructureKit.starts_among(SEED, tuning, Sphere.point(0.0, 0.0), ground)[0]
	for shape in [one, two]:
		shape.sites.follow(ground.x, ground.y, Sphere.latitude(at), Sphere.longitude(at), 1.0, tuning.history_lay_m)
	var ruins_one := _ruins(one)
	var ruins_two := _ruins(two)
	check(not ruins_one.is_empty() and ruins_one.map(_ruin_key) == ruins_two.map(_ruin_key),
		"ruins stand in the same places on the same seed (%d)" % ruins_one.size())

	var differs := 0
	var moved := 0
	var plans := 0
	var exposures := 0
	# The chunks the roads round the town run through, where loose finds lie.
	var on_roads := {}
	for unit in one.sites.units():
		for piece in unit.pieces:
			for k in piece.points.size() - 1:
				var length := piece.points[k].distance_to(piece.points[k + 1])
				for d in range(0, ceili(length), 32):
					var p := piece.points[k].lerp(piece.points[k + 1], d / maxf(length, 1.0))
					on_roads[Vector2i(floori(p.x / tuning.chunk_size), floori(p.y / tuning.chunk_size))] = true
	var coords: Array = on_roads.keys().slice(0, CHUNKS * CHUNKS)
	for n in coords.size():
		var coord: Vector2i = coords[n]
		var middle := (Vector2(coord) + Vector2.ONE * 0.5) * tuning.chunk_size
		var t := 3600.0 * n
		var exposed := Finds.exposure(field, middle.x, middle.y, t, tuning)
		if exposed != Finds.exposure(field, middle.x, middle.y, t + 1.0, tuning):
			# t is on a tick, so a second later is the same tick.
			exposures += 1
		var a := Finds.plan(SEED, coord, exposed, tuning, one.height_at, _way(one), _on(one))
		var b := Finds.plan(SEED, coord, exposed, tuning, two.height_at, _way(two), _on(two))
		plans += a.size()
		if var_to_str(a) != var_to_str(b):
			differs += 1
		# The calmest and the stormiest weather: what changes, and what can't.
		var calm := Finds.plan(SEED, coord, 0.0, tuning, one.height_at, _way(one), _on(one))
		var storm := Finds.plan(SEED, coord, 1.0, tuning, one.height_at, _way(one), _on(one))
		if calm.map(_lies) != storm.map(_lies):
			moved += 1
	print("%d finds planned over %d chunks on the roads" % [plans, coords.size()])
	check(plans > 5, "chunks on the way have finds")
	check(differs == 0, "the same seed, chunk and weather plan the same finds (%d chunks differ)" % differs)
	check(exposures == 0, "a moment within one tick reads the same exposure (%d differ)" % exposures)
	check(moved == 0, "the weather never changes where a find lies (%d chunks moved)" % moved)
	await _in_the_world()


## A chunk's finds, taken out of range and back, then forgotten and back:
## one of a site's, and a loose one.
func _in_the_world() -> void:
	await load_salvage()
	# Time holds still, so every visit reads the same weather.
	world.time_warp = 0.0
	var home := Vector2(world.player_world_x(), world.player_world_z())
	var before := _laid_out()
	check(before.size() >= 5, "finds lie round the start (%d)" % before.size())
	var gone := []
	for site_find in [true, false]:
		for body in salvage.finds():
			if (body.get_meta(&"find").size() > 2) == site_find and before.has(str(body.get_meta(&"find"))):
				gone.append(str(body.get_meta(&"find")))
				salvage.claim(body)
				body.free()
				break
	check(gone.size() == 2, "a site's find and a loose one taken")
	# Far enough that their ground stops being solid, near enough that it stays loaded.
	await go(home.x + 5.0 * world.tuning.chunk_size, home.y)
	await go(home.x, home.y)
	var back := _laid_out()
	var expected := before.duplicate()
	for key: String in gone:
		expected.erase(key)
	check(_same(back, expected),
		"its finds come back as they were, less those taken (%d of %d)" % [back.size(), expected.size()])
	# Far enough that the chunks are forgotten, near enough that the sites stay laid.
	await go(home.x + 20.0 * world.tuning.chunk_size, home.y)
	await go(home.x, home.y)
	var whole := before.duplicate()
	whole.erase(gone[0])
	check(_same(_laid_out(), whole), "a forgotten chunk's loose finds come back whole, a site's taken stays taken")


## Every find lying in the solid ground round you: where it lies and what it
## is, by its place in its chunk's plan.
func _laid_out() -> Dictionary:
	var out := {}
	var here := world.terrain.chunk_at(world.player_world_x(), world.player_world_z())
	for body in salvage.finds():
		var coord: Vector2i = body.get_meta(&"find")[0]
		if maxi(absi(coord.x - here.x), absi(coord.y - here.y)) > world.tuning.near_radius:
			continue
		var p := body.global_transform
		var at := Vector3(world.world_x(p.origin.x), p.origin.y, world.world_z(p.origin.z))
		var fitted: Array = (body as Device).parts().map(func(part: Part) -> String: return part.label) \
			if body is Device else []
		out[str(body.get_meta(&"find"))] = [body.get(&"label"), at, p.basis, fitted, body.get_meta(&"layer"),
			body.has_meta(&"buried")]
	return out


## Buried ones within a millimetre where they lie; loose ones settle by
## physics, within a centimetre and a couple of degrees of before.
func _same(a: Dictionary, b: Dictionary) -> bool:
	if _sorted(a.keys()) != _sorted(b.keys()):
		printerr("finds differ: %s vs %s" % [_sorted(a.keys()), _sorted(b.keys())])
		return false
	for key: String in a:
		var x: Array = a[key]
		var y: Array = b[key]
		var turned := (x[2] as Basis).get_rotation_quaternion().angle_to((y[2] as Basis).get_rotation_quaternion())
		var near := 0.001 if x[5] else 0.01
		if x[0] != y[0] or x[3] != y[3] or x[4] != y[4] or x[5] != y[5] \
				or (x[1] as Vector3).distance_to(y[1]) > near or turned > (0.001 if x[5] else 0.04):
			printerr("%s differs: %s vs %s" % [key, x, y])
			return false
	return true


func _sorted(keys: Array) -> Array:
	var out := keys.duplicate()
	out.sort()
	return out


## The house ruins standing in a shape's laid sheet, by id.
func _ruins(shape: TerrainShape) -> Array[Ruin]:
	var found: Array[Ruin] = []
	for unit in shape.sites.units():
		for site in unit.sites:
			if site is Ruin and site.stands():
				found.append(site)
	found.sort_custom(func(a: Ruin, b: Ruin) -> bool: return a.id < b.id)
	return found


## Where a shape's loose finds may lie.
func _way(shape: TerrainShape) -> Callable:
	return func(x: float, z: float) -> bool: return Finds.on_way(shape.sites, x, z, Tuning.current().finds_scatter_m)


## What keeps a shape's open sand clear of its structures.
func _on(shape: TerrainShape) -> Callable:
	return func(x: float, z: float) -> bool: return shape.sites.covering(x, z) != null


func _ruin_key(ruin: Ruin) -> String:
	return "%s %d %.4f" % [ruin.center, ruin.turn, ruin.floor_y]


func _lies(spec: Dictionary) -> String:
	return "%d %.4f %.4f %.4f" % [spec.index, spec.x, spec.z, spec.yaw]
