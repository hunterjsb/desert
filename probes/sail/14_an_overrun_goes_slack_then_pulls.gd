extends SailProbe
## Sailing probe 14: an overrun goes slack, then pulls firmly, and no line
## ever pulls past its strength. On the Varran rig running in a steady 10 m/s,
## forward held in a clear passing lane: the motor can run past it on slack
## lines, which come taut again at no more than their strength, still riding.
## Forced away along a bow line at 12 m/s relative to the rig, it either holds, never
## pulling past its strength, or parts.

const WIND := 10.0

var _lines: Array[Line] = []


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	speed_up(4)
	var way := heading(1, -60.0)
	# Racing past the deck's boom is a real crash, not a rope catapult.
	# Lay the lines from an outboard lane before either end begins moving.
	_lines = await varran(way, 1, 2.0)
	blow(downwind * WIND)
	tending = deg_to_rad(15.0)
	var seen := {"t": 0, "slack": 0, "peak": 0.0, "past": 0, "parted": 0,
		"was_slack": false, "retension": 0, "thrown": ""}
	var watch := func() -> void:
		player.rotation.y = atan2(-way.x, -way.y)
		_steer()
		seen.t += 1
		if player.tumble != null and seen.thrown == "":
			seen.thrown = player.tumble.how
			var hit := player.get_last_slide_collision()
			var collider := hit.get_collider() as Node if hit != null else null
			print("came off: %s at %.2f m/s, collider %s" % [player.tumble.how, player.tumble.thrown_with,
				collider.get_meta(&"catalog", collider.name) if is_instance_valid(collider) else "none"])
		if seen.t == 120:
			Input.action_press("move_forward", 1.0)
		var taut := false
		for line in _lines:
			if not is_instance_valid(line) or line.rope == null or not ropes.ropes.has(line.rope):
				continue
			seen.peak = maxf(seen.peak, line.rope.tension)
			seen.past += int(line.rope.tension > line.rope.breaking + 0.5)
			taut = taut or line.rope.is_taut()
		seen.slack += int(not taut and seen.t > 120)
		if seen.t > 120:
			seen.retension += int(taut and seen.was_slack)
			seen.was_slack = not taut
	await simulate(30.0, watch)
	Input.action_release("move_forward")
	print("held forward on a run: slack %.1f s, the lines' peak %d N of their %d N, %s" % [seen.slack / 60.0,
		roundi(seen.peak), roundi(world.tuning.rope_breaking), "still riding" if player.board != null else "thrown"])
	check(seen.slack > 30, "its lines went slack (%.1f s)" % (seen.slack / 60.0))
	check(seen.retension > 0, "a slack line actually took the strain again")
	check(seen.peak <= world.tuning.rope_breaking + 0.5 and seen.past == 0 and player.board != null,
		"then pulled again without exceeding their strength (%d N), you still on the board" % roundi(seen.peak))
	if player.ride == null:
		return

	# Head out along a real bow line: a fixed downwind shove can instead
	# close the gap after the powered run, testing slack rather than overload.
	var forced: Rope = _lines[0].rope
	var radial := player.global_position - forced.a.global_position
	var away := Vector2(radial.x, radial.z).normalized()
	var held := {"past": 0, "peak": 0.0, "bow": 0.0}
	ropes.snapped.connect(func(_rope: Rope) -> void: seen.parted += 1)
	player.ride.velocity = Vector2(deck.linear_velocity.x, deck.linear_velocity.z) + away * 12.0
	var facing := player.ride.velocity.normalized()
	await simulate(4.0, func() -> void:
		player.rotation.y = atan2(-facing.x, -facing.y)
		for line in _lines:
			if is_instance_valid(line) and line.rope != null and ropes.ropes.has(line.rope):
				held.peak = maxf(held.peak, line.rope.tension)
				if line.rope == forced:
					held.bow = maxf(held.bow, line.rope.tension)
				held.past += int(line.rope.tension > line.rope.breaking + 0.5))
	print("drawn away along its bow line at 12 m/s: bow peak %d N, all lines' peak %d N, %d parted" % [
		roundi(held.bow), roundi(held.peak), seen.parted])
	check(held.past == 0, "a line asked past its strength never pulls past it: it holds or it parts (%d N)" % roundi(held.peak))
	check(held.bow > forced.breaking * 0.9, "the forced overrun reaches the rope's limiting load")
	speed_up(1)
