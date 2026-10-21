class_name Landforms
extends RefCounted
## Fixed moon ground, projected like Sites. Immutable profiles are shared by
## terrain workers; a nearby mountain keeps its projection until left behind.

class Hill:
	var id: StringName
	var anchor: Sites.Anchor
	var at: Vector2
	var radius: float
	var height: float
	var base: float

	func rise(x: float, z: float) -> float:
		var off := Vector2(x - at.x, z - at.y)
		var d := off.length() / radius * (1.0 + 0.05 * (1.0 + cos(5.0 * atan2(off.y, off.x))))
		return (height + base) * (1.0 - smoothstep(0.08, 1.0, d)) - base

var hills: Array[Hill] = []
var _retired: Array[Hill] = []
var _profiles: Array[Hill] = []
var _lock := Mutex.new()
var revision := 0
var _history: History
var _tuning: Tuning

func _init(history: History, tuning: Tuning) -> void:
	_history = history
	_tuning = tuning

func follow(anchor: Sites.Anchor, jumped := false, loaded := Callable()) -> void:
	var kept: Array[Hill] = []
	for hill in _retired:
		if loaded.is_valid() and loaded.call(Rect2(hill.at - Vector2.ONE * hill.radius, Vector2.ONE * hill.radius * 2)):
			kept.append(hill)
	if jumped and loaded.is_valid():
		for hill in hills:
			if loaded.call(Rect2(hill.at - Vector2.ONE * hill.radius, Vector2.ONE * hill.radius * 2)):
				kept.append(hill)
	var next: Array[Hill] = []
	var changed := kept != _retired
	for id in [&"starcom", &"observatory"]:
		var old := get_hill(id)
		# The whole far ring and any in-flight chunk must be clear before moving it.
		if not jumped and old != null and old.at.distance_to(Vector2(anchor.x, anchor.z)) < old.radius + _tuning.far_radius + _tuning.history_lay_m:
			next.append(old)
		else:
			var proposed := _make(id, anchor)
			# Changing moon coordinates in place must not raise fresh ground through
			# bodies on an already loaded sheet. Travel uses fresh sheet coordinates.
			if old != null and loaded.is_valid() and loaded.call(Rect2(proposed.at - Vector2.ONE * proposed.radius, Vector2.ONE * proposed.radius * 2)):
				next.append(old)
				kept.erase(old)
			else:
				next.append(proposed)
				changed = true
	if changed:
		hills = next
		_retired = kept
		_lock.lock()
		_profiles = hills + _retired
		_lock.unlock()
		revision += 1

func get_hill(id: StringName) -> Hill:
	for hill in hills:
		if hill.id == id:
			return hill
	return null

func _make(id: StringName, anchor: Sites.Anchor) -> Hill:
	var hill := Hill.new()
	hill.id = id
	hill.base = _tuning.mountain_bedrock_depth
	hill.anchor = anchor
	for mark in _history.landmarks:
		if mark.id == id:
			hill.at = anchor.place(mark.p)
	hill.radius = _tuning.observatory_mountain.x if id == &"observatory" else _tuning.starcom_mountain.x
	hill.height = _tuning.observatory_mountain.y if id == &"observatory" else _tuning.starcom_mountain.y
	return hill

## Taking the reference is locked too: another thread may release the old
## array during a sheet change. The held immutable array then needs no lock.
func profiles() -> Array[Hill]:
	_lock.lock()
	var held := _profiles
	_lock.unlock()
	return held

func rise(x: float, z: float) -> float:
	return rise_from(profiles(), x, z)

static func rise_from(held: Array[Hill], x: float, z: float) -> float:
	var h := 0.0
	for hill in held:
		if absf(x - hill.at.x) < hill.radius and absf(z - hill.at.y) < hill.radius:
			h = maxf(h, hill.rise(x, z))
	return h


func ground(x: float, z: float, sand: float) -> float:
	return ground_from(profiles(), x, z, sand)

static func ground_from(held: Array[Hill], x: float, z: float, sand: float) -> float:
	for hill in held:
		if absf(x - hill.at.x) < hill.radius and absf(z - hill.at.y) < hill.radius:
			sand = maxf(sand, hill.rise(x, z))
	return sand

func memories() -> Array:
	var out := []
	for hill in profiles():
		var a := hill.anchor
		out.append([hill.id, a.x, a.z, Sphere.latitude(a.p), Sphere.longitude(a.p), a.facing, _retired.has(hill)])
	return out

func recall(records: Array) -> void:
	var next: Array[Hill] = []
	_retired = []
	for rec in records:
		var hill := _make(rec[0], Sites.Anchor.new(rec[1], rec[2], Sphere.point(rec[3], rec[4]), rec[5], _history.radius))
		if rec.size() > 6 and rec[6]:
			_retired.append(hill)
		else:
			next.append(hill)
	hills = next
	_lock.lock()
	_profiles = hills + _retired
	_lock.unlock()
	revision += 1

func pack(into: StreamPeerBuffer) -> void:
	for i in 2:
		var v := Vector4.ZERO
		if i < hills.size():
			var hill := hills[i]
			v = Vector4(hill.at.x, hill.at.y, hill.radius, hill.height)
		for f in [v.x, v.y, v.z, v.w]:
			into.put_float(f)

	for f in [_tuning.mountain_bedrock_depth, 0.0, 0.0, 0.0]:
		into.put_float(f)
