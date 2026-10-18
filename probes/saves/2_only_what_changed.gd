extends SavesProbe
## Profile & saves probe 2: only what changed. Among a town's ruins, a find
## taken from a site and the clock stopped. The save holds no ground and no
## untouched find: only what's yours, and which site's socket it came from,
## and it stays small. Resumed, the same finds lie where they lay, less the
## one taken, which is yours, and if the sand held it, it still does. A save
## from before sites remembered anything resumes too, the find lying there
## again.

## Bytes a save of a lone find and its sites' memory stays under.
const SMALL := 16 * 1024


func run() -> void:
	saves = get_node("/root/Saves")
	start_among(1234)
	# Dug out, so its loot is there to take.
	Tuning.current().site_return_m = -1.0
	await load_world(1234, false, true)
	world.time_warp = 0.0
	var ruin := _nearest_ruin()
	check(ruin != null, "a house ruin stands near")
	if ruin == null:
		return
	var at := ruin.to_world(Ruin.APPROACH)
	teleport(at.x, at.y)
	await _finds_down()
	var lying := _lying()
	check(lying.size() >= 3, "finds lie round you (%d)" % lying.size())
	var taken: RigidBody3D = null
	for body in world.salvage.near(world.player.global_position):
		if body.get_meta(&"find").size() > 2 and (taken == null or body.has_meta(&"buried")):
			taken = body
	check(taken != null, "a site's find lies near")
	if taken == null:
		return
	var key := _key(taken)
	var id: StringName = taken.get_meta(&"catalog")
	var held := taken.has_meta(&"buried")
	world.salvage.claim(taken)
	await physics_frames(2)
	check(saves.save(world), "saved")
	var size := FileAccess.get_file_as_bytes(saves.path()).size()
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	print("save: %d bytes, %d things, %d sites remembered" % [size, data.things.size(), data.sites.size()])
	check(size < SMALL, "it stays small (%d bytes)" % size)
	check(data.things.size() == 1 and data.things[0].id == id, "it holds only the find taken")
	check(not data.has("terrain") and not data.has("chunks"), "it holds no ground")
	check(data.sites.size() == 1 and data.sites[0][1].size() == 1, "and which site's socket it was taken from")

	check(await resume(), "resumed")
	await _finds_down()
	var again := _lying()
	var moved := 0.0
	for k: String in lying:
		if k == key:
			check(not again.has(k), "the taken find isn't laid out again")
		elif again.has(k):
			moved = maxf(moved, again[k].distance_to(lying[k]))
		else:
			check(false, "find %s lies again" % k)
	check(again.size() == lying.size() - 1, "every other find is back (%d of %d)" % [again.size(), lying.size() - 1])
	check(moved < 0.05, "where it lay (%.3f m)" % moved)
	var yours := world.content.get_children().filter(func(n: Node) -> bool: return n.has_meta(&"catalog"))
	check(yours.size() == 1 and yours[0].get_meta(&"catalog") == id, "the taken find is yours")
	check(yours.size() == 1 and world.salvage.lying(yours[0]) == held and (yours[0].freeze or not held),
		"held by the sand as it was (%s)" % ("held" if held else "loose"))

	# Before sites remembered what was taken.
	data.erase("sites")
	check(SaveFile.write(saves.path(), saves.KIND, saves.VERSION, data), "an older save written")
	check(await resume(), "an older save resumes")
	await _finds_down()
	check(_lying().has(key), "and the find lies there again")


## The standing house ruin nearest you.
func _nearest_ruin() -> Ruin:
	var best: Ruin = null
	var x := world.player_world_x()
	var z := world.player_world_z()
	for unit in world.shape.sites.units():
		for site in unit.sites:
			if site is Ruin and world.shape.sites.covering(site.x, site.z) == site \
					and (best == null or site.distance_to(x, z) < best.distance_to(x, z)):
				best = site
	return best


## Every find laid out in the chunks round you, by where it came from, where it lies.
func _lying() -> Dictionary:
	var out := {}
	for body in world.salvage.near(world.player.global_position):
		out[_key(body)] = Vector3(world.world_x(body.global_position.x), body.global_position.y,
			world.world_z(body.global_position.z))
	return out


func _key(body: Node) -> String:
	return str(body.get_meta(&"find"))


func _finds_down() -> void:
	for i in 900:
		await get_tree().physics_frame
		if world.salvage.is_idle() and world.terrain.is_idle():
			return
	check(false, "the finds were laid out")
