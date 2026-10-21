extends Node3D
## GPU regression: finite sky-proxy depth puts the hull between nearer and farther ground.
## Run with scripts/unseen.sh and pass the capture directory after --.
var scene: Node3D
var camera: Camera3D
var craft: CropSurvey
var ridge: MeshInstance3D
var out := "user://drone-horizon"
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	call_deferred("run")
func frames() -> void:
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
func shot(name: String) -> Image:
	await frames()
	var image := get_viewport().get_texture().get_image()
	image.save_png(out.path_join(name + ".png"))
	return image
func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	scene = Node3D.new()
	add_child(scene)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(.45,.6,.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = .8
	scene.add_child(env)
	camera = Camera3D.new()
	camera.position = Vector3(0,2,0)
	camera.far = 1000
	scene.add_child(camera)
	camera.current = true
	var sun := DirectionalLight3D.new()
	scene.add_child(sun)
	sun.rotation_degrees = Vector3(-45,30,0)
	ridge = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1000,200,100)
	ridge.mesh = box
	ridge.position = Vector3(0,-98,-650)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(.7,.5,.25)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ridge.material_override = mat
	scene.add_child(ridge)
	craft = CropSurvey.new(Tuning.current())
	scene.add_child(craft)
	craft.place(camera.global_position, Vector3(0,.0,-1).normalized(),6000,Vector3.RIGHT,Vector3.UP)
	craft.light(Vector3(0,1,0),Color.WHITE,Color(.3,.3,.3))
	craft.flash(1)
	craft._overlay.set_shader_parameter(&"veil", 0.4)
	craft._overlay.set_shader_parameter(&"veil_color", Vector3(0.2, 0.7, 0.9))
	craft.visible = false
	var empty := await shot("ridge")
	craft.visible = true
	var fixed := await shot("fixed")
	var below_fixed := 0
	var above_fixed := 0
	for y in empty.get_height():
		for x in empty.get_width():
			var changed := empty.get_pixel(x,y) != fixed.get_pixel(x,y)
			if y > empty.get_height()/2+2:
				below_fixed += int(changed)
			elif y < empty.get_height()/2-2:
				above_fixed += int(changed)
	ridge.visible = false
	camera.far = 20000
	craft.place(camera.global_position, Vector3(0,.4,-1).normalized(),6000,Vector3.RIGHT,Vector3.UP)
	camera.look_at(camera.global_position + Vector3(0,.4,-1))
	var flashing := await shot("unobstructed")
	craft.flash(0)
	var quiet := await shot("unobstructed-quiet")
	var muzzle_pixels := difference(quiet, flashing)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80000, 80000)
	ground.mesh = plane
	ground.material_override = mat
	scene.add_child(ground)
	camera.position = Vector3(0,10000,0)
	camera.far = 20000
	var toward := Vector3(0,-4000,-4000).normalized()
	camera.look_at(camera.global_position + toward)
	craft.visible = false
	var behind := await shot("high-ground")
	craft.place(camera.global_position, toward, sqrt(32000000.0), Vector3.RIGHT, Vector3.UP)
	craft.flash(0)
	craft._view.material_overlay = null
	var hull := await shot("high-hull")
	craft.flash(1)
	var muzzle := await shot("high-muzzle")
	craft._view.material_overlay = craft._overlay
	var overlay := await shot("high-overlay")
	var hull_pixels := difference(behind, hull)
	var hidden_muzzle_pixels := difference(hull, muzzle)
	var overlay_pixels := difference(muzzle, overlay)
	var passed := below_fixed == 0 and above_fixed > 0 and hull_pixels > 0 and muzzle_pixels > 0 and overlay_pixels > 0
	print("Drone ridge occlusion pixels hidden=%d visible_above=%d" % [below_fixed,above_fixed])
	print("Drone above ground pixels hull=%d hidden_belly_muzzle=%d overlay=%d; exposed_muzzle=%d" % [hull_pixels,hidden_muzzle_pixels,overlay_pixels,muzzle_pixels])
	print("PROBE PASS" if passed else "PROBE FAIL: drone depth did not order between ground surfaces")
	get_tree().quit(0 if passed else 1)

func difference(a: Image, b: Image) -> int:
	var changed := 0
	for y in a.get_height():
		for x in a.get_width():
			changed += int(a.get_pixel(x,y) != b.get_pixel(x,y))
	return changed
