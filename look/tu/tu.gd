extends Node
## Look-test: Tu close, on seed 1234 where a run begins, in clear, still air,
## the eye on as the game plays. Each size under trial on a full-Tu night, at
## dusk and at mid-totality: the whole frame, and Tu cut from it and blown up
## pixel for pixel. The default size close through a narrow view, at the
## eye's opening for the whole frame. The spin: the same three minutes, one
## true turn, watched at each rate under trial. It prints where Tu sits in
## each frame and how wide, and times the sky against the stock one with Tu
## in view and with Tu filling it:
##   godot --path . --disable-vsync res://look/tu/tu.tscn -- --capture <dir> [--only sizes,close,spin,gpu]
## look/tu/shoot.sh builds the sheet. A small window that never takes focus,
## nothing but this script moving anything, and silence.

const SEED := 1234
## Looking at Tu from where a run begins: up this far, so it sits high in frame.
const PITCH_TO_TU := 12.0
## Dusk: this local hour, the sun just down behind Tu's crescent.
const DUSK := 0.76
## The red spot's longitude on Tu and its drift, as sky.gdshader sets it,
## so each night shot has it in view, this far past the middle of the face.
const SPOT_LON := 0.35
const SPOT_RATE := 1.5e-5
const SPOT_SEEN := -0.35
## Tu cut from the frame: this many of its radii across, blown up to about this wide.
const CUT := 2.5
const CUT_PX := 480
## The close view: Tu across this share of the frame's height.
const CLOSE := 0.85
## The spin's rates under trial, turns a day as seen from Zan; 0 is true to scale.
const RATES := [0.0, 3.0, 1.0]
const STRIP := 8
const GPU_FRAMES := 60
const GPU_ROUNDS := 4

@onready var world: World = $World

var _out := ""
var _only: PackedStringArray = []


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = true
	tuning.salvage = false
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
	_out = args[at + 1] if args.size() > at + 1 else "user://tu"
	var only := args.find("--only")
	if only != -1 and args.size() > only + 1:
		_only = args[only + 1].split(",")
	_capture()


func _wants(group: String) -> bool:
	return _only.is_empty() or _only.has(group)


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
	var default_size := tuning.tu_degrees
	print("tu: real day %.1f h at %d°, %.2f turns a day seen from Zan, one each %.0f s"
		% [day.real_day_hours(), roundi(tuning.tu_degrees), day.tu_turns(), tuning.day_minutes * 60.0 / day.tu_turns()])
	if _wants("sizes"):
		for degrees: float in DayCycle.TU_SIZES:
			tuning.tu_degrees = degrees
			var size := "tu%d" % degrees
			var mid := day.next_eclipse(0.0)
			await _shot("%s_night" % size, _spot_in_view(mid + tuning.day_minutes * 30.0), PITCH_TO_TU, true)
			await _shot("%s_dusk" % size, _at_hour(DUSK), PITCH_TO_TU, true)
			await _shot("%s_eclipse" % size, mid, PITCH_TO_TU, true)
		tuning.tu_degrees = default_size
	var night := _spot_in_view(day.next_eclipse(0.0) + tuning.day_minutes * 30.0)
	if _wants("close"):
		await _close("tu9_close", night)
	if _wants("spin"):
		var turn := tuning.day_minutes * 60.0 / day.tu_turns()
		var hours := tuning.tu_spin_hours
		for rate: float in RATES:
			if rate > 0.0:
				tuning.tu_spin_hours = day.real_day_hours() / (rate + 1.0)
			var name := "true" if rate == 0.0 else "%d" % rate
			for k in STRIP:
				await _shot("spin_%s_%d" % [name, k], night + turn * k / STRIP, PITCH_TO_TU, true, 3)
			tuning.tu_spin_hours = hours
	if _wants("gpu"):
		await _gpu_cost(night)
	get_tree().quit()


## Stands you at spawn facing Tu at a moment, looking up pitch degrees, and
## saves the frame once the eye has settled; and Tu cut from it, blown up
## pixel for pixel, `scale` times or as near CUT_PX as whole pixels go.
func _shot(name: String, t: float, pitch: float, cut := false, scale := 0) -> void:
	_stand(t, pitch)
	await _settle()
	var image := get_viewport().get_texture().get_image()
	if scale == 0:
		image.save_png(_out.path_join(name + ".png"))
	var disc := _disc()
	if cut:
		var side := ceili(disc.z * CUT)
		var corner := Vector2i(roundi(disc.x) - side / 2, roundi(disc.y) - side / 2)
		var piece := image.get_region(Rect2i(corner, Vector2i(side, side)))
		var times := scale if scale > 0 else maxi(1, CUT_PX / side)
		piece.resize(side * times, side * times, Image.INTERPOLATE_NEAREST)
		piece.save_png(_out.path_join(name + "_cut.png"))
	_say(name, t, disc)


## Tu through a narrow view, across CLOSE of the frame, at the eye's opening
## for the whole frame, so it's as bright as it shows in the game.
func _close(name: String, t: float) -> void:
	_stand(t, PITCH_TO_TU)
	await _settle()
	var tuning := world.tuning
	var exposure := tuning.exposure
	tuning.exposure = exposure * world.weather.eye.exposure()
	tuning.eye_adapts = false
	var tu := world.weather.day.tu_direction(t, world.moon.latitude, world.moon.longitude)
	var radius := world.weather.day.tu_radius()
	var fov := world.player.feel._fov
	world.player.feel._fov = rad_to_deg(2.0 * atan(tan(radius) / CLOSE))
	world.player.camera.rotation.x = asin(tu.y)
	for i in 8:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
	_say(name, t, _disc())
	world.player.feel._fov = fov
	tuning.exposure = exposure
	tuning.eye_adapts = true


func _stand(t: float, pitch: float) -> void:
	world.time = t
	world.time_warp = 0.0
	world.moon.place(0.0, world.tuning.spawn_longitude_degrees)
	world.weather.forecast_now()
	var player := world.player
	var at := Vector3(world.engine_x(world.spawn.x), 0.0, world.engine_z(world.spawn.y))
	player.global_position = Vector3(at.x, world.height_under(at) + 1.65, at.z) - player.camera.position
	var tu := world.weather.day.tu_direction(t, 0.0, deg_to_rad(world.tuning.spawn_longitude_degrees))
	player.rotation.y = atan2(-tu.x, -tu.z)
	player.camera.rotation_degrees.x = pitch


## Tu's middle on screen and its radius, px.
func _disc() -> Vector3:
	var camera := world.player.camera
	var day := world.weather.day
	var tu := day.tu_direction(world.time, world.moon.latitude, world.moon.longitude)
	var middle := camera.unproject_position(camera.global_position + tu * 100.0)
	var side := tu.cross(Vector3.UP).normalized()
	var edge := camera.unproject_position(camera.global_position + tu.rotated(side, day.tu_radius()) * 100.0)
	return Vector3(middle.x, middle.y, middle.distance_to(edge))


func _say(name: String, t: float, disc: Vector3) -> void:
	var day := world.weather.day
	var moon := world.moon
	print("tu: %-16s %d°, %.3f local, %.0f%% lit, turned %.2f rad, Tu %d px across at (%d, %d), eye x%.2f"
		% [name, roundi(world.tuning.tu_degrees), day.time_of_day(t, moon.longitude), day.tu_lit(t) * 100.0,
			day.tu_turn(t), roundi(disc.z * 2.0), roundi(disc.x), roundi(disc.y), world.weather.eye.exposure()])


## The moment within half a turn of t either way that brings the red spot
## SPOT_SEEN past the middle of the face.
func _spot_in_view(t: float) -> float:
	var day := world.weather.day
	var turn := world.tuning.day_minutes * 60.0 / day.tu_turns()
	var best := t
	var nearest := INF
	for i in 240:
		var at := t + turn * (i / 240.0 - 0.5)
		var off := absf(wrapf(SPOT_LON + SPOT_RATE * at + day.tu_turn(at) - SPOT_SEEN, -PI, PI))
		if off < nearest:
			nearest = off
			best = at
	return best


## The first world time from 0 on that's this local hour where a run begins.
func _at_hour(hour: float) -> float:
	var day := world.weather.day
	var now := day.time_of_day(0.0, deg_to_rad(world.tuning.spawn_longitude_degrees))
	return fposmod(hour - now, 1.0) * world.tuning.day_minutes * 60.0


## The GPU's time per frame with this sky and with the stock one, on a
## full-Tu night: Tu in view as the game shows it, and Tu filling the frame,
## where every pixel pays for its clouds. Alternated so a busy machine weighs
## on each alike.
func _gpu_cost(night: float) -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var environment: Environment = (world.get_node("WorldEnvironment") as WorldEnvironment).environment
	var ours := environment.sky.sky_material
	var stock := ProceduralSkyMaterial.new()
	stock.sky_horizon_color = Color(0.86, 0.78, 0.66)
	stock.ground_horizon_color = Color(0.86, 0.78, 0.66)
	var radius := world.weather.day.tu_radius()
	var fov := world.player.feel._fov
	for view: String in ["in view", "filling the frame"]:
		_stand(night, PITCH_TO_TU)
		if view != "in view":
			var tu := world.weather.day.tu_direction(night, 0.0, deg_to_rad(world.tuning.spawn_longitude_degrees))
			world.player.feel._fov = rad_to_deg(2.0 * atan(tan(radius) * 0.6))
			world.player.camera.rotation.x = asin(tu.y)
		await _settle()
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
		print("tu: gpu %s: %.3f ms a frame with this sky, %.3f with the stock one, Tu %d px across%s"
			% [view, sums[0] / n, sums[1] / n, roundi(_disc().z * 2.0), _shared_gpu()])
		world.player.feel._fov = fov


## Another Godot on the same GPU skews frame times; say so beside them.
func _shared_gpu() -> String:
	var out: Array = []
	OS.execute("pgrep", ["-x", "godot"], out)
	var count := (out[0] as String).strip_edges().split("\n", false).size() if not out.is_empty() else 0
	return "  [%d other Godot running: times may be skewed]" % (count - 1) if count > 1 else ""


## Long enough for the eye to snap to a cut and the frame to show it.
func _settle() -> void:
	for i in 20:
		await get_tree().physics_frame
	await _frames(4)


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
