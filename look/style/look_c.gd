extends "res://look/style/look.gd"
## C: low-poly, flat-shaded, a tight palette. Few big facets that read at a
## distance against the sand, six colours and a glow, nothing textured. Each
## socket is a charcoal plate with a dot in its kind's colour.

const PALETTE := {
	&"teal": Color(0.13, 0.4, 0.43), &"cream": Color(0.9, 0.85, 0.74), &"coral": Color(0.86, 0.36, 0.24),
	&"charcoal": Color(0.17, 0.17, 0.19), &"mustard": Color(0.93, 0.66, 0.15), &"sage": Color(0.45, 0.6, 0.3),
	&"navy": Color(0.09, 0.15, 0.24), &"glow": Color(0.35, 0.8, 1.0),
}
## Socket kinds to palette colours.
const KIND_COLOR := {&"battery": &"mustard", &"ring": &"cream", &"bottom": &"glow", &"top": &"sage",
	&"port": &"coral", &"plant_small": &"sage", &"plant_large": &"sage"}

var _looks := {}


func title() -> String:
	return "C: low-poly, flat, tight palette"


func frame(id: StringName, size: Vector3) -> Node3D:
	var root := Node3D.new()
	var h := size * 0.5
	match id:
		&"crate_frame":
			_block(root, size, &"teal", Vector3.ZERO, 0.06)
			_block(root, Vector3(size.x + 0.02, 0.1, size.z + 0.02), &"cream", Vector3(0.0, 0.06, 0.0), 0.03)
			for x in [-1, 1]:
				for z in [-1, 1]:
					_block(root, Vector3(0.1, size.y + 0.02, 0.1), &"charcoal", Vector3(x * (h.x - 0.03), 0.0, z * (h.z - 0.03)), 0.03)
		&"planter":
			_block(root, size, &"cream", Vector3.ZERO, 0.06)
			_block(root, Vector3(size.x - 0.1, 0.03, size.z - 0.1), &"charcoal", Vector3(0.0, h.y - 0.005, 0.0), 0.01)
			_block(root, Vector3(size.x + 0.02, 0.06, size.z + 0.02), &"teal", Vector3(0.0, -h.y + 0.04, 0.0), 0.02)
		&"charger":
			_block(root, size, &"charcoal", Vector3.ZERO, 0.05)
			_block(root, Vector3(size.x + 0.01, 0.05, size.z + 0.01), &"mustard", Vector3(0.0, -h.y + 0.05, 0.0), 0.015)
		&"shield":
			_solid(root, Shapes.cylinder(0.2, 0.14, 8), &"charcoal", Vector3(0.0, -h.y + 0.07, 0.0))
			_solid(root, Shapes.cylinder(0.17, 0.2, 8, 0.15), &"cream", Vector3(0.0, -0.01, 0.0))
			_solid(root, Shapes.sphere(0.13, 8, 4), &"glow", Vector3(0.0, 0.1, 0.0)).scale = Vector3(1.0, 0.7, 1.0)
			_solid(root, Shapes.torus(0.17, 0.2, 8, 3), &"glow", Vector3(0.0, size.y * 0.2, 0.0))
	return root


func mount(kind: StringName) -> Node3D:
	if not KIND_COLOR.has(kind):
		return null
	var root := Node3D.new()
	match kind:
		&"battery":
			_block(root, Vector3(0.27, 0.19, 0.02), &"charcoal", Vector3(0.0, 0.0, 0.006), 0.008)
		&"bottom", &"top":
			return null
		&"plant_small", &"plant_large":
			_solid(root, Shapes.cylinder(0.06 if kind == &"plant_small" else 0.09, 0.012, 6), &"teal", Vector3(0.0, 0.0, 0.004), Basis(Vector3.RIGHT, PI / 2.0))
			return root
		_:
			_solid(root, Shapes.cylinder(0.045, 0.02, 6), &"charcoal", Vector3(0.0, 0.0, 0.008), Basis(Vector3.RIGHT, PI / 2.0))
	_solid(root, Shapes.sphere(0.014, 6, 3), KIND_COLOR[kind], Vector3(0.0, 0.07 if kind == &"battery" else 0.0, 0.02))
	return root


func part(id: StringName, size: Vector3) -> Node3D:
	var root := Node3D.new()
	var h := size * 0.5
	match id:
		&"battery", &"big_battery":
			_block(root, size, &"mustard", Vector3(0.0, 0.0, h.z), 0.025)
			_block(root, Vector3(size.x * 0.6, size.y + 0.01, 0.04), &"charcoal", Vector3(0.0, 0.0, size.z - 0.02), 0.012)
		&"hook":
			_solid(root, Shapes.cylinder(0.03, 0.03, 6), &"charcoal", Vector3(0.0, 0.0, 0.015), Basis(Vector3.RIGHT, PI / 2.0))
			_solid(root, Shapes.cylinder(0.015, 0.1, 4), &"cream", Vector3(0.0, 0.0, 0.07), Basis(Vector3.RIGHT, PI / 2.0))
			_solid(root, Shapes.torus(0.025, 0.05, 6, 4), &"cream", Vector3(0.0, 0.0, 0.15), Basis(Vector3.UP, PI / 2.0))
		&"hover_tray":
			_block(root, Vector3(size.x, size.y, 0.06), &"charcoal", Vector3(0.0, 0.0, 0.03), 0.03)
			_block(root, Vector3(size.x + 0.02, size.y + 0.02, 0.025), &"coral", Vector3(0.0, 0.0, 0.05), 0.012)
			for x in [-1, 1]:
				for y in [-1, 1]:
					_solid(root, Shapes.cylinder(0.075, 0.02, 6), &"glow", Vector3(x * 0.18, y * 0.18, 0.068), Basis(Vector3.RIGHT, PI / 2.0))
		&"solar_panel":
			_block(root, Vector3(size.x, size.y, 0.035), &"cream", Vector3(0.0, 0.0, 0.018), 0.012)
			_block(root, Vector3(size.x - 0.06, size.y - 0.06, 0.012), &"navy", Vector3(0.0, 0.0, 0.035), 0.004)
			for i in 3:
				_block(root, Vector3(0.012, size.y - 0.07, 0.014), &"cream", Vector3(-0.19 + i * 0.19, 0.0, 0.038), 0.002)
		&"seedling", &"carrot":
			_solid(root, Shapes.cylinder(0.05, 0.14, 4, 0.0), &"sage", Vector3(0.0, 0.0, 0.07), Basis(Vector3.RIGHT, PI / 2.0))
		&"sapling", &"fungus":
			_solid(root, Shapes.cylinder(0.02, 0.18, 4), &"charcoal", Vector3(0.0, 0.0, 0.09), Basis(Vector3.RIGHT, PI / 2.0))
			_solid(root, Shapes.sphere(0.11, 6, 3), &"sage", Vector3(0.0, 0.0, 0.26))
			_solid(root, Shapes.sphere(0.07, 5, 3), &"sage", Vector3(0.06, 0.03, 0.36))
		_:
			return null
	return root


func stake() -> Node3D:
	var root := Node3D.new()
	_solid(root, Shapes.cylinder(0.035, Stake.LENGTH - 0.1, 4, 0.03), &"coral", Vector3(0.0, 0.0, 0.0))
	_solid(root, Shapes.cylinder(0.0, 0.1, 4, 0.035), &"coral", Vector3(0.0, -Stake.LENGTH * 0.5 + 0.05, 0.0))
	_solid(root, Shapes.torus(0.03, 0.055, 6, 4), &"charcoal", Stake.RING, Basis(Vector3.RIGHT, PI / 2.0))
	return root


## The ruin in one flat colour a step paler than the sand, with a teal band
## round the corner by the camp: it reads as built, not as dune.
func ruin(view: MeshInstance3D, at: Transform3D) -> void:
	var look := _look(&"ruin")
	view.material_override = look
	var band := Node3D.new()
	view.add_sibling(band)
	band.global_transform = at
	var f := Vector2(Ruin.HALF)
	_block(band, Vector3(0.08, 0.3, 6.0), &"teal", Vector3(f.x + 0.02, 2.2, f.y - 3.0), 0.02)
	_block(band, Vector3(6.0, 0.3, 0.08), &"teal", Vector3(f.x - 3.0, 2.2, f.y + 0.02), 0.02)


func finds() -> Array[Node3D]:
	var crude := Node3D.new()
	_solid(crude, Shapes.cylinder(0.08, 0.2, 5, 0.07), &"coral", Vector3(0.0, 0.1, 0.0), Basis(Vector3.BACK, 0.08))
	_solid(crude, Shapes.torus(0.075, 0.095, 5, 3), &"charcoal", Vector3(0.0, 0.07, 0.0))
	_block(crude, Vector3(0.18, 0.02, 0.05), &"charcoal", Vector3(0.0, 0.21, 0.0), 0.005, Basis(Vector3.BACK, 0.3))
	var deep := Node3D.new()
	_block(deep, Vector3(0.34, 0.22, 0.2), &"cream", Vector3(0.0, 0.11, 0.0), 0.06)
	_block(deep, Vector3(0.2, 0.1, 0.02), &"navy", Vector3(-0.04, 0.12, 0.095), 0.005)
	_block(deep, Vector3(0.03, 0.03, 0.02), &"glow", Vector3(0.11, 0.16, 0.098), 0.005)
	return [crude, deep]


func _block(root: Node3D, size: Vector3, color: StringName, at: Vector3, cut: float, turn := Basis.IDENTITY) -> MeshInstance3D:
	return Shapes.put(root, Shapes.chamfer_box(size, cut), _look(color), at, turn)


func _solid(root: Node3D, mesh: PrimitiveMesh, color: StringName, at: Vector3, turn := Basis.IDENTITY) -> MeshInstance3D:
	return Shapes.put(root, Shapes.flat(mesh), _look(color), at, turn)


## One material per colour, shared by everything painted it.
func _look(color: StringName) -> Material:
	if not _looks.has(color):
		_looks[color] = _make(color)
	return _looks[color]


func _make(color: StringName) -> Material:
	if color == &"ruin":
		var painted := ShaderMaterial.new()
		painted.shader = preload("res://look/style/gradient.gdshader")
		return painted
	var look := StandardMaterial3D.new()
	look.roughness = 1.0
	look.albedo_color = PALETTE[color]
	if color == &"glow":
		look.emission_enabled = true
		look.emission = PALETTE[color]
		look.emission_energy_multiplier = 1.8
	return look
