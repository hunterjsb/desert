extends DeckProbe
## Devices & mods probe 19: any outer piece comes off. Three pieces joined in
## a row through your hands, a hook on the first one's far ring and a crate
## standing on the last. Aimed at the middle piece, the readout says take
## drags the whole deck, and it does, nothing coming off. Aimed at the first
## piece joined, the readout says it comes off, and take has it off into
## your hands with its hook, out across its ring and never through the deck.
## Aimed at the last, it comes off with the crate standing on it, into your
## hold, and the middle one is a piece on its own again.


func run() -> void:
	await load_lines()
	var deck := piece(spot(0.0, 4.0))
	var middle := piece(spot(-3.0, 1.0))
	var last := piece(spot(-3.0, 2.5))
	check(await join_by_hand(deck, middle, ring(deck, Vector2i.ZERO, Vector2i(1, 0)))
		and await join_by_hand(deck, last, ring(deck, Vector2i(1, 0), Vector2i(1, 0))), "three pieces join in a row")
	var hook := Catalog.part(&"hook")
	deck.fit(hook, ring(deck, Vector2i.ZERO, Vector2i(-1, 0)))
	var crate := Catalog.device(&"crate_frame")
	world.content.add_child(crate)
	deck.mount(crate, socket_on(deck, Vector2i(2, 0), &"deck"))
	await simulate(0.5)
	var on_first := deck.global_transform * Vector3(0.0, 0.06, 0.0)
	var on_middle := deck.global_transform * Vector3(1.0, 0.06, 0.0)
	var on_last := deck.global_transform * Vector3(2.45, 0.06, 0.0)

	look(on_middle + Vector3(0.0, 1.2, 1.2), on_middle)
	await simulate(2.0 / 60.0)
	check(_reads("drags the whole deck"), "aimed at the middle piece, the readout says take drags the whole deck")
	check(hands.grab() and hands.grasp.body == deck and deck.joined.size() == 2, "and take has hold of it, nothing coming off")
	hands.grab()
	await simulate(0.3)

	look(on_first + Vector3(0.0, 1.2, 1.2), on_first)
	await simulate(2.0 / 60.0)
	check(_reads("this piece comes off"), "aimed at the first piece joined, the readout says it comes off")
	var took := hands.grab()
	var off := hands.held as Chassis
	check(took and off != null and off.deck == null and off.parts().has(hook) and deck.pieces().size() == 2
		and not deck.parts().has(hook), "take has it off into your hands, its hook with it")
	if off == null:
		return
	var seen := {"through": false}
	await simulate(0.6, func() -> void: seen.through = seen.through or off != null and overlaps(off, deck))
	check(not seen.through and hands.phase == Hands.Phase.HELD, "out across its ring, never through the deck")
	hands.stow().free()
	await simulate(0.2)

	look(on_last + Vector3(1.2, 1.2, 0.0), on_last)
	await simulate(2.0 / 60.0)
	check(_reads("this piece comes off") and hands.grab() and hands.grasp.body == last and last.deck == null
		and crate.host() == last and deck.joined.is_empty() and deck.carryable,
		"aimed at the last, it comes off with its crate into your hold, and the middle is a piece on its own")


func _reads(words: String) -> bool:
	return hands._readout.text.contains(words)
