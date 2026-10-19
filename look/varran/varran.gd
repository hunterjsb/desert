extends Node
## Look-test: the Varran settler. His start as a run sets it down; his rig
## sailing a breeze with him towed on his board as its keel, from abeam and
## from behind; the navigation computer's screen; him under his personal
## shield on a storm's front, the rig flying outside the bubble; and the
## Surveyor's deck. Needs a GPU, not --headless; scripts/unseen.sh gives it
## one with no window:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/varran/varran.tscn -- <out dir>

const WORLD_SCENE := preload("res://game/world/world.tscn")
const BREEZE := {"key": "look_varran", "kind": "sail", "day": [0.35, 0.5], "breeze": [8.5, 11.5]}

var world: World
var camera: Camera3D
var out := ""
var rig: Rig
var lines: Array[Line] = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://varran"
	DirAccess.make_dir_recursive_absolute(out)
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	Dev.hide_overlays()
	Tuning.current().run_seed = 1234
	Tuning.current().eye_adapts = false
	world = WORLD_SCENE.instantiate()
	world.kit = Kit.named(&"varran")
	add_child(world)
	await _ground()
	for layer: CanvasLayer in world.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	world.player.set_process_unhandled_input(false)
	camera = Camera3D.new()
	camera.fov = 60.0
	add_child(camera)
	camera.make_current()
	await _start()
	await _sailing()
	await _storm()
	await _surveyor()
	get_tree().quit()


## His kit as a run sets it down, from over your shoulder.
func _start() -> void:
	var place := Scenarios.find(world, Scenarios.by_key("clear"))
	Scenarios.stand(world, Scenarios.by_key("clear"), place)
	await _ground()
	var made := Runs.kit(world)
	await ticks(90)
	var deck: Chassis = made.filter(func(n: Node) -> bool: return n is Chassis)[0]
	var me := world.player.global_position
	var middle := deck.global_transform * deck.center_of_mass
	await shoot("start", me + (me - middle).normalized() * 3.0 + Vector3.UP * 2.6, (me + middle) * 0.5)
	var computer: Console = made.filter(func(n: Node) -> bool: return n is Console)[0]
	var front := -computer.global_basis.z
	for i in 60 * 4:
		await ticks(1)
		if not computer.readings.is_empty():
			break
	await ticks(60)
	await shoot("computer", computer.global_position + front * 1.6 + Vector3.UP * 0.25, computer.global_position + Vector3.UP * 0.1)
	for body in world.player.waist.tied.duplicate():
		world.player.waist.untie(body)
	for node in made:
		if is_instance_valid(node):
			node.free()


## Towed across the breeze on the board, the sheet tended, the edge dug.
func _sailing() -> void:
	Scenarios.stand(world, BREEZE, Scenarios.find(world, BREEZE))
	await _ground()
	var player := world.player
	var down := _downwind()
	# The wind on your left, as the breeze stands you, and the rig's own bow hook.
	var across := down.orthogonal()
	await _launch(across, down)
	player.set_physics_process(true)
	Input.action_press("move_forward", 1.0)
	Input.action_press("move_back", 0.25)
	for i in 60 * 18:
		await ticks(1)
		player.rotation.y = atan2(-across.x, -across.y)
		_tend(deg_to_rad(15.0))
	var me := player.global_position
	var middle := rig.deck.global_transform * rig.deck.center_of_mass
	var flat := Vector3(down.x, 0.0, down.y)
	var way := Vector3(across.x, 0.0, across.y)
	await shoot("sailing", (me + middle) * 0.5 - flat * 9.0 - way * 6.0 + Vector3.UP * 3.0, (me + middle) * 0.5 + Vector3.UP * 1.0)
	await shoot("behind", me - way * 4.5 - flat * 1.0 + Vector3.UP * 2.0, middle + Vector3.UP * 1.5)
	Input.action_release("move_forward")
	Input.action_release("move_back")
	print("varran: sailing at %.2f m/s, the rig at %.2f, heeling %.1f°" % [player.velocity.length(),
		rig.deck.linear_velocity.length(), rad_to_deg(rig.deck.global_basis.y.angle_to(Vector3.UP))])
	await _clear()


## A storm's front reaching him, his shield up round him, the rig outside it
## on its lines, its sail furled; seen from abeam.
func _storm() -> void:
	var front := Scenarios.by_key("storm_20")
	Scenarios.stand(world, front, Scenarios.find(world, front))
	await _ground()
	var player := world.player
	var shield: ShieldGenerator = player.suit.carried.filter(func(b: Node) -> bool: return b is ShieldGenerator)[0]
	shield.stand(true)
	var down := _downwind()
	var across := down.orthogonal()
	await _launch(across, down)
	player.set_physics_process(true)
	(rig.named.mast as Mast).raised = false
	for i in 60 * 5:
		await ticks(1)
		player.rotation.y = atan2(-across.x, -across.y)
	var me := player.global_position
	var middle := rig.deck.global_transform * rig.deck.center_of_mass
	var flat := Vector3(down.x, 0.0, down.y)
	var side := Vector3(across.x, 0.0, across.y)
	var mid := (me + middle) * 0.5
	await shoot("storm", mid - side * 8.0 + flat * 2.0 + Vector3.UP * 2.0, mid + Vector3.UP * 0.6)
	print("varran: in the storm (%.2f), the shield %s, its bubble %.1f m, the rig %.1f m off" % [
		world.weather.field_storm(me), "up" if shield.running() else "down", shield.shelter.radius, me.distance_to(middle)])
	shield.stand(false)
	await _clear()


## The Surveyor's deck as its run sets it down.
func _surveyor() -> void:
	var place := Scenarios.find(world, Scenarios.by_key("clear"))
	Scenarios.stand(world, Scenarios.by_key("clear"), place)
	await _ground()
	var made := Runs.kit(world, Kit.standard())
	await ticks(120)
	var deck: Chassis = made.filter(func(n: Node) -> bool: return n is Chassis)[0]
	var middle := deck.global_transform * deck.center_of_mass
	var side := deck.global_basis.x
	await shoot("surveyor", middle + side * 3.2 - deck.global_basis.z * 2.2 + Vector3.UP * 2.0, middle + Vector3.UP * 0.4)
	print("varran: the Surveyor's deck leans %.1f°" % rad_to_deg(deck.global_basis.y.angle_to(Vector3.UP)))


## His rig as his kit builds it, floating downwind of you toward `across`,
## lying across its lines, its sail up; its bow line and sheet at your waist
## and you on his board.
func _launch(across: Vector2, down: Vector2) -> void:
	var kit := Kit.named(&"varran")
	rig = Rig.build(world.content, kit.assembled.rig.rig, 1.0)
	var toward := down.rotated(signf(down.cross(across)) * deg_to_rad(45.0))
	var at := world.player.global_position + Vector3(toward.x, 0.0, toward.y) * 7.0
	at.y = world.height_under(at) + rig.deck.rest_height()
	rig.deck.global_transform = Transform3D(Basis(Vector3.UP, atan2(toward.x, toward.y) - PI * 0.5), at)
	var player := world.player
	var board := Catalog.device(&"board")
	world.content.add_child(board)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	board.fit(cell, board.sockets().filter(func(s: Socket) -> bool: return s.kind == &"battery")[0])
	board.global_position = player.global_position + Vector3.UP * 0.2
	player.rotation.y = atan2(-across.x, -across.y)
	await ticks(10)
	var mast: Mast = rig.named.mast
	lines = [Line.to_waist(world, Runs._tie_of(rig.named.bow, player.global_position), kit.waist[&"bow"]),
		Line.to_waist(world, mast._tie(), kit.waist[&"mast"])]
	player.get_on(board)
	mast.raised = true
	mast.raise = 1.0
	mast.trim = 2.0 * Mast.BOOM * sin(deg_to_rad(10.0))
	await ticks(2)


func _tend(meeting: float) -> void:
	var mast: Mast = rig.named.mast
	if mast.sail() == null:
		return
	var want := clampf(mast.trimmed_to() + absf(mast.attack) - meeting, 0.0, Mast.MOST)
	mast.trim = lerpf(mast.trim, 2.0 * Mast.BOOM * sin(want * 0.5), 0.05)


func _clear() -> void:
	var player := world.player
	player.step_off()
	for body in player.waist.tied.duplicate():
		player.waist.untie(body)
	for line in lines:
		if is_instance_valid(line):
			line.free()
	for node in world.content.get_children():
		if node is Device and not node is Stake or node is Part:
			node.free()
	await ticks(2)


func _downwind() -> Vector2:
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
	print("varran: shot ", name)
