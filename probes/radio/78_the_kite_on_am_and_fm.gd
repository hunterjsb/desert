extends KiteProbe
## Radio probe 78: the kite on AM and FM (gonkhub, 2026-10-22). A kite flown on
## the set's lead is its aerial on every band. On the AM dial a god comes in
## stronger, as on a long wire hung high, and heard all ways round, with no
## null. On FM, out past where the set's own whip loses Port Morgan's station
## behind the moon's curve, the kite's height brings it back.
## Time limit: 600 s.

## How far from the port's middle the FM test stands, m, toward Tu.
const OUT := 4500.0


func run() -> void:
	await load_storm(0.0, 9.0)
	var tuning := Tuning.current()
	var rig := await kite_rig(false)
	var radio: Radio = rig.radio
	var kite: AntennaKite = rig.kite
	radio.on = true
	await physics_frames(2)
	check(radio.band == Radio.AM_BAND, "the radio on the AM dial")
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var gods := Radio.gods_of(world)
	radio.frequency = gods.carrier(&"quartermaster", world.time)
	# Stood on its end, its rod hears every way alike: no null to flatter the kite.
	radio.global_basis = Basis(Vector3.BACK, PI / 2.0)
	check(is_equal_approx(radio.rod(0.0, false), 1.0), "stood on its end, the rod has no null")
	var bare: Dictionary = radio.receive(&"quartermaster", x, z, world.time)
	await fly_up(kite)
	check(kite.up() and kite.height() > 50.0, "the kite flies high (%.0f m)" % kite.height())
	var flown: Dictionary = radio.receive(&"quartermaster", x, z, world.time)
	print("the Quartermaster %.3f on the rod, %.3f on the kite" % [bare.strength, flown.strength])
	check(flown.strength > bare.strength * 1.5, "on the AM dial a god comes in stronger")
	radio.global_basis = Basis.IDENTITY
	check(is_equal_approx(radio.rod(0.0, false), 1.0) and is_equal_approx(radio.rod(90.0, false), 1.0),
		"lying flat on the kite, heard all ways round, with no null")

	# Out past the whip's horizon from Port Morgan.
	var history := world.shape.history
	var port: Vector3 = history.landmark(&"port_morgan").p
	var at := Sphere.toward(port, Sphere.bearing(port, history.sub_tu), OUT / history.radius)
	world.travel(rad_to_deg(Sphere.latitude(at)), rad_to_deg(Sphere.longitude(at)), 0.0)
	await settle()
	weather_everywhere(0.0, 9.0)
	rig = await kite_rig(false)
	radio = rig.radio
	kite = rig.kite
	radio.fit(Catalog.part(&"fm_converter"), _socket(radio, &"radio_mod"))
	radio.on = true
	radio.switch_band()
	check(radio.band == Radio.FM_BAND, "a radio on FM %.0f m from the port" % OUT)
	radio.fm_mhz = radio.fm_of(&"port_fm")
	x = world.world_x(radio.global_position.x)
	z = world.world_z(radio.global_position.z)
	var whip: Dictionary = radio.receive_fm(x, z, world.time)
	await fly_up(kite)
	var aloft: Dictionary = radio.receive_fm(x, z, world.time)
	print("Port Morgan's station %.0f m off: %.1f dB on the whip, %.1f dB on the kite %.0f m up" % [OUT,
		whip.get("margin", -INF), aloft.get("margin", -INF), kite.height()])
	check(whip.get("margin", -INF) < tuning.fm_threshold_db, "on its own whip it's lost in the noise")
	check(aloft.get("margin", -INF) >= tuning.fm_threshold_db, "on the kite it comes through")
