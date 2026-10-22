extends DeckProbe
## Runs alone
## A loaded mixed-support camp must stay live and stable through a scouting return.

var camp: Chassis
var shield: ShieldGenerator
var planter: Planter
var loose: Part
var at: Vector2
var worst_spin := 0.0
var worst_speed := 0.0
var worst_tilt := 0.0
var watching := false


func run() -> void:
	await load_lines()
	var start := flat_spot(world.player.global_position.x, world.player.global_position.z - 5.0, 7.0)
	camp = piece(start)
	for z in 3:
		for x in 3:
			if x == 0 and z == 0:
				continue
			var from := Vector2i(x - 1, z) if x > 0 else Vector2i(0, z - 1)
			camp.join(piece(start), ring(camp, from, Vector2i.RIGHT if x > 0 else Vector2i.DOWN), 0)
	for p: Chassis in camp.pieces():
		_mount(&"skates" if p.cell in [Vector2i.ZERO, Vector2i(2, 2)] else &"hover_tray", p, Chassis.BOTTOM)
	var dock := _mount(&"power_box", Rig.piece(camp, Vector2i(2, 0))) as PowerBox
	for i in 4:
		var cell := fit_part(dock, &"battery") as Battery
		cell.charge_wh = cell.capacity() * 0.7
	_mount(&"condenser", camp)
	shield = _mount(&"shield", Rig.piece(camp, Vector2i(1, 1))) as ShieldGenerator
	var marker := _mount(&"home_beacon", Rig.piece(camp, Vector2i(0, 1))) as HomeBeacon
	_mount(&"radio", Rig.piece(camp, Vector2i(2, 1)))
	_mount(&"solar_panel", Rig.piece(camp, Vector2i(0, 2)))
	_mount(&"solar_panel", Rig.piece(camp, Vector2i(1, 2)))
	for socket in [ring(camp, Vector2i.ZERO, Vector2i.LEFT), ring(camp, Vector2i(2, 2), Vector2i.RIGHT),
			ring(camp, Vector2i(2, 1), Vector2i.RIGHT)]:
		camp.fit(Catalog.part(&"hook"), socket)
	var west := driven_stake(start + Vector3(-2.0, 0.0, 0.0))
	var east := driven_stake(start + Vector3(5.0, 0.0, 2.0))
	lay(camp, west, 0.5)
	lay(camp, east, 0.5)
	planter = floating(&"planter", start + Vector3(4.0, 0.0, 1.0)) as Planter
	planter.stored[&"coalcane_bundle"] = 4
	lay(planter, camp, 0.5)
	loose = Catalog.part(&"coalcane_bundle")
	world.content.add_child(loose)
	loose.global_position = start + Vector3(-0.8, 0.5, 1.0)
	world.time = fposmod(0.4 - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) * world.tuning.day_minutes * 60.0
	shield.stand(true)
	await simulate(5.0)
	watching = true
	look(marker.global_position + Vector3(-0.8, 0.6, 0.8), marker.global_position)
	await simulate(0.2)
	await _measure("near-unmarked")
	check(hands.interact() and world.home.beacon == marker, "ordinary beacon use marks the complete loaded camp")
	await settle()
	await simulate(1.0)
	check(world.home.supported and world.home.contains(planter) and world.home.contains(loose),
		"both tethered storage and the loose claimed supply belong to ready Home")
	check(camp.pieces().size() == 9 and camp.has_tray() and camp.glider != null and camp.hovering(),
		"all nine joined pieces carry the real mixed supports and powered lift")
	await _measure("near-marked")
	at = Vector2(world.world_x(camp.global_position.x), world.world_z(camp.global_position.z))
	var height := camp.global_position.y
	var stored := planter.stored.duplicate()
	var used := world.power.used_wh
	teleport(at.x + 2100.0, at.y)
	await settle()
	await _measure("remote-marked")
	check(world.home.supported and not camp.freeze and not planter.freeze and not loose.freeze,
		"the full remote camp remains on supported active physics")
	check(shield.running() and camp.hovering() and world.power.used_wh > used,
		"remote shelter and lift keep consuming ordinary power")
	check(planter.stored == stored and world.home.contains(loose), "storage and loose supply survive the scouting interval")
	check(absf(camp.global_position.y - height) < 0.3 and worst_spin < 0.3 and worst_speed < 1.0 and worst_tilt < 5.0,
		"the supported deck neither falls nor spins up during departure")
	teleport(at.x, at.y - 3.0)
	await settle()
	await simulate(1.0)
	check(shield.running() and camp.hovering() and world.home.supported and world.rescued == 0,
		"return reaches the same live shelter without a ground rescue")
	print("MEDIUM HOME pieces=%d members=%d items=%d mass=%.1fkg spin=%.4frad/s speed=%.4fm/s tilt=%.3fdeg rescued=%d" % [camp.pieces().size(),
		world.home.members.size(), world.home.work_count(), camp.mass, worst_spin, worst_speed, worst_tilt, world.rescued])


func _mount(id: StringName, p: Chassis, face := Chassis.TOP) -> RigidBody3D:
	var body: RigidBody3D = Catalog.part(id) if Catalog.PARTS.has(id) else Catalog.device(id)
	world.content.add_child(body)
	Stick.put(camp, p, face, Vector2.ZERO, 0.0, body)
	return body


func _watch() -> void:
	worst_spin = maxf(worst_spin, camp.angular_velocity.length())
	worst_speed = maxf(worst_speed, camp.linear_velocity.length())
	worst_tilt = maxf(worst_tilt, rad_to_deg(camp.global_basis.y.normalized().angle_to(Vector3.UP)))


func _physics_process(_delta: float) -> void:
	if watching and is_instance_valid(camp):
		_watch()


func _measure(label: String) -> void:
	# Engine time monitors are coarse estimates, not an isolated native solver profile.
	await simulate(0.5)
	var process := PackedFloat64Array()
	var physics := PackedFloat64Array()
	var active := 0
	for i in 240:
		await get_tree().physics_frame
		process.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		active = maxi(active, int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)))
	process.sort()
	physics.sort()
	print("MEDIUM COST %s process_ms p50=%.3f p95=%.3f max=%.3f physics_ms p50=%.3f p95=%.3f max=%.3f active_max=%d chunks=%d collision=%d" % [label,
		process[120], process[228], process[239], physics[120], physics[228], physics[239], active,
		world.terrain._chunks.size(), world.terrain.collision_count()])
