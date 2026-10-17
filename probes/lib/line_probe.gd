class_name LineProbe
extends HandsProbe
## For rope probes on the game's own things: floating devices with hooks,
## driven stakes, lines laid ring to ring and you, in a wind the probe chooses.

var ropes: Ropes
var wind: RopeWind


## The world in still air with a wind of the probe's choosing, under clear
## skies, with its finds if `salvage`; you go where the probe puts you, as in
## the hands probes.
func load_lines(run_seed := 1234, salvage := false) -> void:
	# The winds a probe picks are the field's own: a breeze, a storm, the worst gust.
	var tuning := Tuning.current()
	# Still air parks the run's storms where they stand, and a long one would
	# wear out what's on the lines.
	tuning.storm_threshold = 2.0
	# The wind a probe picks is the wind felt: no dune's lee takes any of it.
	tuning.lee_wind = 0.0
	tuning.lee_storm = 0.0
	var kept := [tuning.prevailing_speed, tuning.prevailing_sway, tuning.storm_outflow_speed]
	await load_hands(run_seed, salvage)
	tuning.prevailing_speed = kept[0]
	tuning.prevailing_sway = kept[1]
	tuning.storm_outflow_speed = kept[2]
	wind = RopeWind.new(world.run_seed, world.tuning)
	world.weather.field = wind
	blow(Vector2.ZERO)
	ropes = world.ropes


## A wind everywhere: steady, or with gusts as a share of it.
func blow(along: Vector2, gusts := 0.0) -> void:
	wind.override = wind.steady(along, along.length(), gusts) if along != Vector2.ZERO \
		else func(_x: float, _z: float, _t: float) -> Vector2: return Vector2.ZERO


## A catalog device floating on its tray over `at`, a battery in and a hook on
## every ring mount.
func floating(id: StringName, at: Vector3) -> Device:
	var made := device(id, at, world.tuning.hover_height)
	fit_part(made, &"hover_tray")
	fit_part(made, &"battery")
	for socket in made.sockets():
		if socket.kind == &"ring" and socket.part == null:
			fit_part(made, &"hook")
	made.global_position.y += made.rest_height() - world.tuning.hover_height
	return made


## The flattest sand within `reach` m of a spot, where the sand under a
## square `span` m across rises least: what floats there floats level.
func flat_spot(x: float, z: float, span: float, reach := 40) -> Vector3:
	var best := spot(x, z)
	var least := INF
	for i in range(-reach, reach + 1, 4):
		for j in range(-reach, reach + 1, 4):
			var at := spot(x + i, z + j)
			var low := INF
			var high := -INF
			for k in 9:
				var h := world.height_under(at + Vector3((k % 3 - 1) * span * 0.5, 0.0, (floori(k / 3.0) - 1) * span * 0.5))
				low = minf(low, h)
				high = maxf(high, h)
			if high - low < least:
				least = high - low
				best = at
	return best


func driven_stake(at: Vector3) -> Stake:
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.drive(at, world.height_under(at))
	return stake


## A line from the device's tie nearest the other, to the other's nearest it,
## `slack` metres longer than the way between them.
func lay(from: Device, to: Device, slack := 0.3) -> Line:
	var a := from.free_tie(to.global_position)
	return Line.between(world, a, to.free_tie(a.global_position), slack)


## Looks at the middle of a body from where your eyes are and takes it with E.
func take(body: Node3D) -> bool:
	look(eye(), body.global_transform * middle(body) if body is Part else body.global_position)
	await simulate(0.05)
	return hands.grab()


## Holding a line's end, looks at a tie socket from its open side and lets the
## tug snap it home, pressing take if it doesn't on its own. Says whether it's on.
func snap_onto(socket: Socket) -> bool:
	var at := seat(socket)
	look(at.origin + at.basis.z * 0.9 + Vector3.UP * 0.5, at.origin)
	for i in 30:
		await get_tree().physics_frame
		if socket.part != null:
			return true
	if hands.socket == socket:
		hands.grab()
	return socket.part != null


## A line laid from a device to a stake lying loose by your feet, its end then
## taken off the stake into your hand, as you'd take up any line's end.
func lead(from: Device) -> Line:
	var spare := Catalog.stake()
	world.content.add_child(spare)
	var at := world.player.global_position + flat(from.global_position - world.player.global_position).normalized()
	spare.global_transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * 0.5)
	spare.freeze = true
	var line := Line.between(world, from.free_tie(at), spare.free_tie(from.global_position), 0.0)
	var tie := seat(spare.sockets()[0])
	look(tie.origin + Vector3(0.0, 1.0, 0.6), tie.origin + tie.basis.z * 0.04)
	await simulate(0.05)
	check(hands.grab() and hands.look_socket != null, "you take a line's end off a ring")
	await simulate(0.4)
	spare.queue_free()
	return line


## Walks you to a place on the sand at walking pace, by script, across any
## origin shift on the way; `each` is called after every tick.
func walk_to(at: Vector3, each := Callable()) -> void:
	var player := world.player
	var speed := world.tuning.walk_speed
	var x := world.world_x(at.x)
	var z := world.world_z(at.z)
	while true:
		at = Vector3(world.engine_x(x), 0.0, world.engine_z(z))
		if flat(at - player.global_position).length() <= 0.05:
			break
		var step := flat(at - player.global_position).limit_length(speed / 60.0)
		player.velocity = step * 60.0
		var next := player.global_position + step
		next.y = world.height_under(next)
		player.global_position = next
		await get_tree().physics_frame
		if each.is_valid():
			each.call()
	player.velocity = Vector3.ZERO


## The save on disk resumed into a fresh world on the same seed, which you
## move through as the probe puts you, in the probe's still air.
func resume() -> bool:
	var seed_was := world.run_seed
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	world = WORLD_SCENE.instantiate()
	world.run_seed = seed_was
	add_child(world)
	await settle()
	await get_tree().physics_frame
	world.player.set_physics_process(false)
	var saves := get_node(^"/root/Saves")
	if not saves.restore(world):
		return false
	if saves.restoring:
		await saves.restored
	world.player.collision_layer = 0
	world.player.collision_mask = 0
	world.weather.field = wind
	hands = world.player.hands
	ropes = world.ropes
	return true


## Where a body's wind load stands now, N: drag on the air going past it.
func wind_load(body: RigidBody3D) -> Vector3:
	var past := world.weather.felt_wind(body.global_position) - body.linear_velocity
	past.y = 0.0
	return past * past.length() * world.weather.catch_of(body)


func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func finite(v: Vector3) -> bool:
	return is_finite(v.x) and is_finite(v.y) and is_finite(v.z)
