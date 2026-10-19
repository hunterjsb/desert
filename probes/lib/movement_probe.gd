class_name MovementProbe
extends WorldProbe
## For movement probes: you, driven by held keys the way a player holds them,
## on the run's dunes in still air or a steady wind of the probe's choosing,
## with a clock that can run faster than real time without changing the tick.

const KEYS := ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "crouch"]

var player: Player
var wind: RopeWind
## The lowest your feet have been below the sand, m, on any tick watched.
var deepest := 0.0
## Milliseconds each frame waits while a fast ride is held back for the
## ground to catch up.
var _braking := 0


func load_moving(run_seed := 1234, salvage := false) -> void:
	await load_world(run_seed, true, salvage)
	player = world.player
	hold([])


## Holds exactly these keys and lets go of the rest.
func hold(actions: Array) -> void:
	for action: String in KEYS:
		if actions.has(action):
			Input.action_press(action)
		else:
			Input.action_release(action)


## A steady wind everywhere, m/s, in world x and z.
func blow(along: Vector2) -> void:
	if wind == null:
		wind = RopeWind.new(world.run_seed, world.tuning)
		world.weather.field = wind
	wind.override = func(_x: float, _z: float, _t: float) -> Vector2: return along


## Ticks per simulated second, run `speedup` times faster than real time.
func set_rate(ticks: int, speedup := 1) -> void:
	Engine.time_scale = speedup
	Engine.physics_ticks_per_second = ticks * speedup
	Engine.max_physics_steps_per_frame = 8 * speedup


func ticks_per_second() -> int:
	return roundi(Engine.physics_ticks_per_second / Engine.time_scale)


## Simulated seconds, as ticks; `each` is called after every tick. Watches
## that you never end up in the sand.
func simulate(seconds: float, each := Callable()) -> void:
	for i in roundi(seconds * ticks_per_second()):
		await get_tree().physics_frame
		deepest = minf(deepest, clearance(player))
		if each.is_valid():
			each.call()
	_braking = 0
	Engine.max_physics_steps_per_frame = 8 * roundi(Engine.time_scale)


## Puts you at rest on the sand at a world place, facing along `facing`.
func place(x: float, z: float, facing: Vector2) -> void:
	hold([])
	teleport(x, z)
	face(facing)
	await settle(true)
	await simulate(0.5)


## Turns you to face along a world direction.
func face(along: Vector2) -> void:
	player.rotation.y = atan2(-along.x, -along.y)


## The sand's rise per metre at a world place, along x and z.
func gradient(x: float, z: float) -> Vector2:
	return Vector2(world.height_at(x + 0.25, z) - world.height_at(x - 0.25, z),
		world.height_at(x, z + 0.25) - world.height_at(x, z - 0.25)) / 0.5


func degrees(grade: Vector2) -> float:
	return rad_to_deg(atan(grade.length()))


## Where, within `reach` m of a world place, the sand is steepest between
## `low` and `high` degrees and stays at least `low` for `run` m downhill:
## {x, z, downhill, degrees}, or {} if nowhere.
func slope_between(x0: float, z0: float, reach: float, low: float, high: float, run := 0.0) -> Dictionary:
	var best := {}
	var x := x0 - reach
	while x <= x0 + reach:
		var z := z0 - reach
		while z <= z0 + reach:
			var d := degrees(gradient(x, z))
			if d >= low and d <= high and (best.is_empty() or d > best.degrees) and _holds(x, z, low, run):
				best = {"x": x, "z": z, "downhill": -gradient(x, z).normalized(), "degrees": d}
			z += 2.0
		x += 2.0
	return best


## Where, within `reach` m, the sand is flattest for `run` m all round.
func flat_place(x0: float, z0: float, reach: float, run: float) -> Dictionary:
	var best := {}
	var x := x0 - reach
	while x <= x0 + reach:
		var z := z0 - reach
		while z <= z0 + reach:
			var worst := 0.0
			for k in 8:
				var at := Vector2(x, z) + Vector2(run, 0.0).rotated(k * TAU / 8.0)
				worst = maxf(worst, degrees(gradient(at.x, at.y)))
			worst = maxf(worst, degrees(gradient(x, z)))
			if best.is_empty() or worst < best.degrees:
				best = {"x": x, "z": z, "degrees": worst}
			z += 4.0
		x += 4.0
	return best


func _holds(x: float, z: float, low: float, run: float) -> bool:
	var down := -gradient(x, z).normalized()
	var at := Vector2(x, z)
	var walked := 0.0
	while walked < run:
		at += down
		walked += 1.0
		if degrees(gradient(at.x, at.y)) < low:
			return false
	return true


func flat_speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()


## A hoverboard of this make lying at your feet, nose your way, with a full battery of this kind.
func board_here(cell := &"battery", make := BoardMakes.ISSUE) -> Hoverboard:
	var made := Catalog.device(make) as Hoverboard
	world.content.add_child(made)
	var part := Catalog.part(cell)
	world.content.add_child(part)
	made.fit(part, made.sockets()[0])
	made.global_transform = Transform3D(Basis(Vector3.UP, player.rotation.y), player.global_position + Vector3.UP * 0.06)
	return made


## On a charged board at your feet, as the ride action puts you, settled on its hover.
func ride_here(cell := &"battery", make := BoardMakes.ISSUE) -> Hoverboard:
	var made := board_here(cell, make)
	check(player.get_on(made) and player.board == made, "you step onto the board")
	await simulate(1.0)
	return made


## Ticks the ride moves you for, as simulate() does for simulated time: a
## tick the board waits for ground not yet solid isn't one. `each` is called
## after every tick it moved you. Paced, a fast ride is held to the ground's
## pace, so it never waits; unpaced, it waits for the ground as the game does,
## which changes when it gets there but never where it goes, so a ride that
## nothing else moves around can go as fast as the machine allows.
func ride_for(seconds: float, each := Callable(), paced := true) -> void:
	var ride := player.ride
	if ride == null:
		check(false, "you're on the board")
		return
	var until := ride.ticks + roundi(seconds * ticks_per_second())
	while player.ride == ride and ride.ticks < until:
		var was := ride.ticks
		await get_tree().physics_frame
		if paced:
			keep_pace()
		elif (ride.ticks == was) != (_braking > 0):
			# Waiting, it hands the machine to the workers building the ground.
			_braking = 4 if ride.ticks == was else 0
			Engine.max_physics_steps_per_frame = 1 if _braking > 0 else 8 * roundi(Engine.time_scale)
		if ride.ticks == was:
			continue
		deepest = minf(deepest, clearance(player))
		if each.is_valid():
			each.call()
	_braking = 0
	Engine.max_physics_steps_per_frame = 8 * roundi(Engine.time_scale)


## Whether the ground is solid this far along your way, m.
func solid_ahead(metres: float) -> bool:
	var way := Vector2(player.velocity.x, player.velocity.z)
	var to := Vector2(world.player_world_x(), world.player_world_z()) + way.normalized() * metres
	return world.terrain.has_collision_at(to.x, to.y)


## As fast as set_rate allows while the ground is solid well along your way;
## one tick a frame, at sixty frames a second or slower, while it catches up,
## as a game would run. The tick rate never changes, so the ride's path is the
## same whatever the machine's load: only how fast it gets through it.
func keep_pace() -> void:
	# Collision reaches two chunks past yours, 128 to 192 m ahead once built;
	# flat out a board crosses 40 m in two seconds of the ride.
	_braking = 0 if solid_ahead(80.0) else (16 if solid_ahead(40.0) else 100)
	Engine.max_physics_steps_per_frame = 1 if _braking > 0 else 8 * roundi(Engine.time_scale)


func _process(_delta: float) -> void:
	if _braking > 0:
		OS.delay_msec(_braking)


## Your feet in world coordinates.
func where() -> Vector3:
	var p := player.global_position
	return Vector3(world.world_x(p.x), p.y, world.world_z(p.z))


## No tick ever put you in the sand, in any movement probe.
func before_finish() -> void:
	hold([])
	check(deepest > -0.05, "you never went into the sand (deepest %.3f m)" % deepest)
	super()
