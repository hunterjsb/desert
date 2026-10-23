class_name BoardTowProbe
extends SailProbe
## A board and a real cargo body on open sand, joined at the rider's waist.

var board: Hoverboard
var cargo: Chassis
var line: Line


## A rig on open sand ahead of you, small or big: a deck on skates with a mast
## and its sail furled. Its sheet and `lines` bow lines are tied at your waist
## before you step onto the charged board, as a rider sets out, so boarding
## keeps them all.
func load_towing(big := false, slack := 0.1, lines := 1) -> void:
	await load_sailing()
	speed_up(4)
	var player := world.player
	player.set_physics_process(true)
	# Standing on the sand while the lines are tied, as the Varran probe stands.
	player.collision_layer = 1
	player.collision_mask = 1
	var steps: Array = []
	if big:
		steps = [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)]]
	steps.append([&"hook", Vector2i.ZERO, Vector2i(0, -1)])
	cargo = Rig.build(world.content, steps).deck
	mast = Rig.make([&"mast", [&"sail"]]) as Mast
	Stick.put(cargo, Rig.piece(cargo, Vector2i.ZERO), Chassis.TOP, Vector2.ZERO, PI, mast)
	for i in cargo.pieces().size():
		fit_part(cargo, &"skates")
	for i in lines - 1:
		fit_part(cargo, &"hook")
	cargo.global_position = player.global_position + Vector3(0.0, 0.3, 4.0)
	set_down(cargo)
	await physics_frames(60)
	Line.to_waist(world, mast.boom_tie(), slack)
	line = Line.to_waist(world, cargo.free_tie(player.global_position), slack)
	for i in lines - 1:
		Line.to_waist(world, cargo.free_tie(player.global_position), slack)
	board = Catalog.device(&"board") as Hoverboard
	world.content.add_child(board)
	fit_part(board, &"battery")
	board.global_position = player.global_position + Vector3.UP * 0.2
	await physics_frames(2)
	check(player.get_on(board) and player.board == board and player.waist.tied.size() == lines + 1,
		"you step onto the charged board, the rig's sheet and bow lines kept at your waist")
	Input.action_press("move_forward")
