extends MenuProbe
## Runs alone
## Original loaded pod gear stays a live Home through a remote storm and disk resume.

func run() -> void:
	var tuning := Tuning.current()
	tuning.run_seed = 9876
	tuning.salvage = false
	tuning.surveyor_preflight.enabled = true
	tuning.storm_threshold = 2.0
	tuning.prevailing_speed = 0.0
	tuning.prevailing_sway = 0.0
	tuning.storm_outflow_speed = 0.0
	main = MAIN.instantiate()
	main.opens_on_menu = false
	add_child(main)
	world = main.world()
	var deadline := Time.get_ticks_msec() + 60000
	while (world.arrival == null or not is_instance_valid(world.arrival.preflight)) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(world.arrival != null and is_instance_valid(world.arrival.preflight), "the actual preparation opens")
	if world.arrival == null or not is_instance_valid(world.arrival.preflight):
		return
	await physics_frames(5)
	var prep := world.arrival.preflight
	var original := SurveyorRecovery.named(world)
	# Script original cargo placement to isolate downstream continuity, not packing discovery.
	Stick.put(prep.ship.pod.deck, prep.ship.pod_parts[&"floor_b"], Chassis.TOP, Vector2(0.34, -0.04), 0.0, original[&"beacon"])
	Stick.put(prep.ship.pod.deck, prep.ship.pod_parts[&"side_front_b"], Chassis.TOP, Vector2.ZERO, 0.0, original[&"panel"])
	await physics_frames(3)
	check(Stick.why_not(prep.ship.pod.deck, prep.ship.pod_parts[&"floor_b"], Chassis.TOP, original[&"beacon"]) == "", "the original beacon uses a legal upward mounting face")
	check(PreflightCargo.loaded(world, prep.ship).has(&"beacon") and PreflightCargo.loaded(world, prep.ship).has(&"panel"),
		"the actual optional beacon and panel are physically loaded")
	if not PreflightCargo.loaded(world, prep.ship).has(&"beacon") or not PreflightCargo.loaded(world, prep.ship).has(&"panel"):
		return
	var ids := {}
	for role in [&"floor_a", &"shield", &"camp_cell", &"beacon", &"panel", &"food"]:
		ids[role] = original[role].get_instance_id()
	_stand(Vector3(prep.ship.computer_at.global_position.x, prep.ship.global_position.y + 0.02,
		prep.ship.computer_at.global_position.z + 0.9), prep.ship.computer_at.global_position)
	await physics_frames(2)
	press(&"interact")
	await get_tree().create_timer(0.6).timeout
	check(prep.computer_open(), "the physical planning screen opens")
	if not prep.computer_open():
		return
	prep.computer.ui._confirm.pressed.emit()
	press(&"ui_cancel")
	await get_tree().create_timer(0.6).timeout
	_stand(prep.ship.pod_entry_at.global_position + Vector3(0, 0, 0.6), prep.ship.pod_entry_at.global_position + Vector3.UP * 0.5)
	await physics_frames(2)
	press(&"interact")
	press(&"interact")
	check(world.arrival_state.phase == &"ejection", "the real selected pod launches")
	if world.arrival_state.phase != &"ejection":
		return
	deadline = Time.get_ticks_msec() + 60000
	while world.arrival_state.phase != &"recovery" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(world.arrival_state.phase == &"recovery", "the actual opening reaches recovery")
	var nodes := SurveyorRecovery.named(world)
	for role in ids:
		check(is_instance_valid(nodes.get(role)) and nodes[role].get_instance_id() == ids[role], "the original equipment survives this seeded opening: %s" % role)
		if not is_instance_valid(nodes.get(role)):
			return
	var floor := nodes[&"floor_a"] as Chassis
	var deck := floor.deck if floor.deck != null else floor
	_stand(deck.global_position + Vector3(0, 0.5, 3), deck.global_position)
	var marker := nodes[&"beacon"] as HomeBeacon
	for pair: Array in [[&"camp_cell", Vector2(-0.2, -0.2)], [&"shield", Vector2(-0.2, 0.2)], [&"beacon", Vector2(0.28, -0.25)]]:
		_remount(nodes[pair[0]], deck, floor, pair[1])
	_remount(nodes[&"panel"], deck, nodes[&"floor_b"], Vector2.ZERO)
	var shield := nodes[&"shield"] as ShieldGenerator
	_stand(shield.global_position + Vector3(0, 0.65, 0.7), shield.global_position)
	await physics_frames(5)
	press(&"interact")
	await physics_frames(90)
	check(shield.running(), "the original pod cell powers its actual recovered shield")
	_stand(marker.global_position + Vector3(0.1, 0.9, 0.1), marker.global_position)
	await physics_frames(5)
	press(&"interact")
	check(world.home.beacon == marker, "ordinary use selects the actual original beacon")
	if world.home.beacon != marker:
		return
	deadline = Time.get_ticks_msec() + 60000
	while not world.home.supported and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	check(world.home.beacon == marker and world.home.supported, "ordinary beacon use marks and supports the original pod")
	if not world.home.supported:
		return
	var food := nodes[&"food"] as Supply
	check(world.home.contains(food) and food.get_parent() == world.content, "the original loose supply belongs to Home")
	var at := Vector2(world.world_x(deck.global_position.x), world.world_z(deck.global_position.z))
	var point := world.geographic_at(deck.global_position)
	var amount := food.amount
	var cell := nodes[&"camp_cell"] as Battery
	var charge := cell.charge_wh
	check(world.home.nav().live, "the real beacon initially transmits a live fix")
	teleport(at.x + 2100.0, at.y)
	await settle()
	check(not world.home.nav().live and world.home.nav().metres > 2000.0, "scouting beyond reception retains the actual last-known fix")
	# Controlled ordinary field isolates remote resource continuity from route selection.
	tuning.storm_ramp = 1000.0
	tuning.storm_threshold = -600.0
	world.weather.field = WeatherField.new(world.run_seed, tuning)
	var durability := shield.durability
	var used := world.power.used_wh
	await physics_frames(360)
	check(world.weather.field_storm(shield.global_position) > 0.5 and world.weather.felt_storm(food.global_position) < 0.001,
		"the real remote storm reaches Home while its original bubble shelters supplies")
	check(shield.running() and world.power.used_wh > used and cell.charge_wh < charge and shield.durability == durability,
		"ordinary remote storm ticks consume the original cell without sheltered wear")
	check(not deck.freeze and not food.freeze and world.terrain.has_collision_at(at.x, at.y), "the remote pod stays physically live on real collision")
	var remote_used := world.power.used_wh - used
	var remote_draw := charge - cell.charge_wh
	var manifest: Dictionary = world.arrival_state.duplicate(true)
	charge = cell.charge_wh
	check(main.save_run(), "the distant expedition saves to the real disk store")
	var disk: Dictionary = saves().held()
	var disk_roles := {}
	_count_roles(disk, disk_roles)
	check(disk_roles.values().all(func(count: int) -> bool: return count == 1), "the distant disk contains each actual original role once")
	await main.resume()
	world = main.world()
	nodes = SurveyorRecovery.named(world)
	check(world.arrival_state.equipment == manifest.equipment and world.arrival_state.structure == manifest.structure,
		"far disk resume preserves the original impact and recovery history")
	check(nodes.keys().size() == disk.arrival.node_refs.size() and world.home.supported and world.home.contains(nodes[&"food"]),
		"far disk resume reconnects the same original role set and claimed loose supply")
	var restored_roles := {}
	_count_roles(Snapshot.take(world), restored_roles)
	check(restored_roles == disk_roles, "restoration does not add duplicate original bodies")
	food = nodes[&"food"]
	cell = nodes[&"camp_cell"]
	shield = nodes[&"shield"]
	deck = world.home.root
	check(food.amount == amount and cell.charge_wh <= charge and cell.charge_wh > charge - 1.0 and shield.running(),
		"restore keeps real supplies and charge without refilling or dropping protection")
	check(not world.home.nav().live and world.terrain.has_collision_at(at.x, at.y)
		and Sphere.angle(point, world.geographic_at(deck.global_position)) < 0.00001,
		"the restored last-known Home retains its own geography and collision")
	teleport(at.x, at.y - 3.0)
	await settle()
	await physics_frames(60)
	check(world.home.nav().live and shield.running() and world.home.contains(food) and world.rescued == 0,
		"return reaches the same live protected Home without a ground rescue")
	print("EXPEDITION COMPLETE roles=", nodes.size(), " members=", world.home.members.size(), " remote_used_wh=", remote_used, " cell_draw_wh=", remote_draw, " charge=", cell.charge_wh, " food=", food.amount)

func _stand(at: Vector3, toward: Vector3) -> void:
	world.teleport(world.player, Transform3D(Basis.IDENTITY, at))
	world.player.velocity = Vector3.ZERO
	world.player.camera.look_at(toward)

func _remount(body: RigidBody3D, deck: Chassis, piece: Chassis, at: Vector2) -> void:
	if body is Part and body.socket != null:
		(body.socket.get_parent() as Device).take(body.socket)
	elif body is Device and body.host() != null:
		body.host().dismount(body.host().seat_of(body))
	world.player.hands.hold(body)
	Stick.put(deck, piece, Chassis.TOP, at, 0.0, world.player.hands.stow())

func _count_roles(value: Variant, counts: Dictionary) -> void:
	if value is Dictionary:
		if value.has("arrival_uid"):
			var role: StringName = value.arrival_uid
			counts[role] = int(counts.get(role, 0)) + 1
		for child: Variant in value.values():
			_count_roles(child, counts)
	elif value is Array:
		for child: Variant in value:
			_count_roles(child, counts)
