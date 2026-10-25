class_name Vitals
extends Node
## You, as the moon wears on you: health out of 100, and what you're
## prepared with (Buffs). On power's tick of world time, so the frame rate
## never changes either and the dev time warp runs them with everything else.
## The three harms take health through the felt weather, so a bubble that
## blocks one keeps it off you. Going without food or water never harms you;
## eating, drinking and resting only help. Unharmed, you heal. At no health
## you die, and the run is over.

signal died

const FULL := 100.0
const HARMS: Array[StringName] = [&"wind", &"storm", &"temperature"]
## An anomaly's hidden term this deep where you stand is its heart.
const HEART := 0.99

var health := FULL
var dead := false
## The dev console's god: nothing harms you.
var god := false
## Health a second each harm takes where you stand now, and all each has taken.
var harms := {&"wind": 0.0, &"storm": 0.0, &"temperature": 0.0}
var taken := {&"wind": 0.0, &"storm": 0.0, &"temperature": 0.0}
## What you've drunk, L, and eaten, kcal.
var drunk := 0.0
var eaten := 0.0
## Stood in an anomaly's heart, and not yet out of it.
var in_heart := false

## What a wreck's hazards left you with (Wounds).
var wounds: Wounds
## Rested, Fed and Hydrated, and how long each has left.
var buffs := Buffs.new()

var _player: Player
var _next := 0.0


func _ready() -> void:
	_player = get_parent() as Player
	# After power, which fills canisters, and wear; before the world moves the clock on.
	process_physics_priority = 170
	var bars := Bars.new()
	bars.vitals = self
	add_child(bars)
	wounds = Wounds.new()
	add_child(wounds)


## Whole, unprepared and counting afresh; what you carry stays.
func fresh() -> void:
	health = FULL
	buffs.clear()
	dead = false
	drunk = 0.0
	eaten = 0.0
	for harm in HARMS:
		taken[harm] = 0.0


## Health a second each harm takes at a place, now or at world time t: the
## storm's scouring, wind past what you can stand, and temperature past the
## suit's limits, an anomaly's as it really is. Nothing touches you flying,
## which is only for looking.
func harms_at(at: Vector3, t := NAN) -> Dictionary:
	var tuning := _player.world.tuning
	var weather := _player.world.weather
	if _player.flying:
		return {&"wind": 0.0, &"storm": 0.0, &"temperature": 0.0}
	var felt := weather.felt_temperature(at, t)
	var hidden := weather.hidden(at, t)
	return {
		&"wind": maxf(weather.felt_wind(at, t).length() - tuning.wind_hurts_from, 0.0) * tuning.wind_harm * hidden.y,
		&"storm": weather.felt_storm(at, t) * tuning.storm_harm * hidden.x,
		&"temperature": (maxf(felt - tuning.suit_hot, 0.0) + maxf(tuning.suit_cold - felt, 0.0))
			* tuning.temperature_harm,
	}


## Health taken at once, by a wound: at none you die.
func hurt(amount: float) -> void:
	if dead:
		return
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		dead = true
		died.emit()


## Drinks or eats a portion from a supply, for its buff; returns how much it gave.
func take_in(supply: Supply) -> float:
	var got := buffs.take(supply)
	if supply.kind == &"water":
		drunk += got
		return got
	eaten += got
	if supply.amount <= 0.0:
		_player.suit.discard(supply)
	return got


func _physics_process(_delta: float) -> void:
	var world := _player.world
	if world == null:
		return
	var step := world.tuning.power_tick
	# A jump in time (a scenario) isn't lived through.
	if world.time < _next - step or world.time - _next > 60.0:
		_next = world.time
	# Sat or lying still on support: not crawling, sliding or in the air.
	var at_rest := _player.mode in ["sit", "prone"]
	while not dead and _next + step <= world.time + 1e-9:
		_tick(step, _next, at_rest)
		_next += step
	harms = harms_at(_player.global_position)
	_report()


## One tick lived by a sleep, which steps the clock itself (Sleep): asleep
## is resting, while nothing harms you.
func live(seconds: float, t: float) -> void:
	if not dead:
		_tick(seconds, t, true)
	_next = t + seconds


func _tick(seconds: float, t: float, at_rest: bool) -> void:
	if god:
		health = FULL
		buffs.live(seconds, at_rest)
		return
	var tuning := _player.world.tuning
	var day := tuning.day_minutes * 60.0
	var at := _player.global_position
	var loss := 0.0
	var now := harms_at(at, t)
	for harm: StringName in HARMS:
		loss += now[harm] * seconds
		taken[harm] += now[harm] * seconds
	# A rest is only safe while no harm reaches you.
	buffs.live(seconds, at_rest and loss == 0.0)
	loss += wounds.loss(seconds)
	if loss == 0.0:
		health = minf(health + FULL / (tuning.heal_days * day) * seconds, FULL)
	health = maxf(health - loss, 0.0)
	if health <= 0.0:
		dead = true
		in_heart = false
		died.emit()
	_heart(at, t)


## Into an anomaly's heart where you stand, and out of it alive.
func _heart(at: Vector3, t: float) -> void:
	var world := _player.world
	if not in_heart and not Deeds.waiting(world, &"anomaly_eye"):
		return
	var deep := world.weather.anomaly(at, t)
	if deep >= HEART:
		in_heart = true
	elif deep <= 0.0 and in_heart and not dead:
		in_heart = false
		Deeds.done(world, &"anomaly_eye")


func _report() -> void:
	var tuning := _player.world.tuning
	var making := 0.0
	var made := 0.0
	for node in _player.world.content.get_children():
		if node is Condenser:
			making += node.making()
			made += node.made_l
	Dev.put("survival/hp", "%.1f" % health)
	Dev.put("survival/buffs", "r%.0f f%.0f h%.0f rest%.0f s" % [buffs.rested, buffs.fed, buffs.hydrated, buffs.resting])
	Dev.put("survival/harm", "w%.2f s%.2f t%.2f/s" % [harms.wind, harms.storm, harms.temperature])
	Dev.put("survival/taken", "w%.1f s%.1f t%.1f" % [taken.wind, taken.storm, taken.temperature])
	Dev.put("survival/carried", "%.2fL %dkcal" % [_player.suit.stock(&"water"), _player.suit.stock(&"food")])
	Dev.put("survival/had", "%.2fL %dkcal" % [drunk, eaten])
	Dev.put("survival/cond", "%.1fL/h %.2fL" % [making, made])
	Dev.put("survival/suit", Suit.BUILT_IN if not dead else "dead")
	Dev.put("survival/limits", "%d..%d°C" % [tuning.suit_cold, tuning.suit_hot])
