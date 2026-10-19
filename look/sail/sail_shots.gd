extends Node
## Look-test: sailing, shot six ways onto one sheet. The "sail" scenario on
## the fixed seed: the rig standing on its deck, a reach in a fresh wind
## heeling it, you towed on the board behind it, and its sail furled; then
## "sail_tow", the rig towing the camp past you on the board, and "yacht",
## sailed from its helm across the wind. Needs a GPU, not --headless;
## scripts/unseen.sh gives it one with no window:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/sail/sail_shots.tscn -- sheet.png

const WORLD_SCENE := preload("res://game/world/world.tscn")
const SHOT := Vector2i(960, 540)

var world: World
var camera: Camera3D
## The sheet's six, in its order: the rig, a reach heeling, towed, furled,
## the camp in tow, the yacht.
var shots: Array[Image] = [null, null, null, null, null, null]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://sailing.png"
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	Tuning.current().run_seed = 1234
	Tuning.current().eye_adapts = false
	world = WORLD_SCENE.instantiate()
	add_child(world)
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle():
			break
	Scenarios.apply(world, Scenarios.by_key("sail"))
	for i in 1800:
		await get_tree().physics_frame
		if world.has_meta(&"scenario_kit"):
			break
	var kit: Array = world.get_meta(&"scenario_kit")
	var deck: Chassis = kit[0]
	var mast: Mast = kit[1]
	var board: Hoverboard = kit[4]
	var player := world.player
	camera = Camera3D.new()
	camera.fov = 60.0
	add_child(camera)
	camera.make_current()
	# The rig as it stands, sail up, held by you on its sheet.
	var wind := world.weather.field_wind(deck.global_position).normalized()
	var ahead := -deck.global_basis.z
	player.set_physics_process(false)
	mast.raised = true
	await ticks(150)
	await shoot(0, deck.global_position - wind * 7.0 + ahead * 5.0 + Vector3.UP * 3.5, deck.global_position + Vector3.UP * 1.5)
	# On the board, towed across the wind, the sheet reeled in as it picks up speed.
	player.set_physics_process(true)
	player.get_on(board)
	await ticks(60 * 6)
	mast.trim = 2.0 * Mast.BOOM * sin(deg_to_rad(50.0) * 0.5)
	await ticks(60 * 8)
	await shoot(2, player.global_position - ahead * 4.0 - wind * 1.5 + Vector3.UP * 2.2, deck.global_position + Vector3.UP * 1.2)
	# A fresh gust: it heels.
	var gust := RopeWind.new(world.run_seed, world.tuning)
	var blowing := world.weather.field_wind(deck.global_position)
	gust.override = func(_x: float, _z: float, _t: float) -> Vector2: return Vector2(blowing.x, blowing.z) * 1.5
	world.weather.field = gust
	for i in 240:
		await ticks(1)
		if absf(rad_to_deg(asin(deck.global_basis.x.y))) > 4.0:
			break
	ahead = -deck.global_basis.z
	await shoot(1, deck.global_position + ahead * 7.0 + wind * 4.5 + Vector3.UP * 1.6, deck.global_position + Vector3.UP * 1.4)
	# Furled.
	mast.raised = false
	world.weather.field = WeatherField.new(world.run_seed, world.tuning)
	player.step_off()
	await ticks(60 * 6)
	await shoot(3, deck.global_position - wind * 6.0 - ahead * 4.0 + Vector3.UP * 3.0, deck.global_position + Vector3.UP * 1.0)
	await _in_tow(player)
	await _the_yacht(player)
	var sheet := Image.create(SHOT.x * 3, SHOT.y * 2, false, Image.FORMAT_RGB8)
	for i in shots.size():
		sheet.blit_rect(shots[i], Rect2i(Vector2i.ZERO, SHOT), Vector2i((i % 3) * SHOT.x, (i / 3) * SHOT.y))
	sheet.save_png(out)
	get_tree().quit()


## The rig towing the camp past you on the board, borne off to a broad reach
## and held there as you'd steer it, seen from to windward.
func _in_tow(player: Player) -> void:
	var kit := await _scenario("sail_tow")
	var rig: Chassis = kit[0]
	var mast: Mast = kit[1]
	mast.raised = true
	player.get_on(kit[6])
	var wind := world.weather.field_wind(rig.global_position).normalized()
	var flat := Vector3(wind.x, 0.0, wind.z).normalized()
	# Borne away 30° from across the wind, on the tack it stands on.
	var reach := flat.rotated(Vector3.UP, deg_to_rad(60.0))
	if reach.dot(-rig.global_basis.z) < flat.rotated(Vector3.UP, deg_to_rad(-60.0)).dot(-rig.global_basis.z):
		reach = flat.rotated(Vector3.UP, deg_to_rad(-60.0))
	for i in 60 * 14:
		await ticks(1)
		_hold(rig, reach, 300.0)
		var ahead := -rig.global_basis.z
		player.rotation.y = atan2(-ahead.x, -ahead.z)
	var middle := (rig.global_position + (kit[3] as Node3D).global_position) * 0.5
	var ahead := -rig.global_basis.z
	await shoot(4, middle - wind * 11.0 + ahead * 2.0 + Vector3.UP * 4.0, middle + Vector3.UP * 0.8)
	player.step_off()


## The yacht sailed from its helm across the wind, seen off its bow.
func _the_yacht(player: Player) -> void:
	var kit := await _scenario("yacht")
	var deck: Chassis = kit[0]
	var mast: Mast = kit[1]
	mast.raised = true
	(kit[2] as Helm).interact(player)
	var wind := world.weather.field_wind(deck.global_position).normalized()
	var across := -deck.global_basis.z
	mast.trim = 2.0 * Mast.BOOM * sin(deg_to_rad(40.0) * 0.5)
	for i in 60 * 10:
		await ticks(1)
		var ahead := -deck.global_basis.z
		var off := Vector2(ahead.x, ahead.z).angle_to(Vector2(across.x, across.z))
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(off) > 0.01:
			Input.action_press("move_left" if off < 0.0 else "move_right", clampf(absf(off) * 8.0, 0.0, 1.0))
	Input.action_release("move_left")
	Input.action_release("move_right")
	# Looking up at the sail, so nothing near names itself in the shot.
	player.camera.rotation.x = 1.3
	var ahead := -deck.global_basis.z
	var middle := deck.global_transform * deck.center_of_mass
	await shoot(5, middle + ahead * 3.5 + wind * 5.5 + Vector3.UP * 1.4, middle + Vector3.UP * 0.9)
	player.camera.rotation.x = 0.0
	player.stand_up()


## A scenario applied here and now, once its things are down: what it dropped.
func _scenario(key: String) -> Array:
	var was = world.get_meta(&"scenario_kit")
	for body in world.player.waist.tied.duplicate():
		world.player.waist.untie(body)
	Scenarios.apply(world, Scenarios.by_key(key))
	for i in 1800:
		await get_tree().physics_frame
		if world.get_meta(&"scenario_kit") != was:
			break
	await ticks(30)
	return world.get_meta(&"scenario_kit")


## A turn toward a heading no harder than a helm could give, N·m, as you'd
## steer by its lines.
func _hold(body: RigidBody3D, toward: Vector3, most: float) -> void:
	var ahead := -body.global_basis.z
	var off := Vector2(ahead.x, ahead.z).angle_to(Vector2(toward.x, toward.z))
	body.apply_torque(Vector3.UP * clampf(-off * 600.0 - body.angular_velocity.y * 200.0, -most, most))


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Shot `n` of the sheet, from `from` looking at `to`, a few frames settled.
func shoot(n: int, from: Vector3, to: Vector3) -> void:
	camera.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
	for i in 4:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	print("shot %d: rolled %.1f°, camp at %.2f m/s" % [n, rad_to_deg(asin(absf(world.get_meta(&"scenario_kit")[0].global_basis.x.y))),
		world.get_meta(&"scenario_kit")[0].linear_velocity.length()])
	# Headless, there's no picture: the run still shows the sheet's moments come.
	if image == null:
		image = Image.create(SHOT.x, SHOT.y, false, Image.FORMAT_RGB8)
	image.resize(SHOT.x, SHOT.y, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	shots[n] = image
