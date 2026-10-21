extends ArrivalSaveProbe
## Rerooting swaps body roles; saved references must follow each actual physical panel.
func run() -> void:
	await prepare_arrival()
	var rig := Rig.build(world.content, [[&"piece", Vector2i(1, 0)]])
	var deck := rig.deck
	deck.global_position = world.player.global_position + Vector3(0, 1, -4)
	deck.freeze = true
	var hatch := Rig.piece(deck, Vector2i(1, 0))
	deck.set_meta(&"arrival_uid", &"floor_a")
	hatch.set_meta(&"arrival_uid", &"hatch")
	PodShell.restore_skin(deck, &"heatshield")
	PodShell.restore_skin(hatch, &"armor")
	world.arrival_nodes = {&"floor_a": deck, &"hatch": hatch}
	world.arrival_state.merge({"phase": &"recovery", "materialized": true}, true)
	var floor := deck.detach(deck)
	floor.freeze = true
	var floor_pose := floor.global_transform
	var hatch_pose := deck.global_transform
	check(world.arrival_nodes[&"floor_a"] != floor, "the fixture exercises a stale pre-reroot lookup")
	check(saves.save(world), "rerooted panels saved")
	check(await resume_arrival(), "rerooted panels resumed")
	var kept_floor := world.arrival_nodes.get(&"floor_a") as Chassis
	var kept_hatch := world.arrival_nodes.get(&"hatch") as Chassis
	check(kept_floor != null and kept_hatch != null and kept_floor != kept_hatch
		and kept_floor.global_transform.is_equal_approx(floor_pose) and kept_hatch.global_transform.is_equal_approx(hatch_pose)
		and kept_floor.get_meta(&"pod_skin", &"") == &"heatshield" and kept_hatch.get_meta(&"pod_skin", &"") == &"armor",
		"saved identities and skins follow their physical panels instead of stale carrier references")
