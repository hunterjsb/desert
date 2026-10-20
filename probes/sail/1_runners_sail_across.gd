extends SailProbe
## Sailing probe 1: runners sail across the wind. In a steady 10 m/s wind on
## its left, a camp on skates, steered across the wind and its sheet tended,
## sails a beam reach at a lively pace, barely sliding sideways; the same camp
## floating on trays, steered and trimmed the same, only drifts off downwind.


func run() -> void:
	await load_sailing()
	speed_up(4)
	var went := {}
	driving_sheet = true
	for carried: StringName in [&"skates", &"hover_tray"]:
		rig(open, heading(), carried)
		blow(downwind * 10.0)
		hoist(60.0)
		course = heading()
		tending = deg_to_rad(15.0)
		await sail_for(25.0)
		var ahead := -deck.global_basis.z
		var side := Vector2(-ahead.z, ahead.x).normalized()
		went[carried] = Vector3(way().dot(heading()), way().dot(downwind), absf(way().dot(side)))
		print("%s: across the wind %.2f m/s, downwind %.2f m/s, sliding sideways %.2f m/s" % [carried, went[carried].x, went[carried].y, went[carried].z])
		deck.free()
		follow(open)
		await settle(true)
	speed_up(1)
	var runs: Vector3 = went[&"skates"]
	var floats: Vector3 = went[&"hover_tray"]
	check(runs.x > 3.0 and runs.x < 8.0, "on skates it sails across the wind at a lively pace (%.2f m/s)" % runs.x)
	check(runs.z < 0.1 * runs.x, "barely sliding sideways (%.2f m/s)" % runs.z)
	check(floats.y > 2.0 * absf(floats.x), "floating, it drifts downwind instead (%.2f across, %.2f down)" % [floats.x, floats.y])
