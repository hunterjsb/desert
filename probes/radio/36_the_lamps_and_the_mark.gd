extends ShieldProbe
## Radio probe 36: the signal lamps and the mark's name. Nothing on the radio
## is written but its frequency, so its face shows what it hears by its row of
## lamps: tuned onto the music at night, nearly all lit; between
## carriers with nothing near, none; switched off, all dark. On a frequency
## you've marked, the look-at line names the mark after the frequency. The
## wheel spun fast goes farther a notch each time, up to dial_spin_most, and
## back to a notch once it rests; fine steps never speed up. Under clear
## skies everywhere.


func run() -> void:
	await load_storm(0.0)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var high := _first(world.time, func(u: float) -> bool: return not world.weather.day.is_day(u, world.moon.longitude))
	world.time = high
	radio.on = true
	radio.frequency = Dial.MUSIC_KHZ
	await physics_frames(40)
	var on_music := _lit(radio)
	print("on the music at night: %.2f heard, %d of %d lamps lit" % [radio.lamp_level, on_music, Radio.LAMPS])
	check(on_music >= Radio.LAMPS - 2, "tuned onto the music at night, nearly all lit")

	# The quietest place on the dial now: as far as can be from every carrier.
	var all := radio.carriers()
	all.push_front(Dial.LOWEST)
	all.append(Dial.HIGHEST)
	var gap := 0.0
	var quiet := 0.0
	for i in all.size() - 1:
		if all[i + 1] - all[i] > gap:
			gap = all[i + 1] - all[i]
			quiet = (all[i] + all[i + 1]) * 0.5
	radio.frequency = roundf(quiet)
	await physics_frames(40)
	print("at %d kHz, %.0f kHz from anything: %.2f heard, %d lit" % [roundi(radio.frequency), gap * 0.5, radio.lamp_level,
		_lit(radio)])
	check(_lit(radio) == 0, "between carriers with nothing near, none lit")

	radio.frequency = Dial.MUSIC_KHZ
	await physics_frames(40)
	radio.on = false
	await physics_frames(40)
	check(_lit(radio) == 0 and radio.lamp_level < 0.02, "switched off, all dark")

	# A marked frequency named in the look-at line.
	radio.on = true
	radio.frequency = 1040.0
	check(Hands.describe("Radio", radio.stats()).ends_with("1040 kHz"), "unmarked, the frequency alone")
	Profile.mark(1040.0, "Windsock", Color.CYAN, 1.0)
	print("marked: \"%s\"" % Hands.describe("Radio", radio.stats()))
	check(radio.stats().tuned == "1040 kHz · Windsock", "marked, the look-at line names the mark too")
	radio.frequency = 1042.0
	check(radio.stats().tuned == "1042 kHz · Windsock", "and within a carrier's width of it")
	radio.frequency = 1060.0
	check(radio.stats().tuned == "1060 kHz", "but not farther")

	# The wheel spun fast.
	var tuning := Tuning.current()
	var notch := tuning.dial_notch_khz
	radio.frequency = 500.0
	var went: Array[float] = []
	for k in 7:
		var from := radio.frequency
		radio.tune(1)
		went.append(radio.frequency - from)
	print("spun fast, notch by notch: %s kHz" % [went])
	check(went[0] == notch and went[1] == notch * (1.0 + tuning.dial_spin_grow) and went[6] == notch * minf(1.0 + 6.0 * tuning.dial_spin_grow, tuning.dial_spin_most),
		"spun fast, each notch goes farther, up to dial_spin_most")
	await get_tree().create_timer(tuning.dial_spin_seconds * 2.0).timeout
	var rest := radio.frequency
	radio.tune(1)
	check(radio.frequency - rest == notch, "rested, a notch is a notch again")
	radio.tune(-1)
	check(rest + notch - radio.frequency == notch, "turned back the other way, a notch")
	rest = radio.frequency
	for k in 4:
		radio.tune(1, true)
	check(radio.frequency - rest == tuning.dial_fine_khz * 4.0, "fine steps never speed up")


## How many of its lamps are lit, more than half way.
func _lit(radio: Radio) -> int:
	var n := 0
	for lamp in radio._lamps:
		var paint := (lamp.mesh as BoxMesh).material as StandardMaterial3D
		if paint.albedo_color.get_luminance() > 0.3:
			n += 1
	return n


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += 5.0
	check(false, "found a moment")
	return from
