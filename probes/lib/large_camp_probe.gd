class_name LargeCampProbe
extends SailProbe
## Shared real 108-frame L-deck, and main-thread CPU accounting over real ticks.

var marker: HomeBeacon
var shelter: ShieldGenerator
var cells := {}
var _clock_hz := 0.0


func large_camp(light := false) -> void:
	await load_sailing()
	var start := flat_spot(open.x, open.z, 18.0)
	var location := Vector2(world.world_x(start.x), world.world_z(start.z))
	follow(start)
	await settle()
	start = Vector3(world.engine_x(location.x), world.height_at(location.x, location.y), world.engine_z(location.y))
	deck = piece(start)
	deck.freeze = true
	cells[Vector2i.ZERO] = deck
	for z in 12:
		for x in 12:
			var cell := Vector2i(x, z)
			if cell == Vector2i.ZERO or x >= 6 and z >= 6:
				continue
			var from := cell - Vector2i.RIGHT if x > 0 else cell - Vector2i.DOWN
			var next := Catalog.device(&"chassis") as Chassis
			deck.join(next, ring(deck, from, cell - from), 0)
			cells[cell] = next
	var i := 0
	for cell: Vector2i in cells:
		var frame := cells[cell] as Chassis
		if not light or i % 6 == 0 or i % 12 == 3:
			_mount(&"hover_tray" if (i % 12 == 3 if light else i % 2 == 1) else &"skates", frame, Chassis.BOTTOM)
		if i % (18 if light else 6) == 0:
			_mount(&"battery", frame, Chassis.TOP, Vector2(0.3, 0.3))
		if i % (14 if light else 6) == (7 if light else 3):
			var ids := [&"home_beacon", &"shield", &"planter", &"condenser", &"solar_panel", &"radio"]
			var body := _mount(ids[(i / (14 if light else 6)) % ids.size()], frame)
			if body is HomeBeacon:
				marker = body
			if body is ShieldGenerator:
				shelter = body
		i += 1
	mast = Rig.make([&"mast", [&"sail"]]) as Mast
	Stick.put(deck, deck, Chassis.TOP, Vector2.ZERO, PI, mast)
	_mount(&"hook", cells[Vector2i(1, 1)])
	var sheet := Line.between(world, mast._tie(), deck.free_tie(mast.global_position), 0.1)
	mast.rig_sheet(sheet)
	_mount(&"hook", cells[Vector2i(2, 1)])
	hoist(45.0)
	deck.rest(true)
	deck.global_position = start + Vector3.UP * 0.5
	deck.freeze = false
	check(deck.pieces().size() == 108, "the camp has all 108 joined chassis")
	speed_up(2)
	await sail_for(4.0)
	speed_up(1)
	Engine.max_fps = 60
	if OS.get_name() == "Linux":
		var output := []
		if OS.execute("getconf", ["CLK_TCK"], output) == 0:
			_clock_hz = float(output[0])
		check(_clock_hz > 0.0, "the budget runner exposes its CPU clock rate")
	print("LARGE CAMP pieces=%d mass=%.1f skates=%d trays=%d batteries=%d mounted=%d" % [
		deck.pieces().size(), deck.mass, deck.parts().filter(func(p: Part) -> bool: return p.get_meta(&"catalog", &"") == &"skates").size(),
		deck.parts().filter(func(p: Part) -> bool: return p.get_meta(&"catalog", &"") == &"hover_tray").size(),
		deck.batteries().size(), deck.mounted().size()])


func _mount(id: StringName, frame: Chassis, face := Chassis.TOP, at := Vector2.ZERO) -> RigidBody3D:
	var body: RigidBody3D = Catalog.part(id) if Catalog.PARTS.has(id) else Catalog.device(id)
	world.content.add_child(body)
	Stick.put(deck, frame, face, at, 0.0, body)
	return body


func main_cpu_ms() -> float:
	if _clock_hz <= 0.0:
		return -1.0
	var file := FileAccess.open("/proc/thread-self/stat", FileAccess.READ)
	var stat := file.get_buffer(4096).get_string_from_utf8() if file != null else ""
	var fields := stat.substr(stat.rfind(") ") + 2).split(" ", false)
	if fields.size() < 13:
		check(false, "main-thread CPU counter is readable")
		return -1.0
	return (float(fields[11]) + float(fields[12])) * 1000.0 / _clock_hz


func measure(label: String, budget_ms: float, follow_camp := true) -> Dictionary:
	await simulate(2.0)
	var physics := PackedFloat64Array()
	var ropes_ms := PackedFloat64Array()
	var runners := PackedFloat64Array()
	var rest := PackedFloat64Array()
	var cpu := main_cpu_ms()
	var began := Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))
	for i in 480:
		await get_tree().physics_frame
		if follow_camp:
			follow(deck.global_position + Vector3(0, 0, 15))
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		ropes_ms.append(world.ropes.tick_ms)
		runners.append(deck.glider.cost_us / 1000.0 if deck.glider != null else 0.0)
		rest.append(deck.rest_us / 1000.0)
	var cpu_tick := (main_cpu_ms() - cpu) / 480.0 if cpu >= 0.0 else -1.0
	physics.sort()
	ropes_ms.sort()
	runners.sort()
	rest.sort()
	print("LARGE COST %s main_cpu=%.3f ms/tick physics_p50=%.3f p95=%.3f rope_p50=%.3f runner_p50=%.3f rest_p50=%.3f distance=%.3f heel=%.2f" % [
		label, cpu_tick, physics[240], physics[456], ropes_ms[240], runners[240], rest[240], Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z)).distance_to(began), heel()])
	if cpu_tick >= 0.0:
		metric(label + " main-thread CPU per tick", cpu_tick, "ms", budget_ms)
		if budget_ms > 0.0:
			check(cpu_tick < budget_ms, label + " stays inside its tick budget")
	else:
		print("Main-thread CPU budget needs Linux accounting; physics elapsed is diagnostic only")
	return {"cpu":cpu_tick,"physics":physics[240],"distance":Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z)).distance_to(began)}


func before_finish() -> void:
	super()
	# Retire this fixture’s last native snapshot before the scene shuts down.
	if is_instance_valid(world):
		world.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(deck):
		RopeArticulation.forget(deck)
