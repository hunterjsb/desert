extends Node
## Look-test: the bedroll laid out on seed 1234's open sand in clear morning
## light, shot four ways from beside it: rolled in your hands' place on the
## sand, unrolling, flat, and taken, rolling back up where it lay. Each is
## held at its moment, the look stepped to it, so the strip compares across
## builds. Needs a GPU, not --headless; scripts/unseen.sh gives it one with no
## window (look/bedroll/shoot.sh builds the strip):
##   scripts/unseen.sh --path . --resolution 1280x720 res://look/bedroll/bedroll.tscn -- <dir>

const WORLD_SCENE := preload("res://game/world/world.tscn")
const SHOTS := [["rolled", 0.0], ["unrolling", 0.45], ["flat", 1.0], ["taken, rolling up", 0.5]]
## You stand this far off its middle, to its side and back toward its head,
## and this high, m.
const SIDE := 1.4
const BACK := 0.3
const UP := 1.1


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://bedroll"
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	var tuning := Tuning.current()
	tuning.run_seed = 1234
	tuning.eye_adapts = false
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	var world: World = WORLD_SCENE.instantiate()
	add_child(world)
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle():
			break
	var player := world.player
	player.set_physics_process(false)
	var field := world.weather.field
	var x := world.player_world_x()
	var z := world.player_world_z()
	var t := 0.0
	while field.storm_at(x, z, t) > 0.0 or absf(world.weather.day.time_of_day(t, world.moon.longitude) - 0.38) > 0.02:
		t += 10.0
	world.time = t
	world.time_warp = 0.0
	player.rotation.y = 0.0
	player.camera.rotation = Vector3(-0.9, 0.0, 0.0)
	var bedroll := Catalog.device(&"bedroll") as Bedroll
	world.content.add_child(bedroll)
	bedroll.global_position = player.camera.global_position + Vector3(0.0, -0.3, -0.5)
	player.hands.hold(bedroll)
	await ticks(30)
	player.hands.interact()
	bedroll.set_process(false)
	await ticks(60)
	var head := bedroll.global_transform
	var middle := head * Vector3(Dress.BEDROLL_LENGTH * 0.5 - 0.12, 0.0, 0.0)
	var eye := middle + head.basis.z * SIDE - head.basis.x * BACK + Vector3.UP * UP
	print("bedroll: laid %s, %.1f m off your feet, at %02d:%02d" % [bedroll.laid,
		bedroll.global_position.distance_to(player.global_position),
		floori(world.weather.day.time_of_day(t, world.moon.longitude) * 24.0),
		floori(fmod(world.weather.day.time_of_day(t, world.moon.longitude) * 1440.0, 60.0))])
	for shot: Array in SHOTS:
		if shot[0].begins_with("taken"):
			_face(player, head.origin + Vector3.UP * 0.5, head.origin)
			await ticks(2)
			player.hands.grab()
			bedroll.set_process(true)
			await get_tree().process_frame
			await get_tree().process_frame
			bedroll.set_process(false)
		bedroll._open = shot[1]
		bedroll._show()
		_face(player, eye, middle)
		await ticks(10)
		var image := get_viewport().get_texture().get_image()
		image.convert(Image.FORMAT_RGB8)
		image.save_png(out.path_join("%s.png" % shot[0].get_slice(",", 0)))
		print("bedroll: %s at %.2f" % [shot[0], bedroll.opened()])
	get_tree().quit()


## Your eyes at `eye`, looking at `target`, engine metres.
func _face(player: Player, eye: Vector3, target: Vector3) -> void:
	var to := target - eye
	player.global_position = eye - player.camera.position
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
