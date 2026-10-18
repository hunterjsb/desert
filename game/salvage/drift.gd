class_name Drift
extends RefCounted
## Drift (docs/world-system.md, Loot): what a storm carries, light debris,
## scraps and now and then a small thing, caught by a line strung between two
## stakes driven in the sand, across the wind. It isn't things blown across
## the map: it's a stream read from the weather and the ground at the line,
## made into a body only where the line catches it, so it stays stateless.
## How much: how hard it blows there (what exposure reads), times the line's
## span across the wind, times what snags on a line in the open and, in a
## lee, what falls out where the wind slows. A sheltered valley below a crest
## the wind ramps over is the best farm.

## What the wind carries, as [catalog id, weight]: leaves and salt off the
## feral saltbush, a wild cutting, scraps of old gear.
const CARRIES := [[&"saltbush_leaves", 4], [&"salt", 3], [&"saltbush", 2], [&"hook", 2], [&"compass", 1],
	[&"lamp", 1], [&"battery", 1]]
## What a line catches falls this far downwind of it, m, least and most.
const FALLS := Vector2(0.3, 0.9)
## Held where it fell in the line's lee: anything frozen this near the line
## is its pile, which holds at most drift_most before more blows past, m.
const PILE := 1.5
## A battery the wind carried holds at most this share of its charge.
const CHARGE := 0.2


## Things an hour a metre of line straight across the wind catches at a
## world place and time.
static func per_metre(world: World, x: float, z: float, t: float) -> float:
	var tuning := world.tuning
	var field := world.weather.field
	var wind := field.wind_at(x, z, t)
	if wind.length_squared() < 1e-6:
		return 0.0
	var lee := world.weather.lee.share(x, z, wind.angle())
	return tuning.drift_per_m_hour * Exposure.reading(field, x, z, t, tuning) * (tuning.drift_open + tuning.drift_lee * lee)


## Things an hour a line from a to b, world metres, catches at world time t.
static func rate(world: World, a: Vector2, b: Vector2, t: float) -> float:
	var mid := (a + b) * 0.5
	var wind := world.weather.field.wind_at(mid.x, mid.y, t)
	if wind.length_squared() < 1e-6:
		return 0.0
	return per_metre(world, mid.x, mid.y, t) * absf((b - a).cross(wind.normalized()))


## Every catch line on solid ground: a line laid between two stakes driven
## in the sand, at least drift_shortest_m long. [line, a, b], world metres.
static func lines(world: World) -> Array[Array]:
	var out: Array[Array] = []
	for node in world.content.get_children():
		var line := node as Line
		if line == null or line.state != Line.State.LAID or line.ends.size() != 2:
			continue
		var at: Array[Vector2] = []
		for end in line.ends:
			var stake: Stake = end.socket.get_parent() as Stake if is_instance_valid(end) and end.socket != null else null
			if stake == null or not stake.driven:
				break
			at.append(Vector2(world.world_x(stake.global_position.x), world.world_z(stake.global_position.z)))
		if at.size() == 2 and at[0].distance_to(at[1]) >= world.tuning.drift_shortest_m \
				and world.terrain.has_collision_at((at[0].x + at[1].x) * 0.5, (at[0].y + at[1].y) * 0.5):
			out.append([line, at[0], at[1]])
	return out


## What a line between a and b catches in one tick of drift, from its own
## stream of the seed: {id, x, z, yaw} where it falls, or {} if nothing.
static func caught(world: World, a: Vector2, b: Vector2, tick: int) -> Dictionary:
	var tuning := world.tuning
	var t := tick * tuning.drift_tick_s
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.run_seed, "drift", Vector2i(a.round()), Vector2i(b.round()), tick])
	if rng.randf() >= rate(world, a, b, t) * tuning.drift_tick_s / 3600.0:
		return {}
	var wind := world.weather.field.wind_at((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, t).normalized()
	var at := a.lerp(b, rng.randf_range(0.1, 0.9)) + wind * rng.randf_range(FALLS.x, FALLS.y)
	return {"id": Finds._pick(rng, CARRIES), "x": at.x, "z": at.y, "yaw": rng.randf() * TAU, "charge": rng.randf() * CHARGE}


## How many things lie in a line's pile now.
static func pile(world: World, a: Vector2, b: Vector2) -> int:
	var count := 0
	for node in world.content.get_children():
		var body := node as RigidBody3D
		if body == null or not body.freeze or not body.has_meta(&"buried"):
			continue
		var at := Vector2(world.world_x(body.global_position.x), world.world_z(body.global_position.z))
		if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) <= PILE:
			count += 1
	return count


## A caught thing on the sand where it fell, held there until you take it:
## yours, lying in the line's lee, a surface find.
static func lay(world: World, spec: Dictionary) -> RigidBody3D:
	var body := Finds.bare({"id": spec.id, "device": false, "layer": Finds.SURFACE, "charge": spec.charge})
	if body is Plant:
		(body as Plant).wild = true
	var pose := Finds.pose(body, {"x": spec.x, "z": spec.z, "yaw": spec.yaw, "bury": 0.0, "device": false,
		"drop": SiteLoot.DROP}, world.height_at)
	world.content.add_child(body)
	body.global_transform = Transform3D(pose.basis, Vector3(world.engine_x(pose.origin.x), pose.origin.y,
		world.engine_z(pose.origin.z)))
	body.freeze = true
	body.set_meta(&"buried", true)
	body.set_meta(&"drift", true)
	return body
