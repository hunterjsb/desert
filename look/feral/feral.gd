extends Node
## Look-test: the feral layer on seed 1234, by a pilgrim road out of Sister on
## a clear morning. The saltbush line across the dunes from a distance and
## down its length, a wild bush close up, and the same bush folded shut with
## a storm a minute off:
##   godot --path . --disable-vsync res://look/feral/feral.tscn -- --capture <dir> [--bare]
## look/feral/shoot.sh builds the sheet. Each shot says what its frame costs
## the GPU; --bare shoots the same views without the wild plants, to compare.
## A small window that never takes focus, nothing but this script moving
## anything, and silence.

const SEED := 1234
## Where along the first pilgrim road it's shot, as a share of its length.
const ALONG := 0.45
## The time of day the morning shots are taken at.
const MORNING := 0.36
## [name, metres off the road to the side, metres along it, eye over the
## sand, the spot looked at along the road, its height, field of view].
var SHOTS := [
	["across", 120.0, 0.0, 5.0, 0.0, 0.4, 30.0],
	["down", 14.0, -40.0, 2.2, 90.0, 0.3, 55.0],
	["close", 3.4, -1.2, 1.5, 0.0, 0.35, 50.0],
]

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	# For what they cost on the GPU: the same views without them.
	tuning.feral = not OS.get_cmdline_user_args().has("--bare")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://feral")


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
	player.hands.set_process(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _settled()
	var history := world.shape.history
	var road: PathNetwork.Path = null
	for path in history.network.paths:
		if path.kind == &"pilgrim_road":
			road = path
			break
	var p := road.at(road.length() * ALONG)
	# As travel lands you, but on fresh ground in a sea of dunes, so the road runs over them.
	var off := (world.tuning.history_lay_m + world.tuning.history_cell_m) * 2.0 + world.history_due()
	var dunes := _dunes_from(Vector2(world.player_world_x() + off, world.player_world_z()))
	world.respawn(dunes.x, dunes.y, 0.0, _morning(p))
	world.moon.place(rad_to_deg(Sphere.latitude(p)), rad_to_deg(Sphere.longitude(p)))
	player.flying = true
	player.set_physics_process(false)
	player.feel.set_process(false)
	await _settled()
	# The road through where you stand, on the ground: its middle and which way it runs.
	var here := Vector2(world.player_world_x(), world.player_world_z())
	var run := _road_at(here)
	var across := Vector2(-run.y, run.x)
	var bush := _nearest_bush(here)
	# Across from the highest ground off the road, looking down on it.
	var high := 0.0
	for side in range(90, 171, 10):
		for sign: float in [1.0, -1.0]:
			var spot := here + across * side * sign
			var h := world.shape.height_at(spot.x, spot.y)
			if h - world.shape.height_at(here.x, here.y) > high:
				high = h - world.shape.height_at(here.x, here.y)
				SHOTS[0][1] = side * sign
	for shot: Array in SHOTS:
		var eye: Vector2 = here + across * shot[1] + run * shot[2]
		var target: Vector2 = here + run * shot[4]
		if shot[0] == "close":
			eye = bush + (eye - here)
			target = bush
		await _shoot(out_dir, shot[0], eye, shot[3], target, shot[5], shot[6])
	# Folded: the same bush with a storm a minute off it, in daylight.
	var arrives := _storm_by_day(bush)
	if is_finite(arrives):
		world.time_warp = 0.0
		world.time = arrives - 130.0
		await _ticks(4)
		world.time_warp = 10.0
		while world.time < arrives - 60.0:
			await get_tree().physics_frame
		world.time_warp = 0.0
		var shot: Array = SHOTS[2]
		await _shoot(out_dir, "folded", bush + across * shot[1] + run * shot[2], shot[3], bush, shot[5], shot[6])
		await _shoot(out_dir, "folded_across", here + across * 60.0, 3.0, here, 0.4, 45.0)
	else:
		print("feral: no storm by day")
	get_tree().quit()


func _shoot(out_dir: String, name: String, eye: Vector2, up: float, target: Vector2, target_up: float,
		fov: float) -> void:
	var player := world.player
	var from := Vector3(world.engine_x(eye.x), world.height_at(eye.x, eye.y) + up, world.engine_z(eye.y))
	player.global_position = from - player.camera.position
	await _settled()
	from = Vector3(world.engine_x(eye.x), world.height_at(eye.x, eye.y) + up, world.engine_z(eye.y))
	player.global_position = from - player.camera.position
	var to := Vector3(world.engine_x(target.x), world.height_at(target.x, target.y) + target_up, world.engine_z(target.y))
	var dir := to - from
	player.rotation = Vector3(0.0, atan2(-dir.x, -dir.z), 0.0)
	player.camera.rotation = Vector3(atan2(dir.y, Vector2(dir.x, dir.z).length()), 0.0, 0.0)
	player.camera.fov = fov
	await _ticks(20)
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	# What the frame costs here, the GPU's own time for it, over two seconds.
	var gpu := 0.0
	var frames := 0
	var viewport := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	var until := Time.get_ticks_msec() + 2000
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
		frames += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("feral: %s, %.2f ms on the GPU a frame, %d drawn" % [name, gpu / frames,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])


## Which way the nearest laid pilgrim road runs past a place, on the ground.
func _road_at(here: Vector2) -> Vector2:
	var best := INF
	var run := Vector2.RIGHT
	for piece in world.shape.sites.paths_in(Rect2(here, Vector2.ZERO).grow(300.0)):
		if piece.kind != &"pilgrim_road":
			continue
		for i in piece.points.size() - 1:
			var a := piece.points[i]
			var b := piece.points[i + 1]
			var d := Geometry2D.get_closest_point_to_segment(here, a, b).distance_to(here)
			if d < best:
				best = d
				run = (b - a).normalized()
	return run


func _nearest_bush(here: Vector2) -> Vector2:
	var best := INF
	var at := here
	for plant in world.farm.feral.standing():
		if plant.crop != &"saltbush":
			continue
		var foot := world.farm.feral.foot_of(plant)
		var spot := Vector2(world.world_x(foot.x), world.world_z(foot.z))
		if spot.distance_to(here) < best:
			best = spot.distance_to(here)
			at = spot
	return at


## Where the dunes run high, east of a place.
func _dunes_from(at: Vector2) -> Vector2:
	var shape := world.shape
	for k in 200:
		var spot := at + Vector2(250.0 * k, 0.0)
		var low := INF
		var top := -INF
		for j in 5:
			for i in 5:
				var h := shape.height_at(spot.x + (i - 2) * 75.0, spot.y + (j - 2) * 75.0)
				low = minf(low, h)
				top = maxf(top, h)
		if top - low > 8.0 and shape.sand_at(spot.x, spot.y) > 0.75:
			return spot
	return at


## The first local morning there with the sun clear of Tu.
func _morning(p: Vector3) -> float:
	var day := world.weather.day
	var t := 0.0
	while day.time_of_day(t, Sphere.longitude(p)) < MORNING - 0.01 or day.time_of_day(t, Sphere.longitude(p)) > MORNING \
			or day.sunlight(t, Sphere.latitude(p), Sphere.longitude(p)) < 0.4:
		t += 5.0
	return t


## When the first storm after now reaches a place with the sun well up, clear
## before it.
func _storm_by_day(at: Vector2) -> float:
	var field := world.weather.field
	var day := world.weather.day
	var t := world.time
	for k in 400:
		var change := field.next_change(at.x, at.y, t, 3600.0, Weather.FORECAST_STEP)
		if change == INF:
			t += 3600.0
			continue
		t += change
		if field.raw_storm_at(at.x, at.y, t + 1.0) > 0.0 \
				and day.sunlight(t - 60.0, world.moon.latitude, world.moon.longitude) > 0.4 \
				and field.next_change(at.x, at.y, t - 200.0, 190.0, Weather.FORECAST_STEP) == INF:
			return t
	return INF


func _settled() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle() or not world.farm.feral.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
