extends Node
## Look-test: the eye adapting, on seed 1234 where a run begins, Tu 13° across,
## in still air. Each moment is shot twice, at the fixed exposure the game had
## before (as the other look-tests keep it) and with the eye settled: noon, a
## full-Tu night away from Tu and facing it (and away from it at the smaller
## sizes under trial, and at the Tu-shine x3 once suggested instead), a
## crescent night, the far side's stars; and, with --storm, deep in a storm by
## day. The eclipse is watched through, the eye adapting as it goes: totality
## as it begins and 30 s in, and the sun 1 s back. It prints each frame's light
## as the eye's meter reads it, the exposure, the sand's lightness (CIE L*) low
## in the frame either way, how fast the eye moves through the eclipse and
## stepping into the storm, and what the meter costs the GPU at 1920x1080:
##   godot --path . --disable-vsync res://look/eye/eye.tscn -- --capture <dir> [--storm]
## look/eye/shoot.sh shoots both and builds the sheet. A small window that never
## takes focus, nothing but this script moving anything, and silence.

const SEED := 1234
## Looking at Tu from where a run begins: up this far, so it sits high in frame.
const PITCH_TO_TU := 12.0
const PITCH_GROUND := -6.0
## Local hours: noon, a crescent night (Tu 5% lit), and the storm's midmorning.
const NOON := 0.5
const CRESCENT := 0.8
const MIDMORNING := 0.4
## The far side's shot: latitude, so the pole star stands this high, and the
## view north, up a little, the stars over the dunes.
const FAR_LATITUDE := 30.0
const FAR_PITCH := 8.0
## Seconds before first contact the eclipse is watched from, and after the
## sun comes back.
const BEFORE := 10.0
const AFTER := 10.0
const INTO_TOTALITY := 30.0
const SUN_BACK := 1.0
## Watching the step into a storm, s, and when it says how open the eye is.
const STEP_IN := [0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0, 16.0]
const GPU_FRAMES := 60
const GPU_ROUNDS := 4

@onready var world: World = $World

var _storm := OS.get_cmdline_user_args().has("--storm")
var _out := ""


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = true
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0
	if _storm:
		# A full storm everywhere that never passes.
		tuning.storm_ramp = 0.04
		tuning.storm_threshold = -2.0
	else:
		tuning.storm_threshold = 10.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_out = args[at + 1] if args.size() > at + 1 else "user://eye"
	_capture()


func _capture() -> void:
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
	DirAccess.make_dir_recursive_absolute(_out)
	await _ground()
	for i in 600:
		if world.weather.map.ready:
			break
		await get_tree().process_frame
	player.set_physics_process(false)
	player.flying = true
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	# The run's kit stands at spawn and would fill the view.
	for body in world.get_meta(&"kit", []):
		if is_instance_valid(body):
			body.free()

	var tuning := world.tuning
	tuning.tu_degrees = 13.0
	var day := world.weather.day
	var spawn_lon := tuning.spawn_longitude_degrees
	var tu_lon := tuning.tu_longitude_degrees
	var full := day.next_eclipse(0.0) + tuning.day_minutes * 30.0
	if _storm:
		var morning := _at_hour(MIDMORNING, spawn_lon)
		await _pair("storm", morning, 0.0, spawn_lon, _to_tu(full, spawn_lon) + PI, PITCH_GROUND)
		await _step_in()
		await _gpu_cost()
		get_tree().quit()
		return

	await _pair("noon", _at_hour(NOON, spawn_lon), 0.0, spawn_lon, _to_tu(full, spawn_lon) + PI, PITCH_GROUND)
	await _pair("full", full, 0.0, spawn_lon, _to_tu(full, spawn_lon) + PI, PITCH_GROUND)
	await _pair("full_tu", full, 0.0, spawn_lon, _to_tu(full, spawn_lon), PITCH_TO_TU)
	# The earlier suggestion for the same night: Tu-shine three times physical.
	tuning.eye_adapts = false
	tuning.tu_shine_scale = 3.0
	await _shot("full_x3", full, 0.0, spawn_lon, _to_tu(full, spawn_lon) + PI, PITCH_GROUND)
	tuning.tu_shine_scale = 1.0
	# The smaller sizes under trial, for their numbers.
	for degrees: float in [6.0, 9.0]:
		tuning.tu_degrees = degrees
		await _pair("full_%d" % degrees, full, 0.0, spawn_lon, _to_tu(full, spawn_lon) + PI, PITCH_GROUND)
	tuning.tu_degrees = 13.0
	var crescent := _at_hour(CRESCENT, spawn_lon)
	await _pair("crescent", crescent, 0.0, spawn_lon, _to_tu(full, spawn_lon) + PI, PITCH_GROUND)
	await _pair("far", _at_hour(0.0, tu_lon + 180.0), FAR_LATITUDE, tu_lon + 180.0, 0.0, FAR_PITCH)
	await _eclipse()
	await _gpu_cost()
	get_tree().quit()


## A moment shot at the fixed exposure, then with the eye settled on it.
func _pair(name: String, t: float, latitude: float, longitude: float, yaw: float, pitch: float) -> void:
	world.tuning.eye_adapts = false
	await _shot(name + "_fixed", t, latitude, longitude, yaw, pitch)
	world.tuning.eye_adapts = true
	await _shot(name + "_eye", t, latitude, longitude, yaw, pitch)


## Stands you at spawn's ground at a point on the moon and a moment, facing
## yaw, looking up pitch degrees, and shoots once the light and the eye have
## settled.
func _shot(name: String, t: float, latitude: float, longitude: float, yaw: float, pitch: float) -> void:
	world.time = t
	world.time_warp = 0.0
	world.moon.place(latitude, longitude)
	_stand(yaw, pitch)
	world.weather.forecast_now()
	await _ticks(30)
	for i in 4:
		await get_tree().process_frame
	_save(name)


func _stand(yaw: float, pitch: float) -> void:
	var player := world.player
	var at := Vector3(world.engine_x(world.spawn.x), 0.0, world.engine_z(world.spawn.y))
	player.global_position = Vector3(at.x, world.height_under(at) + 1.65, at.z) - player.camera.position
	player.rotation.y = yaw
	player.camera.rotation_degrees.x = pitch


func _save(name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out.path_join(name + ".png"))
	var eye := world.weather.eye
	var on := world.tuning.eye_adapts
	var file := FileAccess.open(_out.path_join(name + ".txt"), FileAccess.WRITE)
	file.store_string("the eye, x%.1f" % eye.exposure() if on else "as before, fixed")
	# The meter rests while the eye is off; the frame's light is the same either way.
	var reading := "frame %6.2f stops, bright %6.2f" % [eye.seen, eye.seen_bright] if on else "%30s" % ""
	print("eye: %-16s %s  eye +%.2f stops x%.2f  sand L* %4.1f  light %.4f" % [name, reading, eye.stops,
		eye.exposure(), _sand(image), world.weather.seen_light])


## The eclipse from 10 s before first contact, the eye adapting as it goes,
## and its exposure each second.
func _eclipse() -> void:
	var day := world.weather.day
	var spawn_lon := world.tuning.spawn_longitude_degrees
	var mid := day.next_eclipse(0.0)
	var first := mid
	while day.sun_shown(first) < 1.0:
		first -= 0.05
	var second := first
	while day.sun_shown(second) > 0.0:
		second += 0.05
	var third := second
	while day.sun_shown(third) == 0.0:
		third += 0.05
	print("eye: eclipse: first contact %.1f, totality %.1f to %.1f s (%.1f s)" % [first, second, third, third - second])
	world.tuning.eye_adapts = false
	await _shot("totality_fixed", mid, 0.0, spawn_lon, _to_tu(mid, spawn_lon), PITCH_TO_TU)
	world.tuning.eye_adapts = true
	await _shot("before", first - BEFORE, 0.0, spawn_lon, _to_tu(mid, spawn_lon), PITCH_TO_TU)
	world.time_warp = 1.0
	var eye := world.weather.eye
	var series := PackedStringArray()
	var next_mark := ceilf(world.time)
	var shot := {}
	while world.time < third + AFTER:
		await get_tree().process_frame
		var t := world.time
		if t >= next_mark:
			series.append("%+d %.2f" % [roundi(t - second if t < third else t - third), eye.stops])
			next_mark += 1.0
		if t >= second and not shot.has("start"):
			shot["start"] = true
			_save("totality_start")
		elif t >= second + INTO_TOTALITY and not shot.has("30"):
			shot["30"] = true
			_save("totality_30s")
		elif t >= third + SUN_BACK and not shot.has("back"):
			shot["back"] = true
			_save("sun_back_1s")
	world.time_warp = 0.0
	print("eye: eclipse, s from totality's start (then from the sun's return) and stops open: %s" % ", ".join(series))


## Deep in the storm, the eye as it was in a clear day, then left to open.
func _step_in() -> void:
	var eye := world.weather.eye
	world.time_warp = 0.0
	await _ticks(10)
	eye.retina = 0.0
	eye.pupil = 0.0
	var started := Time.get_ticks_msec()
	var marks := PackedStringArray()
	for at: float in STEP_IN:
		while (Time.get_ticks_msec() - started) / 1000.0 < at:
			await get_tree().process_frame
		marks.append("%.1f s %.2f" % [at, eye.stops])
	print("eye: stepping into the storm from a clear day's eye, stops open: %s (settled %.2f)"
		% [", ".join(marks), eye.wanted(eye.seen, eye.seen_bright)])


## The GPU's time per frame with the meter, without it, and without the
## dither after the tonemap too, which the eye needs where the sky's own was
## magnified; alternated so a busy machine weighs on each alike.
func _gpu_cost() -> void:
	var viewport := get_viewport()
	var rid := viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var sums := [0.0, 0.0, 0.0]
	for round in GPU_ROUNDS:
		for way in 3:
			world.tuning.eye_adapts = way == 0
			viewport.use_debanding = way < 2
			for i in 10:
				await get_tree().process_frame
			for i in GPU_FRAMES:
				await get_tree().process_frame
				sums[way] += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	world.tuning.eye_adapts = true
	viewport.use_debanding = true
	var n := float(GPU_ROUNDS * GPU_FRAMES)
	print("eye: gpu %.3f ms a frame with the meter, %.3f without, %.3f without the dither too, at %s%s"
		% [sums[0] / n, sums[1] / n, sums[2] / n, viewport.get_visible_rect().size, _shared_gpu()])


## The sand's lightness low in the frame, the middle fifth across and the band
## from 70% to 90% down.
func _sand(image: Image) -> float:
	var size := image.get_size()
	var sum := 0.0
	var count := 0
	for y in range(int(size.y * 0.7), int(size.y * 0.9), 4):
		for x in range(int(size.x * 0.4), int(size.x * 0.6), 4):
			sum += _lightness(image.get_pixel(x, y))
			count += 1
	return sum / maxi(count, 1)


static func _lightness(c: Color) -> float:
	var y := c.srgb_to_linear().get_luminance()
	return 116.0 * pow(y, 1.0 / 3.0) - 16.0 if y > 0.008856 else 903.3 * y


## The yaw that faces Tu from spawn's latitude at a longitude, degrees.
func _to_tu(t: float, longitude: float) -> float:
	var tu := world.weather.day.tu_direction(t, 0.0, deg_to_rad(longitude))
	return atan2(-tu.x, -tu.z)


## The first world time from 0 on that's this local hour at a longitude, degrees.
func _at_hour(hour: float, longitude: float) -> float:
	var now := world.weather.day.time_of_day(0.0, deg_to_rad(longitude))
	return fposmod(hour - now, 1.0) * world.tuning.day_minutes * 60.0


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
