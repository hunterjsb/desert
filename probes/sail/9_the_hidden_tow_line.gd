extends SailProbe
## Sailing probe 9: the hidden tow line. The "sail_tow" camp on a broad reach
## in a steady 10 m/s wind: the rig's sheet and the camp's line both at your
## waist, you ride the board between them and the rig tows the camp on a line
## of its own past you: the lines on you pull hardly harder than with the rig
## towing you alone, where as the link you'd bear the camp's pull twice over.
## Carving out to windward bears the rig away, to leeward heads it up,
## against the same start with no carve. Braced off its way with the camp
## moored, you're the fulcrum the line bends round, and it hurts you.

## The point of sail, degrees off a beam reach (Scenarios' heading), the
## carve, rad off the rig's way, and how hard the edge digs in.
const OFF := -30.0
const CARVE := deg_to_rad(20.0)
const DIG := 0.3

var kit: Array[Node3D] = []


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	speed_up(4)
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
				seen.tow += (ropes.hidden.tension if ropes.hidden != null else 0.0) / 240.0
				seen.body += ropes.pull_n / 240.0
				seen.camp += Vector2(camp.linear_velocity.x, camp.linear_velocity.z).length() / 240.0
		await simulate(12.0, each)
		if carve[0] == &"alone":
			alone = seen.body
			print("the rig towing you alone: %.2f m/s, the lines on you pull %d N" % [way().length(), roundi(alone)])
			continue
		if carve[0] == &"none":
			print("towing the camp on a broad reach: the rig at %.2f m/s, the camp %.2f; the hidden line %d N, your sheet %d N, the lines on you %d N (as the link, %d N)" % [
				way().length(), seen.camp, roundi(seen.tow), roundi(seen.sheet), roundi(seen.body), roundi(alone + 2.0 * seen.tow)])
			check(ropes.hidden != null and player.board != null and player.waist.tied.size() == 2,
				"riding with both lines at your waist, the hidden line holds")
			check(seen.camp > 1.0, "the rig tows the camp (%.2f m/s)" % seen.camp)
			check(seen.body < alone + 0.3 * seen.tow and player.vitals.health == Vitals.FULL,
				"the camp's pull runs past you: %d N on you, %d N alone, unhurt" % [roundi(seen.body), roundi(alone)])
		var from := _off_the_wind(rig)
		course = Vector2.ZERO
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
	player.set_physics_process(false)
	player.global_position += ground(-downwind) * 4.0
	var bent := {"most": 0.0}
	await simulate(10.0, func() -> void:
		_steer()
		bent.most = maxf(bent.most, ropes.wrench_n))
	print("braced 4 m to windward of the line, the camp moored: it bends round you at up to %d N, %.0f health left" % [
		roundi(bent.most), player.vitals.health])
	check(bent.most > world.tuning.fulcrum_n and player.vitals.health < Vitals.FULL and player.vitals.health >= 1.0,
		"as the fulcrum you're hurt (%.0f health)" % player.vitals.health)
	check(ropes.hidden != null and ropes.ropes.size() == 2, "and below their breaking the lines hold")
	speed_up(1)


## How far the rig heads off the wind, degrees: 0 into it, 180 running.
func _off_the_wind(rig: Chassis) -> float:
	var ahead := -rig.global_basis.z
	return rad_to_deg(acos(clampf(Vector2(ahead.x, ahead.z).normalized().dot(-downwind), -1.0, 1.0)))


## Holds these, the dig partway, and lets go of the rest.
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
		player.waist.untie(line.ends[1])
	await physics_frames(10)
	blow(downwind * 10.0)
	hoist(60.0)
	course = way
	tending = deg_to_rad(15.0)
	check(player.get_on(_of(Hoverboard, 0)), "you step onto the board, your lines still tied")
	await physics_frames(2)


## The scenario's n-th thing of a kind, in the order it laid them: the rig
## before the camp, the sheet before the camp's line.
func _of(kind: Variant, n: int) -> Node3D:
	var found := kit.filter(func(body: Node) -> bool: return is_instance_of(body, kind))
	return found[n] if n < found.size() else null
