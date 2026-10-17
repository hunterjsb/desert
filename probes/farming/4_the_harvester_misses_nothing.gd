extends FarmProbe
## Farming probe 4: the harvester misses nothing. Three planters with
## harvesters, each sown with three carrots and a fungus, grow for four
## clear days held at 20 °C, carrots by day and fungus by night. Everything
## that ripens is either replanted or stored, in the split each is set to,
## and what's stored is still there or was dropped onto you, into your
## slots. Set to replant a quarter, a harvest of four keeps every slot sown
## throughout; set to half, the seed with no free slot is kept for one. Set
## to replant nothing, its slots run out after one harvest each, which proves
## the check can fail.

const DAYS := 4.0
## [split, metres east of you]: the first near enough to drop food onto you.
const FARMS := [[0.25, 2.0], [0.5, 12.0], [0.0, 20.0]]
const CROPS := [&"carrot", &"carrot", &"carrot", &"fungus"]


func run() -> void:
	await load_storm(0.0)
	world.moon.latitude = 0.0
	# The food it drops stays with what you carry: nothing eats it.
	world.player.vitals.set_physics_process(false)
	var planters: Array[Planter] = []
	for farm: Array in FARMS:
		var planter := planter_at(ahead(farm[1]), CROPS, true)
		planter.split = farm[0]
		planters.append(planter)
	hold_temperature(ahead(10.0), 20.0)
	await clock_at(time_of(0.25))
	var ration := world.player.suit.stock(&"food")
	var bare := [0, 0, 0]
	await pass_time(DAYS * 1200.0, func() -> void:
		for i in planters.size():
			planters[i].tank_l = world.tuning.planter_tank_litres
			if planters[i].plants().size() < CROPS.size():
				bare[i] += 1)

	for i in planters.size():
		var planter := planters[i]
		var split: float = FARMS[i][0]
		print("split %.2f: ripened %s, replanted %s, stored %s (%s now), dropped %s, seed kept %s, %d plants"
			% [split, planter.ripened, planter.replanted, planter.banked, planter.stored, planter.dropped,
				planter.seeds, planter.plants().size()])
		for crop: StringName in [&"carrot", &"fungus"]:
			var ripe: int = planter.ripened.get(crop, 0)
			var back: int = planter.replanted.get(crop, 0)
			var kept: int = planter.banked.get(crop, 0)
			var what := "split %.2f, %s" % [split, crop]
			check(ripe > 0 and ripe == back + kept, "%s: all %d that ripened was replanted (%d) or stored (%d)"
				% [what, ripe, back, kept])
			check(absf(back - split * ripe) < 1.0, "%s: replanted in the split (%d of %d)" % [what, back, ripe])
			check(kept == planter.stored.get(crop, 0) + planter.dropped.get(crop, 0),
				"%s: what was stored is still there or was dropped onto you" % what)
			if split > 0.0:
				check(ripe >= 4 * planter.plants()[0].harvest, "%s: harvested again and again (%d)" % [what, ripe])
		if split > 0.0:
			check(bare[i] == 0, "split %.2f: every slot stayed sown (%d times not)" % [split, bare[i]])
	check(planters[1].seeds.get(&"fungus", 0) > 0, "replanting half, the fungus seed with no free slot is kept")
	var none := planters[2]
	check(none.plants().is_empty() and none.ripened.get(&"carrot", 0) == 3 * 4 and none.ripened.get(&"fungus", 0) == 4,
		"replanting nothing, its slots ran out after one harvest each")
	var near := planters[0]
	var food := world.player.suit.stock(&"food") - ration
	check(near.fed_kcal > 0.0 and absf(food - near.fed_kcal) < 1e-6,
		"the near planter dropped %d kcal onto you, all in your slots (%d)" % [near.fed_kcal, food])
	check(planters[1].fed_kcal == 0.0 and planters[2].fed_kcal == 0.0, "farther off, nothing dropped")
