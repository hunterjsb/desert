class_name Finds
extends RefCounted
## What lies in the sand, as pure functions: how hard the weather has been at
## a place, a chunk's finds from the run's seed, the chunk's coordinates and
## that, and the bodies they're made of. Finds are the catalog's own parts and
## devices, so anything dug up fits your sockets.
##
## Two layers: the surface, of common things, and the deep layer, of better
## ones, which harder weather uncovers more often. Each find draws from its
## own stream of the seed, where it lies first, so the weather changes what a
## find is but never where it lies.

const SURFACE := &"surface"
const DEEP := &"deep"
## What each layer holds, as [catalog id, weight]: loose parts, and whole devices.
const PARTS := {
	SURFACE: [[&"battery", 4], [&"hook", 4], [&"lamp", 2], [&"canister", 2]],
	DEEP: [[&"big_battery", 3], [&"battery", 2], [&"hover_tray", 3], [&"solar_panel", 3], [&"hook", 1]],
}
const DEVICES := {
	SURFACE: [[&"crate_frame", 3], [&"charger", 2], [&"planter", 2], [&"stake", 2]],
	DEEP: [[&"crate_frame", 2], [&"turbine", 2], [&"condenser", 2], [&"shield", 2]],
}
## What a found device's sockets hold, by socket kind; a kind not listed is
## found empty.
const FILLS := {
	SURFACE: {&"battery": [&"battery"], &"ring": [&"hook"], &"top": [&"lamp"], &"water": [&"canister"]},
	DEEP: {&"battery": [&"big_battery", &"battery"], &"ring": [&"hook"], &"bottom": [&"hover_tray"],
		&"top": [&"solar_panel", &"lamp"], &"water": [&"canister"]},
}
## Per layer: the share of a device's sockets found filled, the range of a
## battery's charge and of a device's soundness, and how much of a buried
## find lies under the sand. Deep things were kept from the weather longer.
const LAYER := {
	SURFACE: {"fill": 0.35, "charge": Vector2(0.0, 0.4), "sound": Vector2(0.35, 0.75), "bury": Vector2(0.25, 0.5)},
	DEEP: {"fill": 0.6, "charge": Vector2(0.3, 1.0), "sound": Vector2(0.7, 1.0), "bury": Vector2(0.4, 0.65)},
}
## Of finds on open sand, this share are whole devices; of the parts, this
## share lie loose on top of the sand.
const DEVICE_SHARE := 0.35
const LOOSE_SHARE := 0.25
## A buried find always shows at least this share of itself, and this much, m.
const SHOWING_SHARE := 0.35
const SHOWING := 0.1
## Finds on open sand lie this far inside their chunk and this far apart, m,
## on sand no steeper than this, degrees.
const EDGE := 3.0
const APART := 4.0
const STEEPEST := 22.0
const TRIES := 8
## A buried find leans with the sand by this share, and up to this much
## more its own way, degrees.
const WITH_SLOPE := 0.6
const LEAN := 15.0
## Finds on a ruin's floor are numbered from here, and its hall's device has
## at least this many parts to strip.
const IN_RUIN := 100
const HALL_PARTS := 2
## A ruin's floor holds this many finds besides its hall's device, at least and at most.
const RUIN_FINDS := Vector2i(2, 4)
## Loose finds are set down this far above what they'll rest on, m.
const DROP := 0.03


## How hard the weather has been at a place, 0 to 1: over the last
## exposure_hours, the mean of the storm there or the wind past calm,
## whichever was harder. Read on fixed ticks of world time, so a chunk loaded
## any time within one tick reads the same.
static func exposure(field: WeatherField, x: float, z: float, t: float, tuning: Tuning) -> float:
	var step := tuning.exposure_step_minutes * 60.0
	var count := maxi(1, roundi(tuning.exposure_hours * 60.0 / tuning.exposure_step_minutes))
	var last := floorf(t / step) * step
	var calm := tuning.exposure_calm_wind
	var span := tuning.exposure_gale_wind - calm
	var sum := 0.0
	for k in count:
		var at := last - k * step
		var gale := clampf((field.wind_at(x, z, at).length() - calm) / span, 0.0, 1.0)
		sum += maxf(field.storm_at(x, z, at), gale)
	return sum / count


## The share of finds from the deep layer at an exposure.
static func deep_share(exposed: float, tuning: Tuning) -> float:
	return lerpf(tuning.deep_calm, tuning.deep_storm, exposed)


## 1 for the surface layer, 2 for the deep.
static func tier(spec: Dictionary) -> int:
	return 2 if spec.layer == DEEP else 1


## A chunk's finds, on its open sand and on the floor of its ruin if it has
## one. `height` is the ground's one function, (x, z) -> m.
static func plan(run_seed: int, coord: Vector2i, exposed: float, tuning: Tuning, height: Callable,
		ruin: Ruin) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var deep := deep_share(exposed, tuning)
	var count := 0
	var roll := _stream(run_seed, coord, -1)
	for i in tuning.finds_most:
		if roll.randf() < tuning.finds_per_chunk / tuning.finds_most:
			count += 1
	for i in count:
		var rng := _stream(run_seed, coord, i)
		var at := _open_spot(rng, coord, tuning.chunk_size, height, ruin, found)
		if not at.is_finite():
			continue
		var spec := _lying(rng, at, deep)
		spec.index = i
		spec.loose = not spec.device and rng.randf() < LOOSE_SHARE
		var bury := rng.randf()
		_fill(spec, rng)
		var depths: Vector2 = LAYER[spec.layer].bury
		spec.bury = 0.0 if spec.loose else lerpf(depths.x, depths.y, bury)
		found.append(spec)
	if ruin != null:
		var rng := _stream(run_seed, coord, IN_RUIN)
		var spots := range(1, Ruin.SPOTS.size())
		_shuffle(spots, rng)
		var take := rng.randi_range(RUIN_FINDS.x, RUIN_FINDS.y)
		for k in [0] + spots.slice(0, take):
			var each := _stream(run_seed, coord, IN_RUIN + 1 + k)
			var spec := _lying(each, ruin.to_world(Ruin.SPOTS[k]), deep, k == 0)
			spec.index = IN_RUIN + k
			spec.loose = true
			spec.bury = 0.0
			spec.floor = ruin.floor_y
			_fill(spec, each, HALL_PARTS if k == 0 else 0)
			found.append(spec)
	return found


## Where a find lies and which way, then its layer and whether it's a
## device: the draws the weather can't change come first.
static func _lying(rng: RandomNumberGenerator, at: Vector2, deep: float, device := false) -> Dictionary:
	var spec := {"x": at.x, "z": at.y, "yaw": rng.randf() * TAU, "lean": rng.randf() * TAU,
		"lean_by": deg_to_rad(rng.randf() * LEAN)}
	spec.layer = DEEP if rng.randf() < deep else SURFACE
	spec.device = rng.randf() < DEVICE_SHARE or device
	return spec


## What it is, and for a device what it was found with.
static func _fill(spec: Dictionary, rng: RandomNumberGenerator, least := 0) -> void:
	var layer: StringName = spec.layer
	var kind: Dictionary = LAYER[layer]
	spec.id = _pick(rng, DEVICES[layer] if spec.device else PARTS[layer])
	spec.fill = []
	spec.charge = rng.randf_range(kind.charge.x, kind.charge.y)
	spec.sound = rng.randf_range(kind.sound.x, kind.sound.y)
	if not spec.device:
		return
	if least > 0 and spec.id == &"stake":
		spec.id = &"crate_frame"
	if spec.id == &"stake":
		return
	var fills: Dictionary = FILLS[layer]
	var sockets: Array = Catalog.DEVICES[spec.id].sockets
	var open: Array[int] = []
	for i in sockets.size():
		if not fills.has(sockets[i][0]):
			continue
		if rng.randf() < kind.fill:
			spec.fill.append([i, _any(rng, fills[sockets[i][0]]), rng.randf_range(kind.charge.x, kind.charge.y)])
		else:
			open.append(i)
	while spec.fill.size() < least and not open.is_empty():
		var i: int = open.pop_front()
		spec.fill.append([i, _any(rng, fills[sockets[i][0]]), rng.randf_range(kind.charge.x, kind.charge.y)])


## Somewhere on the chunk's open sand, clear of its ruin and of the finds
## before it, not too steep; not finite if nowhere turned up.
static func _open_spot(rng: RandomNumberGenerator, coord: Vector2i, size: int, height: Callable, ruin: Ruin,
		found: Array[Dictionary]) -> Vector2:
	var steepest := tan(deg_to_rad(STEEPEST))
	for k in TRIES:
		var at := Vector2(coord.x * size + rng.randf_range(EDGE, size - EDGE),
			coord.y * size + rng.randf_range(EDGE, size - EDGE))
		if ruin != null and ruin.reaches(at.x, at.y, 2.0):
			continue
		if found.any(func(f: Dictionary) -> bool: return at.distance_to(Vector2(f.x, f.z)) < APART):
			continue
		if _grade(height, at.x, at.y).length() > steepest:
			continue
		return at
	return Vector2(INF, INF)


## The sand's rise per metre at a place, along x and z.
static func _grade(height: Callable, x: float, z: float) -> Vector2:
	return Vector2(height.call(x + 0.5, z) - height.call(x - 0.5, z), height.call(x, z + 0.5) - height.call(x, z - 0.5))


## The body a find is made of: dark, since nothing found runs until it's
## yours, with the parts it was found with fitted.
static func make(spec: Dictionary) -> RigidBody3D:
	var layer: StringName = spec.layer
	if not spec.device:
		return _part(spec.id, spec.charge, layer)
	var device := Catalog.stake() if spec.id == &"stake" else Catalog.device(spec.id)
	# Fitted before it's in the world, so before its _ready would set this.
	device.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	var sockets := device.sockets()
	for entry: Array in spec.fill:
		device.fit(_part(entry[1], entry[2], layer), sockets[entry[0]])
	device.set_powered(false)
	if device.charge_light != null:
		var cell := device.battery()
		ChargeLight.paint(device.charge_light, cell.charge_wh / cell.capacity() if cell != null else 0.0)
	device.set_meta(&"layer", layer)
	return device


## A found device wears its years in the weather, a deep one fewer. Once it's
## in the world, where it knows its look.
static func age(device: Device, sound: float) -> void:
	var tough: float = device.frame_stats.get("toughness", 1.0)
	if tough < INF:
		device.wear((1.0 - sound) * tough)


static func _part(id: StringName, charge: float, layer: StringName) -> Part:
	var part := Catalog.part(id)
	if part is Battery:
		part.charge_wh = part.capacity() * charge
		part.show_charge()
	elif part is Supply:
		# Found empty: where water comes from is Survival's question.
		(part as Supply).drain(INF)
	part.set_meta(&"layer", layer)
	return part


## Where a find lies, world metres. Buried, a part stands on end and anything
## leans with the sand and a little more, its lowest point under the sand at
## its middle by its share of its height. Loose, it rests a few centimetres
## above what's under it, a part on its socket side, to settle.
static func pose(body: RigidBody3D, spec: Dictionary, height: Callable) -> Transform3D:
	var box := bounds(body)
	var turn: Basis
	if spec.bury > 0.0:
		var slope := _grade(height, spec.x, spec.z)
		var up := Vector3.UP.slerp(Vector3(-slope.x, 1.0, -slope.y).normalized(), WITH_SLOPE)
		up = up.rotated(Vector3(cos(spec.lean), 0.0, sin(spec.lean)), spec.lean_by)
		turn = _up_to(up) * Basis(Vector3.UP, spec.yaw) * (Basis.IDENTITY if spec.device else _on_end(box))
	else:
		turn = Basis(Vector3.UP, spec.yaw) * (Basis.IDENTITY if spec.device else Basis(Vector3.RIGHT, -PI / 2.0))
	var low := INF
	var high := -INF
	var under := -INF
	for i in 8:
		var corner := turn * box.get_endpoint(i)
		low = minf(low, corner.y)
		high = maxf(high, corner.y)
	var middle := turn * box.get_center()
	var y: float
	if spec.bury > 0.0:
		y = height.call(spec.x, spec.z) - depth(spec, high - low) - low
	else:
		if spec.has("floor"):
			under = spec.floor
		else:
			for i in 8:
				var corner := turn * box.get_endpoint(i) - middle
				under = maxf(under, height.call(spec.x + corner.x, spec.z + corner.z))
		y = under + DROP - low
	return Transform3D(turn, Vector3(spec.x - middle.x, y, spec.z - middle.z))


## How far a buried find's lowest point lies under the sand, m, for its
## height once turned: never so deep it's out of reach.
static func depth(spec: Dictionary, tall: float) -> float:
	return tall * minf(spec.bury, 1.0 - maxf(SHOWING_SHARE, SHOWING / maxf(tall, 1e-6)))


## A body's bounds in its own frame: every shape it's made of, fitted parts too.
static func bounds(body: Node) -> AABB:
	var box := AABB()
	var first := true
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null:
			var each := shape.transform * shape.shape.get_debug_mesh().get_aabb()
			box = each if first else box.merge(each)
			first = false
	return box


## Stood on end: the part's longest side up.
static func _on_end(box: AABB) -> Basis:
	var s := box.size
	if s.z >= s.x and s.z >= s.y:
		return Basis(Vector3.RIGHT, -PI / 2.0)
	if s.x >= s.y:
		return Basis(Vector3.BACK, PI / 2.0)
	return Basis.IDENTITY


## The turn that brings straight up to `up`.
static func _up_to(up: Vector3) -> Basis:
	var axis := Vector3.UP.cross(up)
	if axis.length() < 1e-6:
		return Basis.IDENTITY
	return Basis(axis.normalized(), Vector3.UP.angle_to(up))


static func _stream(run_seed: int, coord: Vector2i, i: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, coord.x, coord.y, i])
	return rng


static func _pick(rng: RandomNumberGenerator, table: Array) -> StringName:
	var total := 0.0
	for entry: Array in table:
		total += entry[1]
	var at := rng.randf() * total
	for entry: Array in table:
		at -= entry[1]
		if at < 0.0:
			return entry[0]
	return table[-1][0]


static func _any(rng: RandomNumberGenerator, ids: Array) -> StringName:
	return ids[rng.randi() % ids.size()]


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap
