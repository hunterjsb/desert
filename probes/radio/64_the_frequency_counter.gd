extends ShieldProbe
## Radio probe 64: the frequency counter. In the radio's misc bay it reads the
## frequency exactly: tuned within counter_lock_khz of a carrier, the dial
## stands right on it; with nothing near, the dial goes where it's turned.


func run() -> void:
	await load_storm(0.0)
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var carrier := Radio.gods_of(world).carrier(&"ledger", world.time)
	radio.frequency = carrier - tuning.dial_notch_khz - 3.0
	radio.tune(1)
	var bare := radio.frequency
	radio.fit(Catalog.part(&"frequency_counter"), Scenarios._free(radio, &"radio_bay"))
	radio.frequency = carrier - tuning.dial_notch_khz - 3.0
	radio.tune(1)
	print("the Ledger at %.0f kHz: a notch from %.0f stands at %.0f bare, %.0f counted" % [carrier,
		carrier - tuning.dial_notch_khz - 3.0, bare, radio.frequency])
	check(bare != carrier and radio.frequency == carrier, "tuned near a carrier, the dial locks right on it")
	radio.frequency = 1100.0
	# A notch on its own, not a fast spin.
	radio._spun_at = -INF
	radio.tune(1)
	check(radio.frequency == 1100.0 + tuning.dial_notch_khz, "with nothing near, it goes where it's turned")
