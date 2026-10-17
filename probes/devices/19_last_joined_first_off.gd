extends DeckProbe
## Devices & mods probe 19: last joined, first off. Three pieces joined in a
## row through your hands. Aimed at the middle one, take has hold of the
## whole deck and nothing comes off. Aimed at the last one joined, it comes
## off into your hands, out along its ring and never through the deck; then
## the middle one does, and the first is a piece on its own again.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	var middle := piece(spot(-3.0, 1.0))
	var last := piece(spot(-3.0, 2.5))
	check(await join_by_hand(deck, middle, ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
		and await join_by_hand(deck, last, ring(deck, Vector2i(1, 0), Vector2i(1, 0))), "three pieces join in a row")
	await simulate(0.5)

	var on_middle := deck.global_transform * Vector3(1.0, 0.06, 0.0)
	check(await take_at(on_middle + Vector3(0.0, 1.2, 1.2), on_middle) and hands.grasp.body == deck
		and deck.joined.size() == 2, "aimed at the middle piece, take has hold of the deck, and nothing comes off")
	hands.grab()
	await simulate(0.3)

	var on_last := deck.global_transform * Vector3(2.0, 0.06, 0.0)
	check(await take_at(on_last + Vector3(0.0, 1.2, 1.2), on_last) and hands.held == last and last.deck == null
		and deck.joined.size() == 1, "aimed at the last one joined, it comes off into your hands")
	var seen := {"through": false}
	await simulate(0.6, func() -> void: seen.through = seen.through or overlaps(last, deck))
	check(not seen.through and hands.phase == Hands.Phase.HELD, "out along its ring, never through the deck")
	hands.stow().free()
	await simulate(0.2)

	on_middle = deck.global_transform * Vector3(1.0, 0.06, 0.0)
	check(await take_at(on_middle + Vector3(0.0, 1.2, 1.2), on_middle) and hands.held == middle and deck.joined.is_empty()
		and deck.carryable, "then the middle one, and the first is a piece on its own again")
