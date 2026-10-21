extends Probe
## Structure kits probe 4: exposure is pure, and a storm works a site. The
## same seed, place and time read the same sand off from two worlds' weather,
## kept or read afresh; another seed's weather reads otherwise. Where a storm
## works hardest, the sand it moves rises as it works and falls once it lets
## go, never at a jump: at play speed no frame moves a millimetre. A site
## there lies under the sand before the storm, comes out mid-storm with its
## deepest cache in reach, and is under again by morning.

const SEED := 1234
const SAMPLES := 300
## A frame at play speed, s, and the most the sand may move in one, m.
const FRAME := 1.0 / 60.0
const SMOOTH := 0.001


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var one := WeatherField.new(SEED, tuning)
	var two := WeatherField.new(SEED, tuning)
	var other := WeatherField.new(SEED + 1, tuning)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var differ := 0
	var elsewhere := 0
	for k in SAMPLES:
		var x := rng.randf_range(-20000.0, 20000.0)
		var z := rng.randf_range(-20000.0, 20000.0)
		var t := rng.randf_range(0.0, 72.0 * 3600.0)
		# A place's readings kept: read a little earlier first, then now.
		var memo := Exposure.Memo.new()
		Exposure.taken(one, x, z, t - rng.randf() * 3600.0, tuning, memo)
		var a := Exposure.taken(one, x, z, t, tuning, memo)
		differ += int(a != Exposure.taken(two, x, z, t, tuning) or a != Exposure.taken(one, x, z, t, tuning))
		elsewhere += int(absf(a - Exposure.taken(other, x, z, t, tuning)) > 0.01)
	check(differ == 0, "the same seed, place and time read the same, kept or afresh (%d of %d differ)" % [differ, SAMPLES])
	check(elsewhere > SAMPLES / 2, "another seed's weather reads otherwise (%d of %d)" % [elsewhere, SAMPLES])

	var storm := StormSite.find(one, tuning, 600.0, 400.0)
	check(not storm.is_empty(), "a storm that lays a site bare between sand before and after")
	if storm.is_empty():
		return
	var x: float = storm.x
	var z: float = storm.z
	var peak: float = storm.peak
	var surge := [Exposure.surge(one, x, z, storm.before, tuning), Exposure.surge(one, x, z, peak, tuning),
		Exposure.surge(one, x, z, storm.after, tuning)]
	var jump := 0.0
	var memo := Exposure.Memo.new()
	var last := Exposure.taken(one, x, z, storm.before, tuning, memo)
	var t: float = storm.before
	while t < storm.after:
		t += FRAME
		var now := Exposure.taken(one, x, z, t, tuning, memo)
		jump = maxf(jump, absf(now - last))
		last = now
	print("the storm's sand off at %.0f,%.0f: %.2f m before its height, %.2f at it, %.2f after; the most in a frame %.5f m"
		% [x, z, surge[0], surge[1], surge[2], jump])
	check(surge[1] > 1.0 and surge[0] < surge[1] * 0.3 and surge[2] < surge[1] * 0.3,
		"it rises as the storm works and falls once it lets go")
	check(jump < SMOOTH, "never at a jump (%.5f m in a frame)" % jump)

	# A house ruin by hand there, as deep as the storm's work says.
	var shape := TerrainShape.new(SEED, tuning)
	shape.sites.follow(32.0, 32.0, 0.0, 0.0, 1.0, tuning.history_lay_m)
	var site: Ruin = null
	for k in 40:
		site = shape.sites.by_hand(&"house_ruin", x + (k % 8) * 3.0, z + (k / 8) * 3.0, 0.0, storm.depth) as Ruin
		if site.stands():
			break
	shape.sites.add(site)
	var cache := site.piece.sockets.size() - 1
	var read := []
	for moment: float in [storm.before, peak, storm.after]:
		site.decide(moment)
		read.append([site.state(), site.reached(cache)])
	print("a house ruin %.2f m deep there: %s" % [site.depth, ", ".join(read.map(func(r: Array) -> String:
		return Exposure.NAMES[r[0]] + (" with its cache" if r[1] else "")))])
	check(read[0][0] == Exposure.BURIED and read[2][0] == Exposure.BURIED, "under the sand before the storm and by morning")
	check(read[1][0] == Exposure.EXPOSED and read[1][1], "dug out mid-storm, its deepest cache in reach")
	check(not read[0][1] and not read[2][1], "its cache out of reach before and after")
