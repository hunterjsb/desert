extends Node
## Look-test: the power boxes on seed 1234, a clear late morning. Two decks
## resting on the sand: a colonial camp, the cabinet beside a Console and a
## shield with the company's dock among its panels, making more than it
## draws, so its bays charge; and a nomad raft, a skimmer's rack and a temple's
## shrine running a condenser and a lamp, so theirs supply. Bays in every
## state: full, half, low, nearly gone, empty, held to charge, dead. Shot whole,
## each box close, the Console's power page close and standing a step or two
## back, and the strips at dusk.
##   godot --path . --disable-vsync res://look/powerbox/powerbox.tscn -- --capture <dir>
## look/powerbox/shoot.sh builds the sheet. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
const LENS := 60.0
## Each box's bays, in order: [battery, charge], or empty.
const CABINET := [[&"big_battery", 1.0], [&"battery", 0.7], [&"battery", 0.42], [&"battery", 0.12], [],
	[&"battery", 0.55], [&"big_battery", 0.88], []]
const DOCK := [[&"battery", 0.9], [&"big_battery", 0.3], [], [&"battery", 0.6]]
const RACK := [[&"battery", 0.95], [&"big_battery", 0.6], [&"battery", 0.35], [], [&"battery", 0.8], [&"big_battery", 0.15],
	[&"battery", 0.5], [], [&"battery", 0.7], [&"big_battery", 0.25], [], [&"battery", 0.9]]
const SHRINE := [[&"battery", 0.8], [&"battery", 0.22], [&"big_battery", 0.5]]
## The camp's sun, as much as a bank of panels makes at noon, W.
const SUN_W := 150.0

## What the camp's panels make, steady, so its bays charge whatever the sky.
class Sun extends Device:
	func production_w(_t := NAN) -> float:
		return SUN_W

@onready var world: World = $World


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
	_capture(args[at + 1] if args.size() > at + 1 else "user://powerbox")


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
	var morning := Scenarios.find(world, {"key": "morning", "kind": "clear", "day": [0.36, 0.42]})
	if not morning.is_empty():
		world.respawn(morning.x, morning.z, morning.yaw, morning.time)
	await _ground()
	player.set_physics_process(false)
	player.flying = true
	player.collision_layer = 0
	player.collision_mask = 0
	var home := player.global_position
	var ahead := -player.global_basis.z
	ahead = Vector3(ahead.x, 0.0, ahead.z).normalized()
	var right := ahead.cross(Vector3.UP)
	var facing := atan2(ahead.x, ahead.z)

	var cabinet := _box(&"power_cabinet", CABINET)
	cabinet.hold(5, true)
	var dock := _box(&"power_box", DOCK)
	dock.hold(3, true)
	var console := Rig.make([&"console", [&"screen", &"anemometer", &"barometer"]]) as Console
	var sun := Sun.new()
	sun.label = "Solar array"
	sun.frame_stats = {"solar_w": SUN_W}
	var camp := Rig.build(null, [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(-1, 0)], [&"piece", Vector2i(0, 1)],
		[&"piece", Vector2i(1, 1)]])
	var deck := camp.deck
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.0, -0.18), 0.0, cabinet)
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2(-0.1, -0.15), 0.0, console)
	var shield := Catalog.device(&"shield") as ShieldGenerator
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 0)), Chassis.TOP, Vector2(0.32, 0.3), 0.0, shield)
	Stick.put(deck, Rig.piece(deck, Vector2i(-1, 0)), Chassis.TOP, Vector2(0.0, -0.2), 0.0, dock)
	Stick.put(deck, Rig.piece(deck, Vector2i(-1, 0)), Chassis.TOP, Vector2(0.0, 0.28), 0.0, Catalog.part(&"solar_panel"))
	Stick.put(deck, Rig.piece(deck, Vector2i(0, 1)), Chassis.TOP, Vector2(0.0, 0.25), 0.0, Catalog.part(&"solar_panel"))
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 1)), Chassis.TOP, Vector2(0.0, 0.25), 0.0, Catalog.part(&"solar_panel"))
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 1)), Chassis.TOP, Vector2(0.0, -0.25), 0.0, Catalog.part(&"solar_panel"))
	Stick.put(deck, Rig.piece(deck, Vector2i(1, 1)), Chassis.TOP, Vector2.ZERO, 0.0, sun)
	_set_down(deck, home + ahead * 4.2 - right * 1.4, facing)

	var rack := _box(&"power_rack", RACK)
	var shrine := _box(&"power_shrine", SHRINE)
	var raft := Rig.build(null, [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(2, 0)],
		[&"stick", Vector2i(2, 0), &"top", Vector2(0.0, 0.18), 0.0, [&"condenser", [&"canister"]], &"condenser"],
		[&"stick", Vector2i(2, 0), &"top", Vector2(0.3, -0.3), 0.0, &"lamp"],
		[&"stick", Vector2i(2, 0), &"top", Vector2(-0.3, -0.3), 0.0, &"big_battery"]], 0.6)
	var other := raft.deck
	Stick.put(other, other, Chassis.TOP, Vector2(0.0, -0.1), 0.0, rack)
	Stick.put(other, Rig.piece(other, Vector2i(1, 0)), Chassis.TOP, Vector2(0.0, -0.1), 0.0, shrine)
	(raft.named.condenser.parts()[0] as Supply).drain(INF)
	_set_down(other, home + ahead * 4.6 + right * 3.2, facing)
	shield.switch(true)
	console.page = Console.Page.POWER
	await _ticks(240)

	await _look(home + Vector3.UP * 2.0 - ahead * 1.2, home + ahead * 4.4 + Vector3.UP * 0.2 + right * 0.7)
	await _shoot(out_dir, "decks")
	await _close(out_dir, "cabinet", cabinet, 1.5, 0.15)
	await _close(out_dir, "dock", dock, 0.75, 0.6)
	await _close(out_dir, "rack", rack, 1.5, 0.15)
	await _close(out_dir, "shrine", shrine, 1.15, 0.2)
	var middle := console.global_transform * Vector3(0.0, 0.01, -0.33)
	var normal := _front(console)
	_place(middle + normal * 1.55, middle, 50.0)
	await _ticks(30)
	await _shoot(out_dir, "page")
	var at := middle + normal * 1.5
	_place(Vector3(at.x, world.height_under(at) + 1.65, at.z), middle, 75.0)
	await _ticks(20)
	await _shoot(out_dir, "standing")
	print("powerbox: the page reads\n%s" % console.screen_text())

	var dusk := Scenarios.find(world, {"key": "dusk", "kind": "clear", "day": [0.755, 0.77]})
	if not dusk.is_empty():
		world.time = dusk.time
		await _ticks(120)
		await _look(home + Vector3.UP * 1.8 - ahead * 0.8, home + ahead * 4.4 + Vector3.UP * 0.3 + right * 0.7)
		await _shoot(out_dir, "dusk")
	get_tree().quit()


## A box with its bays filled as the list says.
func _box(id: StringName, bays: Array) -> PowerBox:
	var made := Catalog.device(id) as PowerBox
	made.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	var all := made.bays()
	for i in bays.size():
		var bay: Array = bays[i]
		if bay.is_empty() or all[i].kind == PowerBox.DEAD:
			continue
		var cell := Catalog.part(bay[0]) as Battery
		cell.charge_wh = cell.capacity() * bay[1]
		made.fit(cell, all[i])
	return made


## A deck set down resting on the sand at a place, turned to face back at you.
func _set_down(deck: Chassis, at: Vector3, facing: float) -> void:
	deck.resting = true
	deck.lift_share = 0.0
	world.content.add_child(deck)
	var up := -Finds.bounds(deck).position.y + 0.02
	deck.global_transform = Transform3D(Basis(Vector3.UP, facing), Vector3(at.x, world.height_under(at) + up, at.z))


## A box close, from before its front, `off` m off and `up` m over its middle.
func _close(out_dir: String, name: String, box: Device, off: float, up: float) -> void:
	var middle := box.global_position
	await _look(middle + _front(box) * off + Vector3.UP * up, middle)
	await _shoot(out_dir, name)


## The way a device's front faces, flat.
func _front(device: Device) -> Vector3:
	var out := device.global_basis * Vector3.FORWARD
	return Vector3(out.x, 0.0, out.z).normalized()


func _look(eye: Vector3, target: Vector3) -> void:
	_place(eye, target, LENS)
	await _ticks(20)


func _shoot(out_dir: String, name: String) -> void:
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("powerbox: %s" % name)


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
