extends "res://look/style/look.gd"
## B: chunky worn industrial. Bevelled hard-surface pieces in painted metal,
## chipped at the edges, scoured on the windward side and dusted low; trims,
## panel lines, bolts and a stencilled maker's mark. Company issue: gunmetal
## frames, teal panels, safety yellow, and the shield's own OEM in bone white.
## Every socket has a dark bezel with a tab in its kind's colour.

const WORN := preload("res://game/look/worn.gdshader")
const RUIN_SHADER := preload("res://game/look/ruin.gdshader")

const GUNMETAL := Color(0.26, 0.28, 0.29)
const TEAL := Color(0.18, 0.4, 0.43)
const BONE := Color(0.8, 0.76, 0.66)
const YELLOW := Color(0.86, 0.62, 0.12)
const BLACK := Color(0.08, 0.08, 0.08)
const STEEL := Color(0.62, 0.62, 0.6)
const CELL := Color(0.06, 0.09, 0.17)
const SOIL := Color(0.2, 0.13, 0.08)
const LEAF := Color(0.42, 0.56, 0.26)
const RUST := Color(0.4, 0.16, 0.07)

static var _noise: NoiseTexture2D
var _looks := {}


func title() -> String:
	return "B: chunky worn industrial"


func frame(id: StringName, size: Vector3) -> Node3D:
	var root := Node3D.new()
	var h := size * 0.5
	match id:
		&"crate_frame":
			for x in [-1, 1]:
				for z in [-1, 1]:
					_piece(root, Vector3(0.07, size.y, 0.07), _paint(GUNMETAL), Vector3(x * (h.x - 0.035), 0.0, z * (h.z - 0.035)), 0.012)
					for y in [-1, 1]:
						_piece(root, Vector3(0.11, 0.08, 0.11), _paint(BLACK, 0.7, 0.3), Vector3(x * (h.x - 0.04), y * (h.y - 0.035), z * (h.z - 0.04)), 0.02)
			for y in [-1, 1]:
				for s in [-1, 1]:
					_piece(root, Vector3(size.x - 0.1, 0.06, 0.06), _paint(GUNMETAL), Vector3(0.0, y * (h.y - 0.03), s * (h.z - 0.03)), 0.01)
					_piece(root, Vector3(0.06, 0.06, size.z - 0.1), _paint(GUNMETAL), Vector3(s * (h.x - 0.03), y * (h.y - 0.03), 0.0), 0.01)
			# Panels set in between the rails, a seam across each.
			for side in 4:
				var turn := Basis(Vector3.UP, side * PI * 0.5)
				var depth := h.z if side % 2 == 0 else h.x
				_piece(root, Vector3(size.x - 0.14, size.y - 0.14, 0.03), _paint(TEAL), turn * Vector3(0.0, 0.0, depth - 0.04), 0.008, turn)
				_piece(root, Vector3(size.x - 0.16, 0.012, 0.034), _paint(BLACK, 0.2), turn * Vector3(0.0, -0.06, depth - 0.04), 0.002, turn)
			_piece(root, Vector3(size.x - 0.12, 0.03, size.z - 0.12), _paint(TEAL), Vector3(0.0, h.y - 0.03, 0.0), 0.008)
			_stencil(root, "RMC  CF-80", Vector3(-0.17, 0.06, h.z - 0.02), Basis.IDENTITY, 0.0011)
			_stencil(root, "RMC", Vector3(0.0, 0.03, -(h.z - 0.02)), Basis(Vector3.UP, PI), 0.0024)
			_stencil(root, "MAX 80 KG", Vector3(0.0, 0.08, h.x - 0.02), Basis(Vector3.UP, PI * 0.5), 0.0012)
		&"planter":
			_piece(root, size - Vector3(0.0, 0.02, 0.0), _paint(BONE), Vector3(0.0, -0.01, 0.0), 0.03)
			_piece(root, Vector3(size.x - 0.08, 0.02, size.z - 0.08), _paint(SOIL, 0.0, 0.0, 1.0, 0.0), Vector3(0.0, h.y - 0.005, 0.0), 0.004)
			for s in [-1, 1]:
				_piece(root, Vector3(size.x + 0.02, 0.05, 0.05), _paint(TEAL), Vector3(0.0, h.y - 0.02, s * (h.z - 0.02)), 0.01)
				_piece(root, Vector3(0.05, 0.05, size.z + 0.02), _paint(TEAL), Vector3(s * (h.x - 0.02), h.y - 0.02, 0.0), 0.01)
				_piece(root, Vector3(0.12, 0.06, size.z - 0.1), _paint(GUNMETAL), Vector3(s * (h.x - 0.12), -h.y - 0.01, 0.0), 0.01)
			_piece(root, Vector3(size.x - 0.12, 0.012, 0.004), _paint(BLACK, 0.2), Vector3(0.0, -0.03, h.z + 0.001), 0.001)
			_stencil(root, "HYDRO-4   GROW SIDE UP", Vector3(0.0, 0.02, h.z + 0.003), Basis.IDENTITY, 0.0011)
		&"charger":
			_piece(root, size, _paint(GUNMETAL), Vector3.ZERO, 0.025)
			for i in 4:
				_piece(root, Vector3(0.012, size.y * 0.55, 0.01), _paint(BLACK, 0.1), Vector3(-0.12 + i * 0.035, 0.0, -h.z), 0.002)
			_hazard(root, Vector3(size.x * 0.9, 0.035, 0.012), Vector3(0.0, -h.y + 0.03, h.z), Basis.IDENTITY)
			_stencil(root, "CHG-60", Vector3(0.1, 0.05, h.z + 0.002), Basis.IDENTITY, 0.001)
		&"shield":
			# A different maker: bone white, round, finned.
			_drum(root, 0.2, 0.12, _paint(GUNMETAL), Vector3(0.0, -h.y + 0.06, 0.0))
			_drum(root, 0.17, 0.2, _paint(BONE, 0.4), Vector3(0.0, -0.02, 0.0))
			for i in 8:
				var turn := Basis(Vector3.UP, i * TAU / 8.0 + PI / 8.0)
				_piece(root, Vector3(0.015, 0.16, 0.06), _paint(GUNMETAL), turn * Vector3(0.0, -0.02, 0.18), 0.004, turn)
			_drum(root, 0.13, 0.05, _paint(GUNMETAL), Vector3(0.0, 0.105, 0.0))
			var dome := Shapes.put(root, Shapes.sphere(0.11, 20, 10), _glow(Color(0.35, 0.75, 0.95), 1.6), Vector3(0.0, 0.13, 0.0))
			dome.scale = Vector3(1.0, 0.55, 1.0)
			Shapes.put(root, Shapes.torus(0.168, 0.186, 32, 6), _glow(Color(0.25, 0.67, 0.87), 2.5), Vector3(0.0, size.y * 0.2, 0.0))
			_stencil(root, "FIELD UNIT  T2", Vector3(0.0, -0.06, 0.172), Basis.IDENTITY, 0.0008, BONE.darkened(0.7))
	return root


func mount(kind: StringName) -> Node3D:
	var root := Node3D.new()
	var bezel := _paint(BLACK, 0.5, 0.4)
	match kind:
		&"battery":
			_piece(root, Vector3(0.25, 0.17, 0.012), _paint(Color(0.05, 0.05, 0.05), 0.1), Vector3(0.0, 0.0, 0.004), 0.002)
			for y in [-1, 1]:
				_piece(root, Vector3(0.29, 0.025, 0.03), bezel, Vector3(0.0, y * 0.098, 0.012), 0.006)
			for x in [-1, 1]:
				_piece(root, Vector3(0.025, 0.17, 0.03), bezel, Vector3(x * 0.133, 0.0, 0.012), 0.006)
			_piece(root, Vector3(0.05, 0.016, 0.034), _paint(Catalog.KINDS[kind], 0.3), Vector3(0.0, 0.098, 0.014), 0.003)
		&"ring":
			var boss := _drum(root, 0.05, 0.025, bezel, Vector3(0.0, 0.0, 0.012), Basis(Vector3.RIGHT, PI / 2.0))
			boss.name = "boss"
			for i in 4:
				var a := i * TAU / 4.0 + PI / 4.0
				_drum(root, 0.008, 0.01, _paint(STEEL, 0.7, 0.6), Vector3(cos(a) * 0.035, sin(a) * 0.035, 0.027), Basis(Vector3.RIGHT, PI / 2.0))
		&"top":
			for x in [-1, 1]:
				_piece(root, Vector3(0.03, 0.4, 0.025), bezel, Vector3(x * 0.15, 0.0, 0.012), 0.005)
		&"bottom":
			for x in [-1, 1]:
				for y in [-1, 1]:
					_piece(root, Vector3(0.06, 0.06, 0.02), bezel, Vector3(x * 0.13, y * 0.13, 0.01), 0.005)
		&"port":
			_drum(root, 0.03, 0.02, _paint(Catalog.KINDS[kind], 0.4), Vector3(0.0, 0.0, 0.008), Basis(Vector3.RIGHT, PI / 2.0))
			_drum(root, 0.018, 0.022, _paint(BLACK, 0.1), Vector3(0.0, 0.0, 0.01), Basis(Vector3.RIGHT, PI / 2.0))
		&"plant_small", &"plant_large":
			var r := 0.05 if kind == &"plant_small" else 0.08
			Shapes.put(root, Shapes.torus(r, r + 0.014, 16, 4), _paint(BLACK, 0.4, 0.3), Vector3(0.0, 0.0, 0.004), Basis(Vector3.RIGHT, PI / 2.0))
		_:
			return null
	return root


func part(id: StringName, size: Vector3) -> Node3D:
	var root := Node3D.new()
	var h := size * 0.5
	match id:
		&"battery", &"big_battery":
			# Commodity: no maker's mark, only what it holds.
			_piece(root, size - Vector3(0.01, 0.01, 0.01), _paint(Color(0.2, 0.21, 0.19), 0.45), Vector3(0.0, 0.0, h.z), 0.012)
			_piece(root, Vector3(size.x * 0.75, 0.015, 0.012), _glow(Color(0.5, 0.95, 0.35), 2.0), Vector3(0.0, h.y * 0.45, size.z + 0.0), 0.002)
			_piece(root, Vector3(size.x * 0.5, 0.025, 0.03), _paint(BLACK, 0.4, 0.2), Vector3(0.0, -h.y * 0.35, size.z + 0.012), 0.008)
			_stencil(root, "100 Wh" if id == &"battery" else "300 Wh", Vector3(0.0, 0.0, size.z + 0.002), Basis.IDENTITY, 0.0008, Color(0.75, 0.73, 0.66))
		&"hook":
			_drum(root, 0.035, 0.02, _paint(GUNMETAL, 0.6, 0.3), Vector3(0.0, 0.0, 0.01), Basis(Vector3.RIGHT, PI / 2.0))
			_drum(root, 0.014, 0.1, _paint(STEEL, 0.8, 0.6), Vector3(0.0, 0.0, 0.07), Basis(Vector3.RIGHT, PI / 2.0))
			Shapes.put(root, Shapes.torus(0.026, 0.042, 16, 8), _paint(STEEL, 0.8, 0.6), Vector3(0.0, 0.0, 0.15), Basis(Vector3.UP, PI / 2.0))
		&"hover_tray":
			_piece(root, Vector3(size.x, size.y, 0.06), _paint(GUNMETAL), Vector3(0.0, 0.0, 0.03), 0.015)
			for side in 4:
				var turn := Basis(Vector3.BACK, side * PI * 0.5)
				_hazard(root, Vector3(size.x * 0.82, 0.035, 0.012), turn * Vector3(0.0, h.y - 0.04, 0.062), turn)
			for x in [-1, 1]:
				for y in [-1, 1]:
					_drum(root, 0.08, 0.02, _paint(BLACK, 0.3, 0.3), Vector3(x * 0.18, y * 0.18, 0.065), Basis(Vector3.RIGHT, PI / 2.0))
					Shapes.put(root, Shapes.cylinder(0.06, 0.012, 20), _glow(Color(0.45, 0.8, 1.0), 2.0), Vector3(x * 0.18, y * 0.18, 0.074), Basis(Vector3.RIGHT, PI / 2.0))
		&"solar_panel":
			_piece(root, Vector3(size.x, size.y, 0.03), _paint(STEEL, 0.4, 0.5), Vector3(0.0, 0.0, 0.015), 0.006)
			for i in 4:
				for j in 3:
					_piece(root, Vector3(0.18, 0.18, 0.006), _cells(), Vector3(-0.285 + i * 0.19, -0.19 + j * 0.19, 0.032), 0.001)
			_drum(root, 0.025, 0.06, _paint(GUNMETAL), Vector3(0.0, 0.0, -0.01), Basis(Vector3.RIGHT, PI / 2.0))
		&"seedling", &"carrot":
			_plant(root, 0.14, 4, 0.07)
		&"sapling", &"fungus":
			_plant(root, 0.38, 7, 0.12)
		_:
			return null
	return root


func stake() -> Node3D:
	var root := Node3D.new()
	var iron := _paint(RUST.lightened(0.1), 0.8, 0.3)
	_piece(root, Vector3(0.05, Stake.LENGTH - 0.05, 0.05), iron, Vector3(0.0, -0.03, 0.0), 0.01)
	var tip := Shapes.put(root, Shapes.cylinder(0.035, 0.12, 4, 0.0), iron, Vector3(0.0, -Stake.LENGTH * 0.5 + 0.0, 0.0), Basis(Vector3.RIGHT, PI))
	tip.set_instance_shader_parameter("half_size", Vector3(0.035, 0.06, 0.035))
	_piece(root, Vector3(0.09, 0.05, 0.09), iron, Vector3(0.0, Stake.RING.y - 0.06, 0.0), 0.012)
	Shapes.put(root, Shapes.torus(0.03, 0.05, 16, 8), _paint(STEEL.darkened(0.3), 0.9, 0.6), Stake.RING, Basis(Vector3.RIGHT, PI / 2.0) * Basis(Vector3.FORWARD, PI / 2.0))
	return root


## The colonial ruin: poured and overbuilt, its formwork seams, a faded
## band, and a contractor's sector stencil by the corner.
func ruin(view: MeshInstance3D, at: Transform3D) -> void:
	var look := ShaderMaterial.new()
	look.shader = RUIN_SHADER
	look.set_shader_parameter("noise", _noise_texture())
	look.set_shader_parameter("wind_dir", wind)
	view.material_override = look
	var corner := at * Vector3(Ruin.HALF.x, 0.0, Ruin.HALF.y)
	for face: Array in [[Vector3(Ruin.HALF.x + 0.01, 0.0, Ruin.HALF.y - 2.2), Basis(Vector3.UP, PI * 0.5)],
			[Vector3(Ruin.HALF.x - 2.4, 0.0, Ruin.HALF.y + 0.01), Basis.IDENTITY]]:
		var label := _stencil(view.get_parent(), "B-07", Vector3.ZERO, Basis.IDENTITY, 0.012, Color(0.25, 0.22, 0.2))
		label.global_transform = Transform3D(at.basis * face[1], at * (face[0] + Vector3(0.0, 1.7, 0.0)))
	var guard := Node3D.new()
	view.add_sibling(guard)
	guard.global_transform = Transform3D(at.basis, corner)
	for y in [0.4, 1.4, 2.4]:
		_piece(guard, Vector3(0.5, 0.18, 0.06), _paint(YELLOW.darkened(0.2), 0.95), Vector3(-0.25, y, 0.03), 0.01)
		_piece(guard, Vector3(0.06, 0.18, 0.5), _paint(YELLOW.darkened(0.2), 0.95), Vector3(0.03, y, -0.25), 0.01)


func finds() -> Array[Node3D]:
	# Surface: a lamp made from a can, rope-bound, a daub for a mark.
	var crude := Node3D.new()
	var can := _drum(crude, 0.075, 0.2, _paint(Color(0.45, 0.32, 0.2), 1.0, 0.0), Vector3(0.0, 0.1, 0.0))
	can.mesh = Shapes.flat(Shapes.cylinder(0.075, 0.2, 7, 0.068))
	for y in [0.05, 0.15]:
		Shapes.put(crude, Shapes.torus(0.074, 0.088, 10, 4), _paint(Color(0.36, 0.27, 0.18), 0.2, 0.0, 1.0), Vector3(0.0, y, 0.0))
	_piece(crude, Vector3(0.16, 0.012, 0.04), _paint(RUST, 1.0), Vector3(0.0, 0.215, 0.0), 0.004, Basis(Vector3.BACK, 0.25))
	_piece(crude, Vector3(0.012, 0.09, 0.06), _paint(Color(0.55, 0.2, 0.12), 0.1, 0.0, 1.0, 0.0), Vector3(0.0, 0.11, 0.077), 0.002)
	# Colonial: a sealed module, overbuilt, its light still on.
	var deep := Node3D.new()
	var white := _paint(Color(0.88, 0.87, 0.82), 0.06, 0.0, 0.35)
	_piece(deep, Vector3(0.34, 0.22, 0.2), white, Vector3(0.0, 0.11, 0.0), 0.045)
	_piece(deep, Vector3(0.2, 0.12, 0.012), _paint(Color(0.08, 0.09, 0.1), 0.0, 0.3, 0.25), Vector3(-0.04, 0.12, 0.1), 0.004)
	_piece(deep, Vector3(0.025, 0.025, 0.014), _glow(Color(0.3, 0.75, 1.0), 4.0), Vector3(0.11, 0.16, 0.1), 0.004)
	_piece(deep, Vector3(0.3, 0.02, 0.012), _paint(Color(0.8, 0.6, 0.25), 0.05, 1.0, 0.25), Vector3(0.0, 0.035, 0.1), 0.003)
	for x in [-1, 1]:
		for y in [-1, 1]:
			_drum(deep, 0.01, 0.01, _paint(Color(0.5, 0.5, 0.52), 0.05, 0.9, 0.3), Vector3(x * 0.13, 0.11 + y * 0.07, 0.1), Basis(Vector3.RIGHT, PI / 2.0))
	_stencil(deep, "SC  HM-3", Vector3(-0.04, 0.06, 0.102), Basis.IDENTITY, 0.0009, Color(0.3, 0.32, 0.36))
	return [crude, deep]


## A seedling or sapling: a stem and leaves angled up and out.
func _plant(root: Node3D, height: float, leaves: int, reach: float) -> void:
	var leaf := _paint(LEAF, 0.0, 0.0, 0.8, 0.3)
	var stem := _drum(root, 0.008 + height * 0.02, height, _paint(Color(0.35, 0.3, 0.18), 0.0, 0.0, 0.8, 0.2), Vector3(0.0, 0.0, height * 0.5), Basis(Vector3.RIGHT, PI / 2.0))
	stem.name = "stem"
	for i in leaves:
		var a := i * 2.4
		var up := height * (0.45 + 0.5 * float(i) / leaves)
		var blade := Shapes.put(root, Shapes.sphere(reach * 0.5, 8, 4), leaf, Vector3(cos(a) * reach * 0.5, sin(a) * reach * 0.5, up))
		blade.scale = Vector3(1.0, 0.45, 0.15) * 1.6
		blade.basis = Basis(Vector3.BACK, a) * Basis(Vector3.UP, -0.6) * Basis.from_scale(blade.scale)
		blade.set_instance_shader_parameter("half_size", Vector3.ONE * reach)


## Black and yellow: the bands a safety officer would sign off.
func _hazard(root: Node3D, size: Vector3, at: Vector3, turn: Basis) -> void:
	_piece(root, size, _paint(YELLOW, 0.75), at, 0.003, turn)
	var n := int(size.x / (size.y * 1.6))
	for i in n:
		var x := -size.x * 0.5 + (i + 0.5) * size.x / n
		_piece(root, Vector3(size.y * 0.55, size.y * 1.05, size.z + 0.002), _paint(BLACK, 0.6), at + turn * Vector3(x, 0.0, 0.0), 0.001, turn * Basis(Vector3.BACK, 0.7))


func _piece(root: Node3D, size: Vector3, look: Material, at: Vector3, cut: float, turn := Basis.IDENTITY) -> MeshInstance3D:
	var made := Shapes.put(root, Shapes.chamfer_box(size, cut), look, at, turn)
	made.set_instance_shader_parameter("half_size", size * 0.5)
	return made


## A cylinder standing along its own y, turned as told.
func _drum(root: Node3D, radius: float, height: float, look: Material, at: Vector3, turn := Basis.IDENTITY) -> MeshInstance3D:
	var made := Shapes.put(root, Shapes.cylinder(radius, height, 20), look, at, turn)
	made.set_instance_shader_parameter("half_size", Vector3(radius, height * 0.5, radius))
	made.set_instance_shader_parameter("round_xz", 1.0)
	return made


func _stencil(root: Node3D, text: String, at: Vector3, turn: Basis, pixel: float, ink := Color(0.86, 0.83, 0.74)) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.pixel_size = pixel
	label.font_size = 48
	label.outline_size = 0
	label.modulate = ink
	label.shaded = true
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	label.transform = Transform3D(turn, at)
	root.add_child(label)
	return label


func _paint(color: Color, wear := 0.45, metal := 0.0, rough := 0.6, dust := 1.0) -> ShaderMaterial:
	var key := [color, wear, metal, rough, dust]
	if not _looks.has(key):
		var look := ShaderMaterial.new()
		look.shader = WORN
		look.set_shader_parameter("paint", color)
		look.set_shader_parameter("wear", wear)
		look.set_shader_parameter("paint_metal", metal)
		look.set_shader_parameter("paint_rough", rough)
		look.set_shader_parameter("dust_amount", dust)
		look.set_shader_parameter("wind_dir", wind)
		look.set_shader_parameter("noise", _noise_texture())
		_looks[key] = look
	return _looks[key]


func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var look := StandardMaterial3D.new()
	look.albedo_color = color
	look.emission_enabled = true
	look.emission = color
	look.emission_energy_multiplier = energy
	return look


func _cells() -> StandardMaterial3D:
	var look := StandardMaterial3D.new()
	look.albedo_color = CELL
	look.metallic = 0.6
	look.roughness = 0.18
	return look


static func _noise_texture() -> NoiseTexture2D:
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
