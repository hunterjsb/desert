extends Probe
## World system probe 3: the path network is the lore's. The main artery runs
## from the Rim depot through Sister, Halfrise and Port Morgan down to the
## black site and Halloran; every spoke leaves Port Morgan for the ring; the
## observatory's long spoke reaches the anti-Tu point; colonial lines run
## straight. History tapers: away from the landmarks, its sites, towns and
## paths are densest on the Rim, thinner in Mon, sparsest in Han; and much of
## the near side is left empty.

const SEEDS := [1234, 7, 99]
## Of the near side's cells, at least this share is reached by no path and
## no settlement.
const EMPTY := 0.4


## Towns are few enough that one seed's count is noise: summed over the seeds.
var _towns := {}
var _town_area := {}


func run() -> void:
	var tuning := Tuning.current()
	for run_seed: int in SEEDS:
		var history := History.new(run_seed, tuning)
		var network := history.network
		var stops := [&"rim_depot", &"sister", &"halfrise", &"port_morgan", &"pumpwell", &"saloon", &"black_site",
			&"halloran"]
		check(_artery_runs(history, stops), "seed %d: the artery runs the depot to Halloran by every stop" % run_seed)
		var spokes := network.paths.filter(func(p: PathNetwork.Path) -> bool: return p.kind == &"spoke")
		check(spokes.size() == tuning.spokes + 1 and spokes.all(func(p: PathNetwork.Path) -> bool:
			return absf(rad_to_deg(history.from_tu(p.points[-1])) - 90.0) < 0.05),
			"seed %d: %d spokes from Port Morgan to the ring" % [run_seed, spokes.size()])
		var long := network.paths.filter(func(p: PathNetwork.Path) -> bool: return p.kind == &"long_spoke")
		check(long.size() == 1 and Sphere.angle(long[0].points[-1], history.anti_tu) * history.radius < 1.0,
			"seed %d: the observatory's long spoke reaches the anti-Tu point" % run_seed)
		var bent := 0.0
		for path in network.paths:
			if path.eras == Eras.BITS[Eras.COLONIAL] or path.kind in [&"spoke", &"spur", &"long_spoke"]:
				for point in path.points:
					bent = maxf(bent, absf(Sphere.off_line(path.points[0], path.points[-1], point)) * history.radius)
		check(bent < 0.5, "seed %d: colonial lines run straight (%.2f m off)" % [run_seed, bent])
		_taper(history, run_seed)
	var per := func(region: StringName) -> float: return _towns.get(region, 0.0) / _town_area[region]
	print("towns per km² over the seeds: rim %.3f mon %.3f han %.3f" % [per.call(&"rim"), per.call(&"mon"), per.call(&"han")])
	check(per.call(&"rim") > per.call(&"mon") and per.call(&"mon") > per.call(&"han"),
		"towns richest on the Rim, thinner in Mon, sparsest in Han")


## How built up history is, by region, away from the landmarks' own ground
## (they're fixed, and the taper is what history scattered between them):
## sites and path per km² over every fourth cell, without the survey grid and
## the wrecks that crash anywhere, and towns over every cell, but the named.
func _taper(history: History, run_seed: int) -> void:
	var area := {}
	var built := {}
	var path_m := {}
	var empty := 0
	var near := 0
	var town_cells := {}
	for each in history.settlements:
		if each.kind in [&"frontier_town", &"first_town", &"village", &"rim_town", &"salvage_town"] and each.name == "":
			town_cells[history.cells.cell_at(each.p)] = town_cells.get(history.cells.cell_at(each.p), 0) + 1
	var km2 := pow(history.cells.size, 2) / 1e6
	for cell in history.cells.count:
		var middle := history.cells.center(cell)
		if history.from_tu(middle) < PI * 0.5:
			near += 1
			if history.paths_in_cell(cell).is_empty() and not history._cell_settlements.has(cell):
				empty += 1
		if history.landmarks.any(func(l: Dictionary) -> bool:
				return Sphere.angle(middle, l.p) * history.radius < l.radius + 2000.0):
			continue
		var region := history.region_of(middle)
		_town_area[region] = _town_area.get(region, 0.0) + km2
		_towns[region] = _towns.get(region, 0.0) + town_cells.get(cell, 0)
		if cell % 4 != 0:
			continue
		area[region] = area.get(region, 0.0) + km2
		for site in history.sites_in_cell(cell):
			if site.source != &"grid" and site.source != &"wreck_field":
				built[region] = built.get(region, 0.0) + 1.0
		var reaching := history.paths_in_cell(cell)
		for id: int in reaching:
			path_m[region] = path_m.get(region, 0.0) + minf(reaching[id].y - reaching[id].x, history.cells.size * 2.0)
	var per := func(of: Dictionary, region: StringName) -> float: return of.get(region, 0.0) / area[region]
	print("seed %d, per km²: sites rim %.2f mon %.2f han %.2f; path m rim %.0f mon %.0f han %.0f; near side %d%% empty"
		% [run_seed, per.call(built, &"rim"), per.call(built, &"mon"), per.call(built, &"han"), per.call(path_m, &"rim"),
		per.call(path_m, &"mon"), per.call(path_m, &"han"), roundi(100.0 * empty / near)])
	for of: Dictionary in [built, path_m]:
		check(per.call(of, &"rim") > per.call(of, &"mon") and per.call(of, &"mon") > per.call(of, &"han"),
			"seed %d: %s richest on the Rim, thinner in Mon, sparsest in Han" % [run_seed, "sites" if of == built else "paths"])
	check(float(empty) / near >= EMPTY, "seed %d: much of the near side left empty (%d%%)" % [run_seed, roundi(100.0 * empty / near)])


## Whether artery paths join each stop to the next.
func _artery_runs(history: History, stops: Array) -> bool:
	var places := {}
	for place in history.network.places:
		if place.kind in stops:
			places[place.kind] = place.id
	for i in stops.size() - 1:
		var a: int = places.get(stops[i], -1)
		var b: int = places.get(stops[i + 1], -2)
		if not history.network.paths.any(func(p: PathNetwork.Path) -> bool:
				return p.kind == &"artery" and ((p.a == a and p.b == b) or (p.a == b and p.b == a))):
			return false
	return true
