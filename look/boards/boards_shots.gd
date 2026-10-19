extends Node
## Look-test: boards by make and the ride's feel, shot one by one into a
## folder for look/boards/shoot.sh to build a sheet from. On level sand on
## the fixed seed in a low morning sun: each make lying on the sand as found, close,
## and all four together; a skid with its spray; a hard landing, crossed,
## sliding out; and a pop off the flat at speed from the side as it rises,
## tops out, falls and lands. Each shot pauses the world, so what's shot is
## where it was. Needs a GPU, not --headless; scripts/unseen.sh gives it one:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/boards/boards_shots.tscn -- <out dir>

const WORLD_SCENE := preload("res://game/world/world.tscn")
const SHOT := Vector2i(960, 540)
const KEYS := ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "crouch"]
## The time of day it's shot at, a share of the day from midnight.
const MORNING := 0.36
## The pop's frames, s after it leaves the sand.
const STRIP := [0.2, 0.75, 1.3, 1.85]
## Each make as found: the era and kind of site it lay in, and the seed of its draw.
const FOUND := [[Eras.COLONIAL, &"hab_pod", 3], [Eras.SKIMMER, &"wreck_hull", 1], [Eras.SECOND, &"watchtower", 2],
	[Eras.SECOND, &"house_ruin", 4]]

var world: World
var player: Player
var camera: Camera3D
var level := Vector2.ZERO
var out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir().path_join("boards")
	DirAccess.make_dir_recursive_absolute(out)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.eye_adapts = false
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_threshold = 0.9
	world = WORLD_SCENE.instantiate()
	# Paused while it's shot; this look-test isn't.
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	world.time = fposmod(MORNING - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) \
		* tuning.day_minutes * 60.0
	player = world.player
	level = Scenarios.open_sand(world)
	camera = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	await _settled()

	# Each make on the sand as it's found, from the era its makers worked in,
	# its nose to your left, seen from above its tail.
	var laid: Array[Hoverboard] = []
	for i in BoardMakes.ALL.size():
		laid.append(_lay(BoardMakes.ALL[i], Vector3(0.0, 0.0, -1.5 + i * 1.0), FOUND[i]))
	await ticks(30)
	for i in laid.size():
		var at := laid[i].global_position
		await shoot("make_%d" % i, at + Vector3(1.25, 1.05, 0.3), at + Vector3(-0.2, -0.05, 0.0))
	await shoot("makes", laid[1].global_position + Vector3(3.2, 2.3, 1.5),
		laid[1].global_position.lerp(laid[2].global_position, 0.5) + Vector3(-0.2, -0.1, 0.0))
	for board in laid:
		board.free()

	# A skid: flat out, a hard carve right, seen from ahead on its outside.
	await _get_going(5.0)
	for i in 36:
		player.rotation.y -= 1.6 / 60.0
		await ticks(1)
	var pose := player.ride.board_pose(true)
	var way := Vector3(player.ride.velocity.x, 0.0, player.ride.velocity.y).normalized()
	var outside := way.cross(Vector3.UP)
	await shoot("skid", pose.origin + way * 5.0 - outside * 3.5 + Vector3.UP * 1.5, pose.origin + Vector3.UP * 0.2)

	# A hard landing, crossed: dropped from 12 m flat out, turned 25° as it
	# comes down, shot a moment after it meets the sand.
	await _get_going(4.0)
	_hold([])
	var ride := player.ride
	ride.y += 12.0
	ride.vy = 0.0
	var turned := false
	for i in 400:
		await ticks(1)
		if not turned and ride.vy < 0.0 and ride.gap < 0.6:
			ride.ahead = ride.ahead.rotated(deg_to_rad(25.0))
			turned = true
		if ride.touched > 0.0:
			break
	await ticks(6)
	pose = ride.board_pose(true)
	way = Vector3(ride.velocity.x, 0.0, ride.velocity.y).normalized()
	await shoot("landing", pose.origin + way * 4.5 + way.cross(Vector3.UP) * 3.0 + Vector3.UP * 1.2,
		pose.origin + Vector3.UP * 0.1)

	# A pop off the flat from a crouch, from its side, as it flies.
	await _get_going(5.0)
	_hold(["move_forward", "crouch"])
	await ticks(36)
	_hold(["move_forward", "jump"])
	ride = player.ride
	var flown := 0
	var next := 0
	while next < STRIP.size() and flown < 400:
		await ticks(1)
		if ride.gap > Ride.AIR_FROM or flown > 0:
			flown += 1
		if flown >= roundi(STRIP[next] * 60.0):
			pose = ride.board_pose(true)
			way = Vector3(ride.velocity.x, 0.0, ride.velocity.y).normalized()
			await shoot("pop_%d" % next, pose.origin - way.cross(Vector3.UP) * 2.6 - way * 0.4 + Vector3.UP * 0.25,
				pose.origin)
			next += 1
	get_tree().quit()


## A board of this make lying on the level sand with a battery in it, nose
## to -x, `off` from the place, found as `found` says.
func _lay(make: StringName, off: Vector3, found: Array) -> Hoverboard:
	var board := Catalog.device(make) as Hoverboard
	Catalog.found_in(board, found[0], found[1], found[2])
	world.content.add_child(board)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	board.fit(cell, board.sockets()[0])
	var at := Vector3(world.engine_x(level.x), 0.0, world.engine_z(level.y)) + off
	at.y = world.height_under(at) + 0.05
	board.global_transform = Transform3D(Basis(Vector3.UP, PI * 0.5), at)
	return board


func _settled() -> void:
	var at := Vector3(world.engine_x(level.x), 0.0, world.engine_z(level.y))
	at.y = world.height_under(at) + 0.1
	world.teleport(player, Transform3D(Basis.IDENTITY, at))
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			break


## Onto a fresh board on the level sand, flat out along the run's wind for
## `seconds`.
func _get_going(seconds: float) -> void:
	_hold([])
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	var down := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	var at := Vector3(world.engine_x(level.x), 0.0, world.engine_z(level.y)) - Vector3(down.x, 0.0, down.y) * 40.0
	at.y = world.height_under(at) + 0.1
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-down.x, -down.y)), at))
	player.velocity = Vector3.ZERO
	await ticks(10)
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


func _hold(actions: Array) -> void:
	for action: String in KEYS:
		if actions.has(action):
			Input.action_press(action)
		else:
			Input.action_release(action)


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## A shot into `name`.png, from `from` looking at `to`, the world paused.
func shoot(name: String, from: Vector3, to: Vector3) -> void:
	get_tree().paused = true
	camera.make_current()
	camera.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
	var ride := player.ride
	if ride != null:
		var off := absf(ride.velocity.angle_to(ride.ahead)) if ride.velocity.length() > 0.5 else 0.0
		print("%s: %.1f m/s, %.2f m up, pitch %.0f°, lean %.0f°, %.0f° off its way, %s" % [name, ride.velocity.length(),
			ride.gap, rad_to_deg(ride.pitch), rad_to_deg(ride.bank), rad_to_deg(minf(off, PI - off)),
			"skidding" if ride.skidding else ("loose %d%%" % roundi(ride.loose * 100.0))])
	else:
		print(name)
	for i in 3:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null:
		image = Image.create(SHOT.x, SHOT.y, false, Image.FORMAT_RGB8)
	image.resize(SHOT.x, SHOT.y, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	image.save_png(out.path_join(name + ".png"))
	get_tree().paused = false
