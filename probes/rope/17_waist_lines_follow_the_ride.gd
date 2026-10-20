extends SailProbe
## Rope & tethering probe 17: looking down while riding, a waist line stays
## at the same place beside the interpolated board throughout every frame.


func run() -> void:
	await load_sailing()
	var lines := await varran(heading())
	var player := world.player
	player.ride.last_step = Vector3(0.3, 0.03, 0.1)
	var worst := 0.0
	var changed := 0.0
	for line in lines:
		var rope := line.rope
		var before := rope.strand.points.duplicate()
		for fraction: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var a := ropes._shown_end(rope.a, fraction)
			var b := ropes._shown_end(rope.b, fraction)
			rope.strand.pin_ends(a, b, fraction)
			var shown := rope.strand.shown()
			var near := shown[-1]
			var board_at := player.global_position - player.ride.last_step * (1.0 - fraction)
			var waist_at := rope.b.global_position - player.global_position
			worst = maxf(worst, (near - board_at).distance_to(waist_at))
			for i in before.size():
				changed = maxf(changed, before[i].distance_to(rope.strand.points[i]))
	print("waist line relative to displayed rider: %.6f m drift; simulation moved %.6f m" % [worst, changed])
	check(worst < 0.001 and changed == 0.0, "the line follows the displayed rider without moving the simulation")
