extends Node
## Look-test: the crops on seed 1234 on a clear, calm morning, each in a
## planter on the sand at every stage it shows: the root-tuber, the vat fungus
## mature and then fruited, and the saltbush open and folded. Shot close, as
## you'd stand over a planter, at the fixed exposure:
##   godot --path . --disable-vsync res://look/crops/crops.tscn -- --capture <dir>
## look/crops/shoot.sh builds the sheet. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
## [crop, stage shown, grown, fruited, folded].
const SHOTS := [
	[&"root_tuber", "seedling", 0.12, 0.0, 0.0],
	[&"root_tuber", "growing", 0.6, 0.0, 0.0],
	[&"root_tuber", "mature", 1.0, 0.0, 0.0],
	[&"vat_fungus", "seedling", 0.12, 0.0, 0.0],
	[&"vat_fungus", "growing", 0.6, 0.0, 0.0],
	[&"vat_fungus", "mature", 1.0, 0.0, 0.0],
	[&"vat_fungus", "fruited", 1.0, 1.0, 0.0],
	[&"saltbush", "seedling", 0.12, 0.0, 0.0],
	[&"saltbush", "growing", 0.6, 0.0, 0.0],
	[&"saltbush", "open", 1.0, 0.0, 0.0],
	[&"saltbush", "folded", 1.0, 0.0, 1.0],
]
## The time of day it's shot at, how far back and up the eye is, m, and its
## field of view, °: close, as a long lens would see it.
const MORNING := 0.38
const BACK := 0.9
const ABOVE := 0.7
const FOV := 30.0

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	# Clear and calm, so nothing moves the planter or the light.
	tuning.storm_threshold = 2.0
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://crops")


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
	# Nor what you aim at, which its readout would name.
	player.hands.set_process(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var tuning := world.tuning
	var morning := fposmod(MORNING - tuning.start_time_of_day, 1.0) * tuning.day_minutes * 60.0
	world.respawn(world.spawn.x, world.spawn.y, -PI * 0.5, morning)
	await _ground()
	player.set_physics_process(false)
	player.flying = true
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	var planter := Catalog.device(&"planter") as Planter
	world.content.add_child(planter)
	var spot := player.global_position + Vector3(2.0, 0.0, 0.0)
	planter.global_position = Vector3(spot.x, world.height_under(spot) + 0.175, spot.z)
	planter.freeze = true
	planter.tank_l = tuning.planter_tank_litres
	await _ticks(30)
	world.time_warp = 0.0
	for shot: Array in SHOTS:
		for socket in planter.sockets():
			if socket.part is Plant:
				# Unripe, so it comes out whole rather than as its harvest.
				(socket.part as Plant).set_growth(0.0)
				planter.take(socket).free()
		var slots: Array[Socket] = []
		for socket in planter.sockets():
			if socket.kind == Catalog.PARTS[shot[0]].kind:
				var plant := Catalog.part(shot[0]) as Plant
				world.content.add_child(plant)
				planter.fit(plant, socket)
				plant.set_growth(shot[2])
				plant.fruit = shot[3]
				plant.forecast(shot[4] > 0.5, 0.0)
				slots.append(socket)
		var middle := Vector3.ZERO
		for socket in slots:
			middle += planter.global_transform * socket.transform.origin
		middle /= slots.size()
		middle.y += 0.1
		_look_at(middle)
		await _ticks(12)
		# Nothing of the HUD.
		for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
		await get_tree().process_frame
		var name := "%s_%s" % [shot[0], shot[1]]
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
		print("crops: %s" % name)
	get_tree().quit()


## Your eyes back from and above a place, looking at it.
func _look_at(target: Vector3) -> void:
	var player := world.player
	var eye := target + Vector3(0.0, ABOVE, BACK)
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	# Feel holds the camera's own field of view; the lens is the shot's.
	player.feel.set_process(false)
	player.camera.fov = FOV


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
