extends LineProbe
## Rope & tethering probe 13: reeled in by hand, with the wheel as bound. A
## floating crate rides a breeze out on the line in your hand: reeling in
## draws it in about the notches reeled, and paying out lets it back, never
## past the line's length. Tied at your waist, the line reels too. Reeling
## against a staked line steps you in to the stake, which stays put. Nothing
## goes faster than a line's closing speed, and the drawn strand stays as long
## as the line as it reels. The wheel alone reels; with ctrl it leaves a line
## be, and brings what you hold nearer or pushes it out: a part you carry, a
## crate you have hold of, each stopping at the ends of its range.

const NOTCHES := 8
## Drawn within this share of the notches reeled.
const ROUGHLY := 0.2
## Drawn length this close to the line's, as a share of it, as probe 6 has it.
const LENGTH := 0.03
## Nothing on a line goes faster than its closing speed, m/s.
const FLUNG := 3.0

var _seen := {"fastest": 0.0, "length": 0.0, "reeling": 0}


func run() -> void:
	await load_lines()
	speed_up(4)
	var player := world.player
	var at := spot(0.0, 0.0)
	teleport(world.world_x(at.x), world.world_z(at.z))
	await settle(true)
	at = player.global_position
	var out := Vector3.FORWARD
	var crate := floating(&"crate_frame", at + out * 5.0)
	await simulate(0.5)
	var line := await lead(crate)
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	# A breeze carries it out on its line, so the line is taut from the start.
	blow(Vector2(out.x, out.z) * 4.0)
	var rope := line.rope
	await _settled(rope, crate)
	var full := rope.full
	var from := _apart(crate)

	await _reel(NOTCHES, [crate, player], rope)
	await _settled(rope, crate)
	var drawn := from - _apart(crate)
	var reeled := full - rope.length
	print("reeled %d notches in: the line %.2f m shorter, the crate %.2f m nearer, at most %.2f m/s"
		% [NOTCHES, reeled, drawn, _seen.fastest])
	check(absf(reeled - NOTCHES * Reel.NOTCH) < 1e-3, "each notch reels a notch of line in")
	check(absf(drawn - reeled) < ROUGHLY * reeled and _seen.fastest <= FLUNG,
		"reeling in draws the crate about as far, never faster than a line closes")

	var near := _apart(crate)
	await _reel(-NOTCHES / 2, [crate, player], rope)
	await _settled(rope, crate)
	var let_out := _apart(crate) - near
	await _reel(-NOTCHES * 2, [crate, player], rope)
	print("paid out %d notches: the crate %.2f m farther; %d more: the line %.2f m of %.2f"
		% [NOTCHES / 2, let_out, NOTCHES * 2, rope.length, full])
	check(absf(let_out - NOTCHES / 2 * Reel.NOTCH) < NOTCHES / 2 * Reel.NOTCH * ROUGHLY, "paying out lets it back out")
	check(absf(rope.length - full) < 1e-3, "but never past the line's length")

	check(hands.interact() and player.waist.holds(line.ends[1]), "you tie it at your waist")
	await _settled(rope, crate)
	var waist_from := _apart(crate)
	await _reel(NOTCHES / 2, [crate, player], rope)
	await _settled(rope, crate)
	print("at your waist, %d notches in: the line %.2f m shorter, the crate %.2f m nearer"
		% [NOTCHES / 2, full - rope.length, waist_from - _apart(crate)])
	check(absf(full - rope.length - NOTCHES / 2 * Reel.NOTCH) < 1e-3
		and absf(waist_from - _apart(crate) - NOTCHES / 2 * Reel.NOTCH) < NOTCHES / 2 * Reel.NOTCH * ROUGHLY,
		"the line at your waist reels too")
	print("the strand drawn within %.2f%% of the line's length over %d ticks reeling"
		% [_seen.length * 100.0, _seen.reeling])
	check(_seen.reeling > 0 and _seen.length < LENGTH, "the drawn strand stays as long as the line as it reels")

	blow(Vector2.ZERO)
	player.waist.let_go()
	await simulate(1.5)
	await _cable(crate)
	await _staked(at - out * 4.0)
	await _carried()
	await _grasped()
	speed_up(1)


## A strong cable from the crate's port, its other plug in your hand: it reels as
## the rope it is, its plug staying in, up to its own length.
func _cable(crate: Device) -> void:
	var port: Socket = crate.sockets().filter(func(each: Socket) -> bool: return each.kind == &"port")[0]
	var cable: StrongCable = Catalog.cable(world, port.global_position, true)
	crate.fit(cable.plugs[1], port)
	hands.hold(cable.plugs[0])
	await simulate(0.5)
	_wheel(NOTCHES / 2, true)
	await simulate(2.0)
	var reeled := cable.length - cable.rope.length
	_wheel(-NOTCHES, true)
	await simulate(3.0)
	print("a strong cable reeled %.2f m in, then paid out to %.2f m of %.2f" % [reeled, cable.rope.length, cable.length])
	var kept := cable.rope.length
	_wheel(NOTCHES / 2)
	await simulate(1.0)
	check(is_equal_approx(cable.rope.length, kept), "with ctrl the wheel leaves the line in your hand be")
	check(absf(reeled - NOTCHES / 2 * Reel.NOTCH) < 1e-3 and absf(cable.rope.length - cable.length) < 1e-3
		and cable.plugs[1].socket == port, "a strong cable reels too, its plug staying in")
	hands.drop()
	cable.plugs[0].queue_free()
	await simulate(1.0)


## A line from a stake, its end in your hand: reeled in, you're drawn to it.
func _staked(stake_at: Vector3) -> void:
	var player := world.player
	var stake := driven_stake(stake_at)
	var pinned := stake.global_position
	await simulate(0.5)
	player.set_physics_process(false)
	var line := await lead(stake)
	player.set_physics_process(true)
	await simulate(1.0)
	var from := _apart(stake)
	_seen.fastest = 0.0
	await _reel(NOTCHES, [player], line.rope)
	var came := from - _apart(stake)
	print("reeled %d notches against a stake: you came %.2f m nearer at most %.2f m/s, the stake moved %.3f m"
		% [NOTCHES, came, _seen.fastest, stake.global_position.distance_to(pinned)])
	check(came > NOTCHES * Reel.NOTCH * (1.0 - ROUGHLY) and _seen.fastest <= FLUNG,
		"against a stake, reeling in draws you to it, never faster than a line closes")
	check(stake.driven and stake.global_position.distance_to(pinned) < 0.01, "and the stake stays put")
	hands.drop()
	await simulate(1.0)


## A part in your hands goes out and comes in, a notch at a time, as far as it may.
func _carried() -> void:
	# Looking level, so the sand doesn't stop it short.
	world.player.camera.rotation.x = 0.0
	# Food: nothing here has a socket to offer it.
	var ration := Catalog.part(&"ration")
	world.content.add_child(ration)
	ration.global_position = eye() - world.player.camera.global_basis.z * 0.9
	hands.hold(ration)
	await simulate(0.5)
	var held := [_off_eye(ration)]
	for notches in [-2, -20, 2, 20]:
		_wheel(notches)
		await simulate(1.0)
		held.append(_off_eye(ration))
	print("a carried ration from %.2f m: out %.2f, as far as it goes %.2f; in %.2f, as near as it comes %.2f"
		% held)
	check(held[1] > held[0] + 0.4 and absf(held[2] - Hands.HOLD_FARTHEST) < 0.02,
		"with ctrl the wheel pushes what you carry out, as far as it goes")
	check(held[3] < held[2] - 0.4 and absf(held[4] - Hands.HOLD_NEAREST) < 0.02,
		"and brings it in, no nearer than clears you")
	hands.drop()
	await simulate(1.0)


## A crate too heavy to carry, taken hold of: it goes out and comes in, as far as your reach.
func _grasped() -> void:
	var player := world.player
	var crate := device(&"crate_frame", player.global_position - player.global_basis.z * 1.6, 0.3)
	await simulate(1.5)
	check(await take(crate) and hands.grasp.body == crate, "you take hold of a crate")
	await simulate(1.0)
	var apart := [_apart(crate)]
	for notches in [-2, -20, 4, 20]:
		_wheel(notches)
		await simulate(2.0)
		apart.append(_apart(crate))
	print("a crate you have hold of from %.2f m: out %.2f, as far as you reach %.2f; in %.2f, as near as it comes %.2f"
		% apart)
	check(hands.grasp.body == crate, "it never slips from your hands")
	check(apart[1] > apart[0] + 0.3 and apart[2] > apart[1] and absf(apart[2] - world.tuning.reach) < 0.15,
		"with ctrl the wheel pushes it out, as far as you reach")
	check(apart[3] < apart[2] - 0.6 and apart[4] < apart[3] and apart[4] > 0.9,
		"and brings it in, no nearer than clears you")
	hands.grasp.let_go()


## The wheel turned a step at a time as bound by default: up reels in with
## ctrl held, and brings what you hold nearer without.
func _wheel(notches: int, line := false) -> void:
	for i in absi(notches):
		var step := InputEventMouseButton.new()
		step.button_index = MOUSE_BUTTON_WHEEL_UP if notches > 0 else MOUSE_BUTTON_WHEEL_DOWN
		step.ctrl_pressed = not line
		step.pressed = true
		get_viewport().push_input(step)
		var done: InputEventMouseButton = step.duplicate()
		done.pressed = false
		get_viewport().push_input(done)


## Turns the wheel, then watches the bodies' speeds and the strand as it reels and settles.
func _reel(notches: int, bodies: Array, rope: Rope) -> void:
	_wheel(notches, true)
	var was := {"length": rope.length}
	await simulate(absi(notches) * Reel.NOTCH / Reel.PACE * 3.0 + 3.0, func() -> void:
		for body: Node3D in bodies:
			var v: Vector3 = body.velocity if body is CharacterBody3D else (body as RigidBody3D).linear_velocity
			_seen.fastest = maxf(_seen.fastest, flat(v).length())
		if rope.length != was.length:
			_seen.reeling += 1
			was.length = rope.length
			var points := rope.strand.shown()
			var chord := points[0].distance_to(points[points.size() - 1])
			var drawn := 0.0
			for i in points.size() - 1:
				drawn += points[i].distance_to(points[i + 1])
			var off := absf(drawn - maxf(rope.length, chord)) / rope.length
			_seen.length = maxf(_seen.length, off))


## Until the breeze has the line taut and the crate riding still on it.
func _settled(rope: Rope, crate: RigidBody3D) -> void:
	await simulate(1.0)
	for i in 30:
		if rope.is_taut() and flat(crate.linear_velocity).length() < 0.05:
			return
		await simulate(0.5)


func _apart(body: Node3D) -> float:
	return flat(body.global_position - world.player.global_position).length()


func _off_eye(body: Part) -> float:
	return (body.global_transform * middle(body)).distance_to(eye())
