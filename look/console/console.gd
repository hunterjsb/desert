extends Node
## Look-test: the Console on seed 1234, as the "console" scenario stands it on
## its floating deck with a storm due, and one alone on a floating piece of
## its own. Shot as
## you'd see them standing a step or two back, at the game's own lens, and
## its screen close: the map at each resolution its gear gives (estimated
## with no radar, a radar alone, a radar and two more, the full set, two
## Consoles linked), its stats, its power page, and the front near with the
## smart shield on, on the map and on the power page.
## At the fixed exposure:
##   godot --path . --disable-vsync res://look/console/console.tscn -- --capture <dir>
## look/console/shoot.sh builds the sheet. A small window that never takes
## focus, nothing but this script moving anything, and silence. First of all
## it takes the screen out by hand and says how long that frame took: the
## hitch check a headless probe can't make, since only a GPU compiles shaders.

const SEED := 1234
## Standing: this far back from the screen, m, at the game's own lens, °.
const STANDING := 1.5
const LENS := 75.0
## Close: this far from the screen, m, and its lens.
const CLOSE := Vector2(1.55, 50.0)
## The front this near, m, for the last map, and the clock's pace meanwhile.
const NEAR := 1300.0
const WARP := 20.0
## The tiers shot, each as the instruments the Console keeps for it.
const TIERS := [
	["estimate", [&"anemometer", &"barometer", &"hygrometer"]],
	["radar", [&"radar"]],
	["radar_two", [&"radar", &"anemometer", &"barometer"]],
]

@onready var world: World = $World


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://console")


func _capture(out_dir: String) -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	player.hands.set_process(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _ground()
	var scenario := Scenarios.by_key("console")
	Scenarios.stand(world, scenario, Scenarios.find(world, scenario))
	await _ground()
	var dropped := Scenarios.console(world)
	var deck: Chassis = dropped[0]
	var made: Console = dropped.filter(func(b: Node) -> bool: return b is Console)[0]
	player.set_physics_process(false)
	player.flying = true
	await _ticks(150)
	await _take_screen(made)
	await _whole(out_dir, "deck", deck, made, 3.2, -0.5)
	await _standing(out_dir, "standing_map", made)
	made.page = Console.Page.STATS
	await _ticks(10)
	await _standing(out_dir, "standing_stats", made)
	await _close(out_dir, "stats", made)
	made.page = Console.Page.POWER
	await _ticks(10)
	await _close(out_dir, "power", made)
	made.page = Console.Page.MAP
	await _ticks(10)
	await _close(out_dir, "full", made)

	# Each tier: the instruments it keeps, the rest set aside meanwhile, the
	# deck's radio too.
	var radio: Radio = dropped.filter(func(b: Node) -> bool: return b is Radio)[0]
	var radio_on := deck.seat_of(radio)
	var radio_at := [radio_on.transform, radio_on.out, deck.own_piece(radio_on)]
	var spare := {}
	for socket in made.sockets():
		if socket.kind in [&"computer_mod", &"computer_top"] and socket.part != null:
			spare[socket] = socket.part.get_meta(&"catalog")
	for tier: Array in TIERS:
		for socket: Socket in spare:
			var keep: bool = spare[socket] in tier[1]
			if socket.part != null and not keep:
				made.take(socket).free()
			elif socket.part == null and keep:
				var part := Catalog.part(spare[socket])
				world.content.add_child(part)
				made.fit(part, socket)
		if deck.seat_of(radio) != null:
			deck.unstick(deck.seat_of(radio))
			radio.get_parent().remove_child(radio)
		await _ticks(200)
		await _close(out_dir, tier[0], made)
	for socket: Socket in spare:
		if socket.part == null:
			var part := Catalog.part(spare[socket])
			world.content.add_child(part)
			made.fit(part, socket)
	deck.stick(radio, radio_at[0], radio_at[1], radio_at[2])

	# A second Console linked on a third piece, its own radar: finer still.
	var piece := Catalog.device(&"chassis") as Chassis
	world.content.add_child(piece)
	piece.global_position = deck.global_position + Vector3(0.0, 3.0, 0.0)
	deck.join(piece, Rig.ring_of(deck, Vector2i.ZERO, Vector2i(-1, 0)), 0)
	var third := Rig.piece(deck, Vector2i(-1, 0))
	Stick.put(deck, third, Chassis.BOTTOM, Vector2.ZERO, 0.0, Catalog.part(&"hover_tray"))
	Stick.put(deck, third, Chassis.TOP, Vector2(0.3, 0.32), 0.0, Catalog.part(&"big_battery"))
	var other := Rig.make([&"console", [&"screen", &"radar"]]) as Console
	Stick.put(deck, third, Chassis.TOP, Vector2(0.0, -0.18), PI, other)
	await _ticks(200)
	await _close(out_dir, "linked", made)
	deck.dismount(deck.seat_of(other)).queue_free()
	await _ticks(120)

	world.time_warp = WARP
	for i in 60 * 120:
		var front: Dictionary = made.pooled_readings().get("front", {})
		if front.get("d", INF) <= NEAR or front.get("inside", false):
			break
		await get_tree().physics_frame
	world.time_warp = 1.0
	await _ticks(120)
	await _close(out_dir, "near", made)
	made.page = Console.Page.POWER
	await _ticks(10)
	await _close(out_dir, "near_power", made)
	made.page = Console.Page.MAP

	# One alone, on a floating piece of its own beside the deck.
	var own := Rig.build(world.content, [[&"stick", Vector2i.ZERO, &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
		[&"stick", Vector2i.ZERO, &"top", Vector2(0.0, -0.18), 180.0, [&"console", [&"screen", &"anemometer", &"barometer",
			&"hygrometer", &"particle_sensor", &"radar"]]],
		[&"stick", Vector2i.ZERO, &"top", Vector2(-0.2, 0.32), 0.0, &"big_battery"],
		[&"stick", Vector2i.ZERO, &"top", Vector2(0.2, 0.32), 0.0, &"big_battery"]]).deck
	var alone := own.mounted()[0] as Console
	var beside := made.global_position + _normal(made) * 3.5 - made.global_basis.x * 3.5
	# Its screen, the Console's front, to the deck's side as the deck's faces.
	own.global_transform = Transform3D(Basis(Vector3.UP, atan2(_normal(made).x, _normal(made).z)),
		Vector3(beside.x, world.height_under(beside) + own.rest_height(), beside.z))
	await _ticks(240)
	await _whole(out_dir, "alone", alone, alone, 2.4, -0.45)
	get_tree().quit()


## Takes the screen out by hand, the first thing taken this run, standing at
## it, and puts it back: its frame against the frames before.
func _take_screen(made: Console) -> void:
	var middle := _middle(made)
	_place(middle + _normal(made) * 1.0, middle, LENS)
	await _ticks(30)
	var hands := world.player.hands
	var before: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in 30:
		await get_tree().process_frame
		before.append((Time.get_ticks_usec() - last) / 1000.0)
		last = Time.get_ticks_usec()
	var screen := made._screen()
	var started := Time.get_ticks_usec()
	hands.grab()
	await get_tree().process_frame
	var took := (Time.get_ticks_usec() - started) / 1000.0
	before.sort()
	print("console: the screen taken out by hand, its frame %.1f ms, the frames before %.1f" % [took,
		before[before.size() / 2]])
	var part := hands.held as Part
	if part != null:
		hands._let_go()
		await get_tree().physics_frame
		part.get_parent().remove_child(part)
		world.content.add_child(part)
		made.fit(part, screen)
	await _ticks(30)


## The whole of it, from a few steps off and a little to one side, standing.
func _whole(out_dir: String, name: String, centre: Node3D, made: Console, off: float, swing: float) -> void:
	var normal := _normal(made).rotated(Vector3.UP, swing)
	var at := centre.global_position + normal * off
	await _shoot(out_dir, name, made, Vector3(at.x, world.height_under(at) + 1.65, at.z), made.global_position, LENS)


## Its screen as you'd read it standing a step or two back from it.
func _standing(out_dir: String, name: String, made: Console) -> void:
	var middle := _middle(made)
	var at := middle + _normal(made) * STANDING
	await _shoot(out_dir, name, made, Vector3(at.x, world.height_under(at) + 1.65, at.z), middle, LENS)


func _close(out_dir: String, name: String, made: Console) -> void:
	var middle := _middle(made)
	await _shoot(out_dir, name, made, middle + _normal(made) * CLOSE.x, middle, CLOSE.y)


func _middle(made: Console) -> Vector3:
	return made.global_transform * Vector3(0.0, 0.01, -0.33)


func _normal(made: Console) -> Vector3:
	var out := made.global_basis * Vector3.FORWARD
	return Vector3(out.x, 0.0, out.z).normalized()


func _shoot(out_dir: String, name: String, made: Console, eye: Vector3, target: Vector3, lens: float) -> void:
	_place(eye, target, lens)
	await _ticks(20)
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("console: %s, %d cells" % [name, made.map_cells()])


## Your eyes at a place, looking at a target through a lens.
func _place(eye: Vector3, target: Vector3, lens: float) -> void:
	var player := world.player
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	player.feel.set_process(false)
	player.camera.fov = lens


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
