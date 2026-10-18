extends DeckProbe
## Profile & saves probe 22: six pieces, one deck. A deck of five beside one
## of three is eight pieces but no six-piece deck; the first deck's sixth
## makes Six Pack.


func run() -> void:
	await load_lines()
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var one := piece(flat_spot(0.0, 4.0, 8.0))
	var two := piece(flat_spot(0.0, -6.0, 4.0))
	for i in 2:
		two.join(piece(spot(4.0, -3.0 - i * 1.5)), ring(two, Vector2i(i, 0), Vector2i(1, 0)), 0)
	for i in 5:
		if i == 4:
			check(not profile.did("deck_pieces"), "five and three are no six-piece deck")
		one.join(piece(spot(-4.0, 1.0 + i * 1.5)), ring(one, Vector2i(i, 0), Vector2i(1, 0)), 0)
		await simulate(0.1)
	check(one.pieces().size() == 6 and profile.did("deck_pieces"), "the sixth piece of one deck makes it")
