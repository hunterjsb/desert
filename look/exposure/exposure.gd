extends Node
## Look-test: storms expose and rebury ruins. A hab pod stood by hand where a
## storm will lay it bare by day, shot from beside it in the clear before the
## storm, in it as it rises half out of the sand and as it works hardest, and
## in the clear again after; and in the storm from out in the dust, past where
## you'd see it, its bared windows glinting through.
##   scripts/unseen.sh --path . --disable-vsync res://look/exposure/exposure.tscn -- --capture <dir>
## Shots: before, rising, mid, after, glint, and glint_zoom round the middle.

const SEED := 1234
const KIND := &"hab_pod"
## Shot from this far off its window side, m, and from out in the dust.
const NEAR := 9.0
const FAR := 55.0
const EYE := 1.65
## Shot by day: its storm works hardest between these times of day, local,
## and it's clear before and after between these.
const DAY := Vector2(0.36, 0.6)
const LIGHT := Vector2(0.3, 0.72)

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = true
	tuning.finds_per_chunk = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[args.find("--capture") + 1] if args.has("--capture") else "user://exposure"
	DirAccess.make_dir_recursive_absolute(out)
	_quiet()
	world.time_warp = 0.0
	await _ground()
	var found := _find()
	if found.is_empty():
		print("exposure: no storm laid a hab pod bare by day")
		get_tree().quit(1)
		return
	var sites := world.shape.sites
	var site := sites.by_hand(KIND, found.x, found.z, 0.0, found.depth)
	sites.add(site)
	var side := (site.to_world(Vector2(1.0, 0.0)) - Vector2(site.x, site.z)).normalized()
	var rising := _rising(site, found.before, found.peak)
	for shot: Array in [["before", found.before, NEAR], ["rising", rising, NEAR], ["mid", found.peak, NEAR],
			["after", found.after, NEAR], ["glint", found.peak, FAR]]:
		world.time = shot[1]
		var eye2: Vector2 = Vector2(site.x, site.z) + side * (4.0 + float(shot[2]))
		var eye := Vector3(eye2.x, world.shape.height_at(eye2.x, eye2.y) + EYE, eye2.y)
		await _look(eye, Vector3(site.x, site.pad() + 1.4, site.z))
		var image := get_viewport().get_texture().get_image()
		if image != null:
			image.save_png(out.path_join(shot[0] + ".png"))
		if shot[0] == "glint" and image != null:
			var size := image.get_size()
			image = image.get_region(Rect2i(size * 2 / 5, size / 5))
			image.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
			image.save_png(out.path_join("glint_zoom.png"))
		print("exposure: %s, %s, level %.2f, %s, %.0f m off, %d glinting through the dust; %02d:%02d"
			% [shot[0], Exposure.NAMES[site.state()], site.level(), "in the storm" if world.weather.in_storm else "clear",
			Vector2(site.x, site.z).distance_to(eye2), world.terrain.skyline.dust_glints().size(),
			floori(world.weather.day.time_of_day(world.time, world.moon.longitude) * 24.0),
			floori(fmod(world.weather.day.time_of_day(world.time, world.moon.longitude) * 24.0, 1.0) * 60.0)])
	get_tree().quit()


## Round the start, a place and a day's storm that lays a hab pod bare at its
## height and leaves it under the sand in the clear before and after:
## {x, z, depth, before, peak, after}.
func _find() -> Dictionary:
	var field := world.weather.field
	var tuning := world.tuning
	var sites := world.shape.sites
	var from := Vector2(world.player_world_x() + 300.0, world.player_world_z())
	var best := {}
	var most := 1.0
	for ring in 4:
		for k in maxi(1, 8 * ring):
			var at := from + Vector2.from_angle(TAU * k / maxi(1, 8 * ring)) * ring * 120.0
			if not sites.by_hand(KIND, at.x, at.y, 0.0, 0.0).stands():
				continue
			var memo := Exposure.Memo.new()
			for m in range(90, 3 * 24 * 60):
				var t := (m + 1) * Exposure.SURGE_STEP_S
				var day := world.weather.day.time_of_day(t, world.moon.longitude)
				if day < DAY.x or day > DAY.y:
					continue
				var s := Exposure.surge_at(field, at.x, at.y, m, tuning, memo)
				if s < 1.0 or s < Exposure.surge_at(field, at.x, at.y, m - 1, tuning, memo) \
						or s < Exposure.surge_at(field, at.x, at.y, m + 1, tuning, memo):
					continue
				var before := _clear(field, at, t, -1.0)
				var after := _clear(field, at, t, 1.0)
				if is_nan(before) or is_nan(after):
					continue
				var depth := 3.45 * maxf(Exposure.taken(field, at.x, at.y, before, tuning, memo),
					Exposure.taken(field, at.x, at.y, after, tuning, memo))
				var score := Exposure.taken(field, at.x, at.y, t, tuning, memo) / maxf(depth, 0.1)
				if score > most:
					most = score
					best = {"x": at.x, "z": at.y, "depth": maxf(depth, 0.1), "before": before, "peak": t, "after": after}
	return best


## The nearest moment 15 to 90 minutes before (`way` -1) or after a storm's
## height that's clear at a place by day; NAN if none.
func _clear(field: WeatherField, at: Vector2, t: float, way: float) -> float:
	for minutes in range(15, 91, 1):
		var when := t + way * minutes * 60.0
		var day := world.weather.day.time_of_day(when, world.moon.longitude)
		if field.raw_storm_at(at.x, at.y, when) < -0.05 and day >= LIGHT.x and day <= LIGHT.y:
			return when
	return NAN


## The moment between two it's half out of the sand, the partly exposed look.
func _rising(site: Structure, from: float, to: float) -> float:
	for i in 40:
		var mid := (from + to) * 0.5
		if Exposure.level(site.depth, site.pure_taken(mid)) < 1.0:
			from = mid
		else:
			to = mid
	return to


func _look(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var offset := player.camera.global_position - player.global_position
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	await _ground()
	for i in 120:
		if world.terrain.is_pressed():
			break
		await get_tree().process_frame
	player.global_position = Vector3(world.engine_x(eye.x), eye.y, world.engine_z(eye.z)) - offset
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	for i in 60:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw


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
