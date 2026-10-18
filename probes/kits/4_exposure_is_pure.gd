extends Probe
## Structure kits probe 4: exposure is pure. The same seed, place and time
## read the same sand taken off, from two worlds' weather; any moment within
## a tick reads the same; a site reads the same state held or not; another
## seed's weather reads otherwise. And a returning storm reaches deeper: at
## one place over three days the sand taken off rises as storms sit on it
## and falls as calm lets it back, a little a tick, never at a jump; a site
## there goes from under the sand to dug out and back; and its deepest cache
## is reached only once a storm has stripped past it.

const SEED := 1234
const SAMPLES := 300


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var one := WeatherField.new(SEED, tuning)
	var two := WeatherField.new(SEED, tuning)
	var other := WeatherField.new(SEED + 1, tuning)
	var step := tuning.site_exposure_step_minutes * 60.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var differ := 0
	var within := 0
	var elsewhere := 0
	for k in SAMPLES:
		var x := rng.randf_range(-20000.0, 20000.0)
		var z := rng.randf_range(-20000.0, 20000.0)
		var t := floorf(rng.randf_range(0.0, 72.0 * 3600.0) / step) * step
		var a := Exposure.stripped(one, x, z, t, tuning)
		differ += int(a != Exposure.stripped(two, x, z, t, tuning))
		within += int(a != Exposure.stripped(one, x, z, t + rng.randf() * (step - 1.0), tuning))
		elsewhere += int(absf(a - Exposure.stripped(other, x, z, t, tuning)) > 0.01)
	check(differ == 0, "the same seed, place and time read the same (%d of %d differ)" % [differ, SAMPLES])
	check(within == 0, "any moment within a tick reads the same (%d differ)" % within)
	check(elsewhere > SAMPLES / 2, "another seed's weather reads otherwise (%d of %d)" % [elsewhere, SAMPLES])

	# A house ruin by hand where the weather comes and goes.
	var shape := TerrainShape.new(SEED, tuning)
	shape.sites.follow(32.0, 32.0, 0.0, 0.0, 1.0, tuning.history_lay_m)
	var site: Ruin = null
	for k in 40:
		site = shape.sites.by_hand(&"house_ruin", 600.0 + k * 23.0, 400.0, 0.0, 0.0) as Ruin
		if site.stands():
			break
	shape.sites.add(site)
	var times := PackedFloat64Array()
	var taken := PackedFloat64Array()
	for k in 144:
		times.append(k * step)
		taken.append(Exposure.stripped(one, site.x, site.z, k * step, tuning))
	var jump := 0.0
	var rises := 0
	var falls := 0
	for k in range(1, taken.size()):
		jump = maxf(jump, absf(taken[k] - taken[k - 1]))
		rises += int(taken[k] > taken[k - 1] + 0.01)
		falls += int(taken[k] < taken[k - 1] - 0.01)
	# Never more than one tick's work at a step: the newest tick's storm, and
	# a share of every older tick's as the sand comes back.
	var most := 2.0 * (tuning.site_strip_m + absf(tuning.site_return_m))
	print("sand taken off from %.2f to %.2f m over three days; %d rising ticks, %d falling; the biggest step %.2f m"
		% [_least(taken), _most(taken), rises, falls, jump])
	check(rises > 10 and falls > 10, "storms take sand off and calm lets it back (%d up, %d down)" % [rises, falls])
	check(jump <= most, "a little a tick, never at a jump (%.2f m against %.2f)" % [jump, most])
	# As deep as the sand the weather took off at its most, less a little.
	site.depth = _most(taken) * 0.6
	var seen := {}
	var held_same := true
	var cache := site.piece.sockets.size() - 1
	var deep_reached := 0
	var shallow_only := 0
	for k in taken.size():
		shape.sites.set_clock(func() -> float: return times[k])
		var asked := site.state()
		site.decide(times[k])
		held_same = held_same and site.state() == asked
		seen[site.state()] = true
		var deep := site.reached(cache)
		var past := taken[k] >= site.depth * (1.0 + site.piece.sockets[cache].deep)
		if deep != past and site.state() == Exposure.EXPOSED:
			held_same = false
		deep_reached += int(deep)
		shallow_only += int(site.state() == Exposure.EXPOSED and not deep)
		site.forget()
	check(held_same, "a site reads the same state held or not")
	check(seen.size() == 3, "the same site buried, partly exposed and dug out as the weather changes (%d states)"
		% seen.size())
	check(deep_reached > 0 and shallow_only > 0,
		"its deep cache reached only once a storm has stripped past it (%d times; %d dug out without it)"
		% [deep_reached, shallow_only])


func _least(values: PackedFloat64Array) -> float:
	var least := INF
	for v in values:
		least = minf(least, v)
	return least


func _most(values: PackedFloat64Array) -> float:
	var most := -INF
	for v in values:
		most = maxf(most, v)
	return most
