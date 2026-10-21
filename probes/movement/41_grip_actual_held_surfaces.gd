extends HandsProbe
## A held cutter's rear handle and a chassis's near frame meet fixed-length
## arms without changing either physical carrying pose.

func run() -> void:
	await load_hands()
	var player := world.player
	player.camera.rotation_degrees.x = -25.0
	for id: StringName in [&"cutter", &"chassis"]:
		var item := Catalog.device(id)
		world.content.add_child(item)
		item.global_position = player.global_position + Vector3(0.0, 1.0, -1.0)
		await physics_frames(2)
		hands.hold(item)
		await physics_frames(50)
		var body := player.body
		body.pose(0.0)
		var item_pose := item.global_transform
		var velocity := item.linear_velocity
		var player_pose := player.global_transform
		var player_velocity := player.velocity
		var shape_count := item.find_children("*", "CollisionShape3D", true, false).size()
		for side in ["r", "l"] if id == &"chassis" else ["r"]:
			var hand := body.get_node(NodePath("hand_" + side)) as Node3D
			var grip := hand.to_global(Vector3(0.0, -Body.GRIP, 0.0))
			var upper := body.get_node(NodePath("upper_arm_" + side)) as Node3D
			var forearm := body.get_node(NodePath("forearm_" + side)) as Node3D
			check(absf(upper.position.distance_to(forearm.position) - Body.UPPER_ARM) < 0.0001
				and absf(forearm.position.distance_to(hand.position) - Body.FOREARM) < 0.0001
				and upper.basis.get_scale().is_equal_approx(Vector3.ONE)
				and forearm.basis.get_scale().is_equal_approx(Vector3.ONE),
				"the %s %s grip keeps the original arm lengths" % [id, side])
			var error: float
			if id == &"cutter":
				error = grip.distance_to(item.to_global(Vector3(0.0, -0.04, 0.16)))
			else:
				# The original plate's actual top/edge, not the old distant center target.
				var at := item.to_local(grip)
				error = at.distance_to(at.clamp(Vector3(-0.5, -0.06, -0.5), Vector3(0.5, 0.06, 0.5)))
			print("%s %s grip error %.5f m" % [id, side, error])
			check(error < 0.005, "%s %s glove meets its real grip" % [id, side])
		for i in 20:
			body.pose(0.0)
		check(item.global_transform == item_pose and item.linear_velocity == velocity
			and player.global_transform == player_pose and player.velocity == player_velocity
			and item.find_children("*", "CollisionShape3D", true, false).size() == shape_count
			and body.find_children("*", "CollisionShape3D", true, false).is_empty(),
			"posing the %s grip changes no physics" % id)
		hands.drop()
		item.queue_free()
		await physics_frames(2)
