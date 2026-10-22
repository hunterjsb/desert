class_name ArrivalView
extends CanvasLayer
## A disposable presentation over the preloading world; the arrival controller owns time.
var _world: World
var _root := Control.new()
var _screen := SubViewportContainer.new()
var _viewport := SubViewport.new()
var _orbit := ArrivalOrbit.new()
var _interior: PodInterior
var _effects := ArrivalImpactEffects.new()
var _seat_eye: Transform3D
var _ground_camera_base: Transform3D
var _ground_camera_active := false
var _voice := AudioStreamPlayer.new()
var _impact_roll := AudioStreamPlayer.new()
var _heard_phase: StringName
var _has_phase := false
var _state: Dictionary
var _air := AudioStreamPlayer.new()
var _hull := AudioStreamPlayer.new()

func setup(world: World) -> void:
	_world = world
	_voice.bus = Sounds.WORLD
	add_child(_voice)
	_impact_roll.bus = Sounds.WORLD
	add_child(_impact_roll)
	_air.bus = Sounds.WORLD
	_air.stream = Sounds.WIND.duplicate()
	(_air.stream as AudioStreamOggVorbis).loop = true
	add_child(_air)
	_hull.bus = Sounds.WORLD
	var hull := Sounds.BOARD_RUSH.duplicate() as AudioStreamWAV
	hull.loop_mode = AudioStreamWAV.LOOP_FORWARD
	hull.loop_end = roundi(hull.get_length() * hull.mix_rate)
	_hull.stream = hull
	add_child(_hull)
	# Cover the suit and HUD, while system menus and console remain above flight.
	layer = 100
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.stretch = true
	_root.add_child(_screen)
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport.own_world_3d = true
	_viewport.gui_disable_input = true
	_viewport.handle_input_locally = false
	_viewport.size = Vector2i(get_viewport().get_visible_rect().size)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_screen.add_child(_viewport)
	_viewport.add_child(_orbit)
	_orbit.setup(world.shape.history, world.weather.day)
	_orbit.camera.fov = world.player.camera.fov
	_seat_eye = PodShell.seat_pose() * Transform3D(Basis(Vector3.RIGHT, 0.1),
		Vector3(0, float(world.tuning.surveyor_preflight.seat_eye_m), 0))
	_interior = PodShell.flight_interior(world.arrival_nodes)
	# The shell stays fixed while the saved recoil moves the eye inside it.
	_orbit.camera.add_child(_interior)
	_interior.transform = _seat_eye.affine_inverse()
	_root.add_child(_effects)
	_effects.setup(world.tuning)

func present(state: Dictionary) -> void:
	if not is_instance_valid(_world):
		return
	_state = state
	var phase: StringName = state.get("phase", &"orbit")
	var seconds := float(state.get("elapsed", 0.0))
	var duration := maxf(float(state.get("phase_seconds", 1.0)), 0.001)
	var progress := clampf(float(state.get("progress", seconds / duration)), 0.0, 1.0)
	_phase_audio(phase, progress)
	_air_audio(phase, progress)
	_root.visible = phase != &"recovery"
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if phase in [&"landing", &"recovery"] else SubViewport.UPDATE_ALWAYS
	_screen.visible = phase not in [&"landing", &"recovery"]
	if phase == &"recovery":
		return
	_orbit.update_light(_world.time)
	var point: Vector3 = state.get("landing_point", Sphere.point(_world.moon.latitude, _world.moon.longitude))
	var heading := float(state.get("heading", 0.0))
	var descent := 0.0
	match phase:
		&"orbit": descent = lerpf(0.0, 0.04, progress)
		&"ejection": descent = lerpf(0.04, 0.12, progress)
		&"descent": descent = lerpf(0.12, 0.92, smoothstep(0.0, 1.0, progress))
		&"entry", &"landing": descent = lerpf(0.92, 1.0, progress)
	var altitude := lerpf(0.65, 0.0012, descent)
	var angular_offset := deg_to_rad(lerpf(28.0, 0.1, descent))
	var direction := Sphere.toward(point, -heading + PI, angular_offset)
	_orbit.camera.position = direction * ArrivalOrbit.RADIUS * (1.0 + altitude)
	_orbit.camera.look_at(point * ArrivalOrbit.RADIUS, Sphere.north(direction))
	var flight: Dictionary = state.get("preflight", {}).get("flight_sample", {})
	if flight.has("path") and flight.path.size() > 1:
		var path: PackedVector3Array = flight.path
		var elapsed := float(state.get("flight_elapsed", 0.0))
		var t := clampf(elapsed / maxf(float(flight.flight_s), 0.001), 0.0, 1.0)
		var times: PackedFloat32Array = flight.get("path_times", PackedFloat32Array())
		var i := 0
		var fraction := t * (path.size() - 1)
		if times.size() == path.size():
			while i < times.size() - 2 and times[i + 1] < elapsed:
				i += 1
			fraction = clampf((elapsed - times[i]) / maxf(times[i + 1] - times[i], 0.000001), 0.0, 1.0)
		else:
			i = mini(floori(fraction), path.size() - 2)
			fraction -= i
		var position := path[i].lerp(path[i + 1], fraction)
		var clock := float(state.preflight.departure_time) + elapsed
		var turn := Basis(Vector3(0, 0, 1), TAU * elapsed / (_world.tuning.day_minutes * 60.0))
		var body: Basis = turn * (flight.body_basis as Basis)
		var local := body.inverse() * position
		_orbit.camera.position = local * ArrivalOrbit.RADIUS
		var radial := local.normalized()
		var forward: Vector3 = flight.get("landing_forward", Sphere.north(point) * cos(heading) + Sphere.east(point) * sin(heading))
		forward = forward.slide(radial).normalized()
		var limb := asin(clampf(1.0 / maxf(local.length(), 1.000001), 0.0, 1.0))
		var level := smoothstep(0.0, 1.0, progress) if phase == &"entry" else 0.0
		var angle := lerpf(limb - deg_to_rad(float(_world.tuning.surveyor_arrival.flight_limb_below_deg)), PI * 0.5 + 0.1, level)
		var aim := -radial * cos(angle) + forward * sin(angle)
		_orbit.camera.look_at(_orbit.camera.position + aim, radial)
		_orbit.update_light(clock)
	# Effects are pure saved-time samples; computing the window twice triggers no events.
	_effects.present(state, Rect2())
	var recoil := Transform3D(Basis.from_euler(_effects.camera_rotation), _effects.camera_offset)
	var angles := head_angles()
	var head := Transform3D(Basis(Vector3.UP, angles.x) * Basis(Vector3.RIGHT, angles.y), Vector3.ZERO)
	if phase == &"landing":
		var camera := _world.player.camera
		if not _ground_camera_active:
			_ground_camera_base = camera.transform
			_ground_camera_active = true
		camera.transform = _ground_camera_base * head * recoil
		var tail := _world.arrival_nodes.get(&"tail") as Chassis
		var intact := is_instance_valid(tail) and tail.deck != null
		if intact:
			_present_windows(state, camera, _ground_pod_pose())
		else:
			_effects.present(state, Rect2(Vector2.ZERO, Vector2.ONE))
	else:
		var base := _orbit.camera.transform
		_orbit.camera.transform = base * head * recoil
		_interior.transform = (head * recoil).affine_inverse() * _seat_eye.affine_inverse()
		_present_windows(state, _orbit.camera, base * _seat_eye.affine_inverse())


func head_angles() -> Vector2:
	var angles: Vector2 = _state.get("head_look", Vector2.ZERO)
	if not angles.is_finite():
		return Vector2.ZERO
	var rules := _world.tuning.surveyor_arrival
	return Vector2(clampf(angles.x, -deg_to_rad(rules.head_yaw_deg), deg_to_rad(rules.head_yaw_deg)),
		clampf(angles.y, -deg_to_rad(rules.head_pitch_deg), deg_to_rad(rules.head_pitch_deg)))


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_world) or not Controls.playing() or Controls.mouse_free \
		or not event is InputEventMouseMotion or not _state.get("phase", &"") in [&"orbit", &"ejection", &"descent", &"entry", &"landing"]:
		return
	var angles: Vector2 = head_angles() - event.relative * _world.tuning.mouse_sensitivity
	_state.head_look = angles
	_state.head_look = head_angles()
	get_viewport().set_input_as_handled()


func _present_windows(state: Dictionary, camera: Camera3D, pod_pose: Transform3D) -> void:
	var windows: Array[Rect2] = []
	var points := PackedVector2Array()
	for role: StringName in PodShell.VIEWPORTS:
		if not _world.arrival_nodes.is_empty() and not is_instance_valid(_world.arrival_nodes.get(role)):
			continue
		var cell: Vector2i = PodShell.PANELS[role][0]
		var face: Array = Frame.FACES[PodShell.PANELS[role][1]]
		var frame := Transform3D(Basis.IDENTITY, Vector3(cell.x, 0, cell.y)) * Chassis.FACES[Chassis.TOP]
		var panel := pod_pose * frame * Transform3D(Catalog._facing(face[1]), face[0]) * Frame.piece_seat()
		var actual := _world.arrival_nodes.get(role) as Chassis
		var floor := _world.arrival_nodes.get(&"floor_a") as Chassis
		if is_instance_valid(actual) and is_instance_valid(floor):
			var root := floor.deck if floor.deck != null else floor
			var owner := actual.deck if actual.deck != null else actual
			var physical_pod := root.global_transform * floor.pose()
			panel = pod_pose * physical_pod.affine_inverse() * owner.global_transform * actual.pose()
		var corners := PackedVector2Array()
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var point := panel * Vector3(corner.x * PodApertureLooks.OPENING.x * 0.5, 0, corner.y * PodApertureLooks.OPENING.y * 0.5)
			if camera.is_position_behind(point):
				corners.clear()
				break
			var pixel := camera.unproject_position(point) / Vector2(camera.get_viewport().get_visible_rect().size)
			corners.append(pixel)
			low = low.min(pixel)
			high = high.max(pixel)
		if corners.size() == 4:
			windows.append(Rect2(low, high - low))
			points.append_array(corners)
	_effects.present(state, _aperture(camera, pod_pose), windows, points)


func _ground_pod_pose() -> Transform3D:
	var floor := _world.arrival_nodes.get(&"floor_a") as Chassis
	if not is_instance_valid(floor):
		return _world.player.global_transform * PodShell.seat_pose().affine_inverse()
	var root := floor.deck if floor.deck != null else floor
	return root.global_transform * floor.pose()


func _aperture(camera: Camera3D, pod_pose: Transform3D) -> Rect2:
	var pose := pod_pose * PodShell.view_aperture_pose()
	var half := PodShell.view_aperture_size() * 0.5
	var screen_size := Vector2(camera.get_viewport().get_visible_rect().size)
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			var point := pose * Vector3(x * half.x, y * half.y, 0)
			if camera.is_position_behind(point):
				return Rect2()
			var pixel := camera.unproject_position(point) / screen_size
			low = low.min(pixel)
			high = high.max(pixel)
	return Rect2(low, high - low)

## The successful launch action owns this one-shot; constructing a restored view does not.
func launch_sound() -> void:
	if not is_instance_valid(_world):
		return
	_voice.stream = Sounds.BOARD_POP
	_voice.volume_db = float(_world.tuning.surveyor_arrival.ejection_db)
	_voice.play()


## First presentation may resume mid-flight; only a later actual transition sounds.
func _phase_audio(phase: StringName, progress: float) -> void:
	var changed := _has_phase and phase != _heard_phase
	_heard_phase = phase
	_has_phase = true
	var settings := _world.tuning.surveyor_arrival
	if changed:
		_voice.stop()
		var stream: AudioStream
		match phase:
			&"ejection": launch_sound()
			&"landing": stream = Sounds.BOARD_SLAM
		if stream != null:
			_voice.stream = stream
			_voice.volume_db = float(settings.get(str(phase) + "_db", 0.0))
			_voice.play()
		if phase == &"landing":
			_impact_roll.stream = Sounds.BOOM
			_impact_roll.volume_db = float(settings.get("impact_roll_db", -16.0))
			_impact_roll.play()
	if phase == &"landing" and _impact_roll.playing:
		var fade := 1.0 - smoothstep(0.35, 1.0, progress)
		_impact_roll.volume_db = float(settings.get("impact_roll_db", -16.0)) + linear_to_db(maxf(fade, 0.00001))


func _air_audio(phase: StringName, progress: float) -> void:
	var weight := 0.0
	var rules := _world.tuning.surveyor_arrival
	match phase:
		&"ejection": weight = smoothstep(0.0, 1.0, progress) * float(rules.flight_air_ejection)
		&"descent": weight = lerpf(rules.flight_air_ejection, rules.flight_air_descent, progress)
		&"entry": weight = lerpf(rules.flight_air_descent, 1.0, smoothstep(0.0, rules.flight_air_entry_peak, progress))
		&"landing": weight = 1.0 - smoothstep(0.0, rules.flight_air_impact_fade, progress)
	for bed: AudioStreamPlayer in [_air, _hull]:
		if weight <= 0.0:
			bed.stop()
		else:
			bed.volume_db = float(rules.flight_air_db if bed == _air else rules.flight_hull_db) + linear_to_db(weight)
			bed.pitch_scale = lerpf(rules.flight_audio_pitch.x, rules.flight_audio_pitch.y, weight)
			if not bed.playing:
				bed.play()


func dispose() -> void:
	_air.stop()
	_hull.stop()
	_voice.stop()
	_voice.stream = null
	_impact_roll.stop()
	_impact_roll.stream = null
	if _ground_camera_active and is_instance_valid(_world) and is_instance_valid(_world.player) \
		and is_instance_valid(_world.player.camera):
		_world.player.camera.transform = _ground_camera_base * Transform3D(Basis(Vector3.UP, head_angles().x) * Basis(Vector3.RIGHT, head_angles().y), Vector3.ZERO)
		var yaw := _world.player.camera.rotation.y
		_world.player.rotate_y(yaw)
		_world.player.camera.rotation.y = 0.0
	_ground_camera_active = false
	_world = null
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_root.hide()
	queue_free()
