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
var _heard_phase: StringName
var _has_phase := false

func setup(world: World) -> void:
	_world = world
	_voice.bus = Sounds.WORLD
	add_child(_voice)
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
	var phase: StringName = state.get("phase", &"orbit")
	var seconds := float(state.get("elapsed", 0.0))
	var duration := maxf(float(state.get("phase_seconds", 1.0)), 0.001)
	var progress := clampf(float(state.get("progress", seconds / duration)), 0.0, 1.0)
	_phase_audio(phase, progress)
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
		var index := t * (path.size() - 1)
		var i := mini(floori(index), path.size() - 2)
		var position := path[i].lerp(path[i + 1], index - i)
		var clock := float(state.preflight.departure_time) + elapsed
		var turn := Basis(Vector3(0, 0, 1), TAU * elapsed / (_world.tuning.day_minutes * 60.0))
		var body: Basis = turn * (flight.body_basis as Basis)
		var local := body.inverse() * position
		_orbit.camera.position = local * ArrivalOrbit.RADIUS
		var north := Sphere.north(local.normalized())
		var forward := Sphere.north(point) * cos(heading) + Sphere.east(point) * sin(heading)
		var approaching := (point * ArrivalOrbit.RADIUS - _orbit.camera.position).normalized()
		var level := smoothstep(0.4, 1.0, progress) if phase == &"entry" else 0.0
		var radial := local.normalized()
		var level_aim := forward * cos(0.1) + radial * sin(0.1)
		var aim := approaching.slerp(level_aim, level).normalized()
		var up := north.slerp(radial, level).normalized()
		_orbit.camera.look_at(_orbit.camera.position + aim, up if absf(aim.dot(up)) < 0.99 else Sphere.east(local.normalized()))
		_orbit.update_light(clock)
	# Effects are pure saved-time samples; computing the window twice triggers no events.
	_effects.present(state, Rect2())
	var recoil := Transform3D(Basis.from_euler(_effects.camera_rotation), _effects.camera_offset)
	if phase == &"landing":
		var camera := _world.player.camera
		if not _ground_camera_active:
			_ground_camera_base = camera.transform
			_ground_camera_active = true
		camera.transform = _ground_camera_base * recoil
		_effects.present(state, _aperture(camera, _ground_pod_pose()))
	else:
		var base := _orbit.camera.transform
		_orbit.camera.transform = base * recoil
		_interior.transform = recoil.affine_inverse() * _seat_eye.affine_inverse()
		_effects.present(state, _aperture(_orbit.camera, base * _seat_eye.affine_inverse()))


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
			&"ejection": stream = Sounds.UNSEAT
			&"entry": stream = Sounds.BOARD_RUSH
			&"landing": stream = Sounds.LANDING
		if stream != null:
			_voice.stream = stream
			_voice.volume_db = float(settings.get(str(phase) + "_db", 0.0))
			_voice.play()
	if phase == &"entry" and _voice.playing:
		var envelope := smoothstep(0.0, 0.15, progress) * (1.0 - smoothstep(0.8, 1.0, progress))
		_voice.volume_db = float(settings.get("entry_db", 0.0)) + linear_to_db(maxf(envelope, 0.001))


func dispose() -> void:
	_voice.stop()
	_voice.stream = null
	if _ground_camera_active and is_instance_valid(_world) and is_instance_valid(_world.player) \
		and is_instance_valid(_world.player.camera):
		_world.player.camera.transform = _ground_camera_base
	_ground_camera_active = false
	_world = null
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_root.hide()
	queue_free()
