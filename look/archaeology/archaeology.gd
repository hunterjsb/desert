extends Node
## Look-test: dune archaeology. A big dune's ruin a big storm laid bare, shot
## in the clear after it from down its lee; the archaeology setup on a deck
## beside it, and its Console's ground radar page; and the light things a
## storm let fall in a crest's lee lying round you at a slip face's foot.
##   scripts/unseen.sh --path . --disable-vsync res://look/archaeology/archaeology.tscn -- --capture <dir>
## Shots: ruin, deck, page, lee.

const SEED := 1234
const EYE := 1.65
## Shot by day, local time.
const LIGHT := Vector2(0.32, 0.7)
## Down its lee from the ruin's ground, m; the deck this far to your right
## and ahead of where you stand for that.
const OFF := 5.0
const DECK := [4.0, -3.0]

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = true
	tuning.finds_per_chunk = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[args.find("--capture") + 1] if args.has("--capture") else "user://archaeology"
	DirAccess.make_dir_recursive_absolute(out)
	_quiet()
	world.time_warp = 0.0
	await _ground()
	var found := _ruin_after()
	if found.is_empty():
		print("archaeology: no big dune's ruin bared after a storm by day")
		get_tree().quit(1)
		return
	world.time = found.time
	var copy: Structure = found.site
	var down := world.shape.downwind()
	var stand := Vector2(copy.x, copy.z) + down * (copy.reach + OFF)
	await _look(_at(stand), Vector3(copy.x, copy.pad() + 1.2, copy.z))
	var seed: DuneRuins.Seed = null
	for i in 600:
		seed = world.shape.sites.dunes._cells.get(found.key)
		if seed != null and seed.built:
			break
		await get_tree().physics_frame
	var site: Structure = seed.site if seed != null and seed.built else copy
	await _look(_at(stand), Vector3(site.x, site.pad() + 1.2, site.z))
	_shot(out, "ruin", "%s %s, level %.2f, %.1f m deep in the lee of a dune %.0f m tall, %s" % [Exposure.NAMES[site.state()],
		site.kind, site.level(), site.depth, seed.crest if seed != null else 0.0, _clock()])

	var kit: Kit = load("res://game/survival/archaeologist_kit.tres")
	var rig := Scenarios.rig_at(world, kit.assembled.camp.rig, DECK, false)
	var console: Console = rig.named.console
	for i in 120:
		await get_tree().physics_frame
	# In front of the Console's screen and to one side, looking down on the deck.
	var middle := Vector3.ZERO
	for piece in rig.deck.pieces():
		middle += piece.global_position / rig.deck.pieces().size()
	var eye := console.global_transform * Vector3(1.4, 0.9, -2.4)
	await _look(Vector3(world.world_x(eye.x), eye.y, world.world_z(eye.z)),
		Vector3(world.world_x(middle.x), middle.y + 0.2, world.world_z(middle.z)))
	_shot(out, "deck", "a Console with a ground radar, a scoop and a sieve on a deck of three")
	console.page = Console.Page.SURVEY
	for i in 240:
		world.time += 0.25
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var page := console._viewport.get_texture().get_image()
	if page != null:
		page.save_png(out.path_join("page.png"))
	print("archaeology: page, %s" % console.screen_text(Console.Page.SURVEY).split("\n")[0])

	var lee := await _lee_fall()
	if lee.is_empty():
		print("archaeology: no slip face's foot with a storm by day")
	else:
		_shot(out, "lee", "%d light things fell round you through the storm, %s" % [lee.fallen, _clock()])
	get_tree().quit()


## Round the start, the big dune's ruin and moment by day, out of the storm,
## that has it furthest out of the sand within three days.
func _ruin_after() -> Dictionary:
	var dunes := world.shape.sites.dunes
	var field := world.weather.field
	var best := {}
	var most := 0.15
	for each in dunes.cells_near(world.spawn, 2500.0):
		var copy := DuneRuins.Seed.new()
		copy.key = each.key
		copy.id = each.id
		dunes.locate(copy)
		if copy.site == null:
			continue
		for m in range(30, 3 * 24 * 60):
			var t := m * 60.0
			var day := world.weather.day.time_of_day(t, world.moon.longitude)
			if day < LIGHT.x or day > LIGHT.y or field.raw_storm_at(copy.site.x, copy.site.z, t) >= -0.02:
				continue
			var level := Exposure.level(copy.site.depth, copy.site.pure_taken(t))
			if level > most:
				most = level
				best = {"key": copy.key, "site": copy.site, "time": t}
	return best


## At a tall slip face's foot through a storm's two hardest hours, the clock
## jumped half an hour at a time so what the lee lets fall is drawn; then the
## first clear moment by day after it: {fallen}, or {} if none.
func _lee_fall() -> Dictionary:
	var mean := WeatherField.mean_heading(SEED)
	var field := world.weather.field
	var tuning := world.tuning
	for foot in Scenarios.feet(world, mean):
		if world.weather.lee.share(foot.x, foot.y, mean) < Scenarios.LEE_SHARE:
			continue
		var t := 0.0
		while t < 3.0 * 24.0 * 3600.0:
			t += 300.0
			if field.raw_storm_at(foot.x, foot.y, t) < tuning.exposure_storm_full:
				continue
			var after := t + 3600.0
			while after < t + 6.0 * 3600.0:
				var day := world.weather.day.time_of_day(after, world.moon.longitude)
				if field.raw_storm_at(foot.x, foot.y, after) < -0.05 and day >= LIGHT.x and day <= LIGHT.y:
					break
				after += 120.0
			if after >= t + 6.0 * 3600.0:
				continue
			var up := -Vector2.from_angle(mean)
			await _look(_at(foot), _at(foot + up * 10.0))
			world.time = t - 3600.0
			world.salvage._drift_tick = floori(world.time / tuning.drift_tick_s)
			for k in 5:
				world.time += 1800.0
				for i in 3:
					await get_tree().physics_frame
			world.time = after
			var fallen: Array[Vector3] = []
			for node in world.content.get_children():
				if node is RigidBody3D and node.has_meta(&"drift"):
					var p: Vector3 = node.global_position
					fallen.append(Vector3(world.world_x(p.x), p.y, world.world_z(p.z)))
			if fallen.is_empty():
				return {"fallen": 0}
			# Over the nearest of them, the slip face behind, the rest beyond.
			fallen.sort_custom(func(a: Vector3, b: Vector3) -> bool:
				return Vector2(a.x, a.z).distance_to(foot) < Vector2(b.x, b.z).distance_to(foot))
			var near := Vector2(fallen[0].x, fallen[0].z)
			var eye := _at(near - up * 2.4)
			await _look(eye - Vector3(0.0, 0.25, 0.0), fallen[0])
			return {"fallen": fallen.size()}
	return {}


func _at(at: Vector2) -> Vector3:
	return Vector3(at.x, world.shape.height_at(at.x, at.y) + EYE, at.y)


func _shot(out: String, name: String, said: String) -> void:
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(out.path_join(name + ".png"))
	print("archaeology: %s, %s" % [name, said])


func _clock() -> String:
	var day := world.weather.day.time_of_day(world.time, world.moon.longitude) * 24.0
	return "%02d:%02d" % [floori(day), floori(fmod(day, 1.0) * 60.0)]


## Eyes at a world place, looking at another, world metres; the ground round
## built first.
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
