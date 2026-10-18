class_name Starts
extends RefCounted
## Where a run begins on the moon, by its kit: a point on the sphere chosen
## from the history, pure in the seed and the kit's start. "Early game for
## everyone: find an artery and follow it." The Surveyor's is deep desert with
## an artery or spoke a fair walk off, crossed by walking in toward Tu, the one
## way that's always in the sky, and a structure on its horizon; the
## Salvager's by a skimmer wreck field, a hull in sight; the Homesteader's on
## a road by a wayshrine it can see. Every start is on the near side, near
## enough the equator for the suit, clear of the landmarks, never on a site's
## ground, and has something to walk to in sight from where its run's ground
## begins, over the dunes as they're drawn, however deep the sand lies on it.

## The lines a Surveyor looks for.
const ARTERIES: Array[StringName] = [&"artery", &"spoke"]
## How many places a start tries before it gives up on its rule.
const TRIES := 1000
## Kept clear of any site's ground, m: a camp's flat patch and then some.
const CLEAR := 15.0
## The most any piece leaves over the sand buried, m, once worked out.
static var _top := NAN
## Kept clear of a landmark's footprint, m: they're the endings' places.
const LANDMARK_CLEAR := 500.0
## A Homesteader stands this far along the road from the wayshrine's foot, m.
const ALONG_ROAD := Vector2(10.0, 60.0)
## A Surveyor's mast stands no further than this either side of the way in
## toward Tu, rad.
const TOWARD_MAST := 1.2
## Where a mast might stand round a Surveyor's run's start is looked for
## along this many bearings, this far apart, m.
const LOOKOUTS := 120
const LOOKOUT_STEP := 50.0
## A Surveyor's run begins on the nearest ground with no more sand than
## this (TerrainShape.sand_at), looked for in square rings this far apart.
const BARE_SAND := 0.15
const BARE_STEP := 250.0
const BARE_RINGS := 24


## The start a kit names on this world's history, or none: the tuning's spawn point.
static func find(shape: TerrainShape, start: StringName, tuning: Tuning) -> Vector3:
	var spawn := Sphere.point(deg_to_rad(tuning.spawn_latitude_degrees), deg_to_rad(tuning.spawn_longitude_degrees))
	if start == &"":
		return spawn
	var history := shape.history
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([history.run_seed, "start", start])
	var looked := {}
	for i in TRIES:
		var p := _candidate(shape, start, tuning, rng, looked)
		if p != Vector3.ZERO and holds(shape, start, p, tuning, looked):
			return p
	push_warning("no %s start on seed %d; the tuning's spawn instead" % [start, history.run_seed])
	return spawn


## Whether a place keeps a start's rule. `looked` keeps what one search has
## made of the cells round its places.
static func holds(shape: TerrainShape, start: StringName, p: Vector3, tuning: Tuning, looked := {}) -> bool:
	var history := shape.history
	if not _in_band(p, tuning) or history.from_tu(p) > PI * 0.5 or not _off_landmarks(history, p):
		return false
	match start:
		&"artery":
			var band := tuning.start_artery_m
			return toward_tu(history, p, band.y) <= band.y and nearest_line(history, p, ARTERIES) >= band.x \
				and _deep(history, p, tuning.start_deep_m) and _off_sites(history, p) \
				and in_sight(shape, start, p, tuning, looked) != null
		&"wreck_field":
			return nearest_site(history, p, &"wreck_hull", tuning.start_wrecks_m, &"wreck_field") <= tuning.start_wrecks_m \
				and _off_sites(history, p) and in_sight(shape, start, p, tuning, looked) != null
		&"wayshrine":
			return nearest_road(history, p) <= 1.0 \
				and nearest_site(history, p, &"wayshrine", tuning.start_wayshrine_m) <= tuning.start_wayshrine_m \
				and _off_sites(history, p) and in_sight(shape, start, p, tuning, looked) != null
	return false


## Where a start's run begins on the flat world, world metres: the flat patch
## World puts you on, on the dunes alone, so it's known before there's a world.
## A Surveyor's is on the nearest bare flats, where the dunes run low and the
## horizon is far.
static func ground(shape: TerrainShape, tuning: Tuning, start := &"") -> Vector2:
	var half := tuning.chunk_size * 0.5
	if start == &"artery":
		for ring in BARE_RINGS:
			for k in maxi(1, ring * 8):
				var side := k / maxi(1, ring * 2)
				var along := k % maxi(1, ring * 2) - ring
				var at := Vector2([along, ring, -along, -ring][side], [-ring, along, ring, -along][side]) * BARE_STEP \
					+ Vector2.ONE * half
				if shape.sand_at(at.x, at.y) <= BARE_SAND:
					return World.flat_near(shape, at.x, at.y, true)
	return World.flat_near(shape, half, half, true)


## The structure of history's in sight where a start's run begins, by its
## rule: a Surveyor's on its horizon, past the deep desert's reach, of a kind
## drawn there; a Salvager's a hull of its wreck field, a Homesteader's its
## wayshrine. The nearest that stands where the sheet would lay it and shows
## over the dunes between from your eye by start_sight_px, however deep the
## sand lies on it; null if none.
static func in_sight(shape: TerrainShape, start: StringName, p: Vector3, tuning: Tuning, looked := {}) -> Structure:
	var history := shape.history
	var wanted: Callable
	var band: Vector2
	match start:
		&"artery":
			wanted = func(each: Dictionary) -> bool: return Skyline.stands_far(each.kind)
			band = Vector2(tuning.start_deep_m, tuning.skyline_m)
		&"wreck_field":
			wanted = func(each: Dictionary) -> bool: return each.kind == &"wreck_hull" and each.source == &"wreck_field"
			band = Vector2(0.0, tuning.start_wrecks_m)
		&"wayshrine":
			wanted = func(each: Dictionary) -> bool: return each.kind == &"wayshrine"
			band = Vector2(0.0, tuning.start_wayshrine_m)
		_:
			return null
	if not looked.has(&"ground"):
		looked[&"ground"] = ground(shape, tuning, start)
	var reach := minf(band.y, sight_reach(tuning))
	var near: Array[Array] = []
	for cell in history.cells.within(p, reach):
		var made: Variant = looked.get(cell)
		if made == null:
			made = history.sites_in_cell(cell).filter(func(each: Dictionary) -> bool: return StructureKit.has(each.kind))
			looked[cell] = made
		for each: Dictionary in made:
			var by := Sphere.angle(p, each.p) * history.radius
			if by >= band.x and by <= reach and wanted.call(each):
				near.append([by, each])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for each: Array in near:
		var site := _shows(shape, p, each[1], tuning, looked)
		if site != null:
			return site
	return null


## History's site as the sheet would lay it from where the run's ground
## begins (looked's) with the moon's point at p, if it stands there and its
## top shows over the dunes from your eye by start_sight_px however deep the
## sand lies on it; else null.
static func _shows(shape: TerrainShape, p: Vector3, each: Dictionary, tuning: Tuning, looked: Dictionary) -> Structure:
	var at: Vector2 = looked[&"ground"]
	var site := shape.sites.would_lay(each, at.x, at.y, p, true) as Structure
	if site == null or not site.stands():
		return null
	var eye := Vector3(at.x, shape.dunes(at.x, at.y) + Skyline.EYE, at.y)
	var top := Vector3(site.x, site.pad() + site.top_in(Exposure.BURIED), site.z)
	var dist := Vector2(top.x - eye.x, top.z - eye.z).length()
	var center := Vector2i(floori(at.x / tuning.chunk_size), floori(at.y / tuning.chunk_size))
	var least := tuning.start_sight_px * Skyline.PIXEL
	return site if Skyline.clearance(shape, tuning, eye, top, center, site.reach) >= least * dist else null


## How far off anything can show by start_sight_px, m: what the tallest
## piece leaves over the sand buried.
static func sight_reach(tuning: Tuning) -> float:
	return minf(tuning.skyline_m, _tallest() / (tuning.start_sight_px * Skyline.PIXEL))


# --- Where each start looks. ---

static func _candidate(shape: TerrainShape, start: StringName, tuning: Tuning, rng: RandomNumberGenerator,
		looked: Dictionary) -> Vector3:
	var history := shape.history
	match start:
		&"artery":
			# Out from a line behind one of its relay masts, away from Tu: walking
			# back in toward Tu crosses it, and the mast stands on the horizon.
			# Behind one of a line's relay masts, so it stands on a spot of the
			# ground where it would show from where the run begins, and so it's
			# on the way in toward Tu.
			if not looked.has(&"ground"):
				looked[&"ground"] = ground(shape, tuning, start)
			var masts := _masts(history, tuning, looked)
			var spots := _lookouts(shape, tuning, looked)
			if masts.is_empty() or spots.is_empty():
				return Vector3.ZERO
			var mast: Dictionary = masts[rng.randi() % masts.size()][0]
			var spot: Vector2 = spots[rng.randi() % spots.size()]
			var p := _behind(mast.p, spot.x, spot.y / history.radius)
			if absf(angle_difference(Sphere.bearing(p, history.sub_tu), spot.x)) > TOWARD_MAST:
				return Vector3.ZERO
			return p if _in_band(p, tuning) and _shows(shape, p, mast, tuning, looked) != null else Vector3.ZERO
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


## The relay masts history put on the arteries and spokes near enough the
## equator, each as [site, its line]: once a search.
static func _masts(history: History, tuning: Tuning, looked: Dictionary) -> Array:
	if looked.has(&"masts"):
		return looked[&"masts"]
	var masts := []
	var asked := {}
	for line in _lines(history, ARTERIES):
		var s := 0.0
		while s <= line.length():
			var on := line.at(s)
			s += 100.0
			var cell := history.cells.cell_at(on)
			if asked.has(Vector2i(cell, line.id)) or not _in_band(on, tuning, tuning.start_artery_m.y):
				continue
			asked[Vector2i(cell, line.id)] = true
			var reaching := history.paths_in_cell(cell)
			if not reaching.has(line.id):
				continue
			var made: Array[Dictionary] = []
			history.sites_of(cell, [&"path", line.id, reaching[line.id]], made)
			for each in made:
				if each.kind == &"relay_mast":
					masts.append([each, line])
	looked[&"masts"] = masts
	return masts


## Spots on the ground round where a Surveyor's run begins (looked's) that
## take a relay mast and from which it would show however deep the sand lay
## on it, past the line a Surveyor keeps clear of: as Vector2(bearing, m off),
## the bearing on the ground as on the moon. Once a search, looked along
## each bearing in one pass.
static func _lookouts(shape: TerrainShape, tuning: Tuning, looked: Dictionary) -> Array:
	if looked.has(&"lookouts"):
		return looked[&"lookouts"]
	var spots := []
	var at: Vector2 = looked[&"ground"]
	var eye := shape.dunes(at.x, at.y) + Skyline.EYE
	var center := Vector2i(floori(at.x / tuning.chunk_size), floori(at.y / tuning.chunk_size))
	var mast := StructureKit.piece(&"relay_mast")
	var shows := mast.far.map(func(each: Array) -> float: return (each[0] as AABB).end.y).max() - mast.sink[Exposure.BURIED]
	var least := tuning.start_sight_px * Skyline.PIXEL
	var reach := sight_reach(tuning)
	for k in LOOKOUTS:
		var bearing := TAU * k / LOOKOUTS
		var way := Vector2(sin(bearing), -cos(bearing))
		var worst := -INF
		var next := tuning.start_artery_m.x
		var d := 2.0
		while d <= reach:
			var here := at + way * d
			if d >= next:
				next += LOOKOUT_STEP
				var top := shape.dunes(here.x, here.y) + shows
				if top - eye - worst * d >= least * d and _takes(shape, here, mast):
					spots.append(Vector2(bearing, d))
			worst = maxf(worst, (Skyline.drawn(shape, tuning, center, here.x, here.y) - eye) / d)
			d = Skyline.next_look(d)
	looked[&"lookouts"] = spots
	return spots


## Whether the dunes at a spot are about level enough for a piece's survey.
static func _takes(shape: TerrainShape, at: Vector2, piece: StructureKit.Piece) -> bool:
	var half := piece.half.x + piece.apron
	var low := INF
	var high := -INF
	for j in 3:
		for i in 3:
			var h := shape.dunes(at.x + (i - 1) * half, at.y + (j - 1) * half)
			low = minf(low, h)
			high = maxf(high, h)
	return high - low <= piece.survey.x


## The place `by` rad from q from which q lies along `bearing`.
static func _behind(q: Vector3, bearing: float, by: float) -> Vector3:
	var back := bearing + PI
	var p := Sphere.toward(q, back, by)
	for i in 3:
		back -= angle_difference(bearing, Sphere.bearing(p, q))
		p = Sphere.toward(q, back, by)
	return p


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


## The most any kit piece shows over the sand buried, m: how far a start
## need look for something in sight.
static func _tallest() -> float:
	if is_nan(_top):
		_top = 0.0
		for kind: StringName in StructureKit.kinds():
			var piece := StructureKit.piece(kind)
			var boxes: Array = piece.boxes + piece.far.map(func(each: Array) -> AABB: return each[0])
			for box: AABB in boxes:
				_top = maxf(_top, box.end.y - piece.sink[Exposure.BURIED])
	return _top
