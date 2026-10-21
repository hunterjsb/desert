extends MovementProbe
## Movement probe 39: your body. Your suit (Body) is drawn for others and
## for its shadow, but your helmet isn't in your own eyes; it has no shapes
## of its own to bump into. Standing, walking or crouched, your boots stay on
## the sand under you.


func run() -> void:
	await load_moving()
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 4.0)
	await place(flat.x, flat.z, Vector2(1.0, 0.0))
	var body := player.body
	var head := body.get_node(^"head") as MeshInstance3D
	check(head.layers & player.camera.cull_mask == 0 and head.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"your helmet casts its shadow, but isn't in your own eyes")
	check(body.find_children("*", "CollisionShape3D", true, false).is_empty(), "your body is only looks")
	for keys: Array in [[], ["move_forward"], ["crouch"]]:
		hold(keys)
		await simulate(1.0)
		var lowest := INF
		var highest := -INF
		for i in 30:
			await get_tree().process_frame
			for side in ["r", "l"]:
				var sole: float = (body.get_node(NodePath("foot_" + side)) as Node3D).global_position.y \
					- player.global_position.y
				lowest = minf(lowest, sole)
				highest = maxf(highest, sole)
		print("%s: ankles %.2f to %.2f m over your feet" % [keys if not keys.is_empty() else "standing", lowest, highest])
		check(lowest > 0.05 and lowest < 0.15 and highest < 0.3, "%s, your boots stay on the sand" % [
			keys[0] if not keys.is_empty() else "standing"])
	hold([])
