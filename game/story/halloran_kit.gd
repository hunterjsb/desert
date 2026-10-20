class_name HalloranKit
extends RefCounted
## A fragment of the city: factory foundations, a fortified crossing and
## homes made from what the factory left. Plan +X climbs toward Halloran.

const FURNACE := Vector3(292.0, 36.0, 0.0)
const STORE := Vector3(-282.0, 0.0, 8.0)
const CACHE := Vector3(302.0, 36.0, -6.0)

static func grade(x: float) -> float:
	return 36.0 * smoothstep(-240.0, 240.0, x)


static func pieces() -> Array[StructureKit.Piece]:
	var p := StructureKit.define(&"halloran_route", Vector2(330.0, 44.0), Vector2.ZERO, Vector2.ZERO)
	p.builds = HalloranSite
	p.apron = 100.0
	p.fill = PackedFloat32Array([1.6, 0.65, 0.0])
	p.age = Vector2(0.18, 0.35)
	p.look = _look
	# Houses share the colonial slab; later walls leave the old access open.
	for x in [-310.0, -284.0, -256.0, -220.0]:
		for z in [-23.0, 23.0]:
			var y := grade(x)
			_block(p, Vector3(x, y - 0.5, z), Vector3(18, 1, 13), "concrete")
			_block(p, Vector3(x, y + 1.7, z + 5.7), Vector3(18, 3.4, 0.6), "panel")
			_block(p, Vector3(x - 8.5, y + 1.7, z), Vector3(0.8, 3.4, 12), "panel")
			_block(p, Vector3(x + 8.5, y + 1.1, z), Vector3(0.9, 2.2, 12), "stone")
			_block(p, Vector3(x - 5, y + 1.2, z - 5.7), Vector3(7, 2.4, 0.9), "stone")
			_block(p, Vector3(x + 5, y + 1.2, z - 5.7), Vector3(6, 2.4, 0.9), "stone")
			_block(p, Vector3(x - 4, y + 3.5, z + 1), Vector3(9, 0.3, 10), "rust")
			_block(p, Vector3(x - 4, y + 4.2, z + 5.7), Vector3(9, 1.3, 0.6), "plaster")
	# The Crossing: the industrial way becomes the only gate through a wall.
	for z in [-25.0, 25.0]:
		_block(p, Vector3(0, 21.0, z), Vector3(3, 7, 38), "stone")
	for z in [-8.0, 8.0]:
		_block(p, Vector3(0, 23.0, z), Vector3(10, 11, 6), "stone")
		_block(p, Vector3(0, 29, z), Vector3(11, 1, 7), "concrete")
		for x in [-4.0, 0.0, 4.0]:
			_block(p, Vector3(x, 30, z), Vector3(1.6, 2, 7), "stone")
	_block(p, Vector3(0, 25, 0), Vector3(8, 2, 10), "rust")
	# Empty toll shelter and an older pipe retained as its roof beam.
	_block(p, Vector3(-13, grade(-13) - 0.25, 16), Vector3(10, 0.5, 8), "concrete")
	_block(p, Vector3(-13, grade(-13) + 2, 20), Vector3(10, 4, 0.8), "plaster")
	_block(p, Vector3(-13, grade(-13) + 4.2, 16), Vector3(12, 0.4, 9), "rust")
	# Upper refinery bay: the other furnaces remain cold.
	_block(p, Vector3(295, 35.5, 0), Vector3(62, 1, 54), "concrete")
	_block(p, Vector3(315, 43, 0), Vector3(2, 14, 52), "panel")
	for z in [-24.0, 24.0]:
		_block(p, Vector3(291, 42, z), Vector3(48, 12, 1.5), "panel")
		_block(p, Vector3(300, 47.5, z * 0.6), Vector3(25, 0.6, 20), "rust")
	for z in [-16.0, 16.0]:
		_block(p, Vector3(300, 39, z), Vector3(7, 6, 7), "dark")
		_block(p, Vector3(306, 54, z), Vector3(4, 36, 4), "grey")
		StructureKit.far_box(p, Vector3(304, 36, z - 2), Vector3(308, 72, z + 2), coats().grey)
	# Retaining piers and a broken pipe trace the climb, leaving open sand between.
	for x in range(-200, 241, 40):
		var y := grade(x)
		_block(p, Vector3(x, y - 1.5, 13), Vector3(5, 5, 4), "concrete")
		_block(p, Vector3(x, y + 0.2, 13), Vector3(5.5, 0.7, 4.5), "rust")
	StructureKit.far_box(p, Vector3(-6, 18, -12), Vector3(6, 31, 12), coats().stone)
	# The industrial piers are stone-faced and patched at different heights.
	for z in [-8.0, 8.0]:
		for y in [19.0, 21.0, 23.0, 25.0, 27.0]:
			for x in [-4.0, -1.0, 2.0]:
				_block(p, Vector3(x, y, z - signf(z) * 3.06), Vector3(2.7, 1.7, 0.18), "stone")
		_block(p, Vector3(-5.15, 22.5, z), Vector3(0.3, 7, 0.65), "rust")
	# A later upper room and the broken end of a once-continuous hab corridor.
	_block(p, Vector3(-308, 5.6, 28.7), Vector3(12, 4.4, 0.7), "plaster")
	_block(p, Vector3(-314, 5.6, 24), Vector3(0.7, 4.4, 10), "stone")
	_block(p, Vector3(-308, 7.8, 24), Vector3(13, 0.4, 10), "rust")
	for x in [-252.0, -245.0]:
		_block(p, Vector3(x, grade(x) + 1.6, -16), Vector3(0.6, 3.2, 0.6), "rust")
	# Feet below the raised ground stay real, even when only their tops show.
	for state in 3:
		p._shown[state] = PackedInt32Array(range(p.boxes.size()))
	return [p]


static func _block(p: StructureKit.Piece, at: Vector3, size: Vector3, coat: String) -> void:
	StructureKit.box(p, at - size * 0.5, at + size * 0.5, coat)


static func coats() -> Dictionary:
	var c := ColonialKit.coats().duplicate()
	c["stone"] = Paint.coat(Color(0.43, 0.34, 0.25), 0.8, 0.0, 0.95)
	c["plaster"] = Paint.coat(Paint.LIMEWASH, 0.8, 0.0, 0.95)
	c["rust"] = Paint.coat(Paint.RUST, 0.9, 0.4, 0.8)
	return c


static func _look(b: Paint.Pieces, p: StructureKit.Piece, _state: int) -> void:
	var c := coats()
	# Keep the actual geometry under the sand: partial burial reveals it naturally.
	for i in p.boxes.size():
		var box := p.boxes[i]
		b.box(box.size, box.get_center(), c[p.coats[i]], 0.06)
	var pipe_turn := Basis(Vector3.FORWARD, PI * 0.5)
	for x in range(-210, 231, 40):
		var y := grade(x)
		b.drum(0.7, 18.0, Vector3(x, y + 2, 13), c.grey, pipe_turn, 12)
		for dx in [-8.0, 8.0]:
			b.drum(0.86, 0.3, Vector3(x + dx, y + 2, 13), c.rust, pipe_turn, 12)
	for x in [-310.0, -284.0, -256.0, -220.0]:
		for z in [-23.0, 23.0]:
			var y := grade(x)
			# Conduit, patched ceramic, and roof battens show successive occupants.
			for dx in [-7.0, -3.0, 1.0]:
				b.box(Vector3(0.18, 0.16, 10.5), Vector3(x + dx, y + 3.75, z + 1), c.grey, 0.025)
			b.box(Vector3(2.4, 0.9, 0.08), Vector3(x + 4, y + 1.8, z + 5.35), c.orange, 0.02)
			b.drum(0.5, 0.85, Vector3(x + 6, y + 0.45, z - 3), Paint.coat(Paint.CERAMIC), Basis.IDENTITY, 10)
	# Flanged services and broken uprights make the age of the gate legible.
	for z in [-8.0, 8.0]:
		for y in [20.0, 23.0, 26.0]:
			b.drum(0.2, 0.15, Vector3(-5.35, y, z), c.grey, Basis(Vector3.FORWARD, PI / 2), 8)
		for x in [-4.0, 0.0, 4.0]:
			b.box(Vector3(0.15, 0.1, 7.4), Vector3(x, 29.7, z), c.rust, 0.02)
	for x in [-304.0, -278.0, -249.0]:
		var y := grade(x)
		b.drum(0.65, 4.5, Vector3(x, y + 1.0, -13), c.grey, pipe_turn, 10)
		b.drum(0.85, 0.25, Vector3(x - 2.1, y + 1.0, -13), c.orange, pipe_turn, 10)
	# Muster's devotion sits on industrial material, above the old gate.
	SecondAgeKit.tu(b, Vector3(-5.1, 26, 0), Basis(Vector3.UP, -PI / 2), 1.6, c.orange)
	for z in [-16.0, 16.0]:
		for y in [43.0, 51.0, 59.0, 67.0]:
			b.box(Vector3(4.3, 0.5, 4.3), Vector3(306, y, z), c.rust, 0.03)
		for x in [280.0, 289.0]:
			b.drum(1.3, 8.0, Vector3(x, 40, z), c.grey, Basis.IDENTITY, 16)
			b.drum(1.45, 0.3, Vector3(x, 44, z), c.orange, Basis.IDENTITY, 16)
