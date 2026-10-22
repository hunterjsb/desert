extends Node
## Catalog gear in the real desert, with a harvested bundle in the hopper.
var world: World

func _ready() -> void:
	var output := OS.get_cmdline_user_args()[0]
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.salvage = false
	tuning.storm_threshold = 2.0
	tuning.eye_adapts = false
	world = preload("res://game/world/world.tscn").instantiate()
	add_child(world)
	while not world.terrain.is_idle():
		await get_tree().process_frame
	world.time_warp = 0.0
	world.player.set_physics_process(false)
	world.player.hide()
	var at := world.player.global_position + Vector3(4, 0, 0)
	at.y = world.height_under(at)
	var bed := Catalog.device(&"deep_planter") as Planter
	world.content.add_child(bed)
	bed.position = at + Vector3(-0.7, 0.325, 0)
	bed.freeze = true
	var cane := Catalog.part(&"coalcane") as Plant
	bed.fit(cane, bed.sockets()[0])
	cane.set_growth(1.0)
	var burner := Catalog.device(&"burner") as Burner
	world.content.add_child(burner)
	burner.position = at + Vector3(0.65, 0.35, 0)
	burner.freeze = true
	burner.fit(Catalog.part(&"coalcane_bundle"), burner.hopper())
	burner.interact(world.player)
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = at + Vector3(3, 2.1, 3.4)
	camera.look_at(at + Vector3(0, 0.7, 0))
	camera.make_current()
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output)
	get_tree().quit()
