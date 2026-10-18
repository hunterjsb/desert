extends WorldProbe
## Profile & saves probe 21: all four ages. Stepping onto two colonial
## structures, a skimmer wreck and a First Kingdoms hut is three ages, not
## four; onto a second-age house ruin as well, Carbon Dated is done.

const KINDS: Array[StringName] = [&"hab_pod", &"relay_mast", &"wreck_hull", &"pipe_wall_hut", &"house_ruin"]


func run() -> void:
	await load_world(1234, true, true)
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var from := Vector2(world.player_world_x(), world.player_world_z()) + Vector2(400.0, 0.0)
	for i in KINDS.size():
		var site := _stood(KINDS[i], from + Vector2(0.0, i * 300.0))
		check(site != null, "a %s stands by hand" % KINDS[i])
		if site == null:
			return
		world.shape.sites.add(site)
		teleport(site.x, site.z)
		await settle(true)
		await physics_frames(2)
		check(profile.did("ages") == (i == KINDS.size() - 1), "after the %s, %s" % [KINDS[i],
			"all four ages" if i == KINDS.size() - 1 else "not yet four"])


## A structure of a kind stood by hand where the dunes take it, near a place.
func _stood(kind: StringName, near: Vector2) -> Structure:
	for k in 60:
		var site := world.shape.sites.by_hand(kind, near.x + (k % 10) * 23.0, near.y + (k / 10) * 29.0, 0.3, 0.0)
		if site.stands():
			return site
	return null
