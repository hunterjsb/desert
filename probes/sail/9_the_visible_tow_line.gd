extends SailProbe
## Sailing probe 9: an explicit towline carries the following camp's load.
## The rider's independent sheet steers the sailing rig, with no hidden bypass.
## Deliberately moving the towline's rig end to the waist makes opposed loads
## injure the rider normally; reeling the selected sheet leaves that line alone.

## The point of sail, degrees off a beam reach (Scenarios' heading), the
## carve, rad off the rig's way, and how hard the edge digs in.
const OFF := -30.0
const CARVE := deg_to_rad(40.0)
const DIG := 1.0

var kit: Array[Node3D] = []


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	speed_up(4)
	driving_sheet = true
	var turned := {}
	var alone := 0.0
	for carve: Array in [[&"alone", [], 0.0], [&"none", [], 0.0], [&"windward", ["move_left", "move_back"], -CARVE],
			[&"leeward", ["move_right", "move_back"], CARVE]]:
		await _set_up(carve[0] == &"alone")
		var rig: Chassis = _of(Chassis, 0)
		var camp: Chassis = _of(Chassis, 1)
		var sheet: Line = _of(Line, 0)
		var seen := {"t": 0, "sheet": 0.0, "tow": 0.0, "body": 0.0, "camp": 0.0, "carve": 0.0}
		var each := func() -> void:
			_steer()
			# You look along the rig's way, the board steered that far off it.
			var ahead := -rig.global_basis.z
			player.rotation.y = atan2(-ahead.x, -ahead.z) + seen.carve
			seen.t += 1
			if seen.t > 480 and seen.t <= 720:
				seen.sheet += sheet.rope.tension / 240.0
				var tow: Line = _of(Line, 1)
				seen.tow += (tow.rope.tension if tow != null else 0.0) / 240.0
				seen.body += ropes.pull_n / 240.0
				seen.camp += Vector2(camp.linear_velocity.x, camp.linear_velocity.z).length() / 240.0
		await simulate(12.0, each)
		if carve[0] == &"alone":
			alone = seen.body
			print("the rig towing you alone: %.2f m/s, the lines on you pull %d N" % [way().length(), roundi(alone)])
			continue
		if carve[0] == &"none":
			print("towing the camp on a broad reach: the rig at %.2f m/s, the camp %.2f; the visible towline %d N, your sheet %d N, the lines on you %d N (as the link, %d N)" % [
				way().length(), seen.camp, roundi(seen.tow), roundi(seen.sheet), roundi(seen.body), roundi(alone + 2.0 * seen.tow)])
			check(player.board != null and player.waist.tied.size() == 1 and (_of(Line, 1) as Line).rope.a.holder == rig and (_of(Line, 1) as Line).rope.b.holder == camp,
				"the real towline joins both decks while only the sheet is waisted")
			check(seen.camp > 1.0, "the rig tows the camp (%.2f m/s)" % seen.camp)
			check(player.vitals.health == Vitals.FULL and ropes.wrench_n < world.tuning.fulcrum_n,
				"the camp's pull runs past you: %d N on you, %d N alone, unhurt" % [roundi(seen.body), roundi(alone)])
		var from := _off_the_wind(rig)
		course = Vector2.ZERO
		tending = 0.0
		seen.carve = carve[2]
		_press(carve[1])
		await simulate(2.5, each)
		_press([])
		turned[carve[0]] = _off_the_wind(rig) - from
		print("%s: %+.1f° off the wind in 2.5 s" % [carve[0], turned[carve[0]]])
	check(turned[&"windward"] > turned[&"none"] + 6.0, "carving to windward bears it away (%+.1f° against %+.1f°)" % [
		turned[&"windward"], turned[&"none"]])
	check(turned[&"leeward"] < turned[&"none"] - 6.0, "carving to leeward heads it up (%+.1f° against %+.1f°)" % [
		turned[&"leeward"], turned[&"none"]])
	await _set_up(false)
	player.step_off()
	(_of(Chassis, 1) as Chassis).freeze = true
	player.set_physics_process(true)
	player.velocity = Vector3.ZERO
	tending = 0.0
	# Make an actual tow link: cleat the former boom end to the rig, with
	# the movable rider between it and a moored camp along its runners.
	var rig_for_load: Chassis = _of(Chassis, 0)
	var camp_for_load: Chassis = _of(Chassis, 1)
	camp_for_load.global_position = rig_for_load.global_position + rig_for_load.global_basis.z * 8.0
	player.global_position = rig_for_load.global_position + rig_for_load.global_basis.z * 4.0 + Vector3.UP
	var sheet_for_load: Rope = (_of(Line, 0) as Line).rope
	var opposed: Line = _of(Line, 1)
	var end := opposed.ends[0]
	(end.socket.get_parent() as Device).take(end.socket)
	player.waist.tie(end)
	var cleat := rig_for_load.free_tie(player.global_position)
	var sheet_end := mast.take(mast._tie())
	rig_for_load.fit(sheet_end, cleat)
	player.waist._place()
	sheet_for_load.length = sheet_for_load.a.global_position.distance_to(sheet_for_load.through.global_position) \
		+ sheet_for_load.through.global_position.distance_to(sheet_for_load.b.global_position) + 0.05
	opposed.rope.length = opposed.rope.a.global_position.distance_to(opposed.rope.b.global_position) + 0.05
	var bent := {"most": 0.0}
	await simulate(10.0, func() -> void:
		_steer()
		var rig: Chassis = _of(Chassis, 0)
		var away := (rig.global_position - player.global_position).normalized()
		rig.apply_central_force(away * 900.0)
		bent.most = maxf(bent.most, ropes.wrench_n))
	print("made into the tow link with a 900 N rig pull: the lines oppose at up to %d N, %.0f health left" % [
		roundi(bent.most), player.vitals.health])
	check(bent.most > world.tuning.fulcrum_n and player.vitals.health < Vitals.FULL and player.vitals.health >= 1.0,
		"as the fulcrum you're hurt (%.0f health)" % player.vitals.health)
	check(ropes.ropes.size() == 3 and mast.halyard() != null, "and below their breaking the sheet, towline and halyard hold")
	# Unload before checking which line the reel gathers.
	rig_for_load.freeze = true
	sheet_for_load.length += 1.0
	tending = 0.0
	await physics_frames(3)
	var sheet: Rope = (_of(Line, 0) as Line).rope
	var carried: Rope = (_of(Line, 1) as Line).rope
	var was := [sheet.length, carried.length]
	look(eye(), Line._tip((_of(Line, 0) as Line).ends[0]).global_position)
	hands.reel.choose((_of(Line, 0) as Line).ends[1])
	check(hands.reel.line() == sheet and hands.reel.notch(2), "choosing the sheet, the reel works it")
	await simulate(1.0, _steer)
	check(absf(was[0] - sheet.length - 2.0 * Reel.NOTCH) < 0.01 and absf(carried.length - was[1]) < 0.01,
		"two notches take in half a metre of sheet while the camp line stays unchanged (%.2f m, %.2f m)" % [
		was[0] - sheet.length, carried.length - was[1]])
	speed_up(1)


## How far the rig heads off the wind, degrees: 0 into it, 180 running.
func _off_the_wind(rig: Chassis) -> float:
	var ahead := -rig.global_basis.z
	return rad_to_deg(acos(clampf(Vector2(ahead.x, ahead.z).normalized().dot(-downwind), -1.0, 1.0)))


## Holds these movement actions and lets go of the rest.
func _press(keys: Array) -> void:
	for action: String in ["move_left", "move_right", "move_back"]:
		if keys.has(action):
			Input.action_press(action, DIG if action == "move_back" else 1.0)
		else:
			Input.action_release(action)


## The "sail_tow" camp afresh, you standing where it puts you facing the
## point of sail, its sail up, and you on the board.
func _set_up(alone: bool) -> void:
	var player := world.player
	player.step_off()
	for body in player.waist.tied.duplicate():
		player.waist.untie(body)
	for node in kit:
		if is_instance_valid(node) and node is Line:
			for end in (node as Line).ends:
				if is_instance_valid(end) and not (end.get_parent() is Device):
					end.free()
			node.free()
	for node in kit:
		if is_instance_valid(node):
			node.free()
	follow(open)
	await settle(true)
	var way := heading(1, OFF)
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-way.x, -way.y)), open + Vector3.UP * 0.1))
	await physics_frames(5)
	kit = Scenarios.sail_tow(world)
	deck = _of(Chassis, 0)
	mast = _of(Mast, 0)
	if alone:
		var line: Line = _of(Line, 1)
		ropes.untie(line.rope)
		for end in line.ends:
			(end.socket.get_parent() as Device).take(end.socket)
			end.free()
		kit.erase(line)
		line.free()
	await physics_frames(10)
	blow(downwind * 0.0)
	hoist(45.0)
	course = way
	tending = deg_to_rad(15.0)
	check(player.get_on(_of(Hoverboard, 0)), "you step onto the board, your lines still tied")
	await simulate(3.0, _steer)
	blow(downwind * 10.0)


## The scenario's n-th thing of a kind, in the order it laid them: the rig
## before the camp, the sheet before the camp's line; the independent halyard
## stays on its drum and is not one of the two lines whose load we compare.
func _of(kind: Variant, n: int) -> Node3D:
	var found: Array[Node3D] = []
	for body in kit:
		if not is_instance_valid(body) or not is_instance_of(body, kind):
			continue
		if kind == Line and (body as Line).rope == mast.halyard():
			continue
		found.append(body)
	return found[n] if n < found.size() else null
