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


## Every carrier on the dial at world time t, low to high: [kHz, id].
static func carriers(gods: Gods, t: float) -> Array[Array]:
	var out: Array[Array] = [[MUSIC_KHZ, &"music"], [BEACON_KHZ, &"beacon"]]
	for id in Gods.ids():
		out.append([gods.carrier(id, t), id])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return out


## How much of a carrier a radio tuned `off` kHz from it gets, 0 to 1.
static func pull(off: float, width: float) -> float:
	return exp(-2.0 * pow(off / width, 2.0)) if width > 0.0 else (1.0 if off == 0.0 else 0.0)


## How strong a god's signal arrives over `metres` of ground, 0 to about 1.5:
## a ground wave that carries far at low frequencies and short at high ones,
## and at night, for anything over 500 kHz, a sky wave that comes down past
## the skip, real AM behaviour. Times how strong the god sends.
static func strength(id: StringName, khz: float, metres: float, night: bool, tuning: Tuning) -> float:
	var reach := tuning.ground_wave_m * minf(1.0, pow(GROUND_KHZ / maxf(khz, 1.0), 2.0))
	var ground := exp(-metres / reach)
	var sky := tuning.sky_wave if night and khz > GROUND_KHZ and metres > tuning.skip_m else 0.0
	return maxf(ground, sky) * Gods.power(id)


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
