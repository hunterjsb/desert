extends WorldProbe
## Structure kits probe 3: loaded ground never changes across an exposure
## change. A house ruin stood by hand, its ground first built from afar while
## the sand still covered it. Then the weather strips it bare: the clock says
## dug out, but while any of its ground is loaded it stays as it was read,
## and the ground built closer in after the change is built as before, the
## ground's one function agreeing with it. Walked away until its ground is
## forgotten and back, it's read afresh, dug out, and built so.

const KIND := &"house_ruin"
## Its ground is first built from this many chunks off, too far to be solid.
const AFAR := 4


func run() -> void:
	await load_world(1234, true, true)
	world.time_warp = 0.0
	var sites := world.shape.sites
	var size := world.tuning.chunk_size
	var from := Vector2(world.player_world_x(), world.player_world_z())
	var site: Structure = null
	var moments := Vector2.ZERO
	for k in 30:
		site = sites.by_hand(KIND, from.x + 300.0 + k * 13.0, from.y + 40.0 * (k % 4), 0.2, 0.0)
		moments = _moments(site)
		if site.stands() and moments != Vector2.ZERO:
			break
	check(site.stands() and moments != Vector2.ZERO, "a ruin the weather strips bare within three days")
	if moments == Vector2.ZERO:
		return
	# As deep as leaves it under the sand at the first moment, dug out at the second.
	var taken := [Exposure.stripped(world.weather.field, site.x, site.z, moments.x, world.tuning),
		Exposure.stripped(world.weather.field, site.x, site.z, moments.y, world.tuning)]
	site.depth = taken[1] * 0.95
	world.time = moments.x
	sites.add(site)
	teleport(site.x + AFAR * size, site.z)
	await settle()
	var was := site.state()
	check(was != Exposure.EXPOSED, "first read under the sand (%s)" % Exposure.NAMES[was])

	# The storm comes and goes; you walk in.
	world.time = moments.y
	await physics_frames(10)
	var approach := site.to_world(site.piece.approach)
	teleport(approach.x, approach.y)
	await settle()
	var chunk := world.terrain.chunk_under(site.x, site.z)
	check(site.state() == was and chunk.state_of(site) == was,
		"held as it was read while its ground is loaded (%s, built %s)" % [Exposure.NAMES[site.state()],
			Exposure.NAMES[chunk.state_of(site)]])
	check(_off(site) < 1e-4, "its ground built since agrees with the function (%.5f m off)" % _off(site))

	# Away until its ground is forgotten, and back.
	teleport(site.x + (world.tuning.view_radius + 4) * size, site.z)
	await settle()
	check(is_nan(site.decided_at), "nothing holds it once its ground is gone")
	teleport(approach.x, approach.y)
	await settle()
	chunk = world.terrain.chunk_under(site.x, site.z)
	check(chunk.state_of(site) == Exposure.EXPOSED, "read afresh on the way back: dug out (%s)"
		% Exposure.NAMES[chunk.state_of(site)])
	check(_off(site) < 1e-4, "and built so (%.5f m off)" % _off(site))


## Two moments a tick apart or more, the second a day later at most, between
## which the weather took off at least half as much sand again: (0, 0) if
## none in three days.
func _moments(site: Structure) -> Vector2:
	var field := world.weather.field
	var step := world.tuning.site_exposure_step_minutes * 60.0
	for k in 144:
		var t0 := k * step
		var a := Exposure.stripped(field, site.x, site.z, t0, world.tuning)
		for later in range(2, 48):
			var b := Exposure.stripped(field, site.x, site.z, t0 + later * step, world.tuning)
			if b > 0.4 and a < b * 0.5:
				return Vector2(t0, t0 + later * step)
	return Vector2.ZERO


## The most any solid chunk under its ground differs from the function, m.
func _off(site: Structure) -> float:
	var off := 0.0
	for chunk: TerrainChunk in world.terrain.chunks():
		var square := Rect2(Vector2(chunk.coord) * chunk.side, Vector2.ONE * chunk.side)
		if not chunk.has_collision() or not site.touches(square):
			continue
		var data := chunk.collision_data()
		for j in chunk.side + 1:
			for i in chunk.side + 1:
				var x := chunk.coord.x * chunk.side + i
				var z := chunk.coord.y * chunk.side + j
				off = maxf(off, absf(data[j * (chunk.side + 1) + i] - world.shape.height_at(x, z)))
	return off
