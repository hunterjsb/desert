extends Node
## The storm-wall look-test: a front rolls in over real ground, judged by eye.
## Keys are on screen; Atmosphere owns every light, sky and fog setting.
##   godot --path . res://look/wall/wall.tscn
##   godot --path . --disable-vsync res://look/wall/wall.tscn -- --capture <outdir> [--only 5km,inside]

const WORLD_SCENE := preload("res://game/world/world.tscn")
const SEED := 1234
const SPEEDS := {KEY_1: 1.0, KEY_2: 5.0, KEY_3: 20.0, KEY_4: 60.0}
const JUMPS := {KEY_5: 3000.0, KEY_6: 1000.0, KEY_7: 300.0, KEY_8: 50.0, KEY_9: 0.0, KEY_0: -60.0}
const KEYS_HELP := "1-4 speed ×1 ×5 ×20 ×60 · Space pause · R restart · jump: 5 3 km  6 1 km  " \
	+ "7 300 m  8 50 m  9 contact  0 inside · L sun · H hide · click to look, WASD, F4 fly"
## Capture mode's shots: face distance (m), yaw from facing the storm, pitch, name.
const SHOTS := [
	[5000.0, 0.0, 3.0, "5km"],
	[3000.0, 0.0, 4.0, "3km"],
	[1800.0, 0.0, 6.0, "1800m"],
	[1000.0, 0.0, 9.0, "1km"],
	[500.0, 0.0, 14.0, "500m"],
	[300.0, 0.0, 18.0, "300m"],
	[300.0, 75.0, 8.0, "300m_along_the_front"],
	[300.0, 180.0, 5.0, "300m_looking_away"],
	[120.0, 0.0, 22.0, "120m"],
	[50.0, 0.0, 15.0, "50m"],
	[20.0, 0.0, 8.0, "20m"],
	[0.0, 0.0, 5.0, "contact"],
	[-25.0, 0.0, 0.0, "25m_in"],
	[-60.0, 0.0, 0.0, "inside"],
	[-60.0, 180.0, 6.0, "inside_looking_out"],
	[-60.0, 0.0, 70.0, "inside_looking_up"],
]

var world: World
var time_scale := 1.0
var paused := false

var _buffet := FastNoiseLite.new()
var _buffet_time := 0.0

@onready var storm: WallStorm = $Storm
@onready var atmosphere: WallAtmosphere = $Atmosphere
@onready var readout: Label = $Hud/Readout
@onready var keys: Label = $Hud/Keys


func _ready() -> void:
	Tuning.current().run_seed = SEED
	world = WORLD_SCENE.instantiate()
	add_child(world)
	move_child(world, 0)
	storm.setup(world, SEED)
	atmosphere.setup(world, storm)
	keys.text = KEYS_HELP
	face_the_storm(0.0, 3.0)
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at != -1:
		var only := args.find("--only")
		_capture(args[at + 1] if args.size() > at + 1 else "user://wall",
			args[only + 1].split(",") if only != -1 and args.size() > only + 1 else PackedStringArray())


func _process(delta: float) -> void:
	var running := not paused
	storm.advance(delta * time_scale if running else 0.0)
	storm.sync()
	var camera := get_viewport().get_camera_3d()
	atmosphere.apply(camera)
	storm.follow(camera, storm.wind(), atmosphere.inside, running)
	_buffet_camera(camera, delta if running else 0.0)
	readout.text = _readout()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode
	if SPEEDS.has(code):
		time_scale = SPEEDS[code]
	elif JUMPS.has(code):
		storm.jump_to(JUMPS[code])
	elif code == KEY_SPACE:
		paused = not paused
	elif code == KEY_R:
		storm.restart()
		time_scale = 1.0
		paused = false
	elif code == KEY_L:
		atmosphere.next_sun()
	elif code == KEY_H:
		$Hud.visible = not $Hud.visible


## The wind shoves you: a small roll that grows with it. The player never sets
## roll, so this can't fight the mouse.
func _buffet_camera(camera: Camera3D, delta: float) -> void:
	_buffet_time += delta
	var strength := smoothstep(7.0, 22.0, storm.wind().length())
	camera.rotation.z = deg_to_rad(0.5) * strength * _buffet.get_noise_1d(_buffet_time * 90.0)


## Turns the player to look toward where the storm comes from, then by yaw.
func face_the_storm(yaw_degrees: float, pitch_degrees: float) -> void:
	var toward := (-storm.dir).rotated(deg_to_rad(yaw_degrees))
	world.player.rotation.y = atan2(-toward.x, -toward.y)
	world.player.camera.rotation_degrees.x = pitch_degrees


## The stage is whichever part of the arrival is furthest along.
func stage() -> String:
	var distance := storm.face_distance()
	if atmosphere.inside > 0.95 and distance < 0.0:
		return "inside"
	if atmosphere.inside > 0.02:
		return "contact"
	if distance < 150.0:
		return "the face"
	if storm.wind().length() > 6.0:
		return "the wind rises"
	if atmosphere.camera_sun < 0.9:
		return "the light dims"
	return "on the horizon"


func _readout() -> String:
	var distance := storm.face_distance()
	var shown := "%.2f km" % (distance / 1000.0) if absf(distance) >= 1000.0 \
		else "%d m" % roundi(distance)
	var eta := maxf(distance, 0.0) / storm.speed
	var when := "%d:%02d" % [int(eta) / 60, int(eta) % 60] if distance > 0.0 else "now"
	var state := "paused" if paused else "×%d" % roundi(time_scale)
	Dev.put("wall/face_m", distance)
	Dev.put("wall/stage", stage())
	return "face %s   impact %s   %s\n%s   wind %d m/s   sun %s" % [shown, when, state, stage(),
		roundi(storm.wind().length()), atmosphere.sun_name()]


## Jumps through SHOTS, saving a PNG of each and printing frame times. Renders
## at exactly 1920x1080 inside a small window, so it stays out of the way.
func _capture(out_dir: String, only: PackedStringArray) -> void:
	# Screenshots are silent: the roar shouldn't play through his speakers.
	AudioServer.set_bus_mute(0, true)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var window := get_window()
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	$Hud.visible = false
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var waited := Time.get_ticks_msec()
	while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 20000:
		await get_tree().process_frame
	print("capture: %s at %s" % [out_dir, get_viewport().get_visible_rect().size])
	var worst_ms := 0.0
	var worst_gpu := 0.0
	for n in SHOTS.size():
		var shot: Array = SHOTS[n]
		if not only.is_empty() and not only.has(shot[3]):
			continue
		# Land on the distance as the shot is taken, after a second of settling.
		storm.jump_to(shot[0] + storm.speed * 1.6)
		face_the_storm(shot[1], shot[2])
		await get_tree().create_timer(0.6).timeout
		var frames := 0
		var longest := 0.0
		var gpu := 0.0
		var started := Time.get_ticks_usec()
		var last := started
		while Time.get_ticks_usec() - started < 1000000:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			longest = maxf(longest, (now - last) / 1000.0)
			last = now
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
			frames += 1
		var average := (Time.get_ticks_usec() - started) / 1000.0 / frames
		gpu /= frames
		worst_ms = maxf(worst_ms, average)
		worst_gpu = maxf(worst_gpu, gpu)
		var path := out_dir.path_join("%02d_%s.png" % [n + 1, shot[3]])
		get_viewport().get_texture().get_image().save_png(path)
		print("  %-24s face %7.1f m  %-15s frame %5.2f ms (worst %5.2f)  gpu %5.2f ms" % [shot[3],
			storm.face_distance(), stage(), average, longest, gpu])
	print("capture: worst average frame %.2f ms, worst gpu %.2f ms" % [worst_ms, worst_gpu])
	get_tree().quit()
