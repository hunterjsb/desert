extends Probe
## Radio probe 24: finding the Walker never happens early. On 30 seeds, from
## each origin's start and a run begun anywhere from day 3 to day 30 of the
## clock, the Walker begins on the Rim at its farthest from that start and
## walks on: through the run's first ten days it's never nearer than 30 km,
## and it walks the Rim all the while.
## Time limit: 300 s.

const SEEDS := 30
const DAYS := 10.0
const FAR := 30000.0


func run() -> void:
	var tuning := Tuning.current()
	var day := tuning.day_minutes * 60.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 24
	var least := INF
	var soonest := INF
	for s in range(1, SEEDS + 1):
		var shape := TerrainShape.new(s, tuning)
		var history := shape.history
		for start: StringName in [&"artery", &"wreck_field", &"wayshrine"]:
			var p := Starts.find(shape, start, tuning)
			var began := rng.randf_range(3.0, 30.0) * day
			var gods := Gods.new(history, s, tuning)
			gods.place_walker(p, began)
			var t := began
			var near := INF
			while t <= began + 60.0 * day:
				var q := gods.home(&"walker", t)
				var metres := Sphere.angle(p, q) * history.radius
				if t <= began + DAYS * day:
					near = minf(near, metres)
					check(absf(history.from_tu(q) - PI * 0.5) < 1e-6, "seed %d: it walks the Rim" % s)
				elif metres < FAR:
					soonest = minf(soonest, (t - began) / day)
					break
				t += 120.0
			least = minf(least, near)
			check(near >= FAR, "seed %d, from the %s start: %.1f km off at its nearest in ten days" % [s, start, near / 1000.0])
	print("over %d seeds and three starts: never nearer than %.1f km in the first ten days; within %.0f km soonest on day %.1f"
		% [SEEDS, least / 1000.0, FAR / 1000.0, soonest])
