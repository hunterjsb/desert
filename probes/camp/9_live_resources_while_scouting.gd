extends DeckProbe
## Runs alone
## Real power ticks and loose camp membership survive a far save and return.

var camp_deck: Chassis
var camp_shield: ShieldGenerator
var camp_cell: Battery
var loose: Part
var home_at: Vector2

func run() -> void:
	Tuning.current().storm_threshold = 2.0
	await load_hands()
	var start := flat_spot(world.player.global_position.x, world.player.global_position.z - 3.0, 3.0)
	camp_deck = piece(start)
	var extra := piece(start + Vector3.RIGHT)
	camp_deck.join(extra, ring(camp_deck, Vector2i.ZERO, Vector2i.RIGHT), 0)
	camp_cell = fit_part(camp_deck, &"battery") as Battery
	camp_cell.charge_wh = camp_cell.capacity() * 0.5
	var solar := Catalog.part(&"solar_panel")
	world.content.add_child(solar)
	Stick.put(camp_deck, extra, Chassis.TOP, Vector2.ZERO, 0.0, solar)
	camp_shield = Catalog.device(&"light_shield") as ShieldGenerator
	world.content.add_child(camp_shield)
	Stick.put(camp_deck, camp_deck, Chassis.TOP, Vector2(-0.15, -0.15), 0.0, camp_shield)
	var beacon := Catalog.device(&"home_beacon") as HomeBeacon
	world.content.add_child(beacon)
	Stick.put(camp_deck, camp_deck, Chassis.TOP, Vector2(0.3, 0.2), 0.0, beacon)
	loose = Catalog.part(&"coalcane_bundle")
	world.content.add_child(loose)
	loose.global_position = start + Vector3(0, 0.5, 1)
	world.time = fposmod(0.4 - world.weather.day.time_of_day(0.0, world.moon.longitude), 1.0) * world.tuning.day_minutes * 60.0
	camp_shield.stand(true)
	await simulate(2.0)
	look(beacon.global_position + Vector3(0.4, 0.5, 0.8), beacon.global_position)
	await simulate(0.1)
	check(hands.interact() and world.home.beacon == beacon, "mark through ordinary beacon use")
	await _supported()
	home_at = Vector2(world.world_x(camp_deck.global_position.x), world.world_z(camp_deck.global_position.z))
	check(world.home.contains(loose) and camp_shield.running(), "loose claimed supply belongs to a powered shelter")
	var origin_y := camp_deck.global_position.y
	var home_point := world.geographic_at(camp_deck.global_position)
	teleport(home_at.x + 2100.0, home_at.y)
	await settle()
	var remote_point := world.geographic_at(camp_deck.global_position)
	check(Sphere.angle(home_point, remote_point) < 0.00001
		and Sphere.angle(remote_point, world.geographic_at(world.player.global_position)) > 0.01,
		"the real retained Home keeps its geographic place as the player scouts")
	var expected_light := world.weather.day.sunlight(world.time, Sphere.latitude(home_point), Sphere.longitude(home_point))
	var expected_temperature := world.weather.temperature_under(0.0, world.time, home_point)
	check(absf(world.weather.felt_light(camp_deck.global_position) - expected_light) < 0.001
		and absf(world.weather.field_temperature(camp_deck.global_position) - expected_temperature) < 0.001,
		"the live camp samples the day and temperature at its own place")
	var made := world.power.generated_wh
	var used := world.power.used_wh
	var cell_before := camp_cell.charge_wh
	var charge := world.power.stored_wh()
	var spill := world.power.spilled_wh
	await simulate(10.0)
	var generated := world.power.generated_wh - made
	var consumed := world.power.used_wh - used
	var cell_delta := camp_cell.charge_wh - cell_before
	check(generated > 0.0 and consumed > 0.0 and camp_shield.running(), "ordinary remote ticks both generate and consume real power")
	check(camp_cell.charge_wh > cell_before + 0.01, "the actual remote camp cell receives its solar output")
	check(absf(world.power.stored_wh() - charge - generated + consumed + world.power.spilled_wh - spill) < 0.001,
		"live remote generation, demand and battery storage conserve energy")
	check(not camp_deck.freeze and not loose.freeze and absf(camp_deck.global_position.y - origin_y) < 0.3,
		"remote bodies remain physically supported and unfrozen")
	camp_shield.stand(false)
	await simulate(1.0)
	check(world.home.contains(loose) and world.home.supported and not camp_shield.running(), "shutdown preserves the loose Home member")
	check(world.rescued == 0, "the active distant camp needs no missing-ground rescue")
	var saves := get_node(^"/root/Saves")
	check(saves.save(world), "save the live camp from far away")
	await _resume_far(saves)
	camp_deck = world.home.root
	var shields := world.home.members.filter(func(body: RigidBody3D) -> bool: return body is ShieldGenerator)
	var supplies := world.home.members.filter(func(body: RigidBody3D) -> bool: return body.get_meta(&"catalog", &"") == &"coalcane_bundle")
	check(world.home.supported and world.terrain.has_collision_at(home_at.x, home_at.y)
		and shields.size() == 1 and supplies.size() == 1, "far restore reconnects one supported shield and loose supply")
	if shields.size() != 1 or supplies.size() != 1:
		return
	camp_shield = shields[0]
	loose = supplies[0]
	check(not camp_shield.on and not loose.freeze, "restoring preserves the shutdown and live member")
	teleport(home_at.x, home_at.y + 2.0)
	await settle()
	camp_shield.stand(true)
	await simulate(1.0)
	check(camp_shield.running() and world.home.contains(loose) and not camp_deck.freeze, "return reaches the same working camp")
	print("LIVE HOME generated=%.6fWh used=%.6fWh delta_cell=%.6fWh members=%d chunks=%d collision=%d rescued=%d" % [generated, consumed,
		cell_delta, world.home.members.size(), world.terrain._chunks.size(), world.terrain.collision_count(), world.rescued])

func _supported() -> void:
	var until := Time.get_ticks_msec() + 60000
	while not world.home.supported and Time.get_ticks_msec() < until:
		await get_tree().process_frame
	check(world.home.supported, "the full real Home footprint becomes ready")

func _resume_far(saves: Node) -> void:
	var seed_was := world.run_seed
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	world = WORLD_SCENE.instantiate()
	world.run_seed = seed_was
	add_child(world)
	world.player.set_physics_process(false)
	await settle()
	check(saves.restore(world), "restore the distant saved camp")
	if saves.restoring:
		await saves.restored
	hands = world.player.hands
