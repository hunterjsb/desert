extends ShieldProbe
## Radio probe 31: broadcasts overlap on their skirts. Every broadcast is
## heard whole on its carrier, and near it at a share of its strength, so
## you hear it as you tune toward it and tune in on it; far off, nothing. A
## god heard off its carrier is still the one the dial hears, faint. Two
## broadcasts near each other on the dial, the relay's music and a satellite,
## are heard together between their carriers, each the louder nearer its own.
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

	# The music and the windsock, both overhead: heard together between them.
	var sky := Radio.constellation_of(world)
	var p := radio.point_at(x, z)
	var both := _first(t, func(u: float) -> bool:
		return sky.relay().seen_from(p, u).elevation > deg_to_rad(20.0) \
			and sky.orbits[&"windsock"].seen_from(p, u).elevation > deg_to_rad(20.0))
	world.time = both
	var windsock := sky.carrier(&"windsock", both)
	var between := roundf((Dial.MUSIC_KHZ + windsock) * 0.5)
	radio.frequency = between
	await physics_frames(5)
	var music: float = radio.receive_relay(x, z, both).clean
	var satellite: float = radio.sky.levels.get(&"windsock", 0.0)
	print("at %.0f s, tuned to %d kHz between the music (1020) and the windsock (%d): music %.2f, windsock %.2f" % [
		both, roundi(between), roundi(windsock), music, satellite])
	check(music > 0.0 and satellite > 0.0 and radio.music.playing and radio.sky.voice_of(&"windsock").playing,
		"between them, both are heard at once")
	radio.frequency = windsock
	await physics_frames(3)
	var on_windsock: float = radio.sky.levels.get(&"windsock", 0.0)
	check(on_windsock > satellite and radio.receive_relay(x, z, world.time).clean < music,
		"tuned onto the windsock, it's the louder and the music the fainter (%.2f)" % on_windsock)


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += 5.0
	check(false, "found a moment")
	return from
