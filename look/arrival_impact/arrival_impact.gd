extends WorldProbe
## Isolated effects in a real shell's open hatch; integrated sealed flight is checked separately.
var effects: ArrivalImpactEffects
var out: String
var window: Rect2

func run() -> void:
	await load_world()
	world.time_warp = 0.0
	world.time = world.tuning.day_minutes * 60.0 * 0.32
	world.player.set_physics_process(false)
	world.player.hide()
	Dev.hide_overlays()
	var at := world.player.global_position
	at.y = world.height_under(at) + Chassis.THICK * 0.5 + 0.1
	var shell := PodShell.build(world.content, Transform3D(Basis.IDENTITY, at), {&"hatch": false})
	shell.deck.freeze = true
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.fov = 65.0
	camera.global_position = at + Vector3(0.45, 0.58, 0.0)
	camera.look_at(at + Vector3(-4.0, 0.58, 0.0))
	camera.current = true
	var screen := Vector2(get_viewport().get_visible_rect().size)
	var a := camera.unproject_position(at + Vector3(-0.5, 0.12, -0.43)) / screen
	var b := camera.unproject_position(at + Vector3(-0.5, 1.0, 0.43)) / screen
	window = Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (b - a).abs())
	var layer := CanvasLayer.new()
	add_child(layer)
	effects = ArrivalImpactEffects.new()
	layer.add_child(effects)
	effects.setup(world.tuning)
	out = OS.get_cmdline_user_args()[-1]
	DirAccess.make_dir_recursive_absolute(out)
	var clear := await shot("clear", &"descent", 0.0, 0.0)
	var hot := await shot("entry", &"entry", 2.8, 0.94)
	var hit := await shot("impact", &"landing", 0.105, 0.0875)
	await shot("settling", &"landing", 0.65, 0.54)
	var settled := await shot("clear-again", &"landing", 1.16, 0.97)
	effects.present({"phase": &"landing", "elapsed": 0.105, "progress": 0.0875}, window)
	var base := camera.global_transform
	camera.global_transform = base * Transform3D(Basis.from_euler(effects.camera_rotation), effects.camera_offset)
	await shot("impact-jolt", &"landing", 0.105, 0.0875)
	camera.global_transform = base
	var outside := 0
	var heat := 0
	var dust := 0
	var residual := 0
	for y in clear.get_height():
		for x in clear.get_width():
			var p := Vector2(x + 0.5, y + 0.5) / screen
			var changed := clear.get_pixel(x,y) != hit.get_pixel(x,y)
			outside += int(changed and not window.grow(0.003).has_point(p))
			heat += int(clear.get_pixel(x,y) != hot.get_pixel(x,y))
			dust += int(changed)
			residual += int(clear.get_pixel(x,y) != settled.get_pixel(x,y))
	print("IMPACT GPU aperture=%s outside=%d heat=%d dust=%d residual=%d" % [window,outside,heat,dust,residual])
	check(outside == 0 and heat > 100 and dust > heat and residual == 0, "glass effects leave the real cabin unchanged and clear completely")
	effects.dispose()

func shot(label: String, phase: StringName, elapsed: float, progress: float) -> Image:
	effects.present({"phase": phase, "elapsed": elapsed, "progress": progress}, window)
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(out.path_join(label + ".png"))
	return image
