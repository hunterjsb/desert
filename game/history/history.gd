class_name History
extends RefCounted
## The plan of the whole moon, made once a run from the seed, on the sphere:
## the point under Tu, the eight landmarks, the ground they explain
## (Geology), every path and settlement, and, a cell at a time when asked,
## the sites they left. It runs the eras in part 5's order, colonial,
## collapse, skimmer era, First Kingdoms, Dark Age, second age, feral, sand,
## each reading what the ones before left, so history holds together per
## seed. It never changes during a run.

## The fixed set (parts 4 and 5): id, name, footprint radius m, what shows
## first from the dunes, and parts as [id, name, right m, ahead m, radius m]
## in the landmark's own frame, ahead along its heading.
const LANDMARKS := [
	[&"halloran", "Halloran and Aitch", 1200.0, "refinery stacks on the terraces",
		[[&"refinery", "the refinery terraces", 0.0, 0.0, 250.0], [&"muster", "Muster", 0.0, 220.0, 150.0],
		[&"crossing", "the Crossing", -300.0, 0.0, 60.0], [&"aitch", "Aitch", -600.0, 0.0, 400.0]]],
	[&"black_site", "the black site", 300.0, "a blast door in the rift wall",
		[[&"bunker", "the Quartermaster's bunker", 0.0, 0.0, 60.0], [&"specimen_case", "the specimen case", 0.0, -15.0, 5.0]]],
	[&"port_morgan", "Port Morgan", 1600.0, "pylons and pad lights over the plateau",
		[[&"bastion", "the Bastion", 0.0, 0.0, 300.0], [&"pads", "the Pads", 0.0, 700.0, 400.0],
		[&"crakeside", "Crakeside", 700.0, -200.0, 400.0], [&"lowtown", "Lowtown", -800.0, -100.0, 450.0],
		[&"haberjack_bunker", "the Haberjack bunker", 60.0, 40.0, 30.0]]],
	[&"halfrise", "Halfrise", 400.0, "walls on the Rim", [[&"citadel", "the citadel", 0.0, 0.0, 200.0]]],
	[&"sister", "Sister", 300.0, "the temple's dome",
		[[&"temple", "Mother Cistern's temple", 0.0, 0.0, 80.0], [&"basin", "the basin", 20.0, 10.0, 10.0],
		[&"seed_vault", "the seed vault", -30.0, -20.0, 15.0]]],
	[&"rim_depot", "the Rim depot", 400.0, "launch rails",
		[[&"depot_pads", "the hopper pads", 0.0, 0.0, 250.0], [&"rail_yard", "the rail yard", 0.0, 300.0, 150.0]]],
	[&"starcom", "Starcom", 150.0, "the mast", [[&"antenna", "the antenna", 0.0, 0.0, 60.0]]],
	[&"observatory", "the observatory", 3000.0, "the tower over the volcano",
		[[&"tower", "the elevator stub's tower", 0.0, 0.0, 40.0], [&"vent_cap", "the vent cap", 0.0, 0.0, 120.0]]],
]
## Parts by the ids older profiles counted them by (session 5's renames).
const RENAMED := {&"kesselside": &"crakeside", &"okafor_bunker": &"haberjack_bunker"}
## Where they stand, by rule (defaults): angles from the point under Tu,
## degrees, or distances from the landmark placed before, m.
const HALLORAN := Vector2(3.0, 5.0)
const BLACK_SITE := Vector2(1000.0, 1600.0)
const PORT_MORGAN := Vector2(38.0, 48.0)
const HALFRISE := Vector2(88.5, 90.0)
const SISTER := Vector2(1600.0, 2600.0)
const RIM_DEPOT := Vector2(700.0, 1200.0)
const STARCOM := Vector2(50.0, 68.0)
const STARCOM_OFF := Vector2(40.0, 75.0)
## Spokes leave Port Morgan this many degrees either side of straight out
## from Tu; the observatory's takes one of the two nearest.
const SPOKE_SLOTS: Array[float] = [-85.0, -58.0, -30.0, 30.0, 58.0, 85.0]
## Nodes round the ring at least this often, degrees of the Rim.
const RING_EVERY := 15.0

## What history places along a path, as rows: the kind, what the path must
## have carried and in which era, how often along it (m, at full richness),
## how far to the side (m), whether always the same side, whether it faces the
## path or runs with it, and which kinds of path only. Defaults.
const ROWS := [
	{"kind": &"pylon_stub", "carries": PathNetwork.POWER, "era": Eras.COLONIAL, "every": 150.0, "side": [8.0, 12.0],
		"one_side": true, "runs": true},
	{"kind": &"pipeline_segment", "carries": PathNetwork.PIPE, "era": Eras.COLONIAL, "every": 120.0,
		"side": [0.0, 2.0], "one_side": true, "runs": true},
	{"kind": &"relay_mast", "carries": PathNetwork.ROAD, "era": Eras.COLONIAL, "every": 1500.0, "side": [15.0, 40.0],
		"paths": [&"artery", &"spoke", &"long_spoke", &"spur"]},
	{"kind": &"hab_pod", "carries": PathNetwork.ROAD, "era": Eras.COLONIAL, "every": 2500.0, "side": [20.0, 55.0],
		"paths": [&"artery", &"spoke"]},
	{"kind": &"dugout", "carries": PathNetwork.ROAD, "era": Eras.SKIMMER, "every": 2000.0, "side": [20.0, 55.0]},
	{"kind": &"fuel_bladder", "carries": PathNetwork.TRACK, "era": Eras.SKIMMER, "every": 900.0, "side": [5.0, 30.0]},
	{"kind": &"low_wall", "carries": PathNetwork.WATER, "era": Eras.FIRST, "every": 900.0, "side": [5.0, 30.0]},
	{"kind": &"pipe_wall_hut", "carries": PathNetwork.ROAD, "era": Eras.FIRST, "every": 1800.0, "side": [15.0, 50.0],
		"paths": [&"artery", &"spoke", &"ring"]},
	{"kind": &"low_wall", "carries": PathNetwork.TRACK, "era": Eras.FIRST, "every": 400.0, "side": [4.0, 25.0]},
	# The Dark Age's markers on the migration routes: cairns marking water,
	# caches, the first deliberate saltbush plantings.
	{"kind": &"cairn", "carries": PathNetwork.WATER, "era": Eras.FIRST, "every": 1200.0, "side": [3.0, 15.0]},
	{"kind": &"cache", "carries": PathNetwork.WATER, "era": Eras.FIRST, "every": 3500.0, "side": [5.0, 25.0]},
	{"kind": &"saltbush_planting", "carries": PathNetwork.WATER, "era": Eras.FIRST, "every": 800.0, "side": [2.0, 6.0]},
	{"kind": &"wayshrine", "carries": PathNetwork.ROAD, "era": Eras.SECOND, "every": 700.0, "side": [6.0, 20.0]},
	{"kind": &"watchtower", "carries": PathNetwork.ROAD, "era": Eras.SECOND, "every": 2500.0, "side": [10.0, 40.0]},
	{"kind": &"house_ruin", "carries": PathNetwork.ROAD, "era": Eras.SECOND, "every": 1200.0, "side": [25.0, 55.0],
		"paths": [&"road", &"pilgrim_road", &"ring", &"artery"]},
	# A day's walk apart on the artery: 20 minutes at a walk, about 2.2 km.
	{"kind": &"caravanserai", "carries": PathNetwork.ROAD, "era": Eras.SECOND, "every": 2200.0, "side": [30.0, 55.0],
		"paths": [&"artery"]},
	# A freighter's lifeboats, down on the port's approach: off its roads,
	# only within "near" of it, m.
	{"kind": &"lifeboat", "carries": PathNetwork.ROAD, "era": Eras.COLONIAL, "every": 2500.0, "side": [30.0, 90.0],
		"paths": [&"artery", &"spoke", &"spur"], "near": [&"port_morgan", 16000.0]},
	# The Knights' hoppers, down along the crusade's road to Port Morgan.
	{"kind": &"hopper", "carries": PathNetwork.ROAD, "era": Eras.SECOND, "every": 6000.0, "side": [30.0, 90.0],
		"paths": [&"artery"]},
]
## What each kind of settlement is made of: its era, radius m, and members
## as [kind, least, most]. Defaults.
const MEMBERS := {
	&"frontier_town": [Eras.COLONIAL, 260.0, [[&"hab_pod", 4, 9], [&"relay_mast", 1, 1], [&"pump_station", 0, 1],
		[&"freight_pod", 0, 1]]],
	&"pump_station": [Eras.COLONIAL, 60.0, [[&"pump_station", 1, 1], [&"hab_pod", 0, 2]]],
	&"farm_dome": [Eras.COLONIAL, 200.0, [[&"farm_dome", 2, 4], [&"hab_pod", 1, 2]]],
	&"vent_station": [Eras.COLONIAL, 90.0, [[&"vent_station", 1, 1], [&"pipeline_segment", 2, 4]]],
	&"skimmer_camp": [Eras.SKIMMER, 130.0, [[&"fuel_bladder", 1, 3], [&"dugout", 1, 2], [&"wreck_hull", 0, 1]]],
	&"checkpoint": [Eras.SKIMMER, 50.0, [[&"checkpoint", 1, 1], [&"dugout", 0, 1], [&"tithe_hauler", 0, 1]]],
	&"wreck_field": [Eras.SKIMMER, 150.0, [[&"wreck_hull", 2, 5], [&"fuel_bladder", 0, 2], [&"tithe_hauler", 0, 1]]],
	&"first_town": [Eras.FIRST, 230.0, [[&"pipe_wall_hut", 3, 7], [&"low_wall", 1, 3], [&"generator_shrine", 0, 1],
		[&"cistern", 0, 1]]],
	&"cistern": [Eras.FIRST, 60.0, [[&"cistern", 1, 1], [&"low_wall", 0, 2]]],
	&"hermit": [Eras.FIRST, 20.0, [[&"pipe_wall_hut", 1, 1]]],
	&"village": [Eras.SECOND, 250.0, [[&"house_ruin", 3, 7], [&"granary", 0, 1], [&"stepwell", 0, 1],
		[&"watchtower", 0, 1]]],
	&"rim_town": [Eras.SECOND, 300.0, [[&"house_ruin", 4, 9], [&"granary", 1, 1], [&"stepwell", 0, 1],
		[&"ration_gate", 0, 1], [&"watchtower", 0, 1]]],
	&"salvage_town": [Eras.SECOND, 280.0, [[&"house_ruin", 3, 6], [&"watchtower", 1, 1], [&"stepwell", 0, 1]]],
	&"battlefield": [Eras.SECOND, 300.0, [[&"earthwork", 3, 6], [&"watchtower", 0, 1]]],
	&"bunker": [Eras.SECOND, 60.0, [[&"bunker", 1, 1], [&"hopper", 0, 1]]],
}
## Settlements history built along paths, at full richness: [kind, every m,
## kept share at no richness and its rise with richness, m to the side].
const ALONG := {
	&"frontier_town": [4000.0, 0.1, 0.9, Vector2(100.0, 400.0)],
	&"pump_station": [4000.0, 0.8, 0.0, Vector2(20.0, 60.0)],
	&"first_town": [2500.0, 0.05, 0.9, Vector2(60.0, 260.0)],
	&"rim_town": [2500.0, 0.0, 1.0, Vector2(80.0, 300.0)],
}
## A second-age village rises on a First Kingdoms town this often, by region.
const RESETTLED := {&"han": 0.15, &"mon": 0.45, &"rim": 0.85, &"far": 0.2}
## A skimmer camp scars a colonial settlement this often, by region.
const SCARRED := {&"han": 0.6, &"mon": 0.25, &"rim": 0.08, &"far": 0.05}
## The survey grid's spacing, degrees (2.5 km), and every how many a relay tower.
const GRID := 6.0
const RELAY_EVERY := 2
## History thins toward the calm poles: from the first latitude to the
## second, degrees, down to this share. Default.
const POLES := Vector3(50.0, 80.0, 0.3)
## How likely a cell holds a wreck field, under Tu and far from it; and a
## hermit, where no path or settlement reaches.
const WRECKS := Vector2(0.02, 0.002)

const HERMITS := 0.012
## How likely a cell holds a nomads' wrecked rig, anywhere, wilds and all;
## and one of their camps, kept and just left: the moon is presumed empty.
const NOMAD_RIGS := 0.08
const NOMAD_CAMPS := 0.002

var run_seed: int
var radius: float
var cells: MoonCells
var network: PathNetwork
var geology: Geology
var sub_tu: Vector3
var anti_tu: Vector3
## The bearing the axis leaves the point under Tu at, rad.
var axis: float
## Each landmark: {id, name, p, bearing, radius, shows, region, parts: [{id, name, p, radius}]}.
var landmarks: Array[Dictionary] = []
## Each settlement: {id, kind, era, p, radius, region, place, name}.
var settlements: Array[Dictionary] = []

var _by_id := {}
## Per cell: the paths reaching it, {path id: Vector2(from m, to m) along it}, and the settlements.
var _cell_paths := {}
var _cell_settlements := {}
## Per cell: the live vents whose mouths reach it, by index in geology's vents.
var _cell_vents := {}
var _bounds := PackedFloat64Array()
var _richness := PackedFloat64Array()
## Named places on the network, by landmark or part id.
var _at := {}


func _init(seed_value: int, tuning: Tuning) -> void:
	run_seed = seed_value
	radius = tuning.moon_circumference / TAU
	cells = MoonCells.new(radius, tuning.history_cell_m)
	network = PathNetwork.new(radius)
	for degrees: float in [tuning.region_han_degrees, tuning.region_mon_degrees, tuning.region_rim_degrees]:
		_bounds.append(deg_to_rad(degrees))
	_richness = PackedFloat64Array([tuning.richness_han, tuning.richness_mon, tuning.richness_rim, tuning.richness_far])
	sub_tu = Sphere.point(0.0, deg_to_rad(tuning.tu_longitude_degrees))
	anti_tu = -sub_tu
	var rng := _stream(["axis"])
	var spread := deg_to_rad(tuning.axis_spread_degrees)
	axis = (PI * 0.5 if rng.randf() < 0.5 else -PI * 0.5) + rng.randf_range(-spread, spread)
	_landmarks()
	geology = Geology.new(run_seed, radius, landmark(&"halloran"), landmark(&"observatory"))
	_colonial(tuning.spokes)
	_skimmer()
	_first_kingdoms()
	# The Dark Age leaves no sites: its rule is Eras.lineage, and its markers
	# are rows on the First Kingdoms' water lines.
	_second_age()
	_tracks()
	_register()


## How far a place is from the point under Tu, rad: Tu stands 90° less than
## this over its horizon.
func from_tu(p: Vector3) -> float:
	return Sphere.angle(sub_tu, p)


## How high Tu stands over a place, as said: below the horizon on the far side.
func tu_words(p: Vector3) -> String:
	var height := roundi(90.0 - rad_to_deg(from_tu(p)))
	return "Tu %d° up" % height if height >= 0 else "Tu below the horizon"


func region_of(p: Vector3) -> StringName:
	var by := from_tu(p)
	if by < _bounds[0]:
		return &"han"
	if by < _bounds[1]:
		return &"mon"
	return &"rim" if by <= _bounds[2] else &"far"


## How built up history left a place, 0 to 1: rich at the Rim, thinner in
## Mon, sparse and grim in Han, blended over 5° at each edge, and thinner
## toward the calm poles.
func richness(p: Vector3) -> float:
	var by := from_tu(p)
	var blend := deg_to_rad(5.0)
	var value := _richness[0]
	for i in 3:
		value = lerpf(value, _richness[i + 1], smoothstep(_bounds[i] - blend, _bounds[i] + blend, by))
	var lat := absf(rad_to_deg(Sphere.latitude(p)))
	return value * lerpf(1.0, POLES.z, smoothstep(POLES.x, POLES.y, lat))


func landmark(id: StringName) -> Dictionary:
	return _by_id.get(id, {})


## The nearest landmark to a place however far: {landmark, metres, bearing (rad
## clockwise from north there)}.
func nearest_landmark(p: Vector3) -> Dictionary:
	var best := {}
	var near := INF
	for each in landmarks:
		var by := Sphere.angle(p, each.p) * radius
		if by < near:
			near = by
			best = {"landmark": each, "metres": by, "bearing": Sphere.bearing(p, each.p)}
	return best


## The paths that reach a cell: {path id: Vector2(from, to) m along each}.
func paths_in_cell(cell: int) -> Dictionary:
	return _cell_paths.get(cell, {})


## A cell's sites, made fresh each time from the plan: along the paths that
## reach it, in the settlements that do, and off the network. Each site:
## {id, kind, era, p, bearing, reach, depth, tilt, loot, source, region}.
func sites_in_cell(cell: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for part in cell_parts(cell):
		sites_of(cell, part, out)
	return out


## A cell's sites come in parts, each a small piece of work: one for each
## path that reaches it, one for each settlement, one for each live vent's
## mouth, and one off the network.
func cell_parts(cell: int) -> Array[Array]:
	var parts: Array[Array] = []
	var reaching: Dictionary = _cell_paths.get(cell, {})
	for path_id: int in reaching:
		parts.append([&"path", path_id, reaching[path_id]])
	for i: int in _cell_settlements.get(cell, PackedInt32Array()):
		parts.append([&"settlement", i])
	for i: int in _cell_vents.get(cell, PackedInt32Array()):
		parts.append([&"vent", i])
	parts.append([&"off"])
	return parts


## One part's sites in a cell, onto `out`.
func sites_of(cell: int, part: Array, out: Array[Dictionary]) -> void:
	match part[0]:
		&"path":
			_along(network.paths[part[1]], part[2], cell, out)
		&"settlement":
			_members(settlements[part[1]], cell, out)
		&"vent":
			_mouth(part[1], cell, out)
		_:
			_off_network(cell, out)


# --- The colonial layer: the landmarks, then the skeleton between them. ---

func _landmarks() -> void:
	var rng := _stream(["landmarks"])
	var halloran := _on_axis(rng.randf_range(HALLORAN.x, HALLORAN.y))
	var out := Sphere.bearing(halloran, anti_tu)
	# The rift runs across the axis.
	_landmark(0, halloran, out + PI * 0.5 + deg_to_rad(rng.randf_range(-20.0, 20.0)))
	var black := Sphere.toward(halloran, out, rng.randf_range(BLACK_SITE.x, BLACK_SITE.y) / radius)
	_landmark(1, black, out)
	var port := _on_axis(rng.randf_range(PORT_MORGAN.x, PORT_MORGAN.y))
	_landmark(2, port, Sphere.bearing(port, anti_tu))
	var halfrise := _on_axis(rng.randf_range(HALFRISE.x, HALFRISE.y))
	_landmark(3, halfrise, Sphere.bearing(halfrise, port))
	# Sister along the Rim from Halfrise, either way; the depot past it.
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var sister := _on_rim(Sphere.toward(halfrise, Sphere.bearing(halfrise, sub_tu) + side * PI * 0.5,
		rng.randf_range(SISTER.x, SISTER.y) / radius), rng.randf_range(-0.5, 0.5))
	_landmark(4, sister, Sphere.bearing(sister, halfrise))
	var depot := _on_rim(Sphere.toward(sister, Sphere.bearing(sister, halfrise) + PI,
		rng.randf_range(RIM_DEPOT.x, RIM_DEPOT.y) / radius), rng.randf_range(0.0, 0.5))
	_landmark(5, depot, Sphere.bearing(depot, port))
	var off := deg_to_rad(rng.randf_range(STARCOM_OFF.x, STARCOM_OFF.y)) * (1.0 if rng.randf() < 0.5 else -1.0)
	var starcom := Sphere.toward(sub_tu, axis + off, deg_to_rad(rng.randf_range(STARCOM.x, STARCOM.y)))
	_landmark(6, starcom, Sphere.bearing(starcom, port))
	_landmark(7, anti_tu, 0.0)


func _landmark(i: int, p: Vector3, heading: float) -> void:
	var row: Array = LANDMARKS[i]
	var made := {"id": row[0], "name": row[1], "p": p, "bearing": heading, "radius": row[2], "shows": row[3],
		"region": region_of(p), "parts": []}
	for part: Array in row[4]:
		var aside := Vector2(part[2], part[3])
		var at := p
		if aside != Vector2.ZERO:
			at = Sphere.toward(p, heading + atan2(aside.x, aside.y), aside.length() / radius)
		made.parts.append({"id": part[0], "name": part[1], "p": at, "radius": part[4]})
		_at[part[0]] = network.place(at, part[0], Eras.COLONIAL, part[1])
	landmarks.append(made)
	_by_id[row[0]] = made
	_at[row[0]] = network.place(p, row[0], Eras.COLONIAL, row[1])


func _colonial(spokes: int) -> void:
	var col := [Eras.COLONIAL, Eras.FIRST, Eras.SECOND]
	var han := [Eras.COLONIAL, Eras.SKIMMER, Eras.FIRST, Eras.SECOND]
	var port: Vector3 = landmark(&"port_morgan").p
	var black: Vector3 = landmark(&"black_site").p
	# The main artery: the depot's rail and truck line to Port Morgan, which
	# later roads follow, the aqueduct out to the Rim, then the road down to Han.
	var rng := _stream(["artery"])
	var pumpwell := network.place(_aside(port.slerp(black, 1.0 / 3.0), rng.randf_range(100.0, 300.0), rng),
		&"pumpwell", Eras.SECOND, "Pumpwell")
	var saloon := network.place(_aside(port.slerp(black, 2.0 / 3.0), rng.randf_range(100.0, 300.0), rng),
		&"saloon", Eras.SECOND, "Saloon")
	var rail := PathNetwork.ROAD | PathNetwork.RAIL | PathNetwork.POWER
	_join(&"rim_depot", &"sister", &"artery", col, rail)
	_join(&"sister", &"halfrise", &"artery", col, rail | PathNetwork.WATER)
	_join(&"halfrise", &"port_morgan", &"artery", col, rail | PathNetwork.WATER)
	var down := PathNetwork.ROAD | PathNetwork.PIPE | PathNetwork.POWER
	_link(_at[&"port_morgan"], pumpwell, &"artery", han, down, 1.0, 0.0)
	_link(pumpwell, saloon, &"artery", han, down, 1.0, 0.0)
	_link(saloon, _at[&"black_site"], &"artery", han, down, 1.0, 0.0)
	_join(&"black_site", &"halloran", &"artery", han, down)
	_join(&"halloran", &"crossing", &"track", han, PathNetwork.ROAD)
	_join(&"crossing", &"aitch", &"track", han, PathNetwork.ROAD)
	_settle(&"pump_station", network.places[pumpwell].p)
	_settle(&"salvage_town", network.places[pumpwell].p, pumpwell, "Pumpwell")
	_settle(&"frontier_town", network.places[saloon].p)
	_settle(&"salvage_town", network.places[saloon].p, saloon, "Saloon")
	# Spokes out to the ring, the observatory's own long spoke across the dark,
	# and Starcom's spur.
	var out := Sphere.bearing(port, anti_tu)
	var slots := SPOKE_SLOTS.duplicate()
	var observatory_slot := 2 if rng.randf() < 0.5 else 3
	var gates: Array[int] = []
	for k in mini(spokes + 1, slots.size()):
		var bearing := out + deg_to_rad(slots[k] + rng.randf_range(-6.0, 6.0))
		var gate := network.place(_rim_crossing(port, bearing), &"gate", Eras.COLONIAL)
		gates.append(gate)
		_link(_at[&"port_morgan"], gate, &"spoke", col, PathNetwork.ROAD | PathNetwork.POWER, 0.8, 0.0)
		if k == observatory_slot:
			_link(gate, _at[&"observatory"], &"long_spoke", [Eras.COLONIAL, Eras.SECOND],
				PathNetwork.ROAD | PathNetwork.POWER, 0.5, 0.0)
	_join(&"port_morgan", &"starcom", &"spur", [Eras.COLONIAL], PathNetwork.ROAD | PathNetwork.POWER, 0.6)
	_ring(gates)
	# Han: the refinery's pipelines along the rift to its vent stations, on
	# the vents live then, and the vent power the whole place ran on.
	for each in geology.tapped():
		var vent := network.place(each.p, &"vent", Eras.COLONIAL)
		_link(_at[&"halloran"], vent, &"pipeline", [Eras.COLONIAL], PathNetwork.PIPE | PathNetwork.POWER, 1.0, 0.0)
		_settle(&"vent_station", each.p, vent)
	# Colonial settlements on the skeleton: frontier towns on the plains,
	# pump stations on the aqueducts, Frontier Ag's domes near the Rim.
	for path: PathNetwork.Path in network.paths.duplicate():
		if not path.used_in(Eras.COLONIAL) or not path.kind in [&"artery", &"spoke", &"long_spoke", &"spur", &"ring"]:
			continue
		_along_path(path, &"frontier_town")
		if path.carries & PathNetwork.WATER:
			_along_path(path, &"pump_station")
		if path.kind in [&"spoke", &"ring"]:
			_domes(path)


## Round the Rim: through the spokes' gates, Halfrise and the depot, and a node
## at least every RING_EVERY degrees. Colonial on the stretch toward Port
## Morgan, the second age's all round, busiest near Halfrise.
func _ring(gates: Array[int]) -> void:
	var u := _rim_point(landmark(&"halfrise").p)
	var v := sub_tu.cross(u).normalized()
	var round := func(p: Vector3) -> float: return atan2(p.dot(v), p.dot(u))
	var nodes: Array[Array] = []
	for id: int in gates + [_at[&"halfrise"], _at[&"rim_depot"]]:
		nodes.append([round.call(network.places[id].p), id])
	var step := deg_to_rad(RING_EVERY)
	for k in roundi(TAU / step):
		var at := -PI + (k + 0.5) * step
		if nodes.all(func(n: Array) -> bool: return absf(angle_difference(n[0], at)) > step * 0.45):
			nodes.append([at, network.place(u * cos(at) + v * sin(at), &"rim_node", Eras.COLONIAL)])
	nodes.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var artery := [_at[&"halfrise"], _at[&"rim_depot"]]
	for i in nodes.size():
		var a: Array = nodes[i]
		var b: Array = nodes[(i + 1) % nodes.size()]
		# Halfrise to the depot is the artery's, by way of Sister.
		if a[1] in artery and b[1] in artery:
			continue
		var from_halfrise := maxf(absf(a[0]), absf(b[0]))
		var eras := [Eras.FIRST, Eras.SECOND]
		if from_halfrise <= deg_to_rad(80.0):
			eras.append(Eras.COLONIAL)
		var mid := absf(angle_difference(0.0, (a[0] + angle_difference(a[0], b[0]) * 0.5)))
		_link(a[1], b[1], &"ring", eras, PathNetwork.ROAD, 0.35 + 0.65 * pow(cos(mid * 0.5), 2.0), 0.02)


func _domes(path: PathNetwork.Path) -> void:
	var rng := _stream(["domes", path.id])
	var s := 1500.0
	while s < path.length():
		var p := path.at(s)
		var by := rad_to_deg(from_tu(p))
		if by >= 78.0 and by <= 96.0 and rng.randf() < 0.45 * richness(p) * path.richness:
			_settle(&"farm_dome", _aside(p, rng.randf_range(80.0, 300.0), rng))
		s += 3000.0


# --- The skimmer era: scars on colonial structures, and wrecks toward Han. ---

func _skimmer() -> void:
	for i in settlements.size():
		var each: Dictionary = settlements[i]
		if each.era != Eras.COLONIAL:
			continue
		var rng := _stream(["scar", i])
		if rng.randf() < SCARRED[each.region]:
			_settle(&"skimmer_camp", _aside(each.p, rng.randf_range(40.0, 150.0), rng))
	# Black-site checkpoints on the artery round the rift.
	var black: Vector3 = landmark(&"black_site").p
	for path: PathNetwork.Path in network.paths.duplicate():
		if path.kind != &"artery" or not path.used_in(Eras.SKIMMER):
			continue
		var rng := _stream(["checkpoints", path.id])
		var s := 750.0
		while s < path.length():
			var p := path.at(s)
			if Sphere.angle(p, black) * radius < 6000.0 and rng.randf() < 0.7:
				_settle(&"checkpoint", _aside(p, rng.randf_range(20.0, 40.0), rng))
			s += 1500.0
	# Skimmer tracks out from Halloran to the wreck fields.
	var rng := _stream(["fields"])
	for k in rng.randi_range(2, 3):
		var at := Sphere.toward(sub_tu, rng.randf() * TAU, rng.randf_range(2000.0, 6000.0) / radius)
		var field := network.place(at, &"wreck_field", Eras.SKIMMER)
		_settle(&"wreck_field", at, field)
		_link(_at[&"halloran"], field, &"track", [Eras.SKIMMER], PathNetwork.TRACK, 1.0, 0.15)


# --- The First Kingdoms: along the dead colonial lines and by water. ---

func _first_kingdoms() -> void:
	for path: PathNetwork.Path in network.paths.duplicate():
		if path.used_in(Eras.COLONIAL) and path.kind != &"track" and path.kind != &"long_spoke":
			_along_path(path, &"first_town")
	# Cisterns where the colonial water lines ended, and at their pumps.
	var ends := {}
	for path: PathNetwork.Path in network.paths.duplicate():
		if path.carries & PathNetwork.WATER and path.used_in(Eras.COLONIAL):
			for end in [path.a, path.b]:
				if ends.has(end):
					continue
				ends[end] = true
				var rng := _stream(["cistern", end])
				_settle(&"cistern", _aside(network.places[end].p, rng.randf_range(40.0, 120.0), rng))
	for i in settlements.size():
		var rng := _stream(["well", i])
		if settlements[i].kind == &"pump_station" and rng.randf() < 0.5:
			_settle(&"cistern", _aside(settlements[i].p, rng.randf_range(30.0, 90.0), rng))
	# First-age water lines link each to its nearest neighbour.
	_link_nearest([&"first_town", &"cistern"], 3500.0, 1, &"water_line", [Eras.FIRST], PathNetwork.WATER, 0.05)


# --- The second age: on and near the First Kingdoms, most on the Rim. ---

func _second_age() -> void:
	for i in settlements.size():
		var each: Dictionary = settlements[i]
		if each.kind != &"first_town":
			continue
		var rng := _stream(["resettled", i])
		if rng.randf() < RESETTLED[each.region]:
			_settle(&"village", _aside(each.p, rng.randf_range(0.0, 350.0), rng))
	for path: PathNetwork.Path in network.paths.duplicate():
		if path.kind == &"ring":
			_along_path(path, &"rim_town")
	# The late wars round Halfrise, and crusader bunkers on colonial sites
	# near Port Morgan.
	var halfrise: Vector3 = landmark(&"halfrise").p
	var rng := _stream(["battles"])
	for k in rng.randi_range(2, 3):
		_settle(&"battlefield", Sphere.toward(halfrise, rng.randf() * TAU, rng.randf_range(1000.0, 3500.0) / radius))
	var port: Vector3 = landmark(&"port_morgan").p
	for i in settlements.size():
		var each: Dictionary = settlements[i]
		var near := _stream(["bunker", i])
		if each.kind == &"frontier_town" and Sphere.angle(each.p, port) * radius < 8000.0 and near.randf() < 0.5:
			_settle(&"bunker", _aside(each.p, near.randf_range(10.0, 60.0), near))
	# Roads between neighbouring towns, and pilgrim roads to Sister.
	_link_nearest([&"village", &"rim_town", &"salvage_town"], 4000.0, 2, &"road", [Eras.SECOND], PathNetwork.ROAD, 0.08)
	var towns := settlements.filter(func(s: Dictionary) -> bool: return s.kind in [&"village", &"rim_town"])
	var sister: Vector3 = landmark(&"sister").p
	towns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Sphere.angle(a.p, sister) < Sphere.angle(b.p, sister))
	for each in towns.slice(0, 3):
		if Sphere.angle(each.p, sister) * radius < 8000.0:
			_link(_at[&"sister"], each.place, &"pilgrim_road", [Eras.SECOND], PathNetwork.ROAD, 1.0, 0.1)


## Minor paths and farm tracks: from each town out to its fields and wells.
func _tracks() -> void:
	for i in settlements.size():
		var each: Dictionary = settlements[i]
		if not each.kind in [&"frontier_town", &"first_town", &"village", &"rim_town", &"salvage_town"]:
			continue
		var rng := _stream(["tracks", i])
		for k in 1 + roundi(2.0 * richness(each.p) * rng.randf()):
			var end := network.place(Sphere.toward(each.p, rng.randf() * TAU, rng.randf_range(300.0, 900.0) / radius),
				&"field", each.era)
			_link(each.place, end, &"track", [each.era], PathNetwork.TRACK, 1.0, 0.1)


# --- Settlements and paths, as the layers make them. ---

## Settlements of a kind along a path, every so often, thinning as richness falls.
func _along_path(path: PathNetwork.Path, kind: StringName) -> void:
	var rule: Array = ALONG[kind]
	var rng := _stream(["along", kind, path.id])
	var s: float = rule[0] * 0.5
	while s < path.length():
		var p := path.at(s + rng.randf_range(-0.25, 0.25) * rule[0])
		var keep: float = (rule[1] + rule[2] * richness(p)) * path.richness
		var side: Vector2 = rule[3]
		if rng.randf() < keep and not _in_landmark(p):
			_settle(kind, _aside(p, rng.randf_range(side.x, side.y), rng))
		s += rule[0]


func _settle(kind: StringName, p: Vector3, place := -1, name := "") -> int:
	var spec: Array = MEMBERS[kind]
	var made := {"id": settlements.size(), "kind": kind, "era": spec[0], "p": p, "radius": spec[1],
		"region": region_of(p), "name": name,
		"place": place if place >= 0 else network.place(p, kind, spec[0], name)}
	settlements.append(made)
	return made.id


## Each settlement of the kinds joined to its nearest `most` others within
## `metres`, once a pair.
func _link_nearest(kinds: Array, metres: float, most: int, kind: StringName, eras: Array, carries: int,
		wander: float) -> void:
	# Buckets of `metres` on the moon's chord, so neighbours are in the 27 round one.
	var bucket := func(p: Vector3) -> Vector3i: return Vector3i((p * radius / metres).floor())
	var some := settlements.filter(func(s: Dictionary) -> bool: return s.kind in kinds)
	var buckets := {}
	for each: Dictionary in some:
		var key: Vector3i = bucket.call(each.p)
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(each)
	var joined := {}
	for a: Dictionary in some:
		var key: Vector3i = bucket.call(a.p)
		var near := []
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					for b: Dictionary in buckets.get(key + Vector3i(dx, dy, dz), []):
						if b.id != a.id and Sphere.angle(a.p, b.p) * radius <= metres:
							near.append(b)
		near.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
			return Sphere.angle(a.p, x.p) < Sphere.angle(a.p, y.p))
		for b: Dictionary in near.slice(0, most):
			var pair := Vector2i(mini(a.id, b.id), maxi(a.id, b.id))
			if not joined.has(pair):
				joined[pair] = true
				_link(a.place, b.place, kind, eras, carries, 1.0, wander)


func _join(a: StringName, b: StringName, kind: StringName, eras: Array, carries: int, richness_share := 1.0) -> void:
	_link(_at[a], _at[b], kind, eras, carries, richness_share, 0.0)


func _link(a: int, b: int, kind: StringName, eras: Array, carries: int, richness_share: float,
		wander: float) -> PathNetwork.Path:
	return network.join(a, b, kind, eras, carries, richness_share, wander,
		hash([run_seed, "path", network.paths.size()]))


## Which cells each path and settlement reaches. A path reaches every cell
## its corridor touches, with the stretch along it that does.
func _register() -> void:
	var margin := PathNetwork.CORRIDOR + 10.0
	var tall := margin / radius
	for path in network.paths:
		# Each point's latitude and longitude once, the longitude unwrapped so
		# a stretch across the date line stays together.
		var count := path.points.size()
		var lats := PackedFloat64Array()
		var lons := PackedFloat64Array()
		lats.resize(count)
		lons.resize(count)
		for i in count:
			lats[i] = Sphere.latitude(path.points[i])
			var lon := Sphere.longitude(path.points[i])
			lons[i] = lon if i == 0 else lons[i - 1] + wrapf(lon - lons[i - 1], -PI, PI)
		# Four stretches at a time, about a kilometre.
		var i := 0
		while i < count - 1:
			var j := mini(i + 4, count - 1)
			var south := INF
			var north := -INF
			var west := INF
			var east := -INF
			for k in range(i, j + 1):
				south = minf(south, lats[k])
				north = maxf(north, lats[k])
				west = minf(west, lons[k])
				east = maxf(east, lons[k])
			south -= tall
			north += tall
			var wide := margin / (radius * cos(minf(maxf(absf(south), absf(north)), PI * 0.5 - 1e-3)))
			if east - west + 2.0 * wide >= TAU:
				west = -PI
				east = PI - 1e-9
				wide = 0.0
			var span := Vector2(path.lengths[i], path.lengths[j])
			for cell: int in cells.in_box(south, north, west - wide, east + wide):
				var reaching: Dictionary = _cell_paths.get(cell, {})
				if reaching.is_empty():
					_cell_paths[cell] = reaching
				var had: Vector2 = reaching.get(path.id, span)
				reaching[path.id] = Vector2(minf(had.x, span.x), maxf(had.y, span.y))
			i = j
	for each in settlements:
		_register_round(each.p, each.radius + 10.0, _cell_settlements, each.id)
	for i in geology.vents.size():
		if geology.vents[i].state == Geology.LIVE_VENT:
			_register_round(geology.vents[i].p, SiteKinds.reach(&"vent_mouth") + 10.0, _cell_vents, i)


## Puts `id` in the table of every cell within `metres` of a place.
func _register_round(p: Vector3, metres: float, table: Dictionary, id: int) -> void:
	var reach := metres / radius
	var lat := Sphere.latitude(p)
	var lon := Sphere.longitude(p)
	var wide := minf(reach / cos(minf(absf(lat) + reach, PI * 0.5 - 1e-3)), PI)
	for cell: int in cells.in_box(lat - reach, lat + reach, lon - wide, lon + wide):
		var held: PackedInt32Array = table.get(cell, PackedInt32Array())
		held.append(id)
		table[cell] = held


# --- Sites, a cell at a time. ---

func _along(path: PathNetwork.Path, span: Vector2, cell: int, out: Array[Dictionary]) -> void:
	for r in ROWS.size():
		var row: Dictionary = ROWS[r]
		if path.carries & row.carries == 0 or not path.used_in(row.era) \
				or (row.has("paths") and not path.kind in row.paths):
			continue
		var every: float = row.every
		for k in range(maxi(0, floori(span.x / every) - 1), ceili(span.y / every) + 1):
			var rng := _stream(["e", path.id, r, k])
			var s := (k + 0.5 + rng.randf_range(-0.3, 0.3)) * every
			if s < 0.0 or s > path.length():
				continue
			var on := path.at(s)
			if rng.randf() >= richness(on) * path.richness:
				continue
			if row.has("near") and Sphere.angle(on, landmark(row.near[0]).p) * radius > row.near[1]:
				continue
			var side := rng.randf_range(row.side[0], row.side[1])
			if not row.get("one_side", false) and rng.randf() < 0.5:
				side = -side
			var along := path.bearing_at(s)
			var p := Sphere.toward(on, along + PI * 0.5, side / radius) if side != 0.0 else on
			if cells.cell_at(p) != cell:
				continue
			var facing := along if row.get("runs", false) else along + (-PI * 0.5 if side > 0.0 else PI * 0.5)
			out.append(_site(row.kind, p, facing, rng, ["e", path.id, r, k], &"path"))


func _members(each: Dictionary, cell: int, out: Array[Dictionary]) -> void:
	var spec: Array = MEMBERS[each.kind]
	var rng := _stream(["s", each.id])
	var placed: Array[Array] = []
	var k := 0
	for entry: Array in spec[2]:
		for n in rng.randi_range(entry[1], entry[2]):
			var reach := SiteKinds.reach(entry[0])
			var at := Vector3.ZERO
			for tries in 8:
				var tried := Sphere.toward(each.p, rng.randf() * TAU, sqrt(rng.randf()) * each.radius / radius)
				if placed.all(func(o: Array) -> bool: return Sphere.angle(o[0], tried) * radius > o[1] + reach + 4.0):
					at = tried
					break
			if at != Vector3.ZERO:
				placed.append([at, reach])
				if cells.cell_at(at) == cell:
					var own := _stream(["m", each.id, k])
					out.append(_site(entry[0], at, own.randf() * TAU, own, ["s", each.id, k], each.kind))
			k += 1


## A live vent's mouth, in the cell its middle is in, facing along the rift.
func _mouth(i: int, cell: int, out: Array[Dictionary]) -> void:
	var each: Dictionary = geology.vents[i]
	if cells.cell_at(each.p) == cell:
		out.append(_site(&"vent_mouth", each.p, each.bearing, _stream(["v", i]), ["v", i], &"geology"))


func _off_network(cell: int, out: Array[Dictionary]) -> void:
	var box := cells.box(cell)
	var lat0 := box[0]
	var lat1 := box[1]
	var lon0 := box[2]
	var lon1 := box[3]
	var tu_lon := Sphere.longitude(sub_tu)
	var step := deg_to_rad(GRID)
	# Colonial survey beacons and relay towers on a grid over the near side.
	for i in range(ceili(lat0 / step), floori(lat1 / step) + 1):
		var lat := i * step
		if lat < lat0 or lat >= lat1 or absf(lat) > deg_to_rad(84.0):
			continue
		var around := maxi(1, floori(TAU / step * cos(lat)))
		var gap := TAU / around
		for j in range(ceili((lon0 - tu_lon) / gap), floori((lon1 - tu_lon) / gap) + 1):
			var lon := tu_lon + j * gap
			if fposmod(lon - lon0, TAU) >= lon1 - lon0:
				continue
			var p := Sphere.point(lat, lon)
			if from_tu(p) > deg_to_rad(100.0) or cells.cell_at(p) != cell:
				continue
			var rng := _stream(["g", i, posmod(j, around)])
			var relay := i % RELAY_EVERY == 0 and posmod(j, around) % RELAY_EVERY == 0
			out.append(_site(&"relay_mast" if relay else &"survey_beacon", p, 0.0, rng, ["g", i, posmod(j, around)], &"grid"))
	var middle := cells.center(cell)
	# A wreck field that came down here: likelier toward Han.
	var rng := _stream(["w", cell])
	var toward_tu := 1.0 - smoothstep(_bounds[0], _bounds[1], from_tu(middle))
	if rng.randf() < lerpf(WRECKS.y, WRECKS.x, toward_tu):
		var spec: Array = MEMBERS[&"wreck_field"]
		var at := Sphere.point(rng.randf_range(lerpf(lat0, lat1, 0.3), lerpf(lat0, lat1, 0.7)),
			rng.randf_range(lerpf(lon0, lon1, 0.3), lerpf(lon0, lon1, 0.7)))
		var k := 0
		for entry: Array in spec[2]:
			for n in rng.randi_range(entry[1], entry[2]):
				var p := Sphere.toward(at, rng.randf() * TAU, rng.randf_range(10.0, spec[1] * 0.6) / radius)
				var own := _stream(["wm", cell, k])
				if cells.cell_at(p) == cell:
					out.append(_site(entry[0], p, own.randf() * TAU, own, ["wm", cell, k], &"wreck_field"))
				k += 1
	# A First Kingdoms hermit, far from any path.
	var alone := _stream(["h", cell])
	if not _cell_paths.has(cell) and not _cell_settlements.has(cell) and alone.randf() < HERMITS:
		out.append(_site(&"pipe_wall_hut", middle, alone.randf() * TAU, alone, ["h", cell], &"hermit"))
	# The nomads', anywhere: a wrecked rig, now and then one of their camps.
	for nomads: Array in [[&"nomad_rig", NOMAD_RIGS, "n"], [&"nomad_camp", NOMAD_CAMPS, "nc"]]:
		var roam := _stream([nomads[2], cell])
		if roam.randf() >= nomads[1]:
			continue
		var at := Sphere.point(roam.randf_range(lerpf(lat0, lat1, 0.1), lerpf(lat0, lat1, 0.9)),
			roam.randf_range(lerpf(lon0, lon1, 0.1), lerpf(lon0, lon1, 0.9)))
		if cells.cell_at(at) == cell and not _in_landmark(at):
			out.append(_site(nomads[0], at, roam.randf() * TAU, roam, [nomads[2], cell], &"nomads"))


func _site(kind: StringName, p: Vector3, bearing: float, rng: RandomNumberGenerator, parts: Array,
		source: StringName) -> Dictionary:
	var era := SiteKinds.era(kind)
	var tilt: Vector2 = Eras.TILT.get(era, Vector2.ZERO)
	return {"id": _id(parts), "kind": kind, "era": era, "p": p, "bearing": fposmod(bearing, TAU),
		"reach": SiteKinds.reach(kind), "depth": _depth(kind, rng), "tilt": deg_to_rad(rng.randf_range(tilt.x, tilt.y)),
		"loot": hash([run_seed, parts, "loot"]), "source": source, "region": region_of(p)}


# --- Small rules. ---

## Sand over a site of a kind: its own burial where it has one, else its era's.
func _depth(kind: StringName, rng: RandomNumberGenerator) -> float:
	var span := SiteKinds.burial(kind)
	return rng.randf_range(span.x, span.y)


func _on_axis(degrees: float) -> Vector3:
	return Sphere.toward(sub_tu, axis, deg_to_rad(degrees))


## The point on the Rim nearest a place, nudged `degrees` past it.
func _rim_point(p: Vector3) -> Vector3:
	return (p - sub_tu * p.dot(sub_tu)).normalized()


func _on_rim(p: Vector3, degrees: float) -> Vector3:
	var rim := _rim_point(p)
	return Sphere.toward(rim, Sphere.bearing(rim, anti_tu), deg_to_rad(degrees))


## Where the great circle from a place along a bearing first reaches the Rim.
func _rim_crossing(from: Vector3, bearing: float) -> Vector3:
	var step := deg_to_rad(0.25)
	var by := 0.0
	while by < PI and from_tu(Sphere.toward(from, bearing, by + step)) < PI * 0.5:
		by += step
	var lo := by
	var hi := by + step
	for k in 30:
		var mid := (lo + hi) * 0.5
		if from_tu(Sphere.toward(from, bearing, mid)) < PI * 0.5:
			lo = mid
		else:
			hi = mid
	return Sphere.toward(from, bearing, hi)


## A place `metres` to one side of p, either way.
func _aside(p: Vector3, metres: float, rng: RandomNumberGenerator) -> Vector3:
	return Sphere.toward(p, rng.randf() * TAU, metres / radius)


func _in_landmark(p: Vector3) -> bool:
	return landmarks.any(func(l: Dictionary) -> bool: return Sphere.angle(p, l.p) * radius < minf(l.radius, 2000.0))


func _stream(parts: Array) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed] + parts)
	return rng


## A site's id: two hashes of its making, 62 bits, the same every run.
func _id(parts: Array) -> int:
	return ((hash([run_seed] + parts) & 0x7fffffff) << 31) | (hash(parts + [run_seed, 1]) & 0x7fffffff)
