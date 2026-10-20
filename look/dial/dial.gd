extends Node
## Look-test: the radio's dial in your hands, on seed 1234, on the
## "clear_skies" scenario's clear day. A radio on the sand as you'd see it
## standing over it, then the view easing in as you tune it, closed in at
## several places on the band with the knobs turned, easing out as you look
## away and back to your own view; one in your hands, and one at dusk with
## its scale lit. Three frequencies are marked, in a profile of the look-test's
## own, so their ticks show on the band, and its signal lamps show what it hears. The real close-up, driven a frame at a time:
##   godot --path . --disable-vsync res://look/dial/dial.tscn -- --capture <dir>
## Add --720p after the capture directory for a 1280 by 720 UI check.
## look/dial/shoot.sh builds the sheet. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
## Standing over it: your eyes this far back from it, m, and this high.
const STANDING := Vector2(1.1, 1.65)
## Closed in at these places on the band, kHz, and the volume each time.
const BANDS := [[160.0, 1.0], [430.0, 0.7], [1020.0, 0.4], [1930.0, 0.1]]
## Dusk, local time as a share of the day.
const DUSK := 0.742

@onready var world: World = $World
var close: CloseUp


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	# The close-up is off in play; this shoots it.
	tuning.dial_close_up = true


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://dial")


func _capture(out_dir: String) -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1280, 720) if OS.get_cmdline_user_args().has("--720p") else Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	# Marks of its own, never the player's.
	Profile.dir = OS.get_temp_dir().path_join("desert-look-dial-%d" % OS.get_process_id())
	Profile.reset()
	for each: Array in [[262.0, Color("e8604c")], [1048.0, Color("4fc3d9")], [1520.0, Color("f2d55c")]]:
		Profile.mark(each[0], "", each[1], 1.0)
	await _ground()
	await Scenarios.apply(world, Scenarios.by_key("clear_skies"))
	await _ground()
	var radio: Radio = world.get_meta(&"scenario_kit").filter(func(n: Node) -> bool: return n is Radio)[0]
	player.set_physics_process(false)
	player.flying = true
	close = player.close_up
	close.set_process(false)
	await _ticks(60)
	radio.freeze = true

	var middle := radio.face().origin
	var out := _out(radio)
	var stand := middle + out * STANDING.x
	stand.y = world.height_under(stand) + STANDING.y
	_eyes(stand, middle)
	await _ticks(20)
	await _shoot(out_dir, "standing", radio)
	radio.tune(1)
	close.tuned(radio)
	await _closed(out_dir, "easing_in", radio, 0.5)
	await _closed(out_dir, "closed_%04d" % roundi(radio.frequency), radio, 1.0)
	for each: Array in BANDS:
		radio.frequency = each[0]
		radio.volume = each[1]
		await _closed(out_dir, "closed_%04d" % roundi(each[0]), radio, 1.0)
	_eyes(stand, middle + out.cross(Vector3.UP) * 1.5)
	await _ticks(5)
	await _closed(out_dir, "easing_out", radio, 0.5)
	await _closed(out_dir, "out", radio, 0.0)

	# In your hands: tuned, it turns its face up to your eyes.
	_eyes(stand, middle)
	radio.freeze = false
	player.hands.hold(radio)
	await _ticks(30)
	radio.tune(-3)
	close.tuned(radio)
	await _ticks(40)
	await _closed(out_dir, "held", radio, 1.0)

	# Dusk, its scale lit.
	var day := world.weather.day
	while absf(day.time_of_day(world.time, world.moon.longitude) - DUSK) > 0.002:
		world.time += 5.0
	await _ticks(60)
	await _closed(out_dir, "dusk", radio, 1.0)
	get_tree().quit()


## Closed in this far, 0 out to 1, held there while it's shot.
func _closed(out_dir: String, name: String, radio: Radio, k: float) -> void:
	await _ticks(40)
	close.close = k
	close._process(0.0)
	if k <= 0.0:
		world.player.camera.make_current()
	await _shoot(out_dir, name, radio)


## Which way its face looks, level.
func _out(radio: Radio) -> Vector3:
	var out := radio.global_basis.z
	return Vector3(out.x, 0.0, out.z).normalized()


## Your eyes at a place, looking at a target, at the game's own lens.
func _eyes(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)


func _shoot(out_dir: String, name: String, radio: Radio) -> void:
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = layer.name == &"RadioTuningControls" or (OS.get_cmdline_user_args().has("--720p") and layer is Bars)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("dial: %s, %d kHz, volume %d%%, close %.2f" % [name, roundi(radio.frequency), roundi(radio.volume * 100.0),
		close.close])


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
