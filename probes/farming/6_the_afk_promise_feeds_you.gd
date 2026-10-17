extends CampProbe
## Farming probe 6: the AFK promise feeds you. Idle in the reference camp at
## the equator for three days of the run's own weather, with water and
## nothing to eat, you're fed by its farm alone and never go hungry: carrots
## ripen in the clear and fungus in the storm, the harvesters store them and
## sow again, and the planters drop food onto you. At the end the farm is
## still sown, its tanks still hold water, and it has food to spare.
## Time limit: 600 s

const DAYS := 3.0


func run() -> void:
	await load_camp()
	stock_up()
	var vitals := world.player.vitals
	var seen := {"low": vitals.hunger}
	await idle(DAYS, func() -> void: seen.low = minf(seen.low, vitals.hunger))
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
	print("over %d days you ate %.0f kcal; the farm ripened %s units, dropped %.0f kcal and kept %.0f; hunger never below %.0f; %d crops sown, %.2f L in the driest tank"
		% [DAYS, vitals.eaten, ripened, fed, stored, seen.low, sown, water])
	check(vitals.eaten > 0.0 and vitals.eaten <= fed + 1e-6,
		"everything you ate, the farm dropped onto you")
	check(seen.low > world.tuning.eat_below * Vitals.FULL - 5.0, "you never went hungry (%.0f at the lowest)" % seen.low)
	check(ripened.get(&"carrot", 0) > 0 and ripened.get(&"fungus", 0) > 0,
		"carrots ripened in the clear and fungus in the storm")
	check(sown == planters.size() * Scenarios.FARM_CROPS.size() and water > 0.0 and stored > 0.0,
		"the farm is still sown and watered, with food to spare")
