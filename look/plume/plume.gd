extends Node
## Look-test: the plumes. The rift's live vent in moments the run's own
## weather gives (a calm, a strong wind, a burst, dusk, a front coming over it
## and a storm over it, night), each shot from the side across the wind, near
## and far; a burst towering over a storm by the vent from 15 km; a gas
## pocket's dust; the far-side volcano's flank vent; and the rift vent's mouth
## up close. Each shot also times the GPU with the plumes drawn and without.
##   scripts/unseen.sh --path . --disable-vsync res://look/plume/plume.tscn -- --capture <dir> [--only a_b,c_d]
## Each shot is <moment>_<range>.png.

const SEED := 1234
## The shots: [moment, range, m off, eye's height over the sand, m].
const SHOTS := [
	["calm", "near", 260.0, 6.0], ["calm", "mid", 1500.0, 3.0], ["calm", "far", 7000.0, 2.0],
	["wind", "near", 260.0, 6.0], ["wind", "mid", 1500.0, 3.0], ["wind", "far", 7000.0, 2.0],
	["burst", "near", 1500.0, 3.0], ["burst", "mid", 7000.0, 2.0], ["burst", "far", 25000.0, 2.0],
	["over", "far", 15000.0, 2.0],
	["dusk", "mid", 1500.0, 3.0],
	["storm", "mid", 1500.0, 3.0], ["swallowed", "mid", 1500.0, 3.0], ["night", "mid", 1500.0, 3.0],
	["pocket", "far", 6000.0, 2.0], ["flank", "far", 7000.0, 2.0],
]
## Frames timed in each turn with the plumes drawn, and without, and the turns.
const TIMED := 12
const TURNS := 6
## How far moments are looked for, game days.
const DAYS := 200

@onready var world: World = $World

var _vent: Dictionary
var _root: Vector3
## Where each source's own point is laid, world metres, by id: every shot of
## it lays it there, so the weather over it is the same however far you went.
var _laid := {}
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
	var only := PackedStringArray(args[args.find("--only") + 1].split(",")) if args.has("--only") else PackedStringArray()
	DirAccess.make_dir_recursive_absolute(out)
	_quiet()
	var geology := world.shape.history.geology
	_vent = geology.live()[0]
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	# Beside the vent once, to lay its mouth where every shot of it lays it.
	var radius := geology.radius
	var stand := Sphere.toward(_vent.p, _vent.bearing + PI * 0.5, 300.0 / radius)
	world.travel(rad_to_deg(Sphere.latitude(stand)), rad_to_deg(Sphere.longitude(stand)), 0.0)
	world.time_warp = 0.0
	await _ground()
	for i in 5:
		await get_tree().process_frame
	_root = world.weather.plume_for(_vent.id).root
	var raw := world.shape.sites.anchor().place(_vent.p)
	_laid[_vent.id] = raw
	print("plume: the rift vent's mouth at %.0f,%.0f,%.0f" % [_root.x, _root.y, _root.z])
	for shot: Array in SHOTS:
		var name := "%s_%s" % [shot[0], shot[1]]
		if not only.is_empty() and not only.has(name):
			continue
		var found := _moment(shot)
		if found.is_empty():
			print("plume: no %s moment found" % name)
			continue
		print("plume: %s at t=%.0f (local %.3f) %s" % [name, found.t, _local(found.t, found.source), found.says])
		await _shoot(name, found, shot, out)
	if only.is_empty() or only.has("mouth_close"):
		await _mouth(out)
	for line in _costs:
		print("plume: cost %s" % line)
	get_tree().quit()


## A moment for a shot, the run's own: {t, source, root (world), says}; {} if
## none within DAYS.
func _moment(shot: Array) -> Dictionary:
	var geology := world.shape.history.geology
	var field := world.weather.field
	var moment: String = shot[0]
	var span := DAYS * world.tuning.day_minutes * 60.0
	var source := _vent
	if moment == "flank":
		source = geology.live()[1]
	var root := _root_of(source)
	var clear := func(at: Vector3, t: float) -> bool: return field.raw_storm_at(at.x, at.z, t) < -0.08
	var daylight := func(t: float) -> bool: return _local(t, source) > 0.33 and _local(t, source) < 0.62 \
		and world.weather.day.sun_shown(t) >= 1.0
	if moment == "pocket":
		for each in geology.pockets(600.0, span):
			var at := _root_of(each)
			var t: float = each.start + 90.0
			var eye := _eye(at, t, shot)
			if daylight.call(t) and _clear_eye(eye, t) and Plume.seen_through(field, world.tuning, eye, at + Vector3.UP * 50.0, t) > 0.9:
				return {"t": t, "source": each, "root": at, "says": "a pocket blowing, x%.1f" % geology.venting(each, t).x}
		return {}
	if moment in ["burst", "over"]:
		var b := geology.next_burst(source, 600.0)
		while b < span:
			var t := b + (240.0 if moment == "over" else 180.0)
			var eye := _eye(root, t, shot)
			var top := _top(source, root, t)
			var foot := Plume.seen_through(field, world.tuning, eye, root + Vector3.UP * 50.0, t)
			var tower := Plume.seen_through(field, world.tuning, eye, top, t)
			var wanted := foot < 0.1 and tower > 0.8 if moment == "over" \
				else tower > 0.8 and (foot > 0.9 or shot[2] > 10000.0)
			var far: bool = shot[2] > 10000.0
			var lit: bool = daylight.call(t) or far and _local(t, source) > 0.28 and _local(t, source) < 0.7
			if lit and (_clear_eye(eye, t) or far and world.weather.field.raw_storm_at(eye.x, eye.z, t) < -0.05) and wanted:
				return {"t": t, "source": source, "root": root, "says": "venting x%.0f, its top %.1f km up" % [
					geology.venting(source, t).x, top.y / 1000.0]}
			b = geology.next_burst(source, b + 1.0)
		return {}
	var best := {}
	var best_wind := INF if moment == "calm" else 0.0
	var t := 600.0
	while t < span:
		var v := geology.venting(source, t).x
		var local := _local(t, source)
		var wanted := false
		match moment:
			"calm", "wind", "flank":
				wanted = daylight.call(t) and v < 1.3
			"dusk":
				wanted = local > 0.725 and local < 0.75 and v < 1.3
			"night":
				wanted = local > 0.9 and local < 0.97 and v < 1.3
			"storm":
				var raw := field.raw_storm_at(root.x, root.z, t)
				wanted = daylight.call(t) and raw > -0.03 and raw < -0.005
			"swallowed":
				wanted = daylight.call(t) and field.raw_storm_at(root.x, root.z, t) > 0.08
		if wanted:
			var eye := _eye(root, t, shot)
			var line: bool = moment in ["storm", "swallowed"] or (clear.call(root, t) and clear.call(root, t - 600.0)
				and Plume.seen_through(field, world.tuning, eye, root + Vector3.UP * 50.0, t) > 0.9)
			if line and _clear_eye(eye, t):
				var wind := field.steady_wind_at(root.x, root.z, t).length()
				var says := "steady wind %.1f m/s" % wind
				if moment == "calm" and wind < best_wind or moment == "wind" and wind > best_wind:
					best_wind = wind
					best = {"t": t, "source": source, "root": root, "says": says}
				elif not moment in ["calm", "wind"]:
					return {"t": t, "source": source, "root": root, "says": says}
		t += 10.0
	return best


## Clear well away from a front at the eye, where no outflow throws grit at it.
func _clear_eye(eye: Vector3, t: float) -> bool:
	return world.weather.field.raw_storm_at(eye.x, eye.z, t) < -0.1


## Where a shot's eye stands for a source rising at `root`: off to the side
## across the wind, a little downwind; far off, on the highest sand near, as
## you'd climb a crest to look.
func _eye(root: Vector3, t: float, shot: Array) -> Vector3:
	var away: float = shot[2]
	var wind := world.weather.field.steady_wind_at(root.x, root.z, t).normalized()
	var at := Vector2(root.x, root.z) + Vector2(-wind.y, wind.x) * away + wind * away * 0.25
	if away >= 6000.0:
		var best := at
		for j in range(-8, 9):
			for i in range(-8, 9):
				var p := at + Vector2(i, j) * 30.0
				if world.shape.dunes(p.x, p.y) > world.shape.dunes(best.x, best.y):
					best = p
		at = best
	return Vector3(at.x, world.shape.dunes(at.x, at.y) + float(shot[3]), at.y)


## A source's place on this ground: the rift vent's mouth; the rest as the
## sheet would lay them from beside the vent.
func _root_of(source: Dictionary) -> Vector3:
	if source.id == _vent.id:
		return _root
	if not _laid.has(source.id):
		var off := Sphere.flat_from(_vent.p, source.p) * world.shape.history.radius
		var raw: Vector2 = _laid[_vent.id]
		# The far side is too far round to lay from here: anywhere will do.
		_laid[source.id] = raw + (Vector2(off.x, -off.y) if off.length() < 40000.0 else Vector2(60000.0, 0.0))
	var at: Vector2 = _laid[source.id]
	return Vector3(at.x, world.shape.dunes(at.x, at.y), at.y)


## The plume's top at t, world metres, the way it's drawn.
func _top(source: Dictionary, root: Vector3, t: float) -> Vector3:
	var geology := world.shape.history.geology
	var n := Plume.stability(world.weather.day, t, Sphere.latitude(source.p), Sphere.longitude(source.p), 1.0)
	var top := root
	for k in Plume.POINTS:
		var age := Plume.OLDEST * pow(float(k) / (Plume.POINTS - 1), Plume.CROWD)
		var v := geology.venting(source, t - age)
		if v.x > 0.0:
			var p: Vector4 = Plume.parcel_at(world.weather.field, world.tuning, Vector2(root.x, root.z), t, age, v.x, n, 1.0)[0]
			if root.y + p.y > top.y:
				top = root + Vector3(p.x, p.y, p.z)
	return top


func _shoot(name: String, found: Dictionary, shot: Array, out: String) -> void:
	var source: Dictionary = found.source
	var root: Vector3 = found.root
	var t: float = found.t
	var eye := _eye(root, t, shot)
	await _stand(Vector2(eye.x, eye.z), t, source)
	world.tuning.eye_adapts = shot[0] == "night"
	world.weather.forecast_now()
	eye.y = world.height_at(eye.x, eye.z) + float(shot[3])
	var plume := world.weather.plume_for(source.id)
	# At the bend, or for a burst its middle height, a pocket's what's blown up.
	var target := _top(source, root, t).lerp(root, 0.5) if shot[0] in ["burst", "over", "pocket"] \
		else (plume._point(25.0 if shot[1] == "near" else 45.0) if plume != null else root)
	await _look(eye, target)
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	var drawn := []
	for each in world.weather.plumes:
		if each.visible:
			drawn.append("%s %.1f km" % [each.source.id, Vector2(each.root.x - eye.x, each.root.z - eye.z).length() / 1000.0])
	var cost := await _time()
	_costs.append("%s: GPU %.2f ms a frame with them, which adds %.2f; their main thread %.3f ms a frame" % [
		name, cost.x, cost.y, cost.z])
	world.tuning.eye_adapts = false
	print("plume: %s from %.1f km; drawn: %s" % [name, Vector2(root.x - eye.x, root.z - eye.z).length() / 1000.0,
		", ".join(drawn)])


## The rift vent's mouth up close, on the calm's moment.
func _mouth(out: String) -> void:
	var found := _moment(SHOTS[0])
	var plume := world.weather.plume_for(_vent.id)
	var slot := plume.slot if plume != null else Vector2(0.0, 1.0)
	var eye2 := Vector2(_root.x, _root.z) + slot.rotated(2.0) * 48.0
	await _stand(eye2, found.get("t", 600.0), _vent)
	world.weather.forecast_now()
	var eye := Vector3(eye2.x, world.height_at(eye2.x, eye2.y) + 7.0, eye2.y)
	await _look(eye, _root + Vector3(0.0, 2.0, 0.0))
	get_viewport().get_texture().get_image().save_png(out.path_join("mouth_close.png"))
	print("plume: mouth_close 48 m from it")


## Stands you at a world place at world time t, the moon's point under you
## set so the source's own point lands where it's laid for these shots.
func _stand(eye2: Vector2, t: float, source: Dictionary) -> void:
	var radius := world.shape.history.radius
	_root_of(source)
	var laid: Vector2 = _laid[source.id]
	var want := Vector2(laid.x - eye2.x, eye2.y - laid.y) / radius
	var p := Sphere.from_flat(source.p, -want)
	for i in 6:
		p = Sphere.from_flat(p, Sphere.flat_from(p, source.p) - want)
	world.respawn(eye2.x, eye2.y, 0.0, t)
	world.time_warp = 0.0
	world.moon.place(rad_to_deg(Sphere.latitude(p)), rad_to_deg(Sphere.longitude(p)))
	await _ground()
	for i in 4:
		await get_tree().process_frame


## GPU ms a frame with the plumes drawn, and what they add over the same view
## without: the median of the turns' differences, each turn a window drawn and
## one not, side by side, since the GPU's clock wanders; and their own
## main-thread ms a frame while drawn.
func _time() -> Vector3:
	var vp := get_viewport().get_viewport_rid()
	var with := PackedFloat32Array()
	var adds := PackedFloat32Array()
	var cpu := 0.0
	var frames := 0
	for turn in TURNS:
		var sums := Vector2.ZERO
		for drawn in [true, false]:
			for plume in world.weather.plumes:
				plume.process_mode = Node.PROCESS_MODE_INHERIT if drawn else Node.PROCESS_MODE_DISABLED
				if not drawn:
					plume.visible = false
			for i in 3:
				await RenderingServer.frame_post_draw
			for i in TIMED:
				await RenderingServer.frame_post_draw
				var gpu := RenderingServer.viewport_get_measured_render_time_gpu(vp)
				if drawn:
					sums.x += gpu
					for plume in world.weather.plumes:
						cpu += plume.frame_ms
					frames += 1
				else:
					sums.y += gpu
		with.append(sums.x / TIMED)
		adds.append((sums.x - sums.y) / TIMED)
	for plume in world.weather.plumes:
		plume.process_mode = Node.PROCESS_MODE_INHERIT
	with.sort()
	adds.sort()
	return Vector3(with[with.size() / 2], adds[adds.size() / 2], cpu / frames)


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


func _local(t: float, source: Dictionary) -> float:
	return world.weather.day.time_of_day(t, Sphere.longitude(source.p))


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
