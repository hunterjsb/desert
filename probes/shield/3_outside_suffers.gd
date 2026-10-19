extends ShieldProbe
## Bubble shield probe 3: the same camp outside, in the same storm, wears
## down steadily and is wrecked in the time the tuning promises: a full storm
## wrecks a device in storm_wreck_minutes, its tough turbine in that times its
## toughness. Wrecked, it's dark for good: the floating chassis drops and
## nothing makes power. Wind wears on its own, but only past what a device can
## stand: out on open sand, just under wind_harm_speed nothing wears, and
## 10 m/s past it a staked chassis is wrecked in wind_wreck_minutes.

## How close a wreck must come to its promised time, s of world time.
const SLACK := 2.0


func run() -> void:
	await load_storm(1.0)
	var tuning := Tuning.current()
	var camp := camp_at(ahead(6.0))
	var generator := shield_at(ahead(-6.0), false)
	var everything := camp.duplicate()
	everything.append(generator)
	# Out in it from the moment it's set down.
	var start := world.time
	await physics_frames(120)
	var floater: Device = camp[0]
	var floated := clearance(floater)
	var wrecked_at := {}
	var halfway := {}
	var life := tuning.storm_wreck_minutes * 60.0
	var toughest: float = everything.map(func(d: Device) -> float: return d.frame_stats.get("toughness", 1.0)).max()
	await live(life * toughest + 60.0, 30.0, _watch.bind(everything, start, life, wrecked_at, halfway))
	await physics_frames(120)
	var late := PackedStringArray()
	for device in everything:
		var promised: float = life * device.frame_stats.get("toughness", 1.0)
		var when: float = wrecked_at.get(device, INF)
		print("%s: half %.3f at %.0f s, wrecked at %.1f s (promised %.0f)" % [device.label,
			halfway.get(device, -1.0), life * 0.5, when, promised])
		if absf(when - promised) > SLACK:
			late.append("%s %.1f s, not %.0f" % [device.label, when, promised])
	check(late.is_empty(), "each was wrecked in its promised time: %s" % ", ".join(late))
	check(absf(halfway.get(floater, 0.0) - 0.5) < 0.01, "and wore steadily: half gone halfway (%.3f)" % halfway.get(floater, 0.0))
	var dead := func(d: Device) -> bool: return not d.powered and d.production_w() == 0.0 and d.demand_w() == 0.0
	check(everything.all(dead), "wrecked, everything is dark and makes and draws nothing")
	check(floated > 1.0 and clearance(floater) < 0.5, "the floating chassis dropped (%.2f m, was %.2f)" % [clearance(floater), floated])
	generator.interact(world.player)
	check(not generator.running(), "a wrecked shield won't switch on")

	# Wind alone, on a staked chassis: under what it can stand, then past it.
	# Out on open sand, where no dune's lee takes any of it.
	var open := open_sand()
	teleport(open.x + 12.0, open.y)
	await settle(true)
	var staked := Catalog.device(&"chassis")
	world.content.add_child(staked)
	staked.global_position = ahead(-12.0) + Vector3.UP * 0.07
	staked.freeze = true
	weather_everywhere(0.0, tuning.wind_harm_speed - 0.5)
	await live(600.0, 60.0)
	check(staked.durability == 1.0, "wind just under wind_harm_speed wears nothing (%.4f)" % staked.durability)
	weather_everywhere(0.0, tuning.wind_harm_speed + 10.0)
	var at := {}
	await live(tuning.wind_wreck_minutes * 60.0 * 1.2, 60.0, _watch.bind([staked], world.time, INF, at, {}))
	var gone: float = at.get(staked, INF)
	print("wind %.0f m/s wrecked the staked chassis in %.1f s" % [tuning.wind_harm_speed + 10.0, gone])
	check(absf(gone - tuning.wind_wreck_minutes * 60.0) < SLACK,
		"10 m/s past it wrecks a device in wind_wreck_minutes (%.1f s)" % gone)


## Notes when each device is wrecked, and what's left of each halfway through life.
func _watch(devices: Array, start: float, life: float, wrecked_at: Dictionary, halfway: Dictionary) -> void:
	for device: Device in devices:
		if device.wrecked() and not wrecked_at.has(device):
			wrecked_at[device] = world.time - start
		if not halfway.has(device) and world.time - start >= life * 0.5:
			halfway[device] = device.durability
