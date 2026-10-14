class_name RopeProbe
extends WorldProbe
## For rope probes: the world with a wind they choose, the rope core, the
## look-test's stand-ins to tie up, and a clock that can run faster than real
## time without changing the physics step.

const Props := preload("res://look/rope/props.gd")

var ropes: Ropes
var wind: RopeWind


## The world with a wind of the probe's choosing. The clock runs, so gusts
## evolve; the run's storms don't matter, since they no longer set the wind.
func load_ropes(run_seed := 1234) -> void:
	await load_world(run_seed, false)
	wind = RopeWind.new(world.run_seed, world.tuning)
	world.weather.field = wind
	blow(Vector2.ZERO)
	ropes = Ropes.new()
	add_child(ropes)
	ropes.setup(world)
	# You stay out of it unless a probe ties you in.
	world.player.set_physics_process(false)


## A wind everywhere: steady, or with gusts as a share of it.
func blow(along: Vector2, gusts := 0.0) -> void:
	wind.override = wind.steady(along, along.length(), gusts) if along != Vector2.ZERO \
		else func(_x: float, _z: float, _t: float) -> Vector2: return Vector2.ZERO


## Ticks per simulated second, run `speedup` times faster than real time: the
## step stays 1/ticks, the engine just takes more of them per real second.
func set_rate(ticks: int, speedup := 1) -> void:
	Engine.time_scale = speedup
	Engine.physics_ticks_per_second = ticks * speedup
	Engine.max_physics_steps_per_frame = 8 * speedup


func ticks_per_second() -> int:
	return roundi(Engine.physics_ticks_per_second / Engine.time_scale)


## Simulated seconds, as ticks; `each` is called after every tick.
func simulate(seconds: float, each := Callable()) -> void:
	for i in roundi(seconds * ticks_per_second()):
		await get_tree().physics_frame
		if each.is_valid():
			each.call()


## A place on the sand in engine coordinates, `x` and `z` metres from the player.
func spot(x: float, z: float) -> Vector3:
	var at := world.player.global_position + Vector3(x, 0.0, z)
	at.y = world.height_under(at)
	return at


## A line from a stake at `from` to the body's facing ring, with this much slack.
func stake_line(from: Vector3, body: Node3D, slack := 0.0, breaking := Ropes.BREAKING,
		holding := Props.STAKE_HOLDING) -> Rope:
	var stake: RigidBody3D = Props.stake(world, from, holding)
	var ring := Props.ring_toward(body, stake.ring.global_position)
	return ropes.tie(stake.ring, ring, ring.global_position.distance_to(stake.ring.global_position) + slack,
		breaking)


func finite(v: Vector3) -> bool:
	return is_finite(v.x) and is_finite(v.y) and is_finite(v.z)


func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
