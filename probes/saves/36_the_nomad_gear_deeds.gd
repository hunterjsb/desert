extends WreckProbe
## Profile & saves probe 36: the nomads' gear's deeds, through play. Taking
## the mast off a wrecked nomad rig, its sail on it, is Hand-Me-Down;
## stepping into a nomads' camp, Just Missed Them, ???? till then; trimming
## a raised sail's sheet with a streamer flying on its rig, Telltale, and
## not without one.


func run() -> void:
	await load_salvage()
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var spot := open_sand()
	var wreck := await wreck_at(&"nomad_rig", spot.x, spot.y)
	if wreck == null:
		return
	var mast: Mast = null
	for body in salvage.finds():
		if body is Mast and site_of(body) == wreck.site:
			mast = body
	check(mast != null, "its mast lies beside it")
	if mast == null:
		return
	check(not profile.did("hand_me_down"), "not yet")
	# At its pole, under where the boom swings: taken hold of there, the whole mast comes.
	face(mast.global_transform * Vector3(0.0, -0.35, 0.0), mast.global_basis.x, 1.2)
	await physics_frames(2)
	hands.grab()
	await physics_frames(20)
	check(profile.did("hand_me_down"), "its mast and sail taken: Hand-Me-Down")
	hands.drop()
	await physics_frames(10)

	check(Deeds.TABLE.just_missed.get("hidden", false), "Just Missed Them is ???? till it's done")
	var camp: Structure = null
	for tries in 150:
		var off := Vector2.from_angle(tries * 2.39996) * 7.0 * sqrt(tries)
		camp = world.shape.sites.by_hand(&"nomad_camp", spot.x + 200.0 + off.x, spot.y + off.y, 0.2, 0.0)
		if camp.stands():
			break
	world.shape.sites.add(camp)
	teleport(camp.x, camp.z)
	await physics_frames(5)
	check(profile.did("just_missed"), "stepped into a nomads' camp: Just Missed Them")
	# New loose gear must wait for the destination's ground, too. Five
	# physics ticks alone need not finish streaming on another machine.
	await settle_finds()

	var deck := Catalog.device(&"chassis") as Chassis
	world.content.add_child(deck)
	deck.global_position = Vector3(world.player.global_position.x + 3.0, 0.0, world.player.global_position.z)
	deck.global_position.y = world.height_under(deck.global_position) + 0.2
	# The distant wreck can unload after visiting the camp; trim a fresh rig
	# here rather than depending on its dropped salvage remaining resident.
	mast = Rig.make([&"mast", [&"sail"]]) as Mast
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, PI, mast)
	await physics_frames(60)
	check(is_instance_valid(mast), "the trim rig remains on the settled ground")
	if not is_instance_valid(mast):
		return
	mast.raised = true
	mast.raise = 1.0
	Line.to_waist(world, mast._tie(), 1.0)
	await physics_frames(5)
	mast._haul(0.25)
	check(not profile.did("telltale"), "trimming with no streamer on the rig is no Telltale")
	var streamer := Catalog.device(&"streamer")
	Stick.put(deck, deck, Chassis.TOP, Vector2(0.3, 0.3), 0.0, streamer)
	await physics_frames(5)
	mast._haul(0.25)
	check(profile.did("telltale"), "trimmed with a streamer flying on it: Telltale")
