extends WreckProbe
## Wreck probe 4: a wreck remembers what was done to it. At one of history's
## skimmer hulls in a wreck field: a plate cut away and fallen, a slice of its
## hold cleared, its bank grounded. Walked far enough that its ground goes and
## back, it's built again as it was left: the plate lying where it fell, the
## slice gone, the bank dead. Saved and resumed, the same, and a save of it
## holds what was done and nothing of an untouched wreck; buried by a storm
## while you're away, its plate still lies where it fell. Once you've gone so
## far the sheet lifts it, it's forgotten, as any site is.

## Gone this far, m: the ground goes, the site stays laid; then far enough
## that the sheet lifts it.
const AWAY := 900.0
const LIFTED := 3000.0

var saves: Node


func run() -> void:
	saves = get_node("/root/Saves")
	var tuning := Tuning.current()
	tuning.salvage = true
	var history := History.new(1234, tuning)
	var fields := StructureKit.nearest_on_moon(history, history.landmark(&"halloran").p, &"wreck_hull", 20000.0, 8)
	fields = fields.filter(func(each: Dictionary) -> bool: return each.source == &"wreck_field")
	check(not fields.is_empty(), "history lays skimmer hulls in a wreck field")
	if fields.is_empty():
		return
	# Stand off the first, at a moment its sand is stripped.
	tuning.site_return_m = -1.0
	tuning.spawn_latitude_degrees = rad_to_deg(Sphere.latitude(fields[0].p))
	tuning.spawn_longitude_degrees = rad_to_deg(Sphere.longitude(fields[0].p))
	await load_hands(1234, true)
	salvage = world.salvage
	await settle_finds()
	var wreck := await _worked_wreck()
	if wreck == null:
		return
	var site := wreck.site
	var plate := _plate(wreck)
	var bank := -1
	for socket: int in wreck.plan.modules:
		if wreck.hazard(socket) != &"":
			bank = socket
	# Worked: a plate cut away and fallen, a slice cleared, the bank made safe.
	cut_away(wreck, plate)
	await physics_frames(roundi(Wreckage.SETTLE_MOST * Engine.physics_ticks_per_second) + 10)
	var fallen := _fallen_at(wreck, plate)
	clear_out(wreck, 0, 1)
	if bank >= 0:
		wreck.make_safe(wreck.hazard_body(bank), Wreckage.GROUND if wreck.plan.modules[bank].hazard == Wreckage.ELECTRICAL \
			else Wreckage.SEAL)
	var here := Vector2(world.player_world_x(), world.player_world_z())
	print("worked a skimmer hull at %.0f,%.0f, %s: its %s cut away, a slice of its %s cleared, %s" % [site.x, site.z,
		Exposure.NAMES[site.state()], wreck.plan.plates[plate].label, wreck.plan.holds[0].label,
		"its bank grounded" if bank >= 0 else "no hazard on it"])

	# Its ground gone and back.
	await go(here.x + AWAY, here.y)
	check(salvage.wreckage_of(site) == null, "%.0f m off, its ground is gone" % AWAY)
	await go(here.x, here.y)
	wreck = await _built(site)
	_as_left(wreck, plate, fallen, bank, "walked back to")

	# Saved and resumed.
	check(saves.save(world), "saved")
	var data: Dictionary = SaveFile.read(saves.path(), saves.KIND, saves.VERSION).data
	var kept: Array = data.sites.filter(func(each: Array) -> bool: return each[0] == site.id)
	check(kept.size() == 1 and kept[0].size() > 2 and kept[0][2].get("touched", false),
		"the save holds what was done to it")
	var others := 0
	for wrecked in salvage.wrecks():
		if wrecked.site != site and data.sites.any(func(each: Array) -> bool: return each[0] == wrecked.site.id):
			others += 1
	check(others == 0, "and nothing of the wrecks untouched (%d)" % others)
	check(await _resume(), "resumed")
	var again: Structure = null
	for unit in world.shape.sites.units():
		for each in unit.sites:
			if each.id == site.id:
				again = each
	check(again != null, "the sheet lays it again")
	if again == null:
		return
	wreck = await _built(again)
	_as_left(wreck, plate, fallen, bank, "resumed at")

	# Buried by a storm while you're away, it's sunk deep; the plate lying on
	# the sand outside it hasn't moved.
	again.depth = again.taken() * 4.0 + 1.0
	await go(here.x + AWAY, here.y)
	await go(here.x, here.y)
	wreck = await _built(again)
	if wreck != null:
		var lying := _fallen_at(wreck, plate)
		print("buried, the wreck is %s; its plate lies %.3f m from where it fell" % [Exposure.NAMES[again.state()],
			lying.distance_to(fallen)])
		check(again.state() != Exposure.EXPOSED and lying.distance_to(fallen) < 0.05,
			"buried, its fallen plate still lies where it fell")
		# A storm strips it while you stand there: it rises out of the sand,
		# its scrapping with it, and the plate on the sand stays put.
		var sunk := wreck.global_position.y
		again.depth = 0.0
		await physics_frames(60)
		print("stripped while loaded, it rose %.2f m to stand at its site's floor (%.3f m off); its plate %.3f m from where it fell"
			% [wreck.global_position.y - sunk, absf(wreck.transform.origin.y - again.floor_y),
			_fallen_at(wreck, plate).distance_to(fallen)])
		check(wreck.global_position.y > sunk + 1.0 and absf(wreck.transform.origin.y - again.floor_y) < 0.01
			and _fallen_at(wreck, plate).distance_to(fallen) < 0.05,
			"stripped while you stand there, it rises with its site, the fallen plate staying put")

	# Lifted, forgotten.
	await go(here.x + LIFTED, here.y)
	await physics_frames(5)
	var remembered := salvage.site_memories().any(func(each: Array) -> bool: return each[0] == site.id)
	check(not remembered, "%.0f km off, the sheet's lifted it and it's forgotten" % (LIFTED / 1000.0))


## History's skimmer hull nearest where you stand that's built with a plate
## clear of the sand and sand in its hold.
func _worked_wreck() -> Wreckage:
	for site in structures_near(&"wreck_hull", 600.0):
		var beside := site.to_world(site.piece.approach)
		await go(beside.x, beside.y)
		var wreck := salvage.wreckage_of(site)
		if wreck != null and _plate(wreck) >= 0 and wreck.slice_body(0, 0) != null:
			return wreck
	check(false, "a skimmer hull near stands with a plate and sand to work")
	return null


## Its first plate whose seams are all over the sand, or -1.
func _plate(wreck: Wreckage) -> int:
	for i in wreck.plan.plates.size():
		if wreck.plate_body(i) == null:
			continue
		var clear := true
		for c in wreck.plan.plates[i].cells.size():
			clear = clear and not wreck.cell_buried(i, c)
		if clear:
			return i
	return -1


## Where a fallen plate lies, the engine's frame, or NAN.
func _fallen_at(wreck: Wreckage, i: int) -> Vector3:
	if not wreck.state.fallen.has(i):
		return Vector3(NAN, NAN, NAN)
	return wreck.global_transform * wreck.lying_at(i).origin


func _built(site: Structure) -> Wreckage:
	for k in 300:
		if salvage.wreckage_of(site) != null:
			break
		await get_tree().process_frame
	var wreck := salvage.wreckage_of(site)
	check(wreck != null, "its scrapping is built again")
	return wreck


func _as_left(wreck: Wreckage, plate: int, fallen: Vector3, bank: int, how: String) -> void:
	if wreck == null:
		return
	var lying := _fallen_at(wreck, plate)
	var body: Node3D = null
	for child in wreck.find_children("*", "StaticBody3D", true, false):
		if child.has_meta(&"fallen_plate") and child.get_meta(&"fallen_plate") == plate:
			body = child
	check(wreck.plate_body(plate) == null and body != null and body.global_position.distance_to(fallen) < 0.05
		and lying.distance_to(fallen) < 0.05, "%s, its plate lies where it fell" % how)
	check(wreck.cleared(0) == 1 and wreck.slice_body(0, 0) == null, "its slice is still cleared")
	if bank >= 0:
		check(wreck.hazard(bank) == &"", "its hazard still dead")


func _resume() -> bool:
	var seed_was := world.run_seed
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame
	world = WORLD_SCENE.instantiate()
	world.run_seed = seed_was
	add_child(world)
	await settle()
	await get_tree().physics_frame
	if not saves.restore(world):
		return false
	if saves.restoring:
		await saves.restored
	salvage = world.salvage
	hands = world.player.hands
	world.player.set_physics_process(false)
	world.player.collision_layer = 0
	world.player.collision_mask = 0
	await settle_finds()
	return true
