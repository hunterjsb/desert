class_name NavigationWitness
extends RefCounted
## A planned waypoint is evidence only when the live source and its real body agree.

static func read(world: World, expected: Dictionary) -> Dictionary:
	var result := {"matches": false, "actual": {}, "body": null, "held_fast": "", "exposure": NAN}
	var on_site: bool = expected.has("site")
	var coord: Vector2i = expected.get("coord", Vector2i(floori(expected.x / world.tuning.chunk_size), floori(expected.z / world.tuning.chunk_size)))
	var source: Variant = expected.site if on_site else coord
	if world.salvage.taken(source, expected.index):
		result.why = "already taken"
		return result
	if on_site:
		for site: Site in world.shape.sites.query(Rect2(expected.x - 120.0, expected.z - 120.0, 240.0, 240.0), false):
			if site.id != expected.site or not site is Structure:
				continue
			var wreck := world.salvage.wreckage_of(site)
			result.held_fast = wreck.held_fast(expected.index) if wreck != null else ""
			for spec: Dictionary in SiteLoot.plan(site, world.height_at):
				if spec.index == expected.index:
					result.actual = spec
			break
	else:
		result.exposure = world.salvage.exposure_in(coord)
		if not is_nan(result.exposure):
			for spec: Dictionary in Finds.plan(world.run_seed, coord, result.exposure, world.tuning, world.height_at, world.salvage.on_way, world.salvage.on_site):
				if spec.index == expected.index:
					result.actual = spec
	for body: RigidBody3D in world.salvage.finds():
		var identity: Array = body.get_meta(&"find", [])
		if identity.size() < 2 or identity[1] != expected.index:
			continue
		var same: bool = identity.size() >= 3 and identity[2] == expected.site if on_site else identity.size() == 2 and identity[0] == coord
		if same:
			result.body = body
			if result.held_fast == "":
				result.held_fast = world.salvage.held_fast(body)
			break
	var actual_id: StringName = result.actual.get("id", &"")
	result.matches = actual_id == expected.id and result.body != null \
		and result.body.get_meta(&"catalog", &"") == expected.id and result.held_fast == ""
	result.why = "" if result.matches else "live plan, streamed identity or tool gate disagrees"
	return result


## Ordinary finds already streamed nearby can supply a real replacement for a bad forecast.
static func observed(world: World, id: StringName, origin: Vector2, radius: float) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for body: RigidBody3D in world.salvage.finds():
		if body.get_meta(&"catalog", &"") != id:
			continue
		var identity: Array = body.get_meta(&"find", [])
		if identity.size() < 2:
			continue
		var at := Vector2(world.world_x(body.global_position.x), world.world_z(body.global_position.z))
		if origin.distance_to(at) > radius:
			continue
		var candidate := {"id": id, "coord": identity[0], "index": identity[1], "x": at.x, "z": at.y}
		if identity.size() >= 3:
			candidate.site = identity[2]
		if read(world, candidate).matches:
			found.append(candidate)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return origin.distance_squared_to(Vector2(a.x, a.z)) < origin.distance_squared_to(Vector2(b.x, b.z)))
	return found
