extends FeralProbe
## Farming probe 14: a wild cutting grows in your planter as wild stock. Take
## on a ripe wild saltbush by a pilgrim road: its salt comes to your hands at
## the wild share, with its leaves and a cutting in with what you carry, and
## the bush stays, cut back to its share, the one thing a save remembers of
## the wild. Sown in a planter beside a clean cutting, the wild one grows as
## the clean one does, and stays wild: ripe, it gives the wild share of its
## salt where the clean one gives all of it.


func run() -> void:
	await load_world(1234, true, true)
	world.player.set_physics_process(false)
	world.player.vitals.set_physics_process(false)
	await on_path(&"pilgrim_road")
	var bush := nearest_standing(&"saltbush")
	check(bush != null and bush.ripe() and bush.wild, "a ripe wild saltbush stands by you")
	if bush == null:
		return
	var top: Vector3 = (bush.socket.get_parent() as Node3D).global_transform * bush.socket.transform.origin
	var middle := (top + feral.foot_of(bush)) * 0.5
	aim(middle + Vector3(0.0, 1.0, 1.0), middle)
	await physics_frames(2)
	var hands := world.player.hands
	check(hands.grab(), "you take from it")
	await physics_frames(40)
	var carried := world.player.suit.carried
	var cuttings := carried.filter(func(p: RigidBody3D) -> bool: return p is Plant)
	var salt := carried.filter(func(p: RigidBody3D) -> bool: return p.get(&"kind") == &"salt").size() \
		+ (1 if hands.held != null and hands.held.get(&"kind") == &"salt" else 0)
	print("taken: %s in hand, %d salt in all, %d cuttings" % [hands.held.get(&"label") if hands.held else "nothing",
		salt, cuttings.size()])
	check(salt == 2, "its salt comes away at the wild share, 2 of a clean bush's 4 (%d)" % salt)
	check(cuttings.size() == 1 and cuttings[0].wild and cuttings[0].crop == &"saltbush" and cuttings[0].growth == 0.0,
		"with a wild cutting, nothing grown, in with what you carry")
	check(bush.socket != null and bush.growth == 0.5, "the bush stays, cut back to half (%.2f)" % bush.growth)
	var kept: Array = Snapshot.take(world).feral
	check(kept.size() == 1 and kept[0][1].size() == 1 and kept[0][1][0][1] == 0.5,
		"a save keeps only that bush, as cut: %s" % [kept])
	hands.stow().free()

	var cutting: Plant = cuttings[0]
	carried.erase(cutting)
	var planter := planter_at(ahead(3.0), [])
	var clean := Catalog.part(&"saltbush") as Plant
	var standard := planter.sockets().filter(func(s: Socket) -> bool: return s.kind == &"plant_standard")
	planter.fit(cutting, standard[0])
	planter.fit(clean, standard[1])
	# Clear skies over the planter and a mild day in it, so the sun grows both.
	weather_everywhere(0.0)
	hold_temperature(planter.global_position, 20.0)
	await clock_at(midday())
	await pass_time(60.0)
	print("a minute at midday: wild %.3f %s, clean %.3f %s" % [cutting.growth, cutting.state, clean.growth, clean.state])
	check(cutting.growth > 0.0 and is_equal_approx(cutting.growth, clean.growth), "the wild cutting grows as the clean one")
	for plant: Plant in [cutting, clean]:
		plant.set_growth(0.999)
	await pass_time(20.0)
	check(cutting.ripe() and clean.ripe(), "both ripen")
	if not (cutting.ripe() and clean.ripe()):
		return
	var gave := {}
	for plant: Plant in [cutting, clean]:
		var before := carried.size()
		var first := planter.take(plant.socket)
		var units := 1 if first.get(&"kind") == &"salt" else 0
		for thing in carried.slice(before):
			units += 1 if thing.get(&"kind") == &"salt" else 0
		gave[plant] = units
		first.free()
	print("ripe in the planter: wild gave %d salt, clean %d" % [gave[cutting], gave[clean]])
	check(gave[cutting] == 2 and gave[clean] == 4, "ripe, the wild stock gives its share and the clean all of it")
	check(cutting.wild and cutting.socket != null, "and grows on in its slot, still wild")
