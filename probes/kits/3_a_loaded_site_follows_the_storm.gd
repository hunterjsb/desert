extends WorldProbe
## Exclusive on noisy runners
## Structure kits probe 3: a loaded site changes as a storm works on it,
## smoothly, and never buries you. A house ruin stood by hand where a storm
## will lay it bare, its ground built while it's under the sand, watched from
## beside it as the storm comes and goes, a few seconds of weather a frame:
## what's drawn and what's solid follow the weather's own function frame by
## frame, its ground pressed afresh agrees with the function, and it comes
## out of the sand and goes back under. Stood in its hall while the storm has
## it dug out, the sand never comes back over you; off its ground it does, no
## faster than site_rebury_m_s. Its ground forgotten and built again is as
## the weather has it then.
## Time limit: 400 s

const KIND := &"house_ruin"
## Seconds of weather a frame as you watch.
const WARP := 3.0


func run() -> void:
	await load_world(1234, true, true)
	world.time_warp = 0.0
	var sites := world.shape.sites
	var from := Vector2(world.player_world_x() + 320.0, world.player_world_z())
	var stands := func(at: Vector2) -> bool: return sites.by_hand(KIND, at.x, at.y, 0.0, 0.0).stands()
	var storm := StormSite.find(world.weather.field, world.tuning, from.x, from.y, 2, 100.0, 1.0, 0.5, stands, world.shape)
	check(not storm.is_empty(), "a storm that lays a ruin bare between sand before and after")
	if storm.is_empty():
		return
	var site := sites.by_hand(KIND, storm.x, storm.z, 0.0, storm.depth)
	world.time = storm.before
	sites.add(site)
	var beside := Vector2(site.x + site.reach + 25.0, site.z)
	teleport(beside.x, beside.y)
	await settle()
	var chunk := world.terrain.chunk_under(site.x, site.z)
	check(site.state() == Exposure.BURIED, "its ground built under the sand (%s)" % Exposure.NAMES[site.state()])

	# The storm comes and goes as you watch.
	var behind := 0.0
	var apart := 0.0
	var most := 0.0
	var t: float = storm.before
	while t < storm.after:
		t += WARP
		await _at(t)
		var want := site.piece.sink_at(Exposure.level(site.depth, site.pure_taken(t)))
		behind = maxf(behind, absf(chunk.sink_of(site) - want))
		apart = maxf(apart, chunk.body_of(site).position.distance_to(chunk.view_of(site).position))
		most = maxf(most, site.level())
		if absf(t - storm.peak) < WARP * 0.5:
			await _pressed()
			check(_off(site) < 1e-4, "mid-storm its ground pressed afresh agrees with the function (%.5f m off)" % _off(site))
	print("drawn %.4f m off the function at most, its boxes %.4f m off its look; out to level %.2f, then %s"
		% [behind, apart, most, Exposure.NAMES[site.state()]])
	check(behind < 0.002 and apart < 0.002, "what's drawn and what's solid follow the function frame by frame")
	check(most >= Exposure.DUG_OUT and site.state() == Exposure.BURIED, "it comes out of the sand and goes back under")
	await _pressed()
	check(_off(site) < 1e-4, "and its ground agrees with it after (%.5f m off)" % _off(site))

	# Stood in its hall while it's dug out, while the storm lets go.
	await _at(storm.peak)
	await _pressed()
	var hall := site.to_world(Vector2(-4.5, 0.0))
	teleport(hall.x, hall.y)
	await physics_frames(10)
	var held := site.level()
	var over := -INF
	t = storm.peak
	while t < storm.after:
		t += WARP
		await _at(t)
		over = maxf(over, world.height_at(world.player_world_x(), world.player_world_z()) - world.player.global_position.y)
		held = minf(held, site.level())
	check(held >= Exposure.DUG_OUT and over < 0.05, "the sand never comes back over you (level %.2f, sand %.3f m over your feet)"
		% [held, over])
	teleport(beside.x, beside.y)
	var fastest := 0.0
	var last := site.taken()
	for k in 400:
		t += 1.0
		await _at(t)
		fastest = maxf(fastest, last - site.taken())
		last = site.taken()
		# The live interpolation keeps its endpoints in a float32 Vector4.
		if site.taken() <= site.pure_taken(t) + 1e-5:
			break
	check(fastest <= world.tuning.site_rebury_m_s * 1.0001 and fastest > 0.0 and site.taken() <= site.pure_taken(t) + 1e-5,
		"off its ground the sand comes back, no faster than %.2f m/s (%.3f)" % [world.tuning.site_rebury_m_s, fastest])

	# Away until its ground is forgotten, and back.
	teleport(site.x + (world.tuning.view_radius + 4) * world.tuning.chunk_size, site.z)
	await settle()
	check(site.ground < 0, "nothing holds it once its ground is gone: the desert ate it")
	await _at(storm.peak)
	teleport(beside.x, beside.y)
	await settle()
	chunk = world.terrain.chunk_under(site.x, site.z)
	var want := site.piece.sink_at(Exposure.level(site.depth, site.pure_taken(world.time)))
	check(absf(chunk.sink_of(site) - want) < 0.002 and _off(site) < 1e-4,
		"built again as the weather has it then (%s)" % Exposure.NAMES[site.state()])


## The weather at world time `t`, and a frame for the ground to follow it.
func _at(t: float) -> void:
	world.time = t
	await get_tree().process_frame
	await get_tree().process_frame


## Until nothing loaded is behind what stands in it.
func _pressed() -> void:
	for i in 300:
		if world.terrain.is_pressed():
			return
		await get_tree().process_frame


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
