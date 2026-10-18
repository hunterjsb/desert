extends MovementProbe
## Movement probe 6: frame-rate proof on the board. The same ride at 30, 60
## and 120 physics ticks a second follows the same path and leaves the same
## charge and stamina: kick off, push, carve left, hop, drift right, coast,
## a dug carve left, a hockey stop, and the stop is as long at every rate.
## Then the same ride at 60 with the drawing switched off, the view's
## smoothing between ticks and the board's with it: they're only looks, so
## the path is identical.

const RATES := [30, 60, 120]
## A few millimetres apart at most, over a ride of about 100 m.
const SAME_PLACE := 0.005
const SAME_CHARGE := 1e-6
const ROUTE := [[0.0, ["sprint"]], [1.0, ["move_forward", "sprint"]], [2.0, ["move_forward", "move_left"]],
	[3.5, ["move_forward", "jump"]], [3.6, ["move_forward"]], [4.5, ["move_right", "crouch"]], [6.0, []],
	[6.5, ["move_left", "move_back"]], [7.3, ["move_back"]], [9.0, []]]
## The hockey stop starts here, s, and is over by the next key.
const STOPPING := 7.3
const STOPPED := 9.0
const SECONDS := 9.5


func run() -> void:
	await load_moving()
	var x := world.player_world_x()
	var z := world.player_world_z()
	var paths := {}
	var charges := {}
	var stamina := {}
	var stops := {}
	for rate: int in RATES:
		var ridden := await _trace(rate, x, z)
		paths[rate] = ridden[0]
		charges[rate] = ridden[1]
		stamina[rate] = ridden[2]
		stops[rate] = ridden[3]
	for rate: int in [30, 120]:
		var apart := _apart(paths[rate], paths[60])
		print("%d ticks against 60: %.1f m long, at most %.4f m apart; %.6f Wh against %.6f, %.4f stamina against %.4f"
			% [rate, _length(paths[60]), apart, charges[rate], charges[60], stamina[rate], stamina[60]])
		check(apart < SAME_PLACE, "the ride at %d ticks follows the path at 60 (%.4f m apart)" % [rate, apart])
		check(absf(charges[rate] - charges[60]) < SAME_CHARGE, "and leaves the same charge (%.6f Wh apart)"
			% absf(charges[rate] - charges[60]))
		check(absf(stamina[rate] - stamina[60]) < SAME_CHARGE, "and the same stamina (%.6f apart)"
			% absf(stamina[rate] - stamina[60]))
		print("the hockey stop at %d ticks: %.4f m, at 60 %.4f m" % [rate, stops[rate], stops[60]])
		check(absf(stops[rate] - stops[60]) < SAME_PLACE, "and stops in the same distance (%.4f m apart)"
			% absf(stops[rate] - stops[60]))
	player.feel.set_process(false)
	var undrawn := await _trace(60, x, z, false)
	player.feel.set_process(true)
	var apart := _apart(undrawn[0], paths[60])
	print("at 60 without the drawing: %.6f m apart" % apart)
	check(apart < 1e-6, "drawing never changes the path (%.6f m)" % apart)
	set_rate(60)


## The route from rest on a board at your feet, your feet sampled 30 times a
## simulated second: [path, charge left, stamina left after kicking, how far
## the hockey stop went]. It kicks, drifts and digs in.
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
	var seen := {"drifted": false, "stamina": 0.0, "dug": 0.0, "from": Vector3.ZERO, "stop": INF}
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
		seen.dug = maxf(seen.dug, player.ride.dig)
		# Done kicking, before it gets its breath back.
		if at.tick == 2 * rate:
			seen.stamina = player.stamina
		if at.tick == roundi(STOPPING * rate):
			seen.from = where()
		if at.tick == roundi(STOPPED * rate) and flat_speed() < 0.1:
			seen.stop = Vector2(where().x - seen.from.x, where().z - seen.from.z).length()
		if at.tick % every == 0:
			path.append(where()))
	check(player.ride.kicks > 0 and seen.drifted and seen.dug > 0.9 and seen.stop < INF,
		"it kicked (%d times), drifted, dug in and stopped" % player.ride.kicks)
	hold([])
	# Off the board, the power ticks catch up with what the ride drew.
	player.step_off()
	await simulate(0.5)
	return [path, board.battery().charge_wh, seen.stamina, seen.stop]


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
