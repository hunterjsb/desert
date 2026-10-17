extends Node
## Look-test: Tu and Zan's day on seed 1234, in clear, still air. Each size
## under trial is shot at the same moments where a run begins: local noon with
## the eclipse coming, the sun just short of Tu, totality, and a full-Tu night,
## looking at Tu and away from it at its ground; and Tu low behind the dune at
## dawn. Then the far side's stars, and the default size's full-Tu ground at a
## few Tu-shine scales. It prints what it shot and times the sky shader against the stock
## sky at 1920x1080:
##   godot --path . --disable-vsync res://look/sky/sky.tscn -- --capture <dir>
## look/sky/shoot.sh builds the sheets. A small window that never takes focus,
## nothing but this script moving anything, and silence.

const SEED := 1234
## Looking at Tu from where a run begins: up this far, so it sits high in frame.
const PITCH_TO_TU := 12.0
## Seconds before first contact for the shot of the eclipse coming.
const BEFORE := 10.0
## Degrees east of the point under Tu that stand Tu 12° up, due west, just
## over the dune west of spawn.
const LOW_AT := 78.0
## The far side's shot: latitude, so the pole star stands this high.
const FAR_LATITUDE := 30.0
const NIGHT_SCALES := [1.0, 3.0, 10.0]
const GPU_FRAMES := 60
const GPU_ROUNDS := 3

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	# The fixed exposure, not the eye's, so shots and readings compare across builds.
	tuning.eye_adapts = false
	# No storm anywhere, and still air, so nothing but the sky changes.
	tuning.storm_threshold = 10.0
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
	_capture(args[at + 1] if args.size() > at + 1 else "user://sky")


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
	player.set_physics_process(false)
	player.flying = true
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	# The run's kit stands at spawn and would fill the view.
	for body in world.get_meta(&"kit", []):
		if is_instance_valid(body):
			body.free()

	var tuning := world.tuning
	var day := world.weather.day
	var spawn_lon := tuning.spawn_longitude_degrees
	var tu_lon := tuning.tu_longitude_degrees
	for degrees: float in DayCycle.TU_SIZES:
		tuning.tu_degrees = degrees
		var size := "tu%d" % degrees
		var mid := day.next_eclipse(0.0)
		var first := mid
		while day.sun_shown(first) < 1.0:
			first -= 0.1
		var noon := _at_hour(0.5, spawn_lon)
		await _shot(out_dir, "%s_noon" % size, noon, 0.0, spawn_lon, _to_tu(noon, spawn_lon), PITCH_TO_TU)
		await _shot(out_dir, "%s_before" % size, first - BEFORE, 0.0, spawn_lon, _to_tu(first, spawn_lon), PITCH_TO_TU)
		await _shot(out_dir, "%s_totality" % size, mid, 0.0, spawn_lon, _to_tu(mid, spawn_lon), PITCH_TO_TU)
		var full := mid + tuning.day_minutes * 30.0
		await _shot(out_dir, "%s_night" % size, full, 0.0, spawn_lon, _to_tu(full, spawn_lon), PITCH_TO_TU)
		await _shot(out_dir, "%s_ground" % size, full, 0.0, spawn_lon, _to_tu(full, spawn_lon) + PI, -6.0)
		var dawn := _at_hour(0.27, tu_lon + LOW_AT)
		await _shot(out_dir, "%s_low" % size, dawn, 0.0, tu_lon + LOW_AT, _to_tu(dawn, tu_lon + LOW_AT), 3.0)

	tuning.tu_degrees = DayCycle.TU_SIZES[-1]
	var midnight := _at_hour(0.0, tu_lon + 180.0)
	await _shot(out_dir, "far_side", midnight, FAR_LATITUDE, tu_lon + 180.0, 0.0, 18.0)
	var full_night := day.next_eclipse(0.0) + tuning.day_minutes * 30.0
	for scale: float in NIGHT_SCALES.slice(1):
		tuning.tu_shine_scale = scale
		await _shot(out_dir, "ground_x%d" % scale, full_night, 0.0, spawn_lon, _to_tu(full_night, spawn_lon) + PI, -6.0)
	tuning.tu_shine_scale = 1.0

	await _gpu_cost(full_night, midnight, tu_lon)
	get_tree().quit()


## Stands you at spawn's ground at a point on the moon and a moment, facing
## yaw, looking up pitch degrees, and shoots once the light has settled.
func _shot(out_dir: String, name: String, t: float, latitude: float, longitude: float, yaw: float,
		pitch: float) -> void:
	world.time = t
	world.time_warp = 0.0
	world.moon.place(latitude, longitude)
	world.weather.forecast_now()
	var player := world.player
	var at := Vector3(world.engine_x(world.spawn.x), 0.0, world.engine_z(world.spawn.y))
	player.global_position = Vector3(at.x, world.height_under(at) + 1.65, at.z) - player.camera.position
	player.rotation.y = yaw
	player.camera.rotation_degrees.x = pitch
	await _ticks(20)
	for i in 4:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	var moon := world.moon
	var day := world.weather.day
	var tu := day.tu_direction(t, moon.latitude, moon.longitude)
	print("sky: %-14s %d°, %.3f local, Tu %.1f° up, %.0f%% lit, sun %.0f%% shown, Tu-shine %.4f, light %.3f, %.0f °C"
		% [name, roundi(world.tuning.tu_degrees), day.time_of_day(t, moon.longitude), rad_to_deg(asin(tu.y)), day.tu_lit(t) * 100.0,
			day.sun_shown(t) * 100.0, world.weather.sky.tu_seen, world.weather.seen_light,
			world.weather.field_temperature(player.global_position, t)])


## The yaw that faces Tu from spawn's latitude at a longitude, degrees.
func _to_tu(t: float, longitude: float) -> float:
	var tu := world.weather.day.tu_direction(t, 0.0, deg_to_rad(longitude))
	return atan2(-tu.x, -tu.z)


## The first world time from 0 on that's this local hour at a longitude, degrees.
func _at_hour(hour: float, longitude: float) -> float:
	var now := world.weather.day.time_of_day(0.0, deg_to_rad(longitude))
	return fposmod(hour - now, 1.0) * world.tuning.day_minutes * 60.0


## The GPU's time per frame with this sky and with the stock one, by day
## facing Tu and on the far side's starry night, alternated so a busy machine
## weighs on each alike; and with Tu-shine on and off by night.
func _gpu_cost(full_night: float, midnight: float, tu_lon: float) -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var environment: Environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var ours := environment.sky.sky_material
	var stock := ProceduralSkyMaterial.new()
	stock.sky_horizon_color = Color(0.86, 0.78, 0.66)
	stock.ground_horizon_color = Color(0.86, 0.78, 0.66)
	var tuning := world.tuning
	var spawn_lon := tuning.spawn_longitude_degrees
	var views := {
		"day": [world.weather.day.next_eclipse(0.0) - 120.0, 0.0, spawn_lon, PITCH_TO_TU],
		"stars": [midnight, FAR_LATITUDE, tu_lon + 180.0, 18.0],
	}
	for view: String in views:
		var v: Array = views[view]
		await _shot("user://", "gpu_" + view, v[0], v[1], v[2], _to_tu(v[0], v[2]) if view == "day" else 0.0, v[3])
		var sums := [0.0, 0.0]
		for round in GPU_ROUNDS:
			for way in 2:
				environment.sky.sky_material = ours if way == 0 else stock
				await _frames(10)
				for i in GPU_FRAMES:
					await get_tree().process_frame
					sums[way] += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		environment.sky.sky_material = ours
		var n := float(GPU_ROUNDS * GPU_FRAMES)
		print("sky: gpu %s: %.3f ms a frame with this sky, %.3f with the stock one, at %s%s"
			% [view, sums[0] / n, sums[1] / n, get_viewport().get_visible_rect().size, _shared_gpu()])
	await _shot("user://", "gpu_night", full_night, 0.0, spawn_lon, _to_tu(full_night, spawn_lon) + PI, -6.0)
	var lit := [0.0, 0.0]
	for round in GPU_ROUNDS:
		for way in 2:
			tuning.tu_shine_scale = 1.0 if way == 0 else 0.0
			await _frames(10)
			for i in GPU_FRAMES:
				await get_tree().process_frame
				lit[way] += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	tuning.tu_shine_scale = 1.0
	var n := float(GPU_ROUNDS * GPU_FRAMES)
	print("sky: gpu night: %.3f ms a frame with Tu-shine and its shadows, %.3f without%s"
		% [lit[0] / n, lit[1] / n, _shared_gpu()])


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


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
