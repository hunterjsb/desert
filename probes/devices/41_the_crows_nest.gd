extends DeckProbe
## Devices & mods probe 41: the crow's nest seats you and sees farther. A
## crow's nest held over a standing mast's head sticks there, nowhere else;
## from the deck, use on its ladder climbs you in: a seat as the helm is,
## your eyes the mast's height over the deck and your weight high on the
## camp. From up there more of the ground round you shows over the crests:
## its height alone.

const STEPS := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(0, 1)], [&"piece", Vector2i(1, 1)],
	[&"stick", Vector2i(0, 0), &"top", Vector2(0.4, -0.4), 180.0, [&"mast", [&"sail"]], &"mast"]]
## Where the ground is looked over from each eye: this many bearings, this far, m.
const BEARINGS := 72
const FAR := 2500.0


func run() -> void:
	await load_lines()
	var built := Rig.build(world.content, STEPS, 1.0)
	var deck := built.deck
	var mast: Mast = built.named.mast
	deck.global_position = flat_spot(0.0, -6.0, 3.0) + Vector3.UP * 0.3
	await simulate(3.0)
	var nest := Catalog.device(&"crows_nest") as CrowsNest
	check(Stick.why_not(deck, deck, Chassis.TOP, nest) != "", "a crow's nest goes nowhere but a mast's head")
	var head := mast.global_transform * Vector3(0.0, Mast.HEAD_Y, 0.0)
	check(await stick_by_hand(nest, head, Vector3(0.9, 1.3, 0.3)) and nest.host() == mast,
		"held over the mast's head, it sticks there")
	var weight := deck.global_transform * deck.center_of_mass
	var ladder := nest.global_transform * Vector3(0.0, -0.5 - CrowsNest.LADDER * 0.6, -0.15)
	var top := deck.global_position.y + Chassis.THICK * 0.5
	look(Vector3(ladder.x, top + 1.6, ladder.z) + (ladder - mast.global_position).normalized().slide(Vector3.UP) * 1.2, ladder)
	await physics_frames(2)
	check(hands.interact() and world.player.helm == nest, "use on its ladder climbs you in, seated")
	await physics_frames(30)
	var up := eye().y - top
	var raised := (deck.global_transform * deck.center_of_mass).y - weight.y
	print("in the crow's nest your eyes are %.1f m over the deck, its middle %.2f m higher with you up there" % [up, raised])
	check(up > 5.0 and raised > 0.5, "your eyes are the mast's height over the deck, your weight high on it")
	var from_nest := _view(eye())
	var deck_eye := Vector3(ladder.x, top + 1.6, ladder.z)
	var from_deck := _view(deck_eye)
	print("from the crow's nest %.0f%% of the ground within %.0f m shows; from the deck %.0f%%"
		% [100.0 * from_nest, FAR, 100.0 * from_deck])
	check(from_nest > from_deck * 1.1, "from up there more of the ground shows")
	world.player.stand_up()


## The share of the ground out to FAR an eye (engine metres) sees, not
## hidden by the crests between.
func _view(eye_at: Vector3) -> float:
	var shape := world.shape
	var tuning := world.tuning
	var eye_w := Vector3(world.world_x(eye_at.x), eye_at.y, world.world_z(eye_at.z))
	var center := Vector2i(floori(eye_w.x / tuning.chunk_size), floori(eye_w.z / tuning.chunk_size))
	var shown := 0
	var looked := 0
	for k in BEARINGS:
		var way := Vector2.from_angle(TAU * k / BEARINGS)
		var steepest := -INF
		var d := 2.0
		while d < FAR:
			var at := Vector2(eye_w.x, eye_w.z) + way * d
			var slope := (Skyline.drawn(shape, tuning, center, at.x, at.y) - eye_w.y) / d
			looked += 1
			if slope >= steepest:
				shown += 1
				steepest = slope
			d = Skyline.next_look(d)
	return float(shown) / maxi(looked, 1)
