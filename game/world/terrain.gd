class_name Terrain
extends Node3D
## Streams square chunks around the player by grid position, never by what a
## raycast happens to hit. Workers compute the arrays; the main thread only
## uploads them, inside a time budget.

## Collision samples are 1 m apart, so near chunks are too: what you see is
## exactly what you stand on.
const NEAR_STEP := 1

## The slowest single chunk upload on the main thread so far, for the hitch probe.
var max_upload_ms := 0.0

var _world: World
var _tuning: Tuning
var _size: int
var _material: StandardMaterial3D
var _indices := {}
var _chunks := {}
var _tasks := {}
var _results := {}
var _mutex := Mutex.new()
var _center := Vector2i.ZERO
var _planned := false
var _wanted: Array[Vector3i] = []
var _far: MeshInstance3D
var _far_center := Vector2i.ZERO
var _far_building := Vector2i.ZERO
var _far_task := -1
var _far_arrays: Array = []


func setup(world: World) -> void:
	_world = world
	_tuning = world.tuning
	_size = _tuning.chunk_size
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.86, 0.72, 0.52)
	_material.roughness = 1.0
	for step in [NEAR_STEP, _tuning.mid_step]:
		_indices[step] = ChunkBuild.indices_for(_size / step)
	_far = MeshInstance3D.new()
	add_child(_far)


func _process(_delta: float) -> void:
	if _world == null:
		return
	var here := chunk_at(_world.player_world_x(), _world.player_world_z())
	if here != _center or not _planned:
		_center = here
		_planned = true
		_plan()
	_launch()
	_collect()
	_retire()
	_update_far()
	Dev.put("terrain/chunks", _chunks.size())
	Dev.put("terrain/with_collision", collision_count())
	Dev.put("terrain/building", _tasks.size() + _wanted.size())
	Dev.put("terrain/max_upload_ms", max_upload_ms)


func _exit_tree() -> void:
	# Workers hold this node; let them finish before it goes.
	for id: int in _tasks.values():
		WorkerThreadPool.wait_for_task_completion(id)
	_tasks.clear()
	if _far_task != -1:
		WorkerThreadPool.wait_for_task_completion(_far_task)
		_far_task = -1


func chunk_at(world_x: float, world_z: float) -> Vector2i:
	return Vector2i(floori(world_x / _size), floori(world_z / _size))


func has_collision_at(world_x: float, world_z: float) -> bool:
	var chunk: TerrainChunk = _chunks.get(chunk_at(world_x, world_z))
	return chunk != null and chunk.has_collision()


func is_loaded_at(world_x: float, world_z: float) -> bool:
	return _chunks.has(chunk_at(world_x, world_z))


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
		and _far.mesh != null and _far_center == _center


func chunks() -> Array:
	return _chunks.values()


func collision_count() -> int:
	var count := 0
	for chunk: TerrainChunk in _chunks.values():
		if chunk.has_collision():
			count += 1
	return count


## The world's origin moved; put every chunk back at its world position.
func reposition() -> void:
	for chunk: TerrainChunk in _chunks.values():
		_place(chunk)
	_place_far()


func _distance(coord: Vector2i) -> int:
	return maxi(absi(coord.x - _center.x), absi(coord.y - _center.y))


func _plan() -> void:
	_wanted.clear()
	var r := _tuning.view_radius
	var by_distance := []
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var coord := _center + Vector2i(dx, dz)
			var d := maxi(absi(dx), absi(dz))
			var step := NEAR_STEP if d <= _tuning.near_radius else _tuning.mid_step
			var chunk: TerrainChunk = _chunks.get(coord)
			if chunk and chunk.step != 0 and chunk.step <= step:
				continue
			by_distance.append([d, Vector3i(coord.x, coord.y, step)])
	by_distance.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in by_distance:
		_wanted.append(entry[1])


func _launch() -> void:
	while _tasks.size() < _tuning.builds_in_flight and not _wanted.is_empty():
		var key: Vector3i = _wanted.pop_front()
		if _tasks.has(key):
			continue
		_tasks[key] = WorkerThreadPool.add_task(_build.bind(key))


func _build(key: Vector3i) -> void:
	var build := ChunkBuild.make(_world.shape, Vector2i(key.x, key.y), _size, key.z,
		_tuning.skirt_depth, _indices[key.z])
	_mutex.lock()
	_results[key] = build
	_mutex.unlock()


func _collect() -> void:
	var started := Time.get_ticks_usec()
	for key: Vector3i in _tasks.keys():
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
		if (Time.get_ticks_usec() - started) / 1000.0 > _tuning.frame_upload_budget_ms:
			break


func _upload(build: ChunkBuild) -> void:
	var d := _distance(build.coord)
	if d > _tuning.view_radius + 1:
		return
	var chunk: TerrainChunk = _chunks.get(build.coord)
	if chunk and chunk.step != 0 and chunk.step <= build.step:
		return
	var started := Time.get_ticks_usec()
	if chunk == null:
		chunk = TerrainChunk.new()
		chunk.coord = build.coord
		_chunks[build.coord] = chunk
		add_child(chunk)
		_place(chunk)
	chunk.show_build(build, _material)
	if build.step == NEAR_STEP and d <= _tuning.near_radius and not chunk.has_collision():
		chunk.add_collision(_size)
	max_upload_ms = maxf(max_upload_ms, (Time.get_ticks_usec() - started) / 1000.0)


func _retire() -> void:
	for coord: Vector2i in _chunks.keys():
		var chunk: TerrainChunk = _chunks[coord]
		var d := _distance(coord)
		if d > _tuning.view_radius + 1:
			chunk.queue_free()
			_chunks.erase(coord)
		elif d > _tuning.near_radius + 1:
			if chunk.has_collision():
				chunk.remove_collision()
		elif d <= _tuning.near_radius and chunk.step == NEAR_STEP and not chunk.has_collision():
			# Back in range after leaving it: the same samples, so the same ground.
			chunk.add_collision(_size)


func _update_far() -> void:
	if _far_task != -1:
		if not WorkerThreadPool.is_task_completed(_far_task):
			return
		WorkerThreadPool.wait_for_task_completion(_far_task)
		_far_task = -1
		_mutex.lock()
		var arrays := _far_arrays
		_far_arrays = []
		_mutex.unlock()
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, _material)
		_far.mesh = mesh
		_far_center = _far_building
		_place_far()
	if _far.mesh == null or _far_center != _center:
		_far_building = _center
		_far_task = WorkerThreadPool.add_task(_build_far.bind(_center))


func _build_far(center: Vector2i) -> void:
	var arrays := FarRing.make(_world.shape, center, _tuning)
	_mutex.lock()
	_far_arrays = arrays
	_mutex.unlock()


func _place(chunk: TerrainChunk) -> void:
	chunk.position = Vector3((chunk.coord.x - _world.origin_chunk.x) * _size, 0.0,
		(chunk.coord.y - _world.origin_chunk.y) * _size)


func _place_far() -> void:
	_far.position = Vector3((_far_center.x - _world.origin_chunk.x) * _size, 0.0,
		(_far_center.y - _world.origin_chunk.y) * _size)
