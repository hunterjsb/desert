extends Probe
## Wind & storms probe 18: a run sees a plume from far now and then. Sitting
## three hours where each origin starts, on six worlds: storms hide the plumes
## most of the time, as they hide everything else, but from most starts one
## shows at some moment, a burst's column standing over the storms between.

const SEEDS := [1234, 7, 42, 99, 2026, 5]
const STARTS: Array[StringName] = [&"artery", &"wreck_field", &"wayshrine"]
const HOURS := 3.0
## Looked at this often, s, and from this far at least, m.
const EVERY := 60.0
const FAR := 5000.0


func run() -> void:
	var tuning := Tuning.current()
	var day := DayCycle.new(tuning)
	var started := Time.get_ticks_msec()
	var seeing := 0
	var shares := PackedFloat32Array()
	for each_seed: int in SEEDS:
		var shape := TerrainShape.new(each_seed, tuning)
		var geology := shape.history.geology
		var field := WeatherField.new(each_seed, tuning)
		for start in STARTS:
			var p := Starts.find(shape, start, tuning)
			var eye := Vector3(0.0, 2.0, 0.0)
			var seen := 0
			var looks := 0
			var t := 0.0
			while t < HOURS * 3600.0:
				looks += 1
				for source in geology.live() + geology.pockets(t, t):
					if _shows(geology, field, tuning, day, source, p, eye, t):
						seen += 1
						break
				t += EVERY
			shares.append(float(seen) / looks)
			if seen > 0:
				seeing += 1
	shares.sort()
	var median := shares[shares.size() / 2]
	print("%d of %d starts see a plume from %d km or more in %d hours, a median %.0f%% of the time (%d ms)" % [
		seeing, shares.size(), FAR / 1000, HOURS, median * 100.0, Time.get_ticks_msec() - started])
	check(seeing >= shares.size() * 3 / 4, "most starts see a plume now and then (%d of %d)" % [seeing, shares.size()])
	check(median >= 0.03, "and not only once (a median %.0f%% of the time)" % (median * 100.0))


## Whether a source's plume shows from an eye where the run starts, laid as
## the sheet would lay it from there: its top past the storms between.
func _shows(geology: Geology, field: WeatherField, tuning: Tuning, day: DayCycle, source: Dictionary, p: Vector3,
		eye: Vector3, t: float) -> bool:
	var by := Sphere.angle(p, source.p) * geology.radius
	if by < FAR or by > tuning.plume_fade_m.y:
		return false
	var off := Sphere.flat_from(p, source.p) * geology.radius
	var root := Vector3(off.x, 0.0, -off.y)
	var n := Plume.stability(day, t, Sphere.latitude(p), Sphere.longitude(p), 1.0)
	var top := root
	for k in range(0, Plume.POINTS, 2):
		var age := Plume.OLDEST * pow(float(k) / (Plume.POINTS - 1), Plume.CROWD)
		var v := geology.venting(source, t - age)
		if v.x > 0.0:
			var at: Vector4 = Plume.parcel_at(field, tuning, Vector2(root.x, root.z), t, age, v.x, n, 1.0)[0]
			if at.y > top.y:
				top = root + Vector3(at.x, at.y, at.z)
	return top.y > 300.0 and Plume.seen_through(field, tuning, eye, top, t) > 0.5 \
		and field.raw_storm_at(eye.x, eye.z, t) < 0.0
