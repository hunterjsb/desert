extends ShieldProbe
## Survival probe 23: what you carry goes a portion at a time. Used from the
## inventory, a fresh ration gives a measured meal and Fed for a day; used
## again while fed, it's refused and keeps what it holds. Each time Fed runs
## out, another meal, until the last of it, under a portion, gives Fed for
## that share of the day and the empty ration is gone. A crop is food like
## a ration: refused while fed, a meal once not. A canister goes the same
## way, a drink at a time. Every kcal and litre had came out of what you
## carried: no more and no less, and none of it taken unasked.


func run() -> void:
	await load_storm(0.0)
	var player := world.player
	var suit := player.suit
	var vitals := player.vitals
	var buffs := vitals.buffs
	var tuning := world.tuning
	# The ration and canister you start with, and a crop.
	var ration := suit.supply(&"food")
	var canister := suit.supply(&"water")
	var tubers := Catalog.food(&"tubers", 300.0)
	suit.carried.append(tubers)
	check(ration.amount == tuning.ration_kcal and _stack(ration) != _stack(tubers),
		"a fresh ration of your own, and the crop apart")
	# Mostly drunk, so its last drink is under a portion.
	canister.drain(canister.amount - 0.6)
	var food := suit.stock(&"food")
	var water := suit.stock(&"water")
	await live(5.0, 1.0)
	check(vitals.eaten == 0.0 and vitals.drunk == 0.0 and suit.stock(&"food") == food,
		"nothing eaten or drunk unasked")

	var meals := []
	for supply: Supply in [ration, ration, ration, tubers]:
		var had := supply.amount
		var label := supply.label
		check(await _taken(supply, &"fed"), "a meal from the %s" % label)
		meals.append(had - (supply.amount if is_instance_valid(supply) else 0.0))
	print("meals: %s kcal; eaten %.1f of %.1f" % [meals, vitals.eaten, food])
	check(meals == [tuning.meal_kcal, tuning.meal_kcal, 200.0, 300.0], "a portion at a time, the last of each under one")
	check(not is_instance_valid(ration) or not suit.carried.has(ration), "the empty ration is gone")
	check(absf(vitals.eaten - food) < 1e-6 and suit.stock(&"food") == 0.0, "you ate all you carried, and no more")

	var drinks := []
	for i in 3:
		var had := canister.amount
		check(await _taken(canister, &"hydrated"), "a drink from the canister")
		drinks.append(had - canister.amount)
	print("drinks: %s L; drunk %.2f of %.2f" % [drinks, vitals.drunk, water])
	check(absf(drinks[0] - tuning.drink_litres) + absf(drinks[1] - tuning.drink_litres) + absf(drinks[2] - 0.1) < 1e-6,
		"a drink at a time, the last under one")
	check(absf(vitals.drunk - water) < 1e-6 and suit.carried.has(canister) and canister.amount == 0.0,
		"you drank all it held and kept the canister")


## Uses a supply from the inventory for its buff, which lasts as long as the
## share of a portion it gave; then uses it and each other of its kind again,
## each refused while the buff lasts, and lives on until it's run out. Says
## whether it all went so.
func _taken(supply: Supply, buff: StringName) -> bool:
	var suit := world.player.suit
	var buffs := world.player.vitals.buffs
	var had := supply.amount
	var kind := supply.kind
	var portion := Buffs.portion(kind)
	if buffs.active(buff) or not suit.use(_stack(supply)):
		return false
	var gave := had - (supply.amount if is_instance_valid(supply) else 0.0)
	var share := gave / portion
	var lasting: float = buffs.get(buff)
	var full := absf(lasting - Buffs.lasts(buff) * share) < 1e-6
	var kept := true
	for other in suit.carried.duplicate():
		if other is Supply and other.kind == kind and other.amount > 0.0:
			var left: float = other.amount
			kept = kept and suit.use(_stack(other)) and other.amount == left and buffs.get(buff) == lasting
	await live(lasting + 1.0, 60.0)
	return full and kept and not buffs.active(buff)


func _stack(thing: Object) -> int:
	var stacks := world.player.suit.stacks()
	for i in stacks.size():
		if stacks[i].has(thing):
			return i
	return -1
