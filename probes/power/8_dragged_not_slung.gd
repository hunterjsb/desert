extends DeviceProbe
## Power probe 8: a loose plug is dragged, never slung. In a gale a floating
## planter drifts off downwind with one plug of a strong cable in its port; the
## other plug lies on the sand upwind of you, so the planter drags it over the
## dunes and round your legs, where it can catch while the cable stretches.
## From several starts, the wind blowing several ways, the plug follows: it
## never closes on the port dragging it much faster than the rope's closing
## speed, and never goes faster than the wind.

const WIND := 20.0
## Each start: metres east and south of the spawn, the wind's turn from the
## run's prevailing way in degrees, and how far upwind of you the plug lies, m.
## From the last, the stretched cable once slung the plug off at 30 m/s.
const STARTS := [[0.0, 0.0, -45.0, 2.0], [0.0, 0.0, 0.0, 1.0], [-3.0, 1.0, -45.0, 1.0],
	[4.0, -4.0, 90.0, 2.0], [11.0, -9.0, 135.0, 1.0], [11.0, -9.0, -90.0, 2.0]]
## Closing on the port faster than this, m/s, the cable slung it: past the
## rope's closing speed, a tick's push it can't see coming.
const FLUNG := 5.0
const SECONDS := 3.0

var _wind: RopeWind


func run() -> void:
	await load_world(1234, false)
	var tuning := Tuning.current()
	tuning.prevailing_speed = WIND
	tuning.storm_outflow_speed = 0.0
	_wind = RopeWind.new(world.run_seed, tuning)
	world.weather.field = _wind
	world.time_warp = 0.0
	var prevailing := _wind.prevailing_at(world.time)
	var home := world.player.global_position
	for start: Array in STARTS:
		_wind.override = func(_x: float, _z: float, _t: float) -> Vector2: return Vector2.ZERO
		world.player.set_physics_process(true)
		teleport(world.world_x(home.x + start[0]), world.world_z(home.z + start[1]))
		await settle()
		await physics_frames(30)
		# Then you stand still on the sand, something a plug can catch on.
		world.player.set_physics_process(false)
		var turned := prevailing.normalized().rotated(deg_to_rad(start[2]))
		_wind.override = func(_x: float, _z: float, _t: float) -> Vector2: return turned * WIND
		await _dragged(start, Vector3(turned.x, 0.0, turned.y), start[3])


func _dragged(start: Array, downwind: Vector3, upwind: float) -> void:
	var player := world.player
	var planter := spawn_device(&"planter", 0.0, 1.2, false)
	var floats := player.global_position + downwind * 3.0
	planter.global_position = Vector3(floats.x, world.height_under(floats) + 1.5, floats.z)
	fit_part(planter, &"hover_tray")
	fit_part(planter, &"battery")
	var lies := player.global_position - downwind * upwind
	lies.y = world.height_under(lies)
	var cable: StrongCable = Catalog.cable(world, lies, true)
	var fitted := cable.plugs[1]
	planter.fit(fitted, planter.sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0])
	var plug := cable.plugs[0]
	var port: RopeEnd = cable.rope.b
	var seen := {"closing": -INF, "fastest": 0.0, "port": 0.0, "stretched": 0.0}
	for i in roundi(SECONDS * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		# The port whirls as the planter turns: that's what drags the plug.
		var centre := planter.global_transform * planter.center_of_mass
		var dragging := planter.linear_velocity + planter.angular_velocity.cross(port.global_position - centre)
		var along := (port.global_position - plug.global_position).normalized()
		seen.closing = maxf(seen.closing, (plug.linear_velocity - dragging).dot(along))
		seen.fastest = maxf(seen.fastest, Vector2(plug.linear_velocity.x, plug.linear_velocity.z).length())
		seen.port = maxf(seen.port, Vector2(dragging.x, dragging.z).length())
		seen.stretched = maxf(seen.stretched, plug.global_position.distance_to(port.global_position) / cable.length)
	var at := "%+.0f,%+.0f, wind %+.0f°, %.0f m upwind" % start
	print("%s: stretched to %.2f of its length%s; the plug at most %.2f m/s (the port %.2f), closing on the port at %.2f"
		% [at, seen.stretched, "" if cable.rope != null else " and tore", seen.fastest, seen.port, seen.closing])
	check(seen.closing < FLUNG, "%s: dragged, never slung at the port (%.2f m/s)" % [at, seen.closing])
	check(seen.fastest < WIND, "%s: never faster than the wind (%.2f m/s)" % [at, seen.fastest])
	world.ropes.clear()
	if is_instance_valid(fitted):
		fitted.free()
	for node in world.content.get_children():
		if node is RigidBody3D or node is Cable:
			node.free()
	await physics_frames(2)
