class_name WreckProbe
extends SalvageProbe
## For wreck probes: wrecks laid by hand on open sand as history would lay
## them, dug out, and their scrapping (Wreckage) worked straight or by hand.


## The kinds that are wrecks, in the order StructureKit holds them.
func wreck_kinds() -> Array[StringName]:
	var out: Array[StringName] = []
	for kind: StringName in StructureKit.kinds():
		if StructureKit.piece(kind).wreck != null:
			out.append(kind)
	return out


## A wreck of a kind laid by hand where the dunes take it, near a world
## place, dug out, leaning `lean_share` of its era's most (rad if no era
## leans); you're stood beside it and its scrapping and modules are laid
## out. Null if the dunes take it everywhere tried.
func wreck_at(kind: StringName, x: float, z: float, bearing := 0.4, lean_share := 0.6) -> Wreckage:
	var sites := world.shape.sites
	var lean := deg_to_rad(Eras.TILT.get(StructureKit.piece(kind).era, Vector2.ZERO).y * lean_share)
	var site: Structure = null
	# Out from the place on a spiral, nearest first.
	for tries in 150:
		var off := Vector2.from_angle(tries * 2.39996) * 7.0 * sqrt(tries)
		site = sites.by_hand(kind, x + off.x, z + off.y, bearing, 0.0, lean)
		if site.stands():
			break
	check(site.stands(), "a %s stands where it's laid" % kind)
	if not site.stands():
		return null
	sites.add(site)
	var beside := site.to_world(site.piece.approach)
	await go(beside.x, beside.y)
	for i in 300:
		if salvage.wreckage_of(site) != null and salvage.is_idle():
			break
		await get_tree().process_frame
	var wreck := salvage.wreckage_of(site)
	check(wreck != null, "the %s's scrapping is built" % kind)
	return wreck


## Each of a wreck's modules lying in it now, by socket: the device, or null.
func modules_of(wreck: Wreckage) -> Dictionary:
	var out := {}
	for socket: int in wreck.plan.modules:
		out[socket] = null
	for body in salvage.finds():
		if body.has_meta(&"module") and body.get_meta(&"module")[0] == wreck.site:
			out[body.get_meta(&"module")[1]] = body
	return out


## Cuts a plate away straight, cell by cell along its seams.
func cut_away(wreck: Wreckage, i: int) -> void:
	var body := wreck.plate_body(i)
	if body == null:
		return
	for c in wreck.plan.plates[i].cells.size():
		wreck.cut(body, wreck.cell_point(i, c), wreck.cell_seconds() * 2.0)
		if wreck.plate_body(i) == null:
			return


## Clears a hold's first `slices` slices straight.
func clear_out(wreck: Wreckage, h: int, slices: int) -> void:
	for k in mini(slices, wreck.plan.holds[h].slices):
		var body := wreck.slice_body(h, k)
		if body != null:
			wreck.clear(body, wreck.slice_seconds(h, k) + 0.01)


## Does everything a module needs.
func free_module(wreck: Wreckage, socket: int) -> void:
	for need: Array in (wreck.plan.modules[socket] as WreckPlan.Module).needs:
		if need[0] == &"plate":
			cut_away(wreck, need[1])
		else:
			clear_out(wreck, need[1], need[2])


## How many parts a module could hold as found: its sockets its era's
## fills have parts for, at most SiteLoot's least.
func fillable(wreck: Wreckage, body: Device) -> int:
	var fills: Dictionary = Finds.FILLS[SiteLoot.ERAS[wreck.site.era].fills]
	var count := 0
	for socket in body.sockets():
		count += int(fills.has(socket.kind))
	return mini(count, SiteLoot.MODULE_PARTS)


## A thing's middle, the engine's frame.
func middle_of(body: Node3D) -> Vector3:
	return body.global_transform * Finds.bounds(body).get_center()


## Stands your eyes `back` m out from a point along `out`, at a person's eye
## height over the sand under them, looking at it.
func face(at: Vector3, out: Vector3, back := 1.4) -> void:
	var from := at + Vector3(out.x, 0.0, out.z).normalized() * back
	from.y = maxf(world.height_under(from) + 1.6, at.y + 0.1)
	look(from, at)
