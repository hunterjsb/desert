extends Node
## Real seeded destinations at several distances, through the actual renderer.
const WORLD := preload("res://game/world/world.tscn")
var world: World
var out: String

func _ready() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	Tuning.current().run_seed = 1234
	Tuning.current().eye_adapts = false
	Tuning.current().storm_threshold = -2.0 if OS.get_cmdline_user_args().has("--storm") else 2.0
	world = WORLD.instantiate()
	add_child(world)
	world.time_warp = 0
	world.player.set_physics_process(false)
	world.player.set_process_unhandled_input(false)
	await ground()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await shoot("spawn")
	for shot in [[&"starcom", 15000.0], [&"starcom", 150.0], [&"observatory", 15000.0], [&"observatory", 4000.0], [&"observatory", 150.0]]:
		var mark := world.shape.history.landmark(shot[0])
		var p := Sphere.toward(mark.p, mark.bearing + 0.5, shot[1] / world.shape.history.radius)
		world.travel(rad_to_deg(Sphere.latitude(p)), rad_to_deg(Sphere.longitude(p)), 0)
		world.time_warp = 0
		await ground()
		var hill := world.shape.landforms.get_hill(shot[0])
		for t in range(0, 1200, 5):
			if absf(world.weather.day.time_of_day(t, world.moon.longitude) - 0.38) < 0.01:
				world.time = t
				break
		world.player.position.y = world.height_at(world.player_world_x(), world.player_world_z()) + 0.1
		var to := Vector3(world.engine_x(hill.at.x), hill.height + 60, world.engine_z(hill.at.y))
		world.player.camera.look_at(to)
		await shoot("%s_%d" % [shot[0], shot[1]])
	get_tree().quit()

func ground() -> void:
	var until := Time.get_ticks_msec() + 120000
	for i in 3:
		await get_tree().physics_frame
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		if world.terrain.is_idle() and world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			return
	push_error("horizon ground timed out")

func shoot(name: String) -> void:
	for i in 25:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	var map := world.weather.wind_map
	var got := map.read_back()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := 0.0
	if got.size() == 2:
		var heights: PackedByteArray = got[1]
		for b in range(0, WindMap.GROUND, 32):
			for a in range(0, WindMap.GROUND, 32):
				var at := map.first + Vector2i(a, b)
				var slot := Vector2i(posmod(at.x, WindMap.GROUND), posmod(at.y, WindMap.GROUND))
				var gpu := heights.decode_float((slot.y * WindMap.GROUND + slot.x) * 4)
				error = maxf(error, absf(gpu - world.shape.dunes(at.x * WindMap.TEXEL, at.y * WindMap.TEXEL)))
	print("horizons: %s; GPU/CPU ground error %.5fm" % [name, error])
	if got.size() != 2 or error > 0.02:
		push_error("mountain wind map disagrees with terrain")
		get_tree().quit(1)
