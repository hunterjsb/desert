extends Node
## Look-test: a skid's gouge beside a carve's line, and a wipeout's tumble,
## shot one by one into a folder for look/tumble/shoot.sh to build a strip
## from. On level sand on the fixed seed in a low morning sun: flat out along
## the wind, a carve the hover holds and, beside it, one turned hard enough
## to skid, seen from above and from low beside the gouge; then an edge
## caught flat out, your view through the tumble from the throw till you're
## up, and from behind as you hit and once you're at rest, the board tumbled
## away. Each shot pauses the world, so what's shot is where it was. Needs a
## GPU, not --headless; scripts/unseen.sh gives it one:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/tumble/tumble_shots.tscn -- <out dir>

const WORLD_SCENE := preload("res://game/world/world.tscn")
const SHOT := Vector2i(960, 540)
const KEYS := ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "crouch"]
## The time of day it's shot at, a share of the day from midnight.
const MORNING := 0.36
## Turning your view this fast, rad/s, for this long, s: a carve that grips
## and one that skids, the skid this far inside the carve, m.
const GENTLE := 0.4
const HARD := 1.6
const TURNING := 2.0
const INSIDE := 4.0
## The tumble's frames through your eyes, ticks after the throw, and from
## behind.
const FRAMES := [4, 14, 22, 34, 48, 66, 100, 150]
const BEHIND := [22, 100]

var world: World
var player: Player
var camera: Camera3D
var level := Vector2.ZERO
var down := Vector2.ZERO
var out := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else OS.get_user_data_dir().path_join("tumble")
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
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	world.time = fposmod(MORNING - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) \
		* tuning.day_minutes * 60.0
	player = world.player
	level = Scenarios.open_sand(world)
	down = Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	camera = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)

	# The carve, then the skid inside it, turning left from the same place.
	var turned := await _turn(0.0, GENTLE)
	var skid := await _turn(INSIDE, HARD)
	var left := Vector3(down.orthogonal().x, 0.0, down.orthogonal().y)
	var ahead := Vector3(down.x, 0.0, down.y)
	var middle := turned.lerp(skid, 0.5) + ahead * 10.0
	await shoot("gouge_above", middle - ahead * 9.0 - left * 4.0 + Vector3.UP * 11.0, middle + ahead * 3.0)
	var gouge := skid + ahead * 8.0 + left * 3.0
	await shoot("gouge_beside", gouge - left * 9.0 - ahead * 5.0 + Vector3.UP * 1.6, gouge + ahead * 2.0)
	print("tracks: %.2f ms a tick at worst" % world.terrain.tracks.slowest_tick_ms)

	# An edge caught flat out, on fresh sand.
	await _get_going(-INSIDE * 3.0, 6.0)
	_hold(["move_back"])
	for i in 240:
		await ticks(1)
		if player.tumble != null:
			break
	_hold([])
	var tumble := player.tumble
	var t := 0
	for at: int in FRAMES:
		await ticks(at - t)
		t = at
		if at in BEHIND:
			var way := Vector3(tumble.velocity.x, 0.0, tumble.velocity.y)
			var back := -ahead if way.length() < 0.5 else -way.normalized()
			var p := player.global_position
			await shoot("behind_%d" % at, p + back * 6.0 + left * 2.5 + Vector3.UP * 2.6, p + Vector3.UP * 0.3)
		await shoot("eyes_%d" % at, Vector3.INF, Vector3.INF)
	get_tree().quit()


## Flat out along the wind `side` m left of the level place, then your view
## turning left at `rate` with move forward held: where the turn began.
func _turn(side: float, rate: float) -> Vector3:
	await _get_going(side, 4.0)
	var began := player.global_position
	for i in roundi(TURNING * 60.0):
		player.rotation.y += rate / 60.0
		await ticks(1)
	_hold([])
	return began


## Onto a fresh board `side` m left of the level place and 60 m up the wind
## of it, flat out along the wind for `seconds`.
func _get_going(side: float, seconds: float) -> void:
	_hold([])
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	var start := level - down * 60.0 + down.orthogonal() * side
	var at := Vector3(world.engine_x(start.x), 0.0, world.engine_z(start.y))
	at.y = world.height_under(at) + 0.1
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-down.x, -down.y)), at))
	player.velocity = Vector3.ZERO
	player.camera.rotation.x = -0.15
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			break
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


## A shot into `name`.png, from `from` looking at `to`, or through your own
## eyes, the world paused.
func shoot(name: String, from: Vector3, to: Vector3) -> void:
	get_tree().paused = true
	# Your view drawn from the tick it's paused on: the weather's tick would
	# otherwise have the last word on its roll.
	player.feel.process_mode = Node.PROCESS_MODE_ALWAYS
	if from == Vector3.INF:
		player.camera.make_current()
	else:
		camera.make_current()
		camera.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
	await get_tree().process_frame
	await get_tree().process_frame
	var tumble := player.tumble
	if tumble != null:
		var view := player.camera.rotation
		print("%s: %.2f s in, %.1f m/s, %.2f m up, rolled %.0f°, over %d%%, up %d%%, %d hits; the view rolled %.0f° and pitched %.0f°, eyes %.2f m over the sand"
			% [name, tumble.age, tumble.velocity.length(), tumble.lift, rad_to_deg(tumble.rolled),
				roundi(tumble.over * 100.0), roundi(tumble.rising * 100.0), tumble.hits, rad_to_deg(view.z),
				rad_to_deg(view.x), player.camera.global_position.y - world.height_under(player.camera.global_position)])
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
	player.feel.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
