extends ArrivalSaveProbe
## Reconstructing a held arrival object must not replay its recovery action or deed.
func run() -> void:
	await prepare_arrival()
	world.arrival_state.merge({"phase": &"recovery", "materialized": true}, true)
	var stored := Catalog.part(&"canister")
	stored.set_meta(&"arrival_uid", &"water")
	world.player.suit.carried.append(stored)
	var cell := Catalog.part(&"battery")
	world.content.add_child(cell)
	cell.global_position = world.player.global_position + Vector3.UP
	cell.set_meta(&"arrival_uid", &"camp_cell")
	world.set_meta(&"arrival_restoring", true)
	hands.hold(cell)
	world.remove_meta(&"arrival_restoring")
	var expected := world.arrival_state.duplicate(true)
	var profile := get_node(^"/root/Profile")
	var deeds: Dictionary = profile.deeds()
	check(saves.save(world), "held arrival object saved")
	check(await resume_arrival(), "held arrival object resumed")
	check(hands.held == world.arrival_nodes.get(&"camp_cell") and observer.guarded_grips == 1 and observer.unguarded_grips == 0,
		"the same held object reconnects while recovery is suppressed")
	check(world.player.suit.carried.has(world.arrival_nodes.get(&"water")),
		"stowed arrival equipment keeps its own stable identity")
	check(world.arrival_state == expected and profile.deeds() == deeds,
		"held reconstruction changes neither recovered flags nor deeds")
