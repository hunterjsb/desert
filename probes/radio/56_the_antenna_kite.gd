extends WeatherProbe
## Radio probe 56: the antenna kite. Used on a reel clipped to a shortwave set
## in a breeze, it goes up its line tens of metres and the set hears farther
## by it; an earth stake by the reel dumps its charge to ground; with no
## stake, a charged rig arcs and burns a piece out; reeled in, it comes down.
## Time limit: 300 s


func run() -> void:
	await load_weather()
	await Scenarios.apply(world, Scenarios.by_key("kite"))
	var dropped: Array = world.get_meta(&"scenario_kit")
	var radio := dropped[0] as Radio
	var reel := dropped[1] as AntennaReel
	var stake := dropped[2] as EarthStake
	var kite := dropped[3] as AntennaKite
	radio.freeze = true
	reel.freeze = true
	world.counts_deeds = true
	await physics_frames(5)
	var bare := radio.antenna_gain()
	check(kite.use(world.player, reel.global_position) and kite.flying(), "used on the reel in a breeze, it flies")
	await physics_frames(600)
	await physics_frames(30)
	print("up %.0f m on %.0f m of line; shortwave gain %.2f bare, %.2f by the kite" % [kite.height,
		kite.line_m(), bare, radio.antenna_gain()])
	check(kite.height > 40.0 and radio.antenna_gain() > bare * 2.0, "it stands tens of metres up and the set hears farther")

	# Earthed: the stake's gap takes the charge.
	kite.charge = 0.9
	await physics_frames(300)
	print("earthed, its charge falls to %.2f; Grounded %s" % [kite.charge, Profile.did("grounded")])
	check(kite.charge < 0.3 and Profile.did("grounded"), "an earth stake by the reel dumps its charge to ground")

	# Unearthed: carried off, the stake earths nothing, and an arc burns something out.
	stake.global_position += Vector3(40.0, 0.0, 0.0)
	var burnt := false
	for i in 60:
		if kite.flying():
			kite.charge = 0.9
		await physics_frames(30)
		burnt = kite.wrecked() or reel.wrecked() or radio.wrecked() or radio.converter(&"sw") == null
		if burnt:
			break
	print("unearthed: kite %s, reel %s, converter %s, set %s" % [kite.wrecked(), reel.wrecked(),
		radio.converter(&"sw") == null, radio.wrecked()])
	check(burnt, "unearthed, a charged rig arcs and burns a piece out")

	if kite.flying():
		reel.reel_in()
	await physics_frames(2)
	check(not kite.flying(), "reeled in or burnt, it comes down")
