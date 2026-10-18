extends SailProbe
## Sailing probe 5: a raised sail in a storm tears; a furled one doesn't.
## Moored to a stake in a 24 m/s storm wind gusting a third either way, a
## camp with its sail raised loses it to rags within half a minute, or its
## mast; the same camp with its sail furled comes through whole. In a 30 m/s
## blast a raised sail snaps its mast.


func run() -> void:
	await load_sailing()
	speed_up(4)
	var full: float = Catalog.PARTS[&"sail"].stats.sail_m2
	var left := {}
	for up: bool in [true, false]:
		rig(open, heading())
		moor()
		blow(downwind * 24.0, 0.33)
		if up:
			hoist(45.0)
		await sail_for(30.0)
		left[up] = [mast.sail_m2(), mast.wrecked()]
		print("raised" if up else "furled", ": %.1f of %.1f m² left, mast %s" % [mast.sail_m2(), full, "snapped" if mast.wrecked() else "whole"])
		deck.free()
		follow(open)
		await settle(true)
	check(left[true][0] <= 0.0 or left[true][1], "raised in a storm, the sail tears or the mast snaps")
	check(is_equal_approx(left[false][0], full) and not left[false][1], "furled, it comes through whole")
	rig(open, heading())
	moor()
	blow(downwind * 30.0)
	hoist(45.0)
	await sail_for(4.0)
	check(mast.wrecked(), "in a 30 m/s blast the mast snaps")
	speed_up(1)
