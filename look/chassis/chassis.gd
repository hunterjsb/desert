extends Node
## Look-test: the chassis on seed 1234, a clear morning. Placing by hand, as
## you'd see it: a battery shown where it would stick, one shown red where
## it would clip with the words at your aim, one amber where it would sink a
## floating piece, a Console shown from your hold, and a row of batteries
## laid by aim alone, edged flush. Then camps built: the Surveyor's start, a
## camp laid out in stations, and a frame with walls and a shelf.
##   godot --path . --disable-vsync res://look/chassis/chassis.tscn -- --capture <dir>
## look/chassis/shoot.sh builds the sheet. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
const LENS := 70.0

@onready var world: World = $World
var hands: Hands


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://chassis")


func _capture(out_dir: String) -> void:
	var window := get_window()
	window.unfocusable = true
	window.size = Vector2i(960, 540)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	window.content_scale_size = Vector2i(1920, 1080)
	AudioServer.set_bus_mute(0, true)
	var player := world.player
	hands = player.hands
	player.set_process_unhandled_input(false)
	hands.set_process_unhandled_input(false)
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _ground()
	var noon := Scenarios.find(world, {"key": "noon", "kind": "clear", "day": [0.44, 0.5]})
	if not noon.is_empty():
		world.respawn(noon.x, noon.z, noon.yaw, noon.time)
	await _ground()
	player.set_physics_process(false)
	player.flying = true
	player.collision_layer = 0
	player.collision_mask = 0
	var home := player.global_position

	# Placing.
	var deck := _rig([[&"piece", Vector2i(1, 0)],
		[&"stick", Vector2i(0, 0), &"top", Vector2(-0.25, 0.25), 0.0, &"big_battery"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(0.22, -0.22), 0.0, &"shield"]], home + Vector3(0.0, 0.0, -3.0), false)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	hands.hold(cell)
	await _ticks(20)
	await _aim_at(deck.global_transform * deck.face_frame(Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP) * Vector3(0.2, 0.2, 0.0),
		Vector3(-0.5, 1.7, 1.9))
	await _shoot(out_dir, "preview")
	await _aim_at(deck.global_transform * deck.face_frame(deck, Chassis.TOP) * Vector3(-0.22, 0.22, 0.0), Vector3(0.0, 1.3, 1.1))
	await _shoot(out_dir, "blocked")
	hands.drop()
	await _ticks(10)
	cell.queue_free()

	# A row laid by aim alone, each a little off, edged flush.
	var row := _rig([], home + Vector3(3.5, 0.0, -3.0), false)
	var aims: Array[Vector2] = [Vector2(-0.36, -0.3), Vector2(-0.1, -0.28), Vector2(0.15, -0.33), Vector2(0.4, -0.29),
		Vector2(-0.33, 0.02), Vector2(-0.06, 0.05), Vector2(0.2, 0.0)]
	for aim in aims:
		var each := Catalog.part(&"big_battery")
		world.content.add_child(each)
		hands.hold(each)
		await _ticks(20)
		await _aim_at(row.global_transform * row.face_frame(row, Chassis.TOP) * Vector3(aim.x, aim.y, 0.0), Vector3(0.0, 1.3, 0.9))
		hands.grab()
		await _ticks(10)
	await _look(row.global_position + Vector3(0.0, 1.6, 1.4), row.global_position)
	await _shoot(out_dir, "rows")

	# Too heavy: a floating piece whose keel carries four big batteries.
	var light := _rig([[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"keel"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(-0.3, 0.3), 0.0, &"big_battery"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(0.3, 0.3), 0.0, &"big_battery"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(-0.3, -0.3), 0.0, &"big_battery"],
		[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, 0.0), 0.0, &"big_battery"]], home + Vector3(-3.5, 0.0, -3.0), true)
	await _ticks(120)
	var more := Catalog.part(&"big_battery")
	world.content.add_child(more)
	hands.hold(more)
	await _ticks(20)
	await _aim_at(light.global_transform * light.face_frame(light, Chassis.TOP) * Vector3(0.3, -0.3, 0.0), Vector3(0.0, 1.2, 1.0))
	await _shoot(out_dir, "heavy")
	hands.drop()
	await _ticks(10)
	more.queue_free()

	# A Console shown from your hold, the real thing where it would stand.
	var console := Rig.make([&"console", [&"screen", &"anemometer", &"barometer", &"radar"]]) as Console
	world.content.add_child(console)
	console.global_position = deck.global_position + Vector3(1.6, 0.7, 1.4)
	await _ticks(30)
	hands.grasp.take(console)
	await _aim_at(deck.global_transform * deck.face_frame(Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP) * Vector3(-0.1, -0.2, 0.0),
		Vector3(0.6, 1.4, 1.8))
	await _shoot(out_dir, "grasped")
	hands.grasp.let_go()
	await _ticks(10)

	# Camps.
	for each in world.content.get_children():
		if each is RigidBody3D and each != player:
			each.queue_free()
	await _ticks(10)
	for thing in Runs.kit(world, Kit.standard()):
		if thing is Chassis:
			deck = thing
	await _ticks(240)
	await _look(deck.global_transform * Vector3(0.5, 0.0, 0.0) + deck.global_basis * Vector3(-0.9, 1.2, 2.3),
		deck.global_transform * Vector3(0.6, 0.35, 0.2))
	await _shoot(out_dir, "surveyor")

	var stations := _rig(STATIONS, home + Vector3(0.0, 0.0, -9.0), true)
	await _ticks(240)
	await _look(stations.global_transform * Vector3(0.5, 0.0, 0.5) + stations.global_basis * Vector3(2.2, 2.4, 3.2),
		stations.global_transform * Vector3(0.5, 0.4, 0.5))
	await _shoot(out_dir, "stations")
	await _look(stations.global_transform * Vector3(0.5, 0.0, 0.5) + stations.global_basis * Vector3(-2.6, 2.2, -2.4),
		stations.global_transform * Vector3(0.5, 0.5, 0.5))
	await _shoot(out_dir, "stations_back")

	var framed := _rig(FRAMED, home + Vector3(6.0, 0.0, -9.0), false)
	await _ticks(120)
	await _look(framed.global_transform * Vector3(0.5, 0.0, 0.0) + framed.global_basis * Vector3(1.8, 1.9, 2.6),
		framed.global_transform * Vector3(0.6, 0.7, 0.0))
	await _shoot(out_dir, "frame")
	get_tree().quit()


## A camp in stations, a deck two by two on trays: power along its back
## (batteries and panels), weather at its front (the Console and its radio),
## and a workstation on a frame with a wall and a shelf.
const STATIONS := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)],
	[&"stick", Vector2i(0, 0), &"bottom", Vector2(0.0, 0.1), 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 0), &"bottom", Vector2(0.0, 0.1), 0.0, &"hover_tray"],
	[&"stick", Vector2i(0, 1), &"bottom", Vector2(0.0, -0.1), 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 1), &"bottom", Vector2(0.0, -0.1), 0.0, &"hover_tray"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, -0.05), 180.0, [&"console", [&"screen", &"anemometer", &"barometer", &"radar"]]],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, 0.38), 0.0, &"radio"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(-0.2, 0.2), 0.0, &"shield"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.27, 0.27), 0.0, &"lamp"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.0, 0.29), 0.0, &"solar_panel"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(-0.37, -0.25), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(-0.11, -0.25), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.15, -0.25), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.39, -0.25), 0.0, &"battery"],
	[&"frame", Vector2i(1, 1), 0],
	[&"wall", Vector2i(1, 1), &"right"],
	[&"wall", Vector2i(1, 1), &"top"],
	[&"stick", [Vector2i(1, 1), &"right"], &"top", Vector2(0.0, 0.1), 90.0, &"board"],
	[&"stick", [Vector2i(1, 1), &"top"], &"top", Vector2(0.0, 0.0), 0.0, &"solar_panel"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(-0.2, 0.2), 0.0, &"canister"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(0.15, 0.0), 0.0, &"sand_scoop"],
	[&"hook", Vector2i(0, 0), Vector2i(-1, 0)], [&"hook", Vector2i(0, 0), Vector2i(0, -1)]]
## A frame with walls on two sides and a shelf, things on each, beside a
## bare piece with a tray under it.
const FRAMED := [[&"piece", Vector2i(1, 0)], [&"frame", Vector2i(1, 0), 0],
	[&"wall", Vector2i(1, 0), &"back"], [&"wall", Vector2i(1, 0), &"right"], [&"wall", Vector2i(1, 0), &"top"],
	[&"face", Vector2i(1, 0), &"left", &"fabric"],
	[&"stick", [Vector2i(1, 0), &"back"], &"top", Vector2(0.0, 0.15), 90.0, &"board"],
	[&"stick", [Vector2i(1, 0), &"back"], &"top", Vector2(0.28, -0.25), 0.0, &"compass"],
	[&"stick", [Vector2i(1, 0), &"right"], &"top", Vector2(-0.2, 0.1), 0.0, &"lamp"],
	[&"stick", [Vector2i(1, 0), &"top"], &"top", Vector2(-0.2, 0.0), 0.0, &"radio"],
	[&"stick", [Vector2i(1, 0), &"top"], &"top", Vector2(0.25, 0.1), 0.0, &"canister"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.0), 0.0, &"light_shield"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(-0.2, -0.2), 0.0, &"big_battery"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.2, 0.2), 0.0, &"light_panel"]]


## A rig set down at a place, squared to the world, floating or resting.
func _rig(steps: Array, at: Vector3, floating: bool) -> Chassis:
	var rig := Rig.build(null, steps)
	rig.deck.resting = not floating
	rig.deck.lift_share = 1.0 if floating else 0.0
	world.content.add_child(rig.deck)
	var up := rig.deck.rest_height() if floating else -Finds.bounds(rig.deck).position.y + 0.02
	rig.deck.global_transform = Transform3D(Basis.IDENTITY, Vector3(at.x, world.height_under(at) + up, at.z))
	return rig.deck


## Your eyes this far off a point, looking at it, until what you hold has settled where it would stick.
func _aim_at(point: Vector3, off: Vector3) -> void:
	_place(point + off, point, LENS)
	await _ticks(40)


func _look(eye: Vector3, target: Vector3) -> void:
	_place(eye, target, LENS)
	await _ticks(20)


func _shoot(out_dir: String, name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("chassis: %s%s" % [name, (", says " + hands.line()) if hands.line() != "" else ""])


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
