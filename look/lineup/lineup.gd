extends "res://look/style/style.gd"
## Look-test: the model lineup. Everything the catalog draws, as the game
## makes it, laid on the sand in front of the camp at its true size under the
## game's one light, in blocks by role with a Surveyor at each block's end for
## scale: camp devices, power, boards and rig, what you carry, parts, food and
## crops by stage; the chassis kit in each era and a few things in their
## lineages (Dress.lineage); and
## further out the world's own at theirs: every kit structure and wreck small
## enough to stand in a row, the Walker and the pod, and the deliveryship
## overhead. Something Dress draws nothing for keeps its grey box.
## --labels numbers everything (the legend is printed) and flags a grey box in
## red. --audit prints what each costs to draw and quits; headless will do.
##   godot --path . --disable-vsync res://look/lineup/lineup.tscn -- --look grey --capture <dir> [--labels] [--storm]
##   godot --headless --path . res://look/lineup/lineup.tscn -- --look grey --audit
## look/lineup/shoot.sh shoots it and builds the sheets.

## Blocks by role, camp frame: name, middle (x, z), what's in it, tallest
## first so the back line holds them, and its widest line, m. Two aren't
## catalog ids but a raised mast's own pieces; each crop's stages follow its
## loose part.
const BLOCKS := [
	["camp", Vector2(0.0, 4.4), [&"console", &"nav_computer", &"cargo", &"crows_nest", &"shield", &"light_shield",
		&"personal_shield", &"condenser", &"burner", &"deep_planter", &"helm_seat", &"planter", &"chassis", &"survival_kit",
		&"home_beacon", &"bedroll", &"stake"], 7.0],
	["power", Vector2(-8.5, 4.4), [&"power_cabinet", &"power_rack", &"power_shrine", &"turbine", &"light_panel", &"power_box",
		&"solar_panel", &"big_battery", &"battery", &"lamp", &"canister", &"plug", &"strong_plug", &"hose_end"], 7.0],
	["boards", Vector2(8.5, 4.4), [&"mast", &"mast_top", &"boom", &"sail", &"board", &"racer_board", &"patrol_board",
		&"temple_board", &"hover_tray", &"skates", &"board_plate", &"keel", &"frame", &"fabric", &"hull_plate", &"hand_winch",
		&"streamer"], 7.0],
	["held", Vector2(-8.5, 11.0), [&"survey_receiver", &"antenna_kite", &"salvage_kite", &"cutter", &"radio", &"radio_colonial",
		&"radio_skimmer", &"radio_kingdoms", &"radio_second_age", &"crystal_set", &"headset", &"sailing_notes",
		&"surveyor_guide", &"sand_scoop", &"sieve", &"coil", &"rope_end", &"hook", &"compass", &"flare", &"sealant", &"med_kit"],
		7.0],
	["parts", Vector2(0.0, 11.0), [&"screen", &"radar", &"ground_radar", &"anemometer", &"particle_sensor", &"barometer",
		&"hygrometer", &"harvester", &"fm_converter", &"sw_converter", &"bleed_resistor", &"valve_preamp", &"static_choke",
		&"wire_logger", &"solar_lid"], 3.0],
	["food", Vector2(8.5, 11.0), [&"coalcane", &"coalcane_bundle", &"root_tuber", &"vat_fungus", &"saltbush", &"ration",
		&"tubers", &"fungus_caps", &"saltbush_leaves", &"salt"], 4.6],
]
## Lineages to show a few things in, one line a thing, one of each era a
## look can take (Eras.era_of): the company's issue, colonial, a First
## Kingdoms house's, the skimmer era's, and remade and blessed in the second age.
const LINES := [
	["issued", []],
	["colonial", [[Eras.COLONIAL, &"made", [&"tilg"]]]],
	["first", [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"haberjack"]]]],
	["skimmer", [[Eras.SKIMMER, &"made", []]]],
	["second", [[Eras.COLONIAL, &"made", [&"tilg"]], [Eras.FIRST, &"marked", [&"pellicott"]],
		[Eras.DARK, &"remade", [&"wood", &"cord", &"ceramic"]], [Eras.SECOND, &"blessed", [&"tu", &"charm"]]]],
]
## Things in their lineages, camp frame: the block, its middle, and what's in
## it. The chassis kit changes shape by era (ChassisLooks), the bar the rest
## is judged against; the others take only their lineage's marks.
const LINEAGES := [
	["lineage", Vector2(0.0, 17.0), [&"console", &"condenser", &"board", &"battery"]],
	["chassis_eras", Vector2(-9.5, 18.5), [&"mast", &"frame", &"helm_seat", &"hand_winch", &"chassis", &"hull_plate", &"stake"]],
]
## Blocks of things too small to read from 5 m, shot close too.
const CLOSE := ["held", "parts", "food"]
## The lineage blocks' widest line, and the gaps between things and lines, m.
const WIDE := 7.0
const GAP := 0.3
const LINE_GAP := 0.45
## Things turn this far off facing the camera, so a side shows; a part
## standing out further than LONG lies along the row instead of on its back.
const TURN := 0.4
const LONG := 0.45
## The world's own stand in a row this far out, this far apart, m; a kit
## structure reaching further than this from its middle is left out.
const WORLD_Z := 48.0
const WORLD_GAP := 7.0
const WORLD_MOST := 22.0
## Shots of the world's row take this much of it each, m.
const WORLD_SHOT := 42.0
## The deliveryship is drawn this far off at most, at its own size (Deliveryship.PROXY).
const SHIP_OFF := 380.0

## What's laid: [block, label, roots, main looks, grey].
var _laid: Array[Array] = []
var _labels := false
var _blocks := {}
var _world_shots: Array[Array] = []
var _count := 0


func _dress() -> void:
	var args := OS.get_cmdline_user_args()
	_labels = args.has("--labels")
	# The bubble holds the storm off the camp block; in clear air it would veil the rows.
	generator.stand(storm)
	var placed := {}
	for block: Array in BLOCKS:
		var things: Array = []
		for id: StringName in block[2]:
			things.append_array(_things(id))
			placed[id] = true
		if block[0] == "parts":
			for id: StringName in Catalog.DEVICES.keys() + Catalog.PARTS.keys():
				if not placed.has(id) and not _in_blocks(id):
					print("lineup: %s has no block; laid with the parts" % id)
					things.append_array(_things(id))
		_lay(block[0], block[1], things, block[3])
	for block: Array in LINEAGES:
		var lined: Array = []
		for id: StringName in block[2]:
			for entry: Array in LINES:
				var body := _thing(id)
				Catalog.inherit(body, entry[1])
				lined.append(_item(body, "%s/%s" % [id, entry[0]], Catalog.PARTS.has(id), id))
			lined.append(null)
		_lay(block[0], block[1], lined, WIDE)
	_world()
	if args.has("--audit"):
		for each in _laid:
			_audit(each)
		get_tree().quit()


static func _in_blocks(id: StringName) -> bool:
	for block: Array in BLOCKS:
		if block[2].has(id):
			return true
	return false


## A catalog id's things: itself, and a crop's look at each stage after it.
func _things(id: StringName) -> Array:
	var out := [_item(_thing(id), String(id), Catalog.PARTS.has(id), id)]
	var grows: Dictionary = Catalog.PARTS.get(id, {}).get("crop", {})
	if not grows.is_empty():
		for stage: StringName in [Plant.SEEDLING, Plant.YOUNG, Plant.RIPE] + ([Plant.MATURE] if grows.stages.has("bursts") else []):
			var view := MeshInstance3D.new()
			view.mesh = Dress.crop(id, stage)
			view.set_instance_shader_parameter(&"age", Paint.age_of(&"", 1.0))
			out.append(_item(view, "%s/%s" % [id, stage], true, &""))
	return out


func _thing(id: StringName) -> Node3D:
	if id == &"stake":
		return Catalog.stake()
	if Catalog.DEVICES.has(id):
		return Catalog.device(id)
	if Catalog.PARTS.has(id):
		return Catalog.part(id)
	# A raised mast's top and boom, sized as Mast sizes them.
	var view := MeshInstance3D.new()
	var mast: Vector3 = Catalog.DEVICES[&"mast"].size
	view.mesh = Dress.frame(&"boom", Vector3(0.07, 0.07, Mast.BOOM)) if id == &"boom" \
		else Dress.frame(&"mast_top", Vector3(0.09, Mast.BOOM_AT.y + Mast.LUFF + 0.15 - mast.y * 0.5, 0.09))
	view.set_instance_shader_parameter(&"age", Paint.age_of(&"", 1.0))
	return view


## A thing to lay: in the world already, held still at its middle, with how it
## lies (a device upright, a part on its back, a long one along the row) and
## its box so turned. `id` is its catalog id, to tell whether Dress drew it.
func _item(node: Node3D, label: String, on_back: bool, id: StringName) -> Dictionary:
	world.content.add_child(node)
	if node is RigidBody3D:
		(node as RigidBody3D).freeze = true
	var box := _box(node)
	var lie := Basis(Vector3.UP, PI + TURN)
	if label == "mast_top":
		lie = Basis(Vector3.BACK, -PI * 0.5)
	elif label == "boom" or (on_back and box.size.z > LONG and not node is Plant and id != &""):
		lie = Basis(Vector3.UP, PI * 0.5)
	elif on_back:
		lie = lie * Basis(Vector3.RIGHT, -PI * 0.5)
	var grey := false
	if id == &"stake":
		grey = Dress.frame(id, Vector3(0.06, Stake.LENGTH, 0.06)) == null
	elif Catalog.DEVICES.has(id):
		grey = Dress.frame(id, Catalog.DEVICES[id].size, Catalog.DEVICES[id].get("mast", 0.0)) == null
	elif Catalog.PARTS.has(id) and not Catalog.PARTS[id].has("crop"):
		grey = Dress.part(id, Catalog.PARTS[id].size) == null
	elif Catalog.PARTS.has(id):
		grey = Dress.part(id, Catalog.PARTS[id].size) == null and Dress.crop(id, Plant.RIPE) == null
	return {"node": node, "label": label, "lie": lie, "box": Transform3D(lie, Vector3.ZERO) * box, "grey": grey, "main": _main(node)}


## Where its looks reach in its own frame, and its catalog box.
func _box(node: Node3D) -> AABB:
	var box := Finds.bounds(node) if node is CollisionObject3D else AABB()
	var first := not node is CollisionObject3D
	for view in _views(node):
		# What isn't drawn takes no room: a packed kite's wing, a rolled bedroll's spread.
		if not view.is_visible_in_tree():
			continue
		var rel := view.transform
		var up := view.get_parent()
		while view != node and up != node and up is Node3D:
			rel = (up as Node3D).transform * rel
			up = up.get_parent()
		var each := (Transform3D.IDENTITY if view == node else rel) * view.get_aabb()
		box = each if first else box.merge(each)
		first = false
	return box


## Lines of things no wider than `wide`, back to front from the tallest,
## centred on `middle`; a null ends a line early. A Surveyor stands at its left end.
func _lay(block: String, middle: Vector2, things: Array, wide: float) -> void:
	var lines := [[]]
	var used := 0.0
	for each in things:
		if each == null:
			lines.append([])
			used = 0.0
			continue
		var across: float = each.box.size.x
		if not lines[-1].is_empty() and used + GAP + across > wide:
			lines.append([])
			used = 0.0
		used += (GAP if not lines[-1].is_empty() else 0.0) + across
		lines[-1].append(each)
	lines = lines.filter(func(l: Array) -> bool: return not l.is_empty())
	var deep := -LINE_GAP
	for line in lines:
		deep += LINE_GAP + line.reduce(func(m: float, e: Dictionary) -> float: return maxf(m, e.box.size.z), 0.0)
	var z := middle.y - deep * 0.5
	for line in lines:
		var depth: float = line.reduce(func(m: float, e: Dictionary) -> float: return maxf(m, e.box.size.z), 0.0)
		var span: float = line.reduce(func(s: float, e: Dictionary) -> float: return s + e.box.size.x + GAP, -GAP)
		var x := middle.x - span * 0.5
		for each: Dictionary in line:
			_put(each, Vector2(x + each.box.size.x * 0.5, z + depth * 0.5))
			x += each.box.size.x + GAP
			_count += 1
			print("legend\t%s\t%d\t%s%s" % [block, _count, each.label, "\tGREY" if each.grey else ""])
			if _labels:
				_label(each, str(_count))
			_laid.append([block, each.label, [each.node], [each.main] if each.main != null else [], each.grey])
		z += depth + LINE_GAP
	var me := _surveyor()
	world.content.add_child(me)
	var at := _to_world(Vector3(middle.x - wide * 0.5 - 0.6, 0.0, middle.y))
	me.global_transform = Transform3D(Basis(Vector3.UP, _yaw + PI), Vector3(world.engine_x(at.x), world.height_at(at.x, at.y),
		world.engine_z(at.y)))
	_blocks[block] = Vector3(middle.x, deep, middle.y)


## Sets a thing down with its turned box's middle at `at`, camp frame, its
## foot just on the sand there.
func _put(each: Dictionary, at: Vector2) -> void:
	var box: AABB = each.box
	var middle := box.get_center()
	var w := _to_world(Vector3(at.x, 0.0, at.y))
	var origin := _to_world(Vector3(at.x - middle.x, 0.0, at.y - middle.z))
	var node: Node3D = each.node
	node.global_transform = Transform3D(Basis(Vector3.UP, _yaw) * each.lie, Vector3(world.engine_x(origin.x),
		world.height_at(w.x, w.y) - box.position.y + 0.015, world.engine_z(origin.y)))
	each.at = at


## Its number on the sand before it, tilted up to the camera; red over a grey box.
func _label(each: Dictionary, text: String) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 56
	label.pixel_size = 0.0018
	label.outline_size = 14
	label.modulate = Color(1.0, 0.25, 0.2) if each.grey else Color.WHITE
	label.double_sided = true
	world.content.add_child(label)
	var at: Vector2 = each.at + Vector2(0.0, each.box.size.z * 0.5 + 0.09)
	label.global_transform = Transform3D(Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, -1.0), _engine(Vector3(at.x, 0.03, at.y)))
	if each.grey:
		var flag := MeshInstance3D.new()
		var post := BoxMesh.new()
		post.size = Vector3(0.02, 0.6, 0.02)
		var red := StandardMaterial3D.new()
		red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		red.albedo_color = Color(1.0, 0.1, 0.05)
		post.material = red
		flag.mesh = post
		world.content.add_child(flag)
		var by: Vector2 = each.at + Vector2(each.box.size.x * 0.5 + 0.05, 0.0)
		flag.global_position = _engine(Vector3(by.x, 0.3, by.y))


## The Surveyor at rest, for scale: the suit's pieces on their joints, each
## limb hung from its joint toward the next.
func _surveyor() -> Node3D:
	var me := Node3D.new()
	for name: StringName in [&"hips", &"trunk", &"collar", &"head"]:
		var at: Vector3 = {&"hips": SurveyorLooks.HIPS, &"trunk": SurveyorLooks.WAIST, &"collar": SurveyorLooks.WAIST,
			&"head": SurveyorLooks.NECK}[name]
		_bone(me, name, Basis.IDENTITY, at)
	for side in [1.0, -1.0]:
		var m := Vector3(side, 1.0, 1.0)
		var s := "_r" if side > 0.0 else "_l"
		for bone: Array in [["upper_arm", SurveyorLooks.SHOULDER, SurveyorLooks.ELBOW], ["forearm", SurveyorLooks.ELBOW,
				SurveyorLooks.WRIST], ["thigh", SurveyorLooks.HIP, SurveyorLooks.KNEE], ["shin", SurveyorLooks.KNEE, SurveyorLooks.ANKLE]]:
			var y: Vector3 = ((bone[1] - bone[2]) * m).normalized()
			var x := (Vector3.RIGHT - y * y.x).normalized()
			_bone(me, StringName(bone[0] + s), Basis(x, y, x.cross(y)), bone[1] * m)
		_bone(me, StringName("hand" + s), Basis.IDENTITY, SurveyorLooks.WRIST * m)
		_bone(me, StringName("foot" + s), Basis.IDENTITY, SurveyorLooks.ANKLE * m)
	return me


static func _bone(me: Node3D, name: StringName, turn: Basis, at: Vector3) -> void:
	var view := MeshInstance3D.new()
	view.mesh = SurveyorLooks.part(name)
	view.transform = Transform3D(turn, at)
	view.set_instance_shader_parameter(&"age", Paint.ERA_NEW)
	me.add_child(view)


## The world's own, in a row across the front: every kit structure and wreck
## small enough, dug out, the Walker, the pod; the deliveryship overhead.
func _world() -> void:
	var row: Array[Array] = []
	for kind: StringName in StructureKit.kinds():
		var piece := StructureKit.piece(kind)
		if piece == null or not piece.look.is_valid():
			continue
		var view := MeshInstance3D.new()
		view.mesh = piece.mesh(Exposure.EXPOSED, 0)
		var box := view.mesh.get_aabb()
		if maxf(absf(box.position.x), absf(box.end.x)) > WORLD_MOST or maxf(absf(box.position.z), absf(box.end.z)) > WORLD_MOST:
			print("lineup: %s reaches %.0f m, too far for the row" % [kind, maxf(box.size.x, box.size.z)])
			view.free()
			continue
		view.set_instance_shader_parameter(&"age", (piece.age.x + piece.age.y) * 0.5)
		view.set_instance_shader_parameter(&"era", float(piece.marks))
		world.content.add_child(view)
		row.append([String(kind), view, box, [view]])
	var walker := Walker.new()
	world.content.add_child(walker)
	walker.set_physics_process(false)
	walker._far.visible = false
	row.append(["walker", walker, AABB(Vector3(-2.0, -Walker.HIP_HIGH, -1.8), Vector3(4.0, 2.7, 3.6)), walker.painted()])
	row.append(["pod", null, AABB(Vector3(-1.2, -0.2, -0.7), Vector3(2.4, 1.4, 1.4)), []])
	var x: float = -0.5 * (row.reduce(func(s: float, e: Array) -> float: return s + e[2].size.x + WORLD_GAP, -WORLD_GAP))
	var me := _surveyor()
	world.content.add_child(me)
	var by := _to_world(Vector3(x - 1.5, 0.0, WORLD_Z))
	me.global_transform = Transform3D(Basis(Vector3.UP, _yaw + PI), Vector3(world.engine_x(by.x), world.height_at(by.x, by.y),
		world.engine_z(by.y)))
	var from := x
	var names: Array = []
	for each in row:
		var box: AABB = each[2]
		if x + box.size.x - from > WORLD_SHOT and x > from:
			_world_shots.append([from, x - WORLD_GAP, names])
			from = x
			names = []
		names.append(each[0])
		var at := Vector2(x + box.size.x * 0.5, WORLD_Z)
		var w := _to_world(Vector3(at.x - box.get_center().x, 0.0, at.y - box.get_center().z))
		var mid := _to_world(Vector3(at.x, 0.0, at.y))
		var sand := world.height_at(mid.x, mid.y)
		# A kit structure's floor at the sand, as a dug-out site's; the rest by their foot.
		var lift := 0.0 if each[1] is MeshInstance3D else -box.position.y
		var pose := Transform3D(Basis(Vector3.UP, _yaw), Vector3(world.engine_x(w.x), sand + lift, world.engine_z(w.y)))
		if each[0] == "pod":
			var before := world.content.get_children()
			var rig := PodShell.build(world.content, Transform3D(pose.basis, pose.origin + Vector3.UP * (Chassis.THICK * 0.5 - 0.08)))
			rig.deck.freeze = true
			for node in world.content.get_children():
				if not before.has(node):
					each[3].append(node)
					if node is RigidBody3D:
						(node as RigidBody3D).freeze = true
		else:
			(each[1] as Node3D).global_transform = pose
			if each[1] is Walker:
				walker._pose_legs(walker._feet(Vector3(pose.origin.x, 0.0, pose.origin.z), pose.basis, 0.0))
		_count += 1
		print("legend\tworld\t%d\t%s" % [_count, each[0]])
		var roots: Array = each[3] if each[0] == "pod" else [each[1]]
		_laid.append(["world", each[0], roots, [] if each[0] == "pod" else each[3], false])
		x += box.size.x + WORLD_GAP
	_world_shots.append([from, x - WORLD_GAP, names])
	for i in _world_shots.size():
		print("worldshot\tworld%d\t%s" % [i + 1, ", ".join(_world_shots[i][2])])
	# Overhead at its own size, as near as the game draws it, up the sky over the row.
	var ship := MeshInstance3D.new()
	ship.mesh = DeliveryshipLooks.craft()
	ship.set_instance_shader_parameter(&"age", Deliveryship.AGE)
	# Up in its orbit it shades nothing here.
	ship.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.content.add_child(ship)
	ship.global_transform = Transform3D(Basis(Vector3.UP, _yaw + 0.5), _engine(_ship_at()))
	_laid.append(["world", "deliveryship", [ship], [ship], false])


## The deliveryship's middle, camp frame: SHIP_OFF from the world row's eye,
## 32 degrees up, the other way from the lineup so it stays out of the row's shots.
func _ship_at() -> Vector3:
	var up := deg_to_rad(32.0)
	return Vector3(0.0, 1.7 + sin(up) * SHIP_OFF, WORLD_Z + 6.0 + cos(up) * SHIP_OFF)


static func _views(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		out.append(root)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).mesh != null:
			out.append(node)
	return out


## Its own painted look, where it has one: what its pieces are counted on.
static func _main(node: Node3D) -> MeshInstance3D:
	var device := node as Device
	if device != null and device.frame_view != null:
		return device.frame_view
	if node is MeshInstance3D:
		return node
	for view in _views(node):
		if Paint.is_worn(view) and not view.get_parent() is Socket:
			return view
	return null


## One tab-separated line: block, label, triangles, draws (surfaces drawn,
## shadows aside), pieces (of its own looks: runs of one coat, split where
## they don't touch), and the materials it draws with.
func _audit(each: Array) -> void:
	var tris := 0
	var draws := 0
	var mats := {}
	for root: Node in each[2]:
		for view in _views(root):
			if not view.is_visible_in_tree():
				continue
			for s in view.mesh.get_surface_count():
				draws += 1
				tris += _triangles(view.mesh, s)
				mats[_material(view, s)] = true
	var own: Array = each[3]
	if own.is_empty():
		for root: Node in each[2]:
			own.append_array(_views(root).filter(func(v: MeshInstance3D) -> bool: return Paint.is_worn(v)))
	var pieces := 0
	for view: MeshInstance3D in own:
		pieces += _pieces(view.mesh)
	print("audit\t%s\t%s\t%d\t%d\t%d\t%s%s" % [each[0], each[1], tris, draws, pieces, ",".join(mats.keys()),
		"\tGREY" if each[4] else ""])


static func _triangles(mesh: Mesh, s: int) -> int:
	var arrays := mesh.surface_get_arrays(s)
	var index = arrays[Mesh.ARRAY_INDEX]
	return (index.size() if index != null and index.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3


static func _material(view: MeshInstance3D, s: int) -> String:
	var mat := view.material_override
	if mat == null:
		mat = view.get_surface_override_material(s)
	if mat == null:
		mat = view.mesh.surface_get_material(s)
	if mat == Paint.worn():
		return "worn"
	var what := "none" if mat == null else mat.get_class().trim_suffix("Material3D").to_lower()
	if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null:
		what = (mat as ShaderMaterial).shader.resource_path.get_file().get_basename()
	return "%s %s" % [what, view.mesh.get_class()]


## Pieces in a mesh: runs of vertices in one coat and size (Paint.Pieces adds
## each piece's together), each split into the parts whose corners don't meet.
static func _pieces(mesh: Mesh) -> int:
	var count := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var index = arrays[Mesh.ARRAY_INDEX]
		var order: PackedInt32Array = index if index != null and index.size() > 0 else PackedInt32Array(range(verts.size()))
		var colours = arrays[Mesh.ARRAY_COLOR]
		var sizes = arrays[Mesh.ARRAY_CUSTOM1]
		var coated: bool = colours != null and sizes != null and colours.size() == verts.size() \
			and sizes.size() == verts.size() * 4
		var parent := PackedInt32Array(range(verts.size()))
		var seen := {}
		var last := -1
		for i in order.size():
			var k := order[i]
			if last < 0 or (coated and (colours[k] != colours[last] or sizes[k * 4] != sizes[last * 4]
					or sizes[k * 4 + 1] != sizes[last * 4 + 1] or sizes[k * 4 + 2] != sizes[last * 4 + 2]
					or sizes[k * 4 + 3] != sizes[last * 4 + 3])):
				seen.clear()
			last = k
			var at := Vector3i((verts[k] * 1e4).round())
			if seen.has(at):
				_join(parent, seen[at], k)
			else:
				seen[at] = k
			if i % 3 == 2:
				_join(parent, order[i - 2], order[i - 1])
				_join(parent, order[i - 1], k)
		var roots := {}
		for k in order:
			roots[_root(parent, k)] = true
		count += roots.size()
	return count


static func _root(parent: PackedInt32Array, k: int) -> int:
	while parent[k] != k:
		parent[k] = parent[parent[k]]
		k = parent[k]
	return k


static func _join(parent: PackedInt32Array, a: int, b: int) -> void:
	var ra := _root(parent, a)
	var rb := _root(parent, b)
	if ra != rb:
		parent[ra] = rb


## Labelled, each block from 5 m, and the small things' front lines close.
## Otherwise the whole lineup from 20 m, the world's row in stretches and the
## deliveryship; at dusk the whole and the camp block; in a storm, from inside
## the camp's bubble, the camp block within it and the power block past its wall.
func _shots() -> Array:
	var out := []
	if _labels:
		for block: String in _blocks:
			var b: Vector3 = _blocks[block]
			out.append([block + "5", "midmorning", _eye5(b), Vector3(b.x, 0.25, b.z)])
			if block in CLOSE:
				var front := b.z + b.y * 0.5
				out.append([block + "_close", "midmorning", Vector3(b.x + 0.3, 1.5, front + 1.3), Vector3(b.x, 0.05, front - 0.9)])
		return out
	out.append(["all20", "midmorning", Vector3(5.0, 9.0, 29.0), Vector3(0.0, 0.3, 10.0)])
	for i in _world_shots.size():
		var span: Array = _world_shots[i]
		var middle: float = (span[0] + span[1]) * 0.5
		var off := maxf(18.0, (span[1] - span[0]) * 0.6)
		out.append(["world%d" % (i + 1), "midmorning", Vector3(middle + 3.0, 5.0, WORLD_Z + off), Vector3(middle, 1.5, WORLD_Z)])
	out.append(["sky", "midmorning", Vector3(0.0, 1.7, WORLD_Z + 6.0), _ship_at()])
	out.append(["dusk20", "dusk", Vector3(5.0, 9.0, 29.0), Vector3(0.0, 0.3, 10.0)])
	var camp: Vector3 = _blocks["camp"]
	out.append(["dusk_camp5", "dusk", _eye5(camp), Vector3(camp.x, 0.25, camp.z)])
	out.append(["storm_camp", "storm", Vector3(0.7, 1.8, 0.9), Vector3(0.0, 0.4, camp.z + 0.5)])
	out.append(["storm_power", "storm", Vector3(-3.2, 1.8, 1.4), Vector3(-8.5, 0.4, 4.4)])
	return out


## 5 m from a block's middle (`b`: x, depth, z), or just clear of its front line.
static func _eye5(b: Vector3) -> Vector3:
	return Vector3(b.x + 0.5, 3.2, b.z + maxf(3.9, b.y * 0.5 + 2.4))
