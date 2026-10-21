class_name Distress
extends RefCounted
## Wrecks calling SOS on the AM dial (gonkhub, 2026-10-21: "AM: Distress
## Signals, half the gods, and long distance beacons"). Some of the wrecks in
## the sand still run their emergency transmitter on what battery they have
## left: SOS in morse, then the wreck's own fix spoken, latitude and
## longitude, over and over, each on its own carrier either side of 500 kHz,
## the old maritime distress frequency. A ground wave that low carries far,
## so a call is a way to salvage. Pure in the seed and the sites laid.

## The wrecks that might call: down from the colony's end on.
const KINDS: Array[StringName] = [&"freight_pod", &"lifeboat", &"wreck_hull", &"tithe_hauler", &"hopper",
	&"nomad_rig"]
## The distress frequency the calls spread about, kHz.
const KHZ := 500.0
## A radio hears this many of the nearest calls at most, looked for again
## once it has moved this far, m.
const MOST := 3
const LOOK_AGAIN_M := 100.0
## SOS in morse: when each tone starts in its call, s, and whether it's a dah.
const SOS := [[0.0, false], [0.25, false], [0.5, false], [0.9, true], [1.35, true], [1.8, true],
	[2.3, false], [2.55, false], [2.8, false]]


## The calls a radio could hear from a world place x, z: the nearest wrecks
## still calling within distress_reach_m, as {site, khz, x, z, p}, low to high.
static func calls(world: World, x: float, z: float, tuning: Tuning) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var reach := tuning.distress_reach_m
	var near: Array[Site] = []
	for unit in world.shape.sites.units():
		for site: Site in unit.sites:
			if site.kind in KINDS and site.distance_to(x, z) <= reach and calling(world.run_seed, site, tuning):
				near.append(site)
	near.sort_custom(func(a: Site, b: Site) -> bool: return a.distance_to(x, z) < b.distance_to(x, z))
	for site in near.slice(0, MOST):
		out.append({"site": site.id, "khz": carrier(world.run_seed, site, tuning), "x": site.x, "z": site.z,
			"p": site.point})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.khz < b.khz)
	return out


## Whether a wreck's transmitter still calls, from the seed.
static func calling(run_seed: int, site: Site, tuning: Tuning) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, site.id, "distress"])
	return rng.randf() < tuning.distress_share


## A calling wreck's carrier, kHz, a whole one near 500.
static func carrier(run_seed: int, site: Site, tuning: Tuning) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, site.id, "distress_khz"])
	return roundf(KHZ + rng.randf_range(-tuning.distress_spread_khz, tuning.distress_spread_khz))


## How strong a call comes in over `metres` of ground: a low ground wave,
## carrying far.
static func strength(khz: float, metres: float, tuning: Tuning) -> float:
	var reach := tuning.ground_wave_m * minf(1.0, pow(Dial.GROUND_KHZ / maxf(khz, 1.0), 2.0))
	return exp(-metres / reach) * tuning.distress_power


## What it says: SOS, then its fix.
static func words(p: Vector3) -> String:
	var lat := rad_to_deg(Sphere.latitude(p))
	var lon := rad_to_deg(Sphere.longitude(p))
	return "S O S · S O S · Latitude %.1f %s · Longitude %.1f %s" % [absf(lat), "north" if lat >= 0.0 else "south",
		absf(lon), "east" if lon >= 0.0 else "west"]
