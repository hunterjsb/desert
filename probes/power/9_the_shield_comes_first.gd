extends LineProbe
## Power probe 9: the shield comes first. The run's kit crate under clear
## skies, its shield on, its battery just above the reserve: the tray gives
## way at the reserve and the crate settles onto the sand while the shield on
## it keeps running, and the light panel brings the battery back until the
## crate floats again.

const WARP := 120.0
## The most it may take, in days.
const DAYS := 3.5


func run() -> void:
	await load_lines()
	var kit := Runs.kit(world)
	var crate: Device = kit.filter(func(n: Node) -> bool: return n is Device and (n as Device).stats().lift_kg > 0.0)[0]
	var shield: ShieldGenerator = kit.filter(func(n: Node) -> bool: return n is ShieldGenerator)[0]
	var cell := crate.battery()
	var reserve := Power.RESERVE * cell.capacity()
	cell.charge_wh = reserve + 1.0
	await simulate(1.0)
	check(shield.interact(world.player) and crate.stats().hovering, "the shield on, the crate floating")
	var start := world.time
	var seen := {"dark": 0, "rested": -1.0, "rested_wh": 0.0, "rose": -1.0, "rose_wh": 0.0, "low": INF}
	world.time_warp = WARP
	for i in roundi(DAYS * world.tuning.day_minutes * 60.0 / WARP * 60.0):
		await get_tree().physics_frame
		seen.dark += int(not shield.running())
		seen.low = minf(seen.low, cell.charge_wh)
		if seen.rested < 0.0 and not crate.powered:
			seen.rested = world.time - start
			seen.rested_wh = cell.charge_wh
		elif seen.rested >= 0.0 and crate.powered:
			seen.rose = world.time - start
			seen.rose_wh = cell.charge_wh
			break
	world.time_warp = 1.0
	var settled := clearance(crate)
	await simulate(4.0)
	var day := world.tuning.day_minutes * 60.0
	print("the tray gave way at %.2f Wh after %.0f s and the crate settled %.2f m up; the shield ran on, down to %.2f Wh;"
		% [seen.rested_wh, seen.rested, settled, seen.low]
		+ " the panel brought it to %.2f Wh by %.2f days, and the crate floated again %.2f m up"
		% [seen.rose_wh, seen.rose / day, clearance(crate)])
	check(seen.rested >= 0.0 and absf(seen.rested_wh - reserve) < 0.1 and settled < 0.5,
		"running short, the tray gives way at the reserve and the crate settles on the sand")
	check(seen.dark == 0, "the shield on it keeps its power (%d frames dark)" % seen.dark)
	check(seen.rose > seen.rested and seen.rose_wh >= (Power.RESERVE + Power.RESTART) * cell.capacity() - 0.1
		and absf(clearance(crate) - crate.rest_height()) < 0.2,
		"the panel brings the battery back and the crate floats again")
