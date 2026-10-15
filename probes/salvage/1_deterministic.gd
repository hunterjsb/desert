extends SalvageProbe
## Salvage & ruins probe 1: the same seed, chunk and weather always give the
## same finds. Planned twice from scratch, ruins stand in the same places and
## every chunk's finds come out the same; any moment within one tick of the
## weather's record reads the same exposure; the weather changes what a find
## is, never where it lies. In the world, a chunk's finds come back as they
## were when its ground does, less what you took, and whole once the chunk
## has been forgotten.

const SEED := 77
const CHUNKS := 12


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var one := TerrainShape.new(SEED, tuning)
	var two := TerrainShape.new(SEED, tuning)
	var field := WeatherField.new(SEED, tuning)
	var ruins_one := one.ruins.around(0.0, 0.0, 3000.0)
	var ruins_two := two.ruins.around(0.0, 0.0, 3000.0)
	check(not ruins_one.is_empty() and ruins_one.map(_ruin_key) == ruins_two.map(_ruin_key),
		"ruins stand in the same places on the same seed (%d)" % ruins_one.size())

	var differs := 0
	var moved := 0
	var plans := 0
	var exposures := 0
	for j in CHUNKS:
		for i in CHUNKS:
			var coord := Vector2i(i * 3 - 18, j * 3 - 18)
			var middle := (Vector2(coord) + Vector2.ONE * 0.5) * tuning.chunk_size
			var t := 3600.0 * (i + j)
			var exposed := Finds.exposure(field, middle.x, middle.y, t, tuning)
			if exposed != Finds.exposure(field, middle.x, middle.y, t + 1.0, tuning):
				# t is on a tick, so a second later is the same tick.
				exposures += 1
			var a := Finds.plan(SEED, coord, exposed, tuning, one.height_at, one.ruins.in_chunk(coord))
			var b := Finds.plan(SEED, coord, exposed, tuning, two.height_at, two.ruins.in_chunk(coord))
			plans += a.size()
			if var_to_str(a) != var_to_str(b):
				differs += 1
			# The calmest and the stormiest weather: what changes, and what can't.
			var calm := Finds.plan(SEED, coord, 0.0, tuning, one.height_at, one.ruins.in_chunk(coord))
			var storm := Finds.plan(SEED, coord, 1.0, tuning, one.height_at, one.ruins.in_chunk(coord))
			if calm.map(_lies) != storm.map(_lies):
				moved += 1
	print("%d finds planned over %d chunks" % [plans, CHUNKS * CHUNKS])
	check(plans > CHUNKS * CHUNKS, "chunks have finds")
	check(differs == 0, "the same seed, chunk and weather plan the same finds (%d chunks differ)" % differs)
	check(exposures == 0, "a moment within one tick reads the same exposure (%d differ)" % exposures)
	check(moved == 0, "the weather never changes where a find lies (%d chunks moved)" % moved)
	await _in_the_world()


## A chunk's finds, taken out of range and back, then forgotten and back.
func _in_the_world() -> void:
	await load_salvage()
	# Time holds still, so every visit reads the same weather.
	world.time_warp = 0.0
	var home := Vector2(world.player_world_x(), world.player_world_z())
	var before := _laid_out()
	check(before.size() >= 5, "finds lie round the start (%d)" % before.size())
	var taken := salvage.finds()[0]
	var gone: Array = taken.get_meta(&"find")
	salvage.claim(taken)
	taken.free()
	# Far enough that their ground stops being solid, near enough that it stays loaded.
	await go(home.x + 5.0 * world.tuning.chunk_size, home.y)
	await go(home.x, home.y)
	var back := _laid_out()
	var expected := before.duplicate()
	expected.erase(str(gone))
	check(_same(back, expected),
		"its finds come back as they were, less the one taken (%d of %d)" % [back.size(), expected.size()])
	check(not back.has(str(gone)), "what was taken isn't laid out again")
	# Far enough that the chunks are forgotten.
	await go(home.x + 20.0 * world.tuning.chunk_size, home.y)
	await go(home.x, home.y)
	check(_same(_laid_out(), before), "a forgotten chunk comes back whole")


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


func _ruin_key(ruin: Ruin) -> String:
	return "%s %d %.4f" % [ruin.center, ruin.turn, ruin.floor_y]


func _lies(spec: Dictionary) -> String:
	return "%d %.4f %.4f %.4f" % [spec.index, spec.x, spec.z, spec.yaw]
