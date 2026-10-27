extends Node
## Look-test: the held tools and the food on seed 1234, clear and calm, laid
## on the sand as you'd drop them: each about a metre off at morning and at
## dusk, the food laid out together, a planter and a deep planter of ripe
## crops behind the packs they give, each tool in the five looks a
## lineage can give it (HeldLooks), and a ration beside the cell it must
## never be taken for.
##   godot --path . --disable-vsync res://look/held/held.tscn -- --capture <dir>
## look/held/shoot.sh shoots it and look/held/hold.tscn and builds the sheets.

const SEED := 1234
const TOOLS: Array[StringName] = [&"compass", &"cutter", &"sand_scoop", &"flare", &"sealant", &"med_kit"]
const FOOD: Array[StringName] = [&"ration", &"tubers", &"fungus_caps", &"salt", &"saltbush_leaves", &"coalcane_bundle"]
const MOMENTS := {"morning": 0.33, "dusk": 0.715}
## A close shot's eye, this far off its thing and this share of that up, m.
const CLOSE := 1.0
const UP_SHARE := 0.6
## Things lie this far apart along their row, m; the food's row is this far
## behind the tools', and the planters behind it.
const STEP := 0.9
const FOOD_ROW := 2.2
## The visual sand rides a little over the height asked of it, m.
const RIPPLE := 0.012
const LINES = preload("res://look/lineup/lineup.gd").LINES

@onready var world: World = $World
var _laid := {}


func _enter_tree() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = SEED
	tuning.eye_adapts = false
	tuning.salvage = false
	tuning.storm_threshold = 2.0
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--capture")
	if at != -1:
		_capture(args[at + 1] if args.size() > at + 1 else "user://held")


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
	world.respawn(world.spawn.x, world.spawn.y, 0.0, _time("morning"))
	world.time_warp = 0.0
	await _ground()
	player.set_physics_process(false)
	player.flying = true
	player.feel.set_process(false)
	var origin := player.global_position + Vector3(0.0, 0.0, -3.0)
	for i in TOOLS.size():
		_lay(TOOLS[i], origin + Vector3((i - 2.5) * STEP, 0.0, 0.0))
	for i in FOOD.size():
		_lay(FOOD[i], origin + Vector3((i - 2.5) * STEP * 0.4, 0.0, -FOOD_ROW))
	_planters(origin + Vector3(0.0, 0.0, -FOOD_ROW - 0.9))
	var beside := origin + Vector3(0.0, 0.0, 6.5)
	var pair: Array[RigidBody3D] = [_lay(&"ration", beside + Vector3(-0.16, 0.0, 0.0)), _lay(&"battery", beside + Vector3(0.16, 0.0, 0.0))]
	var eras := {}
	for j in HeldLooks.SHAPED.size():
		eras[HeldLooks.SHAPED[j]] = _eras(HeldLooks.SHAPED[j], origin + Vector3(0.0, 0.0, 1.6 + j * 0.9))
	await _ticks(30)
	for moment: String in MOMENTS:
		world.time = _time(moment)
		await _ticks(20)
		for id: StringName in TOOLS + FOOD:
			var box: AABB = _laid[id]
			var middle := box.get_center()
			var reach := box.size.length()
			var away := Vector3(0.35, UP_SHARE, 0.75).normalized() * maxf(CLOSE, reach * 1.1)
			_look(middle + away, middle, clampf(rad_to_deg(2.0 * atan(reach * 0.62 / away.length())), 14.0, 60.0))
			await _shot(out_dir, "%s_%s" % [id, moment])
		var food := origin + Vector3(0.0, 0.05, -FOOD_ROW)
		_look(food + Vector3(0.2, 0.9, 1.0), food, 50.0)
		await _shot(out_dir, "food_%s" % moment)
		_look(food + Vector3(0.4, 1.3, 1.6), food + Vector3(0.0, 0.15, -0.6), 50.0)
		await _shot(out_dir, "planter_%s" % moment)
		var pair_at := beside + Vector3(0.0, pair[0].global_position.y - beside.y, 0.0)
		_look(pair_at + Vector3(0.2, 0.5, 0.55), pair_at, 40.0)
		await _shot(out_dir, "ration_cell_%s" % moment)
		if moment != "morning":
			continue
		for id: StringName in eras:
			var row: AABB = eras[id]
			var middle := row.get_center()
			_look(middle + Vector3(0.1, 0.75, 0.65).normalized() * (row.size.x * 0.6 + 0.2), middle, 42.0)
			await _shot(out_dir, "eras_%s" % id)
	get_tree().quit()


## A thing on the sand at a place, as it'd lie dropped: a device upright, a
## part on its back, a long part on its side, in a lineage's look if given.
func _lay(id: StringName, at: Vector3, line := []) -> RigidBody3D:
	var body: RigidBody3D = Catalog.device(id) if Catalog.DEVICES.has(id) else Catalog.part(id)
	Catalog.inherit(body, line)
	world.content.add_child(body)
	body.freeze = true
	var size: Vector3 = (Catalog.DEVICES[id] if Catalog.DEVICES.has(id) else Catalog.PARTS[id]).size
	var lie := Basis(Vector3.UP, PI + 0.5)
	if Catalog.PARTS.has(id):
		lie = Basis(Vector3.UP, PI * 0.5 + 0.3) if size.z > 0.45 else lie * Basis(Vector3.RIGHT, -PI * 0.5)
	var box := Transform3D(lie, Vector3.ZERO) * Finds.bounds(body)
	var ground := world.height_under(at)
	body.global_transform = Transform3D(lie, Vector3(at.x, ground - box.position.y + RIPPLE, at.z))
	if not _laid.has(id):
		_laid[id] = Transform3D(Basis.IDENTITY, body.global_position) * box
	return body


## A tool in each lineage's look along a row from a place: the row's box.
func _eras(id: StringName, at: Vector3) -> AABB:
	var size: Vector3 = (Catalog.DEVICES[id] if Catalog.DEVICES.has(id) else Catalog.PARTS[id]).size
	var gap := maxf(size.x, size.z) + 0.12
	var row := AABB()
	for i in LINES.size():
		var body := _lay(id, at + Vector3((i - 2.0) * gap, 0.0, 0.0), LINES[i][1])
		var box := Transform3D(Basis.IDENTITY, body.global_position) * Transform3D(body.global_basis, Vector3.ZERO) * Finds.bounds(body)
		row = box if i == 0 else row.merge(box)
	return row


## A planter of ripe root-tuber, saltbush and fruited vat fungus, and a deep
## planter of ripe coalcane, watered.
func _planters(at: Vector3) -> void:
	var planter := Catalog.device(&"planter") as Planter
	var deep := Catalog.device(&"deep_planter") as Planter
	for each: Array in [[planter, at + Vector3(-0.5, 0.0, 0.0)], [deep, at + Vector3(0.9, 0.0, -0.1)]]:
		var device: Planter = each[0]
		var spot: Vector3 = each[1]
		world.content.add_child(device)
		device.global_position = Vector3(spot.x, world.height_under(spot) + Catalog.DEVICES[device.get_meta(&"catalog")].size.y * 0.5, spot.z)
		device.freeze = true
		device.tank_l = world.tuning.planter_tank_litres
	var crops := {&"plant_standard": [&"root_tuber", &"saltbush", &"root_tuber"], &"plant_pot": [&"vat_fungus"],
		&"plant_deep": [&"coalcane"]}
	for device: Planter in [planter, deep]:
		for socket in device.sockets():
			var kinds: Array = crops.get(socket.kind, [])
			if kinds.is_empty():
				continue
			var plant := Catalog.part(kinds.pop_front()) as Plant
			world.content.add_child(plant)
			device.fit(plant, socket)
			plant.set_growth(1.0)
			plant.fruit = 1.0


func _look(eye: Vector3, target: Vector3, fov: float) -> void:
	var player := world.player
	var to := target - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	player.camera.fov = fov


func _shot(out_dir: String, name: String) -> void:
	await _ticks(6)
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("held: %s" % name)


func _time(moment: String) -> float:
	return fposmod(MOMENTS[moment] - world.tuning.start_time_of_day, 1.0) * world.tuning.day_minutes * 60.0


func _ground() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while not world.terrain.is_idle():
		await get_tree().process_frame


func _ticks(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
