extends SailProbe
## Sailing probe 8: furling never tears the sail. Moored in a fresh breeze,
## a raised sail furled comes down whole, and raised again it fills.


func run() -> void:
	await load_sailing()
	speed_up(4)
	var full: float = Catalog.PARTS[&"sail"].stats.sail_m2
	rig(open, heading())
	moor()
	blow(downwind * 10.0)
	hoist(45.0)
	await sail_for(5.0)
	var most := {"n": 0.0}
	mast.raised = false
	await sail_for(Mast.RAISE_SECONDS + 2.0, func() -> void: most.n = maxf(most.n, mast.load_n))
	print("furled: %.1f of %.1f m² left, the most it pulled %.0f N on %.0f N" % [mast.sail_m2(), full, most.n,
		world.tuning.sail_tear_n])
	check(is_equal_approx(mast.sail_m2(), full), "furled in a breeze, the sail comes down whole")
	mast.raised = true
	await sail_for(Mast.RAISE_SECONDS + 2.0)
	check(mast.raise >= 1.0 and mast.sail_m2() > 0.0, "and raised again, it's up")
