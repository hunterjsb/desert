extends SavesProbe
## Survival probe 25: the desert still kills, but going without never does.
## A save from before the buffs, its hidden hunger and thirst run to nothing,
## resumes with no buffs and no supplies made up. Three days on clear, safe
## sand with nothing to eat or drink, you're whole and never harmed; a night
## asleep so, nothing wakes you early. Then a storm with no bubble over you
## takes your health until you die.
## Time limit: 300 s

const DAYS := 3.0
const HOURS := 24


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_storm(0.0)
	var old := Snapshot.take(world)
	old.player.vitals["hunger"] = 0.0
	old.player.vitals["thirst"] = 0.0
	old.player.erase("buffs")
	var food := world.player.suit.stock(&"food")
	var water := world.player.suit.stock(&"water")
	check(SaveFile.write(saves.path(), saves.KIND, saves.VERSION, old) and await resume(),
		"a save from before, starved and parched, resumes")
	var player := world.player
	var vitals := player.vitals
	player.set_physics_process(false)
	check(player.suit.stock(&"food") == food and player.suit.stock(&"water") == water
		and Buffs.ALL.all(func(b: StringName) -> bool: return not vitals.buffs.active(b)),
		"with no buffs, and nothing to eat or drink made up (%.0f kcal, %.2f L)" % [food, water])

	var seen := {"low": vitals.health}
	await live(DAYS * world.tuning.day_minutes * 60.0, 100.0, func() -> void: seen.low = minf(seen.low, vitals.health))
	var harmed := 0.0
	for harm: StringName in Vitals.HARMS:
		harmed += vitals.taken[harm]
	print("%d days unfed and unwatered: health never below %.2f, %.3f taken" % [DAYS, seen.low, harmed])
	check(not vitals.dead and seen.low == Vitals.FULL and harmed == 0.0, "%d days without, whole and unharmed" % DAYS)
	var from := world.time
	await world.sleep.fall_asleep(Sleep.HOURS, HOURS)
	check(world.sleep.last.woke == &"" and world.time - from > HOURS * world.tuning.day_minutes * 60.0 / 24.0 - 1.0
		and vitals.health == Vitals.FULL, "a night asleep without, unwoken (%s)" % world.sleep.last.woke)

	weather_everywhere(1.0)
	await live(10.0, 1.0)
	var stormed := vitals.health
	await live(Vitals.FULL / world.tuning.storm_harm * 1.5, 10.0)
	print("a storm in the open: health %.1f to %.1f, %.1f from the storm" % [stormed, vitals.health, vitals.taken[&"storm"]])
	check(stormed < Vitals.FULL and vitals.dead and vitals.taken[&"storm"] > 0.0, "a storm in the open still kills you")
