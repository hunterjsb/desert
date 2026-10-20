class_name Garble
extends RefCounted
## What interference does to a signal, as sound (gonkhub, 2026-10-19: "instead
## of just reducing volume and increasing static for interference, let's run
## signals through distortion based on their interference ... bit crushing or
## just like glitchy effects ... a lot more layered and a lot more textured").
## A chain on the signal's bus, each stage biting harder the dirtier the
## signal comes through, from a clean pass at none to a broken, chewed-up
## thing at all, and its settings jumping in small uneven steps so it never
## sits still:
##
## - a narrowing band: the lows thinning and the highs closing in, ringing a
##   little, as a weak AM signal does;
## - a crusher (Godot's lo-fi distortion): the bits and the rate falling away,
##   in jumps;
## - grit, an overdrive, past a little dirt;
## - a warble, a phaser sweeping faster as it worsens;
## - a smear, short echoes feeding back, as a signal bounced the long way round.
##
## Dirt is 0 to 1 (Garble.dirt). The scripted glitches on top, stutters,
## dropouts and pitch jumps, are Glitch's.

## Its stages, in order on the bus from `from` (add_chain).
enum Stage { LOWS, HIGHS, CRUSH, GRIT, WARBLE, SMEAR }
const STAGES := 6
## How the dirt is reckoned: what an anomaly near adds, at its deepest; and
## what being off a carrier, out on its skirt, adds.
const ANOMALY := 0.5
const OFF_TUNE := 0.35
## Its settings jump this often, s, at the most dirt; less often at little.
const STEP := 0.09
## The band: its top falls from here to here, Hz, its bottom rises to here.
const OPEN_HZ := 16000.0
const SHUT_HZ := 1300.0
const THIN_HZ := 900.0
## The crusher keeps from this high down to this, Hz.
const CRUSH_HZ := Vector2(700.0, 16000.0)


## How dirty a signal comes through, 0 clean to 1 lost: how weak it is where
## it arrives (`power`, before the dial, against the floor of a clean one),
## how much a storm on the way lets through, how much a jammer buries it, an
## anomaly near, and how far off its carrier the dial is (0 on it, 1 out on
## its skirt).
static func dirt(power: float, through: float, jammed: float, anomaly: float, off_tune: float,
		tuning: Tuning) -> float:
	var kept := smoothstep(tuning.signal_floor, 0.5, power) * through * (1.0 - jammed)
	return clampf(1.0 - kept + anomaly * ANOMALY + off_tune * OFF_TUNE, 0.0, 1.0)


## The chain added to a bus, after what it has; says where it starts.
static func add_chain(bus: int) -> int:
	var from := AudioServer.get_bus_effect_count(bus)
	var lows := AudioEffectHighPassFilter.new()
	lows.cutoff_hz = 20.0
	AudioServer.add_bus_effect(bus, lows)
	var highs := AudioEffectLowPassFilter.new()
	highs.cutoff_hz = OPEN_HZ
	AudioServer.add_bus_effect(bus, highs)
	var crush := AudioEffectDistortion.new()
	crush.mode = AudioEffectDistortion.MODE_LOFI
	AudioServer.add_bus_effect(bus, crush)
	var grit := AudioEffectDistortion.new()
	grit.mode = AudioEffectDistortion.MODE_OVERDRIVE
	AudioServer.add_bus_effect(bus, grit)
	var warble := AudioEffectPhaser.new()
	warble.range_min_hz = 300.0
	warble.range_max_hz = 3000.0
	AudioServer.add_bus_effect(bus, warble)
	var smear := AudioEffectDelay.new()
	smear.tap1_active = true
	smear.tap2_active = false
	smear.feedback_active = true
	smear.feedback_lowpass = 3000.0
	AudioServer.add_bus_effect(bus, smear)
	for k in STAGES:
		AudioServer.set_bus_effect_enabled(bus, from + k, k <= Stage.HIGHS)
	return from


## The chain on bus `bus` from effect `from` set for dirt at world time t;
## `key` keeps one signal's jumps its own.
static func shape(bus: int, from: int, amount: float, t: float, key: int) -> void:
	var d := clampf(amount, 0.0, 1.0)
	# Settings jump, the more often the worse: a fresh roll each step.
	var step := floori(t / (STEP * lerpf(4.0, 1.0, d)))
	var roll := func(n: int) -> float: return float(hash([key, step, n]) & 0xffff) / 65535.0
	var lows := AudioServer.get_bus_effect(bus, from + Stage.LOWS) as AudioEffectHighPassFilter
	var highs := AudioServer.get_bus_effect(bus, from + Stage.HIGHS) as AudioEffectLowPassFilter
	lows.cutoff_hz = lerpf(20.0, THIN_HZ, pow(d, 1.3))
	highs.cutoff_hz = exp(lerpf(log(OPEN_HZ), log(SHUT_HZ), d)) * lerpf(1.0, 0.6 + 0.6 * roll.call(1), d)
	highs.resonance = 0.5 + 0.35 * d
	_stage(bus, from + Stage.CRUSH, d > 0.03)
	if d > 0.03:
		var crush := AudioServer.get_bus_effect(bus, from + Stage.CRUSH) as AudioEffectDistortion
		crush.drive = minf(0.95, d * (0.7 + 0.5 * roll.call(2)))
		crush.keep_hf_hz = exp(lerpf(log(CRUSH_HZ.y), log(CRUSH_HZ.x), d * (0.4 + 0.6 * roll.call(3))))
		crush.post_gain = -6.0 * d
	_stage(bus, from + Stage.GRIT, d > 0.15)
	if d > 0.15:
		var grit := AudioServer.get_bus_effect(bus, from + Stage.GRIT) as AudioEffectDistortion
		grit.drive = pow(d, 1.5) * 0.8
		grit.post_gain = -9.0 * d
	_stage(bus, from + Stage.WARBLE, d > 0.1)
	if d > 0.1:
		var warble := AudioServer.get_bus_effect(bus, from + Stage.WARBLE) as AudioEffectPhaser
		warble.depth = 0.9 * d
		warble.rate_hz = 0.2 + 4.0 * d * roll.call(4)
		warble.feedback = 0.3 + 0.5 * d
	_stage(bus, from + Stage.SMEAR, d > 0.25)
	if d > 0.25:
		var smear := AudioServer.get_bus_effect(bus, from + Stage.SMEAR) as AudioEffectDelay
		smear.tap1_delay_ms = 25.0 + 90.0 * roll.call(5)
		smear.tap1_level_db = lerpf(-40.0, -6.0, d)
		smear.feedback_delay_ms = 60.0 + 120.0 * roll.call(6)
		smear.feedback_level_db = lerpf(-40.0, -10.0, d)


## Whether a stage is on, set only when it changes.
static func _stage(bus: int, index: int, on: bool) -> void:
	if AudioServer.is_bus_effect_enabled(bus, index) != on:
		AudioServer.set_bus_effect_enabled(bus, index, on)
