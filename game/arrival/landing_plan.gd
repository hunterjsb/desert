class_name LandingPlan
extends RefCounted
## Saved regional choices, sampled from the actual sheet and seeded history.

const VERSION := 1
const PROFILES: Array[StringName] = [&"shallow", &"standard", &"steep"]
const RULES := preload("res://game/arrival/landing_plan_rules.tres")


static func build(shape: TerrainShape, anchor: Sites.Anchor, rules: LandingPlanRules = RULES) -> Dictionary:
	var origin := Vector2(anchor.x, anchor.z)
	var records := _records(shape.history, anchor.p, rules.corridor_radius_m + rules.signal_walk_m.y)
	var signals := _detectable(shape, anchor, records, rules)
	var candidates: Array[Dictionary] = []
	var fallback := _candidate(shape, anchor, origin, &"fallback", records, signals, rules)
	if fallback.safe:
		candidates.append(fallback)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([shape.history.run_seed, &"landing_plan", VERSION, anchor.p])
	for reading: Dictionary in signals:
		for attempt in rules.attempts_per_signal:
			if candidates.size() >= rules.candidate_count:
				break
			var at: Vector2 = reading.at + Vector2.from_angle(rng.randf_range(0.0, TAU)) \
				* rng.randf_range(rules.signal_walk_m.x, rules.signal_walk_m.y)
			at = at.round()
			if at.distance_to(origin) > rules.corridor_radius_m or candidates.any(func(c: Dictionary) -> bool:
					return at.distance_to(c.landing_world) < rules.candidate_spacing_m):
				continue
			var candidate := _candidate(shape, anchor, at, StringName("site_%d" % candidates.size()), records, signals, rules)
			if candidate.safe and not candidate.signals.is_empty():
				candidates.append(candidate)
		if candidates.size() >= rules.candidate_count:
			break
	return {"version": VERSION, "seed": shape.history.run_seed,
		"anchor": {"world": origin, "point": anchor.p, "facing": anchor.facing},
		"candidates": candidates, "selected_id": candidates[0].id if not candidates.is_empty() else &"",
		"heading": 0.0, "profile": &"standard"}


static func anchor_for(plan: Dictionary, radius: float) -> Sites.Anchor:
	var from: Dictionary = plan.anchor
	var at: Vector2 = from.world
	return Sites.Anchor.new(at.x, at.y, from.point, from.facing, radius)


## Reject unknown choices rather than silently substituting a different destination.
static func select(plan: Dictionary, id: StringName, heading: float, profile: StringName) -> Dictionary:
	if not is_finite(heading) or not profile in PROFILES:
		return {}
	var copy := plan.duplicate(true)
	copy.selected_id = id
	copy.heading = wrapf(heading, -PI, PI)
	copy.profile = profile
	return copy if not selected(copy).is_empty() else {}


static func selected(plan: Dictionary) -> Dictionary:
	if plan.get("version") != VERSION or not is_finite(float(plan.get("heading", NAN))) \
			or not plan.get("profile", &"") in PROFILES:
		return {}
	for candidate: Dictionary in plan.get("candidates", []):
		if candidate.get("id", &"") == plan.get("selected_id", &"") and candidate.get("safe", false):
			return candidate.duplicate(true)
	return {}


## The launch owner calls this again before committing descent and streaming ground.
static func validate(shape: TerrainShape, anchor: Sites.Anchor, plan: Dictionary, rules: LandingPlanRules = RULES) -> bool:
	var candidate := selected(plan)
	var from: Dictionary = plan.get("anchor", {})
	if candidate.is_empty() or plan.get("seed") != shape.history.run_seed \
			or from.get("world") != Vector2(anchor.x, anchor.z) or from.get("point") != anchor.p \
			or from.get("facing") != anchor.facing:
		return false
	var at: Vector2 = candidate.get("landing_world", Vector2.INF)
	if not at.is_finite() or at.distance_to(Vector2(anchor.x, anchor.z)) > rules.corridor_radius_m:
		return false
	var point := anchor.point_at(at.x, at.y)
	if candidate.get("point") != point:
		return false
	var records := _records(shape.history, point, SiteKinds.most_reach() + rules.structure_clear_m + rules.footprint_half_m * sqrt(2.0))
	return _footprint(shape, anchor, at, records, rules).clear


static func _candidate(shape: TerrainShape, anchor: Sites.Anchor, at: Vector2, id: StringName,
		records: Array[Dictionary], signals: Array[Dictionary], rules: LandingPlanRules) -> Dictionary:
	var point := anchor.point_at(at.x, at.y)
	var ground := _footprint(shape, anchor, at, records, rules)
	var readings: Array[Dictionary] = []
	for reading: Dictionary in signals:
		var distance := at.distance_to(reading.at)
		if distance <= rules.signal_walk_m.y:
			var low := floorf(distance / rules.distance_band_m) * rules.distance_band_m
			var off: Vector2 = reading.at - at
			readings.append({"kind": reading.kind, "bearing": fposmod(atan2(off.x, -off.y), TAU),
				"distance_band": Vector2(low, low + rules.distance_band_m)})
	return {"id": id, "point": point, "landing_world": at,
		"latitude": Sphere.latitude(point), "longitude": Sphere.longitude(point),
		"safe": ground.clear, "footprint": ground, "signals": readings}


static func _records(history: History, point: Vector3, radius: float) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var seen := {}
	for cell in history.cells.within(point, radius):
		for record: Dictionary in history.sites_in_cell(cell):
			if not seen.has(record.id):
				records.append(record)
				seen[record.id] = true
	return records


static func _detectable(shape: TerrainShape, anchor: Sites.Anchor, records: Array[Dictionary],
		rules: LandingPlanRules) -> Array[Dictionary]:
	var ordered := records.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := Sphere.angle(anchor.p, a.p)
		var db := Sphere.angle(anchor.p, b.p)
		return a.id < b.id if is_equal_approx(da, db) else da < db)
	var found: Array[Dictionary] = []
	for record: Dictionary in ordered:
		var piece := StructureKit.piece(record.kind)
		if piece == null or piece.sockets.is_empty() or not Skyline.stands_far(record.kind):
			continue
		var at := anchor.place(record.p)
		if at.distance_to(Vector2(anchor.x, anchor.z)) > rules.corridor_radius_m + rules.signal_walk_m.y:
			continue
		var site := shape.sites.sighted(record, anchor, true) as Structure
		if site == null or not site.stands() or site.top_in(Exposure.BURIED) < rules.detectable_height_m:
			continue
		found.append({"kind": record.kind, "at": Vector2(site.x, site.z)})
		if found.size() >= rules.signal_limit:
			break
	return found


static func _footprint(shape: TerrainShape, anchor: Sites.Anchor, at: Vector2,
		records: Array[Dictionary], rules: LandingPlanRules) -> Dictionary:
	var reach := rules.footprint_half_m * sqrt(2.0) + rules.structure_clear_m
	for record: Dictionary in records:
		if anchor.place(record.p).distance_to(at) < float(record.reach) + reach:
			return {"clear": false, "rise_m": INF}
	for landmark: Dictionary in shape.history.landmarks:
		if anchor.place(landmark.p).distance_to(at) < float(landmark.radius) + reach:
			return {"clear": false, "rise_m": INF}
	var low := INF
	var high := -INF
	# Full lattice coverage bounds the actual triangular terrain between samples.
	for z in range(floori(at.y - rules.footprint_half_m), ceili(at.y + rules.footprint_half_m) + 1):
		for x in range(floori(at.x - rules.footprint_half_m), ceili(at.x + rules.footprint_half_m) + 1):
			var h := shape.height_at(float(x), float(z))
			low = minf(low, h)
			high = maxf(high, h)
	var rise := high - low
	return {"clear": is_finite(rise) and rise <= rules.footprint_rise_m, "rise_m": rise}
