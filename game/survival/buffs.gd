class_name Buffs
extends RefCounted
## Setting out prepared (docs/prd/survival.md): a still, safe rest leaves you
## Rested, a meal Fed, a drink Hydrated. Each helps only your stamina, for a
## while, and runs out to the ordinary you: no harm and no debt. You eat and
## drink when you choose, once that one has run out, and less than a portion
## gives it for less long. Lived on the vitals' ticks of world time, a sleep's
## included, so a night runs them down with everything else.

## The three, in the order they show.
const ALL: Array[StringName] = [&"rested", &"fed", &"hydrated"]
## What each kind of supply makes you.
const FROM := {&"food": &"fed", &"water": &"hydrated"}

## World seconds each has left: none at 0.
var rested := 0.0
var fed := 0.0
var hydrated := 0.0
## World seconds of the still, safe rest you're in, toward Rested.
var resting := 0.0


func active(buff: StringName) -> bool:
	return get(buff) > 0.0


## World seconds each lasts, earned in full.
static func lasts(buff: StringName) -> float:
	var tuning := Tuning.current()
	var days: float = {&"rested": tuning.rested_days, &"fed": tuning.fed_days,
		&"hydrated": tuning.hydrated_days}[buff]
	return days * tuning.day_minutes * 60.0


## One measured portion of a kind of supply: kcal of food, L of water.
static func portion(kind: StringName) -> float:
	return Tuning.current().meal_kcal if kind == &"food" else Tuning.current().drink_litres


## Base stamina, times this.
func capacity() -> float:
	return 1.0 + (Tuning.current().fed_stamina if fed > 0.0 else 0.0)


## Base stamina recovery, times this: each bonus adds against the base.
func recovery() -> float:
	var tuning := Tuning.current()
	return 1.0 + (tuning.rested_recovery if rested > 0.0 else 0.0) \
		+ (tuning.hydrated_recovery if hydrated > 0.0 else 0.0)


## Eats or drinks a portion of a supply, or what's left under one, for that
## share of its buff; nothing while that buff lasts. Returns what it took.
func take(supply: Supply) -> float:
	var buff: StringName = FROM[supply.kind]
	if active(buff):
		return 0.0
	var got := supply.drain(portion(supply.kind))
	if got > 0.0:
		set(buff, lasts(buff) * got / portion(supply.kind))
	return got


## So many seconds of world time lived, at rest and safe or not. A rest long
## enough keeps you Rested in full until you get up; the rest runs down.
func live(seconds: float, at_rest: bool) -> void:
	fed = maxf(fed - seconds, 0.0)
	hydrated = maxf(hydrated - seconds, 0.0)
	resting = resting + seconds if at_rest else 0.0
	if resting >= Tuning.current().rest_seconds:
		rested = lasts(&"rested")
	else:
		rested = maxf(rested - seconds, 0.0)


func clear() -> void:
	rested = 0.0
	fed = 0.0
	hydrated = 0.0
	resting = 0.0
