extends Node
## Look-test: wind on faces on seed 1234, a clear morning, the wind ours to set.
## A camp resting in a gale behind its windbreak, two walls broadside to it,
## fabric beside them drawn taut and bellied in, an awning over them and the
## camp moored upwind; the same camp from its lee; fabric slack in a breeze,
## fluttering; and a scoop open into a fresh wind, its fabric back filled.
##   godot --path . --disable-vsync res://look/faces/faces.tscn -- --capture <dir>
## look/faces/shoot.sh builds the sheet. A small window that never takes
## focus, nothing but this script moving anything, and silence.

const SEED := 1234
const LENS := 60.0
const GALE := 20.0
const BREEZE := 2.5
const FRESH := 11.0
## The wind blows along world +Z, so a face looking out along -Z meets it.
const DOWN := Vector2(0.0, 1.0)

@onready var world: World = $World
var wind: RopeWind


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	tuning.storm_threshold = 2.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at == -1:
		return
	_capture(args[at + 1] if args.size() > at + 1 else "user://faces")


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
	world.set_process_unhandled_input(false)
	Dev.hide_overlays()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _ground()
	var morning := Scenarios.find(world, {"key": "morning", "kind": "clear", "day": [0.3, 0.34]})
	if not morning.is_empty():
		world.respawn(morning.x, morning.z, morning.yaw, morning.time)
	await _ground()
	wind = RopeWind.new(world.run_seed, world.tuning)
	world.weather.field = wind
	_blow(0.0, 0.0)
	player.set_physics_process(false)
	player.flying = true
	player.collision_layer = 0
	player.collision_mask = 0
	var home := player.global_position

	# The camp: three pieces across the wind and three behind, frames along
	# its windward row, walls on two and fabric on the third, an awning over.
	var camp := Rig.build(null, CAMP).deck
	var face := _windward(camp, Vector2i(0, 0))
	camp.join(Catalog.device(&"chassis") as Chassis, Rig.face_of(camp, Vector2i(0, 0), face))
	camp.join(Catalog.device(&"chassis") as Chassis, Rig.face_of(camp, Vector2i(1, 0), face))
	camp.fit(Catalog.part(&"fabric"), Rig.face_of(camp, Vector2i(2, 0), face))
	camp.fit(Catalog.part(&"fabric"), Rig.face_of(camp, Vector2i(1, 0), &"top"))
	_set_down(camp, home + Vector3(-1.0, 0.0, 4.0))
	var stake := Catalog.stake()
	world.content.add_child(stake)
	var upwind := camp.global_transform * Vector3(1.0, 0.0, -4.5)
	stake.drive(upwind, world.height_under(upwind))
	Line.between(world, camp.free_tie(upwind), stake.free_tie(camp.global_position), 0.2)
	_blow(GALE, 0.3)
	await _ticks(150)
	var cloth := camp.global_transform * Vector3(2.0, 0.6, -0.5)
	await _look(cloth + Vector3(1.9, 1.1, -2.6), cloth + Vector3(-0.9, -0.1, 0.3))
	await _shoot(out_dir, "camp", camp)
	await _look(cloth + Vector3(1.5, 1.2, 2.9), cloth + Vector3(-0.7, -0.1, 0.0))
	await _shoot(out_dir, "lee", camp)

	# Slack in a breeze: fabric on a frame's windward face and one side.
	var slack := Rig.build(null, [[&"frame", Vector2i.ZERO, 0]]).deck
	var front := _windward(slack, Vector2i.ZERO)
	slack.fit(Catalog.part(&"fabric"), Rig.face_of(slack, Vector2i.ZERO, front))
	slack.fit(Catalog.part(&"fabric"), Rig.face_of(slack, Vector2i.ZERO, _beside(slack, front)))
	_set_down(slack, home + Vector3(8.0, 0.0, 2.0))
	_blow(BREEZE, 0.4)
	await _ticks(120)
	var near := slack.global_transform * Vector3(0.0, 0.6, 0.0)
	await _look(near + Vector3(-1.5, 0.6, -1.7), near)
	await _shoot(out_dir, "breeze", slack)

	# A scoop: walled both sides and over, fabric across its back, open into the wind.
	var scoop := Rig.build(null, [[&"piece", Vector2i(0, 1)], [&"frame", Vector2i.ZERO, 0],
		[&"stick", Vector2i(0, 1), &"top", Vector2(0.0, 0.0), 0.0, &"big_battery"]]).deck
	var open := _windward(scoop, Vector2i.ZERO)
	var side := _beside(scoop, open)
	for name: StringName in [side, Faces.OPPOSITE[side], &"top"]:
		scoop.join(Catalog.device(&"chassis") as Chassis, Rig.face_of(scoop, Vector2i.ZERO, name))
	scoop.fit(Catalog.part(&"fabric"), Rig.face_of(scoop, Vector2i.ZERO, Faces.OPPOSITE[open]))
	_set_down(scoop, home + Vector3(-9.0, 0.0, 2.0))
	_blow(FRESH, 0.2)
	await _ticks(120)
	var cup := scoop.global_transform * Vector3(0.0, 0.6, 0.5)
	await _look(cup + Vector3(1.4, 0.7, 1.7), cup)
	await _shoot(out_dir, "scoop", scoop)
	get_tree().quit()


## The camp: three pieces across the wind and three behind; a frame on each
## of the windward row; behind, the shield, batteries, a panel and the
## bedroll; a hook on the windward ring of the middle piece to moor it.
const CAMP := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(2, 0)],
	[&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)], [&"piece", Vector2i(2, 1)],
	[&"frame", Vector2i(0, 0), 0], [&"frame", Vector2i(1, 0), 0], [&"frame", Vector2i(2, 0), 0],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.0, 0.0), 0.0, &"big_battery"],
	[&"stick", Vector2i(1, 0), &"top", Vector2(0.0, 0.0), 0.0, &"light_shield"],
	[&"stick", Vector2i(0, 1), &"top", Vector2(0.0, 0.0), 0.0, &"bedroll"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(-0.25, 0.0), 0.0, &"big_battery"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(0.15, 0.0), 0.0, &"battery"],
	[&"stick", Vector2i(2, 1), &"top", Vector2(0.0, 0.0), 0.0, &"light_panel"],
	[&"hook", Vector2i(1, 0), Vector2i(0, -1)]]


## The face of the frame on a piece that looks out into the wind, the deck square to the world.
func _windward(deck: Chassis, cell: Vector2i) -> StringName:
	var best := &""
	var most := -INF
	for name: StringName in Faces.OPPOSITE:
		var out := Rig.face_of(deck, cell, name).transform.basis.z
		if -out.dot(Vector3(DOWN.x, 0.0, DOWN.y)) > most:
			most = -out.dot(Vector3(DOWN.x, 0.0, DOWN.y))
			best = name
	return best


## A side of a frame beside a face, square to it.
func _beside(deck: Chassis, face: StringName) -> StringName:
	return Faces.ROUND[face][0]


## A rig set down resting on the sand at a place, square to the world.
func _set_down(deck: Chassis, at: Vector3) -> void:
	deck.resting = true
	deck.lift_share = 0.0
	world.content.add_child(deck)
	var up := -Finds.bounds(deck).position.y + 0.02
	deck.global_transform = Transform3D(Basis.IDENTITY, Vector3(at.x, world.height_under(at) + up, at.z))


func _blow(speed: float, gusts: float) -> void:
	wind.override = wind.steady(DOWN, speed, gusts) if speed > 0.0 \
		else func(_x: float, _z: float, _t: float) -> Vector2: return Vector2.ZERO


func _look(eye: Vector3, target: Vector3) -> void:
	var player := world.player
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	player.feel.set_process(false)
	player.camera.fov = LENS
	await _ticks(20)


func _shoot(out_dir: String, name: String, deck: Chassis) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	var loads := []
	for i in deck.faces.count():
		if deck.faces.look_of(i) != Vector2.ZERO:
			loads.append("%.2f" % deck.faces.look_of(i).x)
	print("faces: %s, %d faces, fabric loads %s, tilted %.1f°" % [name, deck.faces.count(), ", ".join(loads),
		rad_to_deg(deck.global_basis.y.angle_to(Vector3.UP))])


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
