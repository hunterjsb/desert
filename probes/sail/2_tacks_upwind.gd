extends SailProbe
## Sailing probe 2: no sail goes straight upwind, but it tacks. Pointed into
## a steady 10 m/s wind, the camp makes no ground upwind however its sheet is
## tended; got going across the wind and then steered 60° off it, close-
## hauled, it does, and on the other tack too.


func run() -> void:
	await load_sailing()
	speed_up(4)
	var upwind := {}
	for leg: Array in [[1, 90.0], [1, 30.0], [-1, 30.0]]:
		rig(open, heading(leg[0], leg[1]), &"skates", leg[0])
		blow(downwind * 10.0)
		hoist(30.0)
		tending = deg_to_rad(15.0)
		# From rest close-hauled it barely gets going, as a sailor knows: it
		# builds speed across the wind first, then heads up.
		if leg[1] < 90.0:
			course = heading(leg[0])
			await sail_for(6.0)
		course = heading(leg[0], leg[1])
		var from := deck.global_position
		await sail_for(30.0)
		var gained := -Vector2(deck.global_position.x - from.x, deck.global_position.z - from.z).dot(downwind)
		upwind[leg] = gained
		print("%d° off the wind, on its %s: %.1f m upwind in 30 s, going %.2f m/s" % [
			90 - leg[1], "left" if leg[0] > 0 else "right", gained, way().length()])
		deck.free()
		follow(open)
		await settle(true)
	speed_up(1)
	check(upwind[[1, 90.0]] < 0.5, "straight into the wind it makes no ground (%.1f m)" % upwind[[1, 90.0]])
	check(upwind[[1, 30.0]] > 15.0 and upwind[[-1, 30.0]] > 15.0, "close-hauled it does, on either tack (%.1f m, %.1f m)" % [
		upwind[[1, 30.0]], upwind[[-1, 30.0]]])
