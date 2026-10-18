extends CampProbe
## Scratch: what each system's step costs over a slept day.
## Time limit: 600 s

func run() -> void:
	await load_camp()
	await live(10.0, 1.0)
	var t := world.time
	var h := 5.0
	var cost := {"power": 0, "wear": 0, "farm": 0, "vitals": 0, "woken": 0, "bear": 0, "drift": 0, "groups": 0}
	var bearings := {}
	for rope in world.ropes.ropes:
		bearings[rope] = world.ropes.bearing(rope)
	var us := Time.get_ticks_usec()
	var groups = world.sleep._groups()
	cost.groups += Time.get_ticks_usec() - us
	print("ropes %d groups %d devices %d content %d" % [world.ropes.ropes.size(), groups.size(), world.devices().size(), world.content.get_child_count()])
	for i in 240:
		us = Time.get_ticks_usec()
		world.sleep._woken(t, INF, null)
		cost.woken += Time.get_ticks_usec() - us
		us = Time.get_ticks_usec()
		world.sleep._bear(t, h, bearings, {})
		cost.bear += Time.get_ticks_usec() - us
		us = Time.get_ticks_usec()
		world.power.live(h, t)
		cost.power += Time.get_ticks_usec() - us
		us = Time.get_ticks_usec()
		world.wear.live(h, t)
		cost.wear += Time.get_ticks_usec() - us
		us = Time.get_ticks_usec()
		world.farm.live(h, t)
		cost.farm += Time.get_ticks_usec() - us
		us = Time.get_ticks_usec()
		world.player.vitals.live(h, t)
		cost.vitals += Time.get_ticks_usec() - us
		us = Time.get_ticks_usec()
		world.sleep._drift(groups, t, h)
		cost.drift += Time.get_ticks_usec() - us
		t += h
	for k in cost:
		print("%s: %.3f ms a step" % [k, cost[k] / 240.0 / 1000.0])
