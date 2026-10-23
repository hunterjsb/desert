extends HandsProbe
## Movement probe 41: your gloves are on what you hold. A radio and a battery
## ride low and close in your arms, out of your face, gloves on their sides
## however you look; a cutter and a chassis keep a glove on their own surface.
## Tuning the radio brings it up to read.

func run() -> void:
	await load_hands()
	var player := world.player
	for id: StringName in [&"radio", &"battery", &"cutter", &"chassis"]:
		var made: RigidBody3D = Catalog.device(id) if Catalog.DEVICES.has(id) else Catalog.part(id)
		world.content.add_child(made)
		made.global_position = player.global_position + Vector3(0.0, 1.0, -1.0)
		await physics_frames(2)
		hands.hold(made)
		var small := id in [&"radio", &"battery"]
		for pitch in ([0.0, -40.0, 20.0] if small else [-25.0]):
			player.camera.rotation_degrees.x = pitch
			await physics_frames(40)
			for i in 3:
				await get_tree().process_frame
			var nearest := INF
			for side in ["r", "l"]:
				var hand := player.body.get_node(NodePath("hand_" + side)) as Node3D
				nearest = minf(nearest, _gap(made, hand.to_global(Vector3(0.0, -Body.GRIP, 0.0))))
			var from_eye := player.camera.global_transform.affine_inverse() * Hands.middle_of(made)
			print("%s at %d degrees: glove %.3f m off it; %.2f m below the eye line, %.2f m out" % [id, pitch,
				nearest, -player.to_local(made.to_global(Hands.middle_of(made))).y + player.camera.position.y,
				-player.to_local(made.to_global(Hands.middle_of(made))).z])
			check(nearest < 0.03, "holding the %s at %d degrees, a glove is on it" % [id, pitch])
			if small and pitch == 0.0:
				var at := player.to_local(made.to_global(Hands.middle_of(made)))
				check(player.camera.position.y - at.y > 0.3 and -at.z < 0.45 and from_eye.z < 0.0,
					"the %s rides low and close, out of your face" % id)
		if id == &"radio":
			player.camera.rotation_degrees.x = 0.0
			await physics_frames(30)
			var low := made.to_global(Hands.middle_of(made)).y
			player.close_up.tuned(made as Radio, true)
			await physics_frames(30)
			check(made.to_global(Hands.middle_of(made)).y > low + 0.2, "tuning it brings it up to read")
		hands.drop()
		made.queue_free()
		await physics_frames(2)


## How far a point is from the nearest of a body's own collision boxes, m.
func _gap(body: Node3D, point: Vector3) -> float:
	var best := INF
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null or shape.disabled or shape.has_meta(&"socket"):
			continue
		var box := Catalog.bounds(shape.shape)
		var local := shape.to_local(point)
		best = minf(best, local.distance_to(local.clamp(box.position, box.end)))
	return best
