class_name Fm
extends RefCounted
## The FM band: VHF, 87.5 to 108 MHz, above the ceiling the air puts over the
## AM dial, so it doesn't bounce: a station is heard by line of sight, as far
## as the curve of the moon and the ground between allow, and no farther. So
## height is range: climb a dune, or go up, and a station comes in. What gets
## round an edge does so as real VHF does, by knife-edge diffraction, so a
## station fades in as you crest a rise rather than switching on. FM is
## heard clean or not at all: its limiter clips off the static a storm puts on
## AM, and over the threshold it's quiet; under it, hiss breaks in all at once.
## Two on one frequency don't mix: the stronger takes it (the capture effect).
## Pure in the world's shape and the seed.

## Port Morgan Control Tower's station: the deliveryship's schedule (Radio), and
## later the port's other worldbuilding broadcasts.
const TOWER := &"tower"
const LOWEST := 87.5
const HIGHEST := 108.0
## Light's speed, for a wavelength, m/s over MHz.
const C_MHZ := 299.792458


## Every station on the band, low to high: Port Morgan's own, the port's music
## on its mast ({id, mhz, at (a point on the sphere), mast_m}); Port Morgan
## Control Tower on the same mast (TOWER); and the relay at
## L1 sending the same music down from the sky ({id, mhz, sky (its id in the
## constellation)}). Each on an odd tenth of a MHz the seed picks (as North
## America spaces them), apart from each other, and locked there: a station
## never wanders.
static func stations(gods: Gods, run_seed: int, tuning: Tuning) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, "port_fm"])
	var port := snappedf(88.1 + 0.2 * rng.randi_range(0, 99), 0.1)
	# The relay's somewhere else on the band, at least a MHz off the port's.
	var relay := snappedf(fposmod(port - 88.1 + 1.0 + 0.2 * rng.randi_range(0, 89), 20.0) + 88.1, 0.1)
	# The tower too, a MHz or more off both.
	var tower := port
	while absf(tower - port) < 1.0 or absf(tower - relay) < 1.0:
		tower = snappedf(fposmod(port - 88.1 + 2.0 + 0.2 * rng.randi_range(0, 89), 20.0) + 88.1, 0.1)
	var out: Array[Dictionary] = [{"id": &"port_fm", "mhz": port, "at": gods.home(&"ledger", 0.0),
		"mast_m": tuning.fm_mast_m}, {"id": TOWER, "mhz": tower, "at": gods.home(&"ledger", 0.0),
		"mast_m": tuning.fm_mast_m}, {"id": &"relay", "mhz": relay, "sky": &"relay"}]
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.mhz < b.mhz)
	return out


## How far a station's signal clears the noise where it arrives, dB: its
## margin at a kilometre, less the spreading past that, less what the worst edge
## between costs it (edge_loss). `from` and `to` are the station's and the
## radio's places as world metres, x, z, and `from_top` and `to_top` how high
## each antenna stands, m, as the ground's heights are; `ground` the ground's
## height at a world x, z.
static func margin(from: Vector2, from_top: float, to: Vector2, to_top: float, mhz: float, radius: float,
		ground: Callable, tuning: Tuning) -> float:
	var d := from.distance_to(to)
	var spread := 20.0 * log(maxf(d, 1.0) / 1000.0) / log(10.0)
	return tuning.fm_margin_db - maxf(spread, 0.0) - edge_loss(from, from_top, to, to_top, mhz, radius, ground, tuning)


## What the worst edge between two antennas costs a signal, dB: the ground read
## at points along the way, raised by how far the moon's curve bulges up between
## them there (the radio curve, the true one stretched by fm_bend, as the air
## bends VHF a little round it), against the straight line from one to the other.
static func edge_loss(from: Vector2, from_top: float, to: Vector2, to_top: float, mhz: float, radius: float,
		ground: Callable, tuning: Tuning) -> float:
	var d := from.distance_to(to)
	if d < 1.0:
		return 0.0
	var wave := C_MHZ / mhz
	var bend := radius * tuning.fm_bend
	var worst := -INF
	var points := maxi(tuning.fm_profile_points, 2)
	for i in range(1, points):
		var f := float(i) / points
		var d1 := d * f
		var d2 := d - d1
		var at := from.lerp(to, f)
		var bulge := d1 * d2 / (2.0 * bend)
		var above: float = ground.call(at.x, at.y) + bulge - lerpf(from_top, to_top, f)
		worst = maxf(worst, above * sqrt(2.0 * d / (wave * d1 * d2)))
	return knife_edge_db(worst)


## How far a satellite's signal clears the noise where it arrives, dB: the
## margin a ground station has at a kilometre, `boost` over it for the dish it
## aims at Zan, less the spreading over `metres`, less what the ground near you
## costs it toward the satellite, `elevation` rad up along `bearing` (degrees
## from -z): read along that way out to fm_sky_reach_m, the ground falling away
## with the moon's curve as radio sees it, each point against the straight line
## up to it, a knife edge for the worst. From the radio's antenna `top` m high,
## at world x, z.
static func sky_margin(x: float, z: float, top: float, elevation: float, bearing: float, metres: float,
		boost: float, mhz: float, radius: float, ground: Callable, tuning: Tuning) -> float:
	var spread := 20.0 * log(maxf(metres, 1.0) / 1000.0) / log(10.0)
	var wave := C_MHZ / mhz
	var bend := radius * tuning.fm_bend
	var dir := Vector2(sin(deg_to_rad(bearing)), -cos(deg_to_rad(bearing)))
	var worst := -INF
	var points := maxi(tuning.fm_profile_points, 2)
	for i in range(1, points + 1):
		var d := tuning.fm_sky_reach_m * float(i) / points
		var at := Vector2(x, z) + dir * d
		var above: float = ground.call(at.x, at.y) - d * d / (2.0 * bend) - (top + d * tan(elevation))
		worst = maxf(worst, above * sqrt(2.0 / (wave * d)))
	return tuning.fm_margin_db + boost - maxf(spread, 0.0) - knife_edge_db(worst)


## A knife edge's loss, dB, by how far it stands into the way (v, the
## Fresnel-Kirchhoff parameter): nothing well clear of it, 6 dB grazing it,
## and more the deeper behind it (ITU-R P.526's approximation).
static func knife_edge_db(v: float) -> float:
	if v <= -0.78:
		return 0.0
	return 6.9 + 20.0 * log(sqrt(pow(v - 0.1, 2.0) + 1.0) + v - 0.1) / log(10.0)


## How quiet FM comes through at a margin, dB, 0 lost to hiss to 1 quiet:
## nothing under the threshold, and quiet fm_quiet_db over it.
static func quieting(margin_db: float, tuning: Tuning) -> float:
	return smoothstep(tuning.fm_threshold_db, tuning.fm_threshold_db + tuning.fm_quiet_db, margin_db)


## How deep a signal fades where a radio stands in the pattern it makes
## bouncing off the ground about it (multipath), dB: nothing over most of it,
## and a dip every half wavelength or so, some deep. Strong, a station rides
## over the dips; near its threshold walking it flutters, and riding it
## picket-fences. Standing in a dip, a step out of it brings it back. `moved`
## is how far the radio has gone, m.
static func fade_db(moved: float, mhz: float) -> float:
	var phase := moved / (C_MHZ / mhz * 0.5)
	var swell := 0.5 + 0.3 * sin(TAU * phase) + 0.2 * sin(TAU * phase * 0.37 + 1.7)
	return -20.0 * log(clampf(swell * 2.0, 0.03, 1.0)) / log(10.0)


## Where a frequency sits across the band, 0 at its bottom to 1 at its top.
static func share(mhz: float) -> float:
	return clampf(inverse_lerp(LOWEST, HIGHEST, mhz), 0.0, 1.0)
