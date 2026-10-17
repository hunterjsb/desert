extends CampProbe
## Power probe 4: the AFK promise. The reference camp parked at mid-latitude,
## on its floating deck, is left alone for two days and nights of the run's
## own weather, storms and all, and no device in it goes dark: the deck keeps
## floating, the shield stands every tick, the turbine stays out in the wind
## making power, and the bank never falls to the shield's reserve. A camp
## underbuilt beside it, the kit's power under a found shield, goes dark in
## the same weather.
## Time limit: 600 s

const LATITUDE := 45.0
## On the third day the storm's wear wrecks the turbine (Power, "As built").
const DAYS := 2.0
## The underbuilt camp stands this far across the wind, m, its shield and
## its crate this far right and ahead of you there.
const APART := 40.0
const WEAK_SHIELD := [0.0, 2.0]
const WEAK_CRATE := [0.0, -2.0]


func run() -> void:
	await load_camp(LATITUDE)
	var devices: Array[Device] = []
	for body in camp:
		if body is Device and not body is Stake:
			devices.append(body)
			devices.append_array((body as Device).mounted())
	# Its bank starts full.
	var room := world.power.pool_wh(shield)
	var weak := await _underbuilt()
	var day := world.tuning.day_minutes * 60.0
	var seen := {"dark": 0, "low": INF, "turbine_wh": 0.0, "weak_dark": -1.0, "t": world.time,
		"hour": world.weather.day.time_of_day(world.time, world.moon.longitude)}
	var days: Array[Dictionary] = []
	await idle(DAYS, func() -> void:
		var t := world.time
		var step: float = t - seen.t
		seen.t = t
		var n := mini(floori(t / day), roundi(DAYS) - 1)
		if days.size() <= n:
			days.append({"storm_s": 0.0, "low": INF, "dawn": -1.0})
		var share := world.power.pool_wh(shield) / room
		seen.dark += int(not shield.running() or devices.any(func(d: Device) -> bool: return not d.powered or d.wrecked()))
		seen.low = minf(seen.low, share)
		# What the turbine makes counts only while its cable keeps it in the camp's pool.
		if world.power.pool_wh(turbine) == world.power.pool_wh(shield):
			seen.turbine_wh += turbine.production_w() * step / 3600.0
		if world.weather.field_storm(shield.global_position) >= 1.0:
			days[n].storm_s += step
			days[n].low = minf(days[n].low, share)
		var hour := world.weather.day.time_of_day(t, world.moon.longitude)
		if seen.hour < 0.25 and hour >= 0.25:
			days[n].dawn = share
		seen.hour = hour
		if seen.weak_dark < 0.0 and not weak.running():
			seen.weak_dark = t / day)
	for n in days.size():
		print("day %d: %.0f min of full storm, lowest %.1f%% in it, %.1f%% at dawn"
			% [n + 1, days[n].storm_s / 60.0, days[n].low * 100.0, days[n].dawn * 100.0])
	print("the turbine made %.1f Wh, %.0f%% worn; lowest %.1f%% of %.0f Wh; the underbuilt camp went dark at %.2f days"
		% [seen.turbine_wh, (1.0 - turbine.durability) * 100.0, seen.low * 100.0, room, seen.weak_dark])
	check(seen.dark == 0, "no device in the camp went dark in %d days and nights (%d ticks)" % [DAYS, seen.dark])
	check(seen.low > Power.RESERVE, "the bank never fell to the shield's reserve (lowest %.1f%%)" % (seen.low * 100.0))
	check(seen.turbine_wh > 40.0, "the turbine stayed out in the wind on its cable, making power for the camp (%.1f Wh)"
		% seen.turbine_wh)
	check(seen.weak_dark >= 0.0, "the underbuilt camp went dark in the same weather")


## The kit's power under a found shield, across the wind: the shield on one
## battery, as charged as the kit's, cabled to the light panel on a crate
## resting beside it.
func _underbuilt() -> ShieldGenerator:
	var player := world.player
	var home := player.global_transform
	world.teleport(player, home.translated(player.global_basis.x * APART))
	var made := Scenarios.standing(world, &"shield", [&"battery"], WEAK_SHIELD) as ShieldGenerator
	made.battery().charge_wh = made.battery().capacity() * Kit.standard().charge
	var holder := Scenarios.standing(world, &"crate_frame", [&"hover_tray"], WEAK_CRATE)
	holder.resting = true
	holder.lift_share = 0.0
	var panel := Catalog.device(&"light_panel")
	holder.mount(panel, holder.sockets().filter(func(s: Socket) -> bool: return s.kind == &"top")[0])
	Scenarios.wire(world, panel, made)
	made.stand(true)
	world.teleport(player, home)
	await physics_frames(2)
	return made
