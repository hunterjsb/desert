class_name Dial
extends RefCounted
## The radio's dial, 0 to 2000 kHz, and how a signal on it reaches you: which
## carriers it holds, how near one you're tuned, how strong a god's comes in
## from where it stands, and which way it lies. Nothing on the dial says what
## a carrier is: you learn the dial by listening.

const LOWEST := 0.0
const HIGHEST := 2000.0
## The two carriers that aren't gods: the music and the beacon.
const MUSIC_KHZ := 1020.0
const BEACON_KHZ := 1930.0
## A ground wave carries its full reach at or under this, kHz.
const GROUND_KHZ := 500.0
## Past this far round the moon, m, the opposite point is near enough that a
## god there comes from everywhere at once.
const EVERYWHERE_M := 4000.0


## Every carrier on the dial at world time t, low to high: [kHz, id]. The
## living city's is one, heard only near it.
static func carriers(gods: Gods, t: float) -> Array[Array]:
	var out: Array[Array] = [[MUSIC_KHZ, &"music"], [BEACON_KHZ, &"beacon"], [gods.city.carrier(), &"city"]]
	for id in Gods.ids():
		out.append([gods.carrier(id, t), id])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return out


## A home frequency that wanders inside its band from one spell to the next
## (a moon day for most, a hop for one that hops), never more than `step`
## kHz from where it was (gonkhub, 2026-10-20: "ensure a 'home frequency' cannot
## shift more than 5khz from where it was last"), turning back off the band's
## edges: a walk from the run's start, the seed's steps. `walked` holds each
## spell's frequency as far as worked out, the caller's own for this carrier;
## `key` seeds it. Spells before the first are the first.
static func walk(walked: Array, key: Array, spell: int, band: Vector2, margin: float, step: float) -> float:
	var low := band.x + margin
	var high := band.y - margin
	var rng := RandomNumberGenerator.new()
	if walked.is_empty():
		rng.seed = hash(key + [0])
		walked.append(snappedf(rng.randf_range(low, high), 1.0))
	while walked.size() <= spell:
		rng.seed = hash(key + [walked.size()])
		var next: float = walked[-1] + rng.randf_range(-step, step)
		# Off an edge it turns back, by as much as it would have gone past.
		if next < low:
			next = low + (low - next)
		elif next > high:
			next = high - (next - high)
		walked.append(snappedf(clampf(next, low, high), 1.0))
	return walked[maxi(spell, 0)]


## How much of a carrier a radio tuned `off` kHz from it gets, 0 to 1.
static func pull(off: float, width: float) -> float:
	return exp(-2.0 * pow(off / width, 2.0)) if width > 0.0 else (1.0 if off == 0.0 else 0.0)


## How much of a broadcast a radio tuned `off` kHz from its carrier hears, 0
## to 1: all of it on its carrier, falling off within dial_width_khz, and a
## share of it farther out across its skirt, so near ones overlap.
static func heard(off: float, tuning: Tuning) -> float:
	return maxf(pull(off, tuning.dial_width_khz), tuning.dial_skirt_share * pull(off, tuning.dial_skirt_khz))


## How far from a carrier the dial still counts it as the one it hears, kHz.
static func reach(tuning: Tuning) -> float:
	return maxf(tuning.dial_skirt_khz * tuning.dial_skirt_reach, tuning.dial_width_khz * 2.0)


## How strong a god's signal arrives over `metres` of ground, 0 to about 1.5:
## a ground wave that carries far at low frequencies and short at high ones,
## and at night, for anything over 500 kHz, a sky wave that comes down past
## the skip, real AM behaviour. Times how strong the god sends.
static func strength(id: StringName, khz: float, metres: float, night: bool, tuning: Tuning) -> float:
	var reach := tuning.ground_wave_m * minf(1.0, pow(GROUND_KHZ / maxf(khz, 1.0), 2.0))
	var ground := exp(-metres / reach)
	var sky := tuning.sky_wave if night and khz > GROUND_KHZ and metres > tuning.skip_m else 0.0
	return maxf(ground, sky) * Gods.power(id)


## Whether a signal reaches you by its sky wave rather than along the ground:
## at night, over 500 kHz, past the skip, where the sky wave is the stronger.
static func by_sky(khz: float, metres: float, night: bool, tuning: Tuning) -> bool:
	if not night or khz <= GROUND_KHZ or metres <= tuning.skip_m:
		return false
	var reach := tuning.ground_wave_m * minf(1.0, pow(GROUND_KHZ / maxf(khz, 1.0), 2.0))
	return tuning.sky_wave > exp(-metres / reach)


## Which way a god lies from where you stand, as a radio says it: a compass
## point near, a rougher one farther, and past that only a way across the
## moon. `ground` is its bearing on the ground, degrees from -z; `say_point`
## turns one into words by the moon's north there.
static func way(history: History, from: Vector3, to: Vector3, ground: float, say_point: Callable,
		tuning: Tuning) -> String:
	var metres := Sphere.angle(from, to) * history.radius
	if metres <= tuning.god_exact_m:
		return say_point.call(ground)
	if metres <= tuning.god_rough_m:
		var rough: String = say_point.call(snappedf(ground, 45.0))
		return "somewhere " + rough
	if (PI - Sphere.angle(from, to)) * history.radius < EVERYWHERE_M:
		return "from everywhere"
	# Far off: toward Tu or away from it, or along the Rim if neither.
	var tu_way := Sphere.bearing(from, history.sub_tu)
	var off := absf(angle_difference(Sphere.bearing(from, to), tu_way))
	if Sphere.angle(from, history.sub_tu) < 1e-6:
		return "away from Tu"
	if off < PI / 3.0:
		return "toward Tu"
	if off > PI * 2.0 / 3.0:
		return "away from Tu"
	var east := Sphere.bearing(from, to) - tu_way
	return "across the face of Tu, %s" % ("right" if wrapf(east, -PI, PI) > 0.0 else "left")
