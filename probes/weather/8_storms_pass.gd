extends Probe
## Wind & storms probe 8: for someone sitting still, most storms pass within a
## full base shield's charge, and longer ones exist. Twenty places watched for
## two days each.

## A full base shield's life in a storm (Bubble shield & camp PRD).
const SHIELD_SECONDS := 30.0 * 60.0
const STEP := 10.0


func run() -> void:
	var tuning := Tuning.current()
	var storms: Array[float] = []
	var stormy := 0
	var samples := 0
	for place in 20:
		var field := WeatherField.new(100 + place, tuning)
		var x := randf_range(-100000.0, 100000.0)
		var z := randf_range(-100000.0, 100000.0)
		var was := field.raw_storm_at(x, z, 0.0) > 0.0
		var since := -1.0
		var t := STEP
		while t < 2.0 * 24.0 * 3600.0:
			var now := field.raw_storm_at(x, z, t) > 0.0
			samples += 1
			if now:
				stormy += 1
			if now != was:
				# Only whole storms count: ones seen to start and end.
				if was and since >= 0.0:
					storms.append(t - since)
				since = t
				was = now
			t += STEP
	storms.sort()
	var passed := storms.filter(func(d: float) -> bool: return d <= SHIELD_SECONDS).size()
	print("%d storms, median %.1f min, longest %.1f min, %.0f%% within a shield's charge; stormy %.0f%% of the time"
		% [storms.size(), storms[storms.size() / 2] / 60.0, storms[-1] / 60.0,
			100.0 * passed / storms.size(), 100.0 * stormy / samples])
	check(storms.size() > 200, "enough storms to judge (%d)" % storms.size())
	check(passed > storms.size() * 0.5, "most storms pass within a shield's charge (%d of %d)" % [passed, storms.size()])
	check(passed < storms.size(), "and longer ones exist")
