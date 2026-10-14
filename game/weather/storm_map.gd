class_name StormMap
extends RefCounted
## The storm field as the GPU reads it: raw_storm_at sampled on a grid round
## the player at two moments a second apart, in the air's own frame (the world
## with the field's drift taken out). Storms ride the drift exactly, and only
## their slow change of shape is blended between the two. A worker samples;
## the main thread only uploads.

## Per texel: the raw field, then its slope east and south, per metre.
const CHANNELS := 4
## Below this slope, per metre, the field is too flat to say how far its edge is.
const SLOPE_FLOOR := 2.0e-5
## Signed distances are clamped here, metres.
const FAR := 40000.0

var size: int
var cell: float
## Air-frame metres of texel (0, 0)'s centre. 64-bit, so never stored in a Vector2.
var origin_x := 0.0
var origin_z := 0.0
## The two moments sampled.
var t0 := 0.0
var t1 := 1.0
var ready := false
var texture_a := ImageTexture.new()
var texture_b := ImageTexture.new()
## Slowest main-thread upload so far, ms.
var max_upload_ms := 0.0

var _world: World
var _field: WeatherField
var _a := PackedFloat32Array()
var _b := PackedFloat32Array()
var _task := -1
var _mutex := Mutex.new()
var _built: Array = []


func _init(world: World, field: WeatherField) -> void:
	_world = world
	_field = field
	size = world.tuning.storm_map_cells
	cell = 2.0 * world.tuning.storm_map_reach / size


## Keeps the map current for time t: a fresh pair once t is halfway through
## the current one, built on a worker. After a jump in time or place it builds
## at once, on this thread, so nothing ever reads a stale map.
func update(t: float, warp: float) -> void:
	_collect()
	var span := maxf(1.0, warp)
	var air := _air(_world.player_world_x(), _world.player_world_z(), t)
	var centre := Vector2(origin_x, origin_z) + Vector2.ONE * cell * (size - 1) * 0.5
	var strayed := absf(air.x - centre.x) > cell * size * 0.15 or absf(air.y - centre.y) > cell * size * 0.15
	if not ready or t < t0 - 0.001 or t > t1 + span * 2.0 or (strayed and _task == -1):
		if _task != -1:
			WorkerThreadPool.wait_for_task_completion(_task)
			_task = -1
		var at := _origin_for(air)
		_build(at.x, at.y, t, t + span)
		_collect()
	elif _task == -1 and t >= (t0 + t1) * 0.5:
		var at := _origin_for(air)
		_task = WorkerThreadPool.add_task(_build.bind(at.x, at.y, t, t + span))


## Lets a sampling worker finish, before the field it reads goes away.
func finish() -> void:
	if _task != -1:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


## The raw field as the GPU sees it at a world place and time.
func raw_at(x: float, z: float, t: float) -> float:
	return _sample(x, z, t)[0]


## Signed metres to the nearest front, positive inside a storm, and the unit
## normal pointing into it (x east, z south), as the GPU computes them.
func front_at(x: float, z: float, t: float) -> Vector3:
	var s := _sample(x, z, t)
	var slope := Vector2(s[1], s[2])
	var steep := slope.length()
	var normal := slope / steep if steep > 0.0 else Vector2.ZERO
	return Vector3(clampf(s[0] / maxf(steep, SLOPE_FLOOR), -FAR, FAR), normal.x, normal.y)


## Uniforms for the shaders, for the world's current origin and time.
func uniforms(t: float) -> Dictionary:
	var drift := _field.drift_at(t)
	# Engine metres + offset = world metres; world - drift = air.
	var air_x := _world.world_x(0.0) - drift.x
	var air_z := _world.world_z(0.0) - drift.y
	return {
		"storm_map_a": texture_a,
		"storm_map_b": texture_b,
		"storm_map_blend": _blend(t),
		"storm_map_shift": Vector2(air_x - origin_x + cell * 0.5, air_z - origin_z + cell * 0.5),
		"storm_map_extent": cell * size,
		"storm_map_cells": size,
		"storm_map_ready": 1.0 if ready else 0.0,
		"storm_air": Vector2(air_x, air_z),
	}


func _air(x: float, z: float, t: float) -> Vector2:
	var drift := _field.drift_at(t)
	return Vector2(x - drift.x, z - drift.y)


## Centred on a place, snapped to whole cells so samples land on the same spots.
func _origin_for(air: Vector2) -> Vector2:
	var half := cell * (size - 1) * 0.5
	return Vector2(floorf((air.x - half) / cell) * cell, floorf((air.y - half) / cell) * cell)


func _blend(t: float) -> float:
	return clampf((t - t0) / (t1 - t0), 0.0, 1.0) if t1 > t0 else 0.0


## Worker (or main thread after a jump): both moments, slopes by central
## differences on the grid itself, so the slopes agree with the samples.
func _build(ox: float, oz: float, ta: float, tb: float) -> void:
	var pair: Array = []
	for t: float in [ta, tb]:
		var drift := _field.drift_at(t)
		var raw := PackedFloat32Array()
		raw.resize(size * size)
		for j in size:
			for i in size:
				raw[j * size + i] = _field.raw_storm_at(ox + i * cell + drift.x, oz + j * cell + drift.y, t)
		var texels := PackedFloat32Array()
		texels.resize(size * size * CHANNELS)
		for j in size:
			var up := maxi(j - 1, 0)
			var down := mini(j + 1, size - 1)
			for i in size:
				var left := maxi(i - 1, 0)
				var right := mini(i + 1, size - 1)
				var k := j * size + i
				texels[k * CHANNELS] = raw[k]
				texels[k * CHANNELS + 1] = (raw[j * size + right] - raw[j * size + left]) / ((right - left) * cell)
				texels[k * CHANNELS + 2] = (raw[down * size + i] - raw[up * size + i]) / ((down - up) * cell)
		pair.append(texels)
	_mutex.lock()
	_built = [ox, oz, ta, tb, pair[0], pair[1]]
	_mutex.unlock()


## Takes a finished pair and uploads it, inside the main thread's budget.
func _collect() -> void:
	if _task != -1:
		if not WorkerThreadPool.is_task_completed(_task):
			return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	_mutex.lock()
	var built := _built
	_built = []
	_mutex.unlock()
	if built.is_empty():
		return
	var started := Time.get_ticks_usec()
	origin_x = built[0]
	origin_z = built[1]
	t0 = built[2]
	t1 = built[3]
	_a = built[4]
	_b = built[5]
	_upload(texture_a, _a)
	_upload(texture_b, _b)
	ready = true
	max_upload_ms = maxf(max_upload_ms, (Time.get_ticks_usec() - started) / 1000.0)


func _upload(texture: ImageTexture, texels: PackedFloat32Array) -> void:
	var image := Image.create_from_data(size, size, false, Image.FORMAT_RGBAF, texels.to_byte_array())
	if texture.get_width() == size:
		texture.update(image)
	else:
		texture.set_image(image)


## Bilinear on both moments and blended by time, exactly as the GPU filters:
## texel centres at whole cells, edges clamped.
func _sample(x: float, z: float, t: float) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0, 0.0, 0.0])
	if not ready:
		return out
	var air := _air(x, z, t)
	var fx := clampf((air.x - origin_x) / cell, 0.0, size - 1.0)
	var fz := clampf((air.y - origin_z) / cell, 0.0, size - 1.0)
	var i0 := mini(floori(fx), size - 2)
	var j0 := mini(floori(fz), size - 2)
	var u := fx - i0
	var v := fz - j0
	var w := _blend(t)
	for c in 3:
		var at := func(texels: PackedFloat32Array) -> float:
			var k := j0 * size + i0
			var top := lerpf(texels[k * CHANNELS + c], texels[(k + 1) * CHANNELS + c], u)
			var bottom := lerpf(texels[(k + size) * CHANNELS + c], texels[(k + size + 1) * CHANNELS + c], u)
			return lerpf(top, bottom, v)
		out[c] = lerpf(at.call(_a), at.call(_b), w)
	return out
