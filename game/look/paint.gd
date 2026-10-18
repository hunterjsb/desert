class_name Paint
extends RefCounted
## B, chunky worn industrial, on the game's own shapes until real models come
## (docs/art-direction.md). Company issue: gunmetal frames, teal panels and
## safety yellow; the shield's own maker in bone white. Everything worn shares
## one material: a device's pieces merge into one mesh, and how worn it is
## rides on the instance, so a camp costs the draws grey boxes did.

const GUNMETAL := Color(0.26, 0.28, 0.29)
const TEAL := Color(0.18, 0.4, 0.43)
const BONE := Color(0.8, 0.76, 0.66)
const YELLOW := Color(0.86, 0.62, 0.12)
const BLACK := Color(0.08, 0.08, 0.08)
const STEEL := Color(0.62, 0.62, 0.6)
const CELL := Color(0.06, 0.09, 0.17)
const SOIL := Color(0.2, 0.13, 0.08)
const RUST := Color(0.4, 0.16, 0.07)
const ROPE := Color(0.42, 0.31, 0.2)
## Sun-faded rubber, in the water socket's blue.
const HOSE := Color(0.2, 0.36, 0.46)

## How worn each era's paint starts, before the weather: deep things were
## sealed away, surface ones were made crude and left out. Older is better.
const ERA := {&"deep": 0.05, &"surface": 0.5}
const ERA_NEW := 0.15
## What a lifetime in the weather adds, from sound to wrecked.
const WEATHERED := 0.8
## Maker's marks, by column of the atlas (marks.py). Batteries and the like
## carry none, so a mark means something where it's found. Past the sixth,
## the marks later hands put over them, the atlas's bottom row: the houses'
## crests and the sign of Tu.
enum Mark { CONTRACTOR, SHIELD_MAKER, WIND_MAKER, CONSIGNMENT, SKIMMER_CREW, MEMBER_STATE,
	OKAFOR, KESSEL, ARKWRIGHT, VANTE, TU }
## A scratch is cut through the paint to the metal.
enum Ink { DARK, PALE, SCRATCH }
## Each era's row of the atlas: the hands its marks were put on by.
const MARK_ROW := {&"surface": 1, &"deep": 2}
const MARKS := preload("res://game/look/marks.png")

## A lineage's look (Eras.lineage). How worn its paint starts by its last
## hands' era, as ERA does by a find's layer: colonial gear sealed away, the
## First Kingdoms' kept clean, the skimmer era's worn hard, the second age's
## out in the weather. Its maker's stamp is from its first hands' row: later
## hands add their marks over it and never paint it out.
const AGE_BY_ERA := {Eras.COLONIAL: 0.05, Eras.FIRST: 0.1, Eras.SKIMMER: 0.3, Eras.SECOND: 0.45, Eras.NEW: 0.15}
const ROW_BY_ERA := {Eras.COLONIAL: 2, Eras.SKIMMER: 2, Eras.NEW: 0}
## A part has no soundness of its own yet: it looks this sound.
const PART_SOUND := 0.8
## The houses' heraldry: its crest, its band's enamel and its plaque's (the
## houses' colours, deep red, ochre and teal, part 5; Vante's pairing is a
## default).
const HOUSE := {&"okafor": [Mark.OKAFOR, Color(0.48, 0.08, 0.07), Color(0.48, 0.08, 0.07)],
	&"kessel": [Mark.KESSEL, Color(0.74, 0.5, 0.14), Color(0.74, 0.5, 0.14)],
	&"arkwright": [Mark.ARKWRIGHT, Color(0.04, 0.4, 0.38), Color(0.04, 0.4, 0.38)],
	&"vante": [Mark.VANTE, Color(0.74, 0.5, 0.14), Color(0.48, 0.08, 0.07)]}
## The ages after's materials (part 5): brass fittings; fern cord, salt-glazed
## ceramic, saltbush wood, limewash, sand-glass, a dyed leather tassel, and
## the Cistern's deep water-blue glaze. A plate off something else is in
## another thing's paint.
const BRASS := Color(0.7, 0.52, 0.22)
const CORD := Color(0.4, 0.33, 0.21)
const CERAMIC := Color(0.8, 0.74, 0.62)
const GLAZE := Color(0.08, 0.22, 0.5)
const SALTWOOD := Color(0.45, 0.39, 0.3)
const LIMEWASH := Color(0.85, 0.81, 0.71)
const SAND_GLASS := Color(0.6, 0.68, 0.6)
const DYED := Color(0.55, 0.22, 0.12)
const SCRAP: Array[Color] = [YELLOW, TEAL, BONE, STEEL]

static var _worn: ShaderMaterial
static var _noise: NoiseTexture2D
static var _read := {}


## The one worn material, white paint so each piece's colour shows.
static func worn() -> ShaderMaterial:
	if _worn == null:
		_worn = ShaderMaterial.new()
		_worn.shader = preload("res://game/look/worn.gdshader")
		_worn.set_shader_parameter("paint", Color.WHITE)
		_worn.set_shader_parameter("wear", 1.0)
		_worn.set_shader_parameter("noise", noise())
		_worn.set_shader_parameter("marks", MARKS)
	return _worn


static func noise() -> NoiseTexture2D:
	if _noise == null:
		var gen := FastNoiseLite.new()
		gen.frequency = 0.02
		gen.fractal_octaves = 4
		_noise = NoiseTexture2D.new()
		_noise.noise = gen
		_noise.seamless = true
		_noise.width = 256
		_noise.height = 256
		_noise.generate_mipmaps = true
	return _noise


## The run's prevailing wind heading, radians: a century of it scoured one side.
static func face_wind(heading: float) -> void:
	var downwind := Vector3(cos(heading), 0.0, sin(heading))
	worn().set_shader_parameter("wind_dir", downwind)


## How worn something looks, 0 to 1: its era's paint, then what the weather took.
static func age_of(layer: StringName, sound: float) -> float:
	return clampf(ERA.get(layer, ERA_NEW) + (1.0 - sound) * WEATHERED, 0.0, 1.0)


## Which era's marks a find of this layer carries.
static func era_of(layer: StringName) -> float:
	return MARK_ROW.get(layer, 0)


## How worn a thing looks at a soundness: by its lineage's era, or without
## one as it always did, by the layer it was found in.
static func age_for(body: Node, sound: float) -> float:
	var line: Array = body.get_meta(&"lineage", [])
	if line.is_empty():
		return age_of(body.get_meta(&"layer", &""), sound)
	return clampf(AGE_BY_ERA.get(Eras.era_of(line), ERA_NEW) + (1.0 - sound) * WEATHERED, 0.0, 1.0)


## Which row of the atlas its own marks are from.
static func row_for(body: Node) -> float:
	var line: Array = body.get_meta(&"lineage", [])
	if line.is_empty():
		return era_of(body.get_meta(&"layer", &""))
	return ROW_BY_ERA.get(Eras.origin(line), 2)


## A thing's own look with what its lineage added over it (Over's arrays),
## merged into one mesh, one draw. Its own look's arrays are read back once.
static func merged(own: ArrayMesh, overs: Array) -> ArrayMesh:
	if not _read.has(own):
		_read[own] = own.surface_get_arrays(0)
	var arrays: Array = (_read[own] as Array).duplicate(true)
	for add: Array in overs:
		for c in arrays.size():
			if arrays[c] != null:
				arrays[c].append_array(add[c])
	var custom := 0
	for i in 4:
		custom |= own.surface_get_format(0) & (Mesh.ARRAY_FORMAT_CUSTOM_MASK
			<< (Mesh.ARRAY_FORMAT_CUSTOM_BASE + i * Mesh.ARRAY_FORMAT_CUSTOM_BITS))
	var made := ArrayMesh.new()
	made.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, custom)
	made.surface_set_material(0, worn())
	return made


## Shows an age on every worn mesh among a body's own children.
static func show_age(body: Node, amount: float) -> void:
	for child in body.get_children():
		if is_worn(child):
			(child as GeometryInstance3D).set_instance_shader_parameter(&"age", amount)


static func is_worn(node: Node) -> bool:
	var view := node as MeshInstance3D
	return view != null and view.mesh != null and view.mesh.get_surface_count() > 0 \
		and view.mesh.surface_get_material(0) == worn()


## A finish: paint colour, its share of the wear, metalness, roughness, how
## much sand it holds, and how bright it glows while lit.
static func coat(color: Color, share := 1.0, metal := 0.0, rough := 0.6, dust := 1.0, glow := 0.0) -> Coat:
	var made := Coat.new()
	made.color = color
	made.share = share
	made.metal = metal
	made.rough = rough
	made.dust = dust
	made.glow = glow
	return made


class Coat:
	var color: Color
	var share: float
	var metal: float
	var rough: float
	var dust: float
	var glow: float


## Pieces merged into one mesh in the worn material, each carrying its own
## frame so its edges chip where they are.
class Pieces:
	var _tool := SurfaceTool.new()
	var _any := false
	var _foot: float
	var _stamp: Transform3D
	var _facing: Vector3
	var _mark := -1
	var _ink := 0
	var _row := -1
	## Where its marks went and which: what a lineage's marks keep clear of.
	var _stamps := PackedVector3Array()
	var _marks: Array[int] = []
	static var _cube := []

	## `foot` is where the whole thing meets the sand, in its own frame;
	## without one, nothing drifts against its foot.
	func _init(foot := -INF) -> void:
		_foot = foot
		_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 3:
			_tool.set_custom_format(i, SurfaceTool.CUSTOM_RGBA_FLOAT)
		_tool.set_custom_format(3, SurfaceTool.CUSTOM_R_FLOAT)

	## A box with its edges cut back by `cut`: the bevel catches a line of
	## light, which is most of what reads as made at a distance. Uncut, a
	## plain box, a quarter the triangles.
	func box(size: Vector3, at: Vector3, look: Coat, cut := 0.01, turn := Basis.IDENTITY) -> void:
		_add(_chamfer(size, cut) if cut > 0.0 else _plain(size), Transform3D(turn, at), look, size * 0.5, 1.0)

	## A cylinder along its own y, turned as told.
	func drum(radius: float, height: float, at: Vector3, look: Coat, turn := Basis.IDENTITY, sides := 16,
			top := -1.0) -> void:
		var m := CylinderMesh.new()
		m.bottom_radius = radius
		m.top_radius = radius if top < 0.0 else top
		m.height = height
		m.radial_segments = sides
		m.rings = 1
		_add(m.get_mesh_arrays(), Transform3D(turn, at), look, Vector3(radius, height * 0.5, radius), 2.0)

	## A ring lying in its own xz plane.
	func ring(inner: float, outer: float, at: Vector3, look: Coat, turn := Basis.IDENTITY, sides := 8) -> void:
		var m := TorusMesh.new()
		m.inner_radius = inner
		m.outer_radius = outer
		m.rings = 16
		m.ring_segments = sides
		# No edges to chip on a ring: its half extents reach well past it.
		_add(m.get_mesh_arrays(), Transform3D(turn, at), look, Vector3.ONE, 1.0)

	func ball(radius: float, at: Vector3, look: Coat, scale := Vector3.ONE, turn := Basis.IDENTITY) -> void:
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius * 2.0
		m.radial_segments = 12
		m.rings = 6
		_add(m.get_mesh_arrays(), Transform3D(turn * Basis.from_scale(scale), at), look, Vector3.ONE, 1.0)

	## Paints a mark on the next piece's faces turned to `turn`'s +Z, centred
	## at `at`, `width` across its x and half that up its y; from `row` of the
	## atlas, or its thing's era's.
	func stamp(mark: Mark, at: Vector3, width: float, turn := Basis.IDENTITY, ink := Ink.DARK, row := -1) -> Pieces:
		_mark = mark
		_ink = ink
		_row = row
		_stamp = Transform3D(turn * Basis.from_scale(Vector3(width, width * 0.5, 1.0)), at).affine_inverse()
		_facing = turn.z.normalized()
		_stamps.append(at)
		_marks.append(mark)
		return self

	func commit() -> ArrayMesh:
		var made := _tool.commit() if _any else ArrayMesh.new()
		if made.get_surface_count() > 0:
			made.surface_set_material(0, Paint.worn())
		made.set_meta(&"stamps", _stamps)
		made.set_meta(&"marks", _marks)
		return made

	func _add(arrays: Array, place: Transform3D, look: Coat, half: Vector3, shape: float) -> void:
		_any = true
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var index = arrays[Mesh.ARRAY_INDEX]
		var order: PackedInt32Array = index if index != null and index.size() > 0 else PackedInt32Array(range(verts.size()))
		var turn := place.basis.inverse().transposed()
		# The palette is picked by eye, in sRGB; the shader lights in linear.
		var paint := look.color.srgb_to_linear()
		# Only the faces turned to the mark take it.
		var marked := false
		for i in order.size():
			var k := order[i]
			var v := verts[k]
			var placed := place * v
			if i % 3 == 0 and _mark >= 0:
				var n := normals[k] + normals[order[i + 1]] + normals[order[i + 2]]
				marked = (turn * n).normalized().dot(_facing) > 0.7
			var on := _stamp * placed if marked else Vector3.ZERO
			_tool.set_uv(Vector2(on.x + 0.5, 0.5 - on.y))
			_tool.set_uv2(Vector2(_mark + 1, _ink + 4 * (_row + 1)) if marked else Vector2.ZERO)
			_tool.set_color(paint)
			_tool.set_custom(0, Color(v.x, v.y, v.z, shape))
			_tool.set_custom(1, Color(half.x, half.y, half.z, look.metal))
			_tool.set_custom(2, Color(look.rough, look.dust, look.glow, look.share))
			_tool.set_custom(3, Color(placed.y - _foot if is_finite(_foot) else 1e3, 0.0, 0.0))
			_tool.set_normal((turn * normals[k]).normalized())
			_tool.add_vertex(placed)
		_mark = -1

	## A plain box's triangles, from the unit cube's.
	static func _plain(size: Vector3) -> Array:
		if _cube.is_empty():
			_cube = _chamfer(Vector3.ONE, 0.0)
		var verts: PackedVector3Array = _cube[Mesh.ARRAY_VERTEX].duplicate()
		for i in verts.size():
			verts[i] *= size
		var arrays := _cube.duplicate()
		arrays[Mesh.ARRAY_VERTEX] = verts
		return arrays

	## A chamfered box's triangles, flat-shaded, in its own frame.
	static func _chamfer(size: Vector3, cut: float) -> Array:
		var h := size * 0.5
		var c := minf(cut, minf(h.x, minf(h.y, h.z)) * 0.9)
		var polys: Array[PackedVector3Array] = []
		# Each corner's three points, one on each face meeting there.
		var pts := {}
		for sx in [-1, 1]:
			for sy in [-1, 1]:
				for sz in [-1, 1]:
					var s := Vector3(sx, sy, sz)
					pts[s] = [Vector3(sx * h.x, sy * (h.y - c), sz * (h.z - c)),
						Vector3(sx * (h.x - c), sy * h.y, sz * (h.z - c)),
						Vector3(sx * (h.x - c), sy * (h.y - c), sz * h.z)]
					polys.append(PackedVector3Array(pts[s]))
		for axis in 3:
			for side in [-1, 1]:
				var face := PackedVector3Array()
				for k in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
					var s := Vector3.ZERO
					s[axis] = side
					s[(axis + 1) % 3] = k[0]
					s[(axis + 2) % 3] = k[1]
					face.append(pts[s][axis])
				polys.append(face)
		for axis in 3:
			var a1 := (axis + 1) % 3
			var a2 := (axis + 2) % 3
			for s1 in [-1, 1]:
				for s2 in [-1, 1]:
					var lo := Vector3.ZERO
					lo[axis] = -1
					lo[a1] = s1
					lo[a2] = s2
					var hi := lo
					hi[axis] = 1
					polys.append(PackedVector3Array([pts[lo][a1], pts[lo][a2], pts[hi][a2], pts[hi][a1]]))
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()
		for poly in polys:
			var mid := Vector3.ZERO
			for p in poly:
				mid += p
			mid /= poly.size()
			# Uncut, a corner or an edge has no face.
			if (poly[1] - poly[0]).cross(poly[-1] - poly[0]).length_squared() < 1e-14:
				continue
			var n := (poly[1] - poly[0]).cross(poly[2] - poly[0]).normalized()
			if n.dot(mid) > 0.0:
				poly.reverse()
				n = -n
			for i in range(1, poly.size() - 1):
				for p in [poly[0], poly[i], poly[i + 1]]:
					verts.append(p)
					normals.append(-n)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		return arrays


## Where a lineage's marks go on a thing, worked out once a thing from its own
## look: its box, or the round body in it, seen from its top (a frame's, or
## the face a part shows out of its socket), with the spots on its faces that
## sit flat and keep clear of its sockets and stamps, and its corners, best
## first. Each lineage entry's marks are drawn on it alone, so they cache by
## entry and stack in any lineage without meeting.
class Shell:
	## From the shell's frame, its y up out of its foot or its socket, to the thing's.
	var to_thing := Transform3D.IDENTITY
	var lo: Vector3
	var hi: Vector3
	## The solid top a rim, a cap or a loop sits on.
	var top: float
	## A round body's radius, and the heights it spans; none, a box.
	var radius := 0.0
	var span := Vector2.ZERO
	## The size its marks are drawn to, m.
	var unit: float
	var part: bool
	## Which way is down when it's fitted, so what hangs from it hangs: a
	## part's sockets mostly face sideways, its top up.
	var down := Vector3.DOWN
	## Its own stamps say who it was consigned to: the Dark Age daubs it back.
	var consigned := false
	## Its spots, each facing out along its +Z and up its +Y: for a plaque, a
	## plate, a patch and a charm, in that order.
	var spots: Array[Transform3D] = []
	## Its top corners, or points round a round one's rim, each facing out,
	## and where its edge is at a lashing's height: INF where it has none.
	var corners: Array[Transform3D] = []
	var edges: Array[Vector3] = []
	var _scrap: Color
	var _hit: TriangleMesh

	func _init(look: ArrayMesh, box: AABB, is_part: bool, round: Array, avoid: PackedVector3Array, pick: int) -> void:
		part = is_part
		if part:
			to_thing = Transform3D(Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN), Vector3.ZERO)
			down = Vector3.BACK
		var back := to_thing.affine_inverse()
		var local := back * box
		lo = local.position
		hi = local.end
		var sides := [box.size.x, box.size.y, box.size.z]
		sides.sort()
		unit = clampf(sides[1] * 0.12, 0.006, 0.05)
		_scrap = SCRAP[absi(pick) % SCRAP.size()]
		consigned = (look.get_meta(&"marks", []) as Array).has(Mark.CONSIGNMENT)
		var keep := PackedVector3Array()
		for p in avoid + (look.get_meta(&"stamps", PackedVector3Array()) as PackedVector3Array):
			keep.append(back * p)
		_hit = look.generate_triangle_mesh()
		if not round.is_empty():
			radius = round[0] * (hi.x - lo.x) * 0.5
			span = Vector2(lerpf(lo.y, hi.y, round[1]), lerpf(lo.y, hi.y, round[2]))
		top = span.y if radius > 0.0 else _top()
		_find_corners(keep)
		_find_spots(keep)
		_hit = null

	## The marks one lineage entry adds.
	func layer(b: Over, entry: Array) -> void:
		var how: Array = entry[2]
		match entry[1]:
			&"marked":
				if not how.is_empty() and HOUSE.has(how[0]):
					_heraldry(b, HOUSE[how[0]])
			&"remade":
				for work: StringName in how:
					match work:
						&"cord":
							_lash(b)
						&"ceramic":
							_cap(b, 3, Paint.coat(CERAMIC, 0.15, 0.0, 0.3, 0.6))
						&"plate":
							_plate(b)
						&"wood":
							_splint(b)
			&"blessed":
				var cistern := how.has(&"cistern")
				for gift: StringName in how:
					match gift:
						&"tu":
							_sign(b)
						&"charm":
							_charm(b, GLAZE if cistern else CERAMIC)
						&"tassel":
							_tassel(b)
						&"vial":
							_vial(b)
						&"cistern":
							_cap(b, 1, Paint.coat(GLAZE, 0.1, 0.0, 0.18, 0.4))

	## A house's: an enamel band round its top, and its crest cut into an
	## enamel plaque, riveted in brass.
	func _heraldry(b: Over, house: Array) -> void:
		var band := Paint.coat(house[1], 0.5, 0.1, 0.25, 0.6)
		var t := unit * 0.5
		if radius > 0.0:
			_drum(b, radius + t * 0.6, t * 1.2, Vector3(0.0, top - t * 1.1, 0.0), band, Basis.IDENTITY, 16)
		elif part:
			_loop(b, lerpf(lo.y, top, 0.8), unit * 0.3, unit * 0.9, band)
		else:
			_rim(b, top, t, band)
		if spots.is_empty():
			return
		var at := spots[0]
		_box(b, Vector3(unit * 1.9, unit * 2.3, unit * 0.24), at * Vector3(0.0, 0.0, unit * 0.1),
			Paint.coat(house[2], 0.5, 0.1, 0.25, 0.6), at.basis, [house[0], unit * 4.6, Ink.SCRATCH, -1])
		for x in [-1.0, 1.0]:
			_drum(b, unit * 0.18, unit * 0.12, at * Vector3(x * unit * 0.62, unit * 0.86, unit * 0.24),
				Paint.coat(BRASS, 0.3, 0.9, 0.35, 0.5), at.basis * Basis(Vector3.RIGHT, PI / 2.0), 6)

	## Cord lashed round it: round a round body, round a part's body, or at
	## two of a frame's corners, where a cracked post was bound.
	func _lash(b: Over) -> void:
		var cord := Paint.coat(CORD, 0.0, 0.0, 0.95, 0.7)
		if radius > 0.0:
			for k in 3:
				_drum(b, radius + unit * 0.18, unit * 0.3, Vector3(0.0, lerpf(span.x, span.y, 0.4) + k * unit * 0.42, 0.0),
					cord, Basis.IDENTITY, 16)
		elif part:
			for k in 2:
				_loop(b, lerpf(lo.y, top, 0.5) + k * unit * 0.5, unit * 0.3, unit * 0.32, cord)
		else:
			var done := 0
			for i in corners.size():
				if done == 2:
					break
				if edges[i].is_finite():
					for k in 3:
						_drum(b, unit * 0.8, unit * 0.3, edges[i] + Vector3.UP * k * unit * 0.42, cord, Basis.IDENTITY, 6)
					done += 1

	## A lost part rebuilt round: a ceramic cap on a corner, domed.
	func _cap(b: Over, k: int, look: Coat) -> void:
		if corners.size() <= k:
			return
		var c := corners[k]
		var middle := c.origin - c.basis.z * unit * (0.6 if radius > 0.0 else 0.85)
		_drum(b, unit * 1.25, unit * 0.7, middle + Vector3.UP * unit * 0.25, look, Basis.IDENTITY, 8)
		_drum(b, unit * 1.1, unit * 0.32, middle + Vector3.UP * unit * 0.76, look, Basis.IDENTITY, 8, unit * 0.55)

	## A plate off something else, in its paint, riveted on crooked; on what
	## was consigned, the code daubed back on it from memory.
	func _plate(b: Over) -> void:
		if spots.size() < 2:
			return
		var at := spots[1]
		var turn := at.basis * Basis(Vector3.BACK, 0.08 if at.origin.x >= 0.0 else -0.08)
		_box(b, Vector3(unit * 2.2, unit * 2.0, unit * 0.2), at * Vector3(0.0, 0.0, unit * 0.07),
			Paint.coat(_scrap, 1.2, 0.3 if _scrap == STEEL else 0.0, 0.6), turn,
			[Mark.CONSIGNMENT, unit * 2.2, Ink.DARK, 1] if consigned else [])
		for x in [-1.0, 1.0]:
			for y in [-1.0, 1.0]:
				_drum(b, unit * 0.15, unit * 0.1, at * Vector3(x * unit * 0.88, y * unit * 0.78, unit * 0.18),
					Paint.coat(STEEL, 0.8, 0.6), turn * Basis(Vector3.RIGHT, PI / 2.0), 4)

	## A saltbush-wood splint along an edge, lashed at both ends.
	func _splint(b: Over) -> void:
		var wood := Paint.coat(SALTWOOD, 0.1, 0.0, 0.85, 0.6)
		var cord := Paint.coat(CORD, 0.0, 0.0, 0.95, 0.7)
		var k := mini(2, corners.size() - 1)
		if k < 0 or not edges[k].is_finite():
			return
		var out := corners[k].basis.z
		var low := span.x if radius > 0.0 else lo.y
		var long := (top - low) * 0.75
		var at := Vector3(edges[k].x, (top + low) * 0.5, edges[k].z) + out * unit * 0.3
		_box(b, Vector3(unit * 0.42, long, unit * 0.42), at, wood, corners[k].basis)
		for y in [-0.3, 0.3]:
			_drum(b, unit * 0.62, unit * 0.28, at - out * unit * 0.2 + Vector3.UP * long * y, cord, Basis.IDENTITY, 6)

	## The sign of Tu, daubed on a limewashed patch.
	func _sign(b: Over) -> void:
		if spots.size() < 3:
			return
		var at := spots[2]
		_box(b, Vector3(unit * 2.2, unit * 1.1, unit * 0.1), at * Vector3(0.0, 0.0, unit * 0.03),
			Paint.coat(LIMEWASH, 0.4, 0.0, 0.85, 0.8), at.basis, [Mark.TU, unit * 2.2, Ink.DARK, -1])

	## A charm hung on cord: a disc and a bead, from a frame's top or above
	## its spot on a part; on what faces up, it lies there.
	func _charm(b: Over, color: Color) -> void:
		if spots.size() < 4:
			return
		var at := spots[3]
		var n := at.basis.z
		var hang := -down
		var look := Paint.coat(color, 0.1, 0.0, 0.3, 0.4)
		if absf(n.dot(down)) < 0.7:
			var from := at.origin + hang * unit * 1.6 if part \
				else Vector3(at.origin.x, maxf(top, at.origin.y + unit), at.origin.z)
			var to := at.origin + hang * unit * 0.6
			_box(b, Vector3(unit * 0.1, from.distance_to(to), unit * 0.1), (from + to) * 0.5 + n * unit * 0.15,
				Paint.coat(CORD, 0.0, 0.0, 0.95, 0.7), Basis(hang.cross(n), hang, n))
		_drum(b, unit * 0.62, unit * 0.16, at.origin + n * unit * 0.12, look, at.basis * Basis(Vector3.RIGHT, PI / 2.0), 8)
		_box(b, Vector3.ONE * unit * 0.36, at.origin + at.basis.y * unit * 0.62 + n * unit * 0.18,
			Paint.coat(DYED, 0.0, 0.0, 0.5, 0.3), at.basis)

	## A tassel of dyed cord from a top corner, knotted, hanging down.
	func _tassel(b: Over) -> void:
		if corners.is_empty():
			return
		var c := corners[0]
		var hang := -down
		var out := (c.basis.z - hang * c.basis.z.dot(hang)).normalized()
		var turn := Basis(hang.cross(out), hang, out)
		var knot := c.origin + out * unit * 0.35 + hang * unit * 0.1
		var dyed := Paint.coat(DYED, 0.0, 0.0, 0.9, 0.5)
		_box(b, Vector3.ONE * unit * 0.5, knot, Paint.coat(CORD, 0.0, 0.0, 0.9, 0.5), turn)
		for k in [-1.0, 0.0, 1.0]:
			var lean := turn * Basis(Vector3.BACK, k * 0.2)
			_box(b, Vector3(unit * 0.1, unit * 1.7, unit * 0.1), knot + lean * Vector3(0.0, -unit * 1.0, 0.0), dyed, lean)

	## A water vial of sand-glass, stoppered with saltbush wood, tied on.
	func _vial(b: Over) -> void:
		if spots.size() < 4:
			return
		var at := spots[3]
		var n := at.basis.z
		# Upright on a side; lying along it on a top.
		var along := at.basis if absf(n.y) < 0.7 else at.basis * Basis(Vector3.BACK, PI / 2.0)
		var middle := at.origin + n * unit * 0.42
		_drum(b, unit * 0.38, unit * 1.5, middle, Paint.coat(SAND_GLASS, 0.0, 0.2, 0.12, 0.3), along, 6)
		_drum(b, unit * 0.28, unit * 0.3, middle + along.y * unit * 0.85, Paint.coat(SALTWOOD, 0.0, 0.0, 0.85, 0.5), along, 6)
		_drum(b, unit * 0.42, unit * 0.14, middle, Paint.coat(CORD, 0.0, 0.0, 0.95, 0.7), along, 6)

	## Strips round a box's top edges.
	func _rim(b: Over, y: float, t: float, look: Coat) -> void:
		var mid := (lo + hi) * 0.5
		var w := hi.x - lo.x
		var d := hi.z - lo.z
		for s in [-1.0, 1.0]:
			_box(b, Vector3(w + t, t, t), Vector3(mid.x, y, mid.z + s * d * 0.5), look)
			_box(b, Vector3(t, t, d - t - 0.002), Vector3(mid.x + s * w * 0.5, y, mid.z), look)

	## A loop round a box's body at a height, sunk a little into it.
	func _loop(b: Over, y: float, t: float, w: float, look: Coat) -> void:
		var mid := (lo + hi) * 0.5
		var sx := hi.x - lo.x
		var sz := hi.z - lo.z
		var out := t * 0.5 - unit * 0.35
		for s in [-1.0, 1.0]:
			_box(b, Vector3(sx + 2.0 * (t + out), w, t), Vector3(mid.x, y, mid.z + s * (sz * 0.5 + out)), look)
			_box(b, Vector3(t, w, sz + 2.0 * out - 0.002), Vector3(mid.x + s * (sx * 0.5 + out), y, mid.z), look)

	## A plain box, with a mark on its outer face as [mark, width, ink, row].
	func _box(b: Over, size: Vector3, at: Vector3, look: Coat, turn := Basis.IDENTITY, mark := []) -> void:
		b.box(size, to_thing * Transform3D(turn, at), look, mark)

	func _drum(b: Over, r: float, tall: float, at: Vector3, look: Coat, turn := Basis.IDENTITY, sides := 8,
			narrow := -1.0) -> void:
		b.drum(r, tall, to_thing * Transform3D(turn, at), look, sides, narrow)

	## Where a ray from a point in its frame meets its look, or INF.
	func _cast(from: Vector3, way: Vector3) -> Vector3:
		var hit := _hit.intersect_ray(to_thing * from, to_thing.basis * way)
		return to_thing.affine_inverse() * (hit.position as Vector3) if not hit.is_empty() else Vector3.INF

	## Its solid top: the lowest its edges stand, each read just in from it
	## past any bevel, so a rim never floats.
	func _top() -> float:
		var y := INF
		var mid := (lo + hi) * 0.5
		var half := (hi - lo) * 0.5
		for edge in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var edge_y := -INF
			for inset in [0.6, 1.5]:
				var at := _cast(Vector3(mid.x + edge.x * (half.x - unit * inset), hi.y + 1.0,
					mid.z + edge.y * (half.z - unit * inset)), Vector3.DOWN)
				if at.is_finite():
					edge_y = maxf(edge_y, at.y)
			if is_finite(edge_y):
				y = minf(y, edge_y)
		return y if is_finite(y) else hi.y

	func _find_corners(keep: PackedVector3Array) -> void:
		var found := []
		var mid := (lo + hi) * 0.5
		if radius > 0.0:
			for k in 8:
				var a := (k + 0.5) * TAU / 8.0
				var out := Vector3(sin(a), 0.0, cos(a))
				var edge := _cast(out * (radius + 0.2) + Vector3.UP * lerpf(span.x, span.y, 0.4), -out)
				found.append([Transform3D(_facing(out), out * radius + Vector3.UP * top), edge])
		else:
			for sx in [1.0, -1.0]:
				for sz in [1.0, -1.0]:
					var c := Vector3(hi.x if sx > 0.0 else lo.x, top, hi.z if sz > 0.0 else lo.z)
					var out := Vector3(sx, 0.0, sz).normalized()
					var down := _cast(c - out * unit + Vector3.UP, Vector3.DOWN)
					var y := lerpf(lo.y, top, 0.42)
					var edge := _cast(Vector3(c.x, y, c.z) + out * 0.2, -out)
					# An edge that isn't at its corner (an open frame) takes no lashing.
					if edge.is_finite() and Vector2(edge.x - c.x, edge.z - c.z).length() > unit * 2.0:
						edge = Vector3.INF
					found.append([Transform3D(_facing(out), Vector3(c.x, down.y if down.is_finite() else top, c.z)), edge])
		var order := range(found.size())
		var score := order.map(func(i: int) -> float:
			var at: Transform3D = found[i][0]
			return minf(_clear(at.origin, keep), _clear(at.origin - Vector3.UP * (top - lo.y) * 0.5, keep)))
		order.sort_custom(func(a: int, b: int) -> bool: return score[a] > score[b] + 1e-6 or (absf(score[a] - score[b]) <= 1e-6 and a < b))
		for i: int in order:
			corners.append(found[i][0])
			edges.append(found[i][1])

	func _find_spots(keep: PackedVector3Array) -> void:
		var wide := unit * 2.2
		var tall := unit * 2.3
		var mid := (lo + hi) * 0.5
		var half := (hi - lo) * 0.5
		# Each as [where, how far down the faces it's seen best].
		var cands := []
		if radius > 0.0:
			if span.y - span.x >= tall * 1.1:
				for k in 8:
					var out := Vector3(sin(k * TAU / 8.0), 0.0, cos(k * TAU / 8.0))
					cands.append([Transform3D(_facing(out), out * radius + Vector3.UP * (span.x + span.y) * 0.5), 0])
		else:
			# Seen best: a part's top out of its socket, then its sides, its
			# underside last; a frame's sides, then its top, which holds its mounts.
			var faces: Array = [Vector3.UP, Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT, Vector3.BACK] if part \
				else [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT, Vector3.UP]
			for rank in faces.size():
				var out: Vector3 = faces[rank]
				var turn := Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP) if out == Vector3.UP else _facing(out)
				var across := absf(turn.x.dot(half))
				var up := absf(turn.y.dot(half)) if out == Vector3.UP else (top - lo.y) * 0.5
				if across * 2.0 < wide * 1.1 or up * 2.0 < tall * 1.1:
					continue
				var middle := Vector3(mid.x, top, mid.z) if out == Vector3.UP \
					else Vector3(mid.x, (lo.y + top) * 0.5, mid.z) + out * absf(out.dot(half))
				for fb in [0.0, -0.6, 0.6]:
					for fa in [0.0, -0.5, 0.5, -0.9, 0.9]:
						cands.append([Transform3D(turn, middle + turn.x * fa * (across - wide * 0.5)
							+ turn.y * fb * (up - tall * 0.5)), rank])
		# Greedy, clearest first less how far down the faces it is, each settled
		# on what's there before it's taken.
		var clear := PackedFloat32Array()
		for c: Array in cands:
			clear.append(_clear((c[0] as Transform3D).origin, keep) - c[1] * unit * 0.5)
		while spots.size() < 4:
			var best := -1
			for i in cands.size():
				if clear[i] > -INF and (best < 0 or clear[i] > clear[best] + 1e-9):
					best = i
			if best < 0:
				break
			var at: Variant = _settle(cands[best][0], wide, tall)
			clear[best] = -INF
			if at == null:
				continue
			spots.append(at)
			for i in cands.size():
				if clear[i] > -INF:
					clear[i] = minf(clear[i], (cands[i][0] as Transform3D).origin.distance_to((at as Transform3D).origin)
						- cands[i][1] * unit * 0.5)

	## A spot on what's there: where its middle and corners all meet the look
	## near enough flat, on the highest of them; null where they don't.
	func _settle(c: Transform3D, wide: float, tall: float) -> Variant:
		var n := c.basis.z
		var high := -INF
		var low := INF
		for corner in [Vector2.ZERO, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var at := _cast(c * Vector3(corner.x * wide * 0.5, corner.y * tall * 0.5, 0.0) + n * 0.15, -n)
			if not at.is_finite():
				return null
			var rise := (at - c.origin).dot(n)
			high = maxf(high, rise)
			low = minf(low, rise)
			if high - low > unit * 0.3 or absf(high) > unit * 3.0:
				return null
		return Transform3D(c.basis, c.origin + n * high)

	static func _clear(at: Vector3, from: PackedVector3Array) -> float:
		var nearest := 1e3
		for p in from:
			nearest = minf(nearest, at.distance_to(p))
		return nearest

	## Facing out along a level way, up straight up.
	static func _facing(out: Vector3) -> Basis:
		return Basis(Vector3.UP.cross(out), Vector3.UP, out)


## The pieces a lineage adds over a look, each placed from a prototype made
## once by Pieces at its own origin: placing one is copying and turning its
## arrays, done natively, so a thing's marks cost little past the first of
## each piece. A prototype has no foot, so no sand drifts against these.
class Over:
	var _arrays := []
	static var _protos := {}

	## A plain box at a pose, with a mark on its outer face as [mark, width,
	## ink, row].
	func box(size: Vector3, at: Transform3D, look: Coat, mark := []) -> void:
		_place(["box", size, Over.of(look), mark], at, func(b: Pieces) -> void:
			if not mark.is_empty():
				b.stamp(mark[0], Vector3(0.0, 0.0, size.z * 0.5), mark[1], Basis.IDENTITY, mark[2], mark[3])
			b.box(size, Vector3.ZERO, look, 0.0))

	## A drum along its pose's y.
	func drum(radius: float, tall: float, at: Transform3D, look: Coat, sides := 8, narrow := -1.0) -> void:
		_place(["drum", radius, tall, Over.of(look), sides, narrow], at, func(b: Pieces) -> void:
			b.drum(radius, tall, Vector3.ZERO, look, Basis.IDENTITY, sides, narrow))

	## What was added, as a mesh's arrays, empty for nothing.
	func arrays() -> Array:
		return _arrays

	func _place(key: Array, at: Transform3D, build: Callable) -> void:
		if not _protos.has(key):
			var b := Pieces.new()
			build.call(b)
			_protos[key] = b.commit().surface_get_arrays(0)
		var proto: Array = _protos[key]
		var verts: PackedVector3Array = at * (proto[Mesh.ARRAY_VERTEX] as PackedVector3Array)
		var normals: PackedVector3Array = Transform3D(at.basis, Vector3.ZERO) * (proto[Mesh.ARRAY_NORMAL] as PackedVector3Array)
		if _arrays.is_empty():
			_arrays = proto.duplicate(true)
			_arrays[Mesh.ARRAY_VERTEX] = verts
			_arrays[Mesh.ARRAY_NORMAL] = normals
			return
		for c in _arrays.size():
			if _arrays[c] == null:
				continue
			_arrays[c].append_array(verts if c == Mesh.ARRAY_VERTEX else (normals if c == Mesh.ARRAY_NORMAL else proto[c]))

	## A finish as a key.
	static func of(look: Coat) -> Array:
		return [look.color, look.share, look.metal, look.rough, look.dust, look.glow]
