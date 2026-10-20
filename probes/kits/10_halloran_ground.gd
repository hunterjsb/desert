extends Probe
## Halloran's passable spine shares the chunk's ground, at arbitrary rotations
## and in all burial states. The large landmark must not carve outside its apron.
## Time limit: 300 s.

func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var shape := TerrainShape.new(1234, tuning)
	for angle in [0.0, 0.7, 2.4]:
		var site := shape.sites.by_hand(&"halloran_route", 500, 500, angle, 1.0) as HalloranSite
		check(site != null and site.stands(), "the story route cannot disappear on steep dunes")
		for level in [0.0, 1.0, 2.0]:
			site.ground = site.piece.step_of(level)
			var last := -INF
			for x in range(-320, 321, 8):
				var at := site.to_world(Vector2(x, 0))
				var h := site.sand(at.x, at.y, shape.dunes(at.x, at.y))
				check(last == -INF or absf(h - last) / 8.0 < 0.2, "the essential route stays walkable")
				last = h
				var rect := Rect2(at.floor(), Vector2(2, 2))
				var carve := site.carve(site.ground, rect)
				var point := rect.position
				var packed: PackedFloat32Array = carve[0]
				var built := lerpf(packed[0], shape.dunes(point.x, point.y), packed[1])
				check(absf(built - site.sand(point.x, point.y, shape.dunes(point.x, point.y))) < 0.001,
					"chunk and collision height use the same grade")
		var beyond := site.to_world(Vector2(0, 200))
		check(is_equal_approx(site.sand(beyond.x, beyond.y, 17.0), 17.0), "outside the apron remains dune terrain")
		var room := site.to_world(Vector2(-280, 20))
		site.ground = 0
		var buried := site.sand(room.x, room.y, 0)
		site.ground = site.piece.steps
		check(buried - site.sand(room.x, room.y, 0) > 1.0, "storms expose the lower town's floors")
