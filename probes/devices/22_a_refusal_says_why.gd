extends DeckProbe
## Devices & mods probe 22: a refusal says why. When take or use can't do
## what you aim at, the readout says why in a few words and a soft knock
## sounds, never silence: a battery held to a radio whose slot is full stays
## in your hands; a condenser you have hold of, shown where something already
## stands on a deck, stays in your hold; a piece held to one with a condenser
## standing beyond every ring, even its hooked one, stays in your hands; use
## at a bare chassis piece has nothing to work.

## A few words, at most.
const FEW := 5


func run() -> void:
	await load_lines()
	var full := device(&"radio", spot(0.0, 3.0), 0.12)
	fit_part(full, &"battery")
	var deck := piece(spot(5.0, 3.0))
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, 0.0, Catalog.device(&"shield"))
	var heavy := device(&"condenser", spot(3.6, 3.0), 0.36)
	# A hook on a ring pops off for a piece, but a condenser beyond one stands in its way.
	var blocked := piece(spot(-5.0, 3.0))
	blocked.fit(Catalog.part(&"hook"), ring(blocked, Vector2i.ZERO, Vector2i(0, 1)))
	for toward: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var beyond := device(&"condenser", blocked.global_position, 0.0)
		beyond.global_position = blocked.global_transform * Vector3(toward.x * 1.1, 0.3, toward.y * 1.1)
		beyond.freeze = true
	var bare := piece(spot(0.0, -3.0))
	await simulate(1.0)

	var cell := part(&"battery", Transform3D.IDENTITY.translated(eye()))
	hands.hold(cell)
	await simulate(0.3)
	look(full.global_position + Vector3(-1.2, 0.4, 0.0), full.global_position)
	await simulate(0.2)
	check(_refused(hands.grab()) and hands.held == cell,
		"a battery held to a radio whose slot is full stays in your hands, and it says why")
	hands.stow().free()

	check(await take_at(heavy.global_position + Vector3(-1.4, 0.5, 0.0), heavy.global_position)
		and hands.grasp.body == heavy, "you take hold of a condenser beside a deck")
	var top := on_face(deck, deck, Chassis.TOP)
	look(top + Vector3(-1.2, 1.2, 0.3), top)
	await simulate(0.3)
	check(hands.grasp.showing() and _refused(hands.grab()) and hands.grasp.body == heavy and heavy.host() == null,
		"shown where the shield stands, take keeps it in your hold, saying why")
	hands.grasp.let_go()

	var loose := piece(eye())
	hands.hold(loose)
	await simulate(0.3)
	look(blocked.global_position + Vector3(0.0, 1.4, 1.4), blocked.global_position)
	await simulate(0.2)
	check(_refused(hands.grab()) and hands.held == loose and loose.deck == null,
		"a piece held to one with a condenser beyond every ring stays in your hands")
	hands.stow().free()

	look(bare.global_position + Vector3(-1.4, 0.6, 0.0), bare.global_position)
	await simulate(0.1)
	check(_refused(hands.interact()), "use at a bare chassis piece has nothing to work")


## Whether take or use answered with a few words of why and the knock, from silence.
func _refused(answered: bool) -> bool:
	var said := answered and hands.notice != "" and hands.notice.split(" ").size() <= FEW \
		and hands._sound.stream == Sounds.REFUSE
	hands.notice = ""
	hands._sound.stream = null
	return said
