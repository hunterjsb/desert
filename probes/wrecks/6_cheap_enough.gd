extends WreckProbe
## Wreck probe 6: cheap enough. A wreck's scrapping is built a piece at a time
## inside the streaming budget, its looks made while the world loads: every
## kind, built afresh five times, takes no step longer than STEP_MS on the
## main thread, and all of it under WHOLE_MS. A wreck stands still: nothing
## of it costs a tick until it's worked, and a hazard's lamp and a cooling
## kerf are all it does then.
## Runs alone: it times real frames.

const STEP_MS := 1.5
const WHOLE_MS := 5.0
const TRIES := 5


func run() -> void:
	await load_salvage()
	var spot := open_sand()
	var n := 0
	var slowest := 0.0
	var whole := 0.0
	for kind in wreck_kinds():
		var wreck := await wreck_at(kind, spot.x + (n % 5) * 70.0, spot.y + (n / 5) * 70.0)
		n += 1
		if wreck == null:
			continue
		var steps := 0.0
		var all := 0.0
		for k in TRIES:
			var again := Wreckage.new(wreck.site, {}, world.height_at)
			again.transform = wreck.transform
			wreck.get_parent().add_child(again)
			var started := Time.get_ticks_usec()
			var done := false
			while not done:
				var at := Time.get_ticks_usec()
				done = again.build_step()
				steps = maxf(steps, (Time.get_ticks_usec() - at) / 1000.0)
			all = maxf(all, (Time.get_ticks_usec() - started) / 1000.0)
			again.free()
			await get_tree().process_frame
		print("%s: its slowest step %.2f ms, all of it %.2f ms, at most of %d" % [kind, steps, all, TRIES])
		slowest = maxf(slowest, steps)
		whole = maxf(whole, all)
	check(slowest < STEP_MS, "no step of a wreck's building takes %.1f ms (%.2f)" % [STEP_MS, slowest])
	check(whole < WHOLE_MS, "nor all of it %.1f ms (%.2f)" % [WHOLE_MS, whole])
