extends Probe
## Radio probe 34: always two overhead. Wherever you stand on Zan, pole to
## pole, and at every moment through day and night, at least two satellites
## besides the relay are on the air and high enough to hear clearly (half
## their fade-in over the horizon, relay_rise_degrees / 2). Checked for many
## seeds and places over several days, every few seconds: the constellation
## is balanced so the dial is never empty of them (gonkhub, 2026-10-19).

## Seeds, days and the step, s.
const SEEDS := 16
const DAYS := 4.0
const STEP := 4.0
## Places: these latitudes at these longitudes, degrees, and each run's start.
const LATITUDES := [-89.0, -70.0, -45.0, -20.0, 0.0, 20.0, 45.0, 70.0, 89.0]
const LONGITUDES := [0.0, 72.0, 144.0, 216.0, 288.0]
## The least the dial may have.
const LEAST := 2


func run() -> void:
	var tuning := Tuning.current()
	var clear := deg_to_rad(tuning.relay_rise_degrees * 0.5)
	var span := DAYS * tuning.day_minutes * 60.0
	var worst := 99
	var short := 0
	var samples := 0
	var counts := {}
	var worst_at := ""
	for s in SEEDS:
		var run_seed := 1234 + s * 7919
		var start := Sphere.point(deg_to_rad(float(s * 37 % 160) - 80.0), deg_to_rad(float(s * 53 % 360)))
		var sky := Constellation.new(run_seed, tuning, start)
		var places: Array[Vector3] = [start]
		for lat: float in LATITUDES:
			for lon: float in LONGITUDES:
				places.append(Sphere.point(deg_to_rad(lat), deg_to_rad(lon)))
		var seed_worst := 99
		for p in places:
			var t := 0.0
			while t < span:
				var n := 0
				for id in Constellation.voiced():
					if sky.on_air(id, t) and sky.orbits[id].seen_from(p, t).elevation >= clear:
						n += 1
				counts[n] = counts.get(n, 0) + 1
				samples += 1
				if n < LEAST:
					short += 1
				if n < worst:
					worst = n
					worst_at = "seed %d, %.0f° %.0f°, %.0f s" % [run_seed, rad_to_deg(Sphere.latitude(p)),
						rad_to_deg(Sphere.longitude(p)), t]
				seed_worst = mini(seed_worst, n)
				t += STEP
		print("seed %d: at least %d" % [run_seed, seed_worst])
	var keys := counts.keys()
	keys.sort()
	var spread := PackedStringArray()
	for n in keys:
		spread.append("%d: %.1f%%" % [n, 100.0 * counts[n] / samples])
	print("satellites heard clearly: %s" % ", ".join(spread))
	print("fewest %d (%s); under %d %.2f%% of the time" % [worst, worst_at, LEAST, 100.0 * short / samples])
	check(worst >= LEAST, "always at least %d satellites on the air overhead, everywhere, day and night" % LEAST)
