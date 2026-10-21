extends WeatherProbe
## Radio probe 58: each band holds its own. The AM dial carries only the far
## gods and the beacon, and the wrecks calling SOS near 500 kHz; FM carries
## Port Morgan Tower, the port's music, the living city's chatter and music
## and the near gods, each on its own frequency; on shortwave the relay
## repeats the tower, so the clear scenario's radio, far from the port, hears
## the weather there on its wire.
## Time limit: 300 s


func run() -> void:
	await load_weather()
	var gods := Radio.gods_of(world)
	var am: Array = Dial.carriers(gods, world.time).map(func(each: Array) -> StringName: return each[1])
	print("AM: %s" % [am])
	check(am.size() == 5 and am.has(&"beacon") and not am.any(func(id: StringName) -> bool: return Fm.is_god(id)),
		"the AM dial has only the far gods and the beacon")
	var fm := Fm.stations(gods, world.run_seed, Tuning.current(), world.time)
	var ids: Array = fm.map(func(each: Dictionary) -> StringName: return each.id)
	print("FM: %s" % [fm.map(func(each: Dictionary) -> String: return "%s %.1f" % [each.id, each.mhz])])
	var apart := true
	for i in range(1, fm.size()):
		apart = apart and fm[i].mhz - fm[i - 1].mhz >= Fm.APART - 0.01
	check(ids.size() == 7 and ids.has(Fm.TOWER) and ids.has(Fm.CITY_MUSIC) and Fm.GODS.all(func(id: StringName) -> bool:
		return ids.has(id)) and apart, "FM has the tower, the port, the city's two and the near gods, apart")

	# A wreck that calls: heard near it, SOS and its fix.
	var call := {}
	for unit in world.shape.sites.units():
		for site: Site in unit.sites:
			if call.is_empty() and site.kind in Distress.KINDS and Distress.calling(world.run_seed, site, Tuning.current()):
				var near := Distress.calls(world, site.x + 300.0, site.z, Tuning.current())
				if not near.is_empty():
					call = near[0]
	print("a call: %s" % [call])
	check(not call.is_empty() and absf(call.khz - Distress.KHZ) <= Tuning.current().distress_spread_khz
		and Distress.strength(call.khz, 300.0, Tuning.current()) > Tuning.current().signal_floor
		and Distress.words(call.p).begins_with("S O S"), "a wreck calls SOS near 500 kHz, its fix after")

	# The clear scenario's radio hears the tower through the relay on its wire.
	await Scenarios.apply(world, Scenarios.by_key("clear"))
	var radio := (world.get_meta(&"scenario_kit") as Array)[0] as Radio
	radio.freeze = true
	await physics_frames(120)
	print("on %s at %.0f kHz: \"%s\"" % [radio.band, radio.frequency, radio.said])
	check(radio.band == Radio.SW_BAND and radio.channel == Radio.WEATHER and radio.said.contains("Port Morgan Tower"),
		"on shortwave the relay repeats Port Morgan Tower")
