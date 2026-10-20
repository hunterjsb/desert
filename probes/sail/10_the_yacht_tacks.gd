extends SailProbe
## Sailing probe 10: the yacht tacks with its keel. The "yacht" floating on
## its trays, you at its helm in a steady 10 m/s wind, the sheet tended:
## steered by the helm's keys across the wind and then up to 60° off it, the
## keel holds it there and it makes ground upwind; the same yacht with a
## tray in the keel's place only runs downwind, sliding off sideways however
## it's steered. Left to itself, its sheet made fast and nobody aboard, a
## floating camp still sails itself downwind. At the helm, reeling hauls the
## sheet at your waist in. Saved at the helm, you resume there.

var kit: Array[Node3D] = []


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	speed_up(4)
	var made := {}
	for keeled: bool in [true, false]:
		await _set_up(keeled)
		var helm: Helm = kit[2]
		check(helm.interact(player) and player.helm == helm, "you sit at the helm")
		tending = deg_to_rad(15.0)
		var seen := {"t": 0, "from": Vector3.ZERO, "slide": 0.0}
		await simulate(28.0, func() -> void:
			_steer()
			seen.t += 1
			# Across the wind to get going, then up to 60° off it.
			_hold(heading() if seen.t < 480 else heading(1, 30.0))
			if seen.t == 480:
				seen.from = deck.global_position
			if seen.t > 480:
				var ahead := -deck.global_basis.z
				seen.slide += absf(way().dot(Vector2(ahead.x, ahead.z).normalized().orthogonal())) / (28 * 60 - 480))
		_hold(Vector2.ZERO)
		var gone := Vector2(deck.global_position.x - seen.from.x, deck.global_position.z - seen.from.z)
		made[keeled] = {"up": -gone.dot(downwind), "slide": seen.slide, "speed": way().length()}
		print("%s, 20 s steered 60° off the wind: %.1f m upwind, %.2f m/s, sliding sideways %.2f m/s, still aboard %s" % [
			"keel" if keeled else "no keel", made[keeled].up, made[keeled].speed, made[keeled].slide, player.helm == helm])
		check(player.helm == helm, "still at the helm")
		player.stand_up()
	check(made[true].up > 10.0 and made[true].slide < 0.3, "with its keel it tacks: %.1f m upwind, sliding %.2f m/s" % [
		made[true].up, made[true].slide])
	check(made[false].up < 0.0 and made[false].slide > 2.0, "without, it only runs downwind: %.1f m, sliding %.2f m/s" % [
		made[false].up, made[false].slide])
	# Nobody aboard: the floating camp of the sail probes, its sheet made fast.
	_clear()
	rig(open, heading(1, -30.0), &"hover_tray")
	blow(downwind * 10.0)
	hoist(30.0)
	course = Vector2.ZERO
	tending = 0.0
	await simulate(20.0, func() -> void: follow(deck.global_position + Vector3(0.0, 0.0, 8.0)))
	var downwind_speed := way().dot(downwind)
	print("left to itself: downwind at %.2f m/s" % downwind_speed)
	check(downwind_speed > 2.0, "left to itself it sails downwind (%.2f m/s)" % downwind_speed)
	deck.free()
	await _set_up(true)
	check((kit[2] as Helm).interact(player), "back at the helm")
	await simulate(3.0)
	var trimmed := mast.sheet().length
	for body in player.waist.tied:
		if Mast.sheet_end(body):
			hands.reel.choose(body)
	check(hands.reel.notch(2), "at the helm, the reel works the sheet at your waist")
	await simulate(1.0)
	check(absf(trimmed - mast.sheet().length - 2.0 * Reel.NOTCH) < 0.01, "and two notches take in half a metre of its routed sheet (%.2f m)" % (trimmed - mast.sheet().length))
	check(get_node(^"/root/Saves").save(world), "saved at the helm")
	check(await resume(), "resumed")
	var at := world.player.helm
	check(at != null and at.carrier() != null and Runners.keels(at.carrier()).size() == 1,
		"resumed at the helm of a deck with its keel")
	speed_up(1)


## The helm's keys toward a heading, as you'd steer by eye; none for zero.
func _hold(want: Vector2) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if want == Vector2.ZERO:
		return
	var ahead := -deck.global_basis.z
	# A turn to the left is against angle_to's sense on the sand.
	var turn := clampf(-Vector2(ahead.x, ahead.z).angle_to(want) * 8.0, -1.0, 1.0)
	if turn > 0.01:
		Input.action_press("move_left", turn)
	elif turn < -0.01:
		Input.action_press("move_right", -turn)


func _clear() -> void:
	var player := world.player
	if player.helm != null:
		player.stand_up()
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
	kit.clear()
	follow(open)
	await settle(true)


## The "yacht" afresh, standing where it puts you facing across the wind,
## with its keel or a tray in its place; its sail up.
func _set_up(keeled: bool) -> void:
	await _clear()
	var player := world.player
	var way := heading()
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-way.x, -way.y)), open + Vector3.UP * 0.1))
	await physics_frames(5)
	kit = Scenarios.yacht(world)
	deck = kit[0]
	mast = kit[1]
	if not keeled:
		for socket in deck.stuck():
			if socket.part != null and socket.part.stats.has("keel"):
				# A tray stuck where the keel was, under the same piece.
				var pose := socket.transform
				var out := socket.out
				var piece := deck.own_piece(socket)
				deck.unstick(socket).free()
				deck.stick(Catalog.part(&"hover_tray"), pose, out, piece)
				break
	await physics_frames(30)
	blow(downwind * 10.0)
	hoist(60.0)
