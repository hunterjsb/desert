class_name SalvageProbe
extends HandsProbe
## For salvage probes: the world with its ruins and finds, your hands to take
## them with, and waits until what lies on the ground is laid out and settled.

var salvage: Salvage


func load_salvage(run_seed := 1234) -> void:
	start_among(run_seed)
	# What lies in ruins is these probes' to test, so the wind has dug them out;
	# exposure has its own (probes/kits).
	Tuning.current().site_return_m = -1.0
	await load_hands(run_seed, true)
	salvage = world.salvage
	await settle_finds()


## Waits until the ground round you is solid and every find on it laid out
## and settled.
func settle_finds(max_frames := 1500) -> void:
	await settle(true)
	for i in max_frames:
		await get_tree().process_frame
		if salvage.is_idle() and world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			return
	check(false, "finds laid out and settled within %d frames" % max_frames)


## Goes to a world place and waits for what lies there.
func go(x: float, z: float) -> void:
	teleport(x, z)
	await settle_finds()


## A body's eight corners, engine coordinates.
func corners(body: Node3D) -> Array[Vector3]:
	var box := Finds.bounds(body)
	var out: Array[Vector3] = []
	for i in 8:
		out.append(body.global_transform * box.get_endpoint(i))
	return out


## The plan a laid-out find came from.
func spec_of(body: Node) -> Dictionary:
	var at: Array = body.get_meta(&"find")
	var chunk := world.terrain.chunk_under((at[0].x + 0.5) * world.tuning.chunk_size, (at[0].y + 0.5) * world.tuning.chunk_size)
	for spec in Finds.plan(world.run_seed, at[0], salvage.exposure_in(at[0]), world.tuning, world.height_at,
			chunk.ruin() if chunk != null else null, salvage.on_site):
		if spec.index == at[1]:
			return spec
	return {}


## The house ruins standing within `radius` m of where the run began,
## nearest first.
func ruins_near(radius := 2000.0) -> Array[Ruin]:
	var found: Array[Ruin] = []
	for unit in world.shape.sites.units():
		for site in unit.sites:
			if site is Ruin and world.shape.sites.covering(site.x, site.z) == site \
					and site.distance_to(world.spawn.x, world.spawn.y) <= radius:
				found.append(site)
	found.sort_custom(func(a: Ruin, b: Ruin) -> bool:
		return a.distance_to(world.spawn.x, world.spawn.y) < b.distance_to(world.spawn.x, world.spawn.y))
	return found


## Stands you where "go looking" does, in front of a house ruin's door, and
## waits for what lies there: the ruin.
func go_looking() -> Ruin:
	var scenario := Scenarios.by_key("ruin")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	await settle_finds()
	return ruin_in_front()


## The house ruin whose front door is before you, within 30 m, or null.
func ruin_in_front() -> Ruin:
	var x := world.player_world_x()
	var z := world.player_world_z()
	for site in world.shape.sites.query(Rect2(x - 30.0, z - 30.0, 60.0, 60.0), false):
		if site is Ruin and world.shape.sites.covering(site.x, site.z) == site:
			return site
	return null


## A plan point of a ruin in engine coordinates, on its floor.
func on_floor(ruin: Ruin, p: Vector2) -> Vector3:
	var at := ruin.to_world(p)
	return Vector3(world.engine_x(at.x), ruin.floor_y, world.engine_z(at.y))
