extends MenuProbe
## Menus & UI probe 6: held keys wait. With the system menu open and the move
## action held you stay put, on foot and on a board; with it closed, the same
## hold walks you, and rides you.

const TICKS := 60


func run() -> void:
	await open_main(false)
	# Input gating needs open ground, beyond the now physical landing shell.
	teleport(world.spawn.x - 12.0, world.spawn.y)
	world.player.rotation.y = PI * 0.5
	await physics_frames(30)
	var player := world.player
	Input.action_press(&"move_forward")
	press(&"ui_cancel")
	await physics_frames(TICKS)
	check(main.ui.is_open() and player.own.length() < 0.01 and player.mode == "stand",
		"on foot under the menu you stay put (%.2f m/s, %s)" % [player.own.length(), player.mode])
	press(&"ui_cancel")
	await physics_frames(TICKS)
	check(not main.ui.is_open() and player.own.length() > 1.0 and player.mode == "walk",
		"with it closed you walk (%.2f m/s)" % player.own.length())

	Input.action_release(&"move_forward")
	await physics_frames(TICKS)
	var board := Catalog.device(&"board") as Hoverboard
	world.content.add_child(board)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	board.fit(cell, board.sockets()[0])
	board.global_position = player.global_position + Vector3.UP * 0.06
	check(player.get_on(board), "you step onto a board")
	Input.action_press(&"move_forward")
	press(&"ui_cancel")
	await physics_frames(TICKS)
	check(main.ui.is_open() and player.ride.velocity.length() < 0.5 and board.push == 0.0,
		"on the board under the menu it doesn't push (%.2f m/s)" % player.ride.velocity.length())
	press(&"ui_cancel")
	await physics_frames(TICKS)
	check(not main.ui.is_open() and player.ride.velocity.length() > 3.0,
		"with it closed it rides you (%.2f m/s)" % player.ride.velocity.length())
	Input.action_release(&"move_forward")
