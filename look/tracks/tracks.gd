extends Node
## Look-test: tracks on seed 1234. The game itself makes a walked path, a
## board's wake and a dragged crate's groove side by side near spawn, then each
## is shot without its marks, fresh, and aged by eight minutes of storm (or 36
## of calm), in a clear day, a storm by day, a clear night, a storm at night,
## and a storm at night by a lamp like a device's, its only light. It prints
## what pressing them cost the main thread, and what drawing them costs the GPU:
##   godot --path . --disable-vsync res://look/tracks/tracks.tscn -- --capture <dir>
## look/tracks/shoot.sh builds the sheets. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
## Each subject's start, metres east and south of spawn, the way it goes, and
## how long it's made for, s.
const WALK := Vector2(0.0, 0.0)
const DRAG := Vector2(0.0, 4.0)
const BOARD := Vector2(0.0, -5.0)
const WALK_SECONDS := 9.0
const DRAG_SECONDS := 8.0
const DRAG_SPEED := 1.4
const RIDE_SECONDS := 2.2
## The camera stands this far behind a start, this high, looking this far down.
const BACK := 2.5
const EYE := 1.65
const PITCH := -28.0
const LIGHTS := ["day", "storm", "night", "storm_night", "storm_night_lamp"]
## Eight minutes of a full storm's filling, in fill-clock units.
const AGED := 8.0 * 60.0 / 1200.0
## Frames per sample, and samples each way, when timing the GPU.
const GPU_FRAMES := 60
const GPU_ROUNDS := 4

@onready var world: World = $World

var _times := {}


func _enter_tree() -> void:
	Tuning.current().run_seed = SEED


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
	var made := tracks.clock
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	# A storm at night has no light but lamps': one like a device's, at your side.
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.85, 0.6)
	lamp.omni_range = 7.0
	lamp.position = Vector3(0.4, -0.6, -0.3)
	player.camera.add_child(lamp)
	for light: String in LIGHTS:
		world.time = _times[light.trim_suffix("_lamp")]
		world.time_warp = 1.0
		lamp.visible = light.ends_with("_lamp")
		for subject: Array in [["walk", WALK], ["board", BOARD], ["drag", DRAG]]:
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
				get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
				print("  %-26s storm %3d%%" % [name, roundi(world.weather.storm * 100.0)])
			if light == "day" and subject[0] == "walk":
				tracks.clock = made
				await _gpu_cost(rid)
	get_tree().quit()


## The GPU's time per frame with the sand reading its marks and without,
## alternated so a busy machine weighs on both alike.
func _gpu_cost(rid: RID) -> void:
	var tracks := world.terrain.tracks
	var sums := {true: 0.0, false: 0.0}
	for round in GPU_ROUNDS:
		for drawn in [false, true]:
			tracks.drawn = drawn
			for i in 10:
				await get_tree().process_frame
			for i in GPU_FRAMES:
				await get_tree().process_frame
				sums[drawn] += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	tracks.drawn = true
	var n := float(GPU_ROUNDS * GPU_FRAMES)
	print("tracks: gpu %.3f ms a frame drawing marks, %.3f without, at %s%s" % [sums[true] / n, sums[false] / n,
		get_viewport().get_visible_rect().size, _shared_gpu()])


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
	while t < 6.0 * 24.0 * 3600.0 and found.size() < 4:
		var hour := day.time_of_day(t)
		var storm := field.storm_at(at.x, at.y, t)
		var held := storm >= 1.0 and field.storm_at(at.x, at.y, t - 60.0) >= 1.0 \
			and field.storm_at(at.x, at.y, t - 120.0) >= 1.0
		var clear := field.raw_storm_at(at.x, at.y, t) < -0.1 and field.raw_storm_at(at.x, at.y, t + 60.0) < -0.1
		var lit := hour > 0.38 and hour < 0.55
		var dark := hour > 0.96 or hour < 0.04
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
