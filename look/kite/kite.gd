extends Node
## Look-test: the antenna kite rigged to a radio, on seed 1234, on a clear
## day with a steady 9 m/s wind. A radio with a shortwave converter, a rope
## hook on its top and a bleed resistor in its misc bay; a cable from the
## hook's stem through a driven stake to the kite's reel; the kite flown up on
## its line. Shots: the rig close on the sand, the whole flight looking up its
## line, the kite charged, and torn half to rags.
##   godot --path . --disable-vsync res://look/kite/kite.tscn -- --capture <dir>
## A small window that never takes focus, nothing but this script moving
## anything, and silence.

const SEED := 1234
const WIND := 9.0

@onready var world: World = $World
var _camera: Camera3D


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	tuning.storm_threshold = 2.0
	tuning.prevailing_speed = WIND
	tuning.prevailing_sway = 0.0
	tuning.gust_strength = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://kite")


func _capture(out_dir: String) -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _ground()
	await Scenarios.apply(world, Scenarios.by_key("clear"))
	await _ground()
	player.set_physics_process(false)
	# The wind's way, so the kite flies off ahead of you.
	var w := world.weather.field.wind_at(world.player_world_x(), world.player_world_z(), world.time)
	var down := Vector3(w.x, 0.0, w.y).normalized()
	player.rotation = Vector3(0.0, atan2(-down.x, -down.z), 0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter", &"bleed_resistor"], [0.0, 2.0]) as Radio
	radio.freeze = true
	for socket in radio.sockets():
		if socket.kind == &"radio_top":
			radio.fit(Catalog.part(&"hook"), socket)
	var kite := Scenarios.standing(world, &"antenna_kite", [], [0.0, 5.0]) as AntennaKite
	kite.freeze = true
	var stake := Catalog.stake()
	world.content.add_child(stake)
	var mid := radio.global_position.lerp(kite.global_position, 0.5) + player.global_basis.x * 0.7
	stake.drive(mid, world.height_under(mid))
	var cable := Catalog.cable(world, radio.global_position + Vector3.UP)
	for socket in radio.sockets():
		if socket.kind == &"lead" and socket.is_open():
			radio.fit(cable.plugs[0], socket)
	for socket in kite.sockets():
		if socket.kind == &"lead":
			kite.fit(cable.plugs[1], socket)
	cable.route(stake)
	radio.on = true
	radio.switch_band()
	kite.fly()
	kite.line_out = Tuning.current().kite_line_m
	await _ticks(300)
	print("kite: %.0f m up on %.0f m of line, earthed %s, the set's gain %.2f" % [kite.height(), kite.line_out,
		kite.earthed(), radio.antenna_gain()])
	# The rig on the sand, from beside it.
	_look_from(radio.global_position + player.global_basis.x * 2.2 + Vector3.UP * 1.3 - down * 1.5,
		stake.global_position + Vector3.UP * 0.2)
	await _shoot(out_dir, "rig")
	# The whole flight, looking up its line.
	_look_from(radio.global_position - down * 6.0 + Vector3.UP * 1.7, kite.kite_at)
	await _shoot(out_dir, "flight")
	# Close on the kite.
	var near := kite.kite_at - (kite.kite_at - kite.anchor()).normalized() * 6.0
	_look_from(near, kite.kite_at)
	await _shoot(out_dir, "kite")
	kite.charge = 0.9
	await _ticks(2)
	await _shoot(out_dir, "charged")
	kite.charge = 0.0
	kite.durability = 0.45
	await _ticks(2)
	await _shoot(out_dir, "torn")
	get_tree().quit()


## A camera of its own at `from`, looking at `to`.
func _look_from(from: Vector3, to: Vector3) -> void:
	if _camera == null:
		_camera = Camera3D.new()
		_camera.fov = 60.0
		_camera.far = 4000.0
		world.add_child(_camera)
	_camera.current = true
	_camera.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)


func _shoot(out_dir: String, name: String) -> void:
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	for i in 4:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("kite: shot %s" % name)


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
