extends BoardTowProbe
## Sailing probe 17: a heavy grounded deck stalls and grounds the board's
## hover. It sputters while the rider keeps trying, then recovers when eased.


func run() -> void:
	await load_towing(true)
	var player := world.player
	var start := cargo.global_position
	var seen := {"hot": 0.0, "low": INF, "off": 0, "on": 0}
	await simulate(8.0, func() -> void:
		seen.hot = maxf(seen.hot, player.ride.overload)
		seen.low = minf(seen.low, player.global_position.y - world.height_under(player.global_position))
		seen.off += int(player.ride.motor_pulse < 0.1)
		seen.on += int(player.ride.overload > 0.9 and player.ride.motor_pulse > 0.9))
	var hot: float = player.ride.overload
	print("heavy %.1f kg: heat %.2f, feet %.3f m above sand, %d off/%d on ticks, cargo moved %.2f m" % [
		cargo.mass, seen.hot, seen.low, seen.off, seen.on, flat(cargo.global_position - start).length()])
	check(seen.hot > 0.9 and seen.low < 0.2 and seen.off > 10 and seen.on > 10,
		"the heavy load grounds the hover and makes its motor sputter")
	Input.action_release("move_forward")
	await simulate(2.0)
	check(player.ride.overload < 0.05 and hot > player.ride.overload,
		"easing the motor lets its hover recover")
