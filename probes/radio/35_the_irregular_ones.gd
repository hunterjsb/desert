extends Probe
## Radio probe 35: the irregular ones. The two satellites outside the
## formation fly and behave irregularly (gonkhub, 2026-10-19). The ghost's
## ellipse dives low over the dunes and hangs far out, many times higher,
## sweeping fast at its perigee and crawling at its apogee; its plane and
## perigee swing round, so each lap takes a new route. It's on the air in
## fits, about its share of the time, the spells of uneven length; its carrier
## hops round its band at uneven gaps; it tumbles, its signal swelling and
## fading and its light flashing. The relay's ellipse swings round too, and a
## run still begins with it over where it began; it tumbles slowly. The
## cinder's orbit decays, sinking lap by lap until a burn throws it back up,
## and its roar brightens as it sinks. Nearer, each looks brighter. The
## formation stays as it was: circles that don't turn.

const SEED := 1234
const STEP := 2.0


func run() -> void:
	var tuning := Tuning.current()
	var start := Sphere.point(deg_to_rad(12.0), deg_to_rad(40.0))
	var sky := Constellation.new(SEED, tuning, start)
	var ghost: Satellite = sky.orbits[&"ghost"]
	var relay: Satellite = sky.orbits[&"relay"]

	# Its ellipse: low and fast, high and slow.
	var lowest := INF
	var highest := 0.0
	var fastest := 0.0
	var slowest := INF
	var t := 0.0
	while t < ghost.period:
		var h := ghost.height(t)
		lowest = minf(lowest, h)
		highest = maxf(highest, h)
		var swept := rad_to_deg(ghost.at(t).angle_to(ghost.at(t + 1.0)))
		fastest = maxf(fastest, swept)
		slowest = minf(slowest, swept)
		t += STEP
	print("the ghost: %.2f to %.2f radii up; %.3f to %.3f°/s round the moon" % [lowest, highest, slowest, fastest])
	check(lowest > 0.15 and highest > lowest * 6.0, "the ghost dives low and hangs far out, %.0f times higher" % (highest / lowest))
	check(fastest > slowest * 10.0, "sweeping fast at its perigee and crawling at its apogee")

	# Each lap a new route: its plane swung round, lap on lap.
	for row: Array in [[&"ghost", ghost, 20.0], [&"relay", relay, 10.0]]:
		var orbit: Satellite = row[1]
		var plane := _plane(orbit, 0.0)
		var later := _plane(orbit, orbit.period * 3.0)
		var swung := rad_to_deg(plane.angle_to(later))
		print("%s: its plane swung %.0f° in three laps" % [row[0], swung])
		check(swung > row[2], "%s's route moves on lap by lap" % row[0])
	var formation: Satellite = sky.orbits[&"sounder"]
	var held := rad_to_deg(_plane(formation, 0.0).angle_to(_plane(formation, formation.period * 3.0)))
	check(held < 0.5, "the formation's planes hold still (%.2f°)" % held)
	check(formation.eccentricity == 0.0 and formation.precession == 0.0 and absf(formation.height(0.0)
		- formation.height(formation.period * 0.37)) < 1e-4, "the formation's orbits stay circles that don't turn")
	check(relay.under(0.0).angle_to(start) < 1e-3, "a run still begins with the relay over where it began")

	# On in fits, for spells of uneven length.
	var on := 0
	var samples := 0
	var spells: Array[float] = []
	var since := 0.0
	var was := sky.on_air(&"ghost", 0.0)
	t = 0.0
	while t < 6.0 * 3600.0:
		var now := sky.on_air(&"ghost", t)
		on += int(now)
		samples += 1
		if now != was:
			if was:
				spells.append(t - since)
			since = t
			was = now
		t += STEP
	var mean := 0.0
	for each in spells:
		mean += each / spells.size()
	var spread := 0.0
	for each in spells:
		spread += pow(each - mean, 2.0) / spells.size()
	var share := float(on) / samples
	print("the ghost on the air %.0f%% of six hours, %d spells, %.0f s on average, spread %.0f s" % [100.0 * share,
		spells.size(), mean, sqrt(spread)])
	check(absf(share - sky.rows[&"ghost"].behave.bursts) < 0.08, "on the air about its share of the time")
	check(spells.size() > 10 and sqrt(spread) > mean * 0.4, "in fits, the spells of uneven length")

	# Hopping round its band at uneven gaps.
	var gaps: Array[float] = []
	var last := sky.carrier(&"ghost", 0.0)
	var jumped := 0.0
	var band: Vector2 = sky.rows[&"ghost"].band
	var inside := true
	t = 0.0
	while t < 1200.0:
		var khz := sky.carrier(&"ghost", t)
		inside = inside and khz >= band.x and khz <= band.y
		if khz != last:
			gaps.append(t - jumped)
			jumped = t
			last = khz
		t += 0.5
	gaps.remove_at(0)
	print("its carrier hopped %d times in 20 minutes, gaps %.0f to %.0f s" % [gaps.size() + 1, gaps.min(), gaps.max()])
	check(gaps.size() > 30 and inside, "its carrier hops round its band")
	check(gaps.max() > gaps.min() * 1.5, "at uneven gaps")

	# Tumbling: its signal swells and fades, its light flashes.
	var faint := INF
	var full := 0.0
	var dim := INF
	var flash := 0.0
	t = 0.0
	while t < 30.0:
		faint = minf(faint, sky.tumble(&"ghost", t))
		full = maxf(full, sky.tumble(&"ghost", t))
		dim = minf(dim, sky.glint(&"ghost", t))
		flash = maxf(flash, sky.glint(&"ghost", t))
		t += 0.05
	print("the ghost tumbling: its signal %.2f to %.2f, its light %.2f to %.2f" % [faint, full, dim, flash])
	check(faint < 0.3 and full > 0.99, "the ghost's signal swells and fades as it tumbles")
	check(flash > dim * 10.0, "and it flashes as it turns")
	check(sky.tumble(&"relay", 0.0) < 1.0 or sky.tumble(&"relay", 10.0) < 1.0, "the relay tumbles too")
	check(sky.tumble(&"sounder", 3.0) == 1.0 and sky.glint(&"sounder", 3.0) == 1.0, "the formation doesn't")

	# The cinder: sinking lap by lap, then thrown back up by its burn.
	var cinder: Satellite = sky.orbits[&"cinder"]
	var cycle := cinder.decay_seconds
	var early := _mean_height(cinder, cycle * 0.02)
	var late := _mean_height(cinder, cycle * 0.75)
	var after := _mean_height(cinder, cycle * 1.02)
	print("the cinder: a lap's mean height %.2f radii early in its decay, %.2f late, %.2f after its burn" % [early,
		late, after])
	check(late < early - cinder.decay * 0.6 and after > late + cinder.decay * 0.6, "the cinder sinks, then burns back up")
	var seen := {"elevation": 0.5}
	var lowest_at := 0.0
	var highest_at := 0.0
	t = 0.0
	while t < cycle:
		if cinder.highness(t) < cinder.highness(lowest_at):
			lowest_at = t
		if cinder.highness(t) > cinder.highness(highest_at):
			highest_at = t
		t += STEP
	var low: Dictionary = sky.shaped(&"cinder", null, seen, 0.0, 0.0, lowest_at)
	var high: Dictionary = sky.shaped(&"cinder", null, seen, 0.0, 0.0, highest_at)
	print("its roar: %.0f Hz and pitch %.2f at its lowest, %.0f Hz and %.2f at its highest" % [low.cutoff, low.pitch,
		high.cutoff, high.pitch])
	check(low.cutoff > high.cutoff * 4.0 and low.pitch > high.pitch, "its roar brightens and rises as it sinks")

	# Nearer, brighter.
	var perigee := 0.0
	var apogee := 0.0
	t = 0.0
	while t < ghost.period:
		if ghost.height(t) < ghost.height(perigee):
			perigee = t
		if ghost.height(t) > ghost.height(apogee):
			apogee = t
		t += STEP
	print("the ghost looks %.2f as bright at its perigee, %.2f at its apogee" % [ghost.nearness(perigee),
		ghost.nearness(apogee)])
	check(ghost.nearness(perigee) > 2.0 and ghost.nearness(apogee) < 0.6, "nearer it looks brighter, far out dimmer")
	check(is_equal_approx(formation.nearness(123.0), 1.0), "a circle looks as bright all round")


## Its mean height over a lap from world time t, radii.
func _mean_height(orbit: Satellite, from: float) -> float:
	var sum := 0.0
	for k in 40:
		sum += orbit.height(from + orbit.period * k / 40.0)
	return sum / 40.0


## Its orbit's plane at world time t, as its pole among the stars: the moon's
## own turn under it taken back out.
func _plane(orbit: Satellite, t: float) -> Vector3:
	return _still(orbit, t).cross(_still(orbit, t + 1.0)).normalized()


func _still(orbit: Satellite, t: float) -> Vector3:
	return orbit.at(t).rotated(Vector3(0.0, 0.0, 1.0), TAU * t / orbit.day_seconds)
