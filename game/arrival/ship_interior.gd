class_name SurveyorShip
extends Node3D
## One disposable room in the actual landing World. Arrival owns its time, inputs and cargo.

var world: World
var spawn_at: Marker3D
var window_at: Marker3D
var computer_at: Marker3D
var pod_entry_at: Marker3D
var pod_seat_at: Marker3D
var computer_body: StaticBody3D
var pod: Rig
## Both bounds are ship-local; pod_pose also maps pod-local coordinates into this room.
var pod_pose := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.4, 0.18, 0.3))
var cargo_bounds: AABB
var rack_bounds := AABB(Vector3(-2.85, 0.23, -0.35), Vector3(0.78, 1.82, 1.9))
var rack_slots: Array[Marker3D] = []
var shelf_poses: Array[Transform3D] = []
var pod_parts: Dictionary:
	get: return pod.named if pod != null else {}
var orbit_viewport: SubViewport
var orbit: ArrivalOrbit
var _orbital_origin := Vector3.ZERO
var _orbital_basis := Basis.IDENTITY


func setup(in_world: World, pose: Transform3D, build_pod := true) -> void:
	world = in_world
	global_transform = pose
	var view := MeshInstance3D.new()
	view.mesh = ShipLooks.mesh()
	add_child(view)
	view.set_instance_shader_parameter(&"age", 0.18)
	view.set_instance_shader_parameter(&"lit", 1.0)
	var hull := StaticBody3D.new()
	hull.name = "CabinHull"
	hull.collision_layer = 1
	hull.collision_mask = 0
	add_child(hull)
	for item: Array in ShipLooks.boxes():
		_box(hull, item[0], Transform3D(item[2], item[1]))
	# The sealed observation aperture is solid glass even though its image is orbital.
	_box(hull, Vector3(ShipLooks.WINDOW_SIZE.x, ShipLooks.WINDOW_SIZE.y, 0.035), Transform3D(Basis.IDENTITY, ShipLooks.WINDOW_AT))
	spawn_at = _marker("Spawn", Vector3(-0.8, 0.02, 1.6))
	window_at = _marker("Window", ShipLooks.WINDOW_AT)
	computer_at = _marker("Computer", computer_screen_pose().origin + ShipLooks.COMPUTER_TILT.z * 0.03)
	computer_body = StaticBody3D.new()
	computer_body.name = "LaunchComputer"
	computer_body.set_meta(&"ship_computer", true)
	computer_body.collision_layer = 1
	computer_body.collision_mask = 0
	add_child(computer_body)
	_box(computer_body, ShipLooks.COMPUTER_SIZE,
		Transform3D(ShipLooks.COMPUTER_TILT, ShipLooks.COMPUTER_AT))
	pod_entry_at = _marker("PodEntry", Vector3(1.4, 0.02, 1.7))
	pod_seat_at = _marker("PodSeat", Vector3(1.4, 0.25, -0.2))
	cargo_bounds = pod_pose * AABB(Vector3(-0.4, Chassis.THICK * 0.5, -0.4), Vector3(1.8, 0.92 - Chassis.THICK * 0.5, 0.8))
	for y in [0.24, 1.11]:
		for z in [-0.05, 0.6, 1.25]:
			var slot := _marker("RackSlot%d" % rack_slots.size(), Vector3(-2.45, y, z))
			rack_slots.append(slot)
			shelf_poses.append(slot.transform)
	if build_pod:
		construct_pod()
	for at in [Vector3(-2.1, 2.6, -2.5), Vector3(1.8, 2.6, 0.2), Vector3(-1.7, 2.6, 1.8)]:
		var light := OmniLight3D.new()
		light.position = at
		light.light_color = Color(0.9, 0.94, 1.0)
		light.light_energy = 1.4
		light.omni_range = 5.0
		light.shadow_enabled = true
		add_child(light)
	_bay_sign()
	_window()
	set_view(Sphere.point(world.moon.latitude, world.moon.longitude))


## Physical catalog bodies remain ordinary saveable content, separate from this disposable room.
func construct_pod() -> void:
	pod = PodShell.build(world.content, global_transform * pod_pose)
	pod.deck.freeze = true
	var index := 0
	for role: StringName in [&"roof_a", &"roof_b", &"hatch"]:
		var panel := pod.deck.detach(pod.named[role])
		panel.freeze = true
		panel.global_transform = global_transform * Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
			Vector3(-0.65 + index * 1.2, 0.66, 2.7))
		index += 1


## The controller may point the real orbital renderer at its currently selected geography.
func set_view(point: Vector3, heading := 0.0) -> void:
	var direction := Sphere.toward(point, -heading + PI, deg_to_rad(42.0))
	_orbital_origin = direction * ArrivalOrbit.RADIUS * 1.65
	_orbital_basis = Basis.looking_at(point * ArrivalOrbit.RADIUS - _orbital_origin, Sphere.north(direction))


func _process(_delta: float) -> void:
	if not is_instance_valid(world) or not is_instance_valid(orbit):
		return
	orbit.update_light(world.time)
	var eye := to_local(world.player.camera.global_position)
	var distance := maxf(eye.z - window_at.position.z, 0.05)
	var offset := Vector2(-eye.x, window_at.position.y - eye.y)
	orbit.camera.transform = Transform3D(_orbital_basis,
		_orbital_origin + _orbital_basis * Vector3(eye.x, eye.y - window_at.position.y, distance))
	# The near plane is the actual aperture: walking past it changes the sightline, not its texture.
	orbit.camera.set_frustum(ShipLooks.WINDOW_SIZE.y, offset, distance, ArrivalOrbit.RADIUS * 10.0)


func _window() -> void:
	orbit_viewport = SubViewport.new()
	orbit_viewport.name = "OrbitalWindow"
	orbit_viewport.own_world_3d = true
	orbit_viewport.gui_disable_input = true
	orbit_viewport.handle_input_locally = false
	orbit_viewport.size = Vector2i(1380, 684)
	orbit_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(orbit_viewport)
	orbit = ArrivalOrbit.new()
	orbit_viewport.add_child(orbit)
	orbit.setup(world.shape.history, world.weather.day)
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = ShipLooks.WINDOW_SIZE
	screen.mesh = quad
	screen.position = ShipLooks.WINDOW_AT + Vector3(0, 0, 0.02)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = orbit_viewport.get_texture()
	screen.material_override = material
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(screen)


func _marker(label: String, at: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = label
	marker.position = at
	add_child(marker)
	return marker


static func _box(body: StaticBody3D, size: Vector3, pose: Transform3D) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.transform = pose
	body.add_child(shape)


func computer_screen_pose() -> Transform3D:
	return Transform3D(ShipLooks.COMPUTER_TILT, ShipLooks.COMPUTER_AT) * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.089))


func computer_screen_size() -> Vector2:
	return ShipLooks.DISPLAY_SIZE


func computer_focus_pose() -> Transform3D:
	var screen := computer_screen_pose()
	return Transform3D(Basis.looking_at(-screen.basis.z, Vector3.UP), screen.origin + screen.basis.z * 0.72)


func _bay_sign() -> void:
	var label := Label3D.new()
	label.text = "POD BAY"
	label.font = ThemeDB.fallback_font
	label.font_size = 48
	label.pixel_size = 0.0018
	label.position = Vector3(1.4, 2.55, 2.99)
	label.rotation.y = PI
	label.modulate = Paint.BONE
	label.outline_size = 0
	label.no_depth_test = false
	add_child(label)
