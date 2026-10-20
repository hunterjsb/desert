class_name Terrain
extends Node3D
## Streams square chunks around the player by grid position, never by what a
## raycast happens to hit. Workers compute the arrays and convert them into
## meshes; the main thread only attaches them, retires old ground, swaps the
## far ring and lays out what lies on the ground, all inside one time budget
## per frame.

## A chunk's ground became solid, or stopped being solid, or the chunk was
## forgotten: what lies on the ground comes and goes with it.
signal grounded(chunk: TerrainChunk)
signal ungrounded(chunk: TerrainChunk)
signal unloaded(coord: Vector2i)

## Collision samples are 1 m apart, so near chunks are too: what you see is
## exactly what you stand on.
const NEAR_STEP := 1
## Each piece of collision runs a metre past its edges and this far below the
## neighbour's ground there, m. A heightmap's edge is a real edge to Jolt: a
## small body riding sunk in the sand hit the next one's like a step, and a
## loose end dragged across a seam at 13 m/s came out at 3. Deeper than a body
## sinks, the lip's own edge is never met.
const LIP := 0.05
## Structures a storm works on follow it every frame within this many chunks
## of you; further off, this many chunks' worth a frame in turn.
const FOLLOW_NEAR := 2
const FOLLOW_FAR := 6
## Loaded ground pressed afresh at once, at most; and how many steps behind
## what stands in it a mid chunk's ground may fall first: past the near
## ground nobody sees a few centimetres.
const PRESSES := 2
const MID_BEHIND := 8

## Main-thread time streaming took this frame, and the most it has in any one:
## the hitch probe and F3 read them.
var frame_ms := 0.0
var slowest_frame_ms := 0.0
## Main-thread time following what storms work on took this frame, and the
## most a frame has; how many loaded chunks' ground has been pressed afresh,
## all run, the most a press took to swap in on the main thread and the last
## one's time on its worker, ms.
var follow_ms := 0.0
var slowest_follow_ms := 0.0
var presses := 0
var slowest_press_ms := 0.0
var press_job_ms := 0.0

const SAND_SHADER := preload("res://game/world/sand.gdshader")

## The sand's look, chosen at setup; a look-test may set its own first.
var sand_material: Material
## The marks left on the sand, which it's drawn with.
var tracks: Tracks
## What stands on the far ring past the built ground.
var skyline: Skyline

var _world: World
var _tuning: Tuning
var _size: int
var _material_rid: RID
## What every chunk's collision is made of.
var _sand := PhysicsMaterial.new()
var _indices := {}
var _chunks := {}
var _tasks := {}
var _results := {}
var _mutex := Mutex.new()
var _center := Vector2i.ZERO
var _planned := false
var _wanted: Array[Vector3i] = []
## Chunks to look over since the centre last moved: distances change only then.
var _to_retire: Array = []
## Near chunks waiting for their collision, the costliest of streaming's work.
var _to_ground: Array = []
## When this frame's budget runs out, in Time ticks (usec).
var _deadline := 0
var _far: GeometryInstance3D
var _far_mesh: RID
var _far_center := Vector2i.ZERO
var _far_building := Vector2i.ZERO
var _far_task := -1
var _far_next: RID
## Chunks with structures standing on them, by coord; those whose ground is
## behind what stands in it; presses in flight, and their results.
var _standing := {}
var _behind := {}
## Chunks a structure has just joined (Sites.join), loaded or building, to
## the structures to press into each afresh whether or not it kept its dunes.
var _joined := {}
var _pressing := {}
var _pressed := {}
var _far_turn := 0
var _occupants := PackedVector2Array()
var _occupants_frame := -1


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	_size = _tuning.chunk_size
	if sand_material == null:
		sand_material = _sand_look()
	# Compiles the sand's shader now, while the world loads: otherwise the first
	# chunk to arrive stalls its frame on it (18 ms on an RTX 3070).
	_material_rid = sand_material.get_rid()
	# Godot's Jolt takes the lesser of two frictions, and bodies keep their own 1.0.
	_sand.friction = _tuning.sand_friction
	for step in [NEAR_STEP, _tuning.mid_step]:
		_indices[step] = ChunkBuild.indices_for(_size / step)
	_far = GeometryInstance3D.new()
	add_child(_far)
	tracks = Tracks.new()
	add_child(tracks)
	tracks.setup(world, sand_material)
	skyline = Skyline.new()
	add_child(skyline)
	skyline.setup(world)
	# Structures read their exposure as their ground is built, and hold it
	# while that ground is loaded.
	world.shape.sites.set_clock(func() -> float: return world.time)
	world.shape.sites.joined = join
	unloaded.connect(world.shape.sites.release)


func _process(_delta: float) -> void:
	if _world == null:
		return
	var started := Time.get_ticks_usec()
	_deadline = started + int(_tuning.stream_budget_ms * 1000.0)
	var here := chunk_at(_world.player_world_x(), _world.player_world_z())
	if here != _center or not _planned:
		_center = here
		_planned = true
		_plan()
	_ground()
	_launch()
	# Retiring first: uploads arrive nearly every frame in fast flight and
	# would starve it, leaving old ground loaded.
	_retire()
	_update_far()
	_collect()
	_follow_sites()
	_press()
	_collect_presses()
	_world.salvage.stream(_deadline)
	_world.shape.sites.step(_deadline)
	frame_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_frame_ms = maxf(slowest_frame_ms, frame_ms)
	Dev.put("terrain/chk", "%d" % _chunks.size())
	Dev.put("terrain/col", "%d" % collision_count())
	Dev.put("terrain/bld", "%d" % (_tasks.size() + _wanted.size()))
	Dev.put("terrain/upl", "%.1fms" % slowest_frame_ms)
	Dev.put("terrain/site", "%.2fms %d pressed %.2fms" % [follow_ms, presses, slowest_press_ms])


func _exit_tree() -> void:
	# Workers hold this node; let them finish before it goes.
	for id: int in _tasks.values():
		WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()
	for task: Array in _pressing.values():
		WorkerThreadPool.wait_for_task_completion(task[0])
	_pressing.clear()
	for build: ChunkBuild in _pressed.values():
		RenderingServer.free_rid(build.mesh)
	_pressed.clear()
	_world.shape.sites.finish()
	if _far_task != -1:
		WorkerThreadPool.wait_for_task_completion(_far_task)
		_far_task = -1
	# Meshes the workers filled that nothing took.
	for build: ChunkBuild in _results.values():
		RenderingServer.free_rid(build.mesh)
	_results.clear()
	for mesh: RID in [_far_next, _far_mesh]:
		if mesh.is_valid():
			RenderingServer.free_rid(mesh)
	_far_next = RID()
	_far_mesh = RID()


## The ground's one function at a world place, read from a loaded chunk's
## 1 m samples where there is one: the numbers the mesh and collision were
## built from, without computing them again.
func height_at(world_x: float, world_z: float) -> float:
	var coord := chunk_at(world_x, world_z)
	var chunk: TerrainChunk = _chunks.get(coord)
	if chunk == null or chunk.step != NEAR_STEP:
		return _world.shape.height_at(world_x, world_z)
	var x := world_x - coord.x * _size
	var z := world_z - coord.y * _size
	var i := floori(x)
	var j := floori(z)
	var fx := x - i
	var fz := z - j
	var w := _size + 1
	var k := j * w + i
	var h := chunk.heights
	return TerrainShape.across(fx, fz, h[k + 1], h[k + w], h[k] if fx + fz <= 1.0 else h[k + w + 1])


## The loaded chunk a world place lies on, or null: its heights are the
## ground's own samples every `step` m, its far edges included.
func chunk_under(world_x: float, world_z: float) -> TerrainChunk:
	return _chunks.get(chunk_at(world_x, world_z))


func chunk_at(world_x: float, world_z: float) -> Vector2i:
	return Vector2i(floori(world_x / _size), floori(world_z / _size))


func has_collision_at(world_x: float, world_z: float) -> bool:
	var chunk: TerrainChunk = _chunks.get(chunk_at(world_x, world_z))
	return chunk != null and chunk.has_collision()


func is_loaded_at(world_x: float, world_z: float) -> bool:
	return _chunks.has(chunk_at(world_x, world_z))


## Whether any chunk touching a rectangle of world metres is loaded.
func is_loaded_in(rect: Rect2) -> bool:
	var lo := chunk_at(rect.position.x, rect.position.y)
	var hi := chunk_at(rect.end.x, rect.end.y)
	if (hi.x - lo.x + 1) * (hi.y - lo.y + 1) > _chunks.size():
		for coord: Vector2i in _chunks:
			if coord.x >= lo.x and coord.x <= hi.x and coord.y >= lo.y and coord.y <= hi.y:
				return true
		return false
	for j in range(lo.y, hi.y + 1):
		for i in range(lo.x, hi.x + 1):
			if _chunks.has(Vector2i(i, j)):
				return true
	return false


## Forgets every loaded chunk touching a rectangle of world metres, so it's
## built again from the ground's one function as it is now: what a resume
## does where the history under it was laid differently.
func forget(rect: Rect2) -> void:
	var lo := chunk_at(rect.position.x, rect.position.y)
	var hi := chunk_at(rect.end.x, rect.end.y)
	for coord: Vector2i in _chunks.keys():
		if coord.x >= lo.x and coord.x <= hi.x and coord.y >= lo.y and coord.y <= hi.y:
			var chunk: TerrainChunk = _chunks[coord]
			unloaded.emit(coord)
			_to_ground.erase(chunk)
			chunk.free()
			_chunks.erase(coord)
			_standing.erase(coord)
			_joined.erase(coord)
	_planned = false


## Every chunk within collision range of this point has its collision.
func is_settled_around(world_x: float, world_z: float) -> bool:
	var middle := chunk_at(world_x, world_z)
	var r := _tuning.near_radius
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var chunk: TerrainChunk = _chunks.get(middle + Vector2i(dx, dz))
			if chunk == null or not chunk.has_collision():
				return false
	return true


## Nothing left to build, near or far, nor to press afresh.
func is_idle() -> bool:
	return _planned and _tasks.is_empty() and _wanted.is_empty() and _far_task == -1 \
		and _far_mesh.is_valid() and _far_center == _center and skyline.is_idle() and is_pressed()


func chunks() -> Array:
	return _chunks.values()


func collision_count() -> int:
	var count := 0
	for chunk: TerrainChunk in _chunks.values():
		if chunk.has_collision():
			count += 1
	return count


## Storms hide the far ring: nobody inside one can see that far.
func show_far(shown: bool) -> void:
	_far.visible = shown


func is_far_shown() -> bool:
	return _far.visible


## The world's origin moved; put every chunk back at its world position.
func reposition() -> void:
	for chunk: TerrainChunk in _chunks.values():
		_place(chunk)
	_place_far()
	skyline.reposition()
	# The sand's patterns are drawn in world metres, not the engine's.
	if sand_material is ShaderMaterial:
		sand_material.set_shader_parameter("origin", Vector2(_world.origin_chunk) * _size)


func _distance(coord: Vector2i) -> int:
	return TerrainResidency.distance(coord, _center)


func _plan() -> void:
	_to_retire = _chunks.keys()
	_wanted.clear()
	var r := _tuning.view_radius
	# Ring by ring outward, so the nearest ground is built first; bucketed, not
	# sorted, because this runs on the main thread at every chunk crossed.
	var rings: Array[Array] = []
	for d in r + 1:
		rings.append([])
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var coord := _center + Vector2i(dx, dz)
			var d := maxi(absi(dx), absi(dz))
			var step := NEAR_STEP if TerrainResidency.needs_collision(coord, _center, _tuning) else _tuning.mid_step
			var chunk: TerrainChunk = _chunks.get(coord)
			if chunk and chunk.step != 0 and chunk.step <= step:
				continue
			rings[d].append(Vector3i(coord.x, coord.y, step))
	for ring in rings:
		_wanted.append_array(ring)


## Checked before each piece of main-thread work, so a frame overruns its
## budget by one piece at most.
func _out_of_time() -> bool:
	return Time.get_ticks_usec() >= _deadline


func _launch() -> void:
	while _tasks.size() < _tuning.builds_in_flight and not _wanted.is_empty():
		var key: Vector3i = _wanted[0]
		# Ground is built only once the history that could touch it is laid.
		if not _world.shape.sites.ready(Rect2(Vector2(key.x, key.y) * _size, Vector2.ONE * _size)):
			return
		_wanted.pop_front()
		if _tasks.has(key):
			continue
		var held := _world.shape.sites.hold(Vector2i(key.x, key.y))
		var steps := PackedInt32Array()
		for each in held:
			steps.append(each.ground)
		_tasks[key] = WorkerThreadPool.add_task(_build.bind(key, RenderingServer.mesh_create(), held, steps))


func _build(key: Vector3i, mesh: RID, held: Array[Structure], steps: PackedInt32Array) -> void:
	var build := ChunkBuild.make(_world.shape, Vector2i(key.x, key.y), _size, key.z,
		_tuning.skirt_depth, _indices[key.z], held, steps)
	ChunkBuild.fill(mesh, build.arrays, _material_rid)
	build.mesh = mesh
	_mutex.lock()
	_results[key] = build
	_mutex.unlock()


func _collect() -> void:
	for key: Vector3i in _tasks.keys():
		if _out_of_time():
			return
		if not WorkerThreadPool.is_task_completed(_tasks[key]):
			continue
		WorkerThreadPool.wait_for_task_completion(_tasks[key])
		_tasks.erase(key)
		_mutex.lock()
		var build: ChunkBuild = _results.get(key)
		_results.erase(key)
		_mutex.unlock()
		if build:
			_upload(build)


func _upload(build: ChunkBuild) -> void:
	var chunk: TerrainChunk = _chunks.get(build.coord)
	if not TerrainResidency.keeps_ground(build.coord, _center, _tuning) or (chunk and chunk.step != 0 and chunk.step <= build.step):
		RenderingServer.free_rid(build.mesh)
		if chunk == null:
			_world.shape.sites.release(build.coord)
			_joined.erase(build.coord)
		return
	if chunk == null:
		chunk = TerrainChunk.new()
		chunk.coord = build.coord
		chunk.side = _size
		_chunks[build.coord] = chunk
		add_child(chunk)
		_place(chunk)
	chunk.show_build(build)
	if not chunk.structures().is_empty():
		_standing[chunk.coord] = chunk
	if not chunk.carved.is_empty():
		# A storm may have moved what stands in it while it was built.
		_behind[chunk.coord] = true
	if build.step == NEAR_STEP and TerrainResidency.needs_collision(build.coord, _center, _tuning) and not chunk.has_collision() \
			and not _to_ground.has(chunk):
		_to_ground.append(chunk)


## Collision a piece at a time, before anything else while the budget is
## fresh: a whole chunk's at once took up to 1.25 ms, and under load it was what
## most often took a frame past the hitch line.
func _ground() -> void:
	while not _to_ground.is_empty() and not _out_of_time():
		var chunk: TerrainChunk = _to_ground[0]
		if chunk.step != NEAR_STEP or chunk.has_collision() or not TerrainResidency.needs_collision(chunk.coord, _center, _tuning):
			_to_ground.pop_front()
		elif chunk.add_collision_piece(_size, _sand):
			_to_ground.pop_front()
			grounded.emit(chunk)


func _retire() -> void:
	while not _to_retire.is_empty() and not _out_of_time():
		var coord: Vector2i = _to_retire.pop_back()
		var chunk: TerrainChunk = _chunks.get(coord)
		if chunk == null:
			continue
		if not TerrainResidency.keeps_ground(coord, _center, _tuning):
			unloaded.emit(coord)
			_to_ground.erase(chunk)
			# Freed now, not queued, so the cost lands inside the budget.
			chunk.free()
			_chunks.erase(coord)
			_standing.erase(coord)
			_joined.erase(coord)
		elif not TerrainResidency.keeps_collision(coord, _center, _tuning):
			if chunk.has_collision():
				ungrounded.emit(chunk)
			_to_ground.erase(chunk)
			chunk.remove_collision()
		elif TerrainResidency.needs_collision(coord, _center, _tuning) and chunk.step == NEAR_STEP and not chunk.has_collision() \
				and not _to_ground.has(chunk):
			# Back in range after leaving it: the same samples, so the same ground.
			_to_ground.append(chunk)


# --- What a storm works on. ---

## Every structure standing on loaded ground follows the weather: those
## round you every frame, so they rise and sink smoothly before your eyes,
## the rest a few chunks a frame in turn. Its ground is pressed afresh when
## its step changes. Never burying you or your camp: the sand never comes back
## over a site's ground while either stands on it.
func _follow_sites() -> void:
	if _standing.is_empty():
		return
	var started := Time.get_ticks_usec()
	var t := _world.time
	for dz in range(-FOLLOW_NEAR, FOLLOW_NEAR + 1):
		for dx in range(-FOLLOW_NEAR, FOLLOW_NEAR + 1):
			var chunk: TerrainChunk = _standing.get(_center + Vector2i(dx, dz))
			if chunk != null:
				_follow_chunk(chunk, t)
	var coords := _standing.keys()
	for k in mini(FOLLOW_FAR, coords.size()):
		if _out_of_time():
			break
		_far_turn = (_far_turn + 1) % coords.size()
		var coord: Vector2i = coords[_far_turn]
		if _distance(coord) > FOLLOW_NEAR:
			_follow_chunk(_standing[coord], t)
	follow_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_follow_ms = maxf(slowest_follow_ms, follow_ms)


func _follow_chunk(chunk: TerrainChunk, t: float) -> void:
	var moved := 0
	for each in chunk.structures():
		var did := each.follow(t, _occupied)
		moved |= did
		if did & Structure.STEPPED:
			for coord: Vector2i in each.holders:
				_behind[coord] = true
	if moved and chunk.follow_structures():
		skyline.moved()
		if chunk.has_collision():
			_world.salvage.follow(chunk)


## Whether you or one of your camp's devices stands on a structure's ground:
## where you are read once a frame, and only when a structure asks.
func _occupied(structure: Structure) -> bool:
	var frame := Engine.get_process_frames()
	if frame != _occupants_frame:
		_occupants_frame = frame
		_occupants = PackedVector2Array([Vector2(_world.player_world_x(), _world.player_world_z())])
		for device in _world.devices():
			_occupants.append(Vector2(_world.world_x(device.global_position.x), _world.world_z(device.global_position.z)))
	for at in _occupants:
		if structure.reaches(at.x, at.y, 1.0):
			return true
	return false


## A structure laid over loaded ground (a dune's ruin): each chunk touching
## its ground holds it from now and is pressed afresh with it on a worker,
## the chunk its middle stands on drawing it once that's in.
func join(site: Structure) -> void:
	var lo := chunk_at(site.x - site.reach - 4.0, site.z - site.reach - 4.0)
	var hi := chunk_at(site.x + site.reach + 4.0, site.z + site.reach + 4.0)
	for j in range(lo.y, hi.y + 1):
		for i in range(lo.x, hi.x + 1):
			var coord := Vector2i(i, j)
			var building := _tasks.has(Vector3i(i, j, NEAR_STEP)) or _tasks.has(Vector3i(i, j, _tuning.mid_step))
			if not (_chunks.has(coord) or building) or not site.touches(Rect2(Vector2(coord) * _size, Vector2.ONE * _size).grow(4.0)):
				continue
			if site.holders.is_empty():
				site.hold_ground()
			site.holders[coord] = true
			var sites: Array = _joined.get(coord, [])
			sites.append(site)
			_joined[coord] = sites
			_behind[coord] = true


## A chunk takes in what joined it since its build or press was launched.
func _take_in(chunk: TerrainChunk) -> void:
	for site: Structure in _joined.get(chunk.coord, []):
		if not site in chunk.carved:
			chunk.carved.append(site)
			chunk.carved_steps.append(-1)


## Loaded ground behind what stands in it is pressed afresh on a worker,
## from the dunes it kept, or sampled again where it kept none.
func _press() -> void:
	for coord: Vector2i in _behind.keys():
		if _pressing.size() >= PRESSES or _out_of_time():
			return
		if _pressing.has(coord):
			continue
		var chunk: TerrainChunk = _chunks.get(coord)
		var fresh := _joined.has(coord)
		var building := _tasks.has(Vector3i(coord.x, coord.y, NEAR_STEP)) or _tasks.has(Vector3i(coord.x, coord.y, _tuning.mid_step))
		if fresh and (chunk == null or building):
			# Pressed once it's built: its build was launched before it joined.
			continue
		if chunk == null or (chunk.dunes.is_empty() and not fresh) or building:
			_behind.erase(coord)
			continue
		_behind.erase(coord)
		if fresh:
			_take_in(chunk)
			_joined.erase(coord)
		elif not chunk.behind(1 if chunk.step == NEAR_STEP else MID_BEHIND):
			continue
		var steps := PackedInt32Array()
		for k in chunk.carved.size():
			var each := chunk.carved[k]
			steps.append(each.ground if each.ground >= 0 else chunk.carved_steps[k])
		_pressing[coord] = [WorkerThreadPool.add_task(_press_one.bind(coord, chunk.dunes, chunk.step,
			chunk.carved.duplicate(), steps, RenderingServer.mesh_create())), chunk]


func _press_one(coord: Vector2i, dunes: PackedFloat32Array, step: int, carved: Array[Structure],
		steps: PackedInt32Array, mesh: RID) -> void:
	var started := Time.get_ticks_usec()
	var build := ChunkBuild.make(_world.shape, coord, _size, step, _tuning.skirt_depth, _indices[step], carved, steps) \
		if dunes.is_empty() else ChunkBuild.pressed(_world.shape, dunes, coord, _size, step, _tuning.skirt_depth, _indices[step], carved, steps)
	ChunkBuild.fill(mesh, build.arrays, _material_rid)
	build.mesh = mesh
	_mutex.lock()
	_pressed[coord] = build
	press_job_ms = (Time.get_ticks_usec() - started) / 1000.0
	_mutex.unlock()


func _collect_presses() -> void:
	for coord: Vector2i in _pressing.keys():
		if _out_of_time():
			return
		var task: Array = _pressing[coord]
		if not WorkerThreadPool.is_task_completed(task[0]):
			continue
		WorkerThreadPool.wait_for_task_completion(task[0])
		_pressing.erase(coord)
		_mutex.lock()
		var build: ChunkBuild = _pressed.get(coord)
		_pressed.erase(coord)
		_mutex.unlock()
		# Pressed from a chunk built afresh since, or at another step: nothing of it holds.
		var chunk: TerrainChunk = _chunks.get(coord)
		if chunk == null or chunk != task[1] or chunk.step != build.step:
			RenderingServer.free_rid(build.mesh)
			continue
		var started := Time.get_ticks_usec()
		var adopted := chunk.show_pressed(build)
		if not adopted.is_empty():
			_standing[coord] = chunk
			if chunk.has_collision():
				_world.salvage.adopt(chunk, adopted)
		presses += 1
		slowest_press_ms = maxf(slowest_press_ms, (Time.get_ticks_usec() - started) / 1000.0)
		# It may have moved on again meanwhile.
		_behind[coord] = true


## Nothing a storm works on is behind or being pressed.
func is_pressed() -> bool:
	return _behind.is_empty() and _pressing.is_empty()


func _update_far() -> void:
	if _far_task != -1:
		if _out_of_time() or not WorkerThreadPool.is_task_completed(_far_task):
			return
		WorkerThreadPool.wait_for_task_completion(_far_task)
		_far_task = -1
		_far.set_base(_far_next)
		if _far_mesh.is_valid():
			RenderingServer.free_rid(_far_mesh)
		_far_mesh = _far_next
		_far_next = RID()
		_far_center = _far_building
		_place_far()
	if not _far_mesh.is_valid() or _far_center != _center:
		_far_building = _center
		_far_next = RenderingServer.mesh_create()
		_far_task = WorkerThreadPool.add_task(_build_far.bind(_center, _far_next))


func _build_far(center: Vector2i, mesh: RID) -> void:
	ChunkBuild.fill(mesh, FarRing.make(_world.shape, center, _tuning), _material_rid)


func _sand_look() -> Material:
	if not _tuning.sand_shader:
		var flat := StandardMaterial3D.new()
		flat.albedo_color = _tuning.sand_color
		flat.roughness = 1.0
		return flat
	var sand := ShaderMaterial.new()
	sand.shader = SAND_SHADER
	sand.set_shader_parameter("downwind", Vector2.from_angle(WeatherField.mean_heading(_world.run_seed)))
	sand.set_shader_parameter("sand", _tuning.sand_color)
	return sand


func _place(chunk: TerrainChunk) -> void:
	chunk.position = Vector3((chunk.coord.x - _world.origin_chunk.x) * _size, 0.0,
		(chunk.coord.y - _world.origin_chunk.y) * _size)


func _place_far() -> void:
	_far.position = Vector3((_far_center.x - _world.origin_chunk.x) * _size, 0.0,
		(_far_center.y - _world.origin_chunk.y) * _size)
