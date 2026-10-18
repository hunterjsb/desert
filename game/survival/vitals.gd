class_name Vitals
extends Node
## You, as the moon wears on you: health, hunger and thirst, out of 100. On
## power's tick of world time, so the frame rate never changes a need and the
## dev time warp runs them with everything else. Hunger and thirst run down
## with time, thirst faster in the heat. The three harms take health through
## the felt weather, so a bubble that blocks one keeps it off you. Running
## low, the suit feeds you from what you carry. Unharmed, fed and watered, you
## heal. At no health you die, and the run is over.

signal died

const FULL := 100.0
const HARMS: Array[StringName] = [&"wind", &"storm", &"temperature"]

var health := FULL
var hunger := FULL
var thirst := FULL
var dead := false
## Health a second each harm takes where you stand now, and all each has taken.
var harms := {&"wind": 0.0, &"storm": 0.0, &"temperature": 0.0}
var taken := {&"wind": 0.0, &"storm": 0.0, &"temperature": 0.0}
## What you've drunk, L, and eaten, kcal.
var drunk := 0.0
var eaten := 0.0

var _player: Player
var _next := 0.0


func _ready() -> void:
	_player = get_parent() as Player
	# After power, which fills canisters, and wear; before the world moves the clock on.
	process_physics_priority = 170
	var bars := Bars.new()
	bars.vitals = self
	add_child(bars)


## Fed, watered and whole, on a fresh suit's kit.
func fresh() -> void:
	health = FULL
	hunger = FULL
	thirst = FULL
	dead = false
	drunk = 0.0
	eaten = 0.0
	for harm in HARMS:
		taken[harm] = 0.0
	_player.suit.restock()


## Health a second each harm takes at a place, now or at world time t: the
## storm's scouring, wind past what you can stand, and temperature past the
## suit's limits. Nothing touches you flying, which is only for looking.
func harms_at(at: Vector3, t := NAN) -> Dictionary:
	var tuning := _player.world.tuning
	var weather := _player.world.weather
	if _player.flying:
		return {&"wind": 0.0, &"storm": 0.0, &"temperature": 0.0}
	var felt := weather.felt_temperature(at, t)
	return {
		&"wind": maxf(weather.felt_wind(at, t).length() - tuning.wind_hurts_from, 0.0) * tuning.wind_harm,
		&"storm": weather.felt_storm(at, t) * tuning.storm_harm,
		&"temperature": (maxf(felt - tuning.suit_hot, 0.0) + maxf(tuning.suit_cold - felt, 0.0))
			* tuning.temperature_harm,
	}


## How many times faster than in the mild the heat makes you thirst, at a
## place, now or at world time t.
func thirsting(at: Vector3, t := NAN) -> float:
	var tuning := _player.world.tuning
	var heat := clampf(inverse_lerp(tuning.thirst_heat_from, tuning.suit_hot,
		_player.world.weather.felt_temperature(at, t)), 0.0, 1.0)
	return lerpf(1.0, tuning.heat_thirst, heat)


## Drinks or eats from a supply up to full; returns how much it gave.
func take_in(supply: Supply) -> float:
	var tuning := _player.world.tuning
	if supply.kind == &"water":
		var got := supply.drain((FULL - thirst) / FULL * tuning.thirst_litres)
		thirst = minf(thirst + got / tuning.thirst_litres * FULL, FULL)
		drunk += got
		return got
	var bite := supply.drain((FULL - hunger) / FULL * tuning.hunger_kcal)
	hunger = minf(hunger + bite / tuning.hunger_kcal * FULL, FULL)
	eaten += bite
	if supply.amount <= 0.0:
		_player.suit.discard(supply)
	return bite


func _physics_process(_delta: float) -> void:
	var world := _player.world
	if world == null:
		return
	var step := world.tuning.power_tick
	# A jump in time (a scenario) isn't lived through.
	if world.time < _next - step or world.time - _next > 60.0:
		_next = world.time
	while not dead and _next + step <= world.time + 1e-9:
		_tick(step, _next)
		_next += step
	harms = harms_at(_player.global_position)
	_report()


## One tick lived by a sleep, which steps the clock itself (Sleep).
func live(seconds: float, t: float) -> void:
	if not dead:
		_tick(seconds, t)
	_next = t + seconds


func _tick(seconds: float, t: float) -> void:
	var tuning := _player.world.tuning
	var day := tuning.day_minutes * 60.0
	var at := _player.global_position
	hunger = maxf(hunger - FULL / (tuning.hunger_days * day) * seconds, 0.0)
	thirst = maxf(thirst - FULL / (tuning.thirst_days * day) * thirsting(at, t) * seconds, 0.0)
	_auto(&"water", thirst, tuning.drink_below)
	_auto(&"food", hunger, tuning.eat_below)
	var loss := 0.0
	var now := harms_at(at, t)
	for harm: StringName in HARMS:
		loss += now[harm] * seconds
		taken[harm] += now[harm] * seconds
	if hunger <= 0.0:
		loss += tuning.starving_harm * seconds
	if thirst <= 0.0:
		loss += tuning.parched_harm * seconds
	if loss == 0.0:
		health = minf(health + FULL / (tuning.heal_days * day) * seconds, FULL)
	health = maxf(health - loss, 0.0)
	if health <= 0.0:
		dead = true
		died.emit()


## Below its mark, the suit tops you up from what you carry, one supply after another.
func _auto(kind: StringName, level: float, below: float) -> void:
	if level >= below * FULL:
		return
	var supply := _player.suit.supply(kind)
	while supply != null and take_in(supply) > 0.0:
		supply = _player.suit.supply(kind)


func _report() -> void:
	var tuning := _player.world.tuning
	var at := _player.global_position
	var making := 0.0
	var made := 0.0
	for node in _player.world.content.get_children():
		if node is Condenser:
			making += node.making()
			made += node.made_l
	Dev.put("survival/hp", "%.1f" % health)
	Dev.put("survival/hunger", "%.1f" % hunger)
	Dev.put("survival/thirst", "%.1f x%.2f" % [thirst, thirsting(at)])
	Dev.put("survival/harm", "w%.2f s%.2f t%.2f/s" % [harms.wind, harms.storm, harms.temperature])
	Dev.put("survival/taken", "w%.1f s%.1f t%.1f" % [taken.wind, taken.storm, taken.temperature])
	Dev.put("survival/carried", "%.2fL %dkcal" % [_player.suit.stock(&"water"), _player.suit.stock(&"food")])
	Dev.put("survival/had", "%.2fL %dkcal" % [drunk, eaten])
	Dev.put("survival/cond", "%.1fL/h %.2fL" % [making, made])
	Dev.put("survival/suit", Suit.BUILT_IN if not dead else "dead")
	Dev.put("survival/limits", "%d..%d°C" % [tuning.suit_cold, tuning.suit_hot])
