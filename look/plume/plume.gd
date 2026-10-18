extends Node
## Look-test: the rift's live vent and its plume. Moments the run's own weather
## gives (a calm, a strong wind, dusk, a storm coming over the vent and one
## swallowing it, a burst, night), each shot from the side across the wind,
## near, mid and far; its mouth up close. Each shot also times the GPU with
## the plume drawn and without.
##   scripts/unseen.sh --path . --disable-vsync res://look/plume/plume.tscn -- --capture <dir>
## Each shot is <moment>_<range>.png.

const SEED := 1234
## How far off each range stands, m, and how high the eye is over the sand.
const RANGES := {"near": [260.0, 6.0], "mid": [1500.0, 3.0], "far": [7000.0, 2.0]}
## Frames timed with the plume drawn, and without.
const TIMED := 30

@onready var world: World = $World

var _plume: Plume
var _vent: Dictionary
var _root: Vector3
## Where the vent's own point was laid, world metres: every shot lays it there.
var _raw: Vector2
var _costs: Array[String] = []


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = true
	tuning.finds_per_chunk = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[args.find("--capture") + 1] if args.has("--capture") else "user://plume"
	DirAccess.make_dir_recursive_absolute(out)
	_quiet()
	_plume = world.weather.plume
	_vent = world.shape.history.geology.live()[0]
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	# Beside the vent once: from here on the camera only moves across this
	# ground, so the vent and the weather over it stay where they were laid.
	var radius := world.shape.history.radius
	var stand := Sphere.toward(_vent.p, _vent.bearing + PI * 0.5, 300.0 / radius)
	world.travel(rad_to_deg(Sphere.latitude(stand)), rad_to_deg(Sphere.longitude(stand)), 0.0)
	world.time_warp = 0.0
	await _ground()
	for i in 5:
		await get_tree().process_frame
	_root = _plume.root
	_raw = world.shape.sites.on_ground(_vent.p)
	print("plume: the vent's mouth at %.0f,%.0f,%.0f" % [_root.x, _root.y, _root.z])
	var moments := _moments()
	for each: Array in moments:
		print("plume: %s_%s at t=%.0f (local %.3f) %s" % [each[0], each[1], each[2], _local(each[2]), each[3]])
	for each: Array in moments:
		await _shoot(each[0], each[2], each[1], out)
	await _mouth(moments[0][2], out)
	for line in _costs:
		print("plume: cost %s" % line)
	get_tree().quit()


## The run's own weather's moments at the vent for each shot, as [moment,
## range, world time, what it is]: in clear air at the vent, at the range's
## eye and between, but for the storms'.
func _moments() -> Array:
	var field := world.weather.field
	var geology := world.shape.history.geology
	var day := world.tuning.day_minutes * 60.0
	var x := _root.x
	var z := _root.z
	var clear_at := func(at: Vector2, t: float) -> bool: return field.raw_storm_at(at.x, at.y, t) < -0.06
	var seen_from := func(t: float, range_name: String) -> bool:
		var eye := _eye(t, range_name)
		for k in 5:
			if not clear_at.call(eye.lerp(Vector2(x, z), k / 4.0), t):
				return false
		return true
	var shots := {"calm": ["near", "mid", "far"], "wind": ["near", "mid", "far"], "burst": ["near", "mid", "far"],
		"dusk": ["mid", "far"], "storm": ["mid", "far"], "swallowed": ["mid"], "night": ["mid"]}
	var found := {}
	var best := {}
	var t := 600.0
	while t < day * 60.0:
		var local := _local(t)
		var storm := field.raw_storm_at(x, z, t)
		var wind := field.steady_wind_at(x, z, t).length()
		var clear := storm < -0.08 and field.raw_storm_at(x, z, t - 600.0) < -0.08
		var daylight := local > 0.33 and local < 0.62
		var quiet := geology.venting(_vent, t).x < 1.3
		for range_name: String in ["near", "mid", "far"]:
			var seen: bool = seen_from.call(t, range_name)
			var wants := {
				"calm": clear and daylight and quiet and seen and wind < best.get("calm" + range_name, INF),
				"wind": clear and daylight and quiet and seen and wind > best.get("wind" + range_name, 0.0),
				"dusk": clear and quiet and seen and local > 0.73 and local < 0.75,
				"night": clear and quiet and seen and local > 0.9 and local < 0.97,
				"storm": daylight and storm > -0.03 and storm < -0.005 and clear_at.call(_eye(t, range_name), t),
				"swallowed": daylight and storm > 0.08 and clear_at.call(_eye(t, range_name), t),
			}
			for moment: String in wants:
				var key := moment + "_" + range_name
				if wants[moment] and range_name in shots[moment] and (moment in ["calm", "wind"] or not found.has(key)):
					found[key] = [t, "steady wind %.1f m/s" % wind]
					best[moment + range_name] = wind
		t += 10.0
	# A burst well risen, two and a half minutes in, in clear daylight.
	for range_name: String in shots["burst"]:
		var burst := geology.next_burst(_vent, 0.0)
		while burst < day * 400.0:
			var risen := burst + 150.0
			if field.raw_storm_at(x, z, risen) < -0.08 and _local(risen) > 0.33 and _local(risen) < 0.62 \
					and seen_from.call(risen, range_name):
				var v := geology.venting(_vent, risen)
				found["burst_" + range_name] = [risen, "venting x%.1f, ash %.2f" % [v.x, v.y]]
				break
			burst = geology.next_burst(_vent, burst + 1.0)
	var all := []
	for moment: String in ["calm", "wind", "burst", "dusk", "storm", "swallowed", "night"]:
		for range_name: String in shots[moment]:
			var key := moment + "_" + range_name
			if found.has(key):
				all.append([moment, range_name, found[key][0], found[key][1]])
			else:
				print("plume: no %s moment found" % key)
	return all


## Where a range's eye stands at a moment, world metres: off to the side
## across the wind, a little downwind.
func _eye(t: float, range_name: String) -> Vector2:
	var away: float = RANGES[range_name][0]
	var wind := world.weather.field.steady_wind_at(_root.x, _root.z, t).normalized()
	return Vector2(_root.x, _root.z) + Vector2(-wind.y, wind.x) * away + wind * away * 0.25


## A moment from a range, from the side across the wind, looking at the bend.
func _shoot(moment: String, t: float, range_name: String, out: String) -> void:
	var lift: float = RANGES[range_name][1]
	var eye2 := _eye(t, range_name)
	await _stand(eye2, t)
	var night := moment == "night"
	world.tuning.eye_adapts = night
	world.weather.forecast_now()
	var root := _plume.root
	var eye := Vector3(eye2.x, world.height_at(eye2.x, eye2.y) + lift, eye2.y)
	# At the bend: what left the vent a minute ago.
	var target := _plume._point(25.0 if range_name == "near" else 45.0)
	await _look(eye, target)
	var name := "%s_%s" % [moment, range_name]
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	var cost := await _time()
	_costs.append("%s: GPU %.2f ms with it, %.2f without; its main thread %.3f ms a frame" % [name, cost.x, cost.y, cost.z])
	world.tuning.eye_adapts = false
	print("plume: %s %.0f m from the vent (its mouth %.1f m from where it was first laid), venting x%.2f, seen %.2f..%.2f" % [name,
		Vector2(root.x, root.z).distance_to(eye2), Vector2(root.x, root.z).distance_to(Vector2(_root.x, _root.z)),
		_plume.venting.x, _plume.seen[0].x, _plume.seen[_plume.POINTS - 1].x])


## Its mouth up close, on the calm.
func _mouth(t: float, out: String) -> void:
	var eye2 := Vector2(_root.x, _root.z) + _plume.slot.rotated(2.0) * 48.0
	await _stand(eye2, t)
	world.weather.forecast_now()
	var eye := Vector3(eye2.x, world.height_at(eye2.x, eye2.y) + 7.0, eye2.y)
	await _look(eye, _plume.root + Vector3(0.0, 2.0, 0.0))
	get_viewport().get_texture().get_image().save_png(out.path_join("mouth_close.png"))
	print("plume: mouth_close %.0f m from it" % Vector2(_plume.root.x, _plume.root.z).distance_to(eye2))


## Stands you at a world place at world time t, the moon's point under you
## set so the vent's own point lands where it was first laid: the weather
## over it is the same however far you went.
func _stand(eye2: Vector2, t: float) -> void:
	var radius := world.shape.history.radius
	var want := Vector2(_raw.x - eye2.x, eye2.y - _raw.y) / radius
	var p := Sphere.from_flat(_vent.p, -want)
	for i in 6:
		p = Sphere.from_flat(p, Sphere.flat_from(p, _vent.p) - want)
	world.respawn(eye2.x, eye2.y, 0.0, t)
	world.time_warp = 0.0
	world.moon.place(rad_to_deg(Sphere.latitude(p)), rad_to_deg(Sphere.longitude(p)))
	await _ground()
	for i in 4:
		await get_tree().process_frame


## GPU ms a frame with the plume drawn and without, the median over three
## turns of each, and its own main-thread ms a frame while drawn.
func _time() -> Vector3:
	var vp := get_viewport().get_viewport_rid()
	var with := PackedFloat32Array()
	var without := PackedFloat32Array()
	var cpu := 0.0
	for turn in 6:
		var drawn := turn % 2 == 0
		_plume.process_mode = Node.PROCESS_MODE_INHERIT if drawn else Node.PROCESS_MODE_DISABLED
		if not drawn:
			_plume.visible = false
		for i in 4:
			await RenderingServer.frame_post_draw
		for i in TIMED:
			await RenderingServer.frame_post_draw
			(with if drawn else without).append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
			if drawn:
				cpu += _plume.frame_ms
	_plume.process_mode = Node.PROCESS_MODE_INHERIT
	with.sort()
	without.sort()
	return Vector3(with[with.size() / 2], without[without.size() / 2], cpu / with.size())


func _look(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var offset := player.camera.global_position - player.global_position
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	await _ground()
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	for i in 30:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw


func _local(t: float) -> float:
	return world.weather.day.time_of_day(t, Sphere.longitude(_vent.p))


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var waited := Time.get_ticks_msec()
	while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 60000:
		await get_tree().process_frame


## No focus, no keys, no sound, nothing drawn over the world.
func _quiet() -> void:
	var window := get_window()
	window.unfocusable = true
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	player.set_physics_process(false)
	player.flying = true
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
