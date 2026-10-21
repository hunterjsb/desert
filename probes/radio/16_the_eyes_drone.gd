extends ShieldProbe
## Radio probe 16: the Eye's drones. The Eye's frequency begins a run silent;
## after a silence of between eye_quiet_minutes, the seed's pick, one of its
## two drones, the seed's pick too, plays through once, it falls silent again
## for another such pick, and plays again. Over a run both drones come. Between
## drones there's nothing on its frequency, not even tones.
## At night, when the Eye comes down by sky wave, the drone is heard; in its
## silence, tuned to the Eye, it isn't.

const STEP := 1.0


func run() -> void:
	await load_storm(0.0)
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	var drones: Array = Radio.SONGS[&"eye"]
	var lengths: Array[float] = []
	for each: AudioStream in drones:
		lengths.append(each.get_length())
	var quiet := tuning.eye_quiet_minutes * 60.0

	var first := _first(0.0, func(t: float) -> bool: return gods.song(&"eye", t, lengths).y >= 0.0)
	var which := roundi(gods.song(&"eye", first, lengths).x)
	var ends := _first(first, func(t: float) -> bool: return gods.song(&"eye", t, lengths).y < 0.0)
	var again := _first(ends, func(t: float) -> bool: return gods.song(&"eye", t, lengths).y >= 0.0)
	print("the Eye's drone: first at %.0f s, drone %d, %.0f s long, again at %.0f s" % [first, which, ends - first, again])
	check(first >= quiet.x - STEP and first <= quiet.y + STEP, "it begins silent, %.1f min, within eye_quiet_minutes" % (first / 60.0))
	check(absf(ends - first - lengths[which]) <= STEP, "its drone plays through once")
	check(again - ends >= quiet.x - STEP and again - ends <= quiet.y + STEP, "then falls silent again for another pick")
	# Over twenty plays, each drone comes, each through to its own end.
	var heard := {}
	var whole := true
	var t := first
	for k in 20:
		var play := gods.song(&"eye", t, lengths)
		var n := roundi(play.x)
		heard[n] = heard.get(n, 0) + 1
		var done := _first(t, func(u: float) -> bool: return gods.song(&"eye", u, lengths).y < 0.0)
		whole = whole and absf(done - t - lengths[n]) <= STEP
		t = _first(done, func(u: float) -> bool: return gods.song(&"eye", u, lengths).y >= 0.0)
	print("over twenty plays: %s" % heard)
	check(heard.size() == drones.size(), "both drones come, the seed's pick each time")
	check(whole, "each plays through to its own end")

	# At night, during a drone, tuned to the Eye: heard.
	var day := world.weather.day
	var lon := world.moon.longitude
	var night := _first(0.0, func(t: float) -> bool:
		var play := gods.song(&"eye", t, lengths)
		return not day.is_day(t, lon) and play.y > 2.0 and play.y < lengths[maxi(roundi(play.x), 0)] - 5.0)
	radio.on = true
	world.time = night
	radio.frequency = gods.carrier(&"eye", night)
	await physics_frames(5)
	var playing: AudioStream = drones[roundi(gods.song(&"eye", night, lengths).x)]
	var audible_tick := false
	var loudest := -INF
	# A dirty sky wave can drop briefly; listen through its ordinary interference.
	for tick in 30:
		await physics_frames(1)
		loudest = maxf(loudest, radio.music.volume_db)
		audible_tick = audible_tick or (radio.tuned_to() == &"eye" and radio.on_air() == playing and radio.music.volume_db > -20.0)
	print("at night, mid-drone (%.0f s): on air %s, loudest %.1f dB, \"%s\"" % [night, radio.on_air(), loudest, radio.said])
	check(audible_tick, "at night its drone comes down by sky wave")
	var silent := _first(night, func(u: float) -> bool: return gods.song(&"eye", u, lengths).y < 0.0)
	world.time = silent + 1.0
	radio.frequency = gods.carrier(&"eye", world.time)
	await physics_frames(5)
	check(radio.on_air() == null and not radio.music.playing, "in its silence, nothing on its frequency")


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += STEP
	check(false, "found a moment")
	return from
