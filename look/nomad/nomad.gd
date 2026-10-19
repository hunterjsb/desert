extends Node
## Look-test: the nomads' gear. A wrecked nomad rig and a nomads' camp, laid
## by hand on open sand dug out; a wind streamer in your hand in a breeze,
## and streamers on a rig with its sail up, telltales; the crow's nest on its
## mast and the view from it; and the Varran rig on each tack, the same lines
## on it. Needs a GPU, not --headless; scripts/unseen.sh gives it one:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/nomad/nomad.tscn -- <out dir>

const WORLD_SCENE := preload("res://game/world/world.tscn")
const BREEZE := {"key": "look_nomad", "kind": "sail", "day": [0.35, 0.45], "breeze": [8.5, 11.5]}
const MASTED := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)],
	[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"skates"],
	[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"skates"],
	[&"stick", Vector2i(0, 1), &"bottom", Vector2.ZERO, 0.0, &"skates"],
	[&"stick", Vector2i(1, 1), &"bottom", Vector2.ZERO, 0.0, &"skates"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.4, -0.4), 180.0, [&"mast", [&"sail"]], &"mast"],
	[&"up", &"mast", &"front", Vector2(0.0, 1.2), 0.0, &"streamer"],
	[&"up", &"mast", &"head", Vector2.ZERO, 0.0, &"crows_nest", &"nest"],
	[&"stick", Vector2i(1, 1), &"top", Vector2(0.3, 0.3), 0.0, &"streamer"],
	[&"frame", Vector2i(0, 1), 0],
	[&"stick", Vector2i(0, 1), &"top", Vector2(-0.25, 0.0), 0.0, &"big_battery"]]

var world: World
var camera: Camera3D
var out := ""
var lines: Array[Line] = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://nomad"
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	Tuning.current().run_seed = 1234
	Tuning.current().eye_adapts = false
	Tuning.current().salvage = true
	world = WORLD_SCENE.instantiate()
	add_child(world)
	await _ground()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	world.player.set_process_unhandled_input(false)
	camera = Camera3D.new()
	camera.fov = 60.0
	add_child(camera)
	camera.make_current()
	Scenarios.stand(world, BREEZE, Scenarios.find(world, BREEZE))
	await _ground()
	await _site(&"nomad_rig", "rig", 1.3)
	await _site(&"nomad_camp", "camp", 2.4)
	await _streamers()
	await _nest()
	for windward: int in [1, -1]:
		await _tack(windward)
	get_tree().quit()


## A site of a kind laid by hand on the sand ahead, dug out, shot from its way in.
func _site(kind: StringName, shot: String, back: float) -> void:
	var sites := world.shape.sites
	var from := Vector2(world.player_world_x(), world.player_world_z()) + _down() * 40.0
	var site: Structure = null
	for tries in 150:
		var off := Vector2.from_angle(tries * 2.39996) * 7.0 * sqrt(tries)
		site = sites.by_hand(kind, from.x + off.x, from.y + off.y, 0.9, 0.0)
		if site.stands():
			break
	if not site.stands():
		print("nomad: the dunes took every %s tried" % kind)
		return
	sites.add(site)
	var approach := site.to_world(site.piece.approach * back * 0.5)
	world.teleport(world.player, Transform3D(Basis.IDENTITY, Vector3(world.engine_x(approach.x),
		world.height_at(approach.x, approach.y) + 0.1, world.engine_z(approach.y))))
	await _ground()
	for i in 240:
		await ticks(1)
		if world.salvage.is_idle():
			break
	var middle := Vector3(world.engine_x(site.x), site.floor_y + 0.8, world.engine_z(site.z))
	var eye := Vector3(world.engine_x(approach.x), world.height_at(approach.x, approach.y) + 2.4 + back, world.engine_z(approach.y))
	await shoot(shot, eye, middle)


## A streamer in your hand in the breeze, seen as you hold it up; and a rig
## with its sail up, a streamer up its mast and one on its deck.
func _streamers() -> void:
	var player := world.player
	var streamer := Catalog.device(&"streamer")
	world.content.add_child(streamer)
	streamer.global_position = player.camera.global_position - player.camera.global_basis.z * 0.6
	player.hands.hold(streamer)
	var across := _down().orthogonal()
	player.rotation.y = atan2(-across.x, -across.y)
	await ticks(90)
	var view := player.camera.global_transform
	await shoot("hand", view.origin + view.basis.z * 0.25 + Vector3.UP * 0.05, streamer.global_position)
	player.hands.drop()
	await ticks(10)
	streamer.free()
	var rig := _rig()
	var mast: Mast = rig.named.mast
	mast.raised = true
	mast.raise = 1.0
	mast.trim = 2.0 * Mast.BOOM * sin(deg_to_rad(35.0))
	await ticks(120)
	var middle := rig.deck.global_transform * rig.deck.center_of_mass
	var down := Vector3(_down().x, 0.0, _down().y)
	await shoot("telltale", middle - down * 5.0 + rig.deck.global_basis.x * 3.0 + Vector3.UP * 2.5, middle + Vector3.UP * 2.2)
	await _clear()


## The crow's nest on its mast, and the view from it: sat in it, looking
## out over the dunes downwind.
func _nest() -> void:
	var rig := _rig()
	await ticks(60)
	var nest: CrowsNest = rig.named.nest
	var player := world.player
	var middle := rig.deck.global_transform * rig.deck.center_of_mass
	await shoot("nest", middle + rig.deck.global_basis.x * 6.0 - rig.deck.global_basis.z * 3.0 + Vector3.UP * 2.0,
		middle + Vector3.UP * 3.0)
	player.sit(nest)
	await ticks(30)
	var down := Vector3(_down().x, 0.0, _down().y)
	var eye := player.camera.global_position
	await shoot("view", eye, eye + down * 100.0 - Vector3.UP * 6.0)
	print("nomad: from the crow's nest your eyes are %.1f m over the sand" % (eye.y - world.height_under(eye)))
	player.stand_up()
	await _clear()


## The Varran rig sailing across the breeze with the wind on your `windward`
## side, its lines as his kit lays them.
func _tack(windward: int) -> void:
	var player := world.player
	var down := _down()
	var way := down.orthogonal() * windward
	var kit := Kit.named(&"varran")
	var built := Rig.build(world.content, kit.assembled.rig.rig, 1.0)
	var toward := down.rotated(signf(down.cross(way)) * deg_to_rad(45.0))
	var at := player.global_position + Vector3(toward.x, 0.0, toward.y) * 7.0
	at.y = world.height_under(at) + built.deck.rest_height()
	built.deck.global_transform = Transform3D(Basis(Vector3.UP, atan2(toward.x, toward.y) - windward * PI * 0.5), at)
	var board := Catalog.device(&"board")
	world.content.add_child(board)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	board.fit(cell, board.sockets().filter(func(s: Socket) -> bool: return s.kind == &"battery")[0])
	board.global_position = player.global_position + Vector3.UP * 0.2
	player.rotation.y = atan2(-way.x, -way.y)
	await ticks(10)
	for id: StringName in kit.waist:
		lines.append(Line.to_waist(world, Runs._tie_of(built.named[id], player.global_position), kit.waist[id]))
	player.get_on(board)
	var mast: Mast = built.named.mast
	mast.raised = true
	mast.raise = 1.0
	mast.trim = 2.0 * Mast.BOOM * sin(deg_to_rad(10.0))
	player.set_physics_process(true)
	Input.action_press("move_forward", 1.0)
	Input.action_press("move_back", 0.25)
	for i in 60 * 16:
		await ticks(1)
		player.rotation.y = atan2(-way.x, -way.y)
		var want := clampf(mast.trimmed_to() + absf(mast.attack) - deg_to_rad(15.0), 0.0, Mast.MOST)
		mast.trim = lerpf(mast.trim, 2.0 * Mast.BOOM * sin(want * 0.5), 0.05)
	Input.action_release("move_forward")
	Input.action_release("move_back")
	var me := player.global_position
	var middle := built.deck.global_transform * built.deck.center_of_mass
	var flat := Vector3(down.x, 0.0, down.y)
	await shoot("tack_%s" % ("left" if windward > 0 else "right"), (me + middle) * 0.5 - flat * 10.0 + Vector3.UP * 4.0,
		(me + middle) * 0.5 + Vector3.UP * 1.0)
	print("nomad: wind on your %s, %.2f m/s across" % ["left" if windward > 0 else "right",
		Vector2(player.velocity.x, player.velocity.z).dot(way)])
	await _clear()


## The masted rig on skates beside you, across the breeze.
func _rig() -> Rig:
	var rig := Rig.build(world.content, MASTED, 1.0)
	var down := _down()
	var at := world.player.global_position + Vector3(down.x, 0.0, down.y) * 6.0
	at.y = world.height_under(at) + 0.3
	rig.deck.global_transform = Transform3D(Basis(Vector3.UP, atan2(down.x, down.y) + PI * 0.5), at)
	return rig


func _clear() -> void:
	var player := world.player
	player.step_off()
	for body in player.waist.tied.duplicate():
		player.waist.untie(body)
	for line in lines:
		if is_instance_valid(line):
			line.free()
	lines.clear()
	for node in world.content.get_children():
		if node is Device and not node is Stake or node is Part:
			node.free()
	await ticks(2)


func _down() -> Vector2:
	var wind := world.weather.field_wind(world.player.global_position)
	return Vector2(wind.x, wind.z).normalized()


func _ground() -> void:
	for i in 1800:
		await get_tree().process_frame
		if world.terrain.is_idle() and world.terrain.is_settled_around(world.player_world_x(), world.player_world_z()):
			break
	await ticks(10)


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func shoot(name: String, from: Vector3, to: Vector3) -> void:
	camera.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(out.path_join(name + ".png"))
	print("nomad: shot ", name)
