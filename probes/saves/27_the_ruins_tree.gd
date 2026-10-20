extends HandsProbe
## Profile & saves probe 27: the ruins' deeds, in one storm. Three house ruins
## stood by hand where the storm at its strongest works the sand off each,
## as deep as leaves each one newly bare then: reaching two in it is no Storm
## Chaser, the third is. The thing in a bared ruin's hall taken by hand is
## Bared.


func run() -> void:
	await load_hands(1234, true)
	world.counts_deeds = true
	world.time_warp = 0.0
	var profile := get_node(^"/root/Profile")
	var sites := world.shape.sites
	var field := world.weather.field
	var tuning := world.tuning
	var from := Vector2(world.player_world_x() + 300.0, world.player_world_z())
	var stands := func(at: Vector2) -> bool: return sites.by_hand(&"house_ruin", at.x, at.y, 0.0, 0.0).stands()
	var storm := StormSite.strongest(field, tuning, from.x, from.y, 2, 100.0, 1.0, stands)
	check(not storm.is_empty(), "a storm that lays ruins bare")
	if storm.is_empty():
		return
	var t: float = storm.peak
	var bare: Array[Structure] = []
	for ring in range(0, 5):
		for k in maxi(1, 6 * ring):
			var at := Vector2(storm.x, storm.z) + Vector2.from_angle(TAU * k / maxi(1, 6 * ring)) * ring * 50.0
			var taken := Exposure.taken(field, at.x, at.y, t, tuning)
			if bare.size() < 3 and field.raw_storm_at(at.x, at.y, t) > 0.0 \
					and taken - Exposure.settled(field, at.x, at.y, t, tuning) > 0.05 and stands.call(at):
				var site := sites.by_hand(&"house_ruin", at.x, at.y, 0.0, taken * 1.2)
				sites.add(site)
				bare.append(site)
	check(bare.size() == 3, "three ruins the storm lays bare at once")
	if bare.size() < 3:
		return
	world.time = t
	for i in 3:
		teleport(bare[i].x, bare[i].z)
		await settle(true)
		await physics_frames(3)
		check(world.weather.in_storm and bare[i].bared() > 0.0, "the storm on you, laying the %s bare" % _nth(i))
		check(profile.did("storm_chaser") == (i == 2), "the %s reached: %s" % [_nth(i),
			"Storm Chaser" if i == 2 else "not yet"])
	await settle()
	for i in 600:
		if world.salvage.is_idle():
			break
		await get_tree().process_frame
	var loot: RigidBody3D = null
	for body in world.salvage.finds():
		var at: Array = body.get_meta(&"find")
		if at.size() > 2 and at[2] == bare[2].id:
			loot = body
	check(loot != null and not profile.did("bared"), "its hall holds something, not yet taken")
	if loot == null:
		return
	var middle := loot.global_transform * Finds.bounds(loot).get_center()
	for eye_at: Vector3 in [Vector3(0.0, 1.2, 0.8), Vector3(0.8, 1.2, 0.0), Vector3(0.0, 1.2, -0.8),
			Vector3(-0.8, 1.2, 0.0), Vector3(0.1, 1.5, 0.1)]:
		look(middle + eye_at, middle)
		await physics_frames(1)
		hands._look()
		if hands.look_device == loot or hands.look_part == loot:
			hands.grab()
			break
	await physics_frames(20)
	check(hands.held == loot or hands.grasp.body == loot, "taken by hand")
	check(profile.did("bared"), "loot taken from a ruin the storm bared: Bared")


static func _nth(i: int) -> String:
	return ["first", "second", "third"][i]
