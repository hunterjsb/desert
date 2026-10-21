extends SavesProbe
## Saving low preserves usable clearance; old saves resume standing without a rest deed.
func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_world()
	await physics_frames(20)
	var awarded := [0]
	get_node(^"/root/Profile").deed_done.connect(func(id: String) -> void:
		if id == "ground_rest":
			awarded[0] += 1)
	for pose: StringName in [&"prone", &"sit"]:
		world.player.restore_ground_pose(pose)
		check(saves.save(world), "saved the grounded posture")
		check(await resume(), "resumed the grounded posture")
		check(world.player.ground_pose == pose, "the saved posture remains usable after loading")
		var body := world.player.get_node(^"Body") as CollisionShape3D
		check((body.shape as CapsuleShape3D).height < 1.8, "loading immediately restores the physical low body")
	var old := Snapshot.take(world)
	old.player.erase("ground_pose")
	check(SaveFile.write(saves.path(), saves.KIND, saves.VERSION, old), "wrote a save from before ground posture")
	check(await resume(), "resumed a legacy posture record")
	check(world.player.ground_pose == &"stand", "a legacy save defaults to standing")
	check(awarded[0] == 0, "restoring postures never awards a voluntary rest deed")
