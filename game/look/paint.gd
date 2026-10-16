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

## How worn each era's paint starts, before the weather: deep things were
## sealed away, surface ones were made crude and left out. Older is better.
const ERA := {&"deep": 0.05, &"surface": 0.5}
const ERA_NEW := 0.15
## What a lifetime in the weather adds, from sound to wrecked.
const WEATHERED := 0.8
## Maker's marks, by column of the atlas (marks.py). Batteries and the like
## carry none, so a mark means something where it's found.
enum Mark { CONTRACTOR, SHIELD_MAKER, WIND_MAKER, CONSIGNMENT, SKIMMER_CREW, MEMBER_STATE }
enum Ink { DARK, PALE }
## Each era's row of the atlas: the hands its marks were put on by.
const MARK_ROW := {&"surface": 1, &"deep": 2}
const MARKS := preload("res://game/look/marks.png")

static var _worn: ShaderMaterial
static var _ruin: ShaderMaterial
static var _noise: NoiseTexture2D


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


## The ruin's poured concrete.
static func ruin() -> ShaderMaterial:
	if _ruin == null:
		_ruin = ShaderMaterial.new()
		_ruin.shader = preload("res://game/look/ruin.gdshader")
		_ruin.set_shader_parameter("noise", noise())
		_ruin.set_shader_parameter("marks", MARKS)
	return _ruin


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
	ruin().set_shader_parameter("wind_dir", downwind)


## How worn something looks, 0 to 1: its era's paint, then what the weather took.
static func age_of(layer: StringName, sound: float) -> float:
	return clampf(ERA.get(layer, ERA_NEW) + (1.0 - sound) * WEATHERED, 0.0, 1.0)


## Which era's marks a find of this layer carries.
static func era_of(layer: StringName) -> float:
	return MARK_ROW.get(layer, 0)


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

	## `foot` is where the whole thing meets the sand, in its own frame;
	## without one, nothing drifts against its foot.
	func _init(foot := -INF) -> void:
		_foot = foot
		_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 3:
			_tool.set_custom_format(i, SurfaceTool.CUSTOM_RGBA_FLOAT)
		_tool.set_custom_format(3, SurfaceTool.CUSTOM_R_FLOAT)

	## A box with its edges cut back by `cut`: the bevel catches a line of
	## light, which is most of what reads as made at a distance.
	func box(size: Vector3, at: Vector3, look: Coat, cut := 0.01, turn := Basis.IDENTITY) -> void:
		_add(_chamfer(size, cut), Transform3D(turn, at), look, size * 0.5, 1.0)

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
	## at `at`, `width` across its x and half that up its y.
	func stamp(mark: Mark, at: Vector3, width: float, turn := Basis.IDENTITY, ink := Ink.DARK) -> Pieces:
		_mark = mark
		_ink = ink
		_stamp = Transform3D(turn * Basis.from_scale(Vector3(width, width * 0.5, 1.0)), at).affine_inverse()
		_facing = turn.z.normalized()
		return self

	func commit() -> ArrayMesh:
		var made := _tool.commit() if _any else ArrayMesh.new()
		if made.get_surface_count() > 0:
			made.surface_set_material(0, Paint.worn())
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
			_tool.set_uv2(Vector2(_mark + 1, _ink) if marked else Vector2.ZERO)
			_tool.set_color(paint)
			_tool.set_custom(0, Color(v.x, v.y, v.z, shape))
			_tool.set_custom(1, Color(half.x, half.y, half.z, look.metal))
			_tool.set_custom(2, Color(look.rough, look.dust, look.glow, look.share))
			_tool.set_custom(3, Color(placed.y - _foot if is_finite(_foot) else 1e3, 0.0, 0.0))
			_tool.set_normal((turn * normals[k]).normalized())
			_tool.add_vertex(placed)
		_mark = -1

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
