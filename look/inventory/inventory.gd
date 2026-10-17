extends Node
## Look-test: the inventory open on seed 1234 at mid-morning, carrying three
## canisters, a ration, a coil, a radio playing and a compass, shot facing
## north and facing east; then with ten batteries more, encumbered, and at
## dusk. It prints what the view costs a frame with it shut, open and still,
## and open while you turn, which draws the compass again every frame.
##   godot --path . --disable-vsync res://look/inventory/inventory.tscn -- --capture <dir>
## A small window that never takes focus, nothing but this script moving
## anything, and silence.

const SEED := 1234
const FRAMES := 60
const ROUNDS := 4
## How fast you turn while the cost is measured, degrees a frame.
const TURNING := 3.0

@onready var world: World = $World


func _enter_tree() -> void:
	Tuning.current().run_seed = SEED


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://inventory")


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
	player.suit.set_process_unhandled_input(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _ground()
	player.set_physics_process(false)
	player.camera.rotation_degrees.x = -8.0
	await _fill(player.suit)
	await _ticks(30)
	var suit := player.suit
	suit.show_view(true)
	for shot: Array in [["north", 0.0], ["east", -90.0]]:
		player.rotation_degrees.y = shot[1]
		await _ticks(10)
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("inventory_%s.png" % shot[0]))
	await _cost(suit)
	for i in 10:
		suit.carried.append(Catalog.part(&"battery"))
	await _ticks(10)
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("inventory_encumbered.png"))
	var dusk := world.tuning.day_minutes * 60.0 * (0.76 - world.tuning.start_time_of_day)
	world.time = dusk
	await _ticks(60)
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("inventory_dusk.png"))
	get_tree().quit()


## What a camp's day leaves you carrying: water and food, a coil, a radio
## playing and a compass.
func _fill(suit: Suit) -> void:
	var radio := Catalog.device(&"radio") as Radio
	var cell := Catalog.part(&"battery") as Battery
	radio.fit(cell, radio.sockets().filter(func(s: Socket) -> bool: return s.kind == &"battery")[0])
	cell.charge_wh = 64.0
	world.content.add_child(radio)
	radio.interact(world.player)
	var coil := Catalog.part(&"coil")
	coil.set_meta(&"rolled", &"coil")
	coil.set_meta(&"rolled_m", 6.0)
	suit.carried.append_array([Catalog.part(&"canister"), Catalog.part(&"canister"), coil])
	for thing: RigidBody3D in [radio, Catalog.part(&"compass")]:
		if thing.get_parent() == null:
			world.content.add_child(thing)
		thing.global_position = world.player.global_position + Vector3.UP
		world.player.hands.hold(thing)
		await _ticks(20)
		suit.put_in()


## The view's cost a frame, alternated so a busy machine weighs on each alike:
## shut, open and still, and open while you turn. Frame times are the wall
## clock's with vsync off, the GPU's the main view's; a thing's picture is
## timed on the frames the compass draws, turning.
func _cost(suit: Suit) -> void:
	var main := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(main, true)
	var compass := suit.look_of(suit.stacks().size() - 1)
	RenderingServer.viewport_set_measure_render_time(compass.get_viewport_rid(), true)
	var frame := [0.0, 0.0, 0.0]
	var gpu := [0.0, 0.0, 0.0]
	var drawn := [0, 0, 0]
	var picture := 0.0
	for round in ROUNDS:
		for way in 3:
			suit.show_view(way != 0)
			for i in 10:
				await get_tree().process_frame
			var draws := _draws(suit)
			var last := Time.get_ticks_usec()
			for i in FRAMES:
				if way == 2:
					world.player.rotation_degrees.y += TURNING
				await get_tree().process_frame
				var now := Time.get_ticks_usec()
				frame[way] += (now - last) / 1000.0
				last = now
				gpu[way] += RenderingServer.viewport_get_measured_render_time_gpu(main)
				if way == 2:
					picture += RenderingServer.viewport_get_measured_render_time_gpu(compass.get_viewport_rid())
			drawn[way] += _draws(suit) - draws
	var n := float(ROUNDS * FRAMES)
	for way in 3:
		print("inventory: %-14s frame %.3f ms, main view's gpu %.3f ms, %.2f pictures drawn a frame"
			% [["shut", "open, still", "open, turning"][way], frame[way] / n, gpu[way] / n, drawn[way] / n])
	print("inventory: a thing's picture %.3f ms of gpu the frame it's drawn, at %s%s"
		% [picture / n, get_viewport().get_visible_rect().size, _shared_gpu()])
	suit.show_view(true)


func _draws(suit: Suit) -> int:
	var total := 0
	for i in suit.stacks().size():
		total += suit.look_of(i).draws if suit.look_of(i) != null else 0
	return total


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
