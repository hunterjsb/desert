extends DeckProbe
## Cached frame contacts must follow edits to the actual native collision geometry.


func run() -> void:
	await load_lines()
	var chassis := piece(world.player.global_position + Vector3(0, 0, -4))
	chassis.freeze = true
	chassis.global_position.y += 100.0
	check(_matches_native(chassis), "bare frame matches native geometry")
	chassis.join(piece(spot(2, -4)), ring(chassis, Vector2i.ZERO, Vector2i.RIGHT), 0)
	chassis.join(piece(spot(3, -4)), ring(chassis, Vector2i.RIGHT, Vector2i.RIGHT), 0)
	check(_matches_native(chassis), "joins retain native shape order and corners")
	var off := chassis.detach(chassis)
	off.freeze = true
	check(_matches_native(chassis) and _matches_native(off), "reroot and detach rebuild both bodies' contacts")
	var extra := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 0.6, 0.9)
	extra.shape = box
	chassis.add_child(extra)
	check(_matches_native(chassis), "a newly added native shape joins the ordered contacts")
	box.size *= 1.5
	check(_matches_native(chassis), "editing the same shape resource refreshes its endpoints")
	var replacement := BoxShape3D.new()
	replacement.size = Vector3(0.7, 1.4, 0.5)
	extra.shape = replacement
	check(_matches_native(chassis), "a replacement resource is used before its first contact")
	extra.transform = Transform3D(Basis(Vector3.UP, 0.3), Vector3(2, 1, -3))
	chassis.rotation.z = deg_to_rad(100.0)
	check(_matches_native(chassis), "current shape and chassis transforms place the corners")
	extra.disabled = true
	check(_matches_native(chassis), "disabled shape state is read live")
	extra.disabled = false
	chassis.move_child(extra, 0)
	check(_matches_native(chassis), "re-enabling and reordering preserve native traversal order")
	var radio := Catalog.device(&"radio")
	world.content.add_child(radio)
	var socket := Stick.put(chassis, chassis, Chassis.TOP, Vector2.ZERO, 0.0, radio)
	check(_matches_native(chassis), "mounting retains only the chassis's own native geometry")
	chassis.dismount(socket).freeze = true
	check(_matches_native(chassis), "dismounting retains the correct ordered frame geometry")
	world.shift_origin(Vector2i(3, -2))
	check(_matches_native(chassis), "origin shifts never retain old world-space corners")
	if is_instance_valid(extra):
		extra.free()
	check(_matches_native(chassis), "removing a shape removes its cached contacts")


func _matches_native(chassis: Chassis) -> bool:
	# Read the frames' corners without meeting the sand.
	chassis.frame_contact_points(PackedVector3Array(), PackedFloat32Array(), world.tuning.runner_clearance)
	var native := chassis.get_children().filter(func(child: Node) -> bool: return child is CollisionShape3D)
	var frames := chassis._contact_frames
	if frames.map(func(frame: Chassis.FrameContact) -> CollisionShape3D: return frame.shape) != native:
		return false
	for frame in frames:
		var shape := frame.shape
		if shape.shape == null or shape.disabled or shape.has_meta(&"socket"):
			continue
		# The physics resource's debug bounds are independent of the cached endpoints.
		var bounds := shape.shape.get_debug_mesh().get_aabb()
		var pose := chassis.global_transform * shape.transform
		for i in 8:
			if pose * frame.corners[i] != pose * bounds.get_endpoint(i):
				return false
	return true
