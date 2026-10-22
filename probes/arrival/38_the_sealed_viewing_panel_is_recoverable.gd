extends ArrivalSaveProbe
## The visible opening belongs to the actual recoverable tail, including saved loose panels.
func run() -> void:
	await prepare_arrival()
	var pod := PodShell.build(world.content, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3(0, 2, -5)))
	pod.deck.freeze = true
	for uid: StringName in pod.named:
		pod.named[uid].set_meta(&"arrival_uid", uid)
	world.arrival_nodes = pod.named.duplicate()
	world.arrival_state.merge({"phase": &"recovery", "materialized": true}, true)
	var tail := pod.named[&"tail"] as Chassis
	var mass := pod.deck.mass
	var native := _shapes(pod.deck)
	var views := pod.deck.get_child_count()
	PodShell.ensure_aperture(pod.named)
	PodShell.restore_skin(tail, &"armor")
	check(pod.named.size() == 12 and pod.deck.mass == mass and _shapes(pod.deck) == native
		and pod.deck.get_child_count() == views, "the window is an idempotent skin on the same complete physical pod")
	check(not _blocks_center(tail.frame_view.mesh) and tail.get_meta(&"pod_skin") == &"viewport",
		"the opaque tail mesh genuinely opens through its center")
	var count := world.content.get_child_count()
	var inside := PodShell.flight_interior(pod.named)
	check(inside.get_child_count() > 12 and world.content.get_child_count() == count and not _has_bodies(inside),
		"the actual interior snapshot is only meshes and grants no equipment")
	inside.free()
	var legacy := PodShell.flight_interior()
	check(legacy.get_child_count() > 12 and not _has_bodies(legacy), "legacy flight authors a complete mesh-only shell")
	legacy.free()
	var loose := pod.deck.detach(tail) as Chassis
	loose.freeze = true
	loose.global_position += Vector3(0, 1, 2)
	var detached_views := loose.get_child_count()
	PodShell.restore_skin(loose)
	check(loose.get_child_count() == detached_views and _shapes(loose) == 1
		and not _blocks_center(loose.frame_view.mesh), "ordinary dismantling keeps the sealed transparent panel intact")
	check(saves.save(world), "the actual detached window saves")
	check(await resume_arrival(), "the actual detached window resumes")
	var restored := world.arrival_nodes.get(&"tail") as Chassis
	check(restored != null and restored.deck == null and restored.get_meta(&"pod_skin", &"") == &"viewport"
		and not _blocks_center(restored.frame_view.mesh) and _shapes(restored) == 1,
		"saved loose window restores its genuine aperture and original collision envelope")
	var root := world.arrival_nodes[&"floor_a"] as Chassis
	root.join(restored, Rig.face_of(root, Vector2i(1, 0), &"right"))
	check(restored.deck == root and root.pieces().size() == 10,
		"the same restored window rejoins its ordinary supporting frame")

func _shapes(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is CollisionShape3D:
			count += 1
	return count

func _has_bodies(node: Node) -> bool:
	if node is CollisionObject3D:
		return true
	for child in node.get_children():
		if _has_bodies(child): return true
	return false

func _blocks_center(mesh: Mesh) -> bool:
	var triangles := mesh.get_faces()
	for i in range(0, triangles.size(), 3):
		if Geometry3D.segment_intersects_triangle(Vector3(0, -1, 0), Vector3(0, 1, 0),
			triangles[i], triangles[i + 1], triangles[i + 2]) != null:
			return true
	return false
