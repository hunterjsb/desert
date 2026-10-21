extends Node
## Look-test: the satellites in the night sky, on seed 1234. The "night"
## scenario's clear night, waited on until several are up and in the sun's
## light; then the view turned on each in turn, so it stands in the middle of
## the frame, and a crop round it blown up four times without smoothing, so
## its shape, colour and size can be judged against the stars; it prints how
## high each is, how far from Tu, and how bright it shows. One shot of the
## whole sky toward the most of them too. Clear skies everywhere, and your eyes
## up over the dunes, so nothing stands in the way of a low one.
##   godot --path . --disable-vsync res://look/satellites/satellites.tscn -- --capture <dir> [--only <id>]
## With --only, it waits for that one to be up and lit by night and shoots it alone.
## A small window that never takes focus, nothing but this script moving
## anything, and silence.

const SEED := 1234
## Your eyes this far over the sand, m, clear of the dunes.
const RISE := 80.0
## At least this many up and lit before it shoots, and at least this high, degrees.
const WANTED := 4
const LOW := 15.0
## Aimed this far off each, degrees; the crop round it, pixels, and how far
## it's blown up.
const OFF := 3.0
const CROP := 96
const BLOW := 4

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	# Clear skies everywhere: no far storm wall standing over the low sky.
	tuning.storm_threshold = 2.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	var only := args.find("--only")
	_capture(args[at + 1] if args.size() > at + 1 else "user://satellites",
		StringName(args[only + 1]) if only != -1 and args.size() > only + 1 else &"")


func _capture(out_dir: String, only := &"") -> void:
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
	await Scenarios.apply(world, Scenarios.by_key("night"))
	await _ground()
	player.set_physics_process(false)
	player.flying = true
	# Up over the dunes, so none stands in the way of a low one.
	player.global_position.y += RISE
	var sky := Radio.constellation_of(world)
	var day := world.weather.day
	var from_night := world.time
	while day.is_day(world.time, world.moon.longitude) or (_lit(sky).size() < WANTED if only == &""
			else not only in _lit(sky) or not _dark()):
		world.time += 5.0
		if world.time > from_night + 60.0 * Tuning.current().day_minutes * 60.0:
			print("satellites: no %s up by night within sixty days" % only)
			break
	if only != &"":
		await _ticks(10)
		_look(_dir(sky, only).rotated(Vector3.UP, deg_to_rad(OFF)))
		await _ticks(3)
		await _shoot(out_dir, String(only), String(only), _dir(sky, only))
		get_tree().quit()
		return
	await _ticks(10)
	var lit := _lit(sky)
	print("satellites: night at %.0f s, %d up and lit" % [world.time, lit.size()])
	# The whole sky toward the most of them.
	var toward := Vector3.ZERO
	for id: StringName in lit:
		toward += _dir(sky, id)
	_look(toward.normalized())
	await _ticks(4)
	await _shoot(out_dir, "sky", "")
	for id: StringName in lit:
		# A little off it, so the aim dot doesn't hide it.
		_look(_dir(sky, id).rotated(Vector3.UP, deg_to_rad(OFF)))
		await _ticks(3)
		await _shoot(out_dir, String(id), String(id), _dir(sky, id))
	# The crop survey skimming low, its shadow: high overhead, then low down.
	for each: Array in [["survey_overhead", 40.0, 90.0], ["survey_low", 8.0, 16.0]]:
		var from := world.time
		while day.is_day(world.time, world.moon.longitude) or not _between(sky, &"thermal", each[1], each[2]):
			world.time += 2.0
			if world.time > from + 60.0 * Tuning.current().day_minutes * 60.0:
				print("satellites: no %s within sixty days" % each[0])
				break
		await _ticks(3)
		_look(_dir(sky, &"thermal").rotated(Vector3.UP, deg_to_rad(OFF)))
		await _ticks(3)
		await _shoot(out_dir, each[0], "thermal", _dir(sky, &"thermal"), 200)
	# By day: the hull, a dark shape against the bright sky.
	var from := world.time
	while not day.is_day(world.time, world.moon.longitude) or not _between(sky, &"thermal", 30.0, 90.0):
		world.time += 2.0
		if world.time > from + 60.0 * Tuning.current().day_minutes * 60.0:
			print("satellites: no survey_day within sixty days")
			break
	await _ticks(3)
	_look(_dir(sky, &"thermal").rotated(Vector3.UP, deg_to_rad(OFF)))
	await _ticks(3)
	await _shoot(out_dir, "survey_day", "thermal", _dir(sky, &"thermal"), 200)
	get_tree().quit()


## Whether the sun is well down and Tu's light faint, so the sky is black.
func _dark() -> bool:
	var day := world.weather.day
	var moon := world.moon
	return day.sun_direction(world.time, moon.latitude, moon.longitude).y < sin(deg_to_rad(-15.0)) 		and day.tu_light(world.time, moon.latitude, moon.longitude) < 0.02


## Whether a satellite stands between these heights, degrees, now.
func _between(sky: Constellation, id: StringName, low: float, high: float) -> bool:
	var up := rad_to_deg(asin(clampf(_dir(sky, id).y, -1.0, 1.0)))
	return up >= low and up <= high


## Those up at least LOW and lit, the relay among them.
func _lit(sky: Constellation) -> Array[StringName]:
	var out: Array[StringName] = []
	var sun := world.weather.day.sun_toward(world.time)
	for id in Constellation.ids():
		var orbit: Satellite = sky.orbits[id]
		if sky.rows[id].look.get("hidden", false) or sky.rows[id].look.get("low", false):
			continue
		if orbit.sunlit(world.time, sun) and asin(clampf(_dir(sky, id).y, -1.0, 1.0)) > deg_to_rad(LOW):
			out.append(id)
	return out


## Which way it is from you, as the sky draws it.
func _dir(sky: Constellation, id: StringName) -> Vector3:
	var moon := world.moon
	var p := Sphere.point(moon.latitude, moon.longitude)
	return DayCycle.local((sky.orbits[id].at(world.time) - p).normalized(), moon.latitude, moon.longitude)


func _look(dir: Vector3) -> void:
	var player := world.player
	player.rotation = Vector3(0.0, atan2(-dir.x, -dir.z), 0.0)
	player.camera.rotation = Vector3(atan2(dir.y, Vector2(dir.x, dir.z).length()), 0.0, 0.0)


func _shoot(out_dir: String, name: String, id: String, dir := Vector3.ZERO, crop_px := CROP) -> void:
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	image.save_png(out_dir.path_join(name + ".png"))
	if id != "":
		var camera := world.player.camera
		var seen := camera.unproject_position(camera.global_position + dir * 100.0)
		var middle := Vector2i(seen * Vector2(image.get_size()) / get_viewport().get_visible_rect().size)
		var crop := image.get_region(Rect2i(middle - Vector2i(crop_px, crop_px) / 2, Vector2i(crop_px, crop_px)))
		crop.resize(crop_px * BLOW / 2 * 2, crop_px * BLOW / 2 * 2, Image.INTERPOLATE_NEAREST)
		crop.save_png(out_dir.path_join(name + "_close.png"))
		var material := world.weather.sky.material
		var tu: Vector3 = material.get_shader_parameter("tu_dir")
		var brightest := 0.0
		for x in range(-4, 5):
			for y in range(-4, 5):
				var at := middle + Vector2i(x, y)
				brightest = maxf(brightest, image.get_pixelv(at).get_luminance())
		print("satellites: %s %.1f° up, %.1f° from Tu (radius %.1f°), brightest there %.3f" % [name,
			rad_to_deg(asin(dir.y)), rad_to_deg(dir.angle_to(tu)), rad_to_deg(material.get_shader_parameter("tu_radius")),
			brightest])
	print("satellites: %s" % name)


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
