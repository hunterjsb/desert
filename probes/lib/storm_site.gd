class_name StormSite
extends RefCounted
## For probes: a place and a moment where a storm lays a site bare, and how
## deep such a site lies.

## Minutes before and after a storm's strongest work the site is read.
const BEFORE := 30.0
const AFTER := 20.0


## Round (x, z), out to `rings` rings `apart` m apart, the place within `days`
## whose strongest storm work stands highest over the sand taken off before
## and after it: {x, z, peak, before, after (world times), taken [before, at
## the peak, after], depth}: as deep as leaves it buried before and after and
## past its deepest sockets (`deep`, a share of its depth) at the peak; {} if
## none does.
static func find(field: WeatherField, tuning: Tuning, x: float, z: float, rings := 3, apart := 120.0,
		days := 1.0, deep := 0.5, places := Callable()) -> Dictionary:
	var best := {}
	var score := 1.0
	for each in _storms(field, tuning, x, z, rings, apart, days, places):
		var taken: Array = each.taken
		var depth := maxf(3.0 * maxf(taken[0], taken[2]) * 1.15, 0.1)
		var this: float = taken[1] / (depth * (1.0 + deep) * 1.05)
		if this > score:
			score = this
			best = each
			best.depth = depth
	return best


## The same, where the storm works hardest over its settled sand, as deep as
## leaves it dug out just at the peak: laid bare whatever lay on it before.
static func strongest(field: WeatherField, tuning: Tuning, x: float, z: float, rings := 3, apart := 120.0,
		days := 1.0, places := Callable()) -> Dictionary:
	var best := {}
	var score := 0.0
	for each in _storms(field, tuning, x, z, rings, apart, days, places):
		var taken: Array = each.taken
		var settled := Exposure.settled(field, each.x, each.z, each.peak, tuning)
		var this: float = (taken[1] - settled) / (settled + 0.1)
		if this > score:
			score = this
			best = each
			best.depth = taken[1] * 0.95
	return best


## Each place's strongest storm work in `days`: {x, z, before, peak, after, taken}.
static func _storms(field: WeatherField, tuning: Tuning, x: float, z: float, rings: int, apart: float,
		days: float, places: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ring in rings + 1:
		var count := maxi(1, 8 * ring)
		for k in count:
			var at := Vector2(x, z) + Vector2.from_angle(TAU * k / count) * ring * apart
			if places.is_valid() and not places.call(at):
				continue
			var memo := Exposure.Memo.new()
			var most := -1.0
			var tick := 0
			for m in range(ceili(BEFORE), roundi(days * 24.0 * 60.0)):
				var s := Exposure.surge_at(field, at.x, at.y, m, tuning, memo)
				if s > most:
					most = s
					tick = m
			var peak := (tick + 1) * Exposure.SURGE_STEP_S
			var times := [peak - BEFORE * 60.0, peak, peak + AFTER * 60.0]
			out.append({"x": at.x, "z": at.y, "before": times[0], "peak": times[1], "after": times[2],
				"taken": times.map(func(t: float) -> float: return Exposure.taken(field, at.x, at.y, t, tuning, memo))})
	return out
