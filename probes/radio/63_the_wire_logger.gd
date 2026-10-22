extends ShieldProbe
## Radio probe 63: the wire logger. In the radio's misc bay it records what
## comes in: a god's words read through a dirty signal it plays back once
## they're done, from the set's own speaker, clean; heard clean, it lets them be.


func run() -> void:
	await load_storm(0.0)
	await beside_god(&"quartermaster")
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"wire_logger"], [0.0, 2.0]) as Radio
	radio.freeze = true
	radio.on = true
	radio.frequency = Radio.gods_of(world).carrier(&"quartermaster", world.time)
	var dirt := await _heard_once(radio)
	print("beside the Quartermaster, clear: dirt at most %.2f, played back %d" % [dirt, radio.played_back])
	check(dirt < tuning.logger_dirty and radio.played_back == 0, "heard clean, it lets them be")
	# A thin storm everywhere: its words come through dirty.
	weather_everywhere(0.2)
	radio._last_words = ""
	radio.spoken_at = -INF
	dirt = await _heard_once(radio)
	print("through a thin storm: dirt at most %.2f, played back %d" % [dirt, radio.played_back])
	check(dirt >= tuning.logger_dirty and radio.played_back == 1, "heard dirty, it plays them back once they're done")
	check(radio.reader.bus == Sounds.radio_bus(), "from the set's own speaker, clean of the storm")


## Ticks until it's read the god's next words over the air and anything after
## them; the dirtiest they came through.
func _heard_once(radio: Radio) -> float:
	var before := radio.spoken_count
	var dirt := 0.0
	for i in 60 * 60:
		await get_tree().physics_frame
		if radio.spoken_count > before:
			dirt = maxf(dirt, radio.dirt)
			if radio._lines.is_empty():
				break
	return dirt
