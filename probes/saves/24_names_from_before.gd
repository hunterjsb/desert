extends SavesProbe
## Profile & saves probe 24: names from before. A profile from before session
## 5's renames, with Kesselside and the Okafor bunker counted toward Hot
## Tourist Destinations, loads them as Crakeside and the Haberjack bunker. A
## run saved with a chassis an Okafor marked resumes a Haberjack's, wearing
## the Haberjacks' heraldry.


func run() -> void:
	var profile := get_node(^"/root/Profile")
	SaveFile.write(profile.path(), profile.KIND, profile.VERSION,
		{"toward": {"landmarks": {"halloran": 1.0, "kesselside": 2.0, "okafor_bunker": 3.0}}})
	profile.dir = user_dir
	check(profile.toward_count("landmarks") == 3 and profile.toward("landmarks", "crakeside") == 3
		and profile.toward("landmarks", "haberjack_bunker") == 3,
		"the profile counts Crakeside and the Haberjack bunker, no more")
	saves = get_node(^"/root/Saves")
	await load_world(1234)
	var was := [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"okafor"]]]
	var deck := Catalog.device(&"chassis")
	Catalog.inherit(deck, was)
	world.content.add_child(deck)
	var at := world.player.global_position + Vector3(3.0, 0.0, 2.0)
	deck.global_position = Vector3(at.x, world.height_under(at) + 0.6, at.z)
	await physics_frames(10)
	check(saves.save(world), "saved")
	check(await resume(), "resumed")
	var now := [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"haberjack"]]]
	var marked := world.content.get_children().filter(func(n: Node) -> bool: return n.has_meta(&"lineage"))
	var keys := marked.map(func(n: Node) -> String: return Eras.key(n.get_meta(&"lineage")))
	check(keys == [Eras.key(now)], "the chassis resumes a Haberjack's (%s)" % [keys])
	var look: Mesh = (marked[0] as Device).frame_view.mesh if marked.size() == 1 else null
	check(look == Dress.lineage(&"chassis", now) and look != Dress.lineage(&"chassis", was),
		"it wears the Haberjacks' heraldry")
