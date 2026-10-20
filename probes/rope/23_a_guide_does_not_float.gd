extends LineProbe
## A sharp guide's displayed bend stays on its physical ring.

func run() -> void:
	await load_lines()
	var at := world.player.global_position + Vector3(0, 4, -2)
	var strand := RopeStrand.new()
	world.ropes.add_child(strand)
	var a := RopeEnd.make(world.content, at + Vector3(0, -2, 0), false)
	var b := RopeEnd.make(world.content, at + Vector3(1, -3, 0), false)
	var via := RopeEnd.make(world.content, at, false)
	strand.hang(world, 5.2, a, b)
	strand.through = via
	strand.points = strand._routed(a.global_position, via.global_position, b.global_position)
	strand._show()
	var highest := -INF
	for i in strand.points.size() - 1:
		for step in 9:
			highest = maxf(highest, strand.drawn(i, step / 8.0).y)
	check(highest <= at.y + 0.001, "the drawn tube never loops above the actual pulley")
