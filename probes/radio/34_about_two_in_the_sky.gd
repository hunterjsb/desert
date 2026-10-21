extends Probe
## Radio probe 34: about two in the sky. The satellites that cross the sky
## (not the two hung at Zan and Tu's Lagrange points, nor the lantern round
## Tu) fly orbits each its own, so wherever you stand, at any moment, about two
## of them are over the horizon on the air: sometimes none, sometimes four or
## more (gonkhub, 2026-10-21: "Put them back on unique and variable orbits,
## rolling back to '2 in the sky at once' rule"). Checked for several seeds
## and places over a day.

const SEEDS := 6
const STEP := 15.0
const LATITUDES := [-70.0, -30.0, 0.0, 30.0, 70.0]
const LONGITUDES := [0.0, 120.0, 240.0]
## The mean the sky should hold, at least and at most.
const MEAN := Vector2(1.5, 2.5)


func run() -> void:
	var tuning := Tuning.current()
	var span := tuning.day_minutes * 60.0
	var counts := {}
	var samples := 0
	var total := 0
	for s in SEEDS:
		var start := Sphere.point(deg_to_rad(float(s * 37 % 160) - 80.0), deg_to_rad(float(s * 53 % 360)))
		var sky := Constellation.new(1234 + s * 7919, tuning, start)
		for lat: float in LATITUDES:
			for lon: float in LONGITUDES:
				var p := Sphere.point(deg_to_rad(lat), deg_to_rad(lon))
				var t := 0.0
				while t < span:
					var n := 0
					for id in Constellation.voiced():
						var row: Dictionary = sky.rows[id]
						if row.look.get("hidden", false) or row.orbit.has("lagrange"):
							continue
						if sky.on_air(id, t) and sky.orbits[id].seen_from(p, t).elevation > 0.0:
							n += 1
					counts[n] = counts.get(n, 0) + 1
					total += n
					samples += 1
					t += STEP
	var mean := float(total) / samples
	var keys := counts.keys()
	keys.sort()
	var spread := PackedStringArray()
	for n in keys:
		spread.append("%d: %.1f%%" % [n, 100.0 * counts[n] / samples])
	print("in the sky at once: %.2f on average; %s" % [mean, ", ".join(spread)])
	check(mean >= MEAN.x and mean <= MEAN.y, "about two in the sky at once (%.2f)" % mean)
	var few := 0
	var many := 0
	for n: int in keys:
		if n <= 1:
			few += counts[n]
		elif n >= 3:
			many += counts[n]
	check(few > samples * 0.1 and many > samples * 0.1, "and it varies: sometimes one or none, sometimes three or more")
