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

## Main-thread time streaming took this frame, and the most it has in any one:
## the hitch probe and F3 read them.
var frame_ms := 0.0
var slowest_frame_ms := 0.0

const SAND_SHADER := preload("res://game/world/sand.gdshader")

## The sand's look, chosen at setup; a look-test may set its own first.
var sand_material: Material
## The marks left on the sand, which it's drawn with.
var tracks: Tracks

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
## When this frame's budget runs out, in Time ticks (usec).
var _deadline := 0
var _far: GeometryInstance3D
var _far_mesh: RID
var _far_center := Vector2i.ZERO
var _far_building := Vector2i.ZERO
var _far_task := -1
var _far_next: RID


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	_size = _tuning.chunk_size
	if sand_material == null:
		sand_material = _sand_look()
	# Compiles the sand's shader now, while the world loads: otherwise the first
	# chunk to arrive stalls its frame on it (18 ms on an RTX 3070).
	_material_rid = sand_material.get_rid()
	# Squared: Jolt takes the geometric mean against a body's own 1.0.
	_sand.friction = _tuning.sand_friction * _tuning.sand_friction
	for step in [NEAR_STEP, _tuning.mid_step]:
		_indices[step] = ChunkBuild.indices_for(_size / step)
	_far = GeometryInstance3D.new()
	add_child(_far)
	tracks = Tracks.new()
	add_child(tracks)
	tracks.setup(world, sand_material)


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
	_launch()
	# Retiring first: uploads arrive nearly every frame in fast flight and
	# would starve it, leaving old ground loaded.
	_retire()
	_update_far()
	_collect()
	_world.salvage.stream(_deadline)
	_world.shape.sites.step(_deadline)
	frame_ms = (Time.get_ticks_usec() - started) / 1000.0
	slowest_frame_ms = maxf(slowest_frame_ms, frame_ms)
	Dev.put("terrain/chk", "%d" % _chunks.size())
	Dev.put("terrain/col", "%d" % collision_count())
	Dev.put("terrain/bld", "%d" % (_tasks.size() + _wanted.size()))
	Dev.put("terrain/upl", "%.1fms" % slowest_frame_ms)


func _exit_tree() -> void:
	# Workers hold this node; let them finish before it goes.
	for id: int in _tasks.values():
		WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()
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
			chunk.free()
			_chunks.erase(coord)
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


## Nothing left to build, near or far.
func is_idle() -> bool:
	return _planned and _tasks.is_empty() and _wanted.is_empty() and _far_task == -1 \
		and _far_mesh.is_valid() and _far_center == _center


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
	# The sand's patterns are drawn in world metres, not the engine's.
	if sand_material is ShaderMaterial:
		sand_material.set_shader_parameter("origin", Vector2(_world.origin_chunk) * _size)


func _distance(coord: Vector2i) -> int:
	return maxi(absi(coord.x - _center.x), absi(coord.y - _center.y))


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
			var step := NEAR_STEP if d <= _tuning.near_radius else _tuning.mid_step
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
		_tasks[key] = WorkerThreadPool.add_task(_build.bind(key, RenderingServer.mesh_create()))


func _build(key: Vector3i, mesh: RID) -> void:
	var build := ChunkBuild.make(_world.shape, Vector2i(key.x, key.y), _size, key.z,
		_tuning.skirt_depth, _indices[key.z])
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
	var d := _distance(build.coord)
	var chunk: TerrainChunk = _chunks.get(build.coord)
	if d > _tuning.view_radius + 1 or (chunk and chunk.step != 0 and chunk.step <= build.step):
		RenderingServer.free_rid(build.mesh)
		return
	if chunk == null:
		chunk = TerrainChunk.new()
		chunk.coord = build.coord
		chunk.side = _size
		_chunks[build.coord] = chunk
		add_child(chunk)
		_place(chunk)
	chunk.show_build(build)
	if build.step == NEAR_STEP and d <= _tuning.near_radius and not chunk.has_collision():
		chunk.add_collision(_size, _sand)
		grounded.emit(chunk)


func _retire() -> void:
	while not _to_retire.is_empty() and not _out_of_time():
		var coord: Vector2i = _to_retire.pop_back()
		var chunk: TerrainChunk = _chunks.get(coord)
		if chunk == null:
			continue
		var d := _distance(coord)
		if d > _tuning.view_radius + 1:
			unloaded.emit(coord)
			# Freed now, not queued, so the cost lands inside the budget.
			chunk.free()
			_chunks.erase(coord)
		elif d > _tuning.near_radius + 1:
			if chunk.has_collision():
				ungrounded.emit(chunk)
				chunk.remove_collision()
		elif d <= _tuning.near_radius and chunk.step == NEAR_STEP and not chunk.has_collision():
			# Back in range after leaving it: the same samples, so the same ground.
			chunk.add_collision(_size, _sand)
			grounded.emit(chunk)


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
