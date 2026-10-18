extends SavesProbe
## Survival probe 19: waking jumps cleanly. Asleep for so many hours in the
## run's own weather, under a shield with a planter growing beside you, you
## wake that many hours on: every system that ticks stands on the new hour
## with none to catch up, the forecast reads from it, and the storm pass's
## map was drawn for it while the screen was dark, none drawn in a hitch as
## the world goes on. Saved on waking, the run resumes as it woke.
## Time limit: 300 s

const HOURS := 8
## How close the resumed run keeps to the one that woke: where things stand,
## m, and any number they carry, as a share of it.
const METRES := 0.05
const NUMBER := 0.01


func run() -> void:
	saves = get_node("/root/Saves")
	await load_world(1234, false)
	var here := world.player.global_position
	var shield := Catalog.device(&"shield") as ShieldGenerator
	world.content.add_child(shield)
	shield.global_position = Vector3(here.x - 1.0, world.height_under(here) + 0.22, here.z)
	fit_part(shield, &"big_battery")
	shield.stand(true)
	var planter := Catalog.device(&"planter") as Planter
	world.content.add_child(planter)
	var at := here + Vector3(1.5, 0.0, 1.5)
	planter.global_position = Vector3(at.x, world.height_under(at) + 0.2, at.z)
	for id: StringName in [&"battery", &"root_tuber", &"vat_fungus"]:
		fit_part(planter, id)
	planter.tank_l = world.tuning.planter_tank_litres
	await live(5.0, 1.0)
	world.time_warp = 1.0
	check(world.sleep.refusal() == "", "you can sleep (%s)" % world.sleep.refusal())

	var from := world.time
	var growth := planter.plants()[0].growth
	await world.sleep.fall_asleep(Sleep.HOURS, HOURS)
	var slept := world.time - from
	var hours := world.tuning.day_minutes * 60.0 / 24.0 * HOURS
	print("slept %.1f s of %.0f; %s" % [slept, hours, " / ".join(world.sleep.said)])
	check(absf(slept - hours) < 2.0, "you wake %d hours on" % HOURS)
	check(planter.plants()[0].growth != growth or planter.plants()[0].ripe(), "the crops grew meanwhile")
	var tick := world.tuning.power_tick
	for system: Node in [world.power, world.wear, world.farm, world.player.vitals]:
		var behind: float = world.time - system.get(&"_next")
		check(behind >= -1e-6 and behind <= tick + 1e-6, "%s stands on the new hour (%.2f s behind)" % [system.name, behind])
	var field := world.weather.field
	var x := world.player_world_x()
	var z := world.player_world_z()
	check(absf(world.weather.next_change_time - (world.time + field.next_change(x, z, world.time,
		Weather.FORECAST_HORIZON, Weather.FORECAST_STEP))) < 2.0, "the forecast reads from the new hour")
	var map := world.weather.map
	var drawn := map.rebuilds
	await physics_frames(30)
	check(map.rebuilds == drawn, "no storm map drawn in a hitch as the world goes on")

	var woke := reading()
	check(saves.save(world), "saved on waking")
	check(await resume(), "resumed")
	var back := apart([woke], [reading()])
	check(back.missing == "" and back.metres <= METRES and back.number <= NUMBER,
		"it resumes as it woke (%s; %.3f m %s; %.3f %s)" % [back.missing, back.metres, back.where, back.number, back.which])

