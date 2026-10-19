extends Probe
## Geology probe 1: the ground the landmarks stand on is the seed's alone,
## and holds together. The same seed makes the same rift and vents, another
## another. On twelve worlds the rift is one line through Aitch's floor, the
## black site in its walls; every vent is on it; the vent stations stand on
## the tapped vents; the live vent is further along than any pipe reached,
## still under Tu in Han; the volcano's flank vent is on its flank; gas
## pockets break out round the rift now and then; and the rift's rock and the
## far-side volcano's are magnetized, where ordinary ground isn't.

const SEEDS := 12


func run() -> void:
	var tuning := Tuning.current()
	check(_whole(History.new(1234, tuning).geology) == _whole(History.new(1234, tuning).geology),
		"the same seed makes the same geology")
	check(_whole(History.new(1234, tuning).geology) != _whole(History.new(7, tuning).geology),
		"another seed makes another")
	var wrong := PackedStringArray()
	for k in SEEDS:
		var history := History.new(2000 + k, tuning)
		var geology := history.geology
		var r := history.radius
		var rift := geology.rift
		var gaps := 0.0
		for i in rift.size() - 1:
			gaps = maxf(gaps, Sphere.angle(rift[i], rift[i + 1]) * r)
		var aitch: Vector3 = Geology._part(history.landmark(&"halloran"), &"aitch")
		var stations := history.settlements.filter(func(s: Dictionary) -> bool: return s.kind == &"vent_station")
		var tapped := geology.tapped()
		var live: Dictionary = geology.live()[0]
		var flank: Dictionary = geology.live()[1]
		var summit: Vector3 = history.landmark(&"observatory").p
		var pockets := geology.pockets(0.0, 20.0 * 3600.0)
		var rules := {
			"one line": gaps <= Geology.STEP + 1.0 and rift.size() > 40,
			"through Aitch's floor": _off(rift, aitch, r) < 1.0,
			"the black site in its walls": _off(rift, history.landmark(&"black_site").p, r) < Geology.WALLS,
			"every vent on it": tapped.all(func(v: Dictionary) -> bool: return _off(rift, v.p, r) < 1.0)
				and _off(rift, live.p, r) < 1.0,
			"the stations on the tapped vents": stations.size() == tapped.size()
				and range(tapped.size()).all(func(i: int) -> bool: return Sphere.angle(stations[i].p, tapped[i].p) * r < 0.01),
			"the live vent past the pipes": tapped.all(func(v: Dictionary) -> bool:
				return absf(live.along) > absf(v.along) + 1500.0),
			"the live vent in Han": history.region_of(live.p) == &"han",
			"the volcano's flank vent on its flank": Sphere.angle(flank.p, summit) * r > Geology.FLANK.x - 1.0
				and Sphere.angle(flank.p, summit) * r < Geology.FLANK.y + 1.0,
			"gas pockets round the rift, now and then": pockets.size() > 20 and pockets.all(func(p: Dictionary) -> bool:
				return Sphere.angle(p.p, history.sub_tu) * r < Geology.POCKET_GROUND.y + 1.0),
			"its rock magnetized, and the volcano's, not ordinary ground": geology.magnetized(aitch) > 0.99
				and geology.magnetized(live.p) > 0.99 and geology.magnetized(history.landmark(&"observatory").p) > 0.99
				and geology.magnetized(history.landmark(&"port_morgan").p) < 0.01
				and geology.magnetized(Sphere.toward(aitch, geology.rift_bearing + PI * 0.5, 4.0 * Geology.WALLS / r)) < 0.01,
		}
		for rule: String in rules:
			if not rules[rule]:
				wrong.append("seed %d: %s" % [2000 + k, rule])
	for line in wrong:
		printerr(line)
	check(wrong.is_empty(), "the rift and its vents hold together on %d worlds (%d wrong)" % [SEEDS, wrong.size()])


## How far a place is from the rift's line, m: from each stretch, laid flat
## round its start.
func _off(rift: PackedVector3Array, p: Vector3, r: float) -> float:
	var near := INF
	for i in rift.size() - 1:
		var b := Sphere.flat_from(rift[i], rift[i + 1])
		var q := Sphere.flat_from(rift[i], p)
		var along := clampf(q.dot(b) / b.length_squared(), 0.0, 1.0)
		near = minf(near, q.distance_to(b * along))
	return near * r


func _whole(geology: Geology) -> PackedStringArray:
	var lines := PackedStringArray()
	for p in geology.rift:
		lines.append("%s" % p)
	for v in geology.vents:
		lines.append("%s %d %s %.3f" % [v.id, v.state, v.p, v.along])
	return lines
