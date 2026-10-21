extends Node3D
## Look-test: the shortwave rig set up on the sand and what static does to
## it. The field radio with a shortwave converter and the kite's hook; its
## aerial lead to the earth stake's ring, the kite's line on up to the kite.
## Shots:
##   rig_day        the whole rig by day, the kite flying
##   charging       dusk, charge gathering: a corona at the hook and along
##                  the kite's dipole, a crackle of sparks
##   arc            unearthed: it arcs from the hook down into the converter
##   burnt          after: the converter burnt out, soot, smoke, its lamps dark
##   earthed        staked: the charge leaps the stake's spark gap to earth
##   storm_kite     the kite in a sandstorm, half its sail gone
##   scripts/unseen.sh --path . --resolution 960x600 res://look/radio_kit/rig.tscn -- <out dir> [filter]

const LOOKS := preload("res://look/radio_kit/radio_kit_looks.gd")

const RADIO_AT := Vector3.ZERO
const STAKE_AT := Vector3(1.3, 0.3, -0.5)
const KITE_AT := Vector3(5.0, 7.5, -12.0)

var env: Environment
var sun: DirectionalLight3D
var camera: Camera3D
var props: Node3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://radio_rig"
	var only := args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_sky_contribution = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color(0.62, 0.5, 0.35)
	sand.roughness = 1.0
	plane.material = sand
	ground.mesh = plane
	add_child(ground)
	camera = Camera3D.new()
	camera.near = 0.01
	camera.far = 300.0
	add_child(camera)
	camera.make_current()
	var shots := ["rig_day", "charging", "arc", "burnt", "earthed", "storm_kite"]
	for shot: String in shots:
		if only != "" and not shot.contains(only):
			continue
		await _shoot(shot, out)
	print("radio rig: done, %s" % out)
	get_tree().quit()


func _light(dusk: bool, storm := false) -> void:
	if storm:
		env.background_color = Color(0.62, 0.42, 0.24)
		env.ambient_light_color = Color(0.7, 0.5, 0.3)
		env.ambient_light_energy = 0.55
		env.fog_enabled = true
		env.fog_light_color = Color(0.66, 0.46, 0.27)
		env.fog_density = 0.06
		sun.light_energy = 0.25
		sun.light_color = Color(1.0, 0.7, 0.45)
		sun.look_at_from_position(Vector3.ZERO, Vector3(-0.3, -0.6, -0.5), Vector3.UP)
	elif dusk:
		env.background_color = Color(0.16, 0.13, 0.2)
		env.ambient_light_color = Color(0.35, 0.3, 0.42)
		env.ambient_light_energy = 0.35
		env.fog_enabled = false
		sun.light_energy = 0.35
		sun.light_color = Color(1.0, 0.55, 0.3)
		sun.look_at_from_position(Vector3.ZERO, Vector3(-0.9, -0.12, 0.3), Vector3.UP)
	else:
		env.background_color = Color(0.56, 0.62, 0.7)
		env.ambient_light_color = Color(0.82, 0.75, 0.66)
		env.ambient_light_energy = 0.45
		env.fog_enabled = false
		sun.light_energy = 0.95
		sun.light_color = Color(1.0, 0.94, 0.84)
		sun.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -0.8, -0.4), Vector3.UP)


func _shoot(shot: String, out: String) -> void:
	if props != null:
		props.free()
	props = Node3D.new()
	add_child(props)
	var dusk := shot in ["charging", "arc", "earthed"]
	_light(dusk, shot == "storm_kite")
	var fit := {"bay": &"sw", "hook": true, "battery": true}
	if shot == "burnt":
		fit["burnt"] = &"sw"
	var lit := shot != "burnt"
	_mesh(LOOKS.field_radio(&"company", fit, &"sw", lit), Transform3D(Basis(Vector3.UP, 0.5), RADIO_AT - Vector3(0.0, -LOOKS.FIELD.y * 0.5, 0.0)),
		0.25)
	var radio_xf := Transform3D(Basis(Vector3.UP, 0.5), RADIO_AT + Vector3(0.0, LOOKS.FIELD.y * 0.5, 0.0))
	var hook: Vector3 = radio_xf * LOOKS.HOOK_EYE
	var port: Vector3 = radio_xf * LOOKS.SW_PORT
	_mesh(LOOKS.earth_stake(shot == "earthed"), Transform3D(Basis.IDENTITY, STAKE_AT), 0.2)
	var ring: Vector3 = STAKE_AT + LOOKS.STAKE_RING
	var gap: Vector3 = STAKE_AT + LOOKS.STAKE_GAP
	var torn := 0.5 if shot == "storm_kite" else 0.0
	var kite_xf := Transform3D(Basis.looking_at(-(KITE_AT - ring).normalized(), Vector3.UP) * Basis(Vector3.RIGHT, -0.5),
		KITE_AT)
	var kite := _mesh(LOOKS.kite(0.5 if torn > 0.0 else 1.0), kite_xf, 0.5 if torn > 0.0 else 0.15)
	var cloth := (kite.mesh.surface_get_material(1) as ShaderMaterial).duplicate() as ShaderMaterial
	cloth.set_shader_parameter(&"torn", torn)
	cloth.set_shader_parameter(&"charge", 0.9 if shot in ["charging", "arc", "earthed"] else 0.0)
	cloth.set_shader_parameter(&"age", 0.6 if torn > 0.0 else 0.15)
	kite.set_surface_override_material(1, cloth)
	# The leads: insulated copper from the hook to the stake's ring; the
	# kite's line (its conductor braided in) from the ring up to the kite.
	var b := Paint.Pieces.new()
	LOOKS.lead(b, port, hook + Vector3(0.0, 0.02, 0.0), 0.04, LOOKS.coat(Color(0.12, 0.12, 0.12), 0.6), 6, 0.0025)
	LOOKS.lead(b, hook, ring, 0.25, LOOKS.coat(LOOKS.COPPER.darkened(0.3), 0.5, 0.5), 20, 0.003)
	var kite_ring: Vector3 = kite_xf * (LOOKS.KITE_RING + Vector3(0.0, -0.02, 0.0))
	LOOKS.lead(b, ring, kite_ring, 1.2, LOOKS.coat(Color(0.75, 0.7, 0.62), 0.8), 40, 0.004)
	if shot == "arc":
		# Down the lead into the converter's port, and across to the case.
		LOOKS.arc(b, hook + Vector3(0.0, 0.01, 0.0), port, 3, 0.003)
		LOOKS.arc(b, hook, radio_xf * Vector3(0.12, 0.1, 0.0), 9, 0.002)
		LOOKS.arc(b, port, radio_xf * Vector3(0.2, -0.05, 0.05), 11, 0.002)
	if shot == "earthed":
		LOOKS.arc(b, ring + Vector3(0.0, -0.03, -0.02), gap + Vector3(0.0, -0.008, -0.012), 5, 0.0018)
	_mesh(b.commit(), Transform3D.IDENTITY, 0.2)
	match shot:
		"charging":
			_corona(hook, 0.03)
			_corona(ring, 0.03)
			_omni(hook, Color(0.7, 0.62, 1.0), 0.6, 0.6)
		"arc":
			_omni(hook + Vector3(0.05, -0.05, 0.0), Color(0.85, 0.8, 1.0), 1.6, 1.2)
			_sparks(port, 80, 2.5)
			_sparks(hook, 40, 1.5)
		"burnt":
			_smoke(port + Vector3(0.0, -0.02, 0.0))
		"earthed":
			_omni(gap, Color(0.8, 0.75, 1.0), 1.2, 0.8)
			_sparks(gap, 14, 0.6)
	match shot:
		"rig_day":
			camera.fov = 62.0
			camera.look_at_from_position(Vector3(-1.3, 0.7, 1.7), Vector3(1.8, 2.4, -4.5), Vector3.UP)
		"storm_kite":
			camera.fov = 30.0
			camera.look_at_from_position(KITE_AT + Vector3(-1.0, -1.6, 4.2), KITE_AT + Vector3(0.0, -0.3, 0.0), Vector3.UP)
		"earthed":
			camera.fov = 40.0
			camera.look_at_from_position(gap + Vector3(0.28, 0.04, 0.1), gap + Vector3(0.0, -0.01, 0.0), Vector3.UP)
		"arc", "burnt":
			camera.fov = 40.0
			camera.look_at_from_position(radio_xf * Vector3(0.75, 0.25, 0.55), radio_xf * Vector3(0.12, 0.02, 0.0), Vector3.UP)
		_:
			camera.fov = 40.0
			camera.look_at_from_position(Vector3(0.3, 0.55, 0.95), Vector3(0.12, 0.17, 0.0), Vector3.UP)
	for k in 12:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, shot])
	print("radio rig: %s" % shot)


func _mesh(mesh: ArrayMesh, at: Transform3D, age: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	props.add_child(m)
	m.transform = at
	m.set_instance_shader_parameter(&"age", age)
	m.set_instance_shader_parameter(&"lit", 1.0)
	return m


func _omni(at: Vector3, color: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	props.add_child(light)
	light.position = at


## A corona: pale violet glow, crackling, round a point the charge pours from.
func _corona(at: Vector3, size: float) -> void:
	var made := CPUParticles3D.new()
	made.amount = 90
	made.lifetime = 0.2
	made.preprocess = 1.0
	made.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	made.emission_sphere_radius = size
	made.gravity = Vector3.ZERO
	made.initial_velocity_min = 0.05
	made.initial_velocity_max = 0.2
	made.direction = Vector3.UP
	made.spread = 180.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.006, 0.006)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(0.75, 0.68, 1.0, 0.9)
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	made.mesh = quad
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_color(1, Color(0.6, 0.5, 1.0, 0.0))
	made.color_ramp = fade
	props.add_child(made)
	made.position = at
	made.emitting = true


func _sparks(at: Vector3, count: int, speed: float) -> void:
	var made := ScrapFx.sparks()
	made.amount = count
	made.lifetime = 0.4
	made.preprocess = 0.15
	made.direction = Vector3.UP
	made.spread = 180.0
	made.initial_velocity_min = speed * 0.4
	made.initial_velocity_max = speed
	props.add_child(made)
	made.position = at
	made.emitting = true


func _smoke(at: Vector3) -> void:
	var made := CPUParticles3D.new()
	made.amount = 30
	made.lifetime = 3.0
	made.preprocess = 3.0
	made.gravity = Vector3(0.05, 0.25, 0.0)
	made.initial_velocity_min = 0.02
	made.initial_velocity_max = 0.08
	made.direction = Vector3.UP
	made.spread = 25.0
	made.scale_amount_min = 1.0
	made.scale_amount_max = 3.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.04, 0.04)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	made.mesh = quad
	var fade := Gradient.new()
	fade.set_color(0, Color(0.15, 0.14, 0.13, 0.7))
	fade.set_color(1, Color(0.3, 0.28, 0.26, 0.0))
	made.color_ramp = fade
	props.add_child(made)
	made.position = at
	made.emitting = true
