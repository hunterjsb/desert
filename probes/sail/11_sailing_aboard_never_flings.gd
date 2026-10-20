extends SailProbe
## Time limit: 600 s
## Sailing probe 11: nothing flings, stage two or three, at any tick rate.
## The "sail_tow" camp on a broad reach with you riding between, its course
## held, and the "yacht" across the wind with you at its helm, each for 15 s
## at 30, 60 and 120 ticks a second: every number a number, no body jolted
## harder than a hard landing from one tick to the next or spun wild, you
## never thrown or hurt, and each goes as far at every rate: the yacht within
## 3%, the camp under tow, whose lines swing you a tick at a time, within a
## tenth.

## The most any of it may change speed in a tick, as m/s², and spin, rad/s.
const JOLT := 20.0
const SPIN := 1.5

var kit: Array[Node3D] = []


func run() -> void:
	await load_sailing()
	var player := world.player
	player.set_physics_process(true)
	player.collision_layer = 1
	player.collision_mask = 1
	var went := {}
	for stage: StringName in [&"tow", &"yacht"]:
		for ticks: int in [30, 60, 120]:
			await _set_up(stage)
			var bodies: Array[Node3D] = [kit[0], player]
			if stage == &"tow":
				bodies.append(_of(Chassis, 1))
			var seen := {"jolt": 0.0, "spin": 0.0, "numbers": true, "was": bodies.map(_way)}
			var start: Vector3 = kit[0].global_position
			Engine.physics_ticks_per_second = ticks * 2
			Engine.time_scale = 2.0
			for i in 15 * ticks:
				await get_tree().physics_frame
				_steer()
				if stage == &"yacht":
					_hold(heading())
				else:
					var ahead := -(kit[0] as Node3D).global_basis.z
					player.rotation.y = atan2(-ahead.x, -ahead.z)
				var now := bodies.map(_way)
				for k in bodies.size():
					var v: Vector3 = now[k]
					seen.numbers = seen.numbers and is_finite(v.length()) and is_finite(bodies[k].global_position.length())
					# Once you've settled onto the board's hover; your own way over the sand.
					var change: Vector3 = v - seen.was[k]
					if bodies[k] == player:
						change.y = 0.0
					if i >= ticks:
						seen.jolt = maxf(seen.jolt, change.length() * ticks)
				seen.was = now
				for body in bodies:
					if body is RigidBody3D:
						seen.spin = maxf(seen.spin, (body as RigidBody3D).angular_velocity.length())
			Engine.physics_ticks_per_second = 60
			Engine.time_scale = 1.0
			_hold(Vector2.ZERO)
			var gone := Vector2(kit[0].global_position.x - start.x, kit[0].global_position.z - start.z).length()
			went[[stage, ticks]] = gone
			print("%s at %d ticks a second: %.2f m in 15 s, jolted %.1f m/s² at most, spun %.2f rad/s, aboard %s, %.0f health" % [
				stage, ticks, gone, seen.jolt, seen.spin, player.board != null or player.helm != null, player.vitals.health])
			check(seen.numbers and seen.jolt < JOLT and seen.spin < SPIN,
				"%s at %d ticks: nothing flung (%.1f m/s², %.2f rad/s)" % [stage, ticks, seen.jolt, seen.spin])
			check((player.board != null or player.helm != null) and player.vitals.health == Vitals.FULL,
				"%s at %d ticks: you still aboard, unhurt" % [stage, ticks])
		var within := 0.1 if stage == &"tow" else 0.03
		for ticks: int in [30, 120]:
			check(absf(went[[stage, ticks]] - went[[stage, 60]]) < within * went[[stage, 60]],
				"%s at %d ticks goes as far as at 60 (%.2f m against %.2f m)" % [stage, ticks, went[[stage, ticks]], went[[stage, 60]]])


func _way(body: Node3D) -> Vector3:
	return (body as RigidBody3D).linear_velocity if body is RigidBody3D else (body as CharacterBody3D).velocity


## The helm's keys toward a heading; none for zero.
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


## A stage afresh, you standing where its scenario puts you: the camp under
## tow with you on the board, its course held, or you at the yacht's helm.
func _set_up(stage: StringName) -> void:
	var player := world.player
	if player.helm != null:
		player.stand_up()
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
	player.vitals.health = Vitals.FULL
	follow(open)
	await settle(true)
	var way := heading(1, -30.0) if stage == &"tow" else heading()
	world.teleport(player, Transform3D(Basis(Vector3.UP, atan2(-way.x, -way.y)), open + Vector3.UP * 0.1))
	await physics_frames(5)
	kit = Scenarios.sail_tow(world) if stage == &"tow" else Scenarios.yacht(world)
	deck = kit[0]
	mast = kit[1]
	await physics_frames(10)
	blow(downwind * 10.0)
	# The sheet left as it's set, so only the ticks differ.
	hoist(60.0)
	tending = 0.0
	if stage == &"tow":
		course = way
		check(player.get_on(_of(Hoverboard, 0)), "on the board")
	else:
		course = Vector2.ZERO
		check((_of(Helm, 0) as Helm).interact(player), "at the helm")
	await physics_frames(2)


## The scenario's n-th thing of a kind, in the order it laid them: the rig
## before the camp.
func _of(kind: Variant, n: int) -> Node3D:
	var found := kit.filter(func(body: Node) -> bool: return is_instance_of(body, kind))
	return found[n] if n < found.size() else null
