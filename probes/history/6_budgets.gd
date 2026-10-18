extends WorldProbe
## World system probe 6: the world system keeps its budgets (docs/world-system.md).
## The history pass under 40 ms, the best of three seeds; a cell's sites
## under 1 ms on average where paths run; no part of laying so long that one
## begun as the streaming budget ends passes the hitch line; a chunk's own
## query under 50 µs; the history and a Rim sheet under 8 MB; and standing
## still, none of it runs at all.
## Runs alone

const PASS_MS := 40.0
const CELL_MS := 1.0
const QUERY_US := 50.0
const MEMORY_MB := 8.0
const STILL_TICKS := 300


func run() -> void:
	var tuning := Tuning.current()
	var best := INF
	for run_seed: int in [1234, 7, 99]:
		var started := Time.get_ticks_usec()
		History.new(run_seed, tuning)
		best = minf(best, (Time.get_ticks_usec() - started) / 1000.0)
	var ground := TerrainShape.new(1234, tuning)
	var before := Performance.get_monitor(Performance.MEMORY_STATIC)
	var history := History.new(1234, tuning)
	var cells: Array = history._cell_paths.keys().slice(0, 400)
	var started := Time.get_ticks_usec()
	for cell: int in cells:
		history.sites_in_cell(cell)
	var cell_ms := (Time.get_ticks_usec() - started) / 1000.0 / cells.size()
	var sites := Sites.new(history, ground.ruins, tuning)
	var anchor := Sites.Anchor.new(0.0, 0.0, history.landmark(&"halfrise").p, 1.0, history.radius)
	# Laying round Halfrise, where history is richest, a part at a time as
	# the streaming budget does it.
	var near := history.cells.within(anchor.p, tuning.history_lay_m)
	var parts := 0
	var slowest := 0.0
	started = Time.get_ticks_usec()
	for cell in near:
		var unit := sites._begun(cell, anchor)
		while not unit.todo.is_empty():
			var one := Time.get_ticks_usec()
			sites._make(unit, unit.todo.pop_front())
			slowest = maxf(slowest, (Time.get_ticks_usec() - one) / 1000.0)
			parts += 1
		sites._put(unit)
	var unit_ms := (Time.get_ticks_usec() - started) / 1000.0 / near.size()
	var memory := (Performance.get_monitor(Performance.MEMORY_STATIC) - before) / 1048576.0
	print("pass %.1f ms; a cell's sites %.3f ms; a unit %.3f ms in %.1f parts, the slowest %.3f ms (%d at the Rim); %.1f MB"
		% [best, cell_ms, unit_ms, float(parts) / near.size(), slowest, near.size(), memory])
	check(best <= PASS_MS, "the history pass under %.0f ms (%.1f)" % [PASS_MS, best])
	check(cell_ms <= CELL_MS, "a cell's sites under %.1f ms on average (%.3f)" % [CELL_MS, cell_ms])
	# A part may start just as the budget ends: it must still land under the hitch line.
	var room := tuning.stream_frame_max_ms - tuning.stream_budget_ms
	check(slowest <= room, "no part of laying past the hitch line's room, %.1f ms (%.3f)" % [room, slowest])
	check(memory <= MEMORY_MB, "the history and a Rim sheet under %.0f MB (%.1f)" % [MEMORY_MB, memory])

	# In the world, at the Rim where history is richest: a chunk's own query,
	# then standing still.
	await load_world(1234, true, true)
	var rim := Sphere.toward(world.shape.history.landmark(&"halfrise").p, 0.0, 600.0 / world.shape.history.radius)
	world.travel(rad_to_deg(Sphere.latitude(rim)), rad_to_deg(Sphere.longitude(rim)), 0.0)
	await settle()
	var index := world.shape.sites
	var chunks := world.terrain.chunks()
	started = Time.get_ticks_usec()
	var answers := 0
	for chunk: TerrainChunk in chunks:
		var square := Rect2(Vector2(chunk.coord) * chunk.side, Vector2.ONE * chunk.side)
		answers += index.query(square).size() + index.paths_in(square).size()
	var query_us := float(Time.get_ticks_usec() - started) / chunks.size()
	print("a chunk's query %.1f µs over %d chunks (%d answers)" % [query_us, chunks.size(), answers])
	check(query_us <= QUERY_US, "a chunk's own query under %.0f µs (%.1f)" % [QUERY_US, query_us])
	while not index.is_idle():
		await get_tree().process_frame
	var follows := index.follows
	var laid := index.laid
	await physics_frames(STILL_TICKS)
	check(index.follows == follows and index.laid == laid and index.is_idle(),
		"standing still, the sheet never runs (%d follows, %d laid)" % [index.follows - follows, index.laid - laid])
