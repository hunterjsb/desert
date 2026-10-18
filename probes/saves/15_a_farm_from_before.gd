extends SavesProbe
## Profile & saves probe 15: a farm from before. A save the build before the
## crop roster wrote (15_a_farm_from_before.txt, as it came out), of a planter
## with a harvester, three carrots and a ripe fungus in it, a harvest of
## carrots stored, a survival kit with a carrot and a fungus in its slots, and
## a carrot, carrots and fungus caps carried. It resumes as root-tubers in the
## standard planters and a vat fungus in the pot, each as grown as it was, the
## fungus still ripe; the stored harvest is tubers, as many kcal of them; the
## kit holds a root-tuber and a vat fungus; what's carried comes back renamed,
## the food holding what it held. The farm goes on: the ripe fungus is
## harvested on the next tick.

const FIXTURE := "res://probes/saves/15_a_farm_from_before.txt"


func run() -> void:
	saves = get_node("/root/Saves")
	await load_world(1234)
	var data: Dictionary = str_to_var(FileAccess.get_file_as_string(FIXTURE))
	check(Snapshot.problem(data) == "", "nothing in it is unknown (%s)" % Snapshot.problem(data))
	SaveFile.write(saves.path(), saves.KIND, saves.VERSION, data)
	check(await resume(), "the save from before resumes")
	var planter: Planter
	var kit: Device
	for body in world.content.get_children():
		if body is Planter:
			planter = body
		elif body is Device and body.get_meta(&"catalog") == &"survival_kit":
			kit = body
	if planter == null or kit == null:
		check(false, "the planter and the kit are back")
		return
	var sown := planter.sockets().filter(func(s: Socket) -> bool: return s.part is Plant).map(func(s: Socket) -> String:
		var p: Plant = s.part
		return "%s in %s %.2f%s" % [p.crop, s.kind, p.growth, " ripe" if p.ripe() else ""])
	print("planter: %s; stored %s (%d kcal), seeds %s, ripened %s" % [sown, planter.stored, planter.stored_kcal(),
		planter.seeds, planter.ripened])
	check(sown == ["root_tuber in plant_standard 0.00", "root_tuber in plant_standard 0.40",
		"root_tuber in plant_standard 0.00", "vat_fungus in plant_pot 1.00 ripe"],
		"root-tubers in the standard planters as grown as they were, a ripe vat fungus in the pot")
	check(planter.stored == {&"tubers": 3} and planter.stored_kcal() == 450.0 and planter.ripened == {&"root_tuber": 4}
		and planter.seeds == {&"root_tuber": 0}, "its stored harvest is tubers, 450 kcal, and its tallies the root-tuber's")
	var kept := kit.parts().map(func(p: Part) -> StringName: return p.get_meta(&"catalog"))
	check(kept == [&"root_tuber", &"vat_fungus"], "the kit holds a root-tuber and a vat fungus (%s)" % [kept])
	var carried := world.player.suit.carried.map(func(p: RigidBody3D) -> String:
		return "%s%s" % [p.get_meta(&"catalog"), (" %d" % (p as Supply).amount) if p is Supply else ""])
	print("carried: %s" % [carried])
	check(carried.has("root_tuber") and carried.has("tubers 600") and carried.has("fungus_caps 450"),
		"what's carried comes back renamed, the food holding what it held")
	await physics_frames(40)
	check(planter.ripened.get(&"vat_fungus", 0) == 4, "the farm goes on: the ripe fungus is harvested")
