extends Probe
## Spawns probe 1: each origin's start is the seed's alone and lands in its
## setting, measured here from the history's own lines and sites, on eight
## worlds. The Surveyor's is deep desert, nothing a path or a settlement left
## within sight, an artery or spoke at least a kilometre off, and walking in
## toward Tu crosses one within three. The Salvager's is within 300 m of a
## skimmer wreck field's hulls; the Homesteader's on a second-age road within
## 100 m of a wayshrine. Every one is on the near side, inside the latitude
## the suit is good for, off every site's ground and clear of the landmarks.

const SEEDS := [1234, 1, 2, 3, 42, 777, 1001, 1002]
## The lines sampled this often along, m.
const SAMPLE := 10.0


func run() -> void:
	var tuning := Tuning.current()
	var wrong := PackedStringArray()
	for s: int in SEEDS:
		var shape := TerrainShape.new(s, tuning)
		var again := TerrainShape.new(s, tuning)
		for kit in Kit.origins():
			var p := Starts.find(shape, kit.start, tuning)
			var why := _setting(shape.history, kit.start, p, tuning)
			if Starts.find(again, kit.start, tuning) != p:
				why = "not the seed's alone"
			if why != "":
				wrong.append("seed %d, the %s: %s" % [s, kit.label, why])
		var others := TerrainShape.new(s + 1, tuning)
		if Starts.find(others, &"artery", tuning) == Starts.find(shape, &"artery", tuning):
			wrong.append("seeds %d and %d start the Surveyor in the same place" % [s, s + 1])
	for line in wrong:
		printerr(line)
	check(wrong.is_empty(), "every origin starts in its setting on %d worlds (%d wrong)" % [SEEDS.size(), wrong.size()])


## What's wrong with a start, or "".
func _setting(history: History, start: StringName, p: Vector3, tuning: Tuning) -> String:
	var r := history.radius
	if absf(rad_to_deg(Sphere.latitude(p))) > tuning.start_latitude_degrees or history.from_tu(p) > PI * 0.5:
		return "off the near side's mild band"
	for each in history.landmarks:
		if Sphere.angle(p, each.p) * r < each.radius:
			return "in %s" % each.name
	for site in _sites_within(history, p, 60.0):
		if Sphere.angle(p, site.p) * r < site.reach:
			return "on a %s's ground" % site.kind
	match start:
		&"artery":
			var band := tuning.start_artery_m
			var lines := _samples(history, p, band.y + 500.0, func(path: PathNetwork.Path) -> bool:
				return path.kind in [&"artery", &"spoke"])
			if lines.any(func(x: Vector3) -> bool: return Sphere.angle(p, x) * r < band.x):
				return "an artery or spoke nearer than %.0f m" % band.x
			if not lines.any(_ahead.bind(history, p, band.y)):
				return "walking in toward Tu crosses nothing within %.0f m" % band.y
			for site in _sites_within(history, p, tuning.start_deep_m):
				if not site.source in [&"grid", &"wreck_field", &"hermit", &"nomads"]:
					return "a %s (%s) within %.0f m" % [site.kind, site.source, tuning.start_deep_m]
		&"wreck_field":
			if not _sites_within(history, p, tuning.start_wrecks_m).any(func(site: Dictionary) -> bool:
					return site.kind == &"wreck_hull" and site.source == &"wreck_field"):
				return "no wreck field's hull within %.0f m" % tuning.start_wrecks_m
		&"wayshrine":
			var road := _samples(history, p, 50.0, func(path: PathNetwork.Path) -> bool:
				return path.carries & PathNetwork.ROAD and path.used_in(Eras.SECOND))
			if not road.any(func(x: Vector3) -> bool: return Sphere.angle(p, x) * r <= SAMPLE * 0.5):
				return "not on a road"
			if not _sites_within(history, p, tuning.start_wayshrine_m).any(func(site: Dictionary) -> bool:
					return site.kind == &"wayshrine"):
				return "no wayshrine within %.0f m" % tuning.start_wayshrine_m
		_:
			return "no rule"
	return ""


## Whether a line's point lies on the walk from p straight in toward Tu,
## within `reach` m of it.
func _ahead(x: Vector3, history: History, p: Vector3, reach: float) -> bool:
	var tu := Sphere.bearing(p, history.sub_tu)
	var pole := p.cross(Sphere.toward(p, tu, 0.01)).normalized()
	return absf(asin(x.dot(pole))) * history.radius < SAMPLE and absf(angle_difference(Sphere.bearing(p, x), tu)) < 0.5 \
		and Sphere.angle(p, x) * history.radius <= reach


## Every site history makes within `metres` of p.
func _sites_within(history: History, p: Vector3, metres: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for cell in history.cells.within(p, metres):
		for site in history.sites_in_cell(cell):
			if Sphere.angle(p, site.p) * history.radius <= metres:
				out.append(site)
	return out


## Points every SAMPLE m along the paths it keeps, within `metres` of p.
func _samples(history: History, p: Vector3, metres: float, keep: Callable) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for path in history.network.paths:
		if not keep.call(path):
			continue
		var s := 0.0
		while s <= path.length():
			var x := path.at(s)
			var off := Sphere.angle(p, x) * history.radius
			if off <= metres:
				out.append(x)
				s += SAMPLE
			else:
				# Nothing nearer than the gap till then.
				s += maxf(SAMPLE, off - metres)
	return out
