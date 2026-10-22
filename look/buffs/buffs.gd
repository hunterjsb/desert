extends Node
## Look-test: the corner bars on seed 1234 in the morning. Unprepared, just
## health and stamina; then sat until rested, fed and given a drink by use,
## the three named under a longer stamina bar; then with the inventory open,
## each with its hours left and the food and water carried.
##   scripts/unseen.sh --path . res://look/buffs/buffs.tscn -- --capture <dir>

const SEED := 1234

@onready var world: World = $World


func _enter_tree() -> void:
	Tuning.current().run_seed = SEED
	Tuning.current().eye_adapts = false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://buffs")


func _capture(out_dir: String) -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	player.suit.set_process_unhandled_input(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame
	player.camera.rotation_degrees.x = -8.0
	await _ticks(30)
	player.stamina = 60.0
	await _shot(out_dir, "unprepared")
	player.posture.toggle(&"sit")
	world.time_warp = 20.0
	while not player.vitals.buffs.active(&"rested"):
		await get_tree().physics_frame
	world.time_warp = 1.0
	player.posture.toggle(&"sit")
	player.suit.supply(&"food").use(player, Vector3.ZERO)
	player.suit.supply(&"water").use(player, Vector3.ZERO)
	await _ticks(10)
	player.stamina = 70.0
	await _shot(out_dir, "prepared")
	player.suit.show_view(true)
	await _ticks(10)
	await _shot(out_dir, "inventory")
	get_tree().quit()


func _shot(out_dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("buffs_%s.png" % name))
	print("saved buffs_%s.png" % name)


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
