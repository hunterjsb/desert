extends Node
## Look-test: sites found by eye from far off, at 1920x1080 on a clear
## morning, as you'd see them. Each origin's start, looking at what's in
## sight from where its run begins; a far mast or watchtower on the horizon;
## a glint; a saltbush line and a row of pylon stubs read from a distance;
## then what the skyline costs a frame, on and off, on a camp-free world and
## with the AFK camp parked round you.
##   scripts/unseen.sh --path . --disable-vsync --resolution 1920x1080 res://look/sightlines/sightlines.tscn -- --capture <dir>
## Each shot is <name>.png with <name>_zoom.png, four times larger round
## what it's of; look/sightlines/shoot.sh builds the sheet.

const WORLD_SCENE := preload("res://game/world/world.tscn")
const SEED := 1234
## Local time the shots are taken at.
const MORNING := 0.38
## The zoom's window, pixels of the shot, and how much larger it's drawn.
const WINDOW := Vector2i(320, 180)
const ZOOM := 3

var world: World
var _out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[args.find("--capture") + 1] if args.has("--capture") else "user://sightlines"
	DirAccess.make_dir_recursive_absolute(_out)
	var window := get_window()
	window.unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = true
	var costs := []
	for kit in Kit.origins():
		await _begin(kit)
		var seen := Starts.in_sight(world.shape, kit.start, world.start, tuning)
		var name := "start_%s" % kit.label.to_lower()
		if seen == null:
			print("sightlines: %s, nothing in sight" % name)
		else:
			var spawn := world.spawn
			await _aim(_eye_at(spawn), Vector3(seen.x, seen.pad() + seen.top_in(seen.state()) * 0.6, seen.z))
			await _shoot(name, "%s %.0f m off" % [seen.kind, seen.distance_to(spawn.x, spawn.y)])
		if kit.start == &"artery":
			await _far_tower()
			await _glint()
			costs.append(await _cost("camp-free"))
			await _afk()
			costs.append(await _cost("AFK camp"))
		if kit.start == &"wayshrine":
			await _road(&"pilgrim_road", "road_saltbush")
			await _road(&"spoke", "road_pylons")
	for line in costs:
		print("sightlines: cost %s" % line)
	get_tree().quit()


## A run of an origin's, its world built at its start, at a clear morning there.
func _begin(kit: Kit) -> void:
	if world != null:
		world.queue_free()
		await get_tree().process_frame
	world = WORLD_SCENE.instantiate()
	world.kit = kit
	add_child(world)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	player.set_physics_process(false)
	player.flying = true
	world.set_process_unhandled_input(false)
	await _settled()
	world.time = _clear_morning(world.spawn)
	world.time_warp = 0.0
	await _ticks(10)


## A far mast or watchtower on the horizon: the tallest stand-in a kilometre
## or more off whose top shows from a rise near where you are.
func _far_tower() -> void:
	var spawn := world.spawn
	var best: Structure = null
	var from := Vector3.ZERO
	var clear := 0.0
	for site in world.terrain.skyline.seen():
		if not site.kind in [&"relay_mast", &"watchtower"] or site.distance_to(spawn.x, spawn.y) < 1000.0:
			continue
		var drawn := world.terrain.skyline.stand_in(site)
		if drawn.is_empty():
			continue
		for k in 24:
			var at := spawn + Vector2.from_angle(TAU * k / 24.0) * 120.0 * (k % 3)
			var eye := _eye_at(at)
			var by := Skyline.clearance(world.shape, world.tuning, eye, Vector3(drawn.x, drawn.top, drawn.z),
				world.terrain.chunk_at(at.x, at.y), site.reach) / site.distance_to(at.x, at.y)
			if by > clear:
				clear = by
				best = site
				from = eye
	if best == null:
		print("sightlines: far_tower, none")
		return
	var drawn := world.terrain.skyline.stand_in(best)
	await _aim(from, Vector3(drawn.x, drawn.top - 3.0, drawn.z))
	await _shoot("far_tower", "%s %.0f m off, %.1f px clear" % [best.kind,
		Vector2(drawn.x - from.x, drawn.z - from.z).length(), clear / Skyline.PIXEL])


## The moment today a glint seen from where you are is at its brightest.
func _glint() -> void:
	var spawn := world.spawn
	var eye := _eye_at(spawn)
	var day := world.weather.day
	var moon := world.moon
	var skyline := world.terrain.skyline
	var t0 := world.time
	var best := 0.0
	var when := t0
	var spot := Vector3.ZERO
	for site in skyline.seen():
		if site.distance_to(spawn.x, spawn.y) > world.tuning.skyline_m:
			continue
		for each in skyline.glints_of(site):
			var at: Vector3 = each[0]
			if Skyline.clearance(world.shape, world.tuning, eye, at, world.terrain.chunk_at(spawn.x, spawn.y), site.reach) < 0.0:
				continue
			var t := t0
			while t < t0 + world.tuning.day_minutes * 30.0:
				var sun := day.sun_direction(t, moon.latitude, moon.longitude)
				if sun.y > 0.1:
					var v := (eye - at).normalized()
					var n: Vector3 = each[1]
					var a := n.dot((v + sun).normalized())
					var g := smoothstep(each[2], lerpf(each[2], 1.0, 0.75), a) if n.dot(v) > 0.0 and n.dot(sun) > 0.0 else 0.0
					if g > best:
						best = g
						when = t
						spot = at
				t += 5.0
	if best <= 0.0:
		print("sightlines: glint, none today")
		return
	world.time = when
	await _ticks(10)
	await _aim(eye, spot)
	await _shoot("glint", "%.0f m off, %.0f%% of its brightest" % [Vector2(spot.x - eye.x, spot.z - eye.z).length(), best * 100.0])


## A road read from a distance: travelled to, stood off on a rise, looking along it.
func _road(kind: StringName, name: String) -> void:
	var history := world.shape.history
	var road: PathNetwork.Path = null
	for path in history.network.paths:
		if path.kind == kind and (kind != &"spoke" or path.carries & PathNetwork.POWER):
			road = path
			break
	if road == null:
		print("sightlines: %s, none" % name)
		return
	var p := road.at(road.length() * 0.45)
	world.travel(rad_to_deg(Sphere.latitude(p)), rad_to_deg(Sphere.longitude(p)), 0.0)
	world.time = _clear_morning(Vector2(world.player_world_x(), world.player_world_z()))
	world.time_warp = 0.0
	await _settled()
	var here := Vector2(world.player_world_x(), world.player_world_z())
	var run := _road_at(here, kind)
	var across := run.orthogonal()
	var best := -INF
	var stand := here
	for side in range(500, 1101, 50):
		for sign: float in [1.0, -1.0]:
			var at := here + across * side * sign - run * 300.0
			var h := world.shape.height_at(at.x, at.y)
			if h > best:
				best = h
				stand = at
	var target := here + run * 500.0
	await _aim(_eye_at(stand) + Vector3.UP * 2.0, Vector3(target.x, world.shape.dunes(target.x, target.y), target.y))
	await _shoot(name, "%s %.0f m off" % [kind, stand.distance_to(here)])


## What a frame costs looking round the horizon, with the skyline and without.
func _cost(what: String) -> String:
	var spawn := world.spawn
	var eye := _eye_at(spawn)
	var on := await _frames(eye)
	world.tuning.skyline = false
	var off := await _frames(eye)
	world.tuning.skyline = true
	await _ticks(5)
	var skyline := world.terrain.skyline
	return "%s: GPU %.3f ms on, %.3f off; CPU frame %.3f on, %.3f off; skyline %d things, its main thread %.3f ms a frame on average, the most %.2f, its worker %.1f ms a job" % [
		what, on.x, off.x, on.y, off.y, skyline.seen().size(), on.z, skyline.slowest_ms, skyline.job_ms]


## GPU ms, CPU ms and the skyline's own ms a frame, averaged looking four ways.
func _frames(eye: Vector3) -> Vector3:
	var viewport := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	var sum := Vector3.ZERO
	var frames := 0
	for k in 4:
		var yaw := TAU * k / 4.0
		await _aim(eye, eye + Vector3(sin(yaw), 0.0, cos(yaw)) * 1000.0, false)
		for i in 90:
			await get_tree().process_frame
			sum += Vector3(RenderingServer.viewport_get_measured_render_time_gpu(viewport),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, world.terrain.skyline.frame_ms)
			frames += 1
	return sum / frames


## Parks the AFK camp round you, as the dev scenario does.
func _afk() -> void:
	await Scenarios.apply(world, Scenarios.by_key("afk"))
	world.time_warp = 1.0
	await _settled()
	await _ticks(120)


# --- Shooting. ---

func _eye_at(at: Vector2) -> Vector3:
	return Vector3(at.x, world.shape.height_at(at.x, at.y) + Skyline.EYE, at.y)


## Puts the camera at `eye`, world metres, looking at `target`.
func _aim(eye: Vector3, target: Vector3, settle := true) -> void:
	var player := world.player
	var offset := player.camera.global_position - player.global_position
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	if settle:
		await _settled()
		player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	await _ticks(20)


## The shot, and the zoom round the middle of the screen, where it's aimed.
func _shoot(name: String, what: String) -> void:
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	shot.save_png(_out.path_join(name + ".png"))
	var middle := shot.get_size() / 2
	var zoom := shot.get_region(Rect2i(middle - WINDOW / 2, WINDOW))
	zoom.resize(WINDOW.x * ZOOM, WINDOW.y * ZOOM, Image.INTERPOLATE_NEAREST)
	zoom.save_png(_out.path_join(name + "_zoom.png"))
	print("sightlines: %s, %s; %d things seen from afar" % [name, what, world.terrain.skyline.seen().size()])


func _settled() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var waited := Time.get_ticks_msec()
	while not world.terrain.is_idle() and Time.get_ticks_msec() - waited < 60000:
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## The first clear morning at a place: MORNING local, the sun well up and
## no storm within ten minutes.
func _clear_morning(at: Vector2) -> float:
	var day := world.weather.day
	var field := world.weather.field
	var moon := world.moon
	var t := 0.0
	while t < 200.0 * world.tuning.day_minutes * 60.0:
		var hour := day.time_of_day(t, moon.longitude)
		if absf(hour - MORNING) < 0.004 and day.sunlight(t, moon.latitude, moon.longitude) > 0.3 \
				and field.raw_storm_at(at.x, at.y, t) <= 0.0 and field.next_change(at.x, at.y, t, 600.0, 20.0) >= 600.0:
			return t
		t += 2.0
	return 0.0


## Which way a laid path of a kind runs past a place, on the ground.
func _road_at(here: Vector2, kind: StringName) -> Vector2:
	var near := INF
	var run := Vector2.RIGHT
	for piece in world.shape.sites.paths_in(Rect2(here, Vector2.ZERO).grow(400.0)):
		if piece.kind != kind:
			continue
		for i in piece.points.size() - 1:
			var a := piece.points[i]
			var b := piece.points[i + 1]
			var d := Geometry2D.get_closest_point_to_segment(here, a, b).distance_to(here)
			if d < near:
				near = d
				run = (b - a).normalized()
	return run
