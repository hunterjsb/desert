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
	var selected := {}
	for part: Node in parts.values():
		if is_instance_valid(part):
			selected[part.get_instance_id()] = true
	var copied := {}
	for role: StringName in parts:
		var part := parts[role] as Node3D
		if not is_instance_valid(part):
			continue
		if part is Chassis:
			var deck: Chassis = part.deck if part.deck != null else part
			# Joined panels share one body: copy only that panel's own shell here.
			for child in deck.get_children():
				if child is MeshInstance3D and not child.has_meta(&"socket") \
					and child.get_meta(&"piece", deck) == part:
					interior._collect(child, origin, copied, selected)
		elif part is Part and part.socket != null:
			# Fitted parts wait off-tree; their real meshes live on the host body.
			for child in part.socket.fitted:
				interior._collect(child, origin, copied, selected)
		else:
			for child in part.get_children():
				interior._collect(child, origin, copied, selected)
	return interior


func _collect(node: Node, origin: Transform3D, copied: Dictionary, selected: Dictionary) -> void:
	if node is RigidBody3D and not selected.has(node.get_instance_id()):
		return
	if node is MeshInstance3D and node.mesh != null and not copied.has(node.get_instance_id()):
		copied[node.get_instance_id()] = true
		var pose: Transform3D = origin.affine_inverse() * node.global_transform
		_copy(node, pose)
	for child in node.get_children():
		_collect(child, origin, copied, selected)


func _copy(source: MeshInstance3D, pose: Transform3D) -> void:
	var view := _mesh(source.mesh, pose)
	view.material_override = source.material_override
	view.material_overlay = source.material_overlay
	for i in source.get_surface_override_material_count():
		view.set_surface_override_material(i, source.get_surface_override_material(i))
	view.visible = source.is_visible_in_tree() if source.is_inside_tree() else source.visible
	view.set_meta(&"pod_source_mesh", source.get_instance_id())
	view.cast_shadow = source.cast_shadow
	view.layers = source.layers
	for property in source.get_property_list():
		var key: String = property.name
		if key.begins_with("instance_shader_parameters/"):
			view.set(key, source.get(key))
	# In orbit nothing has been out in the weather yet.
	if view.get_instance_shader_parameter(&"age") != null:
		view.set_instance_shader_parameter(&"age", 0.0)


func _mesh(mesh: Mesh, pose: Transform3D) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	if mesh.get_surface_count() > 0 and mesh.surface_get_material(0) is ShaderMaterial:
		view.set_instance_shader_parameter(&"age", 0.0)
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
		_mesh(PodApertureLooks.frame() if role in PodShell.VIEWPORTS else plate, pose)
		if role in PodShell.VIEWPORTS:
			for side in [-1.0, 1.0]:
				var pane := _mesh(PodApertureLooks.glass(), pose * Transform3D(Basis.IDENTITY, Vector3(0, side * 0.05, 0)))
				pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			_mesh(PodShell._armor_mesh(), pose)
