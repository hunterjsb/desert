class_name Satellite
extends RefCounted
## The relay: an old colonial relay satellite still in orbit, still playing
## the port's music station on its loop. Loosely simulated: a quick circular
## orbit high over Zan, tilted by the seed (backwards round half the time),
## so it crosses the night sky far faster than the stars, while the moon turns under it once a
## day, so it rises and sets and each pass crosses the sky somewhere new. It
## starts each run passing over where the run began. A radio hears it only
## while it's over the horizon, faint low down, and its carrier slides a
## little as it comes and goes (a Doppler shift, made audible). The others in
## the constellation (Constellation) orbit the same way on orbits of their
## own: each its height, its lap and its tilt, from where the seed starts it.
##
## An orbit can be irregular, as gonkhub asked of those outside the old formation
## (2026-10-19): an ellipse (eccentricity), so it swoops low and fast at its
## perigee and hangs high and slow at its apogee, by Kepler's equation; its
## plane swinging round the pole lap by lap (nodal precession), and its
## perigee wandering round the ellipse (apsidal precession), so each pass
## takes a route of its own. Loosely: a real moon's pull wouldn't turn an
## orbit this fast. And it can decay: sinking lap by lap through a span of
## heights until a burn throws it back up, over and over. A circle that
## doesn't turn or sink is the plain orbit above.

## How far its orbit's tilt can be from the equator, degrees.
const TILT := Vector2(25.0, 65.0)

var radius: float
## Its mean height over the ground, moon radii: half way between its lowest
## and highest, the ellipse's semi-major axis less the moon.
var altitude: float
var period: float
var day_seconds: float
## How far from a circle, 0 a circle; and how fast its plane and its perigee
## turn, rad/s.
var eccentricity := 0.0
var precession := 0.0
var apsidal := 0.0
## How far it sinks before its burn, radii, and over how long, s; 0 for none.
var decay := 0.0
var decay_seconds := 0.0

## Orbiting Tu instead of Zan: Tu's middle, in the moon's frame, moon radii
## (Zan keeps one face to Tu, so Tu stands still in that frame); and its ring
## round Tu, as two axes and a radius, moon radii. A zero radius is an orbit of Zan.
var _around := Vector3.ZERO
var _ring_u := Vector3.ZERO
var _ring_v := Vector3.ZERO
var _ring_r := 0.0

## Where its perigee is round the orbit at the run's start, rad from the node.
var _perigee := 0.0
## Its mean anomaly at the run's start, rad.
var _mean := 0.0

## The orbit as two axes in its plane, in the moon's frame at the run's start
## (x toward 0° longitude, y toward 90° east, z north), and where on it the
## relay was then, rad.
var _node: Vector3
var _across: Vector3
var _phase: float

## Held over a place on the ground instead (the drone over Port
## Morgan): that place, its plane's other axis at the run's start, both on
## the moon and turning with it, and how fast its plane swings round that
## place, rad/s. A zero place is an orbit among the stars.
var _pole := Vector3.ZERO
var _toward := Vector3.ZERO
var _swing := 0.0


## Its orbit for a run, passing over `start` (a point on the sphere) at world
## time 0. `orbit` gives another satellite's own, {id, altitude (radii),
## minutes (a lap), tilt (degrees from the equator, the least and most),
## backward (the share of seeds it goes round backwards)}, starting it over a
## point of the seed's choosing instead; left empty, it's the relay's. Any
## orbit can be irregular too: {eccentricity, precess (degrees its plane swings round the
## pole a lap), apsides (degrees its perigee wanders a lap)}; its perigee
## starts where the seed puts it.
func _init(run_seed: int, tuning: Tuning, start: Vector3, orbit := {}) -> void:
	radius = tuning.moon_circumference / TAU
	altitude = orbit.get("altitude", tuning.relay_altitude_radii)
	period = orbit.get("minutes", tuning.relay_period_minutes) * 60.0
	day_seconds = tuning.day_minutes * 60.0
	if orbit.has("decay"):
		decay = minf(orbit.decay[0], altitude)
		decay_seconds = orbit.decay[1] * period
	# Never so eccentric it grazes the ground, sunk as far as it sinks: its
	# perigee a fifth of a radius up at least.
	eccentricity = clampf(orbit.get("eccentricity", 0.0), 0.0, 1.0 - 1.2 / (1.0 + altitude - decay * 0.5))
	precession = deg_to_rad(orbit.get("precess", 0.0)) / period
	apsidal = deg_to_rad(orbit.get("apsides", 0.0)) / period
	if orbit.has("around_tu"):
		_round_tu(run_seed, tuning, orbit)
		return
	if orbit.get("through", Vector3.ZERO) != Vector3.ZERO:
		_through(run_seed, start, orbit)
		return
	if orbit.has("lagrange"):
		_at_lagrange(run_seed, tuning, orbit)
		return
	var relay: bool = orbit.get("id", &"relay") == &"relay"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, "relay"]) if relay else hash([run_seed, "satellite", orbit.id])
	if not relay and not orbit.get("over_start", false):
		# Low enough that any tilt it may have still crosses it.
		start = Sphere.point(asin(rng.randf_range(-0.3, 0.3)), rng.randf() * TAU)
	var latitude := Sphere.latitude(start)
	var range_deg: Vector2 = orbit.get("tilt", TILT)
	var tilt := maxf(deg_to_rad(rng.randf_range(range_deg.x, range_deg.y)), absf(latitude) + 0.01)
	if rng.randf() < orbit.get("backward", 0.5):
		tilt = PI - tilt
	# Where on a tilted circle a point at that latitude lies, and the node that puts it under start.
	_phase = asin(clampf(sin(latitude) / sin(tilt), -1.0, 1.0))
	var node_longitude := Sphere.longitude(start) - atan2(cos(tilt) * sin(_phase), cos(_phase))
	_node = Vector3(cos(node_longitude), sin(node_longitude), 0.0)
	_across = Vector3(-sin(node_longitude) * cos(tilt), cos(node_longitude) * cos(tilt), sin(tilt))
	_start_on_ellipse(run_seed, orbit)


## Where on its ellipse it starts, keeping it over the point its plane puts it
## at the start (_phase, rad round from the node): its perigee where the seed
## puts it, and the mean anomaly that has it there. A circle starts as it is.
func _start_on_ellipse(run_seed: int, orbit: Dictionary) -> void:
	if eccentricity <= 0.0:
		_mean = _phase
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, "perigee", orbit.get("id", &"relay")])
	_perigee = rng.randf() * TAU
	var true_anomaly := _phase - _perigee
	var e := eccentricity
	var eccentric := 2.0 * atan2(sqrt(1.0 - e) * sin(true_anomaly * 0.5), sqrt(1.0 + e) * cos(true_anomaly * 0.5))
	_mean = eccentric - e * sin(eccentric)


## An orbit through one place on the ground every lap (gonkhub, 2026-10-21:
## "Update its flight path to ensure it always passes over Port Morgan,
## letting its path rotate around the moon otherwise"): a great circle
## through it, flown on the moon rather than among the stars (it's a drone,
## and keeps to its route), its plane swinging round that place by its
## precess a lap, so the rest of its track sweeps every place in time. At the
## start it's over `start` on the plane through both, the way the seed sends it.
func _through(run_seed: int, start: Vector3, orbit: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, "satellite", orbit.id])
	_pole = (orbit.through as Vector3).normalized()
	_swing = precession
	precession = 0.0
	var off := start - _pole * start.dot(_pole)
	if off.length() < 1e-4:
		off = _pole.cross(Vector3(0.0, 0.0, 1.0) if absf(_pole.z) < 0.9 else Vector3(1.0, 0.0, 0.0))
	_toward = off.normalized()
	if rng.randf() < orbit.get("backward", 0.5):
		_toward = -_toward
	_phase = atan2(start.dot(_toward), start.dot(_pole))


## How long from world time t until it's next over the place its route holds
## to, s; INF for an orbit that holds to none.
func until_through(t: float) -> float:
	if _pole == Vector3.ZERO:
		return INF
	return fposmod(-(_phase + TAU * t / period), TAU) / TAU * period


## An orbit of Tu (gonkhub, 2026-10-19: "an 11th satellite orbiting Tu"): Tu
## where it hangs, tu_distance_radii off toward the point under it, its size
## the share of the sky tu_degrees gives it; the ring round it so many of Tu's
## radii out, a lap in its minutes, its plane holding Zan's line, so it swings
## round in front of Tu, toward Zan, and round behind, from where the seed starts it.
func _round_tu(run_seed: int, tuning: Tuning, orbit: Dictionary) -> void:
	var toward := Sphere.point(0.0, deg_to_rad(tuning.tu_longitude_degrees))
	var far: float = orbit.around_tu.distance
	_around = toward * far
	var tu_radius := far * tan(deg_to_rad(tuning.tu_degrees * 0.5))
	_ring_r = tu_radius * orbit.around_tu.radii
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, "satellite", orbit.id])
	# Its plane holds the line to Zan, tilted round it by the seed.
	var side := Vector3(0.0, 0.0, 1.0).cross(toward).normalized().rotated(toward, rng.randf_range(-0.6, 0.6))
	_ring_u = side
	_ring_v = -toward
	_phase = rng.randf() * TAU
	altitude = far - 1.0


## Hung at one of Zan and Tu's Lagrange points, since a moon that keeps one face
## to its planet has no stationary orbit: one would need a lap as long as Zan's
## round Tu, out past where Zan's pull holds anything against Tu's. L1 lies
## between Zan and Tu, so from the near side it hangs beside Tu, never setting;
## L2 behind Zan, over the anti-Tu point. Real relays loop round such a point on
## a halo, as Queqiao loops past the Moon's far side to see both its lander and
## Earth, and so does this: a slow ring across the line to Tu, wide enough to
## see round the moon. Tu stands still in the moon's frame, so the point does too.
func _at_lagrange(run_seed: int, tuning: Tuning, orbit: Dictionary) -> void:
	var toward := Sphere.point(0.0, deg_to_rad(tuning.tu_longitude_degrees))
	_around = toward * tuning.lagrange_radii * (1.0 if orbit.lagrange == 1 else -1.0)
	_ring_r = tuning.halo_radii
	_ring_u = Vector3(0.0, 0.0, 1.0).cross(toward).normalized()
	_ring_v = Vector3(0.0, 0.0, 1.0)
	period = tuning.halo_minutes * 60.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, "satellite", orbit.id])
	_phase = rng.randf() * TAU
	altitude = tuning.lagrange_radii - 1.0


## How far round to Zan's side of Tu it is at world time t, 0 at Tu's limb
## or behind it, 1 straight between Tu and Zan; 0 for an orbit of Zan, or one
## hung at a Lagrange point.
func facing(t: float) -> float:
	if _ring_r <= 0.0 or _around.length() < 30.0:
		return 0.0
	return maxf(0.0, (at(t) - _around).normalized().dot(-_around.normalized()))


## Its place at world time t, in the moon's frame, moon radii from its middle:
## round its ellipse by Kepler's equation, its perigee and plane turned as far
## as they've turned, less the turn the moon has made under it since.
func at(t: float) -> Vector3:
	if _pole != Vector3.ZERO:
		var lap := _phase + TAU * t / period
		var other := _toward.rotated(_pole, _swing * t)
		return (_pole * cos(lap) + other * sin(lap)) * (1.0 + altitude)
	if _ring_r > 0.0:
		var angle := _phase + TAU * t / period
		return _around + (_ring_u * cos(angle) + _ring_v * sin(angle)) * _ring_r
	var a := 1.0 + altitude + sinking(t)
	var mean := _mean + TAU * t / period
	var u: float
	var r := a
	if eccentricity <= 0.0:
		u = mean
	else:
		var e := eccentricity
		var eccentric := mean
		for i in 6:
			eccentric -= (eccentric - e * sin(eccentric) - mean) / (1.0 - e * cos(eccentric))
		var true_anomaly := 2.0 * atan2(sqrt(1.0 + e) * sin(eccentric * 0.5), sqrt(1.0 - e) * cos(eccentric * 0.5))
		r = a * (1.0 - e * cos(eccentric))
		u = _perigee + apsidal * t + true_anomaly
	var inertial := (_node * cos(u) + _across * sin(u)) * r
	return inertial.rotated(Vector3(0.0, 0.0, 1.0), precession * t - TAU * t / day_seconds)


## Turned onto an orbit that brings it straight over point p on the sphere
## at world time t, its height, lap and tilt as they were (tilted no less than
## p's latitude needs), only its plane and its place round it moved: where p
## will be among the stars at t, the moon's turn under it and its plane's own
## swing taken back, put on its plane, and it there at t. A circle's orbit
## (the drone's); an ellipse would need its perigee moved too.
func pass_over(p: Vector3, t: float) -> void:
	if _pole != Vector3.ZERO:
		# Its route still through its place: the plane turned to hold p as well.
		var off := p - _pole * p.dot(_pole)
		if off.length() > 1e-4:
			var toward := off.normalized()
			_toward = toward.rotated(_pole, -_swing * t)
			_phase = atan2(p.dot(toward), p.dot(_pole)) - TAU * t / period
		else:
			_phase = (0.0 if p.dot(_pole) > 0.0 else PI) - TAU * t / period
		return
	var q := p.rotated(Vector3(0.0, 0.0, 1.0), TAU * t / day_seconds - precession * t)
	var latitude := Sphere.latitude(q)
	var tilt := acos(clampf(_node.cross(_across).z, -1.0, 1.0))
	var least := asin(minf(absf(sin(latitude)) + 0.02, 1.0))
	if tilt < PI * 0.5:
		tilt = maxf(tilt, least)
	else:
		tilt = minf(tilt, PI - least)
	var round_to := asin(clampf(sin(latitude) / sin(tilt), -1.0, 1.0))
	var node_longitude := Sphere.longitude(q) - atan2(cos(tilt) * sin(round_to), cos(round_to))
	_node = Vector3(cos(node_longitude), sin(node_longitude), 0.0)
	_across = Vector3(-sin(node_longitude) * cos(tilt), cos(node_longitude) * cos(tilt), sin(tilt))
	_phase = round_to - TAU * t / period
	_mean = _phase


## Its height over the ground at world time t, moon radii.
func height(t: float) -> float:
	return at(t).length() - 1.0


## How far its decay has it off its mean height at world time t, radii: from
## half its span up, sinking to half down, then its burn throws it back.
func sinking(t: float) -> float:
	if decay <= 0.0:
		return 0.0
	return decay * (0.5 - fposmod(t, decay_seconds) / decay_seconds)


## The lowest and highest it ever flies, its middle's distance, moon radii.
func reach() -> Vector2:
	var a := 1.0 + altitude
	return Vector2(a * (1.0 - eccentricity) - decay * 0.5, a * (1.0 + eccentricity) + decay * 0.5)


## How high it is in its range at world time t, 0 at its lowest, 1 at its
## highest; a plain circle is always half way.
func highness(t: float) -> float:
	var span := reach()
	if span.y - span.x < 1e-4:
		return 0.5
	return clampf(inverse_lerp(span.x, span.y, at(t).length()), 0.0, 1.0)


## How much brighter it looks than at its mean distance, as light falls off
## with the square of distance: a near swoop bright, far out dim.
func nearness(t: float) -> float:
	return clampf(pow((1.0 + altitude) / at(t).length(), 2.0), 0.25, 4.0)


## The point on the sphere it's over at world time t, in the moon's frame:
## round its orbit, less the turn the moon has made under it since.
func under(t: float) -> Vector3:
	return at(t).normalized()


## Where it is, seen from a point on the sphere at world time t: {elevation
## (rad over the horizon), bearing (rad clockwise from north there), metres
## (the slant range), rate (m/s it's drawing away, less as it nears)}.
func seen_from(p: Vector3, t: float) -> Dictionary:
	var now := _from(p, t)
	var later := _from(p, t + 1.0)
	return {"elevation": now.elevation, "bearing": Sphere.bearing(p, under(t)), "metres": now.metres,
		"rate": later.metres - now.metres}


## Whether the sun lights it at world time t, or it's in Zan's shadow:
## behind the moon from the sun and within the moon's width of the line to it.
func sunlit(t: float, sun: Vector3) -> bool:
	var where := at(t)
	return where.dot(sun) > 0.0 or (where - sun * where.dot(sun)).length() > 1.0


## The fastest it ever draws away or nears, m/s: for scaling its slide. On an
## ellipse, as fast as it goes at its perigee.
func top_rate() -> float:
	var swoop := sqrt((1.0 + eccentricity) / (1.0 - eccentricity))
	return TAU * radius * ((1.0 + altitude) / period * swoop + 1.0 / day_seconds)


func _from(p: Vector3, t: float) -> Dictionary:
	var to := at(t) - p
	return {"elevation": asin(clampf(to.normalized().dot(p), -1.0, 1.0)), "metres": to.length() * radius}
