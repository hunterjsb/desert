extends CampProbe
## Farming probe 6: the AFK farm stocks you. Idle in the reference camp at
## the equator for three days of the run's own weather, with water and
## nothing to eat: root-tubers ripen in the clear and vat fungus in the storm,
## the harvesters store them and sow again, and the planters drop food onto
## you, all of it still yours to eat when you choose. At the end the farm is
## still sown, its tanks still hold water, and it has food to spare.
## Time limit: 600 s

const DAYS := 3.0


func run() -> void:
	await load_camp()
	await idle(DAYS)
	var ripened := {}
	var fed := 0.0
	var stored := 0.0
	var sown := 0
	var water := INF
	for planter in planters:
		for crop: StringName in planter.ripened:
			ripened[crop] = ripened.get(crop, 0) + planter.ripened[crop]
		fed += planter.fed_kcal
		stored += planter.stored_kcal()
		sown += planter.plants().size()
		water = minf(water, planter.tank_l)
	var carried := world.player.suit.stock(&"food")
	print("over %d days the farm ripened %s units, dropped %.0f kcal and kept %.0f; you carry %.0f kcal; %d crops sown, %.2f L in the driest tank"
		% [DAYS, ripened, fed, stored, carried, sown, water])
	check(fed > 0.0 and absf(carried - fed) < 1e-6, "the farm dropped food onto you, and you carry all of it")
	check(ripened.get(&"root_tuber", 0) > 0 and ripened.get(&"vat_fungus", 0) > 0,
		"root-tubers ripened in the clear and vat fungus in the storm")
	check(sown == planters.size() * Scenarios.FARM_CROPS.size() and water > 0.0 and stored > 0.0,
		"the farm is still sown and watered, with food to spare")
