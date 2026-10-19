extends WorldProbe
## Structure kits probe 8: a buried site costs nothing until it's bared and
## you've slowed by. A big dune's ruin at a moment a storm has it bared:
## ridden past fast, a stone's throw off, nothing of it is found, read or
## built, and the frame pays a few microseconds for the seeds; stopped near
## it, it's read on a worker, builds into the index, and its chunk draws it.
## Runs alone: it times real frames.

const SPEED := 20.0
const RIDE := 600.0
const BESIDE := 40.0
const STOP := 60.0
## The seeds' main-thread share of a frame, at most, ms.
const STEP_MS := 0.2


func run() -> void:
	await load_world(1234, false, true)
	world.time_warp = 0.0
	world.player.set_physics_process(false)
	var dunes := world.shape.sites.dunes
	var down := world.shape.downwind()
	var found := Scenarios.bared_dune_ruin(world, Vector2(world.player_world_x(), world.player_world_z()), 2500.0)
	check(not found.is_empty(), "a big dune's ruin a storm lays bare")
	if found.is_empty():
		return
	var ruin: Structure = found.site
	var key: Vector2i = found.key
	var moment: float = found.time
	world.time = moment
	var at := Vector2(ruin.x, ruin.z)
	var side := down.orthogonal() * BESIDE
	_put(at + side - down * RIDE * 0.6)
	await settle()
	# Off at full speed from here, nothing looked at yet.
	dunes.finish()
	dunes._cells.clear()
	dunes._pace = SPEED
	dunes._slow_for = 0.0
	dunes.slowest_step_ms = 0.0
	for i in roundi(RIDE / SPEED * 60.0):
		_put(at + side - down * RIDE * 0.6 + down * SPEED / 60.0 * i)
		await get_tree().physics_frame
	var seed: DuneRuins.Seed = dunes._cells.get(key)
	print("ridden past at %.0f m/s %.0f m off: its seed %s; the seeds' most in a frame %.3f ms" % [SPEED, BESIDE,
		"never made" if seed == null else ("found" if seed.found else "made"), dunes.slowest_step_ms])
	check(seed == null or not seed.found, "nothing of it found or read riding past")
	check(world.shape.sites.covering(ruin.x, ruin.z) == null and dunes.builds == 0, "nothing built")
	check(dunes.slowest_step_ms < STEP_MS, "the seeds cost a frame under %.1f ms" % STEP_MS)
	_put(at + down * (STOP + ruin.reach))
	for i in 600:
		await get_tree().physics_frame
		seed = dunes._cells.get(key)
		if seed != null and seed.built:
			break
	check(seed != null and seed.built and world.shape.sites.covering(ruin.x, ruin.z) == seed.site,
		"stopped near it, it's read and built")
	await settle()
	var chunk := world.terrain.chunk_under(ruin.x, ruin.z)
	check(chunk != null and seed != null and chunk.view_of(seed.site) != null, "its chunk draws it")


func _put(at: Vector2) -> void:
	world.player.global_position = Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 1.0, world.engine_z(at.y))
	world.player.velocity = Vector3.ZERO
