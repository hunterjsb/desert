extends DeckProbe
## Devices & mods probe 22: a refusal says why. When take or use can't do
## what you aim at, the readout says why and a soft knock sounds, never
## silence: a battery held to a crate whose slots are full stays in your
## hands; a crate with its tray in, taken hold of beside a deck, is let go
## with word to take the tray off first; a piece held to a deck whose one
## free ring is blocked stays in your hands; use at a bare crate frame has
## nothing to work.


func run() -> void:
	await load_lines()
	var full := device(&"crate_frame", spot(0.0, 3.0), 0.27)
	fit_part(full, &"battery")
	fit_part(full, &"battery")
	var deck := piece(spot(5.0, 3.0))
	var trayed := device(&"crate_frame", spot(4.0, 3.0), 0.27)
	fit_part(trayed, &"hover_tray")
	trayed.resting = true
	var blocked := piece(spot(-5.0, 3.0))
	for toward: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		blocked.fit(Catalog.part(&"hook"), ring(blocked, Vector2i.ZERO, toward))
	var beyond := device(&"crate_frame", blocked.global_position, 0.0)
	beyond.global_position = blocked.global_transform * Vector3(-1.0, 0.0, 0.0)
	beyond.freeze = true
	await simulate(1.0)

	var cell := part(&"battery", Transform3D.IDENTITY.translated(eye()))
	hands.hold(cell)
	await simulate(0.3)
	look(full.global_position + Vector3(-1.4, 0.4, 0.0), full.global_position)
	await simulate(0.2)
	check(_refused(hands.grab(), "no free battery slot") and hands.held == cell,
		"a battery held to a crate whose slots are full stays in your hands, and it says why")
	hands.stow().free()

	check(await take_at(trayed.global_position + Vector3(-1.4, 0.5, 0.0), trayed.global_position)
		and hands.grasp.body == trayed, "you take hold of a crate with its tray in, beside a deck")
	await simulate(0.1)
	check(_refused(hands.grab(), "take its tray off first") and hands.grasp.body == null and trayed.host() == null,
		"take lets it go beside the deck, saying to take its tray off first")

	var loose := piece(eye())
	hands.hold(loose)
	await simulate(0.3)
	look(blocked.global_position + Vector3(0.0, 1.4, 1.4), blocked.global_position)
	await simulate(0.2)
	check(_refused(hands.grab(), "no room at that ring") and hands.held == loose and loose.deck == null,
		"a piece held to a deck whose one free ring is blocked stays in your hands")
	hands.stow().free()

	look(full.global_position + Vector3(-1.4, 0.4, 0.0), full.global_position)
	await simulate(0.1)
	check(_refused(hands.interact(), "nothing to use"), "use at a bare crate frame has nothing to work")


## Whether take or use answered with these words and the knock, from silence.
func _refused(answered: bool, words: String) -> bool:
	var said := answered and hands.notice.contains(words) and hands._sound.stream == Sounds.REFUSE
	hands.notice = ""
	hands._sound.stream = null
	return said
