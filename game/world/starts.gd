class_name Starts
extends RefCounted
## Where a run begins on the moon, by its kit: a point on the sphere chosen
## from the history, pure in the seed and the kit's start. "Early game for
## everyone: find an artery and follow it." The Surveyor's is deep desert with
## an artery or spoke a fair walk off, crossed by walking in toward Tu, the one
## way that's always in the sky; the Salvager's by a skimmer wreck field; the
## Homesteader's on a road by a wayshrine. Every start is on the near side,
## near enough the equator for the suit, clear of the landmarks, and never on
## a site's ground.

## The lines a Surveyor looks for.
const ARTERIES: Array[StringName] = [&"artery", &"spoke"]
## How many places a start tries before it gives up on its rule.
const TRIES := 1000
## Kept clear of any site's ground, m: a camp's flat patch and then some.
const CLEAR := 15.0
## Kept clear of a landmark's footprint, m: they're the endings' places.
const LANDMARK_CLEAR := 500.0
## A Homesteader stands this far along the road from the wayshrine's foot, m.
const ALONG_ROAD := Vector2(10.0, 60.0)


## The start a kit names on this history, or none: the tuning's spawn point.
static func find(history: History, start: StringName, tuning: Tuning) -> Vector3:
	var spawn := Sphere.point(deg_to_rad(tuning.spawn_latitude_degrees), deg_to_rad(tuning.spawn_longitude_degrees))
	if start == &"":
		return spawn
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([history.run_seed, "start", start])
	for i in TRIES:
		var p := _candidate(history, start, tuning, rng)
		if p != Vector3.ZERO and holds(history, start, p, tuning):
			return p
	push_warning("no %s start on seed %d; the tuning's spawn instead" % [start, history.run_seed])
	return spawn


## Whether a place keeps a start's rule.
static func holds(history: History, start: StringName, p: Vector3, tuning: Tuning) -> bool:
	if not _in_band(p, tuning) or history.from_tu(p) > PI * 0.5 or not _off_landmarks(history, p):
		return false
	match start:
		&"artery":
			var band := tuning.start_artery_m
			return toward_tu(history, p, band.y) <= band.y and nearest_line(history, p, ARTERIES) >= band.x \
				and _deep(history, p, tuning.start_deep_m) and _off_sites(history, p)
		&"wreck_field":
			return nearest_site(history, p, &"wreck_hull", tuning.start_wrecks_m, &"wreck_field") <= tuning.start_wrecks_m \
				and _off_sites(history, p)
		&"wayshrine":
			return nearest_road(history, p) <= 1.0 \
				and nearest_site(history, p, &"wayshrine", tuning.start_wayshrine_m) <= tuning.start_wayshrine_m \
				and _off_sites(history, p)
	return false


# --- Where each start looks. ---

static func _candidate(history: History, start: StringName, tuning: Tuning, rng: RandomNumberGenerator) -> Vector3:
	match start:
		&"artery":
			# Out from a line, away from Tu: walking back in toward Tu crosses it.
			var line := _pick(_lines(history, ARTERIES), rng)
			var on := line.at(rng.randf() * line.length())
			if not _in_band(on, tuning, tuning.start_artery_m.y):
				return Vector3.ZERO
			var band := tuning.start_artery_m
			return Sphere.toward(on, Sphere.bearing(on, history.sub_tu) + PI,
				rng.randf_range(band.x, band.y) / history.radius)
		&"wreck_field":
			# A cell anywhere on the near side near the equator, and a hull of a field in it.
			var most := sin(deg_to_rad(tuning.start_latitude_degrees))
			var p := Sphere.point(asin(rng.randf_range(-most, most)),
				Sphere.longitude(history.sub_tu) + rng.randf_range(-PI, PI) * 0.5)
			var hulls := history.sites_in_cell(history.cells.cell_at(p)).filter(func(s: Dictionary) -> bool:
				return s.kind == &"wreck_hull" and s.source == &"wreck_field")
			if hulls.is_empty():
				return Vector3.ZERO
			var hull: Dictionary = hulls[rng.randi() % hulls.size()]
			return Sphere.toward(hull.p, rng.randf() * TAU,
				rng.randf_range(hull.reach + CLEAR, tuning.start_wrecks_m * 0.9) / history.radius)
		&"wayshrine":
			# A stretch of second-age road, its wayshrine, and the road beside it.
			var road := _pick(_roads(history), rng)
			var on := road.at(rng.randf() * road.length())
			if not _in_band(on, tuning, 1000.0):
				return Vector3.ZERO
			var cell := history.cells.cell_at(on)
			var span: Vector2 = history.paths_in_cell(cell).get(road.id, Vector2.ZERO)
			var made: Array[Dictionary] = []
			history.sites_of(cell, [&"path", road.id, span], made)
			var shrines := made.filter(func(s: Dictionary) -> bool: return s.kind == &"wayshrine")
			if shrines.is_empty():
				return Vector3.ZERO
			var shrine: Dictionary = shrines[rng.randi() % shrines.size()]
			var foot := _foot(road, shrine.p)
			var off := rng.randf_range(ALONG_ROAD.x, ALONG_ROAD.y) * (1.0 if rng.randf() < 0.5 else -1.0)
			return road.at(clampf(foot + off, 0.0, road.length()))
	return Vector3.ZERO


static func _lines(history: History, kinds: Array[StringName]) -> Array[PathNetwork.Path]:
	var out: Array[PathNetwork.Path] = []
	for path in history.network.paths:
		if path.kind in kinds:
			out.append(path)
	return out


## Every path that was a road in the second age: where wayshrines stand.
static func _roads(history: History) -> Array[PathNetwork.Path]:
	var out: Array[PathNetwork.Path] = []
	for path in history.network.paths:
		if path.carries & PathNetwork.ROAD and path.used_in(Eras.SECOND):
			out.append(path)
	return out


## One of them, the longer the likelier.
static func _pick(paths: Array[PathNetwork.Path], rng: RandomNumberGenerator) -> PathNetwork.Path:
	var total := 0.0
	for path in paths:
		total += path.length()
	var at := rng.randf() * total
	for path in paths:
		at -= path.length()
		if at <= 0.0:
			return path
	return paths.back()


# --- What a start is measured by. ---

## How far walking straight in toward Tu from p first crosses a line of
## these kinds, m, looked for as far as `reach`; INF if none.
static func toward_tu(history: History, p: Vector3, reach: float, kinds: Array[StringName] = ARTERIES) -> float:
	var end := Sphere.toward(p, Sphere.bearing(p, history.sub_tu), reach / history.radius)
	var walk := p.cross(end).normalized()
	var near := cos((reach + PathNetwork.STEP) / history.radius)
	var first := INF
	for path in _lines(history, kinds):
		for i in path.points.size() - 1:
			var a := path.points[i]
			var b := path.points[i + 1]
			if a.dot(p) < near or signf(a.dot(walk)) == signf(b.dot(walk)):
				continue
			var line := a.cross(b).normalized()
			if signf(p.dot(line)) == signf(end.dot(line)):
				continue
			var cross := walk.cross(line).normalized()
			if cross.dot(p) < 0.0:
				cross = -cross
			first = minf(first, Sphere.angle(p, cross) * history.radius)
	return first


## How far p is from the nearest line of these kinds, m.
static func nearest_line(history: History, p: Vector3, kinds: Array[StringName]) -> float:
	var best := INF
	for path in _lines(history, kinds):
		best = minf(best, to_path(history, path, p))
	return best


## How far p is from the nearest second-age road, m.
static func nearest_road(history: History, p: Vector3) -> float:
	var best := INF
	for path in _roads(history):
		best = minf(best, to_path(history, path, p))
	return best


## How far p is from a path's line, m, over its whole length or a stretch.
static func to_path(history: History, path: PathNetwork.Path, p: Vector3, span := Vector2(0.0, INF)) -> float:
	var best := INF
	var from := path.segment(span.x)
	var to := path.segment(minf(span.y, path.length()))
	for i in range(from, to + 1):
		best = minf(best, _to_arc(path.points[i], path.points[i + 1], p))
	return best * history.radius


## The nearest site of a kind within `reach` m of p, m; INF if none. From a
## source only, if one is named.
static func nearest_site(history: History, p: Vector3, kind: StringName, reach: float, source := &"") -> float:
	var best := INF
	for cell in history.cells.within(p, reach):
		for site in history.sites_in_cell(cell):
			if site.kind == kind and (source == &"" or site.source == source):
				best = minf(best, Sphere.angle(p, site.p) * history.radius)
	return best


## Deep desert: no path and no settlement reaches within `metres` of p.
static func _deep(history: History, p: Vector3, metres: float) -> bool:
	for cell in history.cells.within(p, metres):
		var reaching := history.paths_in_cell(cell)
		for id: int in reaching:
			if to_path(history, history.network.paths[id], p, reaching[id]) < metres:
				return false
		for part in history.cell_parts(cell):
			if part[0] == &"settlement":
				var each: Dictionary = history.settlements[part[1]]
				if Sphere.angle(p, each.p) * history.radius - each.radius < metres:
					return false
	return true


static func _off_sites(history: History, p: Vector3) -> bool:
	for cell in history.cells.within(p, SiteKinds.most_reach() + CLEAR):
		for site in history.sites_in_cell(cell):
			if Sphere.angle(p, site.p) * history.radius < site.reach + CLEAR:
				return false
	return true


## Near enough the equator, with `margin` m to spare.
static func _in_band(p: Vector3, tuning: Tuning, margin := 0.0) -> bool:
	var most := deg_to_rad(tuning.start_latitude_degrees) + margin / (tuning.moon_circumference / TAU)
	return absf(Sphere.latitude(p)) <= most


static func _off_landmarks(history: History, p: Vector3) -> bool:
	for each in history.landmarks:
		if Sphere.angle(p, each.p) * history.radius < each.radius + LANDMARK_CLEAR:
			return false
	return true


## How far along a path the point of it nearest q is, m.
static func _foot(path: PathNetwork.Path, q: Vector3) -> float:
	var best := INF
	var at := 0.0
	for i in path.points.size() - 1:
		var a := path.points[i]
		var b := path.points[i + 1]
		var by := _to_arc(a, b, q)
		if by < best:
			best = by
			var span := Sphere.angle(a, b)
			var along := clampf(Sphere.angle(a, _on_circle(a, b, q)), 0.0, span) if span > 0.0 else 0.0
			at = path.lengths[i] + (path.lengths[i + 1] - path.lengths[i]) * (along / span if span > 0.0 else 0.0)
	return at


## The angle from q to the short arc from a to b.
static func _to_arc(a: Vector3, b: Vector3, q: Vector3) -> float:
	var pole := a.cross(b)
	if pole.length_squared() > 1e-24:
		pole = pole.normalized()
		var foot := _on_circle(a, b, q)
		# Between its ends: a turns toward it, and it toward b, the arc's way round.
		if a.cross(foot).dot(pole) >= 0.0 and foot.cross(b).dot(pole) >= 0.0:
			return absf(asin(clampf(q.dot(pole), -1.0, 1.0)))
	return minf(Sphere.angle(q, a), Sphere.angle(q, b))


## The point of the great circle through a and b nearest q.
static func _on_circle(a: Vector3, b: Vector3, q: Vector3) -> Vector3:
	var pole := a.cross(b)
	if pole.length_squared() < 1e-24:
		return a
	pole = pole.normalized()
	var flat := q - pole * q.dot(pole)
	return flat.normalized() if flat.length_squared() > 1e-24 else a
