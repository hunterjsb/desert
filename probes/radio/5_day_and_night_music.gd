extends ShieldProbe
## Radio probe 5: day and night music. Through a whole day sat out in a
## bubble under a storm, a radio on the music channel plays "Sandy Andy" while
## the sun is above the horizon and "Waiting on the Sun" while it's below, and
## changes over just as the sun sets and rises, never by the storm's dark.

const WARP := 60.0
## One tick of the warped clock, and a little.
const TOLERANCE := 1.5

var _radio: Radio
var _was := -INF
var _last: AudioStream
var _changes := PackedFloat64Array()
var _wrong := PackedFloat64Array()
var _darkest_day := INF


func run() -> void:
	# FM carrying everywhere, so the port's music comes in.
	Tuning.current().fm_margin_db = 1e6
	await load_storm(1.0)
	_radio = Scenarios.standing(world, &"radio", [&"battery", &"fm_converter"], [0.0, 2.0]) as Radio
	_radio.channel = Radio.MUSIC
	shield_at(_radio.global_position + Vector3(1.0, 0.0, 0.0))
	await physics_frames(2)
	var start := world.time
	var seconds := world.tuning.day_minutes * 60.0 + 100.0
	_was = world.time
	_last = _radio.track()
	await live(seconds, WARP, _each)
	var crossings := _crossings(start, start + seconds)
	print("the sun crossed the horizon at %s s; the music changed at %s s" % [crossings, _changes])
	check(crossings.size() == 2, "a sunset and a sunrise in the day run")
	check(_changes.size() == crossings.size(), "the music changed over at each, and only then")
	for i in mini(crossings.size(), _changes.size()):
		check(absf(_changes[i] - crossings[i]) <= TOLERANCE,
			"changed over as the sun crossed (off by %.1f s)" % (_changes[i] - crossings[i]))
	check(_wrong.is_empty(), "the day's track while the sun is up, the night's while it's down (%d ticks wrong)" % _wrong.size())
	check(_darkest_day < 0.3, "the storm's dark at noon is still the day (%.0f%% light)" % (_darkest_day * 100.0))


## After each tick: what played over it, against the sun at the moment it read.
func _each() -> void:
	var up := world.weather.day.sun_direction(_was, world.moon.latitude, world.moon.longitude).y > 0.0
	var now := _radio.track()
	if now != (Sounds.RADIO_DAY if up else Sounds.RADIO_NIGHT):
		_wrong.append(_was)
	if now != _last:
		_changes.append(_was)
		_last = now
	if now == Sounds.RADIO_DAY:
		_darkest_day = minf(_darkest_day, world.weather.felt_light(_radio.global_position + Vector3.UP, _was))
	_was = world.time


## World times between from and to that the sun crosses the horizon.
func _crossings(from: float, to: float) -> PackedFloat64Array:
	var found := PackedFloat64Array()
	var latitude := world.moon.latitude
	var up := func(t: float) -> bool: return world.weather.day.sun_direction(t, latitude, world.moon.longitude).y > 0.0
	var t := from
	while t < to:
		if up.call(t) != up.call(t + 1.0):
			var lo := t
			var hi := t + 1.0
			while hi - lo > 0.001:
				var mid := (lo + hi) * 0.5
				if up.call(mid) == up.call(lo):
					lo = mid
				else:
					hi = mid
			found.append(hi)
		t += 1.0
	return found
