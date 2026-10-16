extends MovementProbe
## Movement probe 6: frame-rate proof on the board. The same ride at 30, 60
## and 120 physics ticks a second follows the same path and leaves the same
## charge and stamina: kick off, push, carve left, hop, drift right, coast,
## brake. Then
## the same ride at 60 with the drawing switched off, the view's smoothing
## between ticks and the board's with it: they're only looks, so the path is
## identical.

const RATES := [30, 60, 120]
## A few millimetres apart at most, over a ride of about 100 m.
const SAME_PLACE := 0.005
const SAME_CHARGE := 1e-6
const ROUTE := [[0.0, ["sprint"]], [1.0, ["move_forward", "sprint"]], [2.0, ["move_forward", "move_left"]],
	[3.5, ["move_forward", "jump"]], [3.6, ["move_forward"]], [4.5, ["move_right", "crouch"]], [6.0, []],
	[7.0, ["move_back"]], [8.0, []]]
const SECONDS := 8.5


func run() -> void:
	await load_moving()
	var x := world.player_world_x()
	var z := world.player_world_z()
	var paths := {}
	var charges := {}
	var stamina := {}
	for rate: int in RATES:
		var ridden := await _trace(rate, x, z)
		paths[rate] = ridden[0]
		charges[rate] = ridden[1]
		stamina[rate] = ridden[2]
	for rate: int in [30, 120]:
		var apart := _apart(paths[rate], paths[60])
		print("%d ticks against 60: %.1f m long, at most %.4f m apart; %.6f Wh against %.6f, %.4f stamina against %.4f"
			% [rate, _length(paths[60]), apart, charges[rate], charges[60], stamina[rate], stamina[60]])
		check(apart < SAME_PLACE, "the ride at %d ticks follows the path at 60 (%.4f m apart)" % [rate, apart])
		check(absf(charges[rate] - charges[60]) < SAME_CHARGE, "and leaves the same charge (%.6f Wh apart)"
			% absf(charges[rate] - charges[60]))
		check(absf(stamina[rate] - stamina[60]) < SAME_CHARGE, "and the same stamina (%.6f apart)"
			% absf(stamina[rate] - stamina[60]))
	player.feel.set_process(false)
	var undrawn := await _trace(60, x, z, false)
	player.feel.set_process(true)
	var apart := _apart(undrawn[0], paths[60])
	print("at 60 without the drawing: %.6f m apart" % apart)
	check(apart < 1e-6, "drawing never changes the path (%.6f m)" % apart)
	set_rate(60)


## The route from rest on a board at your feet, your feet sampled 30 times a
## simulated second: [path, charge left, stamina left after kicking]. It
## kicks and drifts.
func _trace(rate: int, x: float, z: float, drawn := true) -> Array:
	# A new tick rate takes hold a frame late, so it's set before you're placed.
	set_rate(rate, 4)
	player.step_off()
	for node in world.content.get_children():
		if node is Hoverboard:
			node.free()
	await place(x, z, Vector2(0.6, -0.8))
	var board := board_here()
	board.set_process(drawn)
	player.stamina = world.tuning.stamina_max
	check(player.get_on(board), "you step onto the board")
	var path: Array[Vector3] = [where()]
	var at := {"tick": 0, "step": 0}
	var every := rate / 30
	var seen := {"drifted": false, "stamina": 0.0}
	# Keys change between ticks, at the same simulated moment at every rate.
	var press := func() -> void:
		while at.step < ROUTE.size() and at.tick >= roundi(ROUTE[at.step][0] * rate):
			hold(ROUTE[at.step][1])
			at.step += 1
	press.call()
	await ride_for(SECONDS, func() -> void:
		at.tick += 1
		press.call()
		seen.drifted = seen.drifted or player.ride.drifting
		# Done kicking, before it gets its breath back.
		if at.tick == 2 * rate:
			seen.stamina = player.stamina
		if at.tick % every == 0:
			path.append(where()))
	check(player.ride.kicks > 0 and seen.drifted, "it kicked (%d times) and drifted" % player.ride.kicks)
	hold([])
	# Off the board, the power ticks catch up with what the ride drew.
	player.step_off()
	await simulate(0.5)
	return [path, board.battery().charge_wh, seen.stamina]


func _apart(a: Array[Vector3], b: Array[Vector3]) -> float:
	var most := 0.0
	for i in mini(a.size(), b.size()):
		most = maxf(most, a[i].distance_to(b[i]))
	return most if a.size() == b.size() else INF


func _length(path: Array[Vector3]) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
	return total
