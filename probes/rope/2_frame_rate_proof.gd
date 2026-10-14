extends RopeProbe
## Rope & tethering probe 2: frame-rate proof. The same rigs in the same steady
## wind, run at 30, 60 and 120 physics ticks a second, come to rest in the same
## places, pulling the same: a floater on one line, one pinned between two, one
## on three, and a lantern-light one, so a rope solved from both ends' masses
## is tested at both extremes of weight.

const RATES := [30, 60, 120]
const SETTLE := 25.0
## A centimetre apart at most, and a percent of the pull.
const SAME_PLACE := 0.01
const SAME_PULL := 0.01


func run() -> void:
	await load_ropes()
	blow(Vector2(18.0, 0.0))
	var rested := {}
	for rate: int in RATES:
		set_rate(rate, 4)
		var bodies := _rigs()
		await simulate(SETTLE)
		rested[rate] = {"at": bodies.map(_world_position),
			"pull": ropes.ropes.map(func(rope: Rope) -> float: return rope.tension)}
		ropes.clear()
		for body: Node3D in world.content.get_children():
			if body is RigidBody3D:
				body.free()
		await simulate(0.2)
	set_rate(60)
	var at_60: Array = rested[60].at
	var pull_60: Array = rested[60].pull
	for rate: int in [30, 120]:
		var moved := 0.0
		for i in at_60.size():
			moved = maxf(moved, (rested[rate].at[i] - at_60[i]).length())
		var pulled := 0.0
		for i in pull_60.size():
			pulled = maxf(pulled, absf(rested[rate].pull[i] - pull_60[i]) / pull_60[i])
		print("%d ticks against 60: rests %.4f m apart, pulls differ by %.3f%%" % [rate, moved, pulled * 100.0])
		check(moved < SAME_PLACE, "at %d ticks everything rests where it does at 60 (%.4f m)" % [rate, moved])
		check(pulled < SAME_PULL, "and each taut line pulls the same (%.3f%%)" % (pulled * 100.0))


## Downwind is +x. Every line is loaded, so every pull can be compared.
func _rigs() -> Array[RigidBody3D]:
	var one := Props.floater(world, spot(6.0, -14.0))
	stake_line(spot(0.0, -14.0), one, 0.5)
	var pinned := Props.floater(world, spot(6.0, -5.0))
	stake_line(spot(3.0, -10.0), pinned, 0.0)
	stake_line(spot(3.0, 0.0), pinned, 0.0)
	var three := Props.floater(world, spot(6.0, 6.0))
	for k in 3:
		stake_line(spot(6.0, 6.0) + Vector3(-5.0, 0.0, 0.0).rotated(Vector3.UP, (k - 1) * 0.5), three, 0.2)
	var lantern := Props.floater(world, spot(5.0, 15.0), 2.0, 0.05, Vector3.ONE * 0.4)
	stake_line(spot(0.0, 15.0), lantern, 0.3)
	return [one, pinned, three, lantern]


func _world_position(body: Node3D) -> Vector3:
	return Vector3(world.world_x(body.global_position.x), body.global_position.y,
		world.world_z(body.global_position.z))
