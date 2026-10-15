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


func load_moving(run_seed := 1234) -> void:
	await load_world(run_seed)
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


## Your feet in world coordinates.
func where() -> Vector3:
	var p := player.global_position
	return Vector3(world.world_x(p.x), p.y, world.world_z(p.z))


## No tick ever put you in the sand, in any movement probe.
func before_finish() -> void:
	hold([])
	check(deepest > -0.05, "you never went into the sand (deepest %.3f m)" % deepest)
	super()
