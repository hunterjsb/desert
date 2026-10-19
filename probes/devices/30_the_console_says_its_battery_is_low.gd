extends WeatherProbe
## Devices & mods probe 30: a Console with a radio on it says its battery is
## low. As its pool's charge falls past console_battery_low it logs it and,
## after its tones, says "Battery low." in the radio's voice, from the radio
## on its bus; once, until the charge is back over the line. Falling past
## console_battery_critical it says "Battery critical." With Options' Radio
## voice off it only logs it.


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var made := Scenarios.standing(world, &"console", [&"big_battery", &"screen"], [0.0, 3.0]) as Console
	var radio := Catalog.device(&"radio") as Radio
	world.content.add_child(radio)
	made.mount(radio, Scenarios._free(made, &"top"))
	made.freeze = true
	await physics_frames(10)
	var tuning := Tuning.current()

	_charge(made, tuning.console_battery_low + 0.05)
	await _heard(made, radio, "")
	_charge(made, tuning.console_battery_low - 0.02)
	var low := await _heard(made, radio, "Battery low.")
	print("at %.0f%%: \"%s\"" % [world.power.pool_share(made) * 100.0, low])
	check(low.begins_with("!BATTERY LOW"), "falling past the low line, it logs it and says so from its radio")
	check(await _heard(made, radio, "") == "", "once")
	_charge(made, tuning.console_battery_critical - 0.02)
	check((await _heard(made, radio, "Battery critical.")).begins_with("!BATTERY CRITICAL"), "and past the critical line")

	_charge(made, tuning.console_battery_low + 0.05)
	await _heard(made, radio, "")
	Settings.radio_voice = false
	_charge(made, tuning.console_battery_low - 0.02)
	check((await _heard(made, radio, "")).begins_with("!BATTERY LOW"), "back over it, it says it again; with the Radio voice off, only in its log")
	Settings.radio_voice = true


## Its pool's batteries all at a share of full.
func _charge(made: Console, share: float) -> void:
	for each: Device in world.power.pool_of(made):
		for cell in each.pooled():
			cell.charge_wh = cell.capacity() * share


## Waits out a few of the Console's reads and its tones: the line it logged
## meanwhile ("" for none), checking its radio said `aloud`, or nothing.
func _heard(made: Console, radio: Radio, aloud: String) -> String:
	var before := made.log_lines.size()
	var spoke: AudioStream = null
	for i in roundi(Engine.physics_ticks_per_second * (Tuning.current().console_read_every * 2.0 + 1.5)):
		await get_tree().physics_frame
		if radio.reader.playing:
			spoke = radio.reader.stream
	var said := "" if made.log_lines.size() == before else String(made.log_lines[-1].text)
	check(spoke == (Radio.clip(aloud) if aloud != "" else null) and radio.reader.bus == Sounds.RADIO,
		"%s, %s" % [said if said != "" else "nothing logged", "\"%s\" said" % aloud if aloud != "" else "nothing said"])
	return said
