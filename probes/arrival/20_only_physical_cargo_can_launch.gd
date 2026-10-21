extends MovementProbe
## Readiness and impact resolve only actual pod contents, never a menu or forgotten rack item.

func run() -> void:
	await load_moving()
	world.time_warp = 0.0
	var ship := SurveyorShip.new()
	world.add_child(ship)
	ship.setup(world, Transform3D(Basis.IDENTITY, player.global_position + Vector3.UP * 60.0))
	player.set_physics_process(false)
	world.teleport(player, ship.spawn_at.global_transform)
	var state := {"phase": &"preflight", "preflight": {"version": 1, "launched": false},
		"landing_point": Sphere.point(world.moon.latitude, world.moon.longitude)}
	var nodes := PreflightCargo.stage(world, ship, state)
	await physics_frames(30)
	print("CARGO staged", nodes.size(), " loaded", PreflightCargo.loaded(world, ship), " readiness", PreflightCargo.readiness(world, ship))
	for uid in PreflightCargo.REQUIRED:
		if nodes.has(uid):
			print("BOX ",uid," ",PreflightCargo.bounds_in(nodes[uid],ship.global_transform), " cargo",ship.cargo_bounds," seat",PreflightCargo.seat_bounds(world,ship))
	check(nodes.size() == SurveyorManifest.STRUCTURE.size() + SurveyorManifest.EQUIPMENT.size(), "every available object is physical exactly once")
	if nodes.is_empty():
		return
	check(PreflightCargo.readiness(world, ship).is_empty(), "the visible preloaded emergency stores are ready")
	check(not PreflightCargo.loaded(world, ship).has(&"board"), "the rack board is not loaded implicitly")
	var water := nodes[&"water"] as Supply
	water.drain(water.amount * 0.25)
	var amount := water.amount
	var snapshot := state.duplicate(true)
	check(PreflightCargo.seal(world, ship, state, {}).is_empty() and state == snapshot, "an invalid profile refuses without committing state")
	var invalid := state.duplicate(true)
	invalid.landing_point = Vector3.ZERO
	var invalid_before := invalid.duplicate(true)
	check(PreflightCargo.seal(world, ship, invalid, {"id": &"standard"}).is_empty() and invalid == invalid_before,
		"an invalid geographic point refuses without mutation")
	check(PreflightCargo.seal(world, ship, state, {"id": &"standard", "extra_survival": 2.0}).is_empty() and state == snapshot,
		"an invalid impact profile refuses without mutation")
	var identities := nodes.values().map(func(body: Node) -> int: return body.get_instance_id())
	check(PreflightCargo.stage(world, ship, state).values().map(func(body: Node) -> int: return body.get_instance_id()).all(func(id: int) -> bool: return identities.has(id)) and water.amount == amount,
		"restaging neither duplicates objects nor refills supplies")
	var where := water.global_transform
	world.teleport(water, ship.spawn_at.global_transform)
	check(not PreflightCargo.readiness(world, ship).is_empty(), "removing a required physical store blocks launch")
	world.teleport(water, ship.global_transform * Transform3D(Basis.IDENTITY,
		Vector3(ship.cargo_bounds.end.x - 0.02, ship.cargo_bounds.position.y + 0.06, ship.cargo_bounds.position.z + 0.1)))
	check(not PreflightCargo.loaded(world, ship).has(&"water"), "an origin inside the pod cannot hide a partly protruding body")
	world.teleport(water, where)
	var cell := nodes[&"camp_cell"] as Battery
	var charge := cell.charge_wh
	cell.charge_wh = 0.0
	check(not PreflightCargo.readiness(world, ship).is_empty(), "an empty emergency cell blocks launch")
	cell.charge_wh = charge
	var profile := {"id": &"shallow", "extra_survival": 1.0, "outer_survival": 1.0, "frame_survival": 1.0,
		"device_durability": Vector2.ONE, "chassis_durability": Vector2.ONE}
	var sealed := PreflightCargo.seal(world, ship, state, profile)
	check(not sealed.is_empty() and sealed.preflight.launched, "ready physical cargo seals once")
	if not sealed.is_empty():
		check(not sealed.equipment.any(func(entry: Dictionary) -> bool: return entry.uid == &"board"), "the omitted board never enters the impact manifest")
		check(water.amount == amount and cell.charge_wh == charge, "seal preserves actual contents and charge")
		check(PreflightCargo.seal(world, ship, sealed, {"id": &"other"}) == sealed, "a repeated seal cannot reroll the selected profile")
	if wind != null:
		wind.override = Callable()
	remove_child(world)
	world.queue_free()
	await physics_frames(4)
