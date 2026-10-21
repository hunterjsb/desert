class_name ArrivalOrbit
extends Node3D
## Zan's orbital proxy shares seeded geology and illumination with the landing world.
## Regional albedo is illustrative; this mesh is not the local collision surface.
const RADIUS := 1000.0
var camera := Camera3D.new()
var _surface := ShaderMaterial.new()
var _air := ShaderMaterial.new()
var _space := ShaderMaterial.new()
var _sun := DirectionalLight3D.new()
var _day: DayCycle

func setup(history: History, day: DayCycle) -> void:
	_day = day
	camera.far = RADIUS * 10.0
	camera.near = 0.05
	camera.fov = 60.0
	add_child(camera)
	_surface.shader = preload("res://game/arrival/orbit/surface.gdshader")
	var rng := RandomNumberGenerator.new()
	rng.seed = history.run_seed
	_surface.set_shader_parameter(&"seed_offset", Vector3(rng.randf(), rng.randf(), rng.randf()) * 80.0)
	var rift := PackedVector3Array()
	var count := mini(history.geology.rift.size(), 32)
	for i in count:
		rift.append(history.geology.rift[roundi(float(i) * (history.geology.rift.size() - 1) / maxi(count - 1, 1))])
	_surface.set_shader_parameter(&"rift", rift)
	_surface.set_shader_parameter(&"rift_count", count)
	_sphere(RADIUS, _surface)
	_air.shader = preload("res://game/arrival/orbit/limb.gdshader")
	_sphere(RADIUS * 1.012, _air)
	_space.shader = preload("res://game/arrival/orbit/space.gdshader")
	var sky := Sky.new()
	sky.sky_material = _space
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.sky = sky
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.4, 0.34, 0.27)
	environment.environment.ambient_light_energy = 0.12
	add_child(environment)
	_sun.light_energy = 1.2
	add_child(_sun)
	update_light(0.0)

func update_light(time: float) -> void:
	var sun := _day.sun_toward(time)
	_surface.set_shader_parameter(&"sun_direction", sun)
	_air.set_shader_parameter(&"sun_direction", sun)
	_space.set_shader_parameter(&"sun_direction", sun)
	_space.set_shader_parameter(&"tu_direction", _day.sub_tu(time))
	_space.set_shader_parameter(&"tu_radius", _day.tu_radius())
	_space.set_shader_parameter(&"tu_spin", _day.tu_turn(time))
	_sun.look_at(-sun, Vector3(0, 0, 1))

func _sphere(radius: float, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 256
	mesh.rings = 128
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)
