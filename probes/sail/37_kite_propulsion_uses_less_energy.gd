extends SailProbe
## Equal loaded routes must spend at least half less motor energy with the kite.
## Time limit: 480 s

const ROUTE_M := 250.0
const CRUISE_MPS := 4.0
const MOTOR_OFF_S := 25.0
const LIMIT_S := 180.0


func run() -> void:
	var motor := await _route(false)
	var kite := await _route(true)
	Input.action_release("move_forward")
	Input.action_release("move_left")
	Input.action_release("move_right")
	check(motor.finished and kite.finished, "both loaded legs finish the same route before running flat")
	check(kite.off_m > 10.0 and kite.off_propulsion < 0.000001 and kite.off_load > 15.0,
		"the loaded kite moves the rider with the motor released and no propulsion electricity")
	check(motor.propulsion > 0.0 and kite.propulsion / kite.km <= motor.propulsion / motor.km * 0.5,
		"kite propulsion Wh/km is at least 50% below the matched motor-only route")


func _route(with_kite: bool) -> Dictionary:
	await load_sailing()
	speed_up(4)
	blow(downwind * 10.0)
	var player := world.player
	player.collision_layer = 1
	player.collision_mask = 1
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-downwind.x, -downwind.y)), open + Vector3.UP * 0.1))
	var payload := Catalog.device(&"chassis") as Chassis
	world.content.add_child(payload)
	fit_part(payload, &"hover_tray")
	fit_part(payload, &"battery")
	payload.battery().charge_wh = payload.battery().capacity()
	fit_part(payload, &"hook")
	payload.global_position = player.global_position - ground(downwind) * 4.0 + Vector3.UP * 0.5
	set_down(payload)
	await physics_frames(60)
	var board := Catalog.device(&"board") as Hoverboard
	world.content.add_child(board)
	fit_part(board, &"battery")
	board.battery().charge_wh = board.battery().capacity()
	board.global_position = player.global_position + Vector3.UP * 0.2
	await physics_frames(ceili(world.tuning.power_tick * 60.0) + 2)
	check(board.powered, "the charged board completes a real power tick before boarding")
	check(player.get_on(board) and player.board == board, "the rider boards the charged board")
	# Boarding safely unties ordinary lines, so attach the payload once aboard.
	Line.to_waist(world, payload.free_tie(player.global_position), 0.3)
	world.time = 0.0
	var kite_line: Line
	if with_kite:
		var kite := Catalog.device(&"salvage_kite") as SalvageKite
		world.content.add_child(kite)
		kite.global_position = player.global_position + Vector3.UP * 1.5
		kite.phase = 0.0
		check(kite.use(player, kite.global_position), "the kite unfolds on its ordinary line")
		kite_line = kite.laid()
	player.set_physics_process(true)
	Input.action_release("move_forward")
	var start := player.global_position
	var initial_wh := board.battery().charge_wh
	payload.battery().charge_wh = payload.battery().capacity()
	var payload_wh := payload.battery().charge_wh
	var result := {"propulsion": 0.0, "hover": 0.0, "equipment": 0.0, "total": 0.0,
		"off_m": 0.0, "off_propulsion": 0.0, "off_load": 0.0, "km": 0.0,
		"finished": false, "cross_m": 0.0, "seconds": 0.0}
	for tick in roundi(LIMIT_S * 60.0):
		await get_tree().physics_frame
		if player.board != board or board.battery().charge_wh <= 0.0:
			break
		var dt := get_physics_process_delta_time()
		var step := Vector2(player.ride.last_step.x, player.ride.last_step.z)
		var offset := Vector2(player.global_position.x - start.x, player.global_position.z - start.z)
		var propulsion := board.propulsion_w() * dt / 3600.0
		var payload_hover: float = payload.stats().hover_w
		var hover := (board.hover_w() + payload_hover) * dt / 3600.0
		var equipment := (maxf(board.demand_w() - board.draw_w() - board.charge_w(), 0.0)
			+ maxf(payload.demand_w() - payload_hover, 0.0)) * dt / 3600.0
		result.propulsion += propulsion
		result.hover += hover
		result.equipment += equipment
		result.total += propulsion + hover + equipment
		result.km += step.length() / 1000.0
		result.seconds += dt
		result.cross_m = maxf(result.cross_m, absf(offset.dot(across)))
		if result.seconds <= MOTOR_OFF_S:
			result.off_m += step.dot(downwind)
			result.off_propulsion += propulsion
			if kite_line != null:
				result.off_load = maxf(result.off_load, kite_line.rope.tension)
		else:
			# Both riders look along the same corridor and steer with ordinary inputs.
			var desired := (downwind - across * clampf(offset.dot(across) / 40.0, -0.25, 0.25)).normalized()
			player.rotation.y = atan2(-desired.x, -desired.y)
			Input.action_release("move_left")
			Input.action_release("move_right")
			if player.ride.velocity.dot(desired) < CRUISE_MPS:
				Input.action_press("move_forward")
			else:
				Input.action_release("move_forward")
				var error := player.ride.ahead.angle_to(desired)
				if absf(error) > 0.015:
					Input.action_press("move_left" if error < 0.0 else "move_right")

		if offset.dot(downwind) >= ROUTE_M:
			result.finished = true
			break
	Input.action_release("move_forward")
	Input.action_release("move_left")
	Input.action_release("move_right")
	var label := "kite" if with_kite else "motor"
	for component: String in ["propulsion", "hover", "equipment", "total"]:
		metric(label + " " + component, float(result[component]) / maxf(result.km, 0.000001), "Wh/km")
	metric(label + " actual distance", result.km * 1000.0, "m")
	metric(label + " travel time", result.seconds, "s", LIMIT_S)
	metric(label + " cross-track distance", result.cross_m, "m", 15.0)
	metric(label + " board initial charge", initial_wh, "Wh")
	metric(label + " board final charge", board.battery().charge_wh, "Wh")
	metric(label + " payload initial charge", payload_wh, "Wh")
	metric(label + " payload final charge", payload.battery().charge_wh, "Wh")
	metric(label + " motor-off distance", result.off_m, "m")
	metric(label + " motor-off propulsion energy", result.off_propulsion, "Wh")
	metric(label + " motor-off propulsion power",
		result.off_propulsion * 3600.0 / maxf(minf(result.seconds, MOTOR_OFF_S), 0.000001), "W")
	metric(label + " motor-off kite load", result.off_load, "N")
	metric(label + " payload mass", payload.mass, "kg")
	check(result.cross_m < 15.0, "%s stays in the same downwind route corridor" % label)
	check(board.battery().charge_wh > 0.0 and board.battery().charge_wh < initial_wh,
		"%s consumes real battery energy and finishes before flat" % label)
	check(payload.battery().charge_wh > 0.0 and payload.battery().charge_wh < payload_wh,
		"%s pays for its payload hover without exhausting its battery" % label)
	var spent := initial_wh - board.battery().charge_wh + payload_wh - payload.battery().charge_wh
	metric(label + " battery reconciliation error", absf(result.total - spent), "Wh", 0.05)
	# The power tick may still owe a fraction of one interval at the finish.
	check(absf(result.total - spent) < 0.05,
		"%s integrated components agree with both real battery withdrawals" % label)
	player.set_physics_process(false)
	var retired := world
	if is_instance_valid(retired):
		retired.queue_free()
	await physics_frames(2)
	check(not is_instance_valid(retired), "the previous route world is freed before the next leg")
	return result
