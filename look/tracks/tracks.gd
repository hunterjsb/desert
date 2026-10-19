extends Node
## Look-test: tracks on seed 1234. The game itself makes a walked path, a
## board's wake and a dragged crate's groove side by side near spawn, then each
## is shot without its marks, fresh, and aged by eight minutes of storm (or 36
## of calm), in a clear day, a storm by day, a clear night, a storm at night,
## and a storm at night by a lamp like a device's, its only light. It prints
## what pressing them cost the main thread, and what drawing them costs the GPU.
## At the fixed exposure, or with --eye as the eye sees them, settled on each light:
##   godot --path . --disable-vsync res://look/tracks/tracks.tscn -- --capture <dir> [--eye]
## Optional --before <shader> compares frozen frames against that shader and its
## own defaults; --lights low,day,... narrows the captures.
## look/tracks/shoot.sh builds the sheets. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
## Each subject's start, metres east and south of spawn, the way it goes, and
## how long it's made for, s.
const WALK := Vector2(0.0, 0.0)
const DRAG := Vector2(0.0, 4.0)
const BOARD := Vector2(0.0, -5.0)
const GOUGE := Vector2(0.0, -10.0)
const WALK_SECONDS := 9.0
const DRAG_SECONDS := 8.0
const DRAG_SPEED := 1.4
const RIDE_SECONDS := 2.2
## The camera stands this far behind a start, this high, looking this far down.
const BACK := 2.5
const EYE := 1.65
const PITCH := -28.0
const LIGHTS := ["low", "day", "storm", "night", "storm_night", "storm_night_lamp"]
## Eight minutes of a full storm's filling, in fill-clock units.
const AGED := 8.0 * 60.0 / 1200.0
## Frames per sample, and samples each way, when timing the GPU.
const GPU_FRAMES := 60
const GPU_ROUNDS := 4

@onready var world: World = $World

var _times := {}
var _before: Shader
var _after: Shader
var _baseline_values := {}


func _enter_tree() -> void:
	Tuning.current().run_seed = SEED
	# The fixed exposure, not the eye's, so shots and readings compare across builds.
	Tuning.current().eye_adapts = OS.get_cmdline_user_args().has("--eye")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://tracks")


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
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	DirAccess.make_dir_recursive_absolute(out_dir)
	_times = _find_times(world.spawn)
	print("tracks: times %s" % _times)
	world.respawn(world.spawn.x, world.spawn.y, -PI * 0.5, _times.day)
	await _ground()

	var tracks := world.terrain.tracks
	var material := world.terrain.sand_material as ShaderMaterial
	_after = material.shader
	var args := OS.get_cmdline_user_args()
	var baseline := args.find("--before")
	if baseline != -1:
		_before = Shader.new()
		_before.code = FileAccess.get_file_as_string(args[baseline + 1])
		for parameter: Dictionary in RenderingServer.get_shader_parameter_list(_after.get_rid()):
			var name: String = parameter.name
			if name.begins_with("track_") and name not in ["track_map", "track_clock", "track_shift", "track_window", "track_extent", "track_texel"]:
				_baseline_values[name] = material.get_shader_parameter(name)
	# The crate, dragged east along the sand as a line would tow it.
	var crate := _crate(world.spawn + DRAG)
	await _ticks(60)
	tracks.slowest_tick_ms = 0.0
	var dragged := 0.0
	while dragged < DRAG_SECONDS:
		await get_tree().physics_frame
		dragged += get_physics_process_delta_time()
		crate.linear_velocity = Vector3(DRAG_SPEED, minf(crate.linear_velocity.y, 0.0), 0.0)
	crate.linear_velocity = Vector3.ZERO
	print("tracks: drag, slowest tick %.3f ms" % tracks.slowest_tick_ms)

	# A walk east, wandering a little.
	_put(world.spawn + WALK, -PI * 0.5)
	await _ticks(30)
	tracks.slowest_tick_ms = 0.0
	Input.action_press("move_forward")
	var walked := 0.0
	while walked < WALK_SECONDS:
		await get_tree().physics_frame
		walked += get_physics_process_delta_time()
		player.rotation.y = -PI * 0.5 + 0.25 * sin(walked * 0.7)
	Input.action_release("move_forward")
	print("tracks: walk, slowest tick %.3f ms" % tracks.slowest_tick_ms)
	await _ticks(30)

	# A short ride east, then off; the board coasts on and lies there.
	_put(world.spawn + BOARD, -PI * 0.5)
	await _ticks(30)
	var board := Catalog.device(&"board") as Hoverboard
	world.content.add_child(board)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	board.fit(cell, board.sockets()[0])
	board.global_position = player.global_position + Vector3.UP * 0.06
	await _ticks(2)
	print("tracks: on the board %s" % player.get_on(board))
	tracks.slowest_tick_ms = 0.0
	Input.action_press("move_forward")
	var rode := 0.0
	while rode < RIDE_SECONDS:
		await get_tree().physics_frame
		rode += get_physics_process_delta_time()
	Input.action_release("move_forward")
	await _ticks(40)
	print("tracks: ride, slowest tick %.3f ms" % tracks.slowest_tick_ms)
	player.step_off()
	await _ticks(180)
	print("tracks: slowest frame (uploads) %.3f ms" % tracks.slowest_frame_ms)

	player.set_physics_process(false)
	player.flying = true
	# Screens opened along the way (the suit's slots) go too.
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	print("tracks: %d tiles hold marks" % world.terrain.tracks.held_tiles())
	# Held still: nothing presses again or fills while the clock is set by hand.
	tracks.set_physics_process(false)
	# A controlled skid strip uses the same swept footprint as a board turning sideways.
	for i in 20:
		var start: Vector2 = world.spawn + GOUGE + Vector2(i * 0.6, 0.4 * sin(i * 0.12))
		var corners := tracks._footprint(start, Vector2(0.7, 0.7).normalized(), Catalog.DEVICES[&"board"].size)
		corners.append_array(tracks._footprint(start + Vector2(0.6, 0.0), Vector2(0.7, 0.7).normalized(), Catalog.DEVICES[&"board"].size))
		tracks.press_hull(corners, Tracks.DEEPEST, Tracks.GOUGE_SOFT)
	var made := tracks.clock
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	# A storm at night has no light but lamps': one like a device's, at your side.
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.85, 0.6)
	lamp.omni_range = 7.0
	lamp.position = Vector3(0.4, -0.6, -0.3)
	player.camera.add_child(lamp)
	var chosen := LIGHTS.duplicate()
	var only := args.find("--lights")
	if only != -1:
		chosen = args[only + 1].split(",")
	for light: String in chosen:
		world.time = _times[light.trim_suffix("_lamp")]
		world.time_warp = 0.0
		world.weather.forecast_now()
		lamp.visible = light.ends_with("_lamp")
		for subject: Array in [["walk", WALK], ["board", BOARD], ["gouge", GOUGE], ["drag", DRAG]]:
			var start: Vector2 = world.spawn + subject[1]
			var eye := Vector3(world.engine_x(start.x - BACK), world.height_at(start.x - BACK, start.y) + EYE,
				world.engine_z(start.y))
			player.global_position = eye - player.camera.position
			player.rotation.y = -PI * 0.5
			player.camera.rotation_degrees.x = PITCH
			# Before, every mark filled; then fresh; then aged.
			for state: Array in [["before", 10.0], ["fresh", 0.0], ["aged", AGED]]:
				tracks.clock = made + state[1]
				await _ticks(24)
				var name := "%s_%s_%s" % [subject[0], light, state[0]]
				for look: String in (["before", "after"] if _before != null else ["after"]):
					_wear(look)
					await _ticks(8)
					get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ("_" + look if _before != null else "") + ".png"))
				if light == "low" and subject[0] in ["walk", "gouge"] and state[0] == "fresh":
					await _moving(out_dir, name)
				print("  %-26s storm %3d%%" % [name, roundi(world.weather.storm * 100.0)])
			if light == "day" and subject[0] in ["walk", "gouge"]:
				tracks.clock = made
				await _gpu_cost(rid)
	get_tree().quit()


## A short lateral move shows whether the drawn floor stays attached to its rim.
func _moving(out_dir: String, name: String) -> void:
	var player := world.player
	var start := player.global_position
	for look: String in (["before", "after"] if _before != null else ["after"]):
		_wear(look)
		for frame in 12:
			player.global_position = start + Vector3(0.0, 0.0, frame * 0.025)
			await _ticks(2)
			get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s_%s_move_%02d.png" % [name, look, frame]))
	player.global_position = start
	_wear("after")


## The GPU's time per frame with the sand reading its marks and without,
## alternated so a busy machine weighs on both alike.
func _gpu_cost(rid: RID) -> void:
	var tracks := world.terrain.tracks
	var keys: Array[String] = ["before", "after"] if _before != null else ["off", "on"]
	var sums := {keys[0]: 0.0, keys[1]: 0.0}
	var differences: Array[float] = []
	for round in GPU_ROUNDS:
		var got := {}
		for look: String in keys:
			tracks.drawn = look != "off"
			if _before != null:
				_wear(look)
			for i in 10:
				await get_tree().process_frame
			var total := 0.0
			for i in GPU_FRAMES:
				await get_tree().process_frame
				total += RenderingServer.viewport_get_measured_render_time_gpu(rid)
			got[look] = total / GPU_FRAMES
			sums[look] += got[look]
		differences.append(got[keys[1]] - got[keys[0]])
	tracks.drawn = true
	_wear("after")
	differences.sort()
	print("tracks: gpu %.3f ms %s, %.3f ms %s; median delta %+.3f (%+.3f to %+.3f), at %s%s" % [
		sums[keys[0]] / GPU_ROUNDS, keys[0], sums[keys[1]] / GPU_ROUNDS, keys[1],
		(differences[1] + differences[2]) * 0.5, differences[0], differences[-1],
		get_viewport().get_visible_rect().size, _shared_gpu()])


## Keep baseline defaults with its shader; the live scene otherwise retains tuning overrides.
func _wear(look: String) -> void:
	var material := world.terrain.sand_material as ShaderMaterial
	material.shader = _before if look == "before" else _after
	for name: String in _baseline_values:
		material.set_shader_parameter(name, null if look == "before" else _baseline_values[name])


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""


## The first clear midmorning and clear midnight at a place, and the first day
## and night moments it's stood deep in a storm a while.
func _find_times(at: Vector2) -> Dictionary:
	var field := world.weather.field
	var day := world.weather.day
	var found := {}
	var t := 120.0
	while t < 6.0 * 24.0 * 3600.0 and found.size() < 5:
		var hour := day.time_of_day(t, world.moon.longitude)
		var storm := field.storm_at(at.x, at.y, t)
		var held := storm >= 1.0 and field.storm_at(at.x, at.y, t - 60.0) >= 1.0 \
			and field.storm_at(at.x, at.y, t - 120.0) >= 1.0
		var clear := field.raw_storm_at(at.x, at.y, t) < -0.1 and field.raw_storm_at(at.x, at.y, t + 60.0) < -0.1
		var lit := hour > 0.38 and hour < 0.55
		var dark := hour > 0.96 or hour < 0.04
		var sun := day.sun_direction(t, world.moon.latitude, world.moon.longitude)
		if clear and sun.y > 0.1 and sun.y < 0.2 and not found.has("low"):
			found["low"] = t
		if lit and clear and not found.has("day"):
			found["day"] = t
		elif lit and held and not found.has("storm"):
			found["storm"] = t
		elif dark and clear and not found.has("night"):
			found["night"] = t
		elif dark and held and not found.has("storm_night"):
			found["storm_night"] = t
		t += 10.0
	return found


func _crate(at: Vector2) -> RigidBody3D:
	var body := RigidBody3D.new()
	var holder := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.4, 0.5)
	holder.shape = box
	body.add_child(holder)
	var look := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	look.mesh = mesh
	body.add_child(look)
	body.mass = 10.0
	world.content.add_child(body)
	body.global_position = Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 0.25, world.engine_z(at.y))
	return body


func _put(at: Vector2, yaw: float) -> void:
	world.teleport(world.player, Transform3D(Basis(Vector3.UP, yaw),
		Vector3(world.engine_x(at.x), world.height_at(at.x, at.y) + 0.1, world.engine_z(at.y))))
	world.player.velocity = Vector3.ZERO


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
