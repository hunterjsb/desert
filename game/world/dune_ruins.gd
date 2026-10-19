class_name DuneRuins
extends RefCounted
## Dune archaeology's ruins: one seeded under each big dune, in its own lee,
## deeper than anything short of an intense storm strips. Each is only a seed
## until something of it shows and you've slowed near it: nothing at a chunk's
## load, no ground, look or loot. A worker at low priority finds where the
## ones near you lie and how far out of the sand they are, nearest first, and
## only while you're slow, so a fast rider's never gets that far; a bared one
## builds into the site index once you've slowed within reach (Sites.join).
## Its place is the dunes' and its depth and loot its seed's, so it's the same
## ruin whenever and however it's come to.

## What a dune's ruin may be, by weight: the colony's habitats, and now and
## then a First Kingdoms hut the dunes came over.
const KINDS := [[&"hab_pod", 3], [&"pipe_wall_hut", 1]]
## The dunes are read along the wind this far apart through a cell, m; a crest
## is a top over this many samples either way, and its slip face ends where
## the ground falls less than this a metre.
const STEP := 2.0
const TOP := 10
const TOE := 0.12
## Past its dune's period, the lee is read this far on, m. A ruin is tried
## this many places this far apart down the flat past its dune's slip face,
## and lies where the dune term says it's in a lee at least this deep.
const LEE_M := 160.0
const TRIES := 10
const TRY_M := 5.0
## Then as far along the crest either way, m.
const ASIDE: Array[float] = [0.0, 60.0, -60.0]
const LEE := -0.3
## Seeds looked at a worker's turn, and how often a turn may start, s.
const BATCH := 3
const TURN_S := 0.2
## Watch points (a ground radar) are kept this long past their last ask, s of world time.
const WATCHED_S := 10.0


## One big dune's ruin, by its cell along and across the wind.
class Seed:
	var key: Vector2i
	var id: int
	## Surveyed where it lies, never laid until it's built; null where the
	## cell holds no big dune or the ground won't take it.
	var site: Structure
	var found := false
	## Its dune's height over the lee it lies in, m.
	var crest := 0.0
	## The sand off it and how far out of the sand that has it (Exposure.level),
	## as last read, and when.
	var taken := 0.0
	var level := -1.0
	var read_at := -INF
	var built := false
	## Built when a save was made: built again as soon as the sheet is laid.
	var again := false
	## Sand dug off it by hand, m, and of that what a sieve sifted, m³, kept
	## while its cell is.
	var dug := 0.0
	var sifted := 0.0


## How many reads and builds there have been, the slowest worker turn, ms,
## the main thread's most in a frame looking over the seeds, ms, and with a
## build in it (Sites.step_dunes): the dev overlay's, and the probes'.
var reads := 0
var builds := 0
var slowest_turn_ms := 0.0
var slowest_step_ms := 0.0
var slowest_ms := 0.0

var _ctx: StructureKit.Context
var _tuning: Tuning
var _seed: int
var _cells := {}
var _task := -1
var _turn_at := -INF
## Places a ground radar asks about: id -> [x, z, radius, world time asked].
var _watch := {}
## Your pace over the sand, m/s, and how long you've been slow, s.
var _last := Vector2(NAN, NAN)
var _pace := 0.0
var _slow_for := 0.0


func _init(run_seed: int, ctx: StructureKit.Context, tuning: Tuning) -> void:
	_seed = run_seed
	_ctx = ctx
	_tuning = tuning


## Each frame, from where you are: your pace, a worker's turn at the seeds
## round you while you're slow (and round each ground radar always), and the
## bared ones within reach of you once you've slowed, to build.
func step(x: float, z: float, t: float, delta: float) -> Array[Seed]:
	var started := Time.get_ticks_usec()
	var here := Vector2(x, z)
	if delta > 0.0 and not is_nan(_last.x):
		_pace = lerpf(_pace, here.distance_to(_last) / delta, 1.0 - exp(-delta / 0.5))
	_last = here
	_slow_for = _slow_for + delta if _pace < _tuning.dune_ruin_slow_m_s else 0.0
	var due: Array[Seed] = []
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task):
			return due
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	for seed: Seed in _cells.values():
		if seed.again and seed.site != null and not seed.built:
			due.append(seed)
	if slowed():
		for seed in near(x, z, _tuning.dune_ruin_build_m):
			if seed.site != null and not seed.built and seed.level > 0.0:
				due.append(seed)
	var now := Time.get_ticks_msec() / 1000.0
	if now >= _turn_at + TURN_S:
		var batch := _stale(here, t)
		if not batch.is_empty():
			_turn_at = now
			_task = WorkerThreadPool.add_task(_turn.bind(batch, t), false)
	_forget(here)
	slowest_step_ms = maxf(slowest_step_ms, (Time.get_ticks_usec() - started) / 1000.0)
	return due


## Whether you've been slow long enough to stop for what's near.
func slowed() -> bool:
	return _slow_for >= _tuning.dune_ruin_slow_s


## A ground radar's place, looked over whatever your pace, for a while.
func watch(id: int, x: float, z: float, radius: float, t: float) -> void:
	_watch[id] = [x, z, radius, t]


## The seeds found within `radius` m of a world place, nearest first.
func near(x: float, z: float, radius: float) -> Array[Seed]:
	var out: Array[Seed] = []
	for seed in cells_near(Vector2(x, z), radius, false):
		if seed.found and seed.site != null and seed.site.distance_to(x, z) <= radius:
			out.append(seed)
	out.sort_custom(func(a: Seed, b: Seed) -> bool: return a.site.distance_to(x, z) < b.site.distance_to(x, z))
	return out


## The seed found whose ground a world place is on, or null.
func under(x: float, z: float) -> Seed:
	for seed in cells_near(Vector2(x, z), 1.0, false):
		if seed.found and seed.site != null and seed.site.reaches(x, z):
			return seed
	return null


## Sand dug off a seed not built yet, m: it comes out of the sand as the dig
## takes it, and with something of it showing it builds. How much came off.
func dig(seed: Seed, m: float, t: float) -> float:
	var site := seed.site
	var by := minf(m, site.depth - site.with_dug(site.pure_taken(t)))
	if by <= 0.0:
		return 0.0
	seed.dug += by
	site.dug_m = seed.dug
	_read(seed, t)
	return by


## Every seed in a cell within `radius` m of a place, made as they're asked.
func cells_near(at: Vector2, radius: float, make := true) -> Array[Seed]:
	var shape: TerrainShape = _ctx.shape.get_ref()
	var out: Array[Seed] = []
	if shape == null:
		return out
	var down := shape.downwind()
	var u := at.x * down.x + at.y * down.y
	var v := at.y * down.x - at.x * down.y
	var along := _tuning.dune_spacing
	var across := _tuning.dune_ruin_cell_m
	# A cell's ruin lies up to its period and its lee past its own cell.
	for n in range(floori((u - radius - LEE_M) / along), floori((u + radius) / along) + 1):
		for m in range(floori((v - radius) / across), floori((v + radius) / across) + 1):
			var key := Vector2i(n, m)
			var seed: Seed = _cells.get(key)
			if seed == null:
				if not make:
					continue
				seed = Seed.new()
				seed.key = key
				seed.id = hash([_seed, "dune ruin", key]) & 0x3fffffffffffffff
				_cells[key] = seed
			out.append(seed)
	return out


## The seeds round you and round each ground radar that want a worker's
## look, nearest first: never found, or read longer ago than the recheck.
func _stale(here: Vector2, t: float) -> Array[Seed]:
	var places: Array[Array] = []
	if slowed():
		places.append([here, _tuning.dune_ruin_check_m])
	for id: int in _watch.keys():
		var w: Array = _watch[id]
		if t - w[3] > WATCHED_S or t < w[3]:
			_watch.erase(id)
		else:
			places.append([Vector2(w[0], w[1]), w[2]])
	var wanted: Array[Array] = []
	for place in places:
		var at: Vector2 = place[0]
		for seed in cells_near(at, place[1]):
			if seed.found and (seed.site == null or seed.built):
				continue
			if seed.found and t - seed.read_at < _tuning.dune_ruin_recheck_s and t >= seed.read_at:
				continue
			var by := seed.site.distance_to(at.x, at.y) if seed.site != null else middle(seed).distance_to(at)
			if by <= place[1] + LEE_M:
				wanted.append([by, seed])
	wanted.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array[Seed] = []
	for each in wanted:
		if not out.has(each[1]):
			out.append(each[1])
		if out.size() >= BATCH:
			break
	return out


## A cell's middle, world metres.
func middle(seed: Seed) -> Vector2:
	var shape: TerrainShape = _ctx.shape.get_ref()
	var down := shape.downwind()
	var u := (seed.key.x + 0.5) * _tuning.dune_spacing
	var v := (seed.key.y + 0.5) * _tuning.dune_ruin_cell_m
	return Vector2(u * down.x - v * down.y, u * down.y + v * down.x)


## A worker's turn: each seed found if it isn't, and read at world time `t`.
func _turn(batch: Array[Seed], t: float) -> void:
	var started := Time.get_ticks_usec()
	for seed in batch:
		if not seed.found:
			locate(seed)
		if seed.site != null:
			seed.site.dug_m = seed.dug
			_read(seed, t)
			reads += 1
	slowest_turn_ms = maxf(slowest_turn_ms, (Time.get_ticks_usec() - started) / 1000.0)


func _read(seed: Seed, t: float) -> void:
	seed.taken = seed.site.with_dug(seed.site.pure_taken(t))
	seed.level = Exposure.level(seed.site.depth, seed.taken)
	seed.read_at = t


## Where a cell's ruin lies, if it holds one: through a seeded line across the
## cell along the wind, the highest crest whose top lies in the cell, standing
## big over the trough past its slip face; the ruin in its lee, on the flat
## past the foot of its slip face, surveyed as any structure is. Pure in the
## seed and the dunes, so a worker can.
func locate(seed: Seed) -> void:
	seed.site = _ruin(seed)
	seed.found = true


func _ruin(seed: Seed) -> Structure:
	var shape: TerrainShape = _ctx.shape.get_ref()
	if shape == null:
		return null
	var down := shape.downwind()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed.id
	var along := _tuning.dune_spacing
	var v := (seed.key.y + rng.randf_range(0.2, 0.8)) * _tuning.dune_ruin_cell_m
	var u0 := seed.key.x * along - TOP * STEP
	var count := ceili((along + LEE_M) / STEP) + TOP
	var hs := PackedFloat32Array()
	hs.resize(count + 1)
	for k in count + 1:
		var u := u0 + k * STEP
		hs[k] = shape.dunes(u * down.x - v * down.y, u * down.y + v * down.x)
	var top := -1
	for k in range(TOP, TOP + ceili(along / STEP)):
		if top >= 0 and hs[k] <= hs[top]:
			continue
		var crest := true
		for d in range(-TOP, TOP + 1):
			if hs[k + d] > hs[k]:
				crest = false
				break
		if crest:
			top = k
	if top < 0:
		return null
	var low := top
	while low < count and hs[low + 1] <= hs[low]:
		low += 1
	seed.crest = hs[top] - hs[low]
	if seed.crest < _tuning.dune_ruin_big_m:
		return null
	var toe := top
	while toe < low and (hs[toe] - hs[toe + 1]) / STEP > TOE:
		toe += 1
	var kind: StringName = Finds._pick(rng, KINDS)
	var piece := StructureKit.piece(kind)
	var bearing := rng.randf() * TAU
	var depth := rng.randf_range(_tuning.dune_ruin_depth_m.x, _tuning.dune_ruin_depth_m.y)
	# Down the flat from the foot of its slip face, the first place the ground
	# takes it that's still its dune's lee.
	for k in TRIES * ASIDE.size():
		var u := u0 + toe * STEP + piece.reach * 0.5 + (k % TRIES) * TRY_M
		var w: float = v + ASIDE[k / TRIES]
		var site: Structure = piece.builds.new()
		site.id = seed.id
		site.kind = kind
		site.era = piece.era
		site.x = u * down.x - w * down.y
		site.z = u * down.y + w * down.x
		site.bearing = bearing
		site.depth = depth
		site.loot = hash([_seed, "dune ruin", seed.key, "loot"])
		site.source = &"dune"
		site.setup(piece, _ctx)
		site.place()
		if site.stands() and site.dune <= LEE:
			return site
	return null


## A built ruin dug: its seed keeps what's off it while its cell is kept.
func dug(site: Structure) -> void:
	for seed: Seed in _cells.values():
		if seed.site == site:
			seed.dug = site.dug_m


## A built ruin's unit is lifted: its seed is a seed again, its dug sand gone
## with the site's memory.
func lifted(site: Structure) -> void:
	for seed: Seed in _cells.values():
		if seed.site == site:
			seed.built = false
			seed.dug = 0.0
			site.dug_m = 0.0
			seed.read_at = -INF


## Seeds forgotten once all of their cell is past where history is lifted:
## what was dug off one goes with it, as a site's memory does.
func _forget(here: Vector2) -> void:
	if _cells.size() < 256:
		return
	var lift := _tuning.history_lift_m
	for key: Vector2i in _cells.keys():
		var seed: Seed = _cells[key]
		if middle(seed).distance_to(here) > lift + _tuning.dune_spacing:
			_cells.erase(key)


## Waits for a worker's turn in hand: before the shape goes.
func finish() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


## What a save keeps: each seed dug or built, [cell x, cell y, dug m, built,
## sifted m³].
func memories() -> Array:
	var out := []
	for seed: Seed in _cells.values():
		if seed.site != null:
			seed.sifted = seed.site.sifted_m3
		if seed.dug > 0.0 or seed.built:
			out.append([seed.key.x, seed.key.y, seed.dug, seed.built, seed.sifted])
	return out


## A resumed run's seeds as they were: the sand dug off each, and those built
## found at once and built again as soon as the sheet is laid.
func recall(memories: Array) -> void:
	finish()
	_cells.clear()
	for each: Array in memories:
		var key := Vector2i(each[0], each[1])
		var seed := Seed.new()
		seed.key = key
		seed.id = hash([_seed, "dune ruin", key]) & 0x3fffffffffffffff
		seed.dug = each[2]
		seed.sifted = each[4] if each.size() > 4 else 0.0
		_cells[key] = seed
		locate(seed)
		if seed.site != null:
			seed.site.dug_m = seed.dug
			seed.site.sifted_m3 = seed.sifted
			seed.again = each[3]
