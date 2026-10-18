class_name DayCycle
extends RefCounted
## The 20-minute day. Zan is tidally locked to Tu, so Tu hangs fixed over the
## near side while the sun and the stars turn round the sky once a day, and
## local time follows longitude. The moon has no axial tilt, so the sun rises
## due east, sets due west, and climbs only as high as the latitude allows.
## The sun, Tu and the stars are all worked in the moon's own frame (x toward
## 0° longitude, y toward 90° east, z north), so they share one sky.

## Tu's widths across the sky under trial, degrees (docs/the-moon.md).
const TU_SIZES: Array[float] = [6.0, 9.0, 13.0]
## Tu's geometric albedo, taken as Jupiter's.
const TU_ALBEDO := 0.5
## The sun's angular radius as the storm pass draws it, so the light goes as
## it's seen to.
const SUN_RADIUS := PI / 180.0 * 0.54
## Tu's nod over each day: the orbit's slight eccentricity, and a slighter tilt.
const LIBRATION_LONGITUDE := PI / 180.0 * 1.0
const LIBRATION_LATITUDE := PI / 180.0 * 0.4
## The ring's light through totality, as a share of its flare at the contacts.
const RING_FLOOR := 0.2
## Tu's radius, m, and its mass as GM, m³/s²: 1.1 Jupiter radii, 4 Jupiter masses.
const TU_RADIUS_M := 7.86e7
const TU_GM := 4.0 * 1.26687e17

var _tuning: Tuning
var _day_seconds: float
var _start: float
var _spawn_longitude: float
var _tu_longitude: float


func _init(tuning: Tuning) -> void:
	_tuning = tuning
	_day_seconds = tuning.day_minutes * 60.0
	_start = tuning.start_time_of_day
	_spawn_longitude = deg_to_rad(tuning.spawn_longitude_degrees)
	_tu_longitude = deg_to_rad(tuning.tu_longitude_degrees)


## Local time: 0 at midnight, 0.5 at noon. At the run's spawn it keeps the
## clock the run began on; further east it's later.
func time_of_day(t: float, longitude: float) -> float:
	return fposmod(_clock(t, longitude), 1.0)


## Whether the sun is up. With no tilt it rises at six and sets at six
## everywhere, whatever the weather or Tu does to the light.
func is_day(t: float, longitude: float) -> bool:
	return absf(time_of_day(t, longitude) - 0.5) < 0.25


## Whole local days since the run began, counting the first as day 1.
func day(t: float, longitude: float) -> int:
	return floori(_clock(t, longitude)) + 1


## How far round its orbit Zan is: 0 with the sun behind Tu, 0.5 with Tu full.
func orbit(t: float) -> float:
	return fposmod(_clock(t, _tu_longitude) - 0.5, 1.0)


## Unit vector toward the sun in engine axes (x east, y up, -z north).
func sun_direction(t: float, latitude: float, longitude: float) -> Vector3:
	return _local(_sun(t), latitude, longitude)


## Sunlight on open ground, 0 to 1, before the weather takes its share: none
## of the sun behind Tu reaches it.
func sunlight(t: float, latitude: float, longitude: float) -> float:
	return maxf(0.0, sun_direction(t, latitude, longitude).y) * sun_shown(t)


## The share of the sun's disc not behind Tu, 0 to 1. Tu is far enough off
## that the whole moon sees the same; on the far side the sun is down anyway.
func sun_shown(t: float) -> float:
	var apart := _sun(t).angle_to(_tu(t))
	# Tu's edge is near straight across the small sun: the share of a disc
	# past a chord d of its radii from the centre.
	var d := clampf((apart - tu_radius()) / SUN_RADIUS, -1.0, 1.0)
	return 1.0 - (acos(d) - d * sqrt(1.0 - d * d)) / PI


## The eclipse as it stands: how far Tu's rim is backlit (0 to 1, from just
## before first contact), the ring's flare as the sun goes in or comes out (1
## at the edge, fading as it goes deeper), and the sun's centre from Tu's edge
## in its own radii (1 at first contact, -1 at second).
func eclipse(t: float) -> Vector3:
	var apart := _sun(t).angle_to(_tu(t))
	var r := tu_radius()
	return Vector3(smoothstep(r + 0.05, r - 0.01, apart), exp(-maxf(r - apart, 0.0) / (0.25 * r)),
		(apart - r) / SUN_RADIUS)


## The ring of fire's light, Tu's air bending the sun round its limb, as a
## share of its brightest: none with the sun clear, growing as the sun goes in,
## its most about second and third contact, and a steady fifth through
## totality. Red, and far too weak for panels.
func ring_light(t: float) -> float:
	var now := eclipse(t)
	return now.x * lerpf(RING_FLOOR, 1.0, now.y) * smoothstep(1.0, -1.0, now.z)


## Tu's angular radius: half its width across the sky.
func tu_radius() -> float:
	return deg_to_rad(_tuning.tu_degrees) * 0.5


## How far out Tu's orbit is, in its own radii, for that width.
func tu_orbit() -> float:
	return 1.0 / sin(tu_radius())


## Zan's real day, hours: one lap of the orbit Tu's width sets.
func real_day_hours() -> float:
	var a := tu_orbit() * TU_RADIUS_M
	return TAU * sqrt(a * a * a / TU_GM) / 3600.0


## How many times Tu turns in a day as seen from Zan: its own turns in Zan's
## real day, less the one Zan's lap takes back, since Zan always faces it.
func tu_turns() -> float:
	return real_day_hours() / _tuning.tu_spin_hours - 1.0


## How far Tu has turned as seen from Zan, rad: its clouds slide under the
## point facing Zan by this much. The sky's and the compass's one account.
func tu_turn(t: float) -> float:
	return TAU * fposmod(tu_turns() * t / _day_seconds, 1.0)


## The point under Tu, a place in the moon's frame, nodding with Tu.
func sub_tu(t: float) -> Vector3:
	return _tu(t)


## Unit vector toward Tu's centre in engine axes.
func tu_direction(t: float, latitude: float, longitude: float) -> Vector3:
	return _local(_tu(t), latitude, longitude)


## How bright Tu shows from Zan, 0 dark to 1 full: a Lambert sphere's phase,
## opposite the sun's.
func tu_lit(t: float) -> float:
	var phase := PI - _sun(t).angle_to(_tu(t))
	return (sin(phase) + (PI - phase) * cos(phase)) / PI


## Tu's light on open ground where you stand, as a share of the sun's overhead:
## a full Tu sends sunlight × albedo × (its radius / its distance)², less by
## its phase, and less as it sinks behind the horizon. Physical, before
## Tu-shine's own scale; far too weak for panels.
func tu_light(t: float, latitude: float, longitude: float) -> float:
	var r := sin(tu_radius())
	return TU_ALBEDO * r * r * tu_lit(t) * smoothstep(-r, r, tu_direction(t, latitude, longitude).y)


## World time of the middle of the next eclipse from t on.
func next_eclipse(t: float) -> float:
	return t + (1.0 - orbit(t)) * _day_seconds if orbit(t) > 0.0 else t


## Seconds of totality: the sun's whole disc behind Tu's edge.
func totality() -> float:
	return _crossing(tu_radius() - SUN_RADIUS) * 2.0


## How far the eclipse has cooled the air at t, 0 to 1 of what it would if the
## sun stayed hidden overhead: the air takes as long to follow as it does the
## day, whose peak it puts mid-afternoon, and it follows the sun's height.
func eclipse_chill(t: float, latitude: float, longitude: float) -> float:
	var half := _crossing(tu_radius())
	var lag := tan(TAU * (_tuning.temperature_peak - 0.5)) / TAU * _day_seconds
	# Since the middle of the last eclipse, or of the next once it's begun.
	var since := orbit(t) * _day_seconds
	if since > _day_seconds - half:
		since -= _day_seconds
	var into := since + half
	if into <= 0.0 or lag <= 0.0:
		return 0.0
	var depth := 1.0 - exp(-minf(into, 2.0 * half) / lag)
	if into > 2.0 * half:
		depth *= exp(-(into - 2.0 * half) / lag)
	return depth * maxf(sun_direction(t - since, latitude, longitude).y, 0.0)


## The turn from engine axes where you stand to the stars' frame, which turns
## with the sun: its pole is Zan's, and the sun stays at its +x.
func stars_from(t: float, latitude: float, longitude: float) -> Basis:
	var axes := _axes(latitude, longitude)
	var body := Basis(axes[0], axes[2], -axes[1])
	return Basis(Vector3(0.0, 0.0, 1.0), -_subsolar(t)) * body


func _clock(t: float, longitude: float) -> float:
	return _start + t / _day_seconds + (longitude - _spawn_longitude) / TAU


## The longitude the sun stands over.
func _subsolar(t: float) -> float:
	return _tu_longitude - TAU * orbit(t)


## Toward the sun in the moon's frame, for what's lit in space: the relay.
func sun_toward(t: float) -> Vector3:
	return _sun(t)


## A direction in the moon's frame as engine axes where you stand.
static func local(v: Vector3, latitude: float, longitude: float) -> Vector3:
	return _local(v, latitude, longitude)


## Toward the sun, in the moon's frame.
func _sun(t: float) -> Vector3:
	var at := _subsolar(t)
	return Vector3(cos(at), sin(at), 0.0)


## Toward Tu, in the moon's frame: over the sub-Tu point, nodding a little
## each day.
func _tu(t: float) -> Vector3:
	var round := TAU * orbit(t)
	var lon := _tu_longitude + LIBRATION_LONGITUDE * sin(round)
	var lat := LIBRATION_LATITUDE * cos(round)
	return Vector3(cos(lat) * cos(lon), cos(lat) * sin(lon), sin(lat))


## Seconds either side of mid-eclipse that the sun's centre is within `reach`
## of Tu's, as it closes on Tu at a day's turn plus the nod's.
func _crossing(reach: float) -> float:
	var across := sqrt(maxf(reach * reach - LIBRATION_LATITUDE * LIBRATION_LATITUDE, 0.0))
	return across / (TAU * (1.0 + LIBRATION_LONGITUDE)) * _day_seconds


## East, north and up where you stand, in the moon's frame.
static func _axes(latitude: float, longitude: float) -> Array[Vector3]:
	return [Vector3(-sin(longitude), cos(longitude), 0.0),
		Vector3(-sin(latitude) * cos(longitude), -sin(latitude) * sin(longitude), cos(latitude)),
		Vector3(cos(latitude) * cos(longitude), cos(latitude) * sin(longitude), sin(latitude))]


## A direction in the moon's frame, as engine axes where you stand.
static func _local(v: Vector3, latitude: float, longitude: float) -> Vector3:
	var axes := _axes(latitude, longitude)
	return Vector3(v.dot(axes[0]), v.dot(axes[2]), -v.dot(axes[1]))
