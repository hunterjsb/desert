extends DeckProbe
## Devices & mods probe 19: take takes what you aim at, and a deck never
## comes apart. Three pieces joined in a row through your hands, a hook on
## the first one's far ring, the middle crowded with batteries round a radio.
## Aimed at one battery in the crowd, take has that one off into your hands
## and nothing else moves; take again at once, the aim never leaving, and it
## goes straight back where it was. The radio's own battery comes out and
## goes straight back in the same way. Aimed at the middle's plate, at the
## first with its hook or the last with its lamp, every piece is highlighted and take
## has hold of the whole deck, nothing coming off. Its hook out, the first is
## bare: it's highlighted alone, and take has it off into your hands, out
## across its ring and never through the deck.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	var middle := piece(spot(-3.0, 1.0))
	var last := piece(spot(-3.0, 2.5))
	check(await join_by_hand(deck, middle, ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
		and await join_by_hand(deck, last, ring(deck, Vector2i(1, 0), Vector2i(1, 0))), "three pieces join in a row")
	var west := ring(deck, Vector2i.ZERO, Vector2i(-1, 0))
	deck.fit(Catalog.part(&"hook"), west)
	var crowd: Array[Part] = []
	for at: Vector2 in [Vector2(-0.24, 0.3), Vector2(0.0, 0.3), Vector2(0.24, 0.3), Vector2(-0.24, 0.12), Vector2(0.24, 0.12)]:
		var cell := Catalog.part(&"battery")
		Stick.put(deck, middle, Chassis.TOP, at, 0.0, cell)
		crowd.append(cell)
	var radio := Rig.make([&"radio", [&"battery"]]) as Radio
	Stick.put(deck, middle, Chassis.TOP, Vector2(0.0, -0.25), 0.0, radio)
	Stick.put(deck, last, Chassis.TOP, Vector2(0.3, 0.3), 0.0, Catalog.part(&"lamp"))
	await simulate(0.5)

	var target := crowd[1]
	var was := target.socket.transform
	var at := deck.global_transform * was * Vector3(0.0, 0.0, 0.1)
	look(at + Vector3(0.0, 1.0, 0.3), at)
	await simulate(2.0 / 60.0)
	check(hands.grab() and hands.held == target and deck.batteries().size() == 4 and deck.pieces().size() == 3,
		"aimed at one battery in the crowd, take has that one off, nothing else")
	check(hands.grab(), "take again at once")
	await simulate(0.6)
	check(target.socket != null and target.socket.get_parent() == deck
		and target.socket.transform.origin.distance_to(was.origin) < 0.03, "and it goes straight back where it was")

	var own := radio.battery()
	var slot := own.socket
	var spot_at := radio.global_transform * slot.transform.origin
	look(spot_at + (radio.global_basis * slot.transform.basis.z) * 0.8 + Vector3.UP * 0.4, spot_at)
	await simulate(2.0 / 60.0)
	check(hands.grab() and hands.held == own, "the radio's own battery comes out")
	check(hands.grab(), "take again at once")
	await simulate(0.6)
	check(own.socket == slot, "and it goes straight back in")

	for aim: Array in [["middle's plate", Vector3(1.0, 0.06, -0.3), Vector3(0.0, 1.2, -1.2)],
			["first, with its hook", Vector3(0.0, 0.06, 0.0), Vector3(0.0, 1.2, 1.2)],
			["last, with its lamp", Vector3(2.0, 0.06, 0.2), Vector3(1.2, 1.2, 0.0)]]:
		var point: Vector3 = deck.global_transform * aim[1]
		look(point + aim[2], point)
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
