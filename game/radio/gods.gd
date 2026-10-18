class_name Gods
extends RefCounted
## The seven gods on the air: old machine minds, each stuck in its job, each
## broadcasting in its own band from where it stands. Six stand still at the
## landmarks history placed; the Walker walks the Rim and never stops. Each
## one's carrier wanders inside its band, a fresh place every day from the
## seed, so it has to be hunted for. Pure in the seed and world time.

## Each god: id, name, band kHz, home landmark (&"" for the two placed here),
## and how strong it sends.
const ROSTER := [
	[&"quartermaster", "the Quartermaster", Vector2(140.0, 175.0), &"black_site", 1.0],
	[&"walker", "the Walker", Vector2(230.0, 290.0), &"", 0.9],
	[&"cistern", "Mother Cistern", Vector2(410.0, 450.0), &"sister", 1.0],
	[&"almanac", "the Almanac", Vector2(600.0, 660.0), &"", 0.9],
	[&"ledger", "the Ledger", Vector2(880.0, 940.0), &"port_morgan", 1.6],
	[&"stoker", "the Stoker", Vector2(1180.0, 1240.0), &"halloran", 1.2],
	[&"eye", "the Eye", Vector2(1720.0, 1790.0), &"observatory", 0.8],
]
## The Almanac's ag complex stands this far along the Rim from Halfrise, degrees.
const ALMANAC_ALONG := Vector2(6.0, 14.0)
## A carrier keeps this far inside its band, kHz.
const BAND_MARGIN := 4.0

var history: History
var run_seed: int

var _day_seconds: float
var _radius: float
var _walk: float
var _homes := {}
## The Walker's Rim: the great circle 90° from the point under Tu, as two axes
## in its plane, and where on it the run began, rad.
var _rim_u: Vector3
var _rim_v: Vector3
var _walker_from: float


func _init(world_history: History, seed_value: int, tuning: Tuning) -> void:
	history = world_history
	run_seed = seed_value
	_day_seconds = tuning.day_minutes * 60.0
	_radius = world_history.radius
	_walk = tuning.walker_speed
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, "gods"])
	var halfrise: Vector3 = history.landmark(&"halfrise").p
	var sub := history.sub_tu
	_rim_u = (halfrise - sub * halfrise.dot(sub)).normalized()
	_rim_v = sub.cross(_rim_u).normalized()
	_walker_from = rng.randf() * TAU
	var along := deg_to_rad(rng.randf_range(ALMANAC_ALONG.x, ALMANAC_ALONG.y)) * (1.0 if rng.randf() < 0.5 else -1.0)
	_homes[&"almanac"] = (_rim_u * cos(along) + _rim_v * sin(along)).normalized()
	for row: Array in ROSTER:
		if row[3] != &"":
			_homes[row[0]] = history.landmark(row[3]).p


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


## The god whose band holds a frequency, or &"".
static func in_band(khz: float) -> StringName:
	for each: Array in ROSTER:
		if khz >= each[2].x and khz <= each[2].y:
			return each[0]
	return &""


## Where a god is on the sphere at world time t: the Walker somewhere round
## the Rim, the rest at home.
func home(id: StringName, t: float) -> Vector3:
	if id == &"walker":
		var at := _walker_from + _walk * t / _radius
		return (_rim_u * cos(at) + _rim_v * sin(at)).normalized()
	return _homes[id]


## The god's carrier at world time t, kHz: a fresh place in its band each
## moon day, the same for the whole moon.
func carrier(id: StringName, t: float) -> float:
	var b := band(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run_seed, id, floori(t / _day_seconds)])
	return snappedf(rng.randf_range(b.x + BAND_MARGIN, b.y - BAND_MARGIN), 1.0)
