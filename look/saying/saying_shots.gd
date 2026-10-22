extends Node
## Look-test: saying less, shot three ways onto one sheet. Empty-handed at a
## deck three pieces long with a battery stuck on its last, every piece is
## highlighted as what take would drag; at a bare outer piece, that piece
## alone; the sheet at your waist, its how-to, and that how-to as it reads
## at full size. The game's own run, on a
## profile and saves of its own, never the player's. Needs a GPU, not
## --headless; scripts/unseen.sh gives it one with no window:
##   scripts/unseen.sh --path . --resolution 1920x1080 res://look/saying/saying_shots.tscn -- sheet.png

const MAIN := preload("res://game/main.tscn")
const SHOT := Vector2i(960, 540)

var shots: Array[Image] = [null, null, null, null]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "user://saying.png"
	get_window().unfocusable = true
	AudioServer.set_bus_mute(0, true)
	var own := OS.get_temp_dir().path_join("sandgame-look-%d" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(own)
	for keeper in [^"/root/Saves", ^"/root/Profile"]:
		get_node(keeper).dir = own
	Settings.path = own.path_join("settings.cfg")
	# This surface capture retains the automatic-arrival baseline.
	Tuning.current().run_seed = 1234
	Tuning.current().salvage = false
	Tuning.current().eye_adapts = false
	var main: Main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	var world := main.world()
	while not world.has_meta(&"kit"):
		await get_tree().physics_frame
	while main.ui.is_fading():
		await get_tree().process_frame
	Dev.hide_overlays()
	var player := world.player
	player.set_physics_process(false)
	player.global_rotation = Vector3.ZERO
	# Clear of the run's kit, which lands ahead of you.
	var at := player.global_position + Vector3(8.0, 0.0, 4.0)
	var deck := _piece(world, at)
	for x in [1, 2]:
		deck.join(_piece(world, at), _ring(deck, Vector2i(x - 1, 0)), 0)
	deck.fit(Catalog.part(&"hook"), _ring(deck, Vector2i.ZERO, Vector2i(-1, 0)))
	Stick.put(deck, Rig.piece(deck, Vector2i(2, 0)), Chassis.TOP, Vector2(0.2, 0.2), 0.0, Catalog.part(&"battery"))
	await ticks(30)
	await _aim(player, deck.global_transform * Vector3(1.0, 0.06, 0.0), 0)
	deck.take(_ring(deck, Vector2i.ZERO, Vector2i(-1, 0))).free()
	await _aim(player, deck.global_transform * Vector3(0.0, 0.06, 0.0), 1)
	player.camera.rotation = Vector3(-0.2, 0.0, 0.0)
	var mast := Catalog.device(&"mast") as Mast
	world.content.add_child(mast)
	var sail := Catalog.part(&"sail")
	world.content.add_child(sail)
	mast.fit(sail, mast.sockets()[0])
	mast.global_position = player.global_position + Vector3(2.0, 0.5, 2.0)
	mast.freeze = true
	Scenarios.sheet_to_waist(world, mast)
	await ticks(20)
	await _shoot(2)
	# The how-to at full size: the top middle of the screen, uncropped by the sheet.
	var full := get_viewport().get_texture().get_image()
	if full != null:
		full.convert(Image.FORMAT_RGB8)
		shots[3] = full.get_region(Rect2i((full.get_width() - SHOT.x) / 2, 0, SHOT.x, SHOT.y))
	else:
		shots[3] = Image.create(SHOT.x, SHOT.y, false, Image.FORMAT_RGB8)
	var sheet := Image.create(SHOT.x * 2, SHOT.y * 2, false, Image.FORMAT_RGB8)
	for i in shots.size():
		sheet.blit_rect(shots[i], Rect2i(Vector2i.ZERO, SHOT), Vector2i((i % 2) * SHOT.x, (i / 2) * SHOT.y))
	sheet.save_png(out)
	get_tree().quit()


func _piece(world: World, at: Vector3) -> Chassis:
	var piece := Catalog.device(&"chassis") as Chassis
	world.content.add_child(piece)
	piece.global_position = Vector3(at.x, world.height_under(at) + 0.06, at.z)
	piece.freeze = true
	return piece


## The deck's own ring at a piece's grid place, facing a way along the grid.
func _ring(deck: Chassis, cell: Vector2i, toward := Vector2i(1, 0)) -> Socket:
	for socket in deck.sockets():
		if socket.kind == &"ring" and not socket.has_meta(&"socket") and deck._cell_of(socket) == cell \
				and Chassis._step(socket) == toward:
			return socket
	return null


## Your eyes on a point of the deck from a step back and above, then shot `n`.
func _aim(player: Player, point: Vector3, n: int) -> void:
	var eye := point + Vector3(0.0, 1.3, 1.6)
	var to := point - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.global_position = eye - player.camera.position
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	await ticks(10)
	await _shoot(n)


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
