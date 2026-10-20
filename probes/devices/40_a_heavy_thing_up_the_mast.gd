extends DeckProbe
## Devices & mods probe 40: a mast takes things stuck on it, and a heavy one
## up high raises its camp's middle. Two decks two by two floating on their
## trays, each with its mast standing: a big battery stuck low on the first
## deck's top, and on the second held to the pole high up, where it sticks.
## The second's middle stands higher by what that weight there says, and the
## same push heels it further. Nothing tall goes on a mast, and a mast with
## something on it won't come off its deck till that's off.

const STEPS := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)],
	[&"stick", Vector2i(0, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 0), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(0, 1), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(1, 1), &"bottom", Vector2.ZERO, 0.0, &"hover_tray"],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.4, -0.4), 180.0, [&"mast", [&"sail"]], &"mast"],
	[&"stick", Vector2i(1, 1), &"top", Vector2.ZERO, 0.0, &"battery"],
	[&"stick", Vector2i(0, 1), &"top", Vector2.ZERO, 0.0, &"battery"]]
const LOW := [&"stick", Vector2i(0, 0), &"top", Vector2(0.05, -0.4), 0.0, &"big_battery"]
## Up the pole, m over the mast's middle.
const HIGH := 3.2
## The push that heels it, N·m about its length, for this long, s.
const PUSH := 300.0
const PUSH_SECONDS := 0.6


func run() -> void:
	await load_lines()
	var at := flat_spot(0.0, -6.0, 3.0)
	var low_deck := await _deck(at, STEPS + [LOW])
	var heel_low := await _heel(low_deck)
	var beside := at + Vector3(14.0, 0.0, 0.0)
	beside.y = world.height_under(beside)
	var deck := await _deck(beside, STEPS)
	var mast: Mast = null
	for each in deck.mounted():
		if each is Mast:
			mast = each
	check(mast.standing() and deck.stats().hovering, "the mast stands on the floating deck")
	var battery := Catalog.part(&"big_battery")
	var on := mast.global_transform * Vector3(Mast.POLE_R, HIGH, 0.0)
	var stuck := await stick_by_hand(battery, on, mast.global_basis.x * 1.4 + Vector3.UP * 0.2)
	check(stuck and battery.socket != null and battery.socket.get_parent() == mast,
		"a big battery held to the pole high up sticks on the mast")
	await simulate(2.0)
	var kg := battery.mass
	var rose := deck.center_of_mass.y - low_deck.center_of_mass.y
	var up := deck.to_local(mast.to_global(Vector3(Mast.POLE_R, HIGH, 0.0))).y
	var expected := kg * (up - low_deck.to_local(_low_battery(low_deck)).y) / deck.mass
	print("its camp's middle stands %.3f m higher with %.0f kg up the mast than low on its deck (%.3f m by its weight)"
		% [rose, kg, expected])
	check(rose > 0.75 * expected and rose < 1.25 * expected, "the camp's middle rises by its weight up there (%.3f m)" % rose)
	var heel_high := await _heel(deck)
	print("the same push heels it %.1f° with the battery up the mast, %.1f° low on the deck" % [heel_high, heel_low])
	check(heel_high > heel_low * 1.15, "and it heels further (%.1f° against %.1f°)" % [heel_high, heel_low])

	check(Stick.why_not(mast, mast, &"front", Catalog.device(&"console")) != "", "nothing tall goes on a mast")
	look(mast.global_position + mast.global_basis.z * 1.0 + Vector3.UP * 0.2, mast.global_position)
	await physics_frames(2)
	hands.grab()
	await physics_frames(10)
	check(mast.host() == deck, "a mast with something on it stays on its deck")


## A deck built from steps, floating over a place, settled with its mast up.
func _deck(at: Vector3, steps: Array) -> Chassis:
	var built := Rig.build(world.content, steps, 1.0)
	built.deck.global_position = at + Vector3.UP * (built.deck.rest_height() + 0.05)
	await simulate(3.0)
	return built.deck


## Where the big battery on a deck's top sits, in the world.
func _low_battery(deck: Chassis) -> Vector3:
	for socket in deck.stuck():
		if socket.part != null and socket.part.get_meta(&"catalog", &"") == &"big_battery":
			return deck.global_transform * socket.transform * Vector3(0.0, 0.0, 0.09)
	return deck.global_position


## The most a push about its length heels it from how it settled, degrees.
func _heel(deck: Chassis) -> float:
	await simulate(2.0)
	var axis := -deck.global_basis.z
	var rest := deck.global_basis.y.normalized()
	var seen := {"most": 0.0, "t": 0.0}
	await simulate(4.0, func() -> void:
		seen.t += 1.0 / 60.0
		if seen.t < PUSH_SECONDS:
			deck.apply_torque(axis * PUSH)
		seen.most = maxf(seen.most, rad_to_deg(deck.global_basis.y.normalized().angle_to(rest))))
	return seen.most
