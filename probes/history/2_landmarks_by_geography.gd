extends Probe
## World system probe 2: every world has the eight landmarks, each where Tu's
## geography puts it. On twelve seeds, and one with Tu over another meridian:
## Halloran and Aitch near the point under Tu with Tu all but overhead; the
## black site up the artery from it, inside the ring; Port Morgan partway in;
## Halfrise on the Rim with Tu half-risen; Sister by it and the depot by
## Sister; Starcom in Mon off the line; the observatory at the anti-Tu point,
## where Tu never shows; and Halfrise, Port Morgan and Halloran on one line.

const SEEDS := 12
## Tu nods this much over a day, so "on the horizon" is this near, degrees.
const NOD := 1.6


func run() -> void:
	var tuning := Tuning.current()
	var wrong := PackedStringArray()
	for k in SEEDS + 1:
		if k == SEEDS:
			tuning.tu_longitude_degrees = 40.0
		var history := History.new(1000 + k, tuning)
		var day := DayCycle.new(tuning)
		var r := history.radius
		var at := func(id: StringName) -> Vector3: return history.landmark(id).get("p", Vector3.ZERO)
		var tu := func(id: StringName) -> float: return _tu_height(day, at.call(id))
		var from_tu := func(id: StringName) -> float: return rad_to_deg(history.from_tu(at.call(id)))
		var apart := func(a: StringName, b: StringName) -> float: return Sphere.angle(at.call(a), at.call(b)) * r
		var rules := {
			"all eight": history.landmarks.size() == 8 and history.landmarks.all(func(l: Dictionary) -> bool: return l.p != Vector3.ZERO),
			"Halloran near the point under Tu": from_tu.call(&"halloran") >= 3.0 and from_tu.call(&"halloran") <= 5.0 and tu.call(&"halloran") > 84.0,
			"the black site up the artery from it": apart.call(&"black_site", &"halloran") >= 999.0 and apart.call(&"black_site", &"halloran") <= 1601.0
				and from_tu.call(&"black_site") > from_tu.call(&"halloran") and _on_artery(history, &"black_site"),
			"Port Morgan partway in": history.region_of(at.call(&"port_morgan")) == &"mon" and tu.call(&"port_morgan") > 40.0 and tu.call(&"port_morgan") < 54.0,
			"Halfrise on the Rim, Tu half-risen": history.region_of(at.call(&"halfrise")) == &"rim" and absf(tu.call(&"halfrise")) < NOD + 1.5,
			"Sister by Halfrise": apart.call(&"sister", &"halfrise") < 3000.0 and absf(tu.call(&"sister")) < NOD + 1.5,
			"the depot by Sister": apart.call(&"rim_depot", &"sister") < 1500.0 and history.region_of(at.call(&"rim_depot")) == &"rim",
			"Starcom in Mon off the line": history.region_of(at.call(&"starcom")) == &"mon"
				and absf(rad_to_deg(Sphere.off_line(history.sub_tu, at.call(&"halfrise"), at.call(&"starcom")))) > 15.0,
			"the observatory at the anti-Tu point": Sphere.angle(at.call(&"observatory"), history.anti_tu) * r < 1.0
				and tu.call(&"observatory") < -80.0,
			"the great sites on one line": absf(Sphere.off_line(at.call(&"halfrise"), at.call(&"halloran"), at.call(&"port_morgan"))) * r < 10.0,
		}
		for rule: String in rules:
			if not rules[rule]:
				wrong.append("seed %d: %s" % [1000 + k, rule])
	tuning.tu_longitude_degrees = -60.0
	for line in wrong:
		printerr(line)
	check(wrong.is_empty(), "every landmark where its rule puts it on %d worlds (%d wrong)" % [SEEDS + 1, wrong.size()])


## How high Tu stands over a place, degrees, at its highest over a day.
func _tu_height(day: DayCycle, p: Vector3) -> float:
	var highest := -INF
	for k in 12:
		var t := k * day._day_seconds / 12.0
		highest = maxf(highest, rad_to_deg(asin(day.tu_direction(t, Sphere.latitude(p), Sphere.longitude(p)).y)))
	return highest


func _on_artery(history: History, id: StringName) -> bool:
	var p: Vector3 = history.landmark(id).p
	for path in history.network.paths:
		if path.kind == &"artery" and (Sphere.angle(path.points[0], p) * history.radius < 1.0
				or Sphere.angle(path.points[-1], p) * history.radius < 1.0):
			return true
	return false
