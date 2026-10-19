extends Node
## Look-test: the sand's own light, before and after, on seed 1234 deep in the
## dune sea nearest spawn (look/dunes' "sea"), in still air with the eye on, as
## the game plays. Each moment is shot with the sand shader given by --before
## and then with the game's own, the light, the eye and the frame unchanged:
## noon; a low sun ahead, from the ground and from 200 m up, and behind you
## where it lights what you see; dusk the same; a full-Tu night with Tu behind
## you, and by the headlamp; a walked track at midmorning; your feet at noon;
## ripples over a dune, ripples into the low sun, and a slip face from its
## foot; and close up into the
## low sun, the camera sliding a centimetre a frame and then walking on, to
## see the glitter hold still. With --storm, deep in a storm by day instead.
## It prints the ground's lightness, spread and clipped share (look/dunes'
## measure), the eye, and the GPU's frame time either way, alternated. --only
## shoots just the named shots; each --try shoots the game's shader again with
## those values, as try1, try2 and on:
##   godot --path . --disable-vsync res://look/sandlight/sandlight.tscn -- --capture <dir> --before <shader>
##       [--storm] [--only noon,slide,...] [--gpu] [--try name=value,... ...]
## look/sandlight/shoot.sh shoots both and builds the sheet. A small window that
## never takes focus, nothing but this script moving anything, and silence.

const Dunes := preload("res://look/dunes/dunes.gd")
const SEED := 1234
const EYE := 1.65
## Local hours, found by the sun's height, degrees: low, then the last light.
const LOW_SUN := 8.0
const DUSK_SUN := 1.5
const MIDMORNING := 0.4
## The track is walked from here, m off the spot, out of the other shots.
const TRACK_OFF := Vector2(0.0, 25.0)
## The glitter close up: the sun this high, looking this far down, and the
## camera sliding sideways this far a frame, m; then looking ahead, walking on
## this far a frame; this many frames each.
const CLOSE_SUN := 14.0
const CLOSE_PITCH := -38.0
const SLIDE := 0.012
const WALK_PITCH := -16.0
const STRIDE := 0.05
const MOVES := 3
## Looking down at your feet, degrees; and standing this far from a slip
## face's foot, m.
const FEET_PITCH := -68.0
const RIP_PITCH := -16.0
const SLIP_OFF := 7.0
const GPU_FRAMES := 60
const GPU_ROUNDS := 9

@onready var world: World = $World

var _storm := OS.get_cmdline_user_args().has("--storm")
var _out := ""
var _material: ShaderMaterial
var _looks := {}
var _spot := Vector2.ZERO
var _only := PackedStringArray()
## Each --try's values, shot after "after" as try1, try2, ...
var _tries: Array[Dictionary] = []
## What a try replaced, put back before the next look.
var _kept := {}


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
	_out = args[at + 1] if args.size() > at + 1 else "user://sandlight"
	_material = world.terrain.sand_material as ShaderMaterial
	_looks["after"] = _material.shader
	var before := Shader.new()
	before.code = FileAccess.get_file_as_string(args[args.find("--before") + 1])
	_looks["before"] = before
	var only := args.find("--only")
	if only != -1:
		_only = args[only + 1].split(",")
	for i in args.size() - 1:
		if args[i] == "--try":
			var values := {}
			for item in args[i + 1].split(","):
				values[item.get_slice("=", 0)] = str_to_var(item.get_slice("=", 1))
			_tries.append(values)
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
	_spot = Dunes.spots()["sea"]
	var day := world.weather.day
	var upwind := -Vector2.from_angle(WeatherField.mean_heading(SEED))
	var morning := _sun_at(LOW_SUN, true)
	world.respawn(_spot.x, _spot.y, atan2(-upwind.x, -upwind.y), morning)
	await _ground()
	for i in 600:
		if world.weather.map.ready:
			break
		await get_tree().process_frame
	for body in world.get_meta(&"kit", []):
		if is_instance_valid(body):
			body.free()
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)

	if _storm:
		player.set_physics_process(false)
		player.flying = true
		_hide_screens()
		await _pair("storm", _at_hour(MIDMORNING), atan2(-upwind.x, -upwind.y), -6.0)
		await _gpu_cost("storm")
		get_tree().quit()
		return

	# A track first, walked toward the midmorning sun, while you still walk.
	var mid := _at_hour(MIDMORNING)
	var sun := _sun(mid)
	var toward := atan2(-sun.x, -sun.z)
	var start := _spot + TRACK_OFF
	world.time = mid
	world.time_warp = 0.0
	world.teleport(player, Transform3D(Basis(Vector3.UP, toward),
		Vector3(world.engine_x(start.x), world.height_at(start.x, start.y) + 0.1, world.engine_z(start.y))))
	await _ticks(30)
	Input.action_press("move_forward")
	await _ticks(300)
	Input.action_release("move_forward")
	await _ticks(30)
	player.set_physics_process(false)
	player.flying = true
	world.terrain.tracks.set_physics_process(false)
	_hide_screens()

	var noon := _at_hour(0.5)
	await _pair("noon", noon, atan2(-upwind.x, -upwind.y), -6.0)
	await _gpu_cost("noon")
	sun = _sun(morning)
	await _pair("low_into", morning, atan2(-sun.x, -sun.z), -6.0)
	await _gpu_cost("low sun ahead")
	# Ripples into the low sun, looking down over the few metres they show in.
	await _pair("rip_into", morning, atan2(-sun.x, -sun.z), RIP_PITCH)
	# Nothing but sand in view, glinting: what the shader itself costs.
	await _pair("sand_only", morning, atan2(-sun.x, -sun.z), -50.0)
	await _gpu_cost("sand filling the frame")
	await _pair("low_behind", morning, atan2(sun.x, sun.z), -6.0, _backlit(sun))
	# The dunes from 200 m up into the low sun, a little to one side of it.
	await _pair("air_low", morning, atan2(-sun.x, -sun.z) + 0.6, -9.0, _spot, 200.0)
	var dusk := _sun_at(DUSK_SUN, false)
	sun = _sun(dusk)
	await _pair("dusk", dusk, atan2(sun.x, sun.z), -4.0, _backlit(sun))
	# And from 200 m up, the sun behind you and to one side: the crests' long shadows.
	await _pair("air_dusk", dusk, atan2(sun.x, sun.z) + 0.6, -12.0, _spot, 200.0)
	var full := day.next_eclipse(0.0) + world.tuning.day_minutes * 30.0
	var tu := day.tu_direction(full, world.moon.latitude, world.moon.longitude)
	await _pair("night", full, atan2(tu.x, tu.z), -6.0)
	# The headlamp: a light from beside your eye, all backscatter.
	var fade := roundi(world.tuning.headlamp_fade_seconds * Engine.physics_ticks_per_second) + 10
	world.player.headlamp.on = true
	await _ticks(fade)
	await _pair("lamp", full, atan2(tu.x, tu.z), -20.0)
	world.player.headlamp.on = false
	await _ticks(fade)
	# Back behind the track's start, looking along it.
	var back := Vector2(sin(toward), cos(toward)) * 2.5
	await _pair("track", mid, toward, -28.0, start + back)
	# At your feet at noon.
	await _pair("feet", noon, atan2(-upwind.x, -upwind.y), FEET_PITCH)
	var close := _sun_at(CLOSE_SUN, true)
	# Ripples over a dune: from a crest down its windward face, the sun low.
	await _pair("ripples", close, atan2(-upwind.x, -upwind.y), -10.0, _crest(-upwind) + upwind * 3.0)
	# A slip face from its foot, at the hour that lights it most.
	var toe := _toe(-upwind)
	await _pair("slip", _lighting(-upwind), atan2(-upwind.x, -upwind.y), 8.0, toe - upwind * SLIP_OFF)
	sun = _sun(close)
	var yaw := atan2(-sun.x, -sun.z)
	# Sliding sideways, looking down; then walking on, looking ahead, where
	# the glitter's cells change scale as they come nearer.
	await _moving("slide", close, yaw, CLOSE_PITCH, Vector3(cos(yaw), 0.0, -sin(yaw)) * SLIDE)
	await _moving("walk", close, yaw, WALK_PITCH, Vector3(-sin(yaw), 0.0, -cos(yaw)) * STRIDE)
	get_tree().quit()


## A few frames with each look, the camera moving by `step` a frame.
func _moving(name: String, t: float, yaw: float, pitch: float, step: Vector3) -> void:
	if not _only.is_empty() and not _only.has(name):
		return
	for look: String in _all_looks():
		_wear(look)
		_set_time(t)
		_stand(yaw, pitch, _spot + Vector2(3.0, 0.0))
		await _ticks(30)
		for i in MOVES:
			world.player.global_position += step
			for f in 3:
				await get_tree().process_frame
			_save("%s_%d_%s" % [name, i, look])


## A moment shot with each look, the eye settled on each.
func _pair(name: String, t: float, yaw: float, pitch: float, at := Vector2.INF, over := 0.0) -> void:
	if not _only.is_empty() and not _only.has(name):
		return
	for look: String in _all_looks():
		_wear(look)
		_set_time(t)
		_stand(yaw, pitch, _spot if at == Vector2.INF else at, over)
		await _ticks(30)
		for i in 6:
			await get_tree().process_frame
		_save("%s_%s" % [name, look])


func _all_looks() -> Array[String]:
	var all: Array[String] = ["before", "after"]
	for i in _tries.size():
		all.append("try%d" % (i + 1))
	return all


## Puts on a look: a try is the game's shader with its values, the rest kept.
func _wear(look: String) -> void:
	for name: String in _kept:
		_material.set_shader_parameter(name, _kept[name])
	_kept.clear()
	_material.shader = _looks.get(look, _looks.after)
	if look.begins_with("try"):
		var values: Dictionary = _tries[look.trim_prefix("try").to_int() - 1]
		for name: String in values:
			_kept[name] = _material.get_shader_parameter(name)
			if _kept[name] == null:
				_kept[name] = RenderingServer.shader_get_parameter_default(_looks.after.get_rid(), name)
			_material.set_shader_parameter(name, values[name])


func _set_time(t: float) -> void:
	world.time = t
	world.time_warp = 0.0
	world.weather.forecast_now()


func _stand(yaw: float, pitch: float, at: Vector2, over := 0.0) -> void:
	var player := world.player
	var engine := Vector3(world.engine_x(at.x), 0.0, world.engine_z(at.y))
	player.global_position = Vector3(engine.x, world.height_under(engine) + EYE + over, engine.z) - player.camera.position
	player.rotation.y = yaw
	player.camera.rotation_degrees.x = pitch


func _save(name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out.path_join(name + ".png"))
	var seen := Dunes.readability(image)
	var eye := world.weather.eye
	var sun := _sun(world.time)
	var line := "L* %.1f, spread %.1f, %.1f%% white, eye x%.1f" % [seen.x, seen.y, seen.z, eye.exposure()]
	FileAccess.open(_out.path_join(name + ".txt"), FileAccess.WRITE).store_string(line)
	var tu := world.weather.day.tu_direction(world.time, world.moon.latitude, world.moon.longitude)
	print("sandlight: %-18s sun %5.1f°, Tu %5.1f°  %s" % [name, rad_to_deg(asin(sun.y)), rad_to_deg(asin(tu.y)), line])


## The GPU's time per frame with each look, alternated so a busy machine
## weighs on both alike; and the middle of the rounds' differences, which a
## burst of someone else's load in one round moves least.
func _gpu_cost(what: String) -> void:
	if not _only.is_empty() and not OS.get_cmdline_user_args().has("--gpu"):
		return
	var sums := {"before": 0.0, "after": 0.0}
	var differences := PackedFloat32Array()
	for round in GPU_ROUNDS:
		var got := {}
		for look: String in sums:
			_wear(look)
			for i in 10:
				await get_tree().process_frame
			var sum := 0.0
			for i in GPU_FRAMES:
				await get_tree().process_frame
				sum += RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
			got[look] = sum / GPU_FRAMES
			sums[look] += got[look]
		differences.append(got.after - got.before)
	differences.sort()
	print("sandlight: gpu at %s: %.3f ms a frame before, %.3f after, %+.3f in the middle round (%+.3f to %+.3f), at %s%s"
		% [what, sums.before / GPU_ROUNDS, sums.after / GPU_ROUNDS, differences[floori(GPU_ROUNDS / 2.0)], differences[0],
		differences[GPU_ROUNDS - 1], get_viewport().get_visible_rect().size, _shared_gpu()])


## A standpoint near the spot where the sun behind you lights what you see:
## of the ground every 15 m out to 120 m away from the sun, the most that
## nothing toward the sun stands high enough to shade; the higher, on a tie.
func _backlit(sun: Vector3) -> Vector2:
	var to_sun := Vector2(sun.x, sun.z).normalized()
	var rise := sun.y / Vector2(sun.x, sun.z).length()
	var best := _spot
	var most := -INF
	for i in range(-12, 13):
		for j in range(-12, 13):
			var at := _spot + Vector2(i, j) * 20.0
			if not _sunlit(at, to_sun, rise):
				continue
			var seen := 0.0
			for d in range(15, 135, 15):
				seen += 1.0 if _sunlit(at - to_sun * d, to_sun, rise) else 0.0
			var score := seen + world.height_at(at.x, at.y) * 0.01
			if score > most:
				most = score
				best = at
	return best


## The foot of the tallest slip face within 240 m of the spot, facing `down`.
func _toe(down: Vector2) -> Vector2:
	var best := _spot
	var most := 0.0
	for i in range(-40, 41):
		for j in range(-40, 41):
			var at := _spot + Vector2(i, j) * 6.0
			var h := world.height_at(at.x, at.y)
			var ahead := at + down * 8.0
			var steep := world.height_at(at.x - down.x * 3.0, at.y - down.y * 3.0) - h > 1.5
			var flat := absf(world.height_at(ahead.x, ahead.y) - h) < 0.8
			var tall := world.height_at(at.x - down.x * 16.0, at.y - down.y * 16.0) - h
			if steep and flat and tall > most:
				most = tall
				best = at
	return best


## The highest crest within 120 m of the spot along the wind.
func _crest(down: Vector2) -> Vector2:
	var best := _spot
	for i in range(-40, 41):
		var at := _spot + down * i * 3.0
		if world.height_at(at.x, at.y) > world.height_at(best.x, best.y):
			best = at
	return best


## The morning or afternoon hour the sun lights a slip face facing `down`
## most, kept off noon's flat light.
func _lighting(down: Vector2) -> float:
	var face := Vector3(down.x * sin(0.55), cos(0.55), down.y * sin(0.55))
	var best := _at_hour(0.35)
	for k in 41:
		var hour := 0.3 + k * 0.01
		if absf(hour - 0.5) < 0.07:
			continue
		var t := _at_hour(hour)
		var sun := _sun(t)
		if sun.y > 0.2 and face.dot(sun) > face.dot(_sun(best)):
			best = t
	return best


func _sunlit(at: Vector2, to_sun: Vector2, rise: float) -> bool:
	var ground := world.height_at(at.x, at.y)
	for k in range(4, 240, 6):
		var toward := at + to_sun * k
		if world.height_at(toward.x, toward.y) > ground + k * rise:
			return false
	return true


func _sun(t: float) -> Vector3:
	return world.weather.day.sun_direction(t, world.moon.latitude, world.moon.longitude)


## The first world time the sun stands this high, degrees, rising or setting.
func _sun_at(degrees: float, rising: bool) -> float:
	var t := _at_hour(0.25 if rising else 0.5)
	var target := sin(deg_to_rad(degrees))
	for i in 4000:
		var y := _sun(t).y
		if (y >= target) if rising else (y <= target):
			return t
		t += 0.25
	return t


## The first world time from 0 on that's this local hour at spawn.
func _at_hour(hour: float) -> float:
	var now := world.weather.day.time_of_day(0.0, world.moon.longitude)
	return fposmod(hour - now, 1.0) * world.tuning.day_minutes * 60.0


func _hide_screens() -> void:
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false


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
