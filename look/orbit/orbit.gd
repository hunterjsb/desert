extends Node3D
## Orbital art prototype: real seeded rift placement, illustrative regional albedo.
const RUN_SEED := 1234
const RADIUS := 1000.0
var history: History

func _ready() -> void:
	Dev.hide_overlays()
	var tuning := Tuning.current()
	history = History.new(RUN_SEED, tuning)
	var day := DayCycle.new(tuning)
	var time := tuning.day_minutes * 60.0 * 0.31
	var local_sun := day.sun_direction(time, 0.0, 0.0)
	var sun := Vector3(local_sun.y, local_sun.x, -local_sun.z)
	var camera := Camera3D.new()
	camera.far = 10000.0
	camera.near = 0.1
	camera.fov = 60.0
	var direction := Sphere.point(deg_to_rad(-30.0), deg_to_rad(30.0))
	camera.position = direction * RADIUS * 1.65
	add_child(camera)
	camera.look_at(Sphere.north(direction) * RADIUS * 0.65, Sphere.north(direction))
	var material := ShaderMaterial.new()
	material.shader = preload("res://look/orbit/surface.gdshader")
	material.set_shader_parameter(&"sun_direction", sun)
	var rng := RandomNumberGenerator.new()
	rng.seed = RUN_SEED
	material.set_shader_parameter(&"seed_offset", Vector3(rng.randf(), rng.randf(), rng.randf()) * 80.0)
	var rift := PackedVector3Array()
	for i in 32:
		rift.append(history.geology.rift[roundi(float(i) * (history.geology.rift.size() - 1) / 31.0)])
	material.set_shader_parameter(&"rift", rift)
	material.set_shader_parameter(&"rift_count", mini(history.geology.rift.size(), 32))
	_sphere(RADIUS, material)
	var air := ShaderMaterial.new()
	air.shader = preload("res://look/orbit/limb.gdshader")
	air.set_shader_parameter(&"sun_direction", sun)
	_sphere(RADIUS * 1.012, air)
	var sky_material := ShaderMaterial.new()
	sky_material.shader = preload("res://look/orbit/space.gdshader")
	sky_material.set_shader_parameter(&"sun_direction", sun)
	sky_material.set_shader_parameter(&"tu_direction", day.sub_tu(time))
	sky_material.set_shader_parameter(&"tu_radius", day.tu_radius())
	sky_material.set_shader_parameter(&"tu_spin", day.tu_turn(time))
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.sky = sky
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	if not OS.get_cmdline_user_args().is_empty():
		var destination := OS.get_cmdline_user_args()[-1]
		for i in 12:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(destination)
		print("Orbital prototype: seed=%d rift_points=%d, regional albedo illustrative; no descent implemented" % [RUN_SEED, history.geology.rift.size()])
		get_tree().quit()

func _sphere(radius: float, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 256
	mesh.rings = 128
	var instance := MeshInstance3D.new()
	print("Orbit mesh radius=%.0f triangles=%d" % [radius, mesh.get_faces().size() / 3])
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
