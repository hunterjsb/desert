extends Probe
## Wreck probe 9: the bare roof ribs are solid. The player's capsule, dropped
## onto an aft rib over the torn-open bay, rests there even when the wreck
## leans. The opening beside the rib remains an opening.

func run() -> void:
	var space := Node3D.new()
	add_child(space)
	var hull := Structure.new()
	hull.piece = StructureKit.piece(&"wreck_hull")
	var solid := StaticBody3D.new()
	space.add_child(solid)
	hull.add_shapes(solid, Exposure.PARTLY)
	solid.transform = Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(4.0, 2.0, -3.0))
	var player := preload("res://game/player/player.tscn").instantiate()
	var capsule := player.get_node("Body") as CollisionShape3D
	var shape := capsule.duplicate() as CollisionShape3D
	player.free()
	var feet := CharacterBody3D.new()
	feet.add_child(shape)
	space.add_child(feet)
	var top := solid.transform * Vector3(1.2, 3.16, 5.4)
	feet.position = top + Vector3.UP * 0.5
	await physics_frames(2)
	for i in 90:
		await get_tree().physics_frame
		feet.velocity.y -= 9.8 / Engine.physics_ticks_per_second
		feet.move_and_slide()
	print("rib contact: %.4f m above its face, floor=%s" % [feet.position.y - top.y, feet.is_on_floor()])
	check(feet.is_on_floor() and feet.position.y >= top.y - 0.01 and feet.position.y < top.y + 0.1,
		"the player's capsule rests on the exposed leaning roof rib")
	var at := solid.transform * Vector3(1.2, 3.1, 5.05)
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.1, at - Vector3.UP * 0.1)
	query.exclude = [feet.get_rid()]
	check(space.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "the torn roof beside it remains open")
