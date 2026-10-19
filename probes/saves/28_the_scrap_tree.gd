extends WreckProbe
## Profile & saves probe 28: the wrecks' deeds, scrapped straight. A skimmer
## hull's hatch cut away is First Cut; its live bank grounded, Clean Hands;
## every module of it freed and taken, Stripped. One module freed from each
## of the other kinds, Bonepicker comes with the last.


func run() -> void:
	await load_salvage()
	world.counts_deeds = true
	var profile := get_node(^"/root/Profile")
	var spot := open_sand()
	var kinds := wreck_kinds()
	check(kinds.size() == Wreckage.kinds().size() and kinds[0] == &"wreck_hull", "five kinds, the skimmer hull first")
	for i in kinds.size():
		var wreck := await wreck_at(kinds[i], spot.x + i * 60.0, spot.y)
		if wreck == null:
			return
		if i == 0:
			cut_away(wreck, 0)
			check(profile.did("first_cut"), "its hatch cut away: First Cut")
			for socket: int in wreck.plan.modules:
				var hazard := wreck.hazard_body(socket)
				if hazard != null and wreck.hazard(socket) != &"":
					wreck.make_safe(hazard, Wreckage.work_of(hazard)[0])
			check(profile.did("clean_hands"), "its live bank grounded, nothing set off: Clean Hands")
		var modules := modules_of(wreck)
		var freed := 0
		for socket: int in modules:
			free_module(wreck, socket)
			var body: RigidBody3D = modules_of(wreck)[socket]
			if body == null or salvage.held_fast(body) != "":
				continue
			salvage.claim(body)
			freed += 1
			if i > 0:
				break
			if freed == 1:
				check(not profile.did("stripped"), "one module freed is no Stripped")
		if i == 0:
			check(freed == modules.size() and profile.did("stripped"), "all %d modules freed: Stripped" % freed)
		check(profile.did("bonepicker") == (i == kinds.size() - 1),
			"a %s scrapped, %d kinds of five" % [kinds[i], profile.toward_count("bonepicker")])
