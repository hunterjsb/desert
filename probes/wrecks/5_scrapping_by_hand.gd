extends WreckProbe
## Wreck probe 5: scrapping by hand, through the actions. A skimmer hull, worked as
## a player works it. Its readout says what each piece is and what does its
## work. A heat cutter held off the seams cuts nothing and says to trace them;
## traced cell by cell round its hatch with use held down, it cuts the hatch
## away in about the time its seams take, drawing on its battery as it fires,
## and the hatch falls. A scoop held on the cargo bay's sand clears its open
## slice in the time its sand takes. A stake from your hands grounds the
## charger's live bank; empty-handed you take the charger, while a module the
## sand still holds won't come and says why.


func run() -> void:
	await load_salvage()
	var spot := open_sand()
	var wreck := await wreck_at(&"wreck_hull", spot.x, spot.y, 1.1, 0.4)
	if wreck == null:
		return
	var dt := 1.0 / Engine.physics_ticks_per_second
	var hatch := 0
	var p: WreckPlan.Plate = wreck.plan.plates[hatch]
	var out := wreck.plate_normal(hatch)
	var face := wreck.plate_body(hatch).global_transform * p.face()

	# The readout, empty-handed.
	face_point(face, out)
	await physics_frames(2)
	print("looking at the hatch: \"%s\"" % hands.line())
	check(hands.line().contains(p.label) and hands.line().contains("heat cutter"), "the readout says what cuts it")

	# A cutter, off the seams and then along them.
	var cutter := device(&"cutter", eye() - world.player.camera.global_basis.z * 0.6, 0.0, true) as Cutter
	await physics_frames(5)
	hands.hold(cutter)
	await physics_frames(30)
	var charge := cutter.battery().charge_wh
	face_point(face, out)
	for k in 30:
		await get_tree().physics_frame
		hands.scrap(dt)
	check(wreck.progress(hatch) == 0.0 and hands.notice == Hands.NO_SEAM, "off the seams it cuts nothing, and says to trace them")
	var took := 0.0
	for c in p.cells.size():
		if wreck.plate_body(hatch) == null:
			break
		if (wreck.state.cut[hatch] as PackedFloat32Array)[c] >= 1.0:
			continue
		face_point(wreck.cell_point(hatch, c), out)
		var spent := 0.0
		while wreck.plate_body(hatch) != null and (wreck.state.cut[hatch] as PackedFloat32Array)[c] < 1.0 \
				and spent < wreck.cell_seconds() * 3.0:
			await get_tree().physics_frame
			hands.scrap(dt)
			spent += dt
		took += spent
	var promised := p.cells.size() * wreck.cell_seconds()
	await physics_frames(2)
	print("traced the %s's %d cells of seam by hand in %.1f s (%.1f s cell by cell); %.2f Wh drawn" % [p.label,
		p.cells.size(), took, promised, charge - cutter.battery().charge_wh])
	check(wreck.plate_body(hatch) == null and wreck.done(hatch), "traced round, the hatch comes away")
	check(took > promised * 0.4 and took < promised * 1.15, "in about the time its seams take")
	check(cutter.battery().charge_wh < charge, "the cutter drawing on its battery")
	hands.drop()
	await physics_frames(20)

	# A scoop on the cargo bay's open slice.
	var scoop := Catalog.part(&"sand_scoop")
	world.content.add_child(scoop)
	scoop.global_position = eye() - world.player.camera.global_basis.z * 0.6
	await physics_frames(5)
	hands.hold(scoop)
	await physics_frames(30)
	var sand := wreck.slice_body(0, 0)
	var from_tail := (wreck.global_basis.z).normalized()
	face_point(_slice_face(wreck, sand, from_tail), from_tail, 1.3)
	# The hatch's notice has its moment first.
	for k in 600:
		if hands.notice == "":
			break
		await get_tree().physics_frame
	await physics_frames(2)
	print("looking at the bay's sand: \"%s\"" % hands.line())
	check(hands.line().contains("sand scoop"), "the readout says what clears it")
	var scooped := 0.0
	var seconds := wreck.slice_seconds(0, 0)
	while wreck.cleared(0) < 1 and scooped < seconds * 2.0:
		await get_tree().physics_frame
		face_point(_slice_face(wreck, wreck.slice_body(0, 0), from_tail), from_tail, 1.3)
		hands.scrap(dt)
		scooped += dt
	print("scooped the bay's first slice by hand in %.1f s (%.1f s promised)" % [scooped, seconds])
	check(wreck.cleared(0) == 1 and absf(scooped - seconds) < seconds * 0.15 + 0.2, "a scoop clears its slice in its time")
	hands.drop()
	await physics_frames(20)

	# A stake across the bank; the charger taken; a module the sand holds refused.
	var bank := -1
	for socket: int in wreck.plan.modules:
		if wreck.hazard(socket) != &"":
			bank = socket
	var stake := Catalog.stake()
	world.content.add_child(stake)
	stake.global_position = eye() - world.player.camera.global_basis.z * 0.6
	await physics_frames(5)
	hands.hold(stake)
	await physics_frames(30)
	var live := wreck.hazard_body(bank)
	var through := wreck.global_transform * p.box.get_center()
	look(through + out * 0.9 + Vector3.UP * 0.6, middle_of(live))
	await physics_frames(2)
	print("looking at the bank: \"%s\"" % hands.line())
	check(hands.interact() and wreck.hazard(bank) == &"", "a stake from your hands grounds the bank")
	await physics_frames(30)
	var charger: RigidBody3D = modules_of(wreck)[bank]
	look(through + out * 0.9 + Vector3.UP * 0.6, middle_of(charger))
	await physics_frames(2)
	hands.grab()
	await physics_frames(40)
	check(hands.held == charger or hands.grasp.body == charger, "empty-handed you take the charger")
	hands.drop()
	await physics_frames(20)
	var held := -1
	for socket: int in wreck.plan.modules:
		var body: RigidBody3D = modules_of(wreck)[socket]
		if body != null and salvage.held_fast(body) != "":
			held = socket
	check(held >= 0, "a module is still held in the sand")
	if held < 0:
		return
	var fast: RigidBody3D = modules_of(wreck)[held]
	look(through + out * 0.9 + Vector3.UP * 0.6, middle_of(fast))
	await physics_frames(2)
	hands.grab()
	await physics_frames(5)
	var why := salvage.held_fast(fast)
	check(hands.held != fast and hands.grasp.body != fast and why.contains("sand"),
		"and won't come, saying why: \"%s\"" % why)


## Your eyes `back` m out from a point along a plate or slice's face, a little
## above it, looking at it.
func face_point(at: Vector3, out: Vector3, back := 1.0) -> void:
	look(at + out * back + Vector3.UP * 0.25, at)


## The middle of a slice's open face, toward `out`.
func _slice_face(wreck: Wreckage, sand: StaticBody3D, out: Vector3) -> Vector3:
	var shape := sand.get_child(0) as CollisionShape3D
	var size := (shape.shape as BoxShape3D).size
	var middle := sand.global_transform * shape.position
	return middle + out * size.z * 0.5 + Vector3.UP * 0.3
