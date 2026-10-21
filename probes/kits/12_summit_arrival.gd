extends WorldProbe
## Real streamed summit terrain and galleries support a traveller and cargo.
## Time limit: 300 s.
func run() -> void:
	await load_world(1234, true, true)
	for id in [&"starcom", &"observatory"]:
		var mark := world.shape.history.landmark(id)
		world.travel(rad_to_deg(Sphere.latitude(mark.p)), rad_to_deg(Sphere.longitude(mark.p)), 0)
		world.time_warp = 0
		await settle()
		var found := structures_near(StringName(String(id) + "_summit"))
		check(found.size() == 1, "exactly one streamed summit structure")
		if found.is_empty():
			continue
		var site := found[0]
		var at := site.to_world(Vector2(24, 10))
		teleport(at.x, at.y)
		await settle()
		var box := drop_box(at.x + 1, at.y, 1)
		await physics_frames(120)
		check(box.global_position.y >= site.floor_y and box.global_position.y < site.floor_y + 2,
			"cargo rests on the actual summit gallery")
		var query := PhysicsRayQueryParameters3D.create(box.global_position + Vector3.UP, box.global_position - Vector3.UP * 4)
		query.exclude = [box.get_rid()]
		var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(), "the visible summit has physical ground beneath it")
		if is_instance_valid(box):
			box.queue_free()
