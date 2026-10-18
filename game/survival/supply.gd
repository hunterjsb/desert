class_name Supply
extends Part
## A sealed container of what you live on: water in a canister, food in a
## ration. Open water boils off by afternoon, so water only lasts sealed. It
## carries what's left in it wherever it goes, as a battery carries its
## charge, and its light shows how full it is. Carried, the suit feeds you
## from it; use one you hold, or one you carry in the inventory, and you drink
## or eat your fill.

## What each kind holds: its stats key for how much it holds, and for what's
## left, and the tuning that says how much a fresh one holds.
const HOLDS := {
	&"water": ["water_l", "water_left_l", &"canister_litres"],
	&"food": ["food_kcal", "food_left_kcal", &"ration_kcal"],
}

var amount := 0.0
var light: MeshInstance3D
## Food in pieces shows what's left by how many: this many when whole, drawn
## by `look`.
var pieces := 0
var look: MeshInstance3D


## Sealed and full, as it's found, or holding `holding` as a harvest does.
func seal(holding := NAN) -> void:
	var holds: Array = HOLDS[kind]
	stats[holds[0]] = Tuning.current().get(holds[2]) if is_nan(holding) else holding
	_keep(capacity())


func capacity() -> float:
	return stats.get(HOLDS[kind][0], 0.0)


## Puts some in, up to full; returns what didn't fit.
func fill(some: float) -> float:
	var taken := minf(some, capacity() - amount)
	_keep(amount + taken)
	return some - taken


## Takes some out, down to empty; returns what it gave.
func drain(some: float) -> float:
	var given := minf(some, amount)
	_keep(amount - given)
	return given


func use(by: Player, _at: Vector3) -> bool:
	return by.vitals.take_in(self) > 0.0


## Kept in its stats too, so a device it's fitted in shows it.
func _keep(now: float) -> void:
	amount = now
	stats[HOLDS[kind][1]] = now
	if light != null:
		ChargeLight.paint(light, amount / maxf(capacity(), 1e-9))
	if look != null and pieces > 0:
		var id: StringName = get_meta(&"catalog")
		var left := clampi(ceili(amount / maxf(capacity(), 1e-9) * pieces), 0, pieces)
		look.mesh = Dress.part(id, Catalog.PARTS[id].size, left)
