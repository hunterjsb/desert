class_name BoardTowProbe
extends SailProbe
## A board and a real cargo body on open sand, joined at the rider's waist.

var board: Hoverboard
var cargo: Chassis
var line: Line


func load_towing(big := false, slack := 0.1) -> void:
	await load_sailing()
	speed_up(4)
	var player := world.player
	player.set_physics_process(true)
	board = Catalog.device(&"board") as Hoverboard
	world.content.add_child(board)
	fit_part(board, &"battery")
	board.global_position = player.global_position + Vector3.UP * 0.2
	await physics_frames(2)
	check(player.get_on(board), "you step onto the charged board")
	var steps: Array = []
	if big:
		steps = [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)]]
	steps.append([&"hook", Vector2i.ZERO, Vector2i(0, -1)])
	cargo = Rig.build(world.content, steps).deck
	cargo.global_position = player.global_position + Vector3(0.0, 0.3, 4.0)
	set_down(cargo)
	await physics_frames(60)
	line = Line.to_waist(world, cargo.free_tie(player.global_position), slack)
	Input.action_press("move_forward")
