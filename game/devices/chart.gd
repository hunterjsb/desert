class_name Chart
extends RefCounted
## What a Console keeps for the Walker's quest, and its chart of the moon
## round it. Evidence: each of an anomaly's tells its system witnessed, by
## the sensor that sees it, a compass stuck on its deck leaning off north, a
## radio on it crackling, a shield on it bearing past a full storm's load
## while its particle sensor reads the sand. Bearings: each contact the
## Walker's log reads that a radio in its system hears whole, noted, and
## three crossing fix a place. Plugged into the Walker, it uploads its
## evidence, and with all three tells taught it the anomaly. Its chart is the
## Map's navigation: the noted bearings as lines, the fix, Home, the course
## and the Rim; once the Walker's taught, the Map's weather shows the anomalies.

## Noted bearings kept, the latest.
const KEPT := 12
## A contact is noted only heard this whole.
const WHOLE := 0.98
## The chart reaches past what's on it by this share, and no less than this, m.
const MARGIN := 1.15
const LEAST := 10000.0
## A bearing's line is drawn in this many steps along its half of the moon.
const STEPS := 64


## What its system witnesses now of an anomaly's tells, each kept once, and
## the Walker's contacts it hears.
static func witness(console: Console, t: float) -> void:
	if console.evidence.size() < Deeds.TELLS.size():
		_tells(console, t)
	_note(console, t)


static func _tells(console: Console, t: float) -> void:
	var world := console.world
	var north := world.moon.north()
	var all := console.pooled_readings()
	for device in console._system():
		for socket in device.sockets():
			if socket.part is Compass and not console.evidence.has(&"compass"):
				var at := device.global_transform * socket.transform.origin
				var lean := Compass.anomaly_lean(world, at, t, atan2(north.x, -north.z))
				if absf(lean) >= Compass.TELL:
					_keep(console, &"compass", t, rad_to_deg(absf(lean)),
						"TELL · COMPASS %d° OFF NORTH" % roundi(rad_to_deg(absf(lean))))
		var radio := device as Radio
		if radio != null and radio.playing() and radio.odd >= Radio.CRACKLE_TELL and not console.evidence.has(&"crackle"):
			_keep(console, &"crackle", t, radio.odd, "TELL · RADIO CRACKLE %d%%" % roundi(radio.odd * 100.0))
		var shield := device as ShieldGenerator
		if shield != null and shield.running() and all.has("sand") and not console.evidence.has(&"load"):
			var load := shield.particle_load()
			if load > 1.0:
				_keep(console, &"load", t, load, "TELL · SHIELD LOAD %d%% · SAND %.1f g/m³" % [roundi(load * 100.0),
					all.sand.g_m3])


static func _keep(console: Console, tell: StringName, t: float, value: float, line: String) -> void:
	console.evidence[tell] = {"t": t, "value": value}
	console._say(line)
	if console.evidence.size() == Deeds.TELLS.size():
		console._say("EVIDENCE · 3 OF 3 TELLS")


## Each contact a radio in its system hears whole off the Walker's log,
## noted once as the log gives it: where the Walker stood, and the bearing.
static func _note(console: Console, t: float) -> void:
	for radio in console.radios():
		var heard := radio.reception
		if not radio.playing() or heard.get("id") != &"walker" or heard.get("cut", true) \
				or heard.get("log_clean", 0.0) < WHOLE or heard.get("contact", {}).is_empty():
			continue
		var contact: Dictionary = heard.contact
		if console.bearings.any(func(b: Dictionary) -> bool: return b.t == contact.t):
			continue
		var p: Vector3 = contact.from
		var noted := {"t": contact.t, "lat": snappedf(rad_to_deg(Sphere.latitude(p)), 0.1),
			"lon": snappedf(rad_to_deg(Sphere.longitude(p)), 0.1),
			"brg": roundi(rad_to_deg(fposmod(contact.bearing, TAU))) % 360}
		console.bearings.append(noted)
		console.bearings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.t < b.t)
		while console.bearings.size() > KEPT:
			console.bearings.pop_front()
		console._say("CONTACT · %s · BRG %03d" % [Transmissions.fix(from_of(noted)).to_upper(), noted.brg])
		var found := fix(console.bearings, console.world.tuning)
		if not found.is_empty():
			var here := point_of(console)
			var off := Sphere.flat_from(here, found.p) * console.world.shape.history.radius
			console._say("!FIX · 3 BEARINGS · %s %s" % [Console._distance(off.length()),
				Console.POINTS[roundi(fposmod(rad_to_deg(atan2(off.x, off.y)), 360.0) / 22.5) % 16]])
			Deeds.done(console.world, &"triangulated")


## Plugged into the Walker: its evidence uploaded, and with each of the
## three tells in it, the Walker taught the anomaly for the run.
static func upload(console: Console) -> void:
	if not console.running():
		return
	var world := console.world
	var has := Deeds.TELLS.filter(func(tell: StringName) -> bool: return console.evidence.has(tell))
	if world.taught:
		console._say("WALKER · TAUGHT")
		return
	if has.size() < Deeds.TELLS.size():
		console._say("WALKER · %d OF 3 TELLS · NOTHING TAUGHT" % has.size())
		return
	world.taught = true
	console._say("!WALKER TAUGHT · 3 TELLS UPLOADED")
	Deeds.done(world, &"taught")


## Where three noted bearings cross, if any three do: each pair's lines
## meeting ahead of both, none closer than triangulate_degrees, the three
## crossings within triangulate_m of one another. The tightest of them:
## {p, spread} with the place on the sphere, or {}.
static func fix(noted: Array, tuning: Tuning) -> Dictionary:
	var radius := tuning.moon_circumference / TAU
	var best := {}
	var n := noted.size()
	for i in n:
		for j in range(i + 1, n):
			for k in range(j + 1, n):
				var three := [noted[i], noted[j], noted[k]]
				var crossings: Array[Vector3] = []
				for pair: Array in [[0, 1], [1, 2], [0, 2]]:
					var at := crossing(three[pair[0]], three[pair[1]], tuning.triangulate_degrees)
					if at == Vector3.ZERO:
						break
					crossings.append(at)
				if crossings.size() < 3:
					continue
				var spread := 0.0
				for pair: Array in [[0, 1], [1, 2], [0, 2]]:
					spread = maxf(spread, Sphere.angle(crossings[pair[0]], crossings[pair[1]]) * radius)
				if spread <= tuning.triangulate_m and (best.is_empty() or spread < best.spread):
					best = {"p": (crossings[0] + crossings[1] + crossings[2]).normalized(), "spread": spread}
	return best


## Where two noted bearings' lines cross ahead of both, crossing at `least`
## degrees or more; ZERO if they don't.
static func crossing(a: Dictionary, b: Dictionary, least: float) -> Vector3:
	var pa := from_of(a)
	var pb := from_of(b)
	var na := pa.cross(_way(pa, a.brg))
	var nb := pb.cross(_way(pb, b.brg))
	var line := na.cross(nb)
	if line.length() < 1e-9 or rad_to_deg(asin(clampf(line.length() / (na.length() * nb.length()), 0.0, 1.0))) < least:
		return Vector3.ZERO
	for at: Vector3 in [line.normalized(), -line.normalized()]:
		if at.dot(_way(pa, a.brg)) > 0.0 and at.dot(_way(pb, b.brg)) > 0.0:
			return at
	return Vector3.ZERO


## Where a noted contact's Walker stood, on the sphere.
static func from_of(noted: Dictionary) -> Vector3:
	return Sphere.point(deg_to_rad(noted.lat), deg_to_rad(noted.lon))


## The way along the ground at a place for a bearing, degrees clockwise from north.
static func _way(p: Vector3, degrees: float) -> Vector3:
	var b := deg_to_rad(degrees)
	return Sphere.north(p) * cos(b) + Sphere.east(p) * sin(b)


## Where a Console stands on the sphere.
static func point_of(console: Console) -> Vector3:
	var world := console.world
	return Walker.point(world, world.world_x(console.global_position.x), world.world_z(console.global_position.z))


## Every anomaly near a Console once the Walker's taught, as its map draws
## them: {at: east and south of it, m; radius; peak; strength}.
static func anomalies(console: Console, reach: float) -> Array:
	var world := console.world
	if not world.taught:
		return []
	var x := world.world_x(console.global_position.x)
	var z := world.world_z(console.global_position.z)
	var facing := -world.moon.north().z
	var out := []
	for heart in world.weather.field.anomalies_near(x, z, world.time, reach + world.tuning.anomaly_radius_m):
		out.append({"at": Vector2(heart.x - x, heart.z - z) * facing, "radius": heart.radius, "peak": heart.peak,
			"strength": heart.strength})
	return out


## Navigation, as the Map lays it over: the moon round it north up, out as
## far as what's on it; each noted bearing a line from where the Walker
## stood along its half of the moon, that spot a dot; the fix where three
## cross; Home where its beacon was last heard; the deck's course; the Rim
## and Tu-ward. Places as metres east and south of it, and its rows.
static func layer(console: Console) -> Dictionary:
	var world := console.world
	var radius := world.shape.history.radius
	var here := point_of(console)
	var flat := func(q: Vector3) -> Vector2:
		var off := Sphere.flat_from(here, q) * radius
		return Vector2(off.x, -off.y)
	var lines := []
	var farthest := 0.0
	for noted: Dictionary in console.bearings:
		var from := from_of(noted)
		var points := PackedVector2Array()
		for i in STEPS + 1:
			points.append(flat.call(Sphere.toward(from, deg_to_rad(noted.brg), PI * i / STEPS)))
		lines.append(points)
		farthest = maxf(farthest, points[0].length())
	var ahead := console._root().global_basis * Vector3.FORWARD
	# The engine's axes turn with the moon's north; the chart's don't.
	var chart := {"lines": lines, "rim": PackedVector2Array(),
		"course": Vector2(ahead.x, ahead.z).normalized() * -world.moon.north().z}
	var rows := PackedStringArray()
	rows.append(Console._row("%d BEARINGS" % lines.size()) if not lines.is_empty() else Console._row("NO BEARINGS"))
	var found := fix(console.bearings, world.tuning)
	if not found.is_empty():
		chart["fix"] = flat.call(found.p)
		farthest = maxf(farthest, (chart.fix as Vector2).length())
		rows.append(_place_row("FIX", chart.fix))
	var home: Dictionary = world.home.nav() if world.home != null else {}
	if not is_nan(home.get("metres", NAN)):
		chart["home"] = Vector2(sin(home.bearing), -cos(home.bearing)) * home.metres
		chart["live"] = home.live
		farthest = maxf(farthest, home.metres)
		rows.append(_place_row("HOME LIVE" if home.live else "HOME LAST KNOWN", chart.home))
	rows.append(Console._row("EVIDENCE", "%d/3" % console.evidence.size()))
	chart["rows"] = rows
	chart["reach"] = clampf(farthest * MARGIN, LEAST, PI * radius)
	var history := world.shape.history
	chart["tu"] = flat.call(history.sub_tu)
	var u := history.sub_tu.cross(Vector3(0.0, 0.0, 1.0))
	u = u.normalized() if u.length() > 1e-6 else Vector3(1.0, 0.0, 0.0)
	var v := history.sub_tu.cross(u)
	for i in 97:
		var a := TAU * i / 96.0
		(chart.rim as PackedVector2Array).append(flat.call(u * cos(a) + v * sin(a)))
	return chart


## A place on the chart as a row: how far, and which way.
static func _place_row(label: String, at: Vector2) -> String:
	var far := Console._distance_parts(at.length())
	return Console._row(label, far[0], far[1], Console.POINTS[roundi(fposmod(rad_to_deg(atan2(at.x, -at.y)), 360.0) / 22.5) % 16])
