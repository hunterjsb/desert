extends DeckProbe
## Devices & mods probe 16: one rigid deck. Five chassis pieces, joined
## through your hands into a long L, sit flush on the grid, each exactly a
## piece's width from its neighbour and square to it; a ring with a crate
## standing beyond it isn't offered. Trays under all five and a crate on
## top, the deck floats in a gusting storm for two minutes, moored by one
## line at its far end as a tow would hold it, the line pulling down on that
## end: its pieces never move against each other, and it stays level, with
## no jitter and nothing flung.

## Level within this, degrees: a deck held level as if it were as easy to
## tip along its length as across tips twice as far. Turning no faster than
## this, rad/s; moving no faster than this, m/s, in a storm many times as fast.
const LEVEL := 3.0
const SPIN := 0.3
const SPEED := 1.0


func run() -> void:
	await load_lines()
	var deck := piece(flat_spot(0.0, 4.0, 4.0))
	# The long L: east three times from the first piece, then south.
	var layout := [[Vector2i(0, 0), Vector2i(1, 0)], [Vector2i(1, 0), Vector2i(1, 0)], [Vector2i(2, 0), Vector2i(1, 0)],
		[Vector2i(3, 0), Vector2i(0, 1)]]
	for i in layout.size():
		var loose := piece(spot(-3.0, 1.0 + i * 1.5))
		await simulate(0.3)
		check(await join_by_hand(deck, loose, ring(deck, layout[i][0], layout[i][1])),
			"piece %d: the tug offers the deck's ring, and take joins it" % (i + 2))
	check(deck.pieces().size() == 5, "five pieces, one deck")
	if deck.pieces().size() != 5:
		return
	var worst := 0.0
	for p in deck.joined:
		var frame := relative(deck, p.frame_view)
		var want := Vector3(p.cell.x, 0.0, p.cell.y) * Chassis.WIDTH
		var square := absf(fposmod(frame.basis.get_euler().y + PI / 4.0, PI / 2.0) - PI / 4.0)
		worst = maxf(worst, maxf(frame.origin.distance_to(want), square))
	check(worst < 1e-4, "each sits flush on the grid, square to its neighbours (off by %.6f)" % worst)

	# Something standing beyond a free ring, where a piece would go: no piece goes there.
	var west := ring(deck, Vector2i.ZERO, Vector2i(-1, 0))
	var crate_beyond := device(&"crate_frame", deck.global_position, 0.0)
	crate_beyond.global_position = deck.global_transform * Vector3(-1.0, 0.0, 0.0)
	crate_beyond.freeze = true
	await simulate(0.5)
	var blocked := piece(spot(-3.0, -1.0))
	var joined := await join_by_hand(deck, blocked, west)
	check(not joined, "a ring with a crate standing beyond it isn't offered")
	crate_beyond.free()
	if joined:
		return
	blocked.free()

	for i in 5:
		fit_part(deck, &"hover_tray")
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	fit_part(crate, &"battery")
	fit_part(crate, &"battery")
	deck.mount(crate, socket_on(deck, Vector2i(1, 0), &"deck"))
	deck.fit(Catalog.part(&"hook"), west)
	await simulate(5.0)
	check(deck.stats().hovering and absf(clearance(deck) - deck.rest_height()) < 0.15,
		"trays under all five and a crate on top, it floats")
	var tie := deck.free_tie(west.global_position)
	var at := tie.global_position + Vector3(-3.0, 0.0, 0.0)
	Line.between(world, tie, driven_stake(Vector3(at.x, world.height_under(at), at.z)).free_tie(tie.global_position), 0.3)

	var before := {}
	for child in deck.get_children():
		if child is CollisionShape3D:
			before[child] = relative(deck, child)
	blow(Vector2(wind.storm_speed(), 0.0), world.tuning.gust_storm_strength)
	speed_up(6)
	await simulate(10.0)
	var seen := {"tilt": 0.0, "spin": 0.0, "speed": 0.0, "moved": 0.0}
	await simulate(120.0, func() -> void:
		seen.tilt = maxf(seen.tilt, rad_to_deg(deck.global_basis.y.normalized().angle_to(Vector3.UP)))
		seen.spin = maxf(seen.spin, deck.angular_velocity.length())
		seen.speed = maxf(seen.speed, deck.linear_velocity.length()))
	speed_up(1)
	for shape: Node3D in before:
		var now := relative(deck, shape)
		seen.moved = maxf(seen.moved, now.origin.distance_to(before[shape].origin))
	print("two minutes in a %.0f m/s storm on one line: tilted %.2f deg, turning %.3f rad/s, moving %.2f m/s at most"
		% [wind.storm_speed(), seen.tilt, seen.spin, seen.speed])
	check(seen.moved < 1e-5, "its pieces never moved against each other")
	check(seen.tilt < LEVEL and seen.spin < SPIN, "it stays level, with no jitter")
	check(seen.speed < SPEED and deck.stats().hovering and world.ropes.ropes.size() == 1, "nothing flung, still floating on its line")
