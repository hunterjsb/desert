extends SceneTree
## The shortwave rig's numbers, worked out before any of it's built: how a
## kite flown high gathers charge, how a stake and the bleed resistor
## take it off, how often an unearthed rig burns a piece out, how fast the
## kite wears, and what its height does for a shortwave signal. Monte Carlo
## over many flights; prints tables.
##   godot --headless --script res://look/radio_kit/charge_model.gd
## (A proposal's model, not the game's: its numbers would move to tuning.tres.)

## Charge, 0 to 1 of what arcs for certain. The air's field grows with height
## and the dust a front's outflow drives charges it far faster (the radio's
## static already says the sand charges up: WeatherField.outflow_at).
const FAIR_RATE := 0.002 ## per s, at 100 m in clear air
const DUST_RATE := 0.06 ## per s, at 100 m, in full outflow
## Charge leaks off into the air on its own, slowly: it climbs toward where
## gathering and leaking balance, so a long flight's chance escalates.
const AIR_TAU := 240.0
## Past this much charge an arc can jump somewhere in the rig; its chance a
## second climbs with the square of how far past, to ARC_MOST at full.
const ARC_FROM := 0.25
const ARC_MOST := 0.5
## An arc takes this much charge with it.
const ARC_SPENDS := 0.7
## The stake's spark gap: past its own threshold it dumps charge to earth.
const GAP_AT := 0.2
const GAP_RATE := 0.5 ## per s, of what's past GAP_AT
## The bleed resistor: a steady leak, a time constant, s.
const BLEED_TAU := 20.0
## An arc picks a piece by how exposed it is: [piece, weight]. The kite's
## dipole is out in it, the hook and converter take what comes down the lead.
const PIECES := [["kite dipole", 3.0], ["aerial lead", 1.0], ["hook", 2.0], ["shortwave converter", 3.0],
	["radio", 1.5]]
## Of arcs, the share that burn the piece out; the rest only scorch it.
const BURNS := 0.6
## Kite wear: a little from flying at all, more past a harm wind, most in a
## sandstorm, where it's gone in about this long, s.
const WEAR_FLYING := 1.0 / (6.0 * 3600.0)
const HARM_WIND := 14.0
const WEAR_WIND := 1.0 / 900.0 ## per s per m/s past HARM_WIND
const STORM_RUIN_S := 75.0
## The kite flies on its line at an angle that rises with the wind: below
## LIFT it won't fly; best between these; above STRAIN it pulls hard.
const LIFT := 3.0
const BEST := Vector2(6.0, 12.0)
const STRAIN := 18.0
## Shortwave: the signal at the ground with the radio's whip, and what a kite
## aerial at h metres adds: about 10 dB a tenfold of height, to a ceiling.
const WHIP_M := 0.3
const MOST_GAIN_DB := 26.0

const SCENES := [
	["calm day, 4 m/s", 4.0, 0.0, 0.0],
	["breezy, 9 m/s", 9.0, 0.05, 0.0],
	["dust front's outflow, 13 m/s", 13.0, 0.6, 0.05],
	["sandstorm, 22 m/s", 22.0, 1.0, 1.0],
]
const SETUPS := [["unearthed", false, false], ["stake", true, false], ["bleed resistor", false, true],
	["both", true, true]]
const LINE_M := 120.0
const FLIGHT_S := 1200.0
const RUNS := 400


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	print("Kite height on %.0f m of line, by wind:" % LINE_M)
	for w in [2.0, 4.0, 6.0, 9.0, 12.0, 16.0, 22.0]:
		var h := height(w, LINE_M)
		print("  %4.0f m/s: %5.1f m up, shortwave +%4.1f dB over the whip%s" % [w, h, gain_db(h),
			"  (won't fly)" if h <= 0.0 else ("  (pulling hard)" if w > STRAIN else "")])
	print("")
	print("Twenty minutes flown on %.0f m of line (%d flights each): chance something burns out, mean time to the first, kite left" % [LINE_M, RUNS])
	for scene: Array in SCENES:
		print("  %s:" % scene[0])
		for setup: Array in SETUPS:
			var burnt := 0
			var first := 0.0
			var hits := {}
			var kite_left := 0.0
			for r in RUNS:
				var got := fly(rng, scene[1], scene[2], scene[3], setup[1], setup[2])
				kite_left += got.kite
				if got.burnt != "":
					burnt += 1
					first += got.at
					hits[got.burnt] = hits.get(got.burnt, 0) + 1
			var top := ""
			var most := 0
			for k: String in hits:
				if hits[k] > most:
					most = hits[k]
					top = k
			print("    %-15s %5.1f%% burn out%s; kite %3.0f%%" % [setup[0], 100.0 * burnt / RUNS,
				(", first at %3.0f s, most often the %s" % [first / burnt, top]) if burnt > 0 else "",
				100.0 * kite_left / RUNS])
	quit()


static func height(wind: float, line: float) -> float:
	if wind < LIFT:
		return 0.0
	# The line's angle: 25° just flying, 60° in its best wind, flattening
	# past it as the kite's pressed back.
	var angle := lerpf(25.0, 60.0, clampf((wind - LIFT) / (BEST.x - LIFT), 0.0, 1.0))
	angle -= maxf(wind - BEST.y, 0.0) * 2.0
	# The line sags: about 85% of it straight.
	return line * 0.85 * sin(deg_to_rad(clampf(angle, 10.0, 60.0)))


static func gain_db(h: float) -> float:
	return minf(10.0 * log(maxf(h, WHIP_M) / WHIP_M) / log(10.0), MOST_GAIN_DB)


## One flight: what burns out first (or ""), when, and how much kite is left.
static func fly(rng: RandomNumberGenerator, wind: float, outflow: float, storm: float, staked: bool,
		bled: bool) -> Dictionary:
	var h := height(wind, LINE_M)
	var q := 0.0
	var kite := 1.0
	var dt := 0.5
	var t := 0.0
	while t < FLIGHT_S:
		if h > 0.0:
			q += (FAIR_RATE + DUST_RATE * outflow) * (h / 100.0) * dt
			kite -= (WEAR_FLYING + WEAR_WIND * maxf(wind - HARM_WIND, 0.0) + storm / STORM_RUIN_S) * dt
		q -= q * dt / AIR_TAU
		if staked and q > GAP_AT:
			q -= (q - GAP_AT) * minf(GAP_RATE * dt, 1.0)
		if bled:
			q -= q * dt / BLEED_TAU
		if q > ARC_FROM:
			var past := (q - ARC_FROM) / (1.0 - ARC_FROM)
			if rng.randf() < ARC_MOST * past * past * dt:
				q *= 1.0 - ARC_SPENDS
				if rng.randf() < BURNS:
					return {"burnt": _pick(rng), "at": t, "kite": maxf(kite, 0.0)}
		q = clampf(q, 0.0, 1.0)
		if kite <= 0.0:
			return {"burnt": "", "at": t, "kite": 0.0}
		t += dt
	return {"burnt": "", "at": t, "kite": maxf(kite, 0.0)}


static func _pick(rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for p: Array in PIECES:
		total += p[1]
	var r := rng.randf() * total
	for p: Array in PIECES:
		r -= p[1]
		if r <= 0.0:
			return p[0]
	return PIECES[-1][0]
