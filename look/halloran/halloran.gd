extends Node
## Real seeded landmark, streamed and photographed on the GPU, never a staged mesh.
const WORLD := preload("res://game/world/world.tscn")
var world: World
var camera: Camera3D
var out: String

func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	Tuning.current().run_seed = 1234
	Tuning.current().eye_adapts = false
	Tuning.current().storm_threshold = 2.0
	if OS.get_cmdline_user_args().has("--storm"):
		Tuning.current().storm_threshold = -2.0
		Tuning.current().storm_ramp = 0.04
	world = WORLD.instantiate()
	add_child(world)
	await ground()
	var hall := world.shape.history.landmark(&"halloran")
	var crossing: Dictionary = hall.parts.filter(func(p: Dictionary) -> bool: return p.id == &"crossing")[0]
	world.travel(rad_to_deg(Sphere.latitude(crossing.p)), rad_to_deg(Sphere.longitude(crossing.p)), 0)
	world.time_warp = 0
	for t in range(0, 1200, 5):
		if absf(world.weather.day.time_of_day(t, Sphere.longitude(crossing.p)) - 0.38) < 0.01:
			world.time = t
			break
	await ground()
	world.player.set_process_unhandled_input(false)
	world.player.set_physics_process(false)
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	camera = Camera3D.new()
	camera.fov = 65
	add_child(camera)
	camera.make_current()
	await shot("aitch", Vector3(-325, 5, -40), Vector3(-250, 3, 0))
	await shot("stock", HalloranKit.STORE + Vector3(-3, 2.8, -4), HalloranKit.STORE + Vector3(0, 1, 0))
	await shot("crossing", Vector3(-35, 22, -30), Vector3(3, 25, 0))
	await shot("refinery", Vector3(250, 41, -40), Vector3(300, 47, 0))
	await shot("cold", Vector3(284, 38, -4), HalloranKit.FURNACE + Vector3(0, 2, 0))
	world.stoker_state = {"stock": 1, "fed": 1, "until": world.time + 30}
	await shot("fire", Vector3(284, 38, -4), HalloranKit.FURNACE + Vector3(0, 2, 0))
	world.time += 31
	await shot("cache", Vector3(302, 38, -11), HalloranKit.CACHE + Vector3(0, 1.5, 0))
	get_tree().quit()


func ground() -> void:
	var deadline := Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if world.terrain.is_idle() and world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			break
	for i in 15:
		await get_tree().physics_frame


func shot(name: String, from: Vector3, to: Vector3) -> void:
	var site := world.stoker.site
	if site == null:
		push_error("Halloran never loaded")
		get_tree().quit(1)
		return
	var p := site.frame() * from
	world.teleport(world.player, Transform3D(Basis.IDENTITY, Vector3(world.engine_x(p.x), p.y, world.engine_z(p.z))))
	await ground()
	site = world.stoker.site
	var frame := site.frame()
	frame.origin.x = world.engine_x(frame.origin.x)
	frame.origin.z = world.engine_z(frame.origin.z)
	var eye := frame * from
	world.player.global_position = eye - Vector3.UP * 1.65
	camera.global_position = eye
	camera.look_at(frame * to)
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("halloran: shot ", name)
