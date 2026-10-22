extends SailProbe
## Sailing probe 8: furling never tears the sail. Moored in a fresh breeze,
## a raised sail furled on its halyard comes down whole, and hauled up again
## it fills.


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
	# Furled by easing its halyard right out, raised again by hauling it in.
	var halyard := mast.halyard()
	var hauled := halyard.length
	halyard.length = hauled + Mast.LUFF
	halyard.strand.set_length(halyard.length)
	await sail_for(world.tuning.halyard_lower_seconds + 2.0, func() -> void: most.n = maxf(most.n, mast.load_n))
	print("furled: %.1f of %.1f m² left, the most it pulled %.0f N on %.0f N" % [mast.sail_m2(), full, most.n,
		world.tuning.sail_tear_n])
	check(mast.raise < 0.01 and is_equal_approx(mast.sail_m2(), full), "furled in a breeze, the sail comes down whole")
	halyard.length = hauled
	halyard.strand.set_length(halyard.length)
	await sail_for(2.0)
	check(mast.hoisted() and mast.sail_m2() > 0.0, "and hauled up again, it's up")
