extends SavesProbe
## Lineage probe 4: a thing keeps its lineage across a save. A First Kingdoms
## crate with a second-age battery and a skimmer-era tray fitted, a colonial
## shield beside it, and two things without a lineage, a battery never found
## and a deep find from before lineage, are saved and resumed into a fresh
## world on the same seed: each has the lineage it had, with its numbers and
## its look; the two without have none, and look as they did.


func run() -> void:
	saves = get_node(^"/root/Saves")
	await load_world(1234)
	var crate := _beside(Catalog.device(&"crate_frame"), 3.0, Eras.FIRST, &"pipe_wall_hut", 31) as Device
	for each: Array in [[&"battery", Eras.SECOND, &"house_ruin", 32], [&"hover_tray", Eras.SKIMMER, &"wreck_hull", 33]]:
		var part := Catalog.part(each[0])
		Catalog.found_in(part, each[1], each[2], each[3])
		crate.fit(part, crate.sockets().filter(func(s: Socket) -> bool: return s.kind == part.kind and s.is_open())[0])
	_beside(Catalog.device(&"shield"), 5.0, Eras.COLONIAL, &"hab_pod", 34)
	_beside(Catalog.part(&"big_battery"), 6.5)
	_beside(Finds.make({"id": &"charger", "device": true, "layer": Finds.DEEP, "fill": []}), 8.0)
	await physics_frames(30)
	var before := _things()
	print("before: %s" % "; ".join(before.keys().map(func(k: String) -> String: return "%s %s" % [k, before[k][0]])))
	check(saves.save(world), "saved")
	check(await resume(), "resumed")
	var after := _things()
	for name: String in before:
		check(after.has(name) and after[name] == before[name], "%s resumes with its lineage, numbers and look" % name)
	check(before.size() == 6, "six things to keep (%d)" % before.size())


## A thing set down beside where you stand, given a lineage from a site.
func _beside(body: RigidBody3D, ahead: float, era := &"", kind := &"", seed_value := 0) -> RigidBody3D:
	if era != &"":
		Catalog.found_in(body, era, kind, seed_value)
	world.content.add_child(body)
	var at := world.player.global_position + Vector3(ahead, 0.0, 2.0)
	body.global_position = Vector3(at.x, world.height_under(at) + 0.6, at.z)
	return body


## Every thing with a catalog id in the world, fitted or loose, by its id: its
## lineage, its numbers, its weight, and whether its look is its lineage's.
func _things() -> Dictionary:
	var out := {}
	for child in world.content.get_children():
		if not child.has_meta(&"lineage") and not child.has_meta(&"layer") and child.get_meta(&"catalog", &"") != &"big_battery":
			continue
		var bodies: Array = [child]
		if child is Device:
			bodies.append_array((child as Device).parts())
		for body: Node in bodies:
			var id: StringName = body.get_meta(&"catalog")
			var line: Array = body.get_meta(&"lineage", [])
			var stats: Dictionary = (body as Part).stats if body is Part else (body as Device).frame_stats
			var look: Mesh = Dress.lineage(id, line) if not line.is_empty() else null
			out[str(id)] = [Eras.key(line), stats, body.mass if body is Part else (body as Device).frame_mass,
				look == null or _wears(body, look)]
	return out


## Whether a thing's painted look is this mesh.
func _wears(body: Node, look: Mesh) -> bool:
	if body is Device:
		return (body as Device).frame_view.mesh == look
	var part := body as Part
	var nodes: Array = part.socket.fitted if part.socket != null else part.get_children()
	return nodes.any(func(n: Node) -> bool: return n is MeshInstance3D and (n as MeshInstance3D).mesh == look)
