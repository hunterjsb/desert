extends Probe
## Structure kits probe 6: the dune term strips a windward face more than its
## lee. Up a big dune's windward face and down in the lee past its slip face,
## the same three days of weather take more sand off the face than they would
## off open sand, and less off the lee: the term both ways, and the face more
## than the lee. Still pure: read again, the same.

const SEED := 1234
const DAYS := 3.0
const EVERY := 600.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var shape := TerrainShape.new(SEED, tuning)
	var field := WeatherField.new(SEED, tuning)
	var down := shape.downwind()
	var lee := Vector2(NAN, NAN)
	var face := Vector2(NAN, NAN)
	for seed in shape.sites.dunes._cells_near(Vector2.ZERO, 1500.0):
		shape.sites.dunes.locate(seed)
		if seed.site == null:
			continue
		# Up the wind from the ruin, over the crest, halfway down its windward face.
		var at := Vector2(seed.site.x, seed.site.z)
		var top := at
		for k in 120:
			var p := at - down * k * 2.0
			if shape.dunes(p.x, p.y) > shape.dunes(top.x, top.y):
				top = p
		var mid := top - down * seed.crest * 1.5
		if Exposure.dune_at(shape, mid.x, mid.y, tuning) > 0.3:
			lee = at
			face = mid
			break
	check(lee.is_finite(), "a big dune's face and its lee")
	if not lee.is_finite():
		return
	var terms := [Exposure.dune_at(shape, face.x, face.y, tuning), Exposure.dune_at(shape, lee.x, lee.y, tuning)]
	var off := [[0.0, 0.0], [0.0, 0.0]]
	var t := 0.0
	while t < DAYS * 24.0 * 3600.0:
		for k in 2:
			var at: Vector2 = [face, lee][k]
			off[k][0] += Exposure.taken(field, at.x, at.y, t, tuning, null, terms[k])
			off[k][1] += Exposure.taken(field, at.x, at.y, t, tuning)
		t += EVERY
	print("dune term %.2f on the face, %.2f in the lee; sand off over %d days, with it and on open sand: face %.0f / %.0f, lee %.0f / %.0f"
		% [terms[0], terms[1], DAYS, off[0][0], off[0][1], off[1][0], off[1][1]])
	check(off[0][0] > off[0][1] * 1.2, "the face is stripped harder than open sand")
	check(off[1][0] < off[1][1] * 0.8, "the lee is buried harder than open sand")
	check(off[0][0] > off[1][0] * 2.0, "the face gives up more than the lee")
	check(Exposure.dune_at(shape, lee.x, lee.y, tuning) == terms[1], "read again, the same")
