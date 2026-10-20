extends Node
## Look-test: the Surveyor's care package, on seed 1234, by day. Its cannon
## fired at you; you stand off where it comes down, looking at the spot, and
## up the sky the way it comes: its trail high in the sky, the last seconds of
## its fall, the hit, and its sand cloud spreading and settling.
##   godot --path . --disable-vsync res://look/airdrop/airdrop.tscn -- --capture <dir>
## A small window that never takes focus, nothing but this script moving
## anything, and silence.

const SEED := 1234
## You stand this far off where it lands, m, your eyes this high.
const OFF := 45.0
const EYES := 1.7
## The moments shot, s after the shot, and how far up the sky each looks, degrees.
const SHOTS := [["trail", 4.0, 30.0], ["falling", 12.5, 12.0], ["hit", 14.1, 4.0], ["cloud", 15.5, 4.0],
	["settling", 19.0, 3.0]]

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	tuning.storm_threshold = 2.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://airdrop")


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
	# Midday, the Surveyor high over you.
	var day := world.weather.day
	while not day.is_day(world.time, world.moon.longitude) \
			or Airdrop.surveyor(world, player.global_position, world.time).up < deg_to_rad(50.0):
		world.time += 1.0
	player.set_physics_process(false)
	player.flying = true
	var drop := Airdrop.fire(world, player.global_position)
	var land := drop.global_position
	var muzzle := drop.to_global(drop.along(0.0))
	var side := Vector3(muzzle.x - land.x, 0.0, muzzle.z - land.z).normalized().rotated(Vector3.UP, PI * 0.5)
	var eye := land + side * OFF
	eye.y = world.height_under(eye) + EYES
	print("airdrop: fired from %.0f m, lands %.0f m off you" % [drop._metres, Vector2(land.x - eye.x, land.z - eye.z).length()])
	for shot: Array in SHOTS:
		while world.time < drop.fired_at + shot[1]:
			await get_tree().physics_frame
		var target := land
		if not drop.landed and is_instance_valid(drop.cargo):
			target = drop.cargo.global_position
		_eyes(eye, target)
		await _shoot(out_dir, shot[0], drop)
	get_tree().quit()


func _eyes(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)


func _shoot(out_dir: String, name: String, drop: Airdrop) -> void:
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("airdrop: %s, %.1f s after the shot, landed %s" % [name, world.time - drop.fired_at,
		drop.landed if is_instance_valid(drop) else true])


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame
