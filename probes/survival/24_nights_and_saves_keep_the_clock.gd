extends SavesProbe
## Survival probe 24: saves and nights keep the buffs' clocks, and fill
## nothing. Fed, given a drink and sat a third of the way into a rest, a save
## resumes each buff's time left and the rest so far as the world clock
## left them, still sat and no more rested: loading a posture grants
## nothing. Sat on for less than a whole rest, the saved part completes it.
## Asleep on safe ground for longer than the drink lasts, the night runs the
## meal down by the time slept and the drink out, and you wake rested; what
## you carry is as it was, nothing eaten, drunk or refilled.

const HOURS := 16


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_storm(0.0)
	var tuning := world.tuning
	var player := world.player
	player.set_physics_process(true)
	await live(2.0, 1.0)
	var ration := Catalog.part(&"ration") as Supply
	var canister := Catalog.part(&"canister") as Supply
	player.suit.carried.append_array([ration, canister])
	check(ration.use(player, Vector3.ZERO) and canister.use(player, Vector3.ZERO), "a meal and a drink")
	check(player.posture.toggle(&"sit"), "you sit down")
	await live(tuning.rest_seconds / 3.0, 1.0)
	var was := _buffs(player)
	var at := world.time
	check(was.resting > 0.0 and not player.vitals.buffs.active(&"rested") and saves.save(world),
		"saved partway into a rest (%.1f s)" % was.resting)

	check(await resume(), "the save resumes")
	player = world.player
	var buffs := player.vitals.buffs
	var now := _buffs(player)
	var since := world.time - at
	print("saved %s at %.2f; resumed %s, %.2f s on" % [was, at, now, since])
	var off := absf(was.fed - now.fed - since) + absf(was.hydrated - now.hydrated - since) \
		+ absf(now.resting - was.resting - since)
	check(off < 3.0 * tuning.power_tick + 1e-6 and since < tuning.rest_seconds - was.resting,
		"each buff's time left and the rest so far as the clock left them (%.3f s off)" % off)
	check(player.ground_pose == &"sit" and not buffs.active(&"rested"), "still sat, and no more rested")
	await live(tuning.rest_seconds - was.resting - since + 2.0 * tuning.power_tick, 1.0)
	check(buffs.active(&"rested"), "sat on, the saved part of the rest completes it")

	var food := player.suit.stock(&"food")
	var water := player.suit.stock(&"water")
	var had := [player.vitals.eaten, player.vitals.drunk]
	var fed := buffs.fed
	world.time_warp = 0.0
	check(world.sleep.refusal() == "", "you can sleep (%s)" % world.sleep.refusal())
	var from := world.time
	await world.sleep.fall_asleep(Sleep.HOURS, HOURS)
	var slept := world.time - from
	print("slept %.0f s: fed %.0f to %.0f, hydrated %.0f, rested %.0f; %.0f kcal and %.2f L carried"
		% [slept, fed, buffs.fed, buffs.hydrated, buffs.rested, player.suit.stock(&"food"), player.suit.stock(&"water")])
	check(slept > now.hydrated and absf(fed - buffs.fed - slept) < 1e-3 and buffs.hydrated == 0.0,
		"the night ran the meal down by the time slept, and the drink out")
	check(buffs.rested > Buffs.lasts(&"rested") - tuning.power_tick, "you wake rested")
	check(player.suit.stock(&"food") == food and player.suit.stock(&"water") == water
		and [player.vitals.eaten, player.vitals.drunk] == had, "nothing eaten, drunk or refilled")


func _buffs(player: Player) -> Dictionary:
	var buffs := player.vitals.buffs
	return {"fed": buffs.fed, "hydrated": buffs.hydrated, "resting": buffs.resting}
