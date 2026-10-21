class_name PodInterior
extends Node3D
## A render-only shell at the actual capsule's local poses, never spare equipment.

static func build(parts: Dictionary = {}) -> PodInterior:
	var interior := PodInterior.new()
	interior.name = "PodInterior"
	if parts.is_empty():
		interior._nominal()
		return interior
	PodShell.ensure_aperture(parts)
	var floor := parts.get(&"floor_a") as Chassis
	if not is_instance_valid(floor):
		return interior
	var root := floor.deck if floor.deck != null else floor
	var origin := root.global_transform * floor.pose() if root.is_inside_tree() else floor.pose()
	for role: StringName in parts:
		var part := parts[role] as Node3D
		if not is_instance_valid(part):
			continue
		if part is Chassis:
			var deck: Chassis = part.deck if part.deck != null else part
			for child in deck.get_children():
				if child is MeshInstance3D and not child.has_meta(&"socket") \
					and child.get_meta(&"piece", deck) == part:
					var pose: Transform3D = origin.affine_inverse() * child.global_transform if child.is_inside_tree() \
						else floor.pose().affine_inverse() * child.transform
					interior._copy(child, pose)
		elif part is Frame and part.socket != null:
			for child in part.socket.fitted:
				if child is MeshInstance3D:
					var pose: Transform3D = origin.affine_inverse() * child.global_transform if child.is_inside_tree() \
						else floor.pose().affine_inverse() * child.transform
					interior._copy(child, pose)
	return interior


func _copy(source: MeshInstance3D, pose: Transform3D) -> void:
	var view := _mesh(source.mesh, pose)
	view.material_override = source.material_override
	view.material_overlay = source.material_overlay
	for parameter in source.get_instance_shader_parameter_list():
		var key: StringName = parameter.name
		view.set_instance_shader_parameter(key, source.get_instance_shader_parameter(key))


func _mesh(mesh: Mesh, pose: Transform3D) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.transform = pose
	add_child(view)
	return view


func _nominal() -> void:
	# Old flights have no physical pod yet. Author meshes directly, without catalog bodies.
	var plate := Dress.frame(&"chassis", Catalog.DEVICES[&"chassis"].size)
	for i in 2:
		var floor_pose := Transform3D(Basis.IDENTITY, Vector3(i, 0, 0))
		_mesh(plate, floor_pose)
		_mesh(PodShell._heatshield_mesh(), floor_pose)
		_mesh(Dress.part(&"frame", Catalog.PARTS[&"frame"].size), floor_pose * Chassis.FACES[Chassis.TOP])
	for role: StringName in PodShell.PANELS:
		var cell: Vector2i = PodShell.PANELS[role][0]
		var face: Array = Frame.FACES[PodShell.PANELS[role][1]]
		var frame_pose := Transform3D(Basis.IDENTITY, Vector3(cell.x, 0, cell.y)) * Chassis.FACES[Chassis.TOP]
		var pose := frame_pose * Transform3D(Catalog._facing(face[1]), face[0]) * Frame.piece_seat()
		_mesh(PodApertureLooks.frame() if role == &"tail" else plate, pose)
		if role == &"tail":
			for side in [-1.0, 1.0]:
				var pane := _mesh(PodApertureLooks.glass(), pose * Transform3D(Basis.IDENTITY, Vector3(0, side * 0.05, 0)))
				pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			_mesh(PodShell._armor_mesh(), pose)
