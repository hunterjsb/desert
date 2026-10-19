extends DeckProbe
## Devices & mods probe 41: the crow's nest seats you and sees farther. A
## crow's nest held over a standing mast's head sticks there, nowhere else;
## from the deck, use on its ladder climbs you in: a seat as the helm is,
## your eyes the mast's height over the deck and your weight high on the
## camp. From up there more of the ground round you shows over the crests,
## and more of what history left in sight: its height alone.

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
	print("from the crow's nest %.0f%% of the ground within %.0f m shows and %d of %d sites in sight; from the deck %.0f%% and %d"
		% [100.0 * from_nest.ground, FAR, from_nest.sites, from_nest.of, 100.0 * from_deck.ground, from_deck.sites])
	check(from_nest.ground > from_deck.ground * 1.1 and from_nest.sites >= from_deck.sites,
		"from up there more of the ground shows, and no less of what's in sight")
	world.player.stand_up()


## What an eye (engine metres) sees round it: the share of the ground out to
## FAR not hidden by the crests between, and the sites in sight whose tops do.
func _view(eye_at: Vector3) -> Dictionary:
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
	var sites := 0
	var of := 0
	var laid: Array[Structure] = []
	for unit in world.shape.sites.units():
		for each in unit.sites:
			if each is Structure and not (each as Structure).piece.glints.is_empty():
				laid.append(each)
	for site in laid:
		if Vector2(site.x - eye_w.x, site.z - eye_w.z).length() < 30.0 \
				or Vector2(site.x - eye_w.x, site.z - eye_w.z).length() > FAR:
			continue
		of += 1
		var tops: Array[Vector3] = []
		for glint: Array in site.piece.glints:
			tops.append(site.frame() * (glint[0] as Vector3))
		if tops.is_empty():
			tops.append(Vector3(site.x, site.floor_y + 2.0, site.z))
		if tops.any(func(p: Vector3) -> bool: return Skyline.clearance(shape, tuning, eye_w, p, center, site.reach) >= 0.0):
			sites += 1
	return {"ground": float(shown) / maxi(looked, 1), "sites": sites, "of": of}
