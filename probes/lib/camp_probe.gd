class_name CampProbe
extends ShieldProbe
## For the AFK probes: the reference camp, the "afk" scenario's, parked in the
## run's own weather on the probes' seed from its first moment, and left alone
## for days of it at the dev time warp's fastest. A physics tick is still a
## sixtieth of a second; only more of them run each second.

const WARP := 60.0

## What the camp dropped, and its pieces.
var camp: Array[Node3D] = []
var deck: Chassis
var shield: ShieldGenerator
var turbine: Device
var planters: Array[Planter] = []


## The world in its own weather, you `latitude` degrees north of where the run
## began, facing upwind as the scenario stands you, at time zero, with the
## reference camp parked round you and carrying what it stocks you with.
func load_camp(latitude := 0.0) -> void:
	await load_world(1234, false)
	if latitude != 0.0:
		teleport(world.player_world_x(), world.player_world_z() - deg_to_rad(latitude) * world.moon.radius)
		await settle()
	var upwind := -world.weather.field.prevailing_at(0.0).normalized()
	world.teleport(world.player, Transform3D(Basis(Vector3.UP, atan2(-upwind.x, -upwind.y)),
		world.player.global_position))
	# The ground there took as long as the machine took: the run starts now,
	# with nothing lived meanwhile.
	world.time = 0.0
	world.weather.forecast_now()
	park()


## The reference camp round you, its pieces named.
func park() -> void:
	camp = Scenarios.afk(world)
	planters.clear()
	for body in camp:
		if body is Chassis:
			deck = body
		elif body is ShieldGenerator:
			shield = body
		elif body is Planter:
			planters.append(body)
		elif body is Device and (body as Device).stats().turbine_w > 0.0:
			turbine = body


## Leaves the camp alone for `days`; each() after every tick.
func idle(days: float, each := Callable()) -> void:
	await live(days * world.tuning.day_minutes * 60.0, WARP, each)


## Starts again in a fresh world on the same seed.
func reload() -> void:
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	world = null
