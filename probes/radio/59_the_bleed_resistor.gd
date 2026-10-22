extends KiteProbe
## Radio probe 59: the bleed resistor. In the radio's misc bay it leaks a flown
## kite's charge off steadily: in a breeze, unearthed, the charge that would
## climb past an arc holds well under it.


func run() -> void:
	await load_storm(0.0, 9.0)
	var tuning := Tuning.current()
	var rig := await kite_rig(false)
	var radio: Radio = rig.radio
	var kite: AntennaKite = rig.kite
	radio.fit(Catalog.part(&"bleed_resistor"), _socket(radio, &"radio_bay"))
	check(radio.bleeds(), "it fits the misc bay")
	await fly_up(kite)
	world.time_warp = 20.0
	var most := 0.0
	for i in 60 * 60:
		await get_tree().physics_frame
		most = maxf(most, kite.charge)
	world.time_warp = 1.0
	var bare := tuning.kite_charge_fair * kite.height() / 100.0 * tuning.kite_air_tau
	print("bled: charge at most %.3f, %d arcs; unbled it would settle at %.2f" % [most, kite.arcs, bare])
	check(bare > tuning.kite_arc.x and most < tuning.kite_arc.x * 0.5 and kite.arcs == 0,
		"it holds the charge well under an arc")
