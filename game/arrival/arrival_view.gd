class_name ArrivalView
extends CanvasLayer
## A disposable presentation over the preloading world; the arrival controller owns time.
var _world: World
var _root := Control.new()
var _screen := SubViewportContainer.new()
var _viewport := SubViewport.new()
var _orbit := ArrivalOrbit.new()
var _dust := ColorRect.new()
var _dust_material := ShaderMaterial.new()
var _pod := MeshInstance3D.new()
static var _pod_mesh: ArrayMesh

func setup(world: World) -> void:
	_world = world
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
	_pod.mesh = _proxy_mesh()
	_orbit.camera.add_child(_pod)
	_dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dust_material.shader = preload("res://game/arrival/orbit/entry_dust.gdshader")
	_dust.material = _dust_material
	_root.add_child(_dust)
	_dust.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func present(state: Dictionary) -> void:
	if _world == null:
		return
	var phase: StringName = state.get("phase", &"orbit")
	var seconds := float(state.get("elapsed", 0.0))
	var duration := maxf(float(state.get("phase_seconds", 1.0)), 0.001)
	var progress := clampf(float(state.get("progress", seconds / duration)), 0.0, 1.0)
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
	# The exterior view follows the opaque real shell, without a fictional cockpit window.
	_pod.position = Vector3(0.75, -0.25, lerpf(-3.8, -5.5, smoothstep(0.0, 1.0, progress)) if phase == &"ejection" else -5.5)
	_pod.rotation = Vector3(0.12, -0.42, -0.14 + sin(descent * PI) * 0.06)
	_pod.visible = phase in [&"orbit", &"ejection", &"descent", &"entry"]
	var entry := smoothstep(0.1, 0.85, progress) if phase == &"entry" else 1.0 if phase == &"landing" else 0.0
	_dust_material.set_shader_parameter(&"strength", entry)
	_dust_material.set_shader_parameter(&"passage", seconds)
	_dust.modulate.a = 1.0 - smoothstep(0.0, 0.85, progress) if phase == &"landing" else 1.0

func dispose() -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_root.hide()
	queue_free()

## Mesh-only proxy: no physics, recovery roles or second set of equipment.
static func _proxy_mesh() -> ArrayMesh:
	if _pod_mesh != null:
		return _pod_mesh
	var b := Paint.Pieces.new(-0.6)
	var bone := Paint.coat(Paint.BONE, 0.05, 0.75)
	var teal := Paint.coat(Paint.TEAL)
	var gun := Paint.coat(Paint.GUNMETAL)
	var black := Paint.coat(Paint.BLACK)
	var yellow := Paint.coat(Paint.YELLOW)
	for x in [-0.5, 0.5]:
		b.box(Vector3(0.95, 0.10, 0.95), Vector3(x, -0.5, 0), black, 0.025)
		b.box(Vector3(0.95, 0.10, 0.95), Vector3(x, 0.5, 0), bone, 0.025)
		b.box(Vector3(0.18, 0.015, 0.78), Vector3(x + 0.22, 0.557, 0), teal, 0.006)
		for z in [-0.5, 0.5]:
			b.box(Vector3(0.95, 0.95, 0.10), Vector3(x, 0, z), bone, 0.025)
			b.box(Vector3(0.18, 0.72, 0.015), Vector3(x + 0.22, 0, z * 1.115), teal, 0.006)
	for x in [-1.0, 0.0, 1.0]:
		for z in [-0.54, 0.54]:
			b.box(Vector3(0.055, 1.09, 0.055), Vector3(x, 0, z), gun, 0.009)
			for y in [-0.42, 0.42]:
				b.box(Vector3(0.08, 0.10, 0.025), Vector3(x, y, z * 1.04), yellow, 0.006)
	for x in [-1.0, 1.0]:
		b.box(Vector3(0.10, 0.95, 0.95), Vector3(x, 0, 0), bone, 0.025)
		b.box(Vector3(0.015, 0.68, 0.20), Vector3(x * 1.057, 0, 0.22), teal, 0.006)
	_pod_mesh = b.commit()
	return _pod_mesh
