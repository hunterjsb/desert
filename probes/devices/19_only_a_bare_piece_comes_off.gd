extends DeckProbe
## Devices & mods probe 19: only a bare piece comes off (replacing "any outer
## piece comes off"). Three pieces joined in a row through your hands, a hook
## on the first one's far ring and a crate standing on the last. Aimed at the
## middle, at the first with its hook and at the last with its crate, every
## piece is highlighted as what take would move, and take has hold of all of
## it, nothing coming off. Its hook out, the first is bare: it's highlighted
## alone, and take has it off into your hands, out across its ring and never
## through the deck.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	var middle := piece(spot(-3.0, 1.0))
	var last := piece(spot(-3.0, 2.5))
	check(await join_by_hand(deck, middle, ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
		and await join_by_hand(deck, last, ring(deck, Vector2i(1, 0), Vector2i(1, 0))), "three pieces join in a row")
	var west := ring(deck, Vector2i.ZERO, Vector2i(-1, 0))
	deck.fit(Catalog.part(&"hook"), west)
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	deck.mount(crate, socket_on(deck, Vector2i(2, 0), &"deck"))
	await simulate(0.5)

	for aim: Array in [["middle", Vector3(1.0, 0.06, 0.0), Vector3(0.0, 1.2, 1.2)],
			["first, with its hook", Vector3(0.0, 0.06, 0.0), Vector3(0.0, 1.2, 1.2)],
			["last, with its crate", Vector3(2.45, 0.06, 0.0), Vector3(1.2, 1.2, 0.0)]]:
		var at: Vector3 = deck.global_transform * aim[1]
		look(at + aim[2], at)
		await simulate(2.0 / 60.0)
		check(_marked(3), "aimed at the %s, every piece is highlighted" % aim[0])
		check(hands.grab() and hands.grasp.body == deck and deck.pieces().size() == 3,
			"and take has hold of all of it, nothing coming off (%s)" % aim[0])
		hands.grab()
		await simulate(0.3)

	deck.take(west).free()
	var on_first := deck.global_transform * Vector3(0.0, 0.06, 0.0)
	look(on_first + Vector3(0.0, 1.2, 1.2), on_first)
	await simulate(2.0 / 60.0)
	check(_marked(1) and hands.moves[0] == deck, "its hook out, the first is bare: it's highlighted alone")
	var took := hands.grab()
	var off := hands.held as Chassis
	check(took and off != null and off.deck == null and off.parts().is_empty() and deck.pieces().size() == 2,
		"take has it off into your hands")
	if off == null:
		return
	var seen := {"through": false}
	await simulate(0.6, func() -> void: seen.through = seen.through or off != null and overlaps(off, deck))
	check(not seen.through and hands.phase == Hands.Phase.HELD, "out across its ring, never through the deck")


## Whether take's highlight is up, on this many pieces.
func _marked(pieces: int) -> bool:
	return hands._marks.visible and hands._marks.get_child_count() > 0 and hands.moves.size() == pieces
