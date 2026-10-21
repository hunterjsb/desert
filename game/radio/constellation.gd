class_name Constellation
extends RefCounted
## Everything still in orbit round Zan that broadcasts (gonkhub, 2026-10-19:
## "many satellites orbiting the moon, each with different broadcasts on
## different frequency ranges"). Each comes from its own era and sends its
## own sound in its own band: most are flavour, a few still stream something
## useful, and some only gibberish. A radio hears one while it's over the
## horizon and on the air, near its carrier, and fainter across its skirt, so
## the band changes as they rise, set and come and go. What each sends is
## shaped by the world as an LFO would shape it: the temperature, the sun, the
## wind, the time to the eclipse and more turn its pitch, its loudness, its
## tone. Each looks its own in the night sky too: colour, shape and size, and
## a route of its own; eight fly in a formation that keeps two overhead always. The relay, which carries the music, is one
## of them. Pure in the seed and world time.
##
## Tracks are placeholders, sounds the game already has, until gonkhub's own:
## the cinder's and the metronome's are in.

## How each shows, as the sky draws it (HULK, the crop survey, is modelled: CropSurvey).
enum Shape { POINT, CROSS, BAR, RING, PAIR, DIAMOND, HULK }

## Each satellite: id; era; band kHz (its carrier a fresh place inside it each
## moon day); orbit {altitude radii, minutes a lap, tilt degrees, backward:
## the share of seeds it goes round backwards}, or {slot} in the FORMATION; look {color, size (1 a
## star's point), shape, light (against the brightest stars' 0.09), blink,
## low (so near the ground it shows as its shadow, lit or not, the bigger the nearer
## it passes you), hidden (never seen)};
## sound {track, db (its trim), pulse (s between plays of a short sound, or
## 0 to loop it)}; lfo [[source, target, at 0, at 1], ...]; duty [minutes on,
## minutes off] or [] for always; and behave, how irregular it is, if at all,
## or how else it's heard (facing_zan: on the air only while on Zan's side of
## the planet it orbits; power: how strongly it comes in, against 1):
## {bursts: on the air in fits, about this share of the time, for spells of
## uneven length; hop: its carrier jumping round its band about this often,
## s, never quite on time; tumble: [Hz, depth], turning over so its signal
## swells and fades by up to `depth` and it glints in the sky; jam: [share,
## kHz], spraying static over the dial round its carrier while it's up, as
## much as `share` of full static on its carrier and falling off over `kHz`
## either side, burying what's near it}. The relay's music is the radio's own.
##
## Bands overlap on purpose, the gods' and each other's: the windsock's skirt
## crosses the music's, the choir's Mother Cistern's, the lullaby's the
## Ledger's and the metronome's the Eye's, so you tune in on the one you want.
##
## Sources, 0 to 1: temperature (-40 to 70 °C where the radio is), sun (0 at
## local midnight, 1 at noon), night (1 after sunset), wind (0 to 25 m/s),
## eclipse (1 as the next one starts, 0 a day before), storm, anomaly,
## elevation (0 on the horizon, 1 overhead), height (0 at the lowest its
## orbit takes it, 1 the highest), facing (for one orbiting Tu, how far round
## to Zan's side it is) and drift (a slow wander of its own). Targets: pitch (scale), volume (dB), cutoff (Hz), drive (0 to 1),
## tremolo (Hz, 0 for none) and pulse (s between plays).
const ROSTER := [
	# Its orbit long since knocked out of true: an ellipse that swings round, and a slow tumble.
	# (Thirteen in all: this, the formation's eight, the crop survey flying low, the ghost,
	# the cinder and the lantern round Tu.)
	{"id": &"relay", "era": "colonial", "band": Vector2(1020.0, 1020.0),
		"orbit": {"eccentricity": 0.3, "precess": 40.0, "apsides": 70.0},
		"look": {"color": Color(1.0, 0.97, 0.9), "size": 1.0, "shape": Shape.POINT, "light": 0.35},
		"sound": {}, "lfo": [], "duty": [], "behave": {"tumble": [0.05, 0.3]}},
	# Frontier Ag's crop survey, flying low to read the ground's heat: 6 km up, a great
	# hull modelled and lit (CropSurvey), crawling up from the horizon and sweeping
	# overhead (gonkhub, 2026-10-19; "6km is better", 2026-10-20). A run begins with it
	# passing over.
	{"id": &"thermal", "era": "Frontier Ag", "band": Vector2(320.0, 350.0),
		# Its lap no whole share of the day, and its plane swinging slowly round, so its
		# track sweeps over every place in time rather than retracing the same lines.
		"orbit": {"altitude": 0.2513, "minutes": 7.95, "tilt": Vector2(20.0, 70.0), "backward": 0.5, "over_start": true,
			"precess": 37.0},
		"look": {"color": Color(1.0, 0.55, 0.15), "size": 16.0, "shape": Shape.HULK, "light": 0.6, "low": true},
		"sound": {"track": Sounds.RADIO_EYE_TUNNEL, "db": -2.0, "pulse": 0.0},
		"lfo": [[&"temperature", &"pitch", 0.7, 1.4], [&"elevation", &"cutoff", 700.0, 7000.0]], "duty": []},
	# StarCom's ionospheric sounder, still sweeping the band to measure the air: a roar
	# that rises and falls, brighter by day. It took the crop survey's place in the formation.
	{"id": &"sounder", "era": "StarCom", "band": Vector2(560.0, 590.0),
		"orbit": {"slot": 0},
		"look": {"color": Color(0.85, 1.0, 0.35), "size": 1.0, "shape": Shape.DIAMOND, "light": 0.3},
		"sound": {"track": Sounds.STORM, "db": -6.0, "pulse": 0.0},
		"lfo": [[&"drift", &"pitch", 0.6, 1.6], [&"sun", &"cutoff", 800.0, 6000.0]], "duty": []},
	# StarCom's timing beacon: its tick quickens as the eclipse comes.
	{"id": &"pendulum", "era": "StarCom", "band": Vector2(700.0, 730.0),
		"orbit": {"slot": 1},
		"look": {"color": Color(0.4, 0.9, 1.0), "size": 1.1, "shape": Shape.CROSS, "light": 0.32},
		"sound": {"track": Sounds.RADIO_PING, "db": 0.0, "pulse": 2.0},
		"lfo": [[&"eclipse", &"pulse", 3.0, 0.25], [&"drift", &"pitch", 0.97, 1.03]], "duty": []},
	# A weather satellite: it roars as the wind does where you are, and frays in a storm.
	{"id": &"windsock", "era": "StarCom", "band": Vector2(1032.0, 1060.0),
		"orbit": {"slot": 2},
		"look": {"color": Color(0.6, 1.0, 0.6), "size": 1.3, "shape": Shape.RING, "light": 0.28},
		"sound": {"track": Sounds.WIND, "db": 2.0, "pulse": 0.0},
		"lfo": [[&"wind", &"volume", -18.0, 0.0], [&"wind", &"cutoff", 400.0, 8000.0], [&"storm", &"drive", 0.0, 0.6]],
		"duty": []},
	# The colony's hymn, high and slow, its pitch sinking with the sun.
	{"id": &"choir", "era": "colonial", "band": Vector2(430.0, 470.0),
		"orbit": {"slot": 3},
		"look": {"color": Color(0.8, 0.7, 1.0), "size": 1.0, "shape": Shape.PAIR, "light": 0.3},
		"sound": {"track": Sounds.RADIO_EYE, "db": 0.0, "pulse": 0.0},
		"lfo": [[&"sun", &"pitch", 0.85, 1.0], [&"drift", &"cutoff", 1200.0, 5000.0]], "duty": []},
	# Wartime noise, still jamming: chirps that never mean anything, wilder near an anomaly,
	# and static it sprays across the band round it while it's overhead.
	{"id": &"babel", "era": "the war", "band": Vector2(1290.0, 1340.0),
		"orbit": {"slot": 4},
		"look": {"color": Color(1.0, 0.25, 0.2), "size": 1.1, "shape": Shape.DIAMOND, "light": 0.3, "blink": true},
		"sound": {"track": Sounds.RADIO_TONES, "db": 0.0, "pulse": 0.6},
		"lfo": [[&"drift", &"pulse", 0.3, 1.2], [&"anomaly", &"drive", 0.2, 0.9], [&"drift", &"pitch", 0.6, 1.8]],
		"duty": [], "behave": {"jam": [0.7, 60.0]}},
	# A children's station from the first years, louder after dark, slower in the cold.
	{"id": &"lullaby", "era": "colonial", "band": Vector2(860.0, 895.0),
		"orbit": {"slot": 5},
		"look": {"color": Color(1.0, 0.6, 0.8), "size": 0.8, "shape": Shape.POINT, "light": 0.3},
		"sound": {"track": Sounds.RADIO_NIGHT, "db": 0.0, "pulse": 0.0},
		"lfo": [[&"temperature", &"pitch", 0.88, 1.05], [&"night", &"volume", -14.0, 0.0]], "duty": []},
	# Mon's customs, large and gold, humming a toll nobody pays.
	{"id": &"tollgate", "era": "Mon", "band": Vector2(1500.0, 1540.0),
		"orbit": {"slot": 6},
		"look": {"color": Color(1.0, 0.85, 0.3), "size": 1.6, "shape": Shape.CROSS, "light": 0.33},
		"sound": {"track": Sounds.SHIELD_HUM, "db": 0.0, "pulse": 0.0},
		"lfo": [[&"sun", &"pitch", 0.5, 0.8], [&"drift", &"tremolo", 0.5, 6.0]], "duty": []},
	# Nobody knows whose: a wild ellipse that dives to the dunes and hangs far out, its plane
	# and perigee swinging round; dim, tumbling, on in fits, never long on one frequency,
	# and loudest in a storm.
	{"id": &"ghost", "era": "unknown", "band": Vector2(60.0, 100.0),
		"orbit": {"altitude": 6.0, "minutes": 23.0, "tilt": Vector2(60.0, 85.0), "backward": 0.5,
			"eccentricity": 0.75, "precess": 110.0, "apsides": 80.0},
		"look": {"color": Color(0.45, 0.55, 1.0), "size": 0.7, "shape": Shape.RING, "light": 0.18},
		"sound": {"track": Sounds.RADIO_EYE_TUNNEL, "db": 0.0, "pulse": 0.0},
		"lfo": [[&"storm", &"volume", -20.0, 0.0], [&"height", &"pitch", 0.75, 0.5]], "duty": [],
		"behave": {"bursts": 0.3, "hop": 17.0, "tumble": [0.37, 0.8]}},
	# A spent tug, its orbit decaying: it sinks lap by lap, roaring brighter as it
	# skims the air, then a burn throws it back up; spinning, wildly swinging round.
	# Its track is gonkhub's own, "Cinder".
	{"id": &"cinder", "era": "the war", "band": Vector2(1150.0, 1175.0),
		"orbit": {"altitude": 2.0, "minutes": 4.4, "tilt": Vector2(20.0, 80.0), "backward": 0.7,
			"eccentricity": 0.15, "precess": 160.0, "apsides": 45.0, "decay": [1.6, 5.0]},
		"look": {"color": Color(1.0, 0.45, 0.12), "size": 1.4, "shape": Shape.POINT, "light": 0.3},
		"sound": {"track": Sounds.RADIO_SAT_CINDER, "db": 0.0, "pulse": 0.0},
		"lfo": [[&"height", &"cutoff", 9000.0, 500.0], [&"height", &"volume", 0.0, -10.0],
			[&"height", &"pitch", 1.1, 0.9]], "duty": [], "behave": {"tumble": [0.9, 0.45]}},
	# StarCom's Tu survey probe, still circling the planet it was sent to map. It can't be
	# seen from Zan; it's heard only from the near side, while it swings round Tu's face
	# toward Zan, faint from so far, clearest straight between, gone behind Tu.
	{"id": &"lantern", "era": "StarCom", "band": Vector2(1590.0, 1620.0),
		"orbit": {"around_tu": {"distance": 60.0, "radii": 1.8}, "minutes": 11.0},
		"look": {"color": Color(0.55, 0.45, 0.35), "size": 0.0, "shape": Shape.POINT, "light": 0.0, "hidden": true},
		"sound": {"track": Sounds.RADIO_DAY, "db": -3.0, "pulse": 0.0},
		"lfo": [[&"facing", &"cutoff", 900.0, 6000.0], [&"facing", &"volume", -12.0, 0.0],
			[&"drift", &"pitch", 0.55, 0.62]], "duty": [], "behave": {"facing_zan": true, "power": 0.6}},
	# A survey drone's dead telemetry, a loop it still plays, rising a little with the
	# sun. Its track is gonkhub's own, "satellite1".
	{"id": &"metronome", "era": "Frontier Ag", "band": Vector2(1695.0, 1735.0),
		"orbit": {"slot": 7},
		"look": {"color": Color(0.75, 1.0, 0.85), "size": 0.9, "shape": Shape.BAR, "light": 0.28},
		"sound": {"track": Sounds.RADIO_SAT_METRONOME, "db": 0.0, "pulse": 0.0},
		"lfo": [[&"sun", &"pitch", 0.9, 1.1], [&"elevation", &"cutoff", 500.0, 4000.0]], "duty": []},
]
## The formation eight of them fly in (gonkhub, 2026-10-19: "always at least
## two active signals throughout a full day night cycle"): eight planes, one
## satellite in each, each 2/8 of a lap on from the last, tilted 55°, 5 radii
## up, a lap in 9 minutes. Laid out so, at least two are 8° or more over the
## horizon everywhere on Zan at every moment, whatever the moon's turn under
## them (searched, and radio probe 28), however the seed turns the whole. Each
## still has a route of its own, its plane; they share one lap, or they'd
## drift out of it.
const FORMATION := {"count": 8, "phasing": 2, "inclination": 55.0, "altitude": 5.0, "minutes": 9.0}
## A cannon's muzzle flash: this many times as bright, fading over this long, s.
const MUZZLE_FLARE := 12.0
const MUZZLE_SECONDS := 0.5
## A decaying satellite's burn shows this long, s, this many times as bright.
const BURN_SECONDS := 4.0
const BURN_FLARE := 6.0
## A carrier keeps this far inside its band, kHz.
const BAND_MARGIN := 2.0
## The temperature and wind an LFO spans, °C and m/s.
const COLDEST := -40.0
const HOTTEST := 70.0
const WINDIEST := 25.0

var run_seed: int
## Each satellite's orbit, by id, and its roster row.
var orbits := {}
var rows := {}

var _day_seconds: float
## Each satellite's carrier, spell by spell, as far as worked out; and how far
## it may wander a spell, kHz.
var _walked := {}
var _drift: float
## When each satellite last fired a cannon, world time.
var _fired := {}


func _init(seed_value: int, tuning: Tuning, start: Vector3) -> void:
	run_seed = seed_value
	_day_seconds = tuning.day_minutes * 60.0
	_drift = tuning.carrier_drift_khz
	for row: Dictionary in ROSTER:
		var orbit: Dictionary = row.orbit.duplicate()
		if orbit.has("slot"):
			orbit.merge(FORMATION)
		if not orbit.is_empty():
			orbit["id"] = row.id
		orbits[row.id] = Satellite.new(seed_value, tuning, start, orbit)
		rows[row.id] = row


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for row: Dictionary in ROSTER:
		out.append(row.id)
	return out


## The satellites that broadcast a sound of their own: all but the relay.
static func voiced() -> Array[StringName]:
	var out: Array[StringName] = []
	for row: Dictionary in ROSTER:
		if not (row.sound as Dictionary).is_empty():
			out.append(row.id)
	return out


func relay() -> Satellite:
	return orbits[&"relay"]


## A satellite's carrier at world time t, kHz: a place in its band that
## wanders each moon day, never more than carrier_drift_khz from the day
## before (Dial.walk), the same for the whole moon; or, for one that hops,
## each hop, the hops never quite evenly spaced.
func carrier(id: StringName, t: float) -> float:
	var band: Vector2 = rows[id].band
	if band.x == band.y:
		return band.x
	var behave: Dictionary = rows[id].get("behave", {})
	var slot := floori(t / _day_seconds)
	if behave.has("hop"):
		var hop: float = behave.hop
		# Warped time: always running forward, so each jump comes once, at uneven gaps.
		slot = floori((t + hop * 0.5 * sin(t * 0.031 + _wander(id, "hop"))) / hop)
	if not _walked.has(id):
		_walked[id] = []
	return Dial.walk(_walked[id], [run_seed, id, "carrier"], slot, band, BAND_MARGIN, _drift)


## Whether a satellite is on the air at world time t: always, or by its duty,
## on so many minutes and off so many, from a start of the seed's choosing.
func on_air(id: StringName, t: float) -> bool:
	var behave: Dictionary = rows[id].get("behave", {})
	if behave.get("facing_zan", false):
		return orbits[id].facing(t) > 0.0
	if behave.has("bursts"):
		return _fits(id, t) > _fits_over(behave.bursts)
	var duty: Array = rows[id].duty
	if duty.is_empty():
		return true
	var cycle: float = (duty[0] + duty[1]) * 60.0
	var phase := float(hash([run_seed, id, "duty"]) % 100000) / 100000.0 * cycle
	return fposmod(t + phase, cycle) < duty[0] * 60.0


## How much of a satellite's signal reaches you as it tumbles at world time
## t, 0 to 1: all of it, for one that doesn't; times how strongly it sends,
## for one far off.
func tumble(id: StringName, t: float) -> float:
	var behave: Dictionary = rows[id].get("behave", {})
	if not behave.has("tumble"):
		return behave.get("power", 1.0)
	var turn: Array = behave.tumble
	return 1.0 - turn[1] * (0.5 - 0.5 * cos(TAU * turn[0] * t + _wander(id, "tumble")))


## How brightly a tumbling satellite glints at world time t, against its
## light: a sharp flash once a turn, dim between. 1 for one that doesn't.
func glint(id: StringName, t: float) -> float:
	var behave: Dictionary = rows[id].get("behave", {})
	if not behave.has("tumble"):
		return 1.0
	var turn: Array = behave.tumble
	var face := 0.5 + 0.5 * cos(TAU * turn[0] * t + _wander(id, "tumble"))
	return lerpf(1.0 - turn[1], 1.0, face) + 2.5 * pow(face, 24.0)


## How much static the jammers overhead spray over a radio tuned to `khz`
## from point p on the sphere at world time t, 0 to 1: the most of any one
## up and on the air, by how near its carrier the dial stands and how high
## it is. `except` leaves one out: a jammer doesn't bury itself.
func jamming(khz: float, p: Vector3, t: float, except := &"") -> float:
	var most := 0.0
	for id: StringName in voiced():
		var behave: Dictionary = rows[id].get("behave", {})
		if id == except or not behave.has("jam") or not on_air(id, t):
			continue
		var elevation: float = orbits[id].seen_from(p, t).elevation
		if elevation <= 0.0:
			continue
		var jam: Array = behave.jam
		var up := smoothstep(0.0, deg_to_rad(10.0), elevation)
		most = maxf(most, jam[0] * up * Dial.pull(khz - carrier(id, t), jam[1]))
	return most


## Whether a decaying satellite is firing its burn at world time t: the first
## few seconds after it reaches its lowest and throws itself back up.
func burning(id: StringName, t: float) -> bool:
	var orbit: Satellite = orbits[id]
	return orbit.decay > 0.0 and fposmod(t, orbit.decay_seconds) < BURN_SECONDS


## A satellite's cannon fired at world time t (Airdrop): its muzzle flashes.
func fire(id: StringName, t: float) -> void:
	_fired[id] = t


## How much brighter a satellite looks for its muzzle's flash at world time
## t: MUZZLE_FLARE times at the shot, falling away over MUZZLE_SECONDS; 1 otherwise.
func flash(id: StringName, t: float) -> float:
	var since: float = t - _fired.get(id, -INF)
	if since < 0.0 or since > MUZZLE_SECONDS:
		return 1.0
	return 1.0 + (MUZZLE_FLARE - 1.0) * (1.0 - since / MUZZLE_SECONDS)


## A wander of a satellite's own, rad: where its irregular waves start.
func _wander(id: StringName, what: String) -> float:
	return float(hash([run_seed, id, what]) % 100000) / 100000.0 * TAU


## Its fits at world time t, -1 to 1: three slow waves out of step, so the
## spells over any level are of uneven length and never repeat.
func _fits(id: StringName, t: float) -> float:
	var h := _wander(id, "fits")
	return (sin(t * 0.021 + h) + 0.7 * sin(t * 0.0537 + 2.3 * h) + 0.5 * sin(t * 0.0119 + 4.1 * h)) / 2.2


## The level its fits stand over for about `share` of the time.
static func _fits_over(share: float) -> float:
	# Measured over long spans: the waves' sum stands over 0.31 a quarter of
	# the time, over 0 half; between, near enough a line.
	return lerpf(0.314, 0.0, clampf((share - 0.25) / 0.25, 0.0, 1.0)) if share >= 0.25 \
		else lerpf(0.75, 0.314, clampf(share / 0.25, 0.0, 1.0))


## The satellites' carriers on the air and over the horizon from point p on
## the sphere at world time t: [kHz, id], low to high, for a sweep.
func carriers(p: Vector3, t: float) -> Array[Array]:
	var out: Array[Array] = []
	for id: StringName in voiced():
		if on_air(id, t) and orbits[id].seen_from(p, t).elevation > 0.0:
			out.append([carrier(id, t), id])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return out


## Where an LFO's source stands for a radio at world time t, 0 to 1. `seen` is
## the satellite as seen from the radio (Satellite.seen_from).
func source(name: StringName, id: StringName, radio: Radio, seen: Dictionary, x: float, z: float, t: float) -> float:
	# Those of the satellite alone need no radio.
	match name:
		&"elevation":
			return seen.elevation / (PI * 0.5)
		&"height":
			return orbits[id].highness(t)
		&"facing":
			return orbits[id].facing(t)
		&"drift":
			# Two slow waves of its own, never quite repeating.
			var h := float(hash([run_seed, id, "drift"]) % 1000) * 0.01
			return 0.5 + 0.3 * sin(t * 0.05 + h) + 0.2 * sin(t * 0.13 + 2.0 * h)
	var weather := radio.world.weather
	var p := radio.point_at(x, z)
	match name:
		&"temperature":
			return inverse_lerp(COLDEST, HOTTEST, weather.field_temperature(radio.global_position, t))
		&"sun":
			return 0.5 - 0.5 * cos(TAU * weather.day.time_of_day(t, Sphere.longitude(p)))
		&"night":
			return 0.0 if weather.day.is_day(t, Sphere.longitude(p)) else 1.0
		&"wind":
			return weather.field.steady_wind_at(x, z, t).length() / WINDIEST
		&"eclipse":
			return 1.0 - (weather.day.next_eclipse(t) - t) / _day_seconds
		&"storm":
			return weather.field.storm_at(x, z, t)
		&"anomaly":
			return weather.field.anomaly_at(x, z, t)
	return 0.0


## What a satellite's LFOs set for a radio now: {pitch, volume, cutoff, drive,
## tremolo, pulse}, each as its sound has it where no LFO turns it.
func shaped(id: StringName, radio: Radio, seen: Dictionary, x: float, z: float, t: float) -> Dictionary:
	var row: Dictionary = rows[id]
	var out := {"pitch": 1.0, "volume": 0.0, "cutoff": 20000.0, "drive": 0.0, "tremolo": 0.0,
		"pulse": row.sound.get("pulse", 0.0)}
	for lfo: Array in row.lfo:
		var v := clampf(source(lfo[0], id, radio, seen, x, z, t), 0.0, 1.0)
		var target: StringName = lfo[1]
		if target == &"cutoff":
			# Heard by octaves: swept on a log scale.
			out.cutoff = exp(lerpf(log(lfo[2]), log(lfo[3]), v))
		else:
			out[String(target)] = lerpf(lfo[2], lfo[3], v)
	return out
