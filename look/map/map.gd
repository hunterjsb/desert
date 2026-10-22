extends Node
## Look-test: the Console's one Map and its filters. Beside the Walker, a
## Console with a radar, weather instruments and a ground radar, a Home
## marked on a plate nearby, every contact the Walker keeps noted and the
## Walker taught: its screen with each filter alone, then all three. Needs a
## GPU, not --headless; scripts/unseen.sh gives it one with no window:
##   scripts/unseen.sh --path . --resolution 1280x720 res://look/map/map.tscn -- <out dir>
## Shots: weather, survey, nav, all.

const WORLD_SCENE := preload("res://game/world/world.tscn")


## A staged anomaly 4 km north-east of wherever it's asked, for the weather once taught.
class Staged extends WeatherField:
	func anomalies_near(x: float, z: float, t: float, _reach: float) -> Array[Dictionary]:
		return [{"x": x + 2800.0, "z": z - 2800.0, "radius": 8000.0, "peak": t + 600.0, "strength": 1.0, "share": 0.0}]


var world: World


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://map"
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	Tuning.current().run_seed = 1234
	world = WORLD_SCENE.instantiate()
	add_child(world)
	await _ground()
	world.player.set_process_unhandled_input(false)
	world.player.set_physics_process(false)
	var scenario := Scenarios.by_key("walker")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	await _ground()
	var dropped := await Scenarios.lay(world, scenario, place)
	var console: Console = dropped.filter(func(n: Node) -> bool: return n is Console)[0]
	for id: StringName in [&"radar", &"barometer", &"hygrometer", &"ground_radar"]:
		var part := Catalog.part(id)
		world.content.add_child(part)
		console.fit(part, Scenarios._free(console, part.kind))
	var home := Scenarios.rig_at(world, [[&"stick", Vector2i.ZERO, &"top", Vector2(-0.2, 0.0), 0.0, &"home_beacon", &"beacon"],
		[&"stick", Vector2i.ZERO, &"top", Vector2(0.25, 0.0), 0.0, &"battery"]], [-90.0, 160.0], false)
	print("map: Home %s" % ["marked" if world.home.mark(home.named.beacon) == "" else "refused"])
	var every := world.tuning.walker_log_every
	var slot := ceilf(world.time / every) * every
	for k in world.tuning.walker_contacts_kept + 1:
		world.time = slot + k * every + 1.0
		await ticks(3)
	world.weather.field = Staged.new(world.run_seed, Tuning.current())
	console.upload()
	console.page = Console.Page.MAP
	# Long enough for the radar to sweep its map whole.
	world.time_warp = 1.0
	for i in 600:
		await ticks(1)
		if console._map.size() == console.map_cells() * console.map_cells() and console._map_passes > 0:
			break
	world.time_warp = 0.0
	for shot: Array in [["weather", ["survey", "nav"]], ["survey", ["weather", "nav"]], ["nav", ["weather", "survey"]], ["all", []]]:
		console.filters_off = shot[1]
		console._screen_at = -INF
		await ticks(3)
		await RenderingServer.frame_post_draw
		var image := console._viewport.get_texture().get_image()
		if image != null:
			image.save_png(out.path_join("%s.png" % shot[0]))
		print("map: %s, %s" % [shot[0], console.screen_text(Console.Page.MAP).replace("\n", " | ").left(200)])
	print("map: %d bearings, taught %s, filters %s" % [console.bearings.size(), world.taught, console.filters(console.pooled_readings())])
	get_tree().quit()


func _ground() -> void:
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle() and world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			break
	await ticks(10)


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
