extends ShieldProbe
## Radio probe 31: broadcasts overlap on their skirts. Every broadcast is
## heard whole on its carrier, and near it at a share of its strength, so
## you hear it as you tune toward it and tune in on it; far off, nothing. A
## god heard off its carrier is still the one the dial hears, faint. Two
## broadcasts near each other on the dial, two satellites
## side by side on shortwave, are heard together between their carriers, each
## the louder nearer its own.
## Under clear skies everywhere.


func run() -> void:
	await load_storm(0.0)
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)

	# The shape of it: whole on the carrier, a share on its skirt, nothing far off.
	var near := Dial.heard(10.0, tuning)
	print("heard on the carrier %.2f, 10 kHz off %.2f, 50 kHz off %.4f" % [Dial.heard(0.0, tuning), near,
		Dial.heard(50.0, tuning)])
	check(Dial.heard(0.0, tuning) == 1.0, "whole on its carrier")
	check(near > tuning.dial_skirt_share * 0.5 and near < tuning.dial_skirt_share, "a share of it near its carrier")
	check(Dial.heard(50.0, tuning) < 0.01, "and nothing far off")

	# A god off its carrier: faint, and still the one the dial hears.
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var gods := Radio.gods_of(world)
	var t := world.time
	var best := &""
	var strongest := 0.0
	for id in Gods.ids():
		radio.frequency = gods.carrier(id, t)
		var got: float = radio.receive(id, x, z, t).strength
		if got > strongest:
			strongest = got
			best = id
	radio.on = true
	var home := gods.carrier(best, t)
	radio.frequency = home
	var on_it: float = radio.receive(best, x, z, t).clean
	radio.frequency = home + 12.0
	var off_it: float = radio.receive(best, x, z, t).clean
	print("%s: clean %.2f on its carrier, %.2f 12 kHz off" % [Gods.title(best), on_it, off_it])
	check(off_it > 0.0 and off_it < on_it and radio.tuned_to() == best,
		"12 kHz off %s it's heard faint, and it's still the one the dial hears" % Gods.title(best))
	radio.frequency = home + Dial.reach(tuning) + 15.0
	check(radio.tuned_to() != best, "past its skirt it's gone")

	# Two satellites side by side at 29 MHz, both overhead: heard together
	# between them on shortwave.
	Scenarios.fill(world, radio, [&"sw_converter"])
	radio.switch_band()
	check(radio.band == Radio.SW_BAND, "with a shortwave converter it's on shortwave")
	var sky := Radio.constellation_of(world)
	var p := radio.point_at(x, z)
	var side := ["sextant", "windsock", "choir", "babel", "metronome"]
	var pair := []
	var both := _first(t, func(u: float) -> bool:
		for i in side.size() - 1:
			if sky.orbits[StringName(side[i])].seen_from(p, u).elevation > deg_to_rad(20.0) 					and sky.orbits[StringName(side[i + 1])].seen_from(p, u).elevation > deg_to_rad(20.0) 					and not &"babel" in [StringName(side[i]), StringName(side[i + 1])]:
				pair.assign([StringName(side[i]), StringName(side[i + 1])])
				return true
		return false)
	world.time = both
	var a: StringName = pair[0]
	var b: StringName = pair[1]
	var a_khz := sky.carrier(a, both)
	var b_khz := sky.carrier(b, both)
	var between := roundf((a_khz + b_khz) * 0.5)
	radio.frequency = between
	await physics_frames(5)
	var one: float = radio.sky.levels.get(a, 0.0)
	var other: float = radio.sky.levels.get(b, 0.0)
	print("at %.0f s, tuned to %d kHz between the %s (%d) and the %s (%d): %.2f and %.2f" % [
		both, roundi(between), a, roundi(a_khz), b, roundi(b_khz), one, other])
	check(one > 0.0 and other > 0.0 and radio.sky.voice_of(a).playing and radio.sky.voice_of(b).playing,
		"between them, both are heard at once")
	radio.frequency = a_khz
	await physics_frames(3)
	var on_a: float = radio.sky.levels.get(a, 0.0)
	check(on_a > one and radio.sky.levels.get(b, 0.0) < other,
		"tuned onto the %s, it's the louder and the %s the fainter (%.2f)" % [a, b, on_a])

func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += 5.0
	check(false, "found a moment")
	return from
