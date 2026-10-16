extends DeviceProbe
## Power probe 7: a strong cable is a rope too. In a 20 m/s wind a floating
## planter on a strong cable to a staked turbine stays on the end of it, joined
## and powered; the same rig on a common cable pops a plug and blows away. And
## holding a strong cable's plug, it's you the planter pulls on.

const WIND := 20.0


func run() -> void:
	await load_world(1234, false)
	var tuning := Tuning.current()
	tuning.prevailing_speed = WIND
	tuning.storm_outflow_speed = 0.0
	world.weather.field = WeatherField.new(world.run_seed, tuning)
	var downwind := Vector3(world.weather.field.prevailing_at(world.time).x, 0.0,
		world.weather.field.prevailing_at(world.time).y).normalized()
	world.time_warp = 0.0
	var strong := _rig(true, Vector3(downwind.z, 0, -downwind.x) * 6.0, downwind)
	var common := _rig(false, Vector3(-downwind.z, 0, downwind.x) * 6.0, downwind)
	var held := await _held_rig(downwind)
	# As drawn: sampled last thing each frame, after everything has moved.
	var last := LastInFrame.new()
	last.each = func() -> void: _gap = maxf(_gap, _drawn_end_gap(held))
	add_child(last)
	var pulled := 0.0
	var farthest := 0.0
	for i in 20 * 60:
		await get_tree().physics_frame
		farthest = maxf(farthest, strong.turbine.global_position.distance_to(strong.planter.global_position))
		pulled = maxf(pulled, (world.player.get_meta(&"rope_drag", Vector3.ZERO) as Vector3).length())
	var reach: float = strong.cable.length * (1.0 + strong.cable.rope.max_stretch) + 1.5 if strong.cable.rope != null else 0.0
	print("strong: farthest %.2f m (reach %.2f), joined %s, powered %s; common: %.1f m off, joined %s"
		% [farthest, reach, strong.cable.joined().size() == 2, strong.planter.powered,
			common.turbine.global_position.distance_to(common.planter.global_position), common.cable.joined().size() == 2])
	check(strong.cable.rope != null, "the strong cable didn't snap")
	check(farthest <= reach, "the planter stayed on the end of the strong cable (%.2f of %.2f m)" % [farthest, reach])
	check(strong.cable.joined().size() == 2 and strong.planter.powered, "still joined and powered")
	check(common.cable.joined().is_empty(), "the common cable popped a plug")
	check(common.turbine.global_position.distance_to(common.planter.global_position) > 15.0,
		"and its planter blew away")
	check(world.player.hands.held == held.plug, "you held on to the plug")
	check(pulled > 0.0, "holding it, the planter pulled on you (%.3f m/s a tick)" % pulled)
	check(_gap < 0.05, "the drawn cable runs to the plug in your hand (%.3f m off at worst)" % _gap)
	world.player.hands.drop()
	await physics_frames(5)
	world.player.remove_meta(&"rope_drag")
	await physics_frames(5)
	check((world.player.get_meta(&"rope_drag", Vector3.ZERO) as Vector3).length() == 0.0,
		"let go, it pulls on you no more")


var _gap := 0.0


## Runs after every other node's _process in a frame.
class LastInFrame extends Node:
	var each: Callable

	func _ready() -> void:
		process_priority = 1000

	func _process(_delta: float) -> void:
		each.call()


## How far the drawn cable's nearer end is from where the held plug ties on.
func _drawn_end_gap(held: Dictionary) -> float:
	var cable: StrongCable = held.cable
	if cable.rope == null or world.player.hands.held != held.plug:
		return 0.0
	var points := cable.rope.strand.shown()
	var tip: Vector3 = held.plug.global_transform * StrongCable.END_AT
	return minf(points[0].distance_to(tip), points[points.size() - 1].distance_to(tip))


## A floating planter 3 m downwind of you on a strong cable, its other plug in your hand.
func _held_rig(downwind: Vector3) -> Dictionary:
	var player := world.player
	var planter := spawn_device(&"planter", 0.0, 1.2, false)
	# Over the sand where it floats, not over your feet: the dunes rise.
	var floats := player.global_position + downwind * 3.0
	planter.global_position = Vector3(floats.x, world.height_under(floats) + 1.5, floats.z)
	fit_part(planter, &"hover_tray")
	fit_part(planter, &"battery")
	var lies := player.global_position - downwind * 1.0
	lies.y = world.height_under(lies)
	var cable := Catalog.cable(world, lies, true)
	planter.fit(cable.plugs[1], planter.sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0])
	var plug := cable.plugs[0]
	await physics_frames(30)
	# Look down at the plug lying by your feet and take it, aiming as you reach:
	# the wind slides a light plug along the sand.
	var eye := player.camera.global_position
	var to := plug.global_position - eye
	player.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	player.camera.rotation = Vector3(atan2(to.y, Vector2(to.x, to.z).length()), 0.0, 0.0)
	var took := player.hands.grab()
	if not took:
		# It fails now and then on CI only; say where the plug was.
		print("the plug: %.2f m off, %.3f m over the sand, moving %.2f m/s; %d rescued so far" % [
			plug.global_position.distance_to(eye), plug.global_position.y - world.height_under(plug.global_position),
			plug.linear_velocity.length(), world.rescued])
	check(took, "you pick up the strong cable's plug")
	return {"planter": planter, "cable": cable, "plug": plug}


## A staked turbine and a floating planter 4 m downwind of it, cabled port to port.
func _rig(strong: bool, offset: Vector3, downwind: Vector3) -> Dictionary:
	var turbine := spawn_device(&"turbine", 0.0, 0.2, false)
	turbine.global_position += offset
	turbine.freeze = true
	fit_part(turbine, &"battery")
	var planter := spawn_device(&"planter", 0.0, 1.2, false)
	planter.global_position = turbine.global_position + downwind * 4.0 + Vector3.UP * 1.2
	fit_part(planter, &"hover_tray")
	fit_part(planter, &"battery")
	var cable := Catalog.cable(world, turbine.global_position + Vector3.UP, strong)
	for pair: Array in [[turbine, cable.plugs[0]], [planter, cable.plugs[1]]]:
		var end: Device = pair[0]
		end.fit(pair[1], end.sockets().filter(func(s: Socket) -> bool: return s.kind == &"port")[0])
	return {"turbine": turbine, "planter": planter, "cable": cable}
