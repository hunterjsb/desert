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
## A glint this far off is shot before any nearer, m.
const FAR_GLINT := 300.0
## The tall pieces a far shot looks for.
const TALL: Array[StringName] = [&"relay_mast", &"watchtower"]
## Walking in to the Surveyor's mast: shot from these far, m, zoomed this
## much closer, across the hand-over (Tuning skyline_handover_m).
const HANDOVER: Array[float] = [560.0, 500.0, 460.0, 420.0, 340.0]
const HANDOVER_ZOOM := 6

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
	# Clear skies, so what's far off is seen as it is on a clear day.
	tuning.storm_threshold = 0.9
	var costs := []
	for kit in Kit.origins():
		await _begin(kit)
		var seen := Starts.in_sight(world.shape, kit.start, world.start, tuning, {&"ground": world.spawn})
		var name := "start_%s" % kit.label.to_lower()
		if seen == null:
			print("sightlines: %s, nothing in sight" % name)
		else:
			var spawn := world.spawn
			var eye := _eye_at(spawn)
			await _aim(eye, Vector3(seen.x, seen.pad() + seen.top_in(seen.state()) * 0.6, seen.z))
			await _shoot(name, "%s %.0f m off%s" % [seen.kind, seen.distance_to(spawn.x, spawn.y), _drawn(seen, eye)])
		if kit.start == &"artery":
			if seen != null:
				await _handover(seen)
			await _far_tower(world.spawn)
			# What catches the eye from where the run begins, that first day.
			await _glint(0.2, false)
			costs.append(await _cost("camp-free"))
			await _afk()
			costs.append(await _cost("AFK camp"))
		if kit.start == &"wayshrine":
			if not FileAccess.file_exists(_out.path_join("glint.png")):
				await _glint(0.0)
			await _road(&"pilgrim_road", "road_saltbush")
			await _road(&"spoke", "road_pylons")
			# Masts stand along the spokes: one to steer by, from the rises round.
			if not FileAccess.file_exists(_out.path_join("far_tower.png")):
				await _far_tower(Vector2(world.player_world_x(), world.player_world_z()))
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
	# Its aim dot would sit on what's aimed at.
	player.hands.set_process(false)
	player.set_physics_process(false)
	player.flying = true
	world.set_process_unhandled_input(false)
	await _settled()
	world.time = _clear_morning(world.spawn)
	world.time_warp = 0.0
	await _ticks(10)


## A far mast or watchtower on the horizon: a landmark a kilometre and more
## off whose top clears the dunes, from where you are, a walk back from the
## nearest or the rises round, the farthest found.
func _far_tower(spawn: Vector2) -> void:
	var best: Structure = null
	var from := Vector3.ZERO
	var far := 0.0
	var landmarks: Array[Structure] = []
	for site in world.terrain.skyline.seen():
		if site.kind in TALL:
			landmarks.append(site)
	landmarks.sort_custom(func(a: Structure, b: Structure) -> bool:
		return a.distance_to(spawn.x, spawn.y) < b.distance_to(spawn.x, spawn.y))
	var eyes: Array[Vector2] = []
	for k in 25:
		eyes.append(spawn + Vector2.from_angle(TAU * k / 12.0) * 75.0 * ceili(k / 12.0))
	if not landmarks.is_empty():
		var away := (spawn - Vector2(landmarks[0].x, landmarks[0].z)).normalized()
		for k in range(2, 13):
			eyes.append(spawn + away * k * 100.0)
	# And the highest ground a short walk off.
	var rises := []
	for j in range(-8, 9):
		for i in range(-8, 9):
			var at := spawn + Vector2(i, j) * 50.0
			rises.append([world.shape.dunes(at.x, at.y), at])
	rises.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for each in rises.slice(0, 12):
		eyes.append(each[1])
	for at in eyes:
		var eye := _eye_at(at)
		var center := world.terrain.chunk_at(at.x, at.y)
		for site in landmarks:
			var by := site.distance_to(at.x, at.y)
			if by < 1100.0 or by <= far:
				continue
			# Its top as drawn from there: on the far ring, past that eye's built ground.
			var top := FarRing.ground(world.shape, world.tuning, site.x, site.z) + site.top_in(site.state())
			if Skyline.clearance(world.shape, world.tuning, eye, Vector3(site.x, top, site.z), center, site.reach) > 0.0:
				far = by
				best = site
				from = eye
	if best == null:
		print("sightlines: far_tower, none")
		return
	var top := FarRing.ground(world.shape, world.tuning, best.x, best.z) + best.top_in(best.state())
	await _aim(from, Vector3(best.x, top - 3.0, best.z))
	await _shoot("far_tower", "%s %.0f m off%s" % [best.kind, best.distance_to(from.x, from.z), _drawn(best, from)])


## How tall a mast's or tower's stand-in stands from an eye, and how wide its
## body is, in pixels at 1080 rows as it is (skyline.gdshader draws nothing
## thinner than skyline_thinnest_px).
func _drawn(site: Structure, eye: Vector3) -> String:
	if not site.kind in TALL:
		return ""
	var d := Vector2(site.x - eye.x, site.z - eye.z).length()
	var tall := site.top_in(site.state()) / d / Skyline.PIXEL
	# Its body's width: the far box that stands tallest.
	var body := AABB()
	for each: Array in site.piece.far:
		if (each[0] as AABB).size.y > body.size.y:
			body = each[0]
	var wide := body.size.x / d / Skyline.PIXEL
	return "; %.1f px tall and %.1f wide as it stands" % [tall, wide]


## Walking in to it across the hand-over, from the clearest view of it on
## the way at each distance: as you see it, then from the same spot with only
## its real look and with only its stand-in, which should look alike.
func _handover(seen: Structure) -> void:
	var spawn := world.spawn
	var bearing := (spawn - Vector2(seen.x, seen.z)).angle()
	var mid := seen.pad() + seen.top_in(seen.state()) * 0.5
	var center := world.terrain.chunk_at(seen.x, seen.z)
	for d: float in HANDOVER:
		var eye := _eye_at(Vector2(seen.x, seen.z) + Vector2.from_angle(bearing) * d)
		var clear := -INF
		for k in range(-6, 7):
			var at := _eye_at(Vector2(seen.x, seen.z) + Vector2.from_angle(bearing + k * 0.08) * d)
			var by := Skyline.clearance(world.shape, world.tuning, at, Vector3(seen.x, mid, seen.z), center, 2.0)
			if by > clear:
				clear = by
				eye = at
		await _aim(eye, Vector3(seen.x, mid, seen.z))
		var what := "%s %.0f m off%s" % [seen.kind, d, _drawn(seen, eye)]
		await _shoot("handover_%d" % d, what, HANDOVER_ZOOM)
		for only in ["real", "far"]:
			_only(only)
			await _ticks(3)
			await _shoot("handover_%d_%s" % [d, only], what, HANDOVER_ZOOM)
		_only("")


## Draws a structure with a stand-in only as its real look ("real"), only as
## its stand-in ("far"), or as played ("").
func _only(which: String) -> void:
	var handover := world.tuning.skyline_handover_m
	var look: ShaderMaterial = world.terrain.skyline._box_look
	look.set_shader_parameter("handover", {"real": Vector2(1.0e6, 1.0e6 + 1.0), "far": Vector2(0.0, 0.001)}
		.get(which, handover))
	for made: GeometryInstance3D in world.find_children("*", "GeometryInstance3D", true, false):
		if made.visibility_range_fade_mode == GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF:
			made.visibility_range_end = 0.0 if which == "real" else handover.x
			made.visible = which != "far"


## The moment today, and the place within a short walk of where you are (or
## right where you are, unless `around`), a glint is at its brightest, one
## far off before one near: shot if it's past `least` (a near one counts a
## tenth).
func _glint(least: float, around := true) -> void:
	var spawn := world.spawn
	var day := world.weather.day
	var moon := world.moon
	var skyline := world.terrain.skyline
	# Right where you are, over the run's own first day.
	var t0 := world.time if around else 0.0
	var spots := []
	for site in skyline.seen():
		for each in skyline.glints_of(site):
			spots.append(each)
	# Where you are, and the rises round you a short walk off.
	var eyes: Array[Vector3] = []
	for ring in (5 if around else 1):
		for k in (1 if ring == 0 else 12):
			eyes.append(_eye_at(spawn + Vector2.from_angle(TAU * k / 12.0) * ring * 75.0))
	var best := 0.0
	var when := t0
	var spot := Vector3.ZERO
	var from := eyes[0]
	var t := t0
	while t < t0 + world.tuning.day_minutes * 60.0:
		var sun := day.sun_direction(t, moon.latitude, moon.longitude)
		if sun.y > 0.1:
			for eye in eyes:
				for each: Array in spots:
					var at: Vector3 = each[0]
					var g := Skyline.shine(each, eye, sun) \
						* (1.0 if Vector2(at.x - eye.x, at.z - eye.z).length() >= FAR_GLINT else 0.1)
					if g > best and Skyline.clearance(world.shape, world.tuning, eye, at,
							world.terrain.chunk_at(eye.x, eye.z), 1.0) > 0.0:
						best = g
						when = t
						spot = at
						from = eye
		t += 10.0
	if best <= least:
		print("sightlines: glint, none past %.1f today" % least)
		return
	world.time = when
	await _ticks(10)
	await _aim(from, spot)
	var off := Vector2(spot.x - from.x, spot.z - from.z).length()
	await _shoot("glint", "%.0f m off, %.0f%% of its brightest%s" % [off, best * (100.0 if off >= FAR_GLINT else 1000.0),
		"" if around else ", %.1f min into the run, from where it begins" % (when / 60.0)])


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
	# Looking at the stretch of it past the built ground that shows best.
	var eye := _eye_at(stand) + Vector3.UP * 2.0
	var target := here
	var clear := -INF
	for along in range(-1500, 1501, 50):
		var at := here + run * along
		if at.distance_to(stand) < 600.0:
			continue
		var top := Vector3(at.x, FarRing.ground(world.shape, world.tuning, at.x, at.y) + 0.5, at.y)
		var by := Skyline.clearance(world.shape, world.tuning, eye, top, world.terrain.chunk_at(stand.x, stand.y), 5.0) \
			/ at.distance_to(stand)
		if by > clear:
			clear = by
			target = at
	await _aim(eye, Vector3(target.x, FarRing.ground(world.shape, world.tuning, target.x, target.y), target.y))
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


## GPU ms, CPU ms and the skyline's own ms a frame looking four ways, the
## middle of each, after a second for anything new to compile.
func _frames(eye: Vector3) -> Vector3:
	var viewport := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	var gpu := PackedFloat64Array()
	var cpu := PackedFloat64Array()
	var own := PackedFloat64Array()
	for k in 4:
		var yaw := TAU * k / 4.0
		await _aim(eye, eye + Vector3(sin(yaw), 0.0, cos(yaw)) * 1000.0, false)
		for i in 60:
			await get_tree().process_frame
		for i in 120:
			await get_tree().process_frame
			gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport))
			cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			own.append(world.terrain.skyline.frame_ms)
	for each: PackedFloat64Array in [gpu, cpu]:
		each.sort()
	var mean := 0.0
	for each in own:
		mean += each
	return Vector3(gpu[gpu.size() / 2], cpu[cpu.size() / 2], mean / own.size())


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
func _shoot(name: String, what: String, zoom_by := ZOOM) -> void:
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	shot.save_png(_out.path_join(name + ".png"))
	var middle := shot.get_size() / 2
	var window := WINDOW * ZOOM / zoom_by
	var zoom := shot.get_region(Rect2i(middle - window / 2, window))
	zoom.resize(window.x * zoom_by, window.y * zoom_by, Image.INTERPOLATE_NEAREST)
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


## The first clear morning at a place: MORNING local, the sun well up, and
## no storm within a few kilometres now or ten minutes on, so nothing towers
## over the view; nearer, if no morning is that clear.
func _clear_morning(at: Vector2) -> float:
	var day := world.weather.day
	var moon := world.moon
	var length := world.tuning.day_minutes * 60.0
	var first := fposmod(MORNING - day.time_of_day(0.0, moon.longitude), 1.0) * length
	for far: float in [5000.0, 2500.0, 0.0]:
		for d in 300:
			var t := first + d * length
			if day.sunlight(t, moon.latitude, moon.longitude) > 0.3 and _calm_round(at, t, far):
				return t
	return first


func _calm_round(at: Vector2, t: float, far: float) -> bool:
	var field := world.weather.field
	for when: float in [t, t + 600.0]:
		if field.raw_storm_at(at.x, at.y, when) > 0.0:
			return false
		for k in (12 if far > 0.0 else 0):
			for by: float in [far * 0.5, far]:
				var p := at + Vector2.from_angle(TAU * k / 12.0) * by
				if field.raw_storm_at(p.x, p.y, when) > 0.0:
					return false
	return true


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
