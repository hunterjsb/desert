extends Probe
## Rope & tethering probe 19: interpolation preserves a slack chain's arc,
## even when its bends change. Drawing moves neither endpoint nor physics.


func run() -> void:
	var strand := RopeStrand.new()
	add_child(strand)
	strand.points = PackedVector3Array([Vector3.ZERO, Vector3(0.25, -0.2, 0.1),
		Vector3(0.5, -0.4, 0.2), Vector3(0.75, -0.2, 0.1), Vector3.RIGHT])
	strand.length = RopeStrand._arc(strand.points)
	strand._fit()
	strand._previous = PackedVector3Array([Vector3.ZERO, Vector3(0.25, -0.1, -0.1),
		Vector3(0.5, -0.2, -0.2), Vector3(0.75, -0.1, -0.1), Vector3.RIGHT])
	var physical := strand.points.duplicate()
	var worst := 0.0
	for fraction: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		strand.pin_ends(Vector3.ZERO, Vector3.RIGHT, fraction)
		var drawn := strand.shown()
		worst = maxf(worst, absf(RopeStrand._arc(drawn) - strand.length) / strand.length)
		check(drawn[0] == Vector3.ZERO and drawn[-1] == Vector3.RIGHT, "both visible rings remain pinned")
	print("interpolated slack arc error %.4f%%; physical points unchanged %s" % [worst * 100.0, strand.points == physical])
	check(worst < 0.01 and strand.points == physical, "the blended rope keeps its arc without changing physics")
	# A grounded middle and displayed rings moved between ticks: the bend
	# correction must keep that sand contact as well as the visible ends.
	for i in strand.points.size():
		strand._ground[i] = -0.4
		strand._slope[i] = Vector2.ZERO
		strand._sampled[i] = Vector2(strand.points[i].x, strand.points[i].z)
		strand._previous[i] = strand.points[i] + Vector3(-0.03, 0.02, -0.02)
	var from := Vector3(-0.05, 0.0, 0.0)
	var to := Vector3(1.0, 0.0, 0.05)
	strand.pin_ends(from, to, 0.5)
	var grounded := strand.shown()
	var lowest := INF
	for point in grounded:
		lowest = minf(lowest, point.y)
	check(grounded[0] == from and grounded[-1] == to and lowest >= -0.4,
		"moving the displayed rings keeps the strand above its ground planes")
	check(absf(RopeStrand._arc(grounded) - strand.length) / strand.length < 0.01 and strand.points == physical,
		"ground contact and changed endpoints preserve the arc without moving physics")
