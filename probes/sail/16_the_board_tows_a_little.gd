extends BoardTowProbe
## Sailing probe 16: the board can crawl with a small load, spending battery
## power on the work against its line. It remains a poor camp hauler.


func run() -> void:
	await load_towing()
	var start := cargo.global_position
	var charge := board.battery().charge_wh
	var seen := {"work": 0.0, "samples": 0, "peak": 0.0}
	await simulate(12.0, func() -> void:
		seen.work += board.tow_work_w
		seen.samples += 1
		seen.peak = maxf(seen.peak, line.rope.tension))
	Input.action_release("move_forward")
	var speed := world.player.ride.velocity.length()
	var gone := flat(cargo.global_position - start).length()
	print("%.1f kg cargo: %.2f m/s, %.2f m moved, %.1f W extra motor draw, %.4f Wh spent, %.0f N peak" % [
		cargo.mass, speed, gone, seen.work / seen.samples, charge - board.battery().charge_wh, seen.peak])
	check(gone > 0.3 and speed < 3.0, "the small load moves at a crawl")
	check(seen.work / seen.samples > 1.0 and board.battery().charge_wh < charge,
		"pulling against the line spends extra battery power")
