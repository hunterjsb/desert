extends Node3D
## Look-test: the radio equipment proposals (radio_kit_looks.gd), one tile
## each on a sand-coloured ground, framed to fit, lit by a high warm sun.
## Saves <out>/<name>.png per shot; `-- <out> <filter>` shoots only the names
## holding filter.
##   scripts/unseen.sh --path . --resolution 640x480 res://look/radio_kit/studio.tscn -- <out dir> [filter]

const LOOKS := preload("res://look/radio_kit/radio_kit_looks.gd")

var sun: DirectionalLight3D
var camera: Camera3D
var view: MeshInstance3D
var floor_mesh: MeshInstance3D


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://radio_kit"
	var only := args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.56, 0.6, 0.66)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.75, 0.66)
	env.ambient_light_energy = 0.45
	env.ambient_light_sky_contribution = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = false
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 1.3
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.94, 0.84)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 12.0
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -0.8, -0.4), Vector3.UP)
	view = MeshInstance3D.new()
	add_child(view)
	floor_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color(0.62, 0.5, 0.35)
	sand.roughness = 1.0
	plane.material = sand
	floor_mesh.mesh = plane
	add_child(floor_mesh)
	camera = Camera3D.new()
	camera.fov = 30.0
	camera.near = 0.005
	add_child(camera)
	camera.make_current()
	var shots := _shots()
	var n := 0
	for shot: Array in shots:
		if only != "" and not String(shot[0]).contains(only):
			continue
		await _shoot(shot, out)
		n += 1
	print("radio kit studio: saved %d shots to %s" % [n, out])
	get_tree().quit()


## [name, mesh, camera direction from it, age, zoom (1 fits it)]
func _shots() -> Array:
	var three := Vector3(0.55, 0.35, 1.0)
	var front := Vector3(0.0, 0.08, 1.0)
	var back := Vector3(-0.7, 0.45, -0.8)
	var list := [
		["tier0_crystal_scrap", LOOKS.crystal_set(&"scrap"), Vector3(0.4, 0.8, 0.9), 0.5, 1.0],
		["tier0_crystal_second_age", LOOKS.crystal_set(&"second_age"), Vector3(0.4, 0.8, 0.9), 0.4, 1.0],
		["tier1_company_am", LOOKS.field_radio(&"company", {}, &"am"), three, 0.3, 1.3],
		["tier1_colonial_fm", LOOKS.field_radio(&"colonial", {"bay": &"fm"}, &"fm"), three, 0.15, 1.3],
		["tier1_skimmer_sw", LOOKS.field_radio(&"skimmer", {"bay": &"sw", "hook": true}, &"sw"), three, 0.45, 1.3],
		["tier1_kingdoms_loop", LOOKS.field_radio(&"kingdoms", {"bay": &"fm", "misc": &"loop"}, &"fm"), three, 0.1, 1.3],
		["tier1_second_age", LOOKS.field_radio(&"second_age", {"misc": &"headset"}, &"am"), three, 0.35, 1.3],
		["tier1_full_kit_back", LOOKS.field_radio(&"company", {"bay": &"sw", "misc": &"bleed", "hook": true, "battery": true},
			&"sw"), back, 0.25, 1.3],
		["tier1_full_kit_front", LOOKS.field_radio(&"company", {"bay": &"sw", "misc": &"bleed", "hook": true, "battery": true},
			&"sw"), Vector3(-0.5, 0.3, 1.0), 0.25, 1.3],
		["tier2_survey_sw", LOOKS.survey_set(&"sw", {"bay": &"preamp", "misc": &"counter", "hook": true}), three, 0.1, 1.2],
		["tier2_survey_fm", LOOKS.survey_set(&"fm", {}), front, 0.1, 1.0],
		["face_am", LOOKS.field_radio(&"company", {"converters": [&"fm", &"sw"]}, &"am"), front, 0.2, 2.6],
		["face_fm", LOOKS.field_radio(&"company", {"converters": [&"fm", &"sw"]}, &"fm"), front, 0.2, 2.6],
		["face_sw", LOOKS.field_radio(&"company", {"converters": [&"fm", &"sw"]}, &"sw"), front, 0.2, 2.6],
		["face_off", LOOKS.field_radio(&"company", {"converters": [&"fm", &"sw"]}, &"sw", false), front, 0.2, 2.6],
		["tier1_both_converters", LOOKS.field_radio(&"company", {"converters": [&"fm", &"sw"], "misc": &"bleed", "hook": true},
			&"fm"), Vector3(0.9, 0.35, 0.8), 0.2, 1.3],
	]
	for id: StringName in LOOKS.MODULES:
		var b := Paint.Pieces.new()
		LOOKS.module(b, id, Transform3D.IDENTITY)
		list.append(["module_%s" % id, b.commit(), Vector3(1.0, 0.45, 0.65), 0.2, 1.0])
	var hb := Paint.Pieces.new()
	LOOKS.hook(hb, Transform3D.IDENTITY)
	list.append(["module_hook", hb.commit(), Vector3(1.0, 0.45, 0.65), 0.2, 1.0])
	var kite := LOOKS.kite()
	list.append(["kite_new", kite, Vector3(0.35, -0.25, 1.0), 0.1, 1.0, {}])
	list.append(["kite_worn", kite, Vector3(0.35, -0.25, 1.0), 0.5, 1.0, {"torn": 0.1}])
	list.append(["kite_storm_ruined", LOOKS.kite(0.4), Vector3(0.35, -0.25, 1.0), 0.9, 1.0, {"torn": 0.55}])
	list.append(["kite_charged", kite, Vector3(0.35, -0.25, 1.0), 0.3, 1.0, {"charge": 1.0}])
	list.append(["reel", LOOKS.reel(), Vector3(0.8, 0.4, 0.7), 0.2, 1.0])
	list.append(["earth_stake", LOOKS.earth_stake(), Vector3(0.5, 0.2, 1.0), 0.2, 1.0])
	list.append(["earth_stake_head", LOOKS.earth_stake(true), Vector3(0.6, 0.3, 1.0), 0.2, 4.0])
	return list


func _shoot(shot: Array, out: String) -> void:
	var mesh: ArrayMesh = shot[1]
	view.mesh = mesh
	view.set_instance_shader_parameter(&"age", shot[3])
	view.set_instance_shader_parameter(&"lit", 1.0)
	# The kite's sail keeps its own material: its torn, age and charge on it.
	if mesh.get_surface_count() > 1:
		var cloth := (mesh.surface_get_material(1) as ShaderMaterial).duplicate() as ShaderMaterial
		cloth.set_shader_parameter(&"age", shot[3])
		for name: String in ["torn", "charge"]:
			cloth.set_shader_parameter(name, (shot[5] as Dictionary).get(name, 0.0) if shot.size() > 5 else 0.0)
		view.set_surface_override_material(1, cloth)
	else:
		view.set_surface_override_material(0, null)
	var box := mesh.get_aabb()
	# Its foot on the sand; a kite off it, against the sky.
	view.position = Vector3(0.0, -box.position.y + (1.5 if String(shot[0]).begins_with("kite") else 0.0), 0.0)
	var middle := box.get_center() + view.position
	var zoom: float = shot[4]
	var radius := box.size.length() * 0.5
	var dir: Vector3 = (shot[2] as Vector3).normalized()
	var distance := radius / sin(deg_to_rad(camera.fov * 0.5)) * 1.02 / zoom
	var look_at := middle
	if zoom > 1.5:
		# Close in on the face: its band window, upper middle.
		look_at = view.position + Vector3(0.0, LOOKS.BAND_Y - 0.01, box.end.z)
		if String(shot[0]).begins_with("earth_stake"):
			look_at = view.position + Vector3(0.0, 0.5, 0.0)
	camera.look_at_from_position(look_at + dir * distance, look_at, Vector3.UP)
	for k in 4:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, shot[0]])
	print("radio kit studio: %s" % shot[0])
