extends MenuProbe
## Arrival selection must not take over old saves, developer scenarios or other origins.

func run() -> void:
	var tuning := Tuning.current()
	# Exercise the saved automatic opening; preparation has separate acceptance.
	tuning.surveyor_preflight["enabled"] = false
	tuning.run_seed = 1234
	tuning.salvage = false
	_short_flight()
	await open_main()
	print("COMPAT homesteader")
	await main.new_game(false, false, Kit.named(&"homesteader"))
	world = main.world()
	await _kit_ready()
	check(not world.arrival_enabled and world.arrival_state.is_empty() and _inputs_live(), "another origin keeps ordinary movement and kit flow")
	check(_carried() == _kit_carried(Kit.named(&"homesteader")), "the Homesteader receives only its own carried kit")

	print("COMPAT legacy-save")
	# A real no-arrival Surveyor run supplies the old save's equipment and state.
	var legacy := main._make(Main.RUN)
	var old_world := legacy.get_node("World") as World
	old_world.kit = Kit.standard()
	old_world.arrival_enabled = false
	await main._into(legacy, false)
	world = main.world()
	await _kit_ready()
	var carried := _carried()
	check(carried == _kit_carried(Kit.standard()) and main.save_run(), "a pre-arrival Surveyor kit can be saved")
	var store := saves()
	var data: Dictionary = store.held()
	data.erase("arrival")
	check(SaveFile.write(store.path(), store.KIND, store.VERSION, data), "the legacy fixture contains no arrival record")
	await main.resume()
	world = main.world()
	check(not world.arrival_enabled and world.arrival == null and world.arrival_state.is_empty(), "legacy Surveyor resume starts no flight")
	check(_carried() == carried and Snapshot.take(world).things.size() == data.things.size() and _inputs_live(),
		"legacy resume preserves actual gear and normal input without a second grant")

	print("COMPAT scenario-cancel")
	# Catch the actual opening in orbit, then use Main's scenario transition.
	tuning.surveyor_arrival["orbit_s"] = 60.0
	var was_id := world.get_instance_id()
	main.new_game(false, false, Kit.standard())
	await _wait(func() -> bool: return main.world() != null and main.world().get_instance_id() != was_id and main.world().arrival != null and main.world().arrival.active(), "the real new Surveyor enters orbit")
	world = main.world()
	main.start_scenario(Scenarios.by_key("survive"))
	await faded_in()
	world = main.world()
	await _kit_ready(&"scenario_kit")
	check(not world.arrival_enabled and world.arrival_state.is_empty() and not world.counts_deeds and _inputs_live(),
		"a developer scenario cancels flight and restores movement, hands, suit and vitals")
	check(_carried() == _kit_carried(Kit.standard()) and SurveyorRecovery.named(world).is_empty(),
		"the scenario gets its old physical kit without pod survivors")
	print("COMPAT scenario-death")
	var seed_was := world.run_seed
	was_id = world.get_instance_id()
	world.player.vitals.hurt(1000.0)
	await _wait(func() -> bool: return main.world() != null and main.world().get_instance_id() != was_id, "scenario death begins its next run")
	world = main.world()
	await _kit_ready()
	check(not world.arrival_enabled and world.run_seed != seed_was and _inputs_live(), "scenario restart preserves its no-arrival flow on a new seed")

	print("COMPAT surveyor-death")
	_short_flight()
	await main.new_game(true, false, Kit.standard())
	world = main.world()
	check(world.arrival_enabled and world.arrival_state.get("phase", &"") == &"recovery", "the automatic Surveyor fixture still reaches physical recovery")
	seed_was = world.run_seed
	was_id = world.get_instance_id()
	world.player.vitals.hurt(1000.0)
	await _wait(func() -> bool: return main.world() != null and main.world().get_instance_id() != was_id, "Surveyor Ironman death begins its next run")
	world = main.world()
	check(world.arrival_enabled and world.run_seed != seed_was and world.arrival != null and world.arrival.active(),
		"Surveyor death propagates arrival selection to the new run")
	check(world.player.suit.carried.is_empty() and not world.player.is_physics_processing(),
		"the restarted flight holds movement without granting the legacy inventory")

func _short_flight() -> void:
	for phase in [&"orbit", &"ejection", &"descent", &"entry", &"landing"]:
		Tuning.current().surveyor_arrival[String(phase) + "_s"] = 0.12

func _kit_ready(tag: StringName = &"kit") -> void:
	await _wait(func() -> bool: return world.has_meta(tag), "the ordinary physical kit is ready")

func _inputs_live() -> bool:
	var player := world.player
	return player.is_physics_processing() and player.is_processing_unhandled_input() \
		and player.hands.is_processing_unhandled_input() and player.suit.is_processing_unhandled_input() \
		and player.vitals.is_physics_processing() and world.time_warp == 1.0

func _carried() -> Array[StringName]:
	var ids: Array[StringName] = []
	for body in world.player.suit.carried:
		ids.append(body.get_meta(&"catalog"))
	ids.sort()
	return ids

func _kit_carried(kit: Kit) -> Array[StringName]:
	var ids := kit.carried_ids()
	ids.sort()
	return ids

func _wait(ready: Callable, reason: String) -> void:
	var until := Time.get_ticks_msec() + 60000
	while not ready.call() and Time.get_ticks_msec() < until:
		await get_tree().physics_frame
	check(ready.call(), reason)
