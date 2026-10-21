extends LineProbe
## A gathered knot fits an ordinary anchor with its original ends and mass,
## records Make Fast only there, and remains ordinary removable fittings.

func run() -> void:
	await load_lines()
	world.counts_deeds = true
	var player := world.player
	var at := player.global_position
	var lines: Array[Line] = []
	for offset in [Vector3(-4, 0, -4), Vector3(4, 0, -4)]:
		var far := driven_stake(at + offset)
		lines.append(Line.to_waist(world, far.free_tie(at), 5.0))
	var primary := lines[0].ends[1]
	var second := lines[1].ends[1]
	hands.hold(player.waist.untie(primary))
	check(RopeBundle.gather(primary, player.waist.untie(second)), "original ends gather through a nested fitting")
	hands.refresh_held_shape()
	await simulate(0.25)
	var profile := get_node(^"/root/Profile")
	check(not profile.did(&"make_fast"), "gathering alone does not make an anchor")
	var anchor := driven_stake(at + Vector3(0, 0, -1.5))
	var weight := anchor.mass
	var target := anchor.global_transform * Stake.RING
	look(target + Vector3(0, 0.3, 1), target)
	await simulate(0.4)
	check(hands.socket != null and hands.socket.get_parent() == anchor, "the ordinary anchor offers its real socket")
	if hands.socket == null:
		return
	check(hands.grab(), "take fastens the gathered ends normally")
	await physics_frames(2)
	check(hands.held == null and primary.socket != null and RopeBundle.members(primary) == [primary, second],
		"the same knot remains fitted after its anchor takes it")
	if primary.socket == null:
		return
	check(Line._tip(primary).holder == anchor and Line._tip(second).holder == anchor,
		"both distinct ropes pull at the physical anchor")
	check(absf(anchor.mass - weight - 0.6) < 0.001, "fitted end masses are counted exactly once")
	check(profile.did(&"make_fast"), "successful ordinary batch anchoring records Make Fast")
	var shapes := primary.socket.fitted.filter(func(node: Node) -> bool: return node is CollisionShape3D)
	var knot_at: Vector3 = shapes[0].global_position
	look(knot_at + Vector3(0, 0.1, 0.6), knot_at)
	await simulate(0.3)
	check(hands.look_socket != null and hands.look_socket.part == primary, "the primary knot is an ordinary physical pickup target")
	check(hands.grab(), "take retrieves the primary knot")
	await simulate(world.tuning.take_seconds + Hands.ARRIVE + 0.2)
	check(hands.held == primary and RopeBundle.members(primary) == [primary, second],
		"ordinary hands retrieval preserves the gathered knot")
	check(absf(primary.mass - 0.6) < 0.001 and absf(anchor.mass - weight) < 0.001,
		"retrieval restores loose mass and removes each mass from the anchor")
	player.velocity = Vector3(2.0, 0.0, 0.5)
	hands.drop()
	check((primary.linear_velocity - player.velocity).length() < 0.001, "dropping preserves ordinary player momentum")
	await physics_frames(2)
	check(RopeBundle.members(primary) == [primary, second]
		and lines.all(func(line: Line) -> bool: return world.ropes.ropes.has(line.rope)),
		"the dropped knot retains both distinct original lines")
