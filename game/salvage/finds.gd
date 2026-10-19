class_name Finds
extends RefCounted
## What lies in the sand, as pure functions: how hard the weather has been at
## a place, a chunk's loose finds from the run's seed, the chunk's
## coordinates and that, and the bodies every find is made of. Finds are the
## catalog's own parts and devices, so anything dug up fits your sockets.
## Most loot is history's, in its sites (SiteLoot); loose finds lie only on
## the way, along paths and among a settlement's sites, a few a kilometre.
##
## Two layers: the surface, of common things, and the deep layer, of better
## ones, which harder weather uncovers more often. Each find draws from its
## own stream of the seed, where it lies first, so the weather changes what a
## find is but never where it lies.

const SURFACE := &"surface"
const DEEP := &"deep"
## What each layer holds, as [catalog id, weight]: loose parts, and whole
## devices. Rope and wire are common, hose a little less and a compass
## uncommon; a harvester is a rare, better part. A sand yacht's pieces, the
## runners, a sail and a mast, lie deep.
const PARTS := {
	SURFACE: [
		[&"battery", 4],
		[&"hook", 4],
		[&"lamp", 2],
		[&"canister", 2],
		[&"coil", 3],
		[&"plug", 3],
		[&"hose_end", 2],
		[&"compass", 1],
		[&"frame", 1],
		[&"fabric", 1],
	],
	DEEP: [
		[&"big_battery", 3],
		[&"battery", 2],
		[&"hover_tray", 3],
		[&"solar_panel", 3],
		[&"hook", 1],
		[&"strong_plug", 2],
		[&"harvester", 1],
		[&"sail", 2],
		[&"skates", 2],
		[&"board_plate", 2],
		[&"frame", 2],
	],
}
const DEVICES := {
	SURFACE: [
		[&"chassis", 4],
		[&"light_panel", 2],
		[&"planter", 2],
		[&"stake", 2],
		[&"survival_kit", 1],
		[&"radio", 2],
		[&"bedroll", 1],
		# What a company surveyor before you dropped: its own issue.
		[&"power_box", 1],
	],
	DEEP: [
		[&"chassis", 3],
		[&"turbine", 2],
		[&"condenser", 2],
		[&"shield", 2],
		[&"board", 1],
		[&"console", 1],
		[&"mast", 1],
	],
}
## What a survival kit holds, by socket kind, and the share of its slots
## found filled: it was packed to be found. Seeds keep only out of the
## weather, so a kit lying on open sand has mostly lost them.
const SURVIVAL_KIT := {&"water": [&"canister"], &"food": [&"ration"], &"plant_standard": [&"root_tuber"],
	&"plant_pot": [&"vat_fungus"]}
const KIT_FILL := 0.75
const KIT_SEEDS_IN_THE_OPEN := 0.1
## What a found device's sockets hold, by socket kind, and a found chassis's
## spots, by the fills each names (top, battery, bottom); a kind not listed
## is found empty. A Console is a deep find, and its screen and instruments
## come only in one. A power box's bays hold the cells it was built for, so
## the heaviest box found still drags by hand.
const FILLS := {
	SURFACE: {&"battery": [&"battery"], &"bay": [&"battery"], &"ring": [&"hook"], &"top": [&"lamp"],
		&"water": [&"canister"]},
	DEEP: {&"battery": [&"big_battery", &"battery"], &"bay": [&"battery"], &"ring": [&"hook"], &"bottom": [&"hover_tray"],
		&"top": [&"solar_panel", &"lamp"], &"water": [&"canister"], &"screen": [&"screen"],
		&"computer_mod": [&"anemometer", &"barometer", &"hygrometer", &"particle_sensor"], &"computer_top": [&"radar"],
		&"sail": [&"sail"]},
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
## A house ruin's hall holds a device with at least this many parts to strip.
const HALL_PARTS := 2
## Loose finds are set down this far above what they'll rest on, m.
const DROP := 0.03
## Whether a ruin has a beacon left running draws from its loot seed's stream here.
const BEACON := 200


## How hard the weather has been at a place, 0 to 1: over the last
## exposure_hours, the mean of how deep into a storm it was or how far the
## wind blew past the prevailing wind's strongest, whichever was harder. Read
## on fixed ticks of world time, so a chunk loaded any time within one tick
## reads the same.
static func exposure(field: WeatherField, x: float, z: float, t: float, tuning: Tuning) -> float:
	var step := tuning.exposure_step_minutes * 60.0
	var count := maxi(1, roundi(tuning.exposure_hours * 60.0 / tuning.exposure_step_minutes))
	var last := floorf(t / step) * step
	var sum := 0.0
	for k in count:
		sum += Exposure.reading(field, x, z, last - k * step, tuning)
	return sum / count


## The share of finds from the deep layer at an exposure.
static func deep_share(exposed: float, tuning: Tuning) -> float:
	return lerpf(tuning.deep_calm, tuning.deep_storm, exposed)


## 1 for the surface layer, 2 for the deep; a site's find, 2 for its era's best.
static func tier(spec: Dictionary) -> int:
	return spec.get("tier", 2 if spec.layer == DEEP else 1)


## A chunk's loose finds, on its open sand. `height` is the ground's one
## function, (x, z) -> m; `on_way(x, z)` says a place is on the way (on_way()),
## where alone they lie; `on_site(x, z)` says a place is a structure's
## ground, which they keep clear of.
static func plan(run_seed: int, coord: Vector2i, exposed: float, tuning: Tuning, height: Callable,
		on_way: Callable, on_site := Callable()) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var deep := deep_share(exposed, tuning)
	var count := 0
	var roll := _stream(run_seed, coord, -1)
	for i in tuning.finds_most:
		if roll.randf() < tuning.finds_per_chunk / tuning.finds_most:
			count += 1
	for i in count:
		var rng := _stream(run_seed, coord, i)
		var at := _open_spot(rng, coord, tuning.chunk_size, height, found, on_way, on_site)
		if not at.is_finite():
			continue
		var spec := _lying(rng, at, deep)
		spec.index = i
		spec.loose = not spec.device and rng.randf() < LOOSE_SHARE
		var bury := rng.randf()
		_fill(spec, rng)
		# Too short to stand in the sand and still show enough, like a plug.
		if not spec.device and _longest(spec.id) <= SHOWING:
			spec.loose = true
		var depths: Vector2 = LAYER[spec.layer].bury
		spec.bury = 0.0 if spec.loose else lerpf(depths.x, depths.y, bury)
		found.append(spec)
	return found


## Whether a world place is on the way: within a laid path's corridor, or
## `scatter` m of a settlement's site, built or only planned. What travellers
## dropped lies there, and nowhere else on open sand.
static func on_way(sites: Sites, x: float, z: float, scatter: float) -> bool:
	var at := Vector2(x, z)
	var corridor := PathNetwork.CORRIDOR
	for piece in sites.paths_in(Rect2(x - corridor, z - corridor, corridor * 2.0, corridor * 2.0)):
		for k in piece.points.size() - 1:
			if Geometry2D.get_closest_point_to_segment(at, piece.points[k], piece.points[k + 1]).distance_to(at) <= corridor:
				return true
	for site in sites.query(Rect2(x - scatter, z - scatter, scatter * 2.0, scatter * 2.0)):
		if History.MEMBERS.has(site.source) and site.distance_to(x, z) <= scatter:
			return true
	return false


## What the nearest beacon within reach of a world place points at: the
## device in a house ruin's hall, which every one holds whatever the weather,
## in one of the ruins the seed left a beacon running in, passing over any
## whose hall `taken(site id, socket)` says is yours already; picked through
## the site index. {x, z, coord, index, site} in world metres, or {} if none
## is in reach.
static func beacon(_run_seed: int, sites: Sites, x: float, z: float, tuning: Tuning, taken: Callable) -> Dictionary:
	var size := float(tuning.chunk_size)
	var ruin := sites.nearest(x, z, tuning.radio_reach_m, func(site: Site) -> bool:
		return site is Ruin and SiteLoot._stream(site.loot, BEACON).randf() < tuning.beacon_share \
			and not taken.call(site.id, 0)) as Ruin
	if ruin == null:
		return {}
	var at := ruin.to_world(Ruin.SPOTS[0])
	return {"x": at.x, "z": at.y, "coord": Vector2i(floori(ruin.center.x / size), floori(ruin.center.y / size)),
		"index": 0, "site": ruin.id}


## Where a find lies and which way, then its layer and whether it's a
## device: the draws the weather can't change come first.
static func _lying(rng: RandomNumberGenerator, at: Vector2, deep: float) -> Dictionary:
	var spec := {"x": at.x, "z": at.y, "yaw": rng.randf() * TAU, "lean": rng.randf() * TAU,
		"lean_by": deg_to_rad(rng.randf() * LEAN)}
	spec.layer = DEEP if rng.randf() < deep else SURFACE
	spec.device = rng.randf() < DEVICE_SHARE
	return spec


## What it is, and for a device what it was found with.
static func _fill(spec: Dictionary, rng: RandomNumberGenerator) -> void:
	var layer: StringName = spec.layer
	var kind: Dictionary = LAYER[layer]
	spec.id = _pick(rng, DEVICES[layer] if spec.device else PARTS[layer])
	spec.fill = []
	spec.charge = rng.randf_range(kind.charge.x, kind.charge.y)
	spec.sound = rng.randf_range(kind.sound.x, kind.sound.y)
	if not spec.device or spec.id == &"stake":
		return
	var packed: bool = spec.id == &"survival_kit"
	var fills: Dictionary = SURVIVAL_KIT if packed else FILLS[layer]
	var holds := holds(spec.id)
	for i in holds.size():
		if not fills.has(holds[i]):
			continue
		var share: float = kind.fill
		if packed:
			share = KIT_SEEDS_IN_THE_OPEN if holds[i] in [&"plant_pot", &"plant_standard", &"plant_deep"] else KIT_FILL
		if rng.randf() < share:
			spec.fill.append([i, _any(rng, fills[holds[i]]), rng.randf_range(kind.charge.x, kind.charge.y)])


## What a found device can hold, in order, each by the fills it draws from:
## its sockets by kind, then a chassis's spots.
static func holds(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var spec: Dictionary = Catalog.DEVICES[id]
	for socket: Array in spec.sockets:
		out.append(socket[3].get("fills", socket[0]) if socket.size() > 3 else socket[0])
	for spot: Array in spec.get("spots", []):
		out.append(spot[3])
	return out


## Somewhere on the chunk's open sand on the way, clear of structures and of
## the finds before it, not too steep; not finite if nowhere turned up.
static func _open_spot(rng: RandomNumberGenerator, coord: Vector2i, size: int, height: Callable,
		found: Array[Dictionary], on_way: Callable, on_site: Callable) -> Vector2:
	var steepest := tan(deg_to_rad(STEEPEST))
	for k in TRIES:
		var at := Vector2(coord.x * size + rng.randf_range(EDGE, size - EDGE),
			coord.y * size + rng.randf_range(EDGE, size - EDGE))
		if (on_site.is_valid() and on_site.call(at.x, at.y)) or not on_way.call(at.x, at.y):
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


## The body a find is made of, with the parts it was found with fitted, dark.
static func make(spec: Dictionary) -> RigidBody3D:
	var body := bare(spec)
	for k in spec.fill.size():
		fit(body as Device, spec, k)
	dark(body)
	return body


## A find's body before its parts: a part whole, or a device's bare frame.
## Making one is split this way so no piece of the streaming budget is long.
## A site's find is given the hands it passed through from its own seed, by
## its site's era and kind, before it's in the world.
static func bare(spec: Dictionary) -> RigidBody3D:
	var body: RigidBody3D
	if spec.has("rig"):
		# A rig kept whole: its deck and all that's on it, one find.
		body = Rig.build(null, spec.rig, spec.charge).deck
	elif not spec.device:
		body = _part(spec.id, spec.charge, spec.layer, spec.get("sealed", false))
	else:
		body = Catalog.stake() if spec.id == &"stake" else Catalog.device(spec.id)
		# Fitted before it's in the world, so before its _ready would set this.
		body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		mark(body, spec.layer)
	if spec.has("era"):
		Catalog.found_in(body, spec.era, spec.kind, spec.seed)
	return body


## A find's layer, which its paint shows: older is better. A part has no
## soundness of its own yet, so it looks the middle of its layer's.
static func mark(body: Node, layer: StringName) -> void:
	body.set_meta(&"layer", layer)
	if body is Device:
		(body as Device).show_wear()
		return
	var sound: Vector2 = LAYER[layer].sound if LAYER.has(layer) else Vector2.ONE
	Paint.show_age(body, Paint.age_of(layer, (sound.x + sound.y) * 0.5))


## Fits the k-th part a device was found with; a site's part has hands of
## its own, from its own seed.
static func fit(device: Device, spec: Dictionary, k: int) -> void:
	var entry: Array = spec.fill[k]
	var part := _part(entry[1], entry[2], spec.layer, spec.id == &"survival_kit" or spec.get("sealed", false))
	if spec.has("era"):
		Catalog.found_in(part, spec.era, spec.kind, hash([spec.seed, k]))
	var slots: Array = Catalog.DEVICES[spec.id].sockets
	if entry[0] < slots.size():
		device.fit(part, device.frame_sockets()[entry[0]])
		return
	var spot: Array = Catalog.DEVICES[spec.id].spots[entry[0] - slots.size()]
	Stick.put(device as Chassis, device as Chassis, spot[0], spot[1], deg_to_rad(spot[2]), part)


## Nothing found runs until it's yours; its light still shows what it holds.
static func dark(body: RigidBody3D) -> void:
	var device := body as Device
	if device == null:
		return
	device.set_powered(false)
	if device.charge_light != null:
		ChargeLight.paint(device.charge_light, device.charge_share())


## A found device wears its years in the weather, a deep one fewer. Once it's
## in the world, where it knows its look.
static func age(device: Device, sound: float) -> void:
	var tough: float = device.frame_stats.get("toughness", 1.0)
	if tough < INF:
		device.wear((1.0 - sound) * tough)


static func _part(id: StringName, charge: float, layer: StringName, sealed := false) -> Part:
	var part := Catalog.part(id)
	if part is Battery:
		part.charge_wh = part.capacity() * charge
		part.show_charge()
	elif part is Supply and part.kind == &"water" and not sealed:
		# Open water boils off: only a kit's canister is found sealed and full.
		(part as Supply).drain(INF)
	mark(part, layer)
	if id in [&"coil", &"plug", &"strong_plug", Hose.END]:
		part.set_meta(&"rolled", id)
	return part


## Found rope, wire and hose lie as one body until they're yours, and stowed
## they go back to one: a coil, and a cable's or a hose's first end with the
## rest of it behind. Then a coil becomes a line to lay, as long as the one
## stowed, and an end pulls the rest up out of the sand.
static func unroll(world: World, body: Node) -> void:
	if not body.has_meta(&"rolled"):
		return
	var id: StringName = body.get_meta(&"rolled")
	var metres: float = body.get_meta(&"rolled_m", world.tuning.rope_coil_length)
	body.remove_meta(&"rolled")
	body.remove_meta(&"rolled_m")
	if id == &"coil":
		Line.make(world, metres, body as Part)
	elif id == Hose.END:
		Catalog.hose(world, (body as Part).global_position, body as Part)
	else:
		Catalog.cable(world, (body as Part).global_position, id == &"strong_plug", body as Part)


## Where a find lies, world metres. Buried, a part, a board or a chassis
## piece stands on end and anything leans with the sand and a little more,
## its lowest point under the sand at its middle by its share of its height.
## Loose, it rests a few centimetres above what's under it, a part on its
## socket side, to settle.
static func pose(body: RigidBody3D, spec: Dictionary, height: Callable) -> Transform3D:
	var box := bounds(body)
	var turn: Basis
	if spec.bury > 0.0:
		var slope := _grade(height, spec.x, spec.z)
		var up := Vector3.UP.slerp(Vector3(-slope.x, 1.0, -slope.y).normalized(), WITH_SLOPE)
		up = up.rotated(Vector3(cos(spec.lean), 0.0, sin(spec.lean)), spec.lean_by)
		var on_end: bool = not spec.device or Catalog.DEVICES.get(spec.id, {}).get("on_end", false)
		turn = _up_to(up) * Basis(Vector3.UP, spec.yaw) * (_on_end(box) if on_end else Basis.IDENTITY)
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
		y = under + spec.get("drop", DROP) - low
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
			var each := shape.transform * Catalog.bounds(shape.shape)
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


static func _longest(id: StringName) -> float:
	var size: Vector3 = Catalog.PARTS[id].size
	return maxf(size.x, maxf(size.y, size.z))


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
