extends SavesProbe
## Profile & saves probe 2: only what changed. A world with its finds laid
## out, one of them taken, and the clock hours on, so the weather a chunk
## coming near now would lay out other finds. The save holds no ground and
## no untouched find: only what's yours, and which finds near you were taken
## from where, and it stays small. Resumed, the same finds lie where they
## lay, less the one taken, which is yours.

## Bytes a save of a lone find and its chunks' memory stays under.
const SMALL := 16 * 1024
const HOURS := 9.0


func run() -> void:
	saves = get_node("/root/Saves")
	await load_world(1234, false, true)
	await _finds_down()
	var lying := _lying()
	check(lying.size() >= 3, "finds lie round you (%d)" % lying.size())
	var taken: RigidBody3D = null
	for body in world.salvage.near(world.player.global_position):
		if body is Device:
			taken = body
			break
	check(taken != null, "a found device lies near")
	var key := _key(taken)
	var id: StringName = taken.get_meta(&"catalog")
	world.salvage.claim(taken)
	world.time += HOURS * 3600.0
	await physics_frames(2)
	check(saves.save(world), "saved")
	var size := FileAccess.get_file_as_bytes(saves.path()).size()
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	print("save: %d bytes, %d things, %d chunks remembered" % [size, data.things.size(), data.finds.size()])
	check(size < SMALL, "it stays small (%d bytes)" % size)
	check(data.things.size() == 1 and data.things[0].id == id, "it holds only the find taken")
	check(not data.has("terrain") and not data.has("chunks"), "it holds no ground")
	var remembered := 0
	for memory: Array in data.finds:
		remembered += memory[2].size()
	check(remembered == 1, "and which find was taken")

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


## Every find laid out in the chunks round you, by chunk and number, where it lies.
func _lying() -> Dictionary:
	var out := {}
	for body in world.salvage.near(world.player.global_position):
		out[_key(body)] = Vector3(world.world_x(body.global_position.x), body.global_position.y,
			world.world_z(body.global_position.z))
	return out


func _key(body: Node) -> String:
	var at: Array = body.get_meta(&"find")
	return "%s/%d" % [at[0], at[1]]


func _finds_down() -> void:
	for i in 600:
		await get_tree().physics_frame
		if world.salvage.is_idle() and world.terrain.is_idle():
			return
	check(false, "the finds were laid out")
