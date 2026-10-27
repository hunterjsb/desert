extends Node
## Look-test: the Walker and the living city. The Walker on the Rim near,
## from its flank and its front quarter, and far off, its stand-in at its own
## size; the Console's Map with navigation alone, the bearings it noted
## beside it and their fix; the living city's lights at night from two km and
## one; and after teaching, its Map's weather showing an anomaly, then with
## navigation over it. Needs a GPU, not
## --headless; scripts/unseen.sh gives it one with no window:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/walker/walker.tscn -- <out dir>

const WORLD_SCENE := preload("res://game/world/world.tscn")


## A staged anomaly 4 km north-east of wherever it's asked, for the map after teaching.
class Staged extends WeatherField:
	func anomalies_near(x: float, z: float, t: float, _reach: float) -> Array[Dictionary]:
		return [{"x": x + 2800.0, "z": z - 2800.0, "radius": 8000.0, "peak": t + 600.0, "strength": 1.0, "share": 0.0}]


var world: World
var camera: Camera3D
var out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://walker"
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	Tuning.current().run_seed = 1234
	Tuning.current().eye_adapts = false
	# Clear skies throughout: the far side's storms would hide the city.
	Tuning.current().storm_threshold = 2.0
	world = WORLD_SCENE.instantiate()
	add_child(world)
	await _ground()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	world.player.set_process_unhandled_input(false)
	world.player.set_physics_process(false)
	camera = Camera3D.new()
	camera.fov = 60.0
	add_child(camera)
	camera.make_current()
	var walker := await _walker()
	await _far(walker)
	await _city()
	get_tree().quit()


## Beside it as it comes by, its flank, front quarter and port; the Console
## beside you, its Map's navigation and, once the Walker's taught, its weather.
func _walker() -> Walker:
	var scenario := Scenarios.by_key("walker")
	var place := Scenarios.find(world, scenario)
	Scenarios.stand(world, scenario, place)
	await _ground()
	var dropped := await Scenarios.lay(world, scenario, place)
	var console: Console = dropped.filter(func(n: Node) -> bool: return n is Console)[0]
	var walker: Walker = get_tree().get_nodes_in_group(&"walker")[0]
	world.time_warp = 1.0
	while walker.global_position.distance_to(world.player.global_position) > 9.0 and world.time < place.time + 120.0:
		await ticks(1)
	world.time_warp = 0.0
	var at := walker.global_position
	var side := walker.global_basis.x
	var ahead := -walker.global_basis.z
	await shoot("near", at + side * 7.5 + ahead * 2.0 + Vector3.UP * 0.2, at + Vector3.DOWN * 0.4)
	await shoot("front", at + ahead * 7.0 - side * 4.0 + Vector3.UP * 1.0, at + Vector3.DOWN * 0.3)
	await shoot("port", walker.port.global_position + side * 1.4 + Vector3.UP * 0.3, walker.port.global_position)
	await _chart(console)
	await _taught(console)
	return walker


## Far off, as you'd see it on the skyline, and that far off through a long lens.
func _far(walker: Walker) -> void:
	var at := walker.global_position
	var away := _in_sight(at, 1200.0, 2.5)
	world.player.global_position = Vector3(away.x, world.height_under(away), away.z)
	await _ground()
	var eye := world.player.global_position + Vector3.UP * 1.65
	at = walker.global_position
	camera.fov = 60.0
	await shoot("far", eye, at + Vector3.UP * 1.0)
	camera.fov = 4.0
	await shoot("far_close", eye, at + Vector3.UP * 0.5)
	camera.fov = 60.0
	print("walker: %.0f m off, its stand-in past %.0f m" % [eye.distance_to(at), world.tuning.skyline_handover_m.y])


## The Map's navigation alone once it has noted every contact the Walker keeps.
func _chart(console: Console) -> void:
	var every := world.tuning.walker_log_every
	var slot := ceilf(world.time / every) * every
	for k in world.tuning.walker_contacts_kept + 1:
		world.time = slot + k * every + 1.0
		await ticks(3)
	console.page = Console.Page.MAP
	console.filters_off = ["weather"]
	await _screen(console, "chart")
	print("walker: %d bearings noted, a fix %s" % [console.bearings.size(), not Chart.fix(console.bearings, world.tuning).is_empty()])


## Taught: its Map's weather shows an anomaly, alone and with navigation.
func _taught(console: Console) -> void:
	world.weather.field = Staged.new(world.run_seed, Tuning.current())
	world.taught = true
	console.page = Console.Page.MAP
	console.filters_off = ["nav"]
	await ticks(5)
	await _screen(console, "taught_map")
	console.filters_off = []
	await _screen(console, "taught_chart")


## The living city by night from two km off and one.
func _city() -> void:
	var city := Radio.gods_of(world).city
	var day := world.weather.day
	var t := world.time
	while city.moving(t) or day.time_of_day(t, Sphere.longitude(city.at(t))) > 0.02:
		t += 5.0
	for each: Array in [[2000.0, "city_far"], [1000.0, "city"]]:
		var at := Sphere.toward(city.at(t), 0.0, each[0] / world.shape.history.radius)
		world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
		world.time = t
		world.time_warp = 0.0
		await _ground()
		await ticks(5)
		var lights: CityLights = world.get_children().filter(func(n: Node) -> bool: return n is CityLights)[0]
		var middle := lights.global_position + Vector3.UP * 10.0
		# Where its lights show over the dunes, as far off.
		var stand := _in_sight(middle, each[0], 0.0)
		world.player.global_position = Vector3(stand.x, world.height_under(stand), stand.z)
		await _ground()
		await ticks(30)
		await shoot(each[1], world.player.global_position + Vector3.UP * 1.65, middle)
	var lights: CityLights = world.get_children().filter(func(n: Node) -> bool: return n is CityLights)[0]
	print("walker: the city shown %.2f past storms %.2f" % [lights.shown, lights.veil])


## A place about `far` m from `at` on the sand whose eye sees `high` m over
## it clear of the dunes (over its sand, or over `at` itself for none), of
## sixteen ways round and a few distances; the highest of them if none does.
func _in_sight(at: Vector3, far: float, high: float) -> Vector3:
	var shape := world.shape
	var top := at
	if high > 0.0:
		top.y = shape.height_at(world.world_x(at.x), world.world_z(at.z)) + high
	var best := at + Vector3(far, 0.0, 0.0)
	var highest := -INF
	for d: float in [1.0, 0.9, 1.1, 0.8, 1.2]:
		for k in 16:
			var way := Vector3(cos(TAU * k / 16.0), 0.0, sin(TAU * k / 16.0))
			var spot := at + way * far * d
			spot.y = 0.0
			var sand := shape.height_at(world.world_x(spot.x), world.world_z(spot.z))
			var eye := Vector3(spot.x, sand + 1.65, spot.z)
			var clear := true
			for i in range(1, 60):
				var p := eye.lerp(top, i / 60.0)
				if shape.height_at(world.world_x(p.x), world.world_z(p.z)) > p.y:
					clear = false
					break
			if clear:
				return spot
			if sand > highest:
				highest = sand
				best = spot
	return best


## A Console's screen, from in front of it, drawn afresh with the clock stopped.
func _screen(console: Console, name: String) -> void:
	console._screen_at = -INF
	var front := -console.global_basis.z
	world.player.global_position = console.global_position + front * 1.4 - Vector3.UP * 1.0
	await ticks(20)
	await shoot(name, console.global_position + front * 1.3 + Vector3.UP * 0.05, console.global_position + Vector3.UP * 0.05)


func _ground() -> void:
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle() and world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			break
	await ticks(10)


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func shoot(name: String, from: Vector3, to: Vector3) -> void:
	camera.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(out.path_join(name + ".png"))
	print("walker: shot ", name)
