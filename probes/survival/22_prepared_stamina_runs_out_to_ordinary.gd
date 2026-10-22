extends ShieldProbe
## Survival probe 22: prepared, your stamina goes further, until it runs out
## to the ordinary you. Unprepared on clear sand, you win stamina back at the
## base rate, up to the base. Sat still as long as the tuning asks, then
## given a meal and a drink through use, you win it back faster by Rested's
## and Hydrated's shares together, up to Fed's larger stamina, which the meal
## doesn't fill at once. On your feet past when all three run out, you're
## back at the base rate and the base, unharmed: no worse than before.

## Stamina you start each measure from.
const LOW := 40.0


func run() -> void:
	await load_storm(0.0)
	var player := world.player
	var tuning := world.tuning
	var vitals := player.vitals
	var buffs := vitals.buffs
	player.set_physics_process(true)
	await live(2.0, 1.0)
	var base := await _recovery(player)
	print("unprepared: %.2f a second, up to %.1f" % [base.rate, base.full])
	check(absf(base.rate - tuning.stamina_regen) < 0.05 and absf(base.full - tuning.stamina_max) < 1e-6,
		"unprepared, the base rate up to the base")

	check(player.posture.toggle(&"sit"), "you sit down")
	await live(tuning.rest_seconds + 2.0, 10.0)
	check(buffs.active(&"rested"), "sat still %.0f s, you're rested" % buffs.resting)
	check(player.posture.toggle(&"sit") and player.ground_pose == &"stand", "and stand up")
	var ration := Catalog.part(&"ration") as Supply
	var canister := Catalog.part(&"canister") as Supply
	player.suit.carried.append_array([ration, canister])
	player.stamina = LOW
	check(ration.use(player, Vector3.ZERO) and canister.use(player, Vector3.ZERO) and player.stamina == LOW
		and buffs.active(&"fed") and buffs.active(&"hydrated"), "a meal and a drink, and no stamina from them at once")
	var prepared := await _recovery(player)
	var share := 1.0 + tuning.rested_recovery + tuning.hydrated_recovery
	print("prepared: %.2f a second (%.3f of base), up to %.1f" % [prepared.rate, prepared.rate / base.rate, prepared.full])
	check(absf(prepared.rate / base.rate - share) < 0.01, "rested and hydrated, %.2f times as quick" % share)
	check(absf(prepared.full - tuning.stamina_max * (1.0 + tuning.fed_stamina)) < 1e-6,
		"fed, %.0f more stamina" % (tuning.stamina_max * tuning.fed_stamina))

	var health := vitals.health
	await live(Buffs.lasts(&"fed") + 30.0, 60.0)
	var harmed := 0.0
	for harm: StringName in Vitals.HARMS:
		harmed += vitals.taken[harm]
	check(not buffs.active(&"rested") and not buffs.active(&"fed") and not buffs.active(&"hydrated")
		and player.stamina <= tuning.stamina_max, "all three run out, and stamina back within the base")
	var after := await _recovery(player)
	print("run out: %.2f a second, up to %.1f; health %.1f to %.1f, %.3f taken" % [after.rate, after.full, health,
		vitals.health, harmed])
	check(absf(after.rate - base.rate) < 1e-3 and absf(after.full - base.full) < 1e-6
		and vitals.health >= health and harmed == 0.0, "back to the base rate and the base, unharmed")


## Stamina won back stood still from LOW over a second, and where it stops.
func _recovery(player: Player) -> Dictionary:
	player.stamina = LOW
	await live(1.0, 1.0)
	var rate := player.stamina - LOW
	await live(20.0, 1.0)
	return {"rate": rate, "full": player.stamina}
