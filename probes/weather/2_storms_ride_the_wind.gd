extends Probe
## Wind & storms probe 2: fronts move with the prevailing wind. Along a line
## downwind, find a front, look again half a minute later, and measure how far
## it went; over many fronts that matches the wind's own speed.

const LATER := 30.0
const SEARCH := 3000.0
const STEP := 10.0


func run() -> void:
	var field := WeatherField.new(11, Tuning.current())
	var ratios: Array[float] = []
	var tries := 0
	while ratios.size() < 200 and tries < 2000:
		tries += 1
		var t := randf_range(0.0, 3.0 * 24.0 * 3600.0)
		var start := Vector2(randf_range(-100000.0, 100000.0), randf_range(-100000.0, 100000.0))
		var wind := (field.prevailing_at(t) + field.prevailing_at(t + LATER)) * 0.5
		var along := wind.normalized()
		var before := _crossing_near(field, start, along, 0.0, t)
		if is_nan(before):
			continue
		var after := _crossing_near(field, start, along, before, t + LATER)
		if is_nan(after):
			continue
		ratios.append((after - before) / (wind.length() * LATER))
	ratios.sort()
	check(ratios.size() == 200, "found 200 fronts to follow (%d)" % ratios.size())
	var median := ratios[ratios.size() / 2]
	var close := ratios.filter(func(r: float) -> bool: return absf(r - 1.0) < 0.3).size()
	print("front speed / wind speed: median %.3f, %d of %d within 30%%" % [median, close, ratios.size()])
	check(absf(median - 1.0) < 0.1, "fronts move at the wind's speed (median ratio %.3f)" % median)
	check(close >= ratios.size() * 0.8, "nearly all of them do (%d of %d within 30%%)" % [close, ratios.size()])


## The threshold crossing on the line start + along * s nearest to s = near,
## or NAN if there's none within the search.
func _crossing_near(field: WeatherField, start: Vector2, along: Vector2, near: float, t: float) -> float:
	var best := NAN
	var s := near - SEARCH
	var p := start + along * s
	var was := field.raw_storm_at(p.x, p.y, t) > 0.0
	while s < near + SEARCH:
		s += STEP
		p = start + along * s
		var now := field.raw_storm_at(p.x, p.y, t) > 0.0
		if now != was and (is_nan(best) or absf(s - near) < absf(best - near)):
			best = s
		was = now
	return best
