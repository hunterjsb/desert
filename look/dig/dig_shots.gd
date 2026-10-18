extends Node
## Look-test: the dig, shot six ways onto one sheet. On level sand on the
## fixed seed, flat out into a carve with the edge dug a third, two thirds
## and all the way in; a hockey stop from a cruise, from the side; the board
## leaning on its edge in a dug carve, from ahead; and the hockey stop through
## your own eyes. Needs a GPU, not --headless; scripts/unseen.sh gives it one
## with no window:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/dig/dig_shots.tscn -- sheet.png

const WORLD_SCENE := preload("res://game/world/world.tscn")
const SHOT := Vector2i(960, 540)
const KEYS := ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "crouch"]
## The time of day it's shot at, a share of the day from midnight.
const MORNING := 0.36

var world: World
var player: Player
var camera: Camera3D
var shots: Array[Image] = [null, null, null, null, null, null]
var level := Vector2.ZERO


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://dig.png"
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.eye_adapts = false
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	# Clear skies in a low morning sun, so the sand thrown shows against its shadow.
	tuning.storm_threshold = 0.9
	world = WORLD_SCENE.instantiate()
	add_child(world)
	world.time = fposmod(MORNING - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) \
		* tuning.day_minutes * 60.0
	player = world.player
	level = Scenarios.open_sand(world)
	camera = Camera3D.new()
	camera.fov = 55.0
	add_child(camera)
	for depth: int in 3:
		await _carve(0.34 + 0.33 * depth)
		var pose := player.ride.board_pose(true)
		var nose := -pose.basis.z
		var outward := Vector3(nose.z, 0.0, -nose.x)
		await shoot(depth, pose.origin - nose * 5.5 + outward * 3.0 + Vector3.UP * 1.6, pose.origin + nose * 1.5 + Vector3.UP * 0.4)
	await _stop()
	var pose := player.ride.board_pose(true)
	var way := Vector3(player.velocity.x, 0.0, player.velocity.z).normalized()
	await shoot(3, pose.origin - way * 2.0 + way.cross(Vector3.UP) * 6.0 + Vector3.UP * 1.4, pose.origin + way * 1.5 + Vector3.UP * 0.4)
	await _carve(1.0)
	pose = player.ride.board_pose(true)
	var ahead := -pose.basis.z
	await shoot(4, pose.origin + ahead * 3.2 + Vector3.UP * 0.35, pose.origin + Vector3.UP * 0.1)
	await _stop()
	player.camera.make_current()
	await shoot(5, Vector3.INF, Vector3.INF)
	var sheet := Image.create(SHOT.x * 3, SHOT.y * 2, false, Image.FORMAT_RGB8)
	for i in shots.size():
		sheet.blit_rect(shots[i], Rect2i(Vector2i.ZERO, SHOT), Vector2i((i % 3) * SHOT.x, (i / 3) * SHOT.y))
	sheet.save_png(out)
	get_tree().quit()


## Onto a fresh board on the level sand, flat out along the run's wind for
## `seconds`.
func _get_going(seconds: float) -> void:
	_hold([])
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	var down := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	var at := Vector3(world.engine_x(level.x), 0.0, world.engine_z(level.y))
	at.y = world.height_under(at) + 0.1
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-down.x, -down.y)), at))
	player.velocity = Vector3.ZERO
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			break
	var board := Catalog.device(&"board") as Hoverboard
	world.content.add_child(board)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	board.fit(cell, board.sockets()[0])
	board.global_transform = Transform3D(player.global_basis, player.global_position + Vector3.UP * 0.06)
	await ticks(2)
	player.get_on(board)
	await ticks(30)
	_hold(["move_forward"])
	await ticks(roundi(seconds * 60.0))


## Flat out, then a hard carve left with the edge dug `depth` in, a moment on.
func _carve(depth: float) -> void:
	await _get_going(5.0)
	_hold(["move_left"])
	Input.action_press("move_back", depth)
	await ticks(30)


## From a cruise, move back alone: the board across your way, its edge in.
func _stop() -> void:
	await _get_going(2.2)
	_hold(["move_back"])
	await ticks(22)


func _hold(actions: Array) -> void:
	for action: String in KEYS:
		if actions.has(action):
			Input.action_press(action)
		else:
			Input.action_release(action)


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Shot `n` of the sheet, from `from` looking at `to`, or through the camera
## that's current.
func shoot(n: int, from: Vector3, to: Vector3) -> void:
	# The storm pass is drawn about your own eyes; under clear skies it has
	# nothing to show, and from a chase camera it would black out round you.
	world.weather.face.visible = from == Vector3.INF
	if from != Vector3.INF:
		camera.make_current()
		camera.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
	print("shot %d: %.1f m/s, dug %d%%, leaning %.0f°, the board %.0f° off its way, the edge at %.2f m/s" % [n,
		player.ride.velocity.length(), roundi(player.ride.dig * 100.0), rad_to_deg(player.ride.bank),
		rad_to_deg(absf(player.ride.velocity.angle_to(player.ride.ahead))), player.ride.edge])
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	# Headless, there's no picture: the run still shows the sheet's moments come.
	if image == null:
		image = Image.create(SHOT.x, SHOT.y, false, Image.FORMAT_RGB8)
	image.resize(SHOT.x, SHOT.y, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	shots[n] = image
