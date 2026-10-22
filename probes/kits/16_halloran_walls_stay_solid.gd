extends WorldProbe
## The ends of Halloran stay solid after the Crossing leaves collision range.
## Time limit: 300 s.

func run() -> void:
	await load_world(1234, true, true)
	var hall := world.shape.history.landmark(&"halloran")
	var crossing: Dictionary = hall.parts.filter(func(p: Dictionary) -> bool: return p.id == &"crossing")[0]
	world.travel(rad_to_deg(Sphere.latitude(crossing.p)), rad_to_deg(Sphere.longitude(crossing.p)), 0)
	world.time_warp = 0
	await settle()
	var sites := structures_near(&"halloran_route")
	check(sites.size() == 1, "Halloran is streamed")
	if sites.is_empty():
		return
	var site := sites[0]
	for point: Vector2 in [Vector2(-310, 0), Vector2(295, 0), Vector2(-310, 0)]:
		var at := site.to_world(point)
		teleport(at.x, at.y)
		await settle()
		await physics_frames(3)
		var frame := site.frame()
		frame.origin.x = world.engine_x(frame.origin.x)
		frame.origin.z = world.engine_z(frame.origin.z)
		var lower := point.x < 0
		var from := Vector3(-314, 6, 23) if lower else Vector3(300, 50, 14)
		var to := Vector3(-314, 2.5, 23) if lower else Vector3(300, 46, 14)
		var query := PhysicsRayQueryParameters3D.create(frame * from, frame * to, 1)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(), "Halloran's roof supports bodies away from the Crossing")
		from = Vector3(-315, 2, 15) if lower else Vector3(290, 38, 22)
		to = Vector3(-315, 2, 20) if lower else Vector3(290, 38, 26)
		query = PhysicsRayQueryParameters3D.create(frame * from, frame * to, 1)
		hit = world.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(), "Halloran's wall blocks passage away from the Crossing")
