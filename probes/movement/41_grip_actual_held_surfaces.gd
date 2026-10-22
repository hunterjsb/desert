extends HandsProbe
## Movement probe 41: your gloves meet what you hold within reach. A cutter
## and a chassis, held looking a little down, each have a glove on their own
## surface rather than reaching short of it or into it.

func run() -> void:
	await load_hands()
	var player := world.player
	for id: StringName in [&"cutter", &"chassis"]:
		for pitch in [-25.0]:
			player.camera.rotation_degrees.x = pitch
			var item := Catalog.device(id)
			world.content.add_child(item)
			item.global_position = player.global_position + Vector3(0.0, 1.0, -1.0)
			await physics_frames(2)
			hands.hold(item)
			await physics_frames(50)
			player.body.pose(0.0)
			var nearest := INF
			for side in ["r", "l"]:
				var hand := player.body.get_node(NodePath("hand_" + side)) as Node3D
				nearest = minf(nearest, _gap(item, hand.to_global(Vector3(0.0, -Body.GRIP, 0.0))))
			print("%s at %d degrees: nearest glove %.3f m off it" % [id, pitch, nearest])
			check(nearest < 0.03, "holding the %s at %d degrees, a glove is on it" % [id, pitch])
			hands.drop()
			item.queue_free()
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
