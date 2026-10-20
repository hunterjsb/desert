extends Node
## Look-test: the eclipse at Tu's default size, on seed 1234 where a run
## begins, with the eye on as the game plays. In still air it's watched live
## from before first contact, facing Tu: second contact and its diamond ring,
## mid-totality, and third contact; then on the next days, the last of the sun
## going in, its light gone copper, and mid-totality facing away from Tu, the
## glow all round the horizon; and a full-Tu night once the eye has adapted.
## With --storm, in a full storm everywhere, blowing: mid-totality out in the
## dust, then the next day's inside a bubble at a small camp with its lamp lit.
## With --walls, the run's own storms, found in its weather: a wall coming at
## you from WALL_AT m and the deep inside of one, each at mid-totality and by
## day.
## It prints each shot's eye and the sand's lightness (CIE L*) low in the
## frame, and what the eclipse's light costs the GPU at 1920x1080 at
## mid-totality, against the same frame without it:
##   godot --path . --disable-vsync res://look/eclipse/eclipse.tscn -- --capture <dir> [--storm|--walls]
## look/eclipse/shoot.sh shoots both and builds the sheet. A small window that
## never takes focus, nothing but this script moving anything, and silence.

const SEED := 1234
## Looking at Tu from where a run begins: up this far, so it sits high in frame.
const PITCH_TO_TU := 12.0
const PITCH_GROUND := -6.0
## Seconds before first contact the eclipse is watched from.
const BEFORE := 10.0
## The share of the sun left for the shot of its last light going copper.
const LAST_LIGHT := 0.25
## The camp in the bubble, as [catalog id, metres right, metres ahead, yaw
## degrees, parts fitted or, on a chassis, stuck], round the generator on its
## plate, which stands this far ahead.
const AHEAD := 2.5
const CAMP := [
	[&"chassis", -1.6, 1.2, 20.0, [&"battery", &"lamp"]],
	[&"planter", 1.8, 0.4, -10.0, [&"battery", &"root_tuber", &"root_tuber"]],
]
## How far off the wall stands, m, and how far up you look at it.
const WALL_AT := 500.0
const PITCH_WALL := 6.0
const GPU_FRAMES := 60
const GPU_ROUNDS := 4

@onready var world: World = $World

var _storm := OS.get_cmdline_user_args().has("--storm")
var _walls := OS.get_cmdline_user_args().has("--walls")
## Where you stand, world metres: spawn, or a storm found in the run's weather.
var _place := Vector2.ZERO
var _out := ""
## While set, each frame's drawing goes without the eclipse's light.
var _without := false


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = true
	tuning.salvage = false
	if _walls:
		# The run's own weather, as the game plays it.
		pass
	elif _storm:
		# A full storm everywhere that never passes, its wind blowing.
		tuning.storm_ramp = 0.04
		tuning.storm_threshold = -2.0
	else:
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
	_out = args[at + 1] if args.size() > at + 1 else "user://eclipse"
	RenderingServer.frame_pre_draw.connect(_before_draw)
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
	var day := world.weather.day
	var spawn_lon := tuning.spawn_longitude_degrees
	var mid := day.next_eclipse(0.0)
	_place = world.spawn
	print("eclipse: Tu %d° across, %.1f s of totality" % [roundi(tuning.tu_degrees), day.totality()])
	if _walls:
		await _storms()
		get_tree().quit()
		return
	if _storm:
		await _watch(mid, {0.0: "storm_out"})
		await _gpu_cost("storm, out in the dust")
		var camp := _camp()
		await _watch(mid + tuning.day_minutes * 60.0, {0.0: "storm_in"})
		await _gpu_cost("storm, in a bubble")
		for device in camp:
			device.queue_free()
		get_tree().quit()
		return
	await _watch(mid, {-1.0: "second", 0.0: "mid", 1.0: "third"})
	await _gpu_cost("in the clear")
	var days := tuning.day_minutes * 60.0
	await _watch(mid + days, {-2.0: "copper"}, 0.0, 0.0)
	await _watch(mid + 2.0 * days, {0.0: "mid_away"}, PI, 6.0)
	var full := mid + tuning.day_minutes * 30.0
	await _shot("full_night", full, _to_tu(full, spawn_lon) + PI, PITCH_GROUND)
	get_tree().quit()


## Watches the eclipse round mid from BEFORE s ahead of first contact, live,
## the eye adapting as it goes, turned this far from Tu and looking up this
## far, and saves a shot at each moment: -2 the sun's last LAST_LIGHT, -1
## second contact, 0 mid-totality, 0.1 and 0.2 one and two seconds on, 1
## third contact.
func _watch(mid: float, moments: Dictionary, turn := 0.0, pitch := PITCH_TO_TU) -> void:
	var day := world.weather.day
	var spawn_lon := world.tuning.spawn_longitude_degrees
	var first := mid
	while day.sun_shown(first) < 1.0:
		first -= 0.02
	var second := mid
	while day.eclipse(second).z < -1.0:
		second -= 0.02
	var third := mid
	while day.eclipse(third).z < -1.0:
		third += 0.02
	var last_light := first
	while day.sun_shown(last_light) > LAST_LIGHT:
		last_light += 0.01
	var at := {-2.0: last_light, -1.0: second, 0.0: mid, 1.0: third, 0.1: mid + 1.0, 0.2: mid + 2.0}
	world.time = first - BEFORE
	world.time_warp = 0.0
	world.moon.place(0.0, spawn_lon)
	_stand(_to_tu(mid, spawn_lon) + turn, pitch)
	world.weather.forecast_now()
	await _ticks(30)
	world.time_warp = 1.0
	var series := PackedStringArray()
	var next_mark := ceilf(world.time)
	var last: float = at[moments.keys().max()]
	var taken := {}
	while world.time < last + 0.1:
		await get_tree().process_frame
		var t := world.time
		if t >= next_mark:
			series.append("%+d %.2f" % [roundi(t - second), world.weather.eye.stops])
			next_mark += 1.0
		for moment: float in moments.keys():
			if t >= at[moment] and not taken.has(moment):
				taken[moment] = true
				_save(moments[moment])
	world.time_warp = 0.0
	print("eclipse: totality %.1f s; s from second contact and stops open: %s" % [third - second, ", ".join(series)])


## The run's own storms: a wall WALL_AT m upwind, faced, and the deep inside
## of one, facing Tu; each at an eclipse's mid-totality, watched live, and by
## day.
func _storms() -> void:
	var day := world.weather.day
	var spawn_lon := world.tuning.spawn_longitude_degrees
	for when: String in ["eclipse", "day"]:
		for kind: String in ["front", "deep"]:
			var name := "%s_%s" % [kind, when]
			var scenario := {"key": name, "kind": kind, "distance": WALL_AT, "day": [0.4, 0.55]}
			if when == "eclipse":
				scenario["eclipse"] = -day.totality() * 0.5
			var place := Scenarios.find(world, scenario)
			if place.is_empty():
				print("eclipse: %s: none in the run's weather" % name)
				continue
			_place = Vector2(place.x, place.z)
			world.respawn(place.x, place.z, 0.0, place.time)
			world.time_warp = 0.0
			await _ground()
			for i in 600:
				if world.weather.map.ready:
					break
				await get_tree().process_frame
			var upwind := -world.weather.field.prevailing_at(place.time).normalized()
			var yaw := atan2(-upwind.x, -upwind.y)
			if when == "eclipse":
				var turn := yaw - _to_tu(place.time, spawn_lon) if kind == "front" else 0.0
				var moments := {0.0: name} if kind == "front" else {0.0: name, 0.1: name + "_1s", 0.2: name + "_2s"}
				await _watch(place.time, moments, turn, PITCH_WALL if kind == "front" else PITCH_TO_TU)
			else:
				await _shot(name, place.time, yaw, PITCH_WALL)


## A moment shot once the eye has settled on it.
func _shot(name: String, t: float, yaw: float, pitch: float) -> void:
	world.time = t
	world.time_warp = 0.0
	world.moon.place(0.0, world.tuning.spawn_longitude_degrees)
	_stand(yaw, pitch)
	world.weather.forecast_now()
	await _ticks(30)
	for i in 4:
		await get_tree().process_frame
	_save(name)


func _stand(yaw: float, pitch: float) -> void:
	var player := world.player
	var at := Vector3(world.engine_x(_place.x), 0.0, world.engine_z(_place.y))
	player.global_position = Vector3(at.x, world.height_under(at) + 1.65, at.z) - player.camera.position
	player.rotation.y = yaw
	player.camera.rotation_degrees.x = pitch


func _save(name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out.path_join(name + ".png"))
	var eye := world.weather.eye
	var day := world.weather.day
	var now := day.eclipse(world.time)
	print("eclipse: %-10s sun %+.2f radii from Tu's edge, %3.0f%% shown, ring %.2f  frame %6.2f stops, bright %6.2f  eye x%.2f  sand L* %4.1f"
		% [name, now.z, day.sun_shown(world.time) * 100.0, day.ring_light(world.time), eye.seen, eye.seen_bright, eye.exposure(), _sand(image)])


## Sets the shield and its camp down AHEAD m in front of the camera, running,
## so the camera stands inside the bubble.
func _camp() -> Array[Device]:
	var player := world.player
	var ahead := -player.global_basis.z
	ahead.y = 0.0
	ahead = ahead.normalized()
	var at := player.global_position + ahead * AHEAD
	var turn := Basis(Vector3.UP, player.global_rotation.y)
	var made: Array[Device] = []
	var plate := _device(&"chassis", [&"shield", &"battery"])
	_set_down(plate, &"chassis", at, turn)
	made.append(plate)
	var generator := plate.mounted()[0] as ShieldGenerator
	for entry: Array in CAMP:
		var device := _device(entry[0], entry[4])
		_set_down(device, entry[0], at + turn * Vector3(entry[1], 0.0, -entry[2]),
			turn * Basis(Vector3.UP, deg_to_rad(entry[3])))
		made.append(device)
	plate.battery().charge_wh = plate.battery().capacity()
	generator.stand(true)
	return made


## A device with parts fitted, or a chassis with these stuck on its top.
func _device(id: StringName, fitted: Array) -> Device:
	var made := Catalog.device(id)
	world.content.add_child(made)
	made.global_position = world.player.global_position + Vector3.UP * 50.0
	if made is Chassis:
		for i in fitted.size():
			Stick.put(made, made, Chassis.TOP, [Vector2(-0.2, 0.2), Vector2(0.28, -0.28)][i], 0.0, Rig.make(fitted[i]))
		return made
	for part_id: StringName in fitted:
		var part := Catalog.part(part_id)
		world.content.add_child(part)
		for socket in made.sockets():
			if socket.kind == part.kind and socket.part == null:
				made.fit(part, socket)
				break
	return made


func _set_down(device: Device, id: StringName, at: Vector3, turn: Basis) -> void:
	var half: float = Catalog.DEVICES[id].size.y * 0.5
	device.global_transform = Transform3D(turn, Vector3(at.x, world.height_under(at) + half + 0.02, at.z))
	device.freeze = true


## The GPU's time per frame at mid-totality, held there, with the eclipse's
## light and without it, alternated so a busy machine weighs on each alike.
func _gpu_cost(where: String) -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	world.time_warp = 0.0
	var sums := [0.0, 0.0]
	for round in GPU_ROUNDS:
		for way in 2:
			_without = way == 1
			for i in 30:
				await get_tree().process_frame
			for i in GPU_FRAMES:
				await get_tree().process_frame
				sums[way] += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	_without = false
	var n := float(GPU_ROUNDS * GPU_FRAMES)
	print("eclipse: gpu %s: %.3f ms a frame with the eclipse's light, %.3f without, at %s%s"
		% [where, sums[0] / n, sums[1] / n, get_viewport().get_visible_rect().size, _shared_gpu()])


## Takes the eclipse's light out of the frame about to be drawn: the sky's
## ring, bead, corona and horizon, and the ring's light in the dust.
func _before_draw() -> void:
	if not _without:
		return
	var weather := world.weather
	weather.sky.material.set_shader_parameter("eclipse", Vector3(0.0, 0.0, 99.0))
	weather.sky.material.set_shader_parameter("eclipse_air", Vector3.ZERO)
	weather.face.set_light("ring_light", Vector3.ZERO)
	weather.atmosphere.show_eclipse(Vector3.UP, Vector3.ZERO, 0.0, 0.0)


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
