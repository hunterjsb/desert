extends Probe
## Geology probe 2: what a vent is doing is the time's alone. The live vent
## reads the same at a moment however it's asked, whoever asked before;
## over thirty days it seeps and now and then bursts, darker with ash, each
## burst dying away; the tapped vents and the capped summit are quiet.

## Thirty days: a burst's slot is a day and a half.
const DAYS := 30.0


func run() -> void:
	var tuning := Tuning.current()
	var geology := History.new(1234, tuning).geology
	var live: Dictionary = geology.live()[0]
	var span := DAYS * tuning.day_minutes * 60.0
	var times := PackedFloat64Array()
	for k in 400:
		times.append(fposmod(k * 7919.0, span))
	var first := times.duplicate()
	first.sort()
	var asked := {}
	for t in first:
		asked[t] = geology.venting(live, t)
	var fresh := History.new(1234, tuning).geology
	var same := 0
	for t in times:
		if geology.venting(live, t) == asked[t] and fresh.venting(fresh.live()[0], t) == asked[t]:
			same += 1
	check(same == times.size(), "the live vent reads the same at a moment however it's asked (%d of %d)" % [same, times.size()])

	var bursts := 0
	var longest := 0.0
	var began := -1.0
	var least := INF
	var seeping_ash := 0.0
	var peak_ash := 0.0
	var t := 0.0
	while t < span:
		var v := geology.venting(live, t)
		least = minf(least, v.x)
		if v.x < 1.3:
			seeping_ash = maxf(seeping_ash, v.y)
		peak_ash = maxf(peak_ash, v.y)
		if v.x > 2.5 and began < 0.0:
			bursts += 1
			began = t
		elif v.x < 1.5 and began >= 0.0:
			longest = maxf(longest, t - began)
			began = -1.0
		t += 10.0
	print("%d bursts in %.0f days, the longest %.0f s over; never below x%.2f; ash %.2f seeping, %.2f at a peak"
		% [bursts, DAYS, longest, least, seeping_ash, peak_ash])
	check(least > 0.75, "it always seeps (x%.2f at its least)" % least)
	check(bursts >= 3 and longest > 0.0 and longest < 1800.0, "it bursts now and then, and each dies away (%d, %.0f s)" % [bursts, longest])
	check(seeping_ash < 0.3 and peak_ash > 0.6, "a burst is darker with ash (%.2f, %.2f)" % [seeping_ash, peak_ash])
	var quiet := 0.0
	for each in geology.vents:
		if each.state != Geology.LIVE_VENT:
			for k in 50:
				quiet = maxf(quiet, geology.venting(each, k * 997.0).x)
	check(quiet == 0.0, "the tapped vents and the capped summit are quiet")
