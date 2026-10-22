extends ArrivalSaveProbe
## Side and roof glazing remains on the same dismantled, saved physical panel.
func run() -> void:
	await prepare_arrival()
	var pod := PodShell.build(world.content, Transform3D(Basis.IDENTITY, world.player.global_position + Vector3(0, 2, -5)))
	pod.deck.freeze = true
	for role: StringName in pod.named:
		pod.named[role].set_meta(&"arrival_uid", role)
	world.arrival_nodes = pod.named.duplicate()
	world.arrival_state.merge({"phase": &"recovery", "materialized": true}, true)
	var mass := pod.deck.mass
	for role in PodShell.VIEWPORTS:
		var panel := pod.named[role] as Chassis
		check(panel.get_meta(&"pod_skin", &"") == &"viewport" and not _opaque(panel.frame_view.mesh), "each viewing panel has a real visual opening")
	PodShell.ensure_aperture(pod.named)
	check(is_equal_approx(pod.deck.mass, mass), "extra glazing does not create physical equipment or change pod mass")
	var side := pod.deck.detach(pod.named[&"side_front_a"]) as Chassis
	var roof := pod.deck.detach(pod.named[&"roof_b"]) as Chassis
	side.freeze = true
	roof.freeze = true
	check(saves.save(world) and await resume_arrival(), "the actual loose side and roof save and resume")
	for role in [&"side_front_a", &"roof_b"]:
		var panel := world.arrival_nodes.get(role) as Chassis
		check(is_instance_valid(panel) and panel.deck == null and panel.get_meta(&"pod_skin", &"") == &"viewport"
			and not _opaque(panel.frame_view.mesh), "dismantling and disk restore preserve that original glazed panel")

func _opaque(mesh: Mesh) -> bool:
	var triangles := mesh.get_faces()
	for i in range(0, triangles.size(), 3):
		if Geometry3D.segment_intersects_triangle(Vector3(0, -1, 0), Vector3(0, 1, 0),
			triangles[i], triangles[i + 1], triangles[i + 2]) != null:
			return true
	return false
