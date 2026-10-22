extends ShieldProbe
## Changing station discards its queued speech, even within one channel kind.


func run() -> void:
	await load_storm(0.0)
	Tuning.current().fm_margin_db = 1e6
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"fm_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.set_physics_process(false)
	radio.on = true
	radio.frequency = Radio.gods_of(world).carrier(&"quartermaster", world.time)
	radio._listen(0.0)
	radio._say_aloud("Temperature minus three.", true, world.time)
	check(not radio._lines.is_empty(), "AM station has speech queued")
	var previous := radio.spoken.duplicate()
	radio.switch_band()
	radio.fm_mhz = radio.fm_of(&"ledger")
	radio._listen(0.0)
	check(radio._spoken_station == &"ledger" and radio.spoken != previous and not radio._lines.is_empty(),
		"AM to FM god clears the previous station's words")
	previous = radio.spoken.duplicate()
	radio.fm_mhz = radio.fm_of(&"walker")
	radio._listen(0.0)
	check(radio._spoken_station == &"walker" and radio.spoken != previous and not radio._lines.is_empty(),
		"FM god to FM god clears the previous station's words")
	var count := radio.spoken_count
	var queue := radio._lines.duplicate()
	radio._listen(0.0)
	check(radio.spoken_count == count and radio._lines == queue,
		"remaining on the station preserves its speech queue and cadence")
