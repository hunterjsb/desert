extends Probe
## A moving remote support request retires its former ground without player movement.

func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = false
	var shape := TerrainShape.new(1234, tuning)
	var sites := shape.sites
	sites.follow(0, 0, 0.3, 1, 1, 64)
	var anchor := sites.anchor()
	var former: Array[Sites.Unit] = []
	for x in [4000, 8000, 12000]:
		var home := Rect2(x - 64, -64, 128, 128)
		sites.retain(&"home", home, anchor)
		var until := Time.get_ticks_msec() + 10000
		while not sites.ready(home) and Time.get_ticks_msec() < until:
			sites.step(Time.get_ticks_usec() + 1000)
			await get_tree().process_frame
		check(sites.ready(home), "moving home history becomes ready")
		check(not former.any(func(unit: Sites.Unit) -> bool: return sites.units().has(unit)),
			"old remote units retire while the player stays put")
		former.assign(sites.units().filter(func(unit: Sites.Unit) -> bool: return unit.ground.intersects(home)))
	check(sites.follows == 1, "camp scheduling does not follow the player anchor")
	sites.release(&"home")
	check(not former.any(func(unit: Sites.Unit) -> bool: return sites.units().has(unit)),
		"clearing home retires its remote history immediately")
	sites.finish()
