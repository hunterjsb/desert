extends CampProbe
## Survival probe 1: the AFK promise, with a body. You stand idle in the
## reference camp at the equator for three days and nights of the run's own
## weather, storms and all, carrying three canisters of water and nothing to
## eat, and it keeps you alive: the shield keeps the storm off you and the
## farm drops food onto you. Take the farm away and the same you die of
## hunger before the three days are out.
## Time limit: 600 s

## Longer than an empty stomach lasts: hunger runs out in two, and starving
## kills you in under one more.
const DAYS := 3.0


func run() -> void:
	var fed := await _left(true)
	var starved := await _left(false)
	print("with the farm: %s; without it: %s" % [fed, starved])
	check(not fed.dead and fed.low > 90.0, "with the farm you're alive after %d days (health never below %.0f)"
		% [DAYS, fed.low])
	check(fed.harmed < 1e-6, "the shield kept every harm off you (%.3f health)" % fed.harmed)
	check(starved.dead and starved.hunger <= 0.0 and starved.thirst > 0.0 and starved.harmed < 1e-6,
		"without it you starve, at %.2f days" % starved.died)


## You left idle in the camp, with its farm or without: how you came through.
func _left(farm: bool) -> Dictionary:
	if world != null:
		await reload()
	await load_camp()
	if not farm:
		for planter in planters:
			planter.free()
	var vitals := world.player.vitals
	var day := world.tuning.day_minutes * 60.0
	var seen := {"low": vitals.health, "died": -1.0}
	await idle(DAYS, func() -> void:
		seen.low = minf(seen.low, vitals.health)
		if vitals.dead and seen.died < 0.0:
			seen.died = world.time / day)
	var harmed := 0.0
	for harm: StringName in Vitals.HARMS:
		harmed += vitals.taken[harm]
	return {"dead": vitals.dead, "died": seen.died, "low": seen.low, "hunger": vitals.hunger, "thirst": vitals.thirst,
		"harmed": harmed, "water_l": world.player.suit.stock(&"water"), "eaten": vitals.eaten}
