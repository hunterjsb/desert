extends "res://look/style/style.gd"
## Look-test: how finely the renderer draws the game's look. The art-direction
## camp in the game's own light, a walked path through it, shot under each
## graphics quality or with features tried one at a time, so a sheet sets them
## side by side; --motion shoots runs of frames instead, walking the path and
## creeping past the rope, for crawl and ghosting; --time alternates every try
## against master in rounds and prints each one's GPU time, median, and its
## difference from master either side of it.
##   godot --path . --disable-vsync res://look/render/render.tscn -- --look grey --capture <dir> [--storm]
##       [--base <key>=<value>,...] [--try <label>:<key>=<value>,...]... [--only shot,...] [--motion | --time]
## Keys: quality (low, medium, high: the game's own, as Options sets it); aa
## (none, fxaa, smaa, taa, fsr2, msaa2, msaa4, msaa8, or msaaN+smaa); ao (off,
## half, full); ao_quality (0-4); ao_blur (passes); glow (0, 1); glow_bicubic (0, 1);
## shadow (<size>:<filter 0-5>);
## env.<property>, sun.<property> and tuning.<property> for any such value.
## A try starts from master's drawing (no AA, no AO, no glow, 4096 soft-low
## shadows: low's) and --base, which master takes too. look/render/shoot.sh shoots it and builds the sheets.

## Shots: name, moment, camera and target in the camp's frame; INF, the sun, and
## -INF, Tu. Night is midnight, Tu up all night where a run begins.
const RENDER_SHOTS := [
	["camp5_noon", "noon", Vector3(1.0, 1.7, 4.9), Vector3(0.0, 0.5, 0.0)],
	["camp5_dusk", "dusk", Vector3(1.0, 1.7, 4.9), Vector3(0.0, 0.5, 0.0)],
	["camp20_noon", "noon", Vector3(4.0, 2.0, 19.6), Vector3(0.0, 0.8, 0.0)],
	["camp20_dusk", "dusk", Vector3(4.0, 2.0, 19.6), Vector3(0.0, 0.8, 0.0)],
	["rope_close", "midmorning", Vector3(-3.5, 0.95, 0.65), Vector3(-2.9, 0.55, -0.15)],
	["rope4", "midmorning", Vector3(-5.3, 1.6, 3.05), Vector3(-2.9, 0.55, -0.15)],
	["feet", "midmorning", Vector3(1.9, 0.55, 2.7), Vector3(1.2, 0.1, 0.4)],
	["sun_dusk", "dusk", Vector3(1.0, 1.7, 4.9), Vector3.INF],
	["camp5_night", "night", Vector3(1.0, 1.7, 4.9), Vector3(0.0, 0.5, 0.0)],
	["tu_night", "night", Vector3(1.0, 1.7, 4.9), -Vector3.INF],
	["storm", "storm", Vector3(0.9, 1.7, 5.2), Vector3(0.0, 0.5, 0.0)],
	["storm20", "storm", Vector3(4.0, 2.0, 19.6), Vector3(0.0, 0.8, 0.0)],
]
## The walked path, camp frame, from where it starts toward the camp.
const PATH := [Vector2(3.4, 12.0), Vector2(0.9, 2.6)]
const STRIDE := 0.36
## Motion runs: name, moment, camera and target at the start, camp frame, the
## camera's move each frame, m, and the frames shot. A walk is 2.4 cm a frame
## at 60 frames a second.
const RUNS := [
	["walk", "midmorning", Vector3(3.0, 1.6, 11.0), Vector3(1.9, 0.0, 7.0), Vector3(-0.0062, 0.0, -0.023), 30],
	["rope", "midmorning", Vector3(-5.3, 1.6, 3.05), Vector3(-2.9, 0.55, -0.15), Vector3(0.002, 0.0, 0.0), 30],
	["storm", "storm", Vector3(0.9, 1.7, 5.2), Vector3(0.0, 0.5, 0.0), Vector3(-0.004, 0.0, -0.012), 30],
]
## Timing: the views timed, frames settled after a change, frames sampled, rounds.
const TIMED := ["camp5_noon", "camp20_dusk", "storm"]
const SETTLE := 12
const SAMPLES := 30
const ROUNDS := 7

## Each try: its label and its settings, master's drawing first.
var _tries: Array = []
var _sun: DirectionalLight3D
var _environment: Environment
## The Environment and sun values as they stood before any try touched them.
var _kept := {}


func _dress() -> void:
	super()
	# A lamp on the solar chassis, its lens among the camp's glows.
	var lamp := Catalog.part(&"lamp")
	world.content.add_child(lamp)
	Stick.put(camp[2], camp[2], Chassis.TOP, Vector2(-0.3, 0.3), 0.0, lamp)
	var tracks := world.terrain.tracks
	var from: Vector2 = _to_world(Vector3(PATH[0].x, 0.0, PATH[0].y))
	var to: Vector2 = _to_world(Vector3(PATH[1].x, 0.0, PATH[1].y))
	var heading := (to - from).normalized()
	var side := 1.0
	for i in int(from.distance_to(to) / STRIDE):
		tracks._print_foot(from + heading * STRIDE * i, heading, side, Tracks.STEP_DEPTH)
		side = -side


func _ready() -> void:
	_sun = $World/Sun
	_environment = ($World/WorldEnvironment as WorldEnvironment).environment
	var args := OS.get_cmdline_user_args()
	var base := {}
	if args.has("--base"):
		base = _values(args[args.find("--base") + 1])
	_tries = [["master", base]]
	for i in args.size() - 1:
		if args[i] == "--try":
			var label := args[i + 1].get_slice(":", 0)
			_tries.append([label, base.merged(_values(args[i + 1].trim_prefix(label + ":")), true)])
	await super()


static func _values(settings: String) -> Dictionary:
	var values := {}
	for setting in settings.split(",", false):
		values[setting.get_slice("=", 0)] = setting.get_slice("=", 1)
	return values


func _shots() -> Array:
	return RENDER_SHOTS


## Master's drawing, then the try's.
func _draw(values: Dictionary) -> void:
	var window := get_window()
	for key: String in _kept:
		_holder(key).set(key.get_slice(".", 1), _kept[key])
	window.msaa_3d = Viewport.MSAA_DISABLED
	window.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	window.use_taa = false
	window.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	_environment.ssao_enabled = false
	_environment.glow_enabled = false
	RenderingServer.directional_shadow_atlas_set_size(4096, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
	_ssao(_setting("ssao/quality"), _setting("ssao/half_size"), _setting("ssao/blur_passes"))
	RenderingServer.environment_glow_set_use_bicubic_upscale(_setting("glow/upscale_mode") > 0)
	if values.has("quality"):
		Settings.quality = StringName(values.quality)
		Settings.draw(window)
	for key: String in values:
		var value: String = values[key]
		match key:
			"aa":
				for way in value.split("+"):
					match way:
						"fxaa": window.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
						"smaa": window.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA
						"taa": window.use_taa = true
						"fsr2": window.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
						"msaa2": window.msaa_3d = Viewport.MSAA_2X
						"msaa4": window.msaa_3d = Viewport.MSAA_4X
						"msaa8": window.msaa_3d = Viewport.MSAA_8X
			"ao":
				_environment.ssao_enabled = value != "off"
				_ssao(int(values.get("ao_quality", _setting("ssao/quality"))), value == "half",
					int(values.get("ao_blur", _setting("ssao/blur_passes"))))
			"glow":
				_environment.glow_enabled = value == "1"
			"glow_bicubic":
				RenderingServer.environment_glow_set_use_bicubic_upscale(value == "1")
			"shadow":
				RenderingServer.directional_shadow_atlas_set_size(int(value.get_slice(":", 0)), true)
				RenderingServer.directional_soft_shadow_filter_set_quality(int(value.get_slice(":", 1)))
			_:
				var on := _holder(key)
				if on != null:
					var property := key.get_slice(".", 1)
					if not _kept.has(key):
						_kept[key] = on.get(property)
					on.set(property, str_to_var(value))


static func _setting(name: String) -> Variant:
	return ProjectSettings.get_setting("rendering/environment/" + name)


## The renderer's SSAO quality; the rest as the project sets it.
static func _ssao(quality: int, half: bool, blur: int) -> void:
	RenderingServer.environment_set_ssao_quality(quality, half, _setting("ssao/adaptive_target"), blur,
		_setting("ssao/fadeout_from"), _setting("ssao/fadeout_to"))


## What an env., sun. or tuning. key sets, or null.
func _holder(key: String) -> Object:
	return {"env": _environment, "sun": _sun, "tuning": world.tuning}.get(key.get_slice(".", 0))


func _capture(out_dir: String, only: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	var args := OS.get_cmdline_user_args()
	if args.has("--motion"):
		await _motion(out_dir)
	elif args.has("--time"):
		await _time()
	else:
		await _stills(out_dir, only)
	print("style: done%s" % _shared_gpu())
	get_tree().quit()


func _stills(out_dir: String, only: PackedStringArray) -> void:
	var storm_at := world.time
	for shot: Array in _shots():
		if (shot[1] == "storm") != storm or (not only.is_empty() and not only.has(shot[0])):
			continue
		await _stand(shot, storm_at)
		for attempt: Array in _tries:
			_draw(attempt[1])
			for i in 30:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s_%s.png" % [shot[0], attempt[0]]))
		print("  %s" % shot[0])


## Puts the camera on a shot and its moment; a storm runs a moment so its dust moves.
func _stand(shot: Array, storm_at: float) -> void:
	var cell := generator.host().battery()
	cell.charge_wh = cell.capacity()
	_aim(shot[2], shot[3])
	await _ground()
	_aim(shot[2], shot[3])
	if storm:
		world.time = storm_at - 1.6
		world.time_warp = 1.0
		await get_tree().create_timer(0.8).timeout
	else:
		world.time = _run_time(MOMENTS.get(shot[1], 0.0))
		world.time_warp = 0.0
		for i in 20:
			await get_tree().physics_frame
	_aim(shot[2], shot[3])


func _aim(from: Vector3, at: Vector3) -> void:
	var eye := _engine(from)
	world.player.global_position = eye - _eye
	# The light's +Z points back at the sun.
	var to := _engine(at) - eye if at.is_finite() else _sun.global_basis.z if at == Vector3.INF \
		else world.weather.day.tu_direction(world.time, world.moon.latitude, world.moon.longitude)
	world.player.rotation.y = atan2(-to.x, -to.z)
	world.player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())


## Each run under each try: its frames as the camera moves, then the last
## pose held still for as long, so a ghost shows against the settled frame.
func _motion(out_dir: String) -> void:
	var storm_at := world.time
	for run: Array in RUNS:
		if (run[1] == "storm") != storm:
			continue
		await _stand([run[0], run[1], run[2], run[3]], storm_at)
		for attempt: Array in _tries:
			_draw(attempt[1])
			_aim(run[2], run[3])
			for i in 30:
				await get_tree().process_frame
			for i in run[5]:
				_aim(run[2] + run[4] * i, run[3] + run[4] * i)
				await get_tree().process_frame
				var frame := get_viewport().get_texture().get_image()
				# The middle, every frame, where crawl shows frame to frame.
				frame.get_region(Rect2i(Vector2i(640, 360), Vector2i(640, 360))).save_png(
					out_dir.path_join("%s_%s_c%02d.png" % [run[0], attempt[0], i]))
				if i == run[5] - 1:
					frame.save_png(out_dir.path_join("%s_%s_moving.png" % [run[0], attempt[0]]))
			for i in 30:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s_%s_still.png" % [run[0], attempt[0]]))
		print("  %s" % run[0])


## Every try timed against master at each timed view, as master, the try,
## master again, so drift on a shared GPU cancels: each try's median GPU time
## over the rounds, and the median of its difference from the masters either
## side of it. The tries take a new order each round.
func _time() -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var storm_at := world.time
	var order := range(1, _tries.size())
	seed(7)
	for shot: Array in _shots():
		if (shot[1] == "storm") != storm or not TIMED.has(shot[0]):
			continue
		await _stand(shot, storm_at)
		var own := {}
		var less := {}
		for round in ROUNDS:
			order.shuffle()
			var before := await _sample(rid, _tries[0][1])
			for i: int in order:
				var got := await _sample(rid, _tries[i][1])
				var after := await _sample(rid, _tries[0][1])
				own.get_or_add(i, []).append(got)
				less.get_or_add(i, []).append(got - (before + after) * 0.5)
				own.get_or_add(0, []).append(after)
				before = after
		for i in _tries.size():
			var by: Array = less.get(i, [0.0])
			by.sort()
			print("  time %-12s %-14s %6.3f ms  %+6.3f ms  (%+.3f to %+.3f)" % [shot[0], _tries[i][0],
				_median(own[i]), _median(by), by[by.size() / 4], by[by.size() * 3 / 4]])


## The median GPU time of a run of frames drawn under a try, once it has settled.
func _sample(rid: RID, values: Dictionary) -> float:
	_draw(values)
	for k in SETTLE:
		await get_tree().process_frame
	var samples: Array[float] = []
	for k in SAMPLES:
		await get_tree().process_frame
		samples.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
	return _median(samples)


static func _median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2] if sorted.size() % 2 == 1 \
		else (sorted[sorted.size() / 2 - 1] + sorted[sorted.size() / 2]) * 0.5
