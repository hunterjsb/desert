extends SailProbe
## Sailing probe 6: your camp tows you on the board. Standing behind a camp
## on skates with its sheet tied at your waist, you step onto a board and the
## sheet stays tied. The sail up in a steady 10 m/s wind, keys let go, the
## sheet tended and the camp held across the wind as you'd steer it by its
## lines, it sails off and tows you after it by the sheet, the board running
## where the line leads. Paying the sheet out on the board eases the sail.


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	rig(open, heading(), &"skates", 1, false)
	var ahead := ground(heading())
	var at := deck.global_position - ahead * 7.0
	at.y = world.height_under(at) + 0.1
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-ahead.x, -ahead.z)), at))
	player.velocity = Vector3.ZERO
	await physics_frames(10)
	var sheet := Scenarios.sheet_to_waist(world, mast)
	hands.reel.choose(sheet.ends[1])
	var board := Catalog.device(&"board")
	world.content.add_child(board)
	fit_part(board, &"battery")
	board.global_position = player.global_position + Vector3.UP * 0.2
	await physics_frames(2)
	check(player.get_on(board) and player.board == board, "you step onto the board")
	check(player.waist.tied.has(sheet.ends[1]), "the sheet stays tied at your waist")
	blow(downwind * 10.0)
	hoist(60.0)
	# You tend the sheet at your waist as you go, and steer by where you pull.
	tending = deg_to_rad(15.0)
	course = heading()
	# Lambdas copy what they're given: what they change lives in here.
	var seen := {"pulled": 0.0}
	await simulate(25.0, func() -> void:
		_steer()
		seen.pulled = maxf(seen.pulled, sheet.rope.tension))
	var pulled: float = seen.pulled
	var mine := Vector2(player.velocity.x, player.velocity.z)
	var apart := player.global_position.distance_to(Line._tip(sheet.ends[0]).global_position)
	print("towed: you at %.2f m/s, the camp at %.2f m/s, %.1f m behind its boom on a %.1f m sheet, pulling up to %d N" % [
		mine.length(), way().length(), apart, sheet.rope.length, roundi(pulled)])
	check(player.board == board and mine.length() > 2.0, "the camp tows you (%.2f m/s)" % mine.length())
	check(absf(mine.length() - way().length()) < 1.0 and apart < sheet.rope.length * 1.1 + 0.5,
		"keeping pace with it, on the end of the sheet (%.1f m)" % apart)
	check(pulled > 30.0, "the sheet pulls you (%d N)" % roundi(pulled))
	tending = 0.0
	course = Vector2.ZERO
	trim(35.0)
	var was := mast.trim
	check(player.hands.reel.notch(-2), "the reel works the sheet riding")
	await simulate(1.0)
	check(absf(mast.trim - was - 2.0 * Reel.NOTCH) < 0.01, "paying out two notches eases the sail (%.2f m to %.2f m)" % [was, mast.trim])
