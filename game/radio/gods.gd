class_name Gods
extends RefCounted
## The seven gods on the air: old machine minds, each stuck in its job, each
## broadcasting in its own band from its home. Six stand still where history
## put them, five at their landmarks and the Almanac in Frontier Ag's farm
## domes nearest Halfrise; the Walker walks the Rim and never stops, from the
## point on it farthest from where the run began. Each one's carrier wanders
## inside its band, a fresh place every day from the seed, so it has to be
## hunted for. Pure in the seed, the run's start and world time.

## Each god: id, name, band kHz, home landmark (&"" for the two placed here),
## and how strong it sends.
const ROSTER := [
	[&"quartermaster", "the Quartermaster", Vector2(152.0, 172.0), &"black_site", 1.0],
	# Its survey feed sends strongest after the Ledger's (the storms, signals & sailing spec).
	[&"walker", "the Walker", Vector2(225.0, 275.0), &"", 1.4],
	[&"cistern", "Mother Cistern", Vector2(590.0, 630.0), &"sister", 1.0],
	[&"almanac", "the Almanac", Vector2(680.0, 740.0), &"", 0.9],
	[&"ledger", "the Ledger", Vector2(880.0, 940.0), &"port_morgan", 1.6],
	[&"stoker", "the Stoker", Vector2(1180.0, 1240.0), &"halloran", 1.2],
	[&"eye", "the Eye", Vector2(1620.0, 1690.0), &"observatory", 0.8],
]
## A carrier keeps this far inside its band, kHz.
const BAND_MARGIN := 4.0

var history: History
var run_seed: int
## The living city, whose nomads pray to the Walker and chatter on a carrier of their own.
var city: LivingCity

var _day_seconds: float
var _radius: float
## Each god's carrier, day by day, as far as worked out; and how far it may wander a day, kHz.
var _walked := {}
var _drift: float
var _walk: float
var _homes := {}
## The songs some gods play now and then, by god: when each play began, world
## time, and when the silence after it begins, worked out as far as asked; and
## how long a silence can be, s.
var _plays := {}
var _silences := {}
## Which of its songs each play is, by god, as far as worked out.
var _tracks := {}
## The dial's carriers as worked out for one moon day (dial_carriers).
var _carriers_day := -INF
var _carriers: Array[Array] = []
var _quiet := {}
## When the Stoker's furnace song was last called up, world time: the dev
## console's meltdown, for now.
var meltdown_at := -INF
## The Walker's route, its only home: the Rim, the great circle 90° from the
## point under Tu that the ring road is laid along, as two axes in its plane,
## and where on it it stood at world time 0, rad; and the run's start and
## first moment it was placed for.
var _rim_u: Vector3
var _rim_v: Vector3
var _walker_from: float
var _walker_for := []


func _init(world_history: History, seed_value: int, tuning: Tuning) -> void:
	history = world_history
	run_seed = seed_value
	_day_seconds = tuning.day_minutes * 60.0
	_radius = world_history.radius
	_drift = tuning.carrier_drift_khz
	_walk = tuning.walker_speed
	_quiet[&"eye"] = tuning.eye_quiet_minutes * 60.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "gods"])
	var halfrise: Vector3 = history.landmark(&"halfrise").p
	var sub := history.sub_tu
	_rim_u = (halfrise - sub * halfrise.dot(sub)).normalized()
	_rim_v = sub.cross(_rim_u).normalized()
	_walker_from = rng.randf() * TAU
	city = LivingCity.new(world_history, seed_value, tuning)
	_homes[&"almanac"] = ag_complex(history)
	for row: Array in ROSTER:
		if row[3] != &"":
			_homes[row[0]] = history.landmark(row[3]).p


## The Almanac's Rim ag complex: Frontier Ag's farm domes nearest Halfrise,
## the colony's on the Rim; Halfrise itself on a moon history left none.
static func ag_complex(of: History) -> Vector3:
	var halfrise: Vector3 = of.landmark(&"halfrise").p
	var best := halfrise
	var near := INF
	for each in of.settlements:
		if each.kind == &"farm_dome" and Sphere.angle(each.p, halfrise) < near:
			near = Sphere.angle(each.p, halfrise)
			best = each.p
	return best


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for row: Array in ROSTER:
		out.append(row[0])
	return out


static func row(id: StringName) -> Array:
	for each: Array in ROSTER:
		if each[0] == id:
			return each
	return []


static func title(id: StringName) -> String:
	return row(id)[1]


static func band(id: StringName) -> Vector2:
	return row(id)[2]


static func power(id: StringName) -> float:
	return row(id)[4]


## Puts the Walker where a run's start keeps it far: as the run begins, at
## the point on the Rim farthest from `start`, a quarter of the moon off or
## more for its first three weeks, so finding it never happens early. A
## start under Tu, where every point on the Rim is as far, keeps the seed's.
func place_walker(start: Vector3, began: float) -> void:
	if _walker_for == [start, began]:
		return
	_walker_for = [start, began]
	var sub := history.sub_tu
	var flat := start - sub * start.dot(sub)
	if flat.length() < 1e-6:
		return
	var far := -flat.normalized()
	_walker_from = atan2(far.dot(_rim_v), far.dot(_rim_u)) - _walk * began / _radius


## Where a god is on the sphere at world time t, which its signal comes
## from: the Walker as far round the Rim as it has walked, the rest at home.
func home(id: StringName, t: float) -> Vector3:
	if id == &"walker":
		var at := _walker_from + _walk * t / _radius
		return (_rim_u * cos(at) + _rim_v * sin(at)).normalized()
	return _homes[id]


## Which of a god's songs is playing at world time t and where it is, s into
## it: (song, s), or (-1, -1) when none is. The Stoker's plays through once
## each time it's called up (a meltdown); the Eye's drones come after a
## silence, one of them, the seed's pick, plays through, it falls silent again
## for a few minutes, the seed's pick each time, and so on. `lengths` are its
## songs', s, always the same for a god. The station keeps world time, so it's
## the same whenever you tune in.
func song(id: StringName, t: float, lengths: Array[float]) -> Vector2:
	if id == &"stoker":
		var into := stoker_song(t, lengths[0])
		return Vector2(0.0 if into >= 0.0 else -1.0, into)
	if t < 0.0:
		return Vector2(-1.0, -1.0)
	if not _plays.has(id):
		_plays[id] = [_silence(id, -1)]
		_silences[id] = []
		_tracks[id] = [_track(id, 0, lengths.size())]
	var plays: Array = _plays[id]
	var silences: Array = _silences[id]
	var tracks: Array = _tracks[id]
	while plays[-1] <= t:
		var k := plays.size() - 1
		silences.append(plays[k] + lengths[tracks[k]])
		plays.append(silences[k] + _silence(id, k))
		tracks.append(_track(id, k + 1, lengths.size()))
	var i := plays.bsearch(t, false) - 1
	return Vector2(tracks[i], t - plays[i]) if i >= 0 and t < silences[i] else Vector2(-1.0, -1.0)


## Where the Stoker's song is at world time t, s into it, or -1 when it isn't playing.
func stoker_song(t: float, length: float) -> float:
	return t - meltdown_at if t >= meltdown_at and t - meltdown_at < length else -1.0


## The Stoker's furnace song called up at world time t, from its start.
func meltdown(t: float) -> void:
	meltdown_at = t


## Which of a god's `count` songs its k-th play is: the seed's pick.
func _track(id: StringName, k: int, count: int) -> int:
	return hash([run_seed, id, k, "song"]) % maxi(count, 1)


## How long a god's k-th silence lasts, s: the seed's pick.
func _silence(id: StringName, k: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, id, k])
	var range_s: Vector2 = _quiet[id]
	return rng.randf_range(range_s.x, range_s.y)


## The god's carrier at world time t, kHz: a place in its band that wanders
## each moon day, never more than carrier_drift_khz from the day before
## (Dial.walk), the same for the whole moon.
func carrier(id: StringName, t: float) -> float:
	if not _walked.has(id):
		_walked[id] = []
	return Dial.walk(_walked[id], [run_seed, id], floori(t / _day_seconds), band(id), BAND_MARGIN, _drift)


## Every carrier on the AM dial at world time t, low to high, [kHz, id]: the
## beacon's and each far god's (the near ones are on FM). They move only
## from one moon day to the next, so they're worked out once a day.
func dial_carriers(t: float) -> Array[Array]:
	var day := floorf(t / _day_seconds)
	if day != _carriers_day:
		_carriers_day = day
		_carriers = [[Dial.BEACON_KHZ, &"beacon"]]
		for id in ids():
			if not Fm.is_god(id):
				_carriers.append([carrier(id, t), id])
		_carriers.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return _carriers
