class_name SiteLoot
extends RefCounted
## What history's sites hold (docs/world-system.md, Loot). A kit piece's
## sockets are filled from its era's table, its kind saying what fits and its
## region how generous, each socket from its own stream of the site's loot
## seed: a site holds the same things whoever comes, whenever, laid from
## wherever. The sand decides what's within reach. Buried, a site's loot lies
## under it; partly exposed, what's near its top shows, half in the sand;
## dug out, the rest; and a socket deeper than the rest of its site only once
## a storm has stripped past it. Each era's best lies there: the good things
## are deep.

const FLOOR := &"floor"
const SHELF := &"shelf"
const CACHE := &"cache"
const BED := &"bed"
const BEST := &"best"
## A wreck's modules (WreckPlan): a small device on a rack, a big one on a
## floor. Every one holds a device with at least MODULE_PARTS parts fitted,
## since wrecks were left in a hurry, and lies exactly where it was stowed,
## held fast in its wreck until what's in its way is gone.
const MODULE := &"module"
const BAY := &"bay"
const MODULES: Array[StringName] = [MODULE, BAY]
const MODULE_PARTS := 2
## The house ruin's first floor spot: a later visitor's device with parts to
## strip, on whatever sand is in the hall.
const HALL := &"hall"
## What a nomads' rig carries, always: a wrecked one's mast with its sail
## (RIGGED); and a camp's kept rig whole, a deck as Rig steps (RIG).
const RIGGED := &"rigged"
const RIG := &"rig"

## Per era: the share of its sockets still holding something, how its finds
## read (Finds' layer: the paint, the marks and the look-at line's word), a
## battery's charge and a device's soundness, which layer's fills a device's
## sockets hold and how many, and whether water was kept sealed. Then what
## each kind of socket holds, as [catalog id, weight], and its best, which
## every socket deeper than the rest of its site holds. Loot identity by era
## (part 4); shelves hold parts, caches small things, beds what grows.
const ERAS := {
	# Infrastructure: power, chassis, big systems.
	Eras.COLONIAL: {"kept": 0.55, "layer": Finds.DEEP, "charge": Vector2(0.3, 1.0), "sound": Vector2(0.7, 1.0),
		"fills": Finds.DEEP, "fill": 0.6, "sealed": false,
		FLOOR: [[&"chassis", 5], [&"frame", 2], [&"condenser", 1], [&"turbine", 1],
			[&"big_battery", 2], [&"hover_tray", 2], [&"solar_panel", 2], [&"strong_plug", 2], [&"board", 1], [&"burner", 1], [&"deep_planter", 1], [&"radio_colonial", 1]],
		SHELF: [[&"battery", 3], [&"big_battery", 1], [&"lamp", 2], [&"strong_plug", 2], [&"plug", 1],
			[&"barometer", 1], [&"hygrometer", 1], [&"compass", 1], [&"med_kit", 1], [&"fm_converter", 1],
			[&"frequency_counter", 1], [&"direction_loop", 1], [&"solar_lid", 1], [&"coalcane", 1]],
		CACHE: [[&"big_battery", 2], [&"strong_plug", 2], [&"hover_tray", 1], [&"screen", 1]],
		BED: [[&"root_tuber", 3], [&"vat_fungus", 2]],
		BEST: [[&"console", 2], [&"shield", 2], [&"turbine", 2], [&"condenser", 1], [&"big_battery", 3],
			[&"hover_tray", 2], [&"solar_panel", 2], [&"radar", 1], [&"screen", 1], [&"harvester", 1],
			[&"power_cabinet", 1]]},
	# The best single-item gear, from deserters and the black site: light,
	# cheap and fragile, made before Zan was a desert. Its boards are its
	# crews' racers.
	Eras.SKIMMER: {"kept": 0.6, "layer": Finds.DEEP, "charge": Vector2(0.2, 0.9), "sound": Vector2(0.5, 0.9),
		"fills": Finds.DEEP, "fill": 0.5, "sealed": false,
		FLOOR: [[&"survival_kit", 3], [&"radio", 2], [&"radio_skimmer", 1], [&"racer_board", 1], [&"light_panel", 1], [&"battery", 2],
			[&"big_battery", 1], [&"coil", 1], [&"strong_plug", 1], [&"ration", 2], [&"power_rack", 1],
			[&"antenna_kite", 1]],
		SHELF: [[&"battery", 2], [&"ration", 2], [&"hook", 1], [&"plug", 1], [&"anemometer", 1],
			[&"particle_sensor", 1], [&"compass", 1], [&"lamp", 1], [&"sand_scoop", 1], [&"sealant", 1],
			[&"sw_converter", 1], [&"antenna_reel", 1]],
		CACHE: [[&"big_battery", 2], [&"battery", 2], [&"strong_plug", 1], [&"hose_end", 1], [&"med_kit", 1],
			[&"sealant", 1]],
		BED: [[&"vat_fungus", 1]],
		BEST: [[&"shield", 3], [&"racer_board", 2], [&"radar", 2], [&"harvester", 2], [&"particle_sensor", 1],
			[&"anemometer", 1], [&"big_battery", 2], [&"console", 1], [&"cutter", 2], [&"power_rack", 1]]},
	# Intact working colonial tech, kept running and used in new ways.
	Eras.FIRST: {"kept": 0.6, "layer": Finds.SURFACE, "charge": Vector2(0.4, 1.0), "sound": Vector2(0.75, 1.0),
		"fills": Finds.DEEP, "fill": 0.75, "sealed": true,
		FLOOR: [[&"condenser", 3], [&"turbine", 2], [&"frame", 2], [&"planter", 2], [&"chassis", 2],
			[&"radio", 1], [&"radio_kingdoms", 1], [&"canister", 2], [&"hose_end", 2], [&"battery", 2], [&"power_cabinet", 1]],
		SHELF: [[&"battery", 2], [&"barometer", 2], [&"hygrometer", 2], [&"compass", 2], [&"lamp", 2],
			[&"hose_end", 2], [&"canister", 1], [&"fm_converter", 1], [&"bleed_resistor", 1], [&"wire_logger", 1],
			[&"valve_preamp", 1]],
		CACHE: [[&"battery", 2], [&"big_battery", 1], [&"canister", 2], [&"compass", 1]],
		BED: [[&"root_tuber", 3], [&"saltbush", 1], [&"vat_fungus", 1]],
		BEST: [[&"condenser", 2], [&"turbine", 2], [&"shield", 2], [&"console", 1], [&"big_battery", 2],
			[&"harvester", 2], [&"hover_tray", 1], [&"radar", 1], [&"screen", 1], [&"power_cabinet", 1]]},
	# Worn reused gear; water, seeds and salt. Its floors hold what a house
	# ruin's always did; its best, what the deep layer did, its board the
	# temple's make.
	Eras.SECOND: {"kept": 0.7, "layer": Finds.SURFACE, "charge": Vector2(0.0, 0.4), "sound": Vector2(0.35, 0.75),
		"fills": Finds.SURFACE, "fill": 0.35, "sealed": true,
		FLOOR: [[&"battery", 4], [&"hook", 4], [&"lamp", 2], [&"canister", 2], [&"coil", 3], [&"plug", 3],
			[&"hose_end", 2], [&"compass", 1], [&"chassis", 4], [&"frame", 1], [&"fabric", 1], [&"planter", 2],
			[&"survival_kit", 5], [&"radio", 2], [&"radio_second_age", 1], [&"crystal_set", 2], [&"root_tuber", 6], [&"vat_fungus", 4],
			[&"ration", 2], [&"salt", 2], [&"saltbush", 2], [&"power_shrine", 1], [&"sail", 1]],
		SHELF: [[&"canister", 3], [&"salt", 3], [&"saltbush", 2], [&"root_tuber", 2], [&"ration", 2],
			[&"coil", 2], [&"lamp", 1], [&"compass", 1], [&"hook", 1]],
		CACHE: [[&"survival_kit", 2], [&"canister", 2], [&"coil", 2], [&"radio", 1], [&"compass", 1]],
		BED: [[&"root_tuber", 3], [&"saltbush", 2], [&"vat_fungus", 1]],
		BEST: [[&"big_battery", 3], [&"battery", 2], [&"hover_tray", 3], [&"solar_panel", 3],
			[&"strong_plug", 2], [&"harvester", 1], [&"chassis", 3], [&"turbine", 2], [&"condenser", 2],
			[&"shield", 2], [&"temple_board", 1], [&"console", 1], [&"survival_kit", 2],
			[&"root_tuber", 4], [&"vat_fungus", 4], [&"ration", 1], [&"power_shrine", 1]]},
	# The nomads' own, now: mobility, sailing gear and what keeps them going,
	# out in the weather but kept up; whatever any era left them, each thing's
	# lineage drawn from `from`, by weight.
	Eras.NOMAD: {"kept": 0.75, "layer": Finds.SURFACE, "charge": Vector2(0.2, 0.8), "sound": Vector2(0.55, 0.9),
		"fills": Finds.DEEP, "fill": 0.5, "sealed": true,
		"from": {Eras.COLONIAL: 2, Eras.SKIMMER: 2, Eras.FIRST: 1, Eras.SECOND: 3},
		FLOOR: [[&"coil", 3], [&"streamer", 2], [&"skates", 1], [&"board_plate", 1], [&"bedroll", 2], [&"chassis", 3],
			[&"frame", 2], [&"fabric", 2], [&"canister", 2], [&"survival_kit", 1], [&"battery", 2], [&"board", 1],
			[&"survey_receiver", 2], [&"crystal_set", 1], [&"antenna_kite", 1], [&"salvage_kite", 1]],
		SHELF: [[&"streamer", 3], [&"coil", 2], [&"hook", 3], [&"canister", 2], [&"ration", 2], [&"compass", 1],
			[&"battery", 1], [&"salt", 1], [&"fm_converter", 1], [&"sw_converter", 1], [&"antenna_reel", 1]],
		CACHE: [[&"canister", 3], [&"ration", 2], [&"streamer", 1], [&"med_kit", 1], [&"coil", 1], [&"saltbush", 1]],
		BED: [[&"saltbush", 2], [&"root_tuber", 1]],
		BEST: [[&"sail", 3], [&"mast", 2], [&"hand_winch", 2], [&"skates", 2], [&"keel", 1], [&"helm_seat", 1], [&"crows_nest", 1],
			[&"racer_board", 1], [&"anemometer", 1]]},
}
## What a kind holds in place of its era's, by socket kind (and "kept": its
## own share left holding something): the kind says what fits.
const KINDS := {
	# Buried colonial corridors and habs: the vat fungus's own stock.
	&"hab_pod": {SHELF: [[&"vat_fungus", 3], [&"ration", 2], [&"lamp", 1], [&"battery", 1]]},
	# The mast's cabinet: its instruments and its power.
	&"relay_mast": {SHELF: [[&"battery", 2], [&"big_battery", 1], [&"barometer", 1], [&"anemometer", 1],
		[&"compass", 1], [&"strong_plug", 1], [&"ground_radar", 1], [&"fm_converter", 1], [&"sw_converter", 1],
		[&"bleed_resistor", 1], [&"static_choke", 1], [&"direction_loop", 1], [&"headset_jack", 1]]},
	# The inspection hatch: the line's own hose, valves and water.
	&"pipeline_segment": {BEST: [[&"hose_end", 3], [&"canister", 2], [&"condenser", 1], [&"strong_plug", 1],
		[&"big_battery", 1]]},
	# A wreck nobody reached before the sand did, and a deserters' dugout.
	# A wreck's modules are what its crew stowed: the skimmer era's single
	# items, the Provisional's military kit and the black site's, colonial
	# freight and a lifeboat's survival stores, the Knights' convoy gear. A
	# skimmer's pilot sat in its helm seat and it rode its ventral keel, so the
	# land yacht's two parts lie deep in its wreck, with what else it carried.
	&"wreck_hull": {"kept": 0.9, BEST: [[&"helm_seat", 3], [&"keel", 3], [&"shield", 2], [&"racer_board", 2], [&"radar", 1],
		[&"harvester", 1], [&"big_battery", 1]],
		MODULE: [[&"survey_receiver", 1], [&"survival_kit", 3], [&"radio", 2], [&"light_panel", 2], [&"shield", 1], [&"light_shield", 2]]},
	&"tithe_hauler": {"kept": 0.9,
		MODULE: [[&"survey_receiver", 1], [&"shield", 3], [&"light_shield", 2], [&"radio", 2], [&"survival_kit", 2]],
		BAY: [[&"shield", 3], [&"condenser", 2], [&"chassis", 2], [&"console", 1], [&"power_rack", 1]]},
	&"freight_pod": {"kept": 0.8,
		MODULE: [[&"survey_receiver", 1], [&"shield", 2], [&"light_panel", 3], [&"turbine", 2], [&"radio", 1]],
		BAY: [[&"condenser", 3], [&"console", 2], [&"turbine", 2], [&"planter", 2], [&"power_cabinet", 1]]},
	&"lifeboat": {"kept": 0.9,
		MODULE: [[&"survey_receiver", 1], [&"radio", 3], [&"survival_kit", 4], [&"light_panel", 2], [&"light_shield", 2]]},
	&"hopper": {"kept": 0.85, BEST: [[&"patrol_board", 3], [&"shield", 2], [&"radio", 1], [&"survival_kit", 2]],
		MODULE: [[&"survey_receiver", 1], [&"turbine", 3], [&"light_panel", 2], [&"radio", 1]],
		BAY: [[&"console", 2], [&"condenser", 3], [&"chassis", 2], [&"shield", 1]]},
	# Where deserters slept: their bedrolls and kits, and what kept them.
	&"dugout": {"kept": 0.8, FLOOR: [[&"bedroll", 3], [&"survival_kit", 3], [&"radio", 1], [&"battery", 2],
		[&"ration", 2], [&"coil", 1]]},
	# Fuel and its tap.
	&"fuel_bladder": {FLOOR: [[&"battery", 2], [&"canister", 2], [&"hose_end", 2], [&"plug", 1]],
		CACHE: [[&"big_battery", 2], [&"battery", 2], [&"hose_end", 2], [&"strong_plug", 1]]},
	# Where a colonial water line ended: water, and the plot it fed.
	&"cistern": {FLOOR: [[&"canister", 4], [&"hose_end", 2], [&"condenser", 1], [&"planter", 1]],
		BED: [[&"root_tuber", 2], [&"saltbush", 2], [&"vat_fungus", 1]]},
	# An old field plot's corner.
	&"low_wall": {BED: [[&"root_tuber", 3], [&"saltbush", 2]]},
	# Offerings in the basin and the niche: water vials, salt and a few
	# seeds; a pilgrim's cache in the plinth.
	&"wayshrine": {"kept": 0.9, SHELF: [[&"canister", 4], [&"salt", 3], [&"saltbush", 3], [&"root_tuber", 2],
		[&"vat_fungus", 1], [&"ration", 1]],
		BEST: [[&"survival_kit", 4], [&"canister", 2], [&"radio", 1], [&"compass", 1], [&"coil", 1],
			[&"power_shrine", 1]]},
	# The late wars' weapons cache, on the platform, a Knights' patrol board among it.
	&"watchtower": {CACHE: [[&"shield", 2], [&"light_shield", 1], [&"radio", 2], [&"survival_kit", 2],
		[&"compass", 1], [&"coil", 2], [&"big_battery", 1], [&"patrol_board", 1]]},
	&"house_ruin": {HALL: [[&"chassis", 8], [&"planter", 2], [&"survival_kit", 3],
		[&"radio", 2], [&"turbine", 2], [&"condenser", 2], [&"shield", 2], [&"console", 1]]},
	# A nomads' rig, wrecked: its mast down beside it with its sail always,
	# what they stowed in its locker, the rack they scavenged for its power.
	&"nomad_rig": {"kept": 0.85, "tier": 1, RIGGED: [[&"mast", 1]],
		MODULE: [[&"survey_receiver", 1], [&"survival_kit", 3], [&"radio", 2], [&"light_shield", 1], [&"streamer", 1]],
		BAY: [[&"power_rack", 1]]},
	# A nomads' camp, kept up and just left: their rig, and anything of any era.
	&"nomad_camp": {"kept": 1.0, RIG: [[&"runner", 2], [&"yacht", 1]],
		FLOOR: [[&"chassis", 3], [&"frame", 2], [&"turbine", 1], [&"condenser", 1], [&"shield", 1],
			[&"light_shield", 1], [&"big_battery", 1], [&"radio", 1], [&"survival_kit", 2], [&"bedroll", 2],
			[&"planter", 1], [&"skates", 1], [&"coil", 2], [&"canister", 2], [&"power_rack", 1], [&"sail", 1],
			[&"mast", 1]],
		SHELF: [[&"streamer", 3], [&"compass", 2], [&"canister", 2], [&"ration", 2], [&"coil", 2], [&"med_kit", 1],
			[&"anemometer", 1], [&"barometer", 1], [&"battery", 2], [&"lamp", 1]],
		CACHE: [[&"canister", 4], [&"ration", 3], [&"med_kit", 1], [&"saltbush", 1]],
		BED: [[&"saltbush", 3], [&"root_tuber", 1]]},
}
## What a big dune's ruin holds in place of its kind's (DuneRuins): kept
## whole under the dunes, a colony's survey gear among it, its deepest a
## ground radar's; its sieves for the silt.
const DUNE := {"kept": 0.85,
	SHELF: [[&"sieve", 3], [&"battery", 2], [&"lamp", 1], [&"compass", 1], [&"sand_scoop", 1], [&"ration", 1]],
	CACHE: [[&"sieve", 1], [&"big_battery", 2], [&"strong_plug", 1], [&"screen", 1], [&"ground_radar", 1]],
	BEST: [[&"ground_radar", 4], [&"console", 2], [&"big_battery", 2], [&"shield", 1], [&"screen", 1]]}
## Per region: how much of each site's loot is left, and the chance any
## floor or cache holds its era's best: Han is "the jackpot for single
## items: sparse, dangerous, rewarding"; the calm far side has less.
const REGIONS := {&"rim": {"kept": 1.0, "best": 0.0}, &"mon": {"kept": 0.9, "best": 0.08},
	&"han": {"kept": 0.75, "best": 0.35}, &"far": {"kept": 0.6, "best": 0.05}}
## Nomads loot as you do and leave what they don't need: this share of what
## lies loose in other eras' wrecks is theirs, from this table.
const LEFT_SHARE := 0.2
const LEFT := [[&"coil", 3], [&"streamer", 3], [&"canister", 2], [&"skates", 1], [&"bedroll", 1], [&"fabric", 1],
	[&"sail", 1]]
## A find laid at a site rests this far above what it's on, frozen there: placed, never dropped.
const DROP := 0.005
## Sand within this of a socket's surface leaves what's there lying on it.
const ON_TOP := 0.05
## What a site holds lies this far clear of the way through it (its tour),
## m: room for you to pass.
const WAY := 0.45
## Where pushing it clear won't do, a find looks round its socket for a clear
## spot in rings this far apart, m, this many of them.
const SEARCH_STEP := 0.25
const SEARCH_RINGS := 8

## Each socket's resting spot by kind, state and a find's size, once worked out.
static var _spots := {}


## What each socket of a site holds, drawn whatever the sand: {} for one left empty.
static func draw(site: Site, i: int) -> Dictionary:
	var piece := StructureKit.piece(site.kind)
	var socket: StructureKit.SiteSocket = piece.sockets[i]
	var era: Dictionary = ERAS[site.era]
	var kind: Dictionary = DUNE if site.source == &"dune" else KINDS.get(site.kind, {})
	var region: Dictionary = REGIONS.get(site.region, REGIONS[&"rim"])
	var rng := _stream(site.loot, i)
	var hall := kind.has(HALL) and i == 0
	if socket.kind in MODULES:
		return _module(site, i, socket, kind, era, rng)
	if socket.kind in [RIGGED, RIG]:
		return _rigged(site, i, socket, kind, era, rng)
	if not hall and rng.randf() >= float(kind.get("kept", era.kept)) * region.kept:
		return {}
	var best: bool = socket.deep > 0.0 or (socket.kind in [FLOOR, CACHE] and rng.randf() < region.best)
	var table: Array = kind[HALL] if hall else (kind.get(BEST, era[BEST]) if best else kind.get(socket.kind, era[socket.kind]))
	var made := site.era
	if not best and not hall and piece.wreck != null and site.era != Eras.NOMAD and socket.kind in [FLOOR, SHELF, CACHE] \
			and _stream(site.loot, i, "nomads").randf() < LEFT_SHARE:
		table = LEFT
		made = Eras.NOMAD
	var id := Finds._pick(rng, table)
	var spec := {"id": id, "device": Catalog.DEVICES.has(id), "layer": era.layer, "era": _made_in(site.loot, i, made),
		"kind": site.kind, "nomads": made == Eras.NOMAD,
		"seed": hash([site.loot, i]), "tier": 2 if best else 1, "index": i, "site": site.id, "yaw": rng.randf() * TAU,
		"lean": rng.randf() * TAU,
		"lean_by": deg_to_rad(rng.randf() * Finds.LEAN), "sealed": era.sealed, "frozen": true, "drop": DROP}
	spec.charge = rng.randf_range(era.charge.x, era.charge.y)
	spec.sound = rng.randf_range(era.sound.x, era.sound.y)
	spec.fill = []
	if spec.device:
		_fill(spec, rng, era, Finds.HALL_PARTS if hall else 0)
	return spec


## A wreck's module: always there, a device from its kind's row with at
## least two parts fitted, sounder than what lies loose, frozen where it was
## stowed.
static func _module(site: Site, i: int, socket: StructureKit.SiteSocket, kind: Dictionary, era: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var id := Finds._pick(rng, kind[socket.kind])
	var spec := {"id": id, "device": true, "layer": era.layer, "era": _made_in(site.loot, i, site.era), "kind": site.kind,
		"seed": hash([site.loot, i]), "tier": kind.get("tier", 2), "index": i, "site": site.id, "yaw": rng.randf_range(-0.12, 0.12),
		"lean": 0.0, "lean_by": 0.0, "sealed": era.sealed, "frozen": true, "drop": DROP, "module": true}
	spec.charge = rng.randf_range(era.charge.x, era.charge.y)
	spec.sound = rng.randf_range(maxf(era.sound.x, 0.6), maxf(era.sound.y, 0.85))
	spec.fill = []
	_fill(spec, rng, era, MODULE_PARTS)
	return spec


## What a nomads' rig carries, always there: a wrecked one's mast with its
## sail fitted, lying as its socket turns it; a camp's kept rig whole, its
## deck built from its Rig steps. Kept up, they're sound.
static func _rigged(site: Site, i: int, socket: StructureKit.SiteSocket, kind: Dictionary, era: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var id := Finds._pick(rng, kind[socket.kind])
	var whole := socket.kind == RIG
	var spec := {"id": &"chassis" if whole else id, "device": true, "layer": era.layer,
		"era": _made_in(site.loot, i, site.era), "kind": site.kind, "seed": hash([site.loot, i]), "tier": kind.get("tier", 2), "index": i,
		"site": site.id, "yaw": socket.turn if is_finite(socket.turn) else rng.randf() * TAU, "lean": 0.0, "lean_by": 0.0,
		"sealed": era.sealed, "frozen": true, "drop": DROP}
	spec.charge = rng.randf_range(era.charge.x, era.charge.y)
	spec.sound = rng.randf_range(maxf(era.sound.x, 0.7), maxf(era.sound.y, 0.9))
	spec.fill = []
	if whole:
		spec.rig = NomadKit.RIGS[id]
	else:
		_fill(spec, rng, era, 1)
	return spec


## The era a find's lineage is drawn as: a nomads' thing is whatever any era
## made, by their row's `from`, from the loot seed alone.
static func _made_in(loot: int, i: int, era: StringName) -> StringName:
	if era != Eras.NOMAD:
		return era
	var weights: Dictionary = ERAS[Eras.NOMAD].from
	var rng := _stream(loot, i, "made")
	var total := 0.0
	for each: StringName in weights:
		total += weights[each]
	var at := rng.randf() * total
	for each: StringName in weights:
		at -= weights[each]
		if at < 0.0:
			return each
	return weights.keys()[-1]


## What lies within reach at a structure now, as find specs: what its sockets
## hold, less what's `taken` (socket -> true), where the sand leaves it
## showing in the state the structure is held in. `height` is the ground's
## one function, world metres.
static func plan(site: Structure, height: Callable, taken := {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in site.piece.sockets.size():
		var spec := within_reach(site, i, height, taken)
		if not spec.is_empty():
			out.append(spec)
	return out


## What one socket holds within reach now, or {}.
static func within_reach(site: Structure, i: int, height: Callable, taken := {}) -> Dictionary:
	return {} if taken.has(i) else lying(site, i, draw(site, i), height)


## The same from what it holds, drawn already.
static func lying(site: Structure, i: int, drawn: Dictionary, height: Callable, taken := {}) -> Dictionary:
	if taken.has(i) or drawn.is_empty():
		return {}
	var spec := drawn.duplicate()
	return spec if _lies(site, i, spec, height) else {}


## Works out every socket's resting spots for what it may hold while the
## world loads, so no chunk pays for them inside the streaming budget.
static func prepare() -> void:
	for kind: StringName in StructureKit.kinds():
		var piece := StructureKit.piece(kind)
		if piece.lean > 0.0 or piece.sockets.is_empty():
			continue
		var era: Dictionary = ERAS[piece.era]
		var own: Dictionary = KINDS.get(kind, {})
		for i in piece.sockets.size():
			var socket: StructureKit.SiteSocket = piece.sockets[i]
			if socket.kind in MODULES or socket.kind in [RIG, RIGGED]:
				continue
			var tables: Array = [own.get(socket.kind, era[socket.kind]), own.get(BEST, era[BEST]), own.get(HALL, []),
				DUNE.get(socket.kind, []), DUNE[BEST]]
			for table: Array in tables:
				for entry: Array in table:
					var size := _size({"id": entry[0], "device": Catalog.DEVICES.has(entry[0])})
					for state in 3:
						_spot(piece, state, i, size)


## Where a wreck's module lies, set on its spec as the frame its foot stands
## in, world metres: on its rack or floor, leaning with the wreck. False
## while the dunes still cover where it stands; the sand packed in the
## wreck's holds is its own, and doesn't keep it.
static func _stowed(site: Structure, socket: StructureKit.SiteSocket, spec: Dictionary, height: Callable) -> bool:
	var base := site.frame() * Transform3D(Basis(Vector3.UP, spec.yaw), socket.at)
	var sand: float = height.call(base.origin.x, base.origin.z)
	if sand > base.origin.y + ON_TOP:
		return false
	spec.base = base
	spec.x = base.origin.x
	spec.z = base.origin.z
	spec.loose = false
	spec.bury = 0.0
	return true


## Where a socket's find lies, set on its spec; false while the sand keeps it.
## It rests on the highest of the site's boxes under it no higher than its
## socket, moved clear of any it would stand in, or on the sand over that,
## and can't be reached higher over the sand than a hand reaches. Buried,
## only what lies on top of the sand shows. Past that, with sand over it, it
## shows half buried where enough of it stands out; deeper, it lies in that
## sand, surfacing as the storms strip the site: more the more is taken off
## partly exposed, all of it dug out.
static func _lies(site: Structure, i: int, spec: Dictionary, height: Callable) -> bool:
	var piece := site.piece
	var socket: StructureKit.SiteSocket = piece.sockets[i]
	if socket.deep > 0.0 and site.taken() < site.depth * (1.0 + socket.deep):
		return false
	if spec.get("module", false):
		return _stowed(site, socket, spec, height)
	var size := _size(spec)
	var state := site.state()
	var p := Vector2(socket.at.x, socket.at.z)
	var surface := socket.at.y
	if piece.lean == 0.0 or site.tilt == 0.0:
		# On what stands of it now, between states too.
		var spot := _spot(piece, StructureKit.Piece.shown_state(site.level()), i, size)
		if not spot.is_finite():
			return false
		p = Vector2(spot.x, spot.y)
		surface = spot.z
	var at := site.frame() * Vector3(p.x, surface, p.y)
	var sand: float = height.call(at.x, at.z)
	spec.x = at.x
	spec.z = at.z
	spec.yaw = site.basis().get_euler().y + spec.yaw
	spec.loose = false
	var over := sand - at.y
	if over <= ON_TOP or (i == 0 and KINDS.get(site.kind, {}).has(HALL)):
		var rest := maxf(at.y, _highest(height, at, size.x))
		if rest - sand > StructureKit.HANDS:
			return false
		spec.loose = true
		spec.bury = 0.0
		spec.floor = rest
		return true
	if state == Exposure.BURIED:
		return false
	spec.bury = over / size.z
	if spec.bury <= 1.0 - maxf(Finds.SHOWING_SHARE, Finds.SHOWING / size.z):
		return true
	var rng := _stream(site.loot, i, "surfaces")
	var surfaced := 1.0
	if state == Exposure.PARTLY and site.depth > 0.0:
		surfaced = clampf((site.taken() - site.depth / 3.0) / (site.depth * 2.0 / 3.0), 0.0, 1.0)
	if rng.randf() >= surfaced:
		return false
	var depths: Vector2 = Finds.LAYER[Finds.SURFACE].bury
	spec.bury = rng.randf_range(depths.x, depths.y)
	return true


## Where a find of a size rests at a socket of a piece in a state, plan
## metres [u, v, height]: the same for every site of the kind, so worked out
## once.
static func _spot(piece: StructureKit.Piece, state: int, i: int, size: Vector3) -> Vector3:
	var key := hash([piece.kind, state, i, snappedf(size.x, 0.001), snappedf(size.y, 0.001)])
	if not _spots.has(key):
		var socket: StructureKit.SiteSocket = piece.sockets[i]
		var p := _clear(piece, state, Vector2(socket.at.x, socket.at.z), socket.at.y, size.x, size.y)
		_spots[key] = Vector3(p.x, p.y, _surface(piece, state, p, socket.at.y)) if p.is_finite() else Vector3(NAN, NAN, NAN)
	return _spots[key]


## The highest top of the boxes standing in a state that a plan point is
## over, no higher than `y` and a little; a room's floor, or `y`, where none.
static func _surface(piece: StructureKit.Piece, state: int, p: Vector2, y: float) -> float:
	var top := -INF
	for b in piece.shown(state):
		var box := piece.boxes[b]
		if box.end.y <= y + ON_TOP and box.end.y > top and p.x >= box.position.x and p.x <= box.end.x \
				and p.y >= box.position.z and p.y <= box.end.z:
			top = box.end.y
	if top > -INF:
		return top
	for room in piece.rooms:
		if room.holds(p):
			return room.floor
	return y


## A plan point moved clear of the boxes a find `r` m across its half and
## `tall` m high would stand in, resting where it then rests, and off the way
## through: pushed out the nearest side of each in turn, or else the nearest
## clear spot round it in the same room; NAN if there's none.
static func _clear(piece: StructureKit.Piece, state: int, p: Vector2, y: float, r: float, tall: float) -> Vector2:
	var at := p
	for step in 8:
		var out := _blocked(piece, state, at, y, r, tall)
		if out == Vector2.ZERO:
			return at
		at += out
	var room := -1
	for k in piece.rooms.size():
		if piece.rooms[k].holds(p):
			room = k
	for ring in range(1, SEARCH_RINGS + 1):
		for k in 8 * ring:
			var tried := p + Vector2.from_angle(TAU * k / (8 * ring)) * ring * SEARCH_STEP
			if (room < 0 or piece.rooms[room].holds(tried)) and _blocked(piece, state, tried, y, r, tall) == Vector2.ZERO:
				return tried
	return Vector2(NAN, NAN)


## How far a find at a plan point must move to clear the first box or way it
## stands in, or zero where it's clear.
static func _blocked(piece: StructureKit.Piece, state: int, p: Vector2, y: float, r: float, tall: float) -> Vector2:
	for k in piece.tour.size() - 1:
		var near := Geometry2D.get_closest_point_to_segment(p, piece.tour[k], piece.tour[k + 1])
		var off := p - near
		if off.length() < r + WAY:
			var away := off.normalized() if off.length() > 0.001 else (piece.tour[k + 1] - piece.tour[k]).orthogonal().normalized()
			return near + away * (r + WAY + 0.02) - p
	var on := _surface(piece, state, p, y)
	for b in piece.shown(state):
		var box := piece.boxes[b]
		if box.end.y <= on + 0.02 or box.position.y >= on + tall:
			continue
		var lo := Vector2(box.position.x, box.position.z) - Vector2.ONE * r
		var hi := Vector2(box.end.x, box.end.z) + Vector2.ONE * r
		if p.x <= lo.x or p.x >= hi.x or p.y <= lo.y or p.y >= hi.y:
			continue
		var outs := [Vector2(lo.x - p.x - 0.02, 0.0), Vector2(hi.x - p.x + 0.02, 0.0),
			Vector2(0.0, lo.y - p.y - 0.02), Vector2(0.0, hi.y - p.y + 0.02)]
		outs.sort_custom(func(a: Vector2, c: Vector2) -> bool: return a.length() < c.length())
		return outs[0]
	return Vector2.ZERO


## The sand's highest under a find's footprint, world height.
static func _highest(height: Callable, at: Vector3, r: float) -> float:
	var most: float = height.call(at.x, at.z)
	for corner in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
		most = maxf(most, height.call(at.x + corner.x, at.z + corner.y))
	return most


## A find's half width across any way it lies, its height lying, and its
## height stood on end in the sand, m.
static func _size(spec: Dictionary) -> Vector3:
	var id: StringName = spec.id
	if spec.has("rig"):
		return Vector3(1.6, 0.6, 0.6)
	if not spec.device:
		var s: Vector3 = Catalog.PARTS[id].size
		return Vector3(Vector2(s.x, s.y).length() * 0.5, s.z, maxf(s.x, maxf(s.y, s.z)))
	var d: Dictionary = Catalog.DEVICES[id]
	var size: Vector3 = d.size
	var on_end: bool = d.get("on_end", false)
	return Vector3(Vector2(size.x, size.z).length() * 0.5, size.y,
		maxf(size.x, maxf(size.y, size.z)) if on_end else size.y)


## What a found device's sockets hold, by its era: a survival kit packed as
## kits are, its seeds kept out of the weather; and at least `least` parts.
static func _fill(spec: Dictionary, rng: RandomNumberGenerator, era: Dictionary, least: int) -> void:
	var packed: bool = spec.id == &"survival_kit"
	var fills: Dictionary = Finds.SURVIVAL_KIT if packed else Finds.FILLS[era.fills]
	var holds := Finds.holds(spec.id)
	var open: Array[int] = []
	for i in holds.size():
		if not fills.has(holds[i]):
			continue
		if rng.randf() < (Finds.KIT_FILL if packed else float(era.fill)):
			spec.fill.append([i, Finds._any(rng, fills[holds[i]]), rng.randf_range(era.charge.x, era.charge.y)])
		else:
			open.append(i)
	while spec.fill.size() < least and not open.is_empty():
		var i: int = open.pop_front()
		spec.fill.append([i, Finds._any(rng, fills[holds[i]]), rng.randf_range(era.charge.x, era.charge.y)])


## Every catalog id a site's tables hold, for probes.
static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for rows: Dictionary in ERAS.values() + KINDS.values() + [{FLOOR: LEFT}]:
		for key: Variant in rows:
			if rows[key] is Array and key != RIG:
				for entry: Array in rows[key]:
					if not out.has(entry[0]):
						out.append(entry[0])
	return out


static func _stream(loot: int, i: int, salt := "") -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([loot, i, salt])
	return rng
