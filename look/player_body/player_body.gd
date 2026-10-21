extends Node
## Look-test: your body (Body, SurveyorLooks), through your own eyes and from
## outside, at a camp in the afternoon. Through your eyes: looking down
## standing, walking, holding a radio, crouched, sat and lying down; from
## outside: front, back and walking, a little way off.
##   scripts/unseen.sh --path . --resolution 1280x720 res://look/player_body/player_body.tscn -- <out dir> [filter]

var world: World
var player: Player
var out := ""
var only := ""
var outside: Camera3D


func _ready() -> void:
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://player_body"
	only = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	Tuning.current().run_seed = 1234
	Tuning.current().eye_adapts = false
	Tuning.current().prevailing_speed = 0.0
	Tuning.current().salvage = false
	Tuning.current().storm_threshold = 2.0
	world = preload("res://game/world/world.tscn").instantiate()
	add_child(world)
	for i in 2400:
		await get_tree().process_frame
		if world.terrain.is_idle():
			break
	world.time_warp = 0.0
	world.time = fposmod(0.42 - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) \
		* world.tuning.day_minutes * 60.0
	player = world.player
	player.set_process_unhandled_input(false)
	Dev.hide_overlays()
	outside = Camera3D.new()
	outside.fov = 40.0
	world.add_child(outside)
	for i in 40:
		await get_tree().physics_frame
	await _eyes("fp_down", -62.0)
	await _eyes("fp_ahead", -20.0)
	Input.action_press("move_forward")
	for i in 30:
		await get_tree().physics_frame
	await _eyes("fp_walk_down", -55.0)
	await _from("walk_side", Vector3(2.6, 1.2, 0.3), Vector3(0.0, 0.95, 0.0))
	Input.action_release("move_forward")
	for i in 30:
		await get_tree().physics_frame
	for id: StringName in [&"radio", &"cutter", &"chassis"]:
		var item := Catalog.device(id)
		world.content.add_child(item)
		item.global_position = player.global_position + Vector3(0.0, 1.0, -1.0)
		await get_tree().physics_frame
		player.hands.hold(item)
		for i in 40:
			await get_tree().physics_frame
		var suffix := "" if id == &"radio" else "_" + String(id)
		await _eyes("fp_holding" + suffix, -25.0)
		await _from("holding_front" + suffix, Vector3(-1.2, 1.5, -2.4), Vector3(0.0, 1.2, 0.0))
		player.hands.drop()
		item.queue_free()
	for i in 10:
		await get_tree().physics_frame
	await _from("front", Vector3(0.9, 1.4, -2.6), Vector3(0.0, 1.0, 0.0))
	await _from("back", Vector3(-1.4, 1.6, 2.4), Vector3(0.0, 1.0, 0.0))
	Input.action_press("crouch")
	for i in 30:
		await get_tree().physics_frame
	await _eyes("fp_crouch_down", -60.0)
	await _from("crouch_side", Vector3(2.4, 1.0, 0.4), Vector3(0.0, 0.7, 0.0))
	Input.action_release("crouch")
	for pose: StringName in [&"sit", &"prone"]:
		player.restore_ground_pose(pose)
		for i in 50:
			await get_tree().physics_frame
		await _eyes("fp_%s" % pose, -45.0 if pose == &"sit" else -20.0)
		await _from("%s_side" % pose, Vector3(2.4, 1.2, 0.6), Vector3(0.0, 0.4, 0.3))
	print("player body: done, %s" % out)
	get_tree().quit()


## Through your own eyes, looking `pitch` degrees.
func _eyes(name: String, pitch: float) -> void:
	if only != "" and not name.contains(only):
		return
	player.camera.rotation_degrees.x = pitch
	player.camera.make_current()
	await _save(name)


## From outside: the camera at `from`, looking at `at`, both in the player's frame.
func _from(name: String, from: Vector3, at: Vector3) -> void:
	if only != "" and not name.contains(only):
		return
	player.camera.rotation_degrees.x = -10.0
	outside.look_at_from_position(player.to_global(from), player.to_global(at), Vector3.UP)
	outside.make_current()
	await _save(name)
	player.camera.make_current()


func _save(name: String) -> void:
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("player body: ", name)
