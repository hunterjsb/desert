extends Node
## Look-test: sleep, shot four ways onto one sheet. The run's own start, the
## Surveyor's kit round you and its bedroll carried: use on the bedroll brings
## up the words to choose how long, a storm due; a house ruin's sleeping
## bench, its line "Bed"; through the storm under the camp's light shield,
## and the summary you wake to; and the bedroll hung on the camp's upright in
## the board's place, by the headlamp.
## The game's own run, on a profile and saves of its own, never the player's.
## Needs a GPU, not --headless; scripts/unseen.sh gives it one with no window:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/sleep/sleep_shots.tscn -- sheet.png

const MAIN := preload("res://game/main.tscn")
const SHOT := Vector2i(960, 540)

var shots: Array[Image] = [null, null, null, null]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://sleep.png"
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	var own := OS.get_temp_dir().path_join("sandgame-look-%d" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(own)
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = own
	Settings.path = own.path_join("settings.cfg")
	# This surface capture retains the automatic-arrival baseline.
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = true
	Tuning.current().eye_adapts = false
	var main: Main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	var world := main.world()
	await SurfaceStart.begin(main)
	while not world.has_meta(&"kit"):
		await get_tree().physics_frame
	while main.ui.is_fading():
		await get_tree().process_frame
	Dev.hide_overlays()
	var player := world.player
	var kit: Array = world.get_meta(&"kit")
	var deck: Chassis = kit.filter(func(n: Node) -> bool: return n is Chassis and n.has_tray())[0]
	var shield: ShieldGenerator = kit.filter(func(n: Node) -> bool: return n is ShieldGenerator)[0]
	var bedroll: Bedroll = player.suit.carried.filter(func(t: Node) -> bool: return t is Bedroll)[0]
	# Beside the camp, inside its light shield's bubble once it's on, facing it.
	var beside := deck.global_position + deck.global_basis.x * 2.2
	_face(player, beside, deck.global_position)
	await ticks(30)
	print("sleep: '%s', storm due in %.0f s" % [world.sleep.refusal(), world.weather.next_change_time - world.time])
	bedroll.interact(player)
	await ticks(20)
	await _shoot(0)
	main.ui.close_top()

	# A house ruin stood by hand, dug out, and its bench from the back room's door.
	var at := Vector2(world.player_world_x(), world.player_world_z()) + Vector2(60.0, 60.0)
	var ruin: Structure = null
	for j in 60:
		ruin = world.shape.sites.by_hand(&"house_ruin", at.x + (j % 6) * 12.0, at.y + (j / 6) * 12.0, 0.0, 0.0)
		if ruin.stands():
			break
	world.shape.sites.add(ruin)
	var stand := ruin.to_world(Vector2(6.0, -2.1))
	var bench := ruin.to_world(Vector2(SecondAgeKit.BENCH.get_center().x, SecondAgeKit.BENCH.get_center().z))
	_face(player, Vector3(world.engine_x(stand.x), 0.0, world.engine_z(stand.y)),
		Vector3(world.engine_x(bench.x), ruin.origin().y + 0.4, world.engine_z(bench.y)))
	while not world.terrain.is_settled_around(stand.x, stand.y) or not world.terrain.is_idle():
		await get_tree().physics_frame
	await ticks(30)
	print("ruin: looking at a bed %s, '%s'" % [player.hands.look_bed, player.hands.line()])
	await _shoot(1)
	print("ruin: use opens the words: %s" % (player.hands.interact() and main.ui.is_open()))
	main.ui.close_top()

	_face(player, beside, deck.global_position)
	await ticks(30)
	shield.interact(player)
	await ticks(60)
	bedroll.interact(player)
	await ticks(5)
	_press(&"ui_accept")
	while not world.sleep.sleeping:
		await get_tree().process_frame
	while world.sleep.sleeping:
		await get_tree().process_frame
	print("woke: %s" % " / ".join(world.sleep.said))
	await ticks(30)
	await _shoot(2)

	# The board off the upright, the bedroll hung there, by the light of the headlamp.
	var hung: Device = deck.mounted().filter(func(d: Device) -> bool: return d is Hoverboard)[0]
	var wall := deck.own_piece(deck.seat_of(hung))
	var board := deck.unstick(deck.seat_of(hung))
	board.global_position += deck.global_basis.x * -1.5
	player.suit.carried.erase(bedroll)
	player.suit._off_you(bedroll)
	Stick.put(deck, wall, Chassis.TOP, Vector2(0.0, 0.12), PI / 2.0, bedroll)
	var on_wall := deck.global_transform * wall.pose().origin
	_face(player, on_wall + deck.global_basis.z * 2.0 + deck.global_basis.x * 0.6, on_wall)
	player.headlamp.on = true
	await ticks(150)
	await _shoot(3)

	var sheet := Image.create(SHOT.x * 2, SHOT.y * 2, false, Image.FORMAT_RGB8)
	for i in shots.size():
		sheet.blit_rect(shots[i], Rect2i(Vector2i.ZERO, SHOT), Vector2i((i % 2) * SHOT.x, (i / 2) * SHOT.y))
	sheet.save_png(out)
	print("sheet: %s" % out)
	get_tree().quit()


## You standing on the sand over `spot`, engine metres, still, your eyes on `target`.
func _face(player: Player, spot: Vector3, target: Vector3) -> void:
	var feet := Vector3(spot.x, player.world.height_under(spot) + 0.1, spot.z)
	var to := target - (feet + player.camera.position)
	player.velocity = Vector3.ZERO
	player.world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-to.x, -to.z)), feet))
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)


func _press(action: StringName) -> void:
	var event: InputEvent = InputMap.action_get_events(action)[0].duplicate()
	event.pressed = true
	get_viewport().push_input(event)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event)


func _shoot(n: int) -> void:
	for i in 4:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null:
		image = Image.create(SHOT.x, SHOT.y, false, Image.FORMAT_RGB8)
	image.resize(SHOT.x, SHOT.y, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	shots[n] = image


func ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
