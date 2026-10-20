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
	# Later homes keep the old bay's columns, with real openings toward the street.
	for x in [-310.0, -284.0, -256.0, -220.0]:
		for z in [-23.0, 23.0]:
			var y := grade(x)
			var front: float = z - signf(z) * 5.7
			var back: float = z + signf(z) * 5.7
			_block(p, Vector3(x, y - 0.5, z), Vector3(18, 1, 13), "concrete")
			for dx in [-8.45, -3.0, 3.0, 8.45]:
				_block(p, Vector3(x + dx, y + 1.75, back), Vector3(0.65, 3.5, 0.65), "concrete")
			_block(p, Vector3(x, y + 0.65, back), Vector3(17.3, 1.3, 0.5), "panel")
			_block(p, Vector3(x, y + 3.15, back), Vector3(18, 0.7, 0.65), "concrete")
			# An open front door is framed by repaired masonry and its surviving beam.
			for dx in [-4.8, 4.8]:
				_block(p, Vector3(x + dx, y + 1.2, front), Vector3(7.0, 2.4, 0.65), "stone")
			_block(p, Vector3(x, y + 2.65, front), Vector3(18, 0.5, 0.8), "concrete")
			for dx in [-1.3, 1.3]:
				_block(p, Vector3(x + dx, y + 1.2, front), Vector3(0.2, 2.4, 0.85), "rust")
			# Side windows break the industrial shell; lintels still carry the half roof.
			for dx in [-8.5, 8.5]:
				_block(p, Vector3(x + dx, y + 0.65, z), Vector3(0.7, 1.3, 11.5), "stone")
				_block(p, Vector3(x + dx, y + 3.1, z), Vector3(0.75, 0.8, 12), "concrete")
				for dz in [-5.3, 0.0, 5.3]:
					_block(p, Vector3(x + dx, y + 2, z + dz), Vector3(0.7, 1.4, 1.2), "plaster")
			_block(p, Vector3(x - 4, y + 3.6, z), Vector3(9, 0.3, 12.5), "rust")
			_block(p, Vector3(x - 4, y + 4.2, back), Vector3(9, 1.0, 0.6), "plaster")
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
	# Columns and broken clerestories show the factory frame behind later cladding.
	for z in [-24.0, 24.0]:
		for x in [267.0, 279.0, 291.0, 303.0, 315.0]:
			_block(p, Vector3(x, 42, z), Vector3(1.2, 12, 1.5), "concrete")
		_block(p, Vector3(291, 38, z), Vector3(48, 4, 0.65), "grey")
		_block(p, Vector3(291, 47.3, z), Vector3(49, 0.9, 1.6), "concrete")
		for x in [273.0, 285.0, 297.0, 309.0]:
			_block(p, Vector3(x, 43.8, z), Vector3(10.8, 3.6, 0.6), "panel")
		_block(p, Vector3(300, 47.5, z * 0.6), Vector3(25, 0.6, 20), "rust")
	for z in [-22.0, -11.0, 0.0, 11.0, 22.0]:
		_block(p, Vector3(315, 43, z), Vector3(1.5, 14, 1.2), "concrete")
	for z in [-16.5, -5.5, 5.5, 16.5]:
		_block(p, Vector3(315, 40, z), Vector3(0.65, 8, 9.8), "panel")
		_block(p, Vector3(315, 49.5, z), Vector3(0.8, 1, 11), "rust")
	for z in [-16.0, 16.0]:
		_block(p, Vector3(300, 39, z), Vector3(7, 6, 7), "dark")
		_block(p, Vector3(306, 54, z), Vector3(4, 36, 4), "grey")
		StructureKit.far_box(p, Vector3(304, 36, z - 2), Vector3(308, 72, z + 2), coats().grey)
	# The service main follows the grade on saddles, with no disconnected spans.
	for point in pipe_points():
		var y := grade(point.x)
		_block(p, Vector3(point.x, y + 0.35, point.z), Vector3(2.0, 2.3, 2.3), "concrete")
		_block(p, Vector3(point.x, y + 1.55, point.z), Vector3(2.3, 0.25, 2.6), "rust")
	var path := pipe_points()
	for i in path.size() - 1:
		var delta := path[i + 1] - path[i]
		var turn := Basis(Quaternion(Vector3.UP, delta.normalized()))
		StructureKit.fitted_box(p, Vector3(1.0, delta.length(), 1.0), (path[i] + path[i + 1]) * 0.5, turn)
	StructureKit.fitted_box(p, Vector3(3.5, 3.8, 3.5), Vector3(-282, 1.9, 14.5))
	# The upper main turns down into the refinery's cold service manifold.
	StructureKit.fitted_box(p, Vector3(1.0, 1.0, 10.0), Vector3(292, 38, 8), Basis.IDENTITY)
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
	var path := pipe_points()
	for i in path.size() - 1:
		_pipe(b, path[i], path[i + 1], c)
		var turn := Basis(Quaternion(Vector3.UP, (path[i + 1] - path[i]).normalized()))
		for point: Vector3 in [path[i], path[i + 1]]:
			b.drum(0.88, 0.22, point, c.rust, turn, 12)
			for k in 6:
				var angle := k * TAU / 6
				b.drum(0.055, 0.29, point + turn * Vector3(cos(angle) * 0.77, 0, sin(angle) * 0.77), c.dark, turn, 6)
	_pipe(b, Vector3(292, 38, 13), Vector3(292, 38, 3.0), c)
	_pipe(b, Vector3(292, 38, 3.0), FURNACE + Vector3(0, 2, 0), c)
	b.drum(0.85, 0.2, Vector3(292, 38, 3.0), c.rust, Basis(Vector3.RIGHT, PI / 2), 12)
	# The lower end is seated in an old pump cabinet rather than abandoned in air.
	b.box(Vector3(3.5, 3.8, 3.5), Vector3(-282, 1.9, 14.5), c.dark, 0.1)
	b.box(Vector3(3.0, 2.8, 0.1), Vector3(-282, 1.8, 12.7), c.orange, 0.06)
	for x in [-310.0, -284.0, -256.0, -220.0]:
		for z in [-23.0, 23.0]:
			var y := grade(x)
			var front: float = z - signf(z) * 5.7
			var back: float = z + signf(z) * 5.7
			# Roof seams and cross-battens reveal a shelter assembled from factory sheet.
			for dx in [-7.0, -4.0, -1.0]:
				b.box(Vector3(0.12, 0.14, 12.7), Vector3(x + dx, y + 3.8, z), c.grey, 0.025)
			for dz in [-4.5, 4.5]:
				b.box(Vector3(9.3, 0.22, 0.18), Vector3(x - 4, y + 3.35, z + dz), c.rust, 0.03)
			for dx in [-5.8, 5.8]:
				# Shutters hang beside actual open window bays.
				b.box(Vector3(1.1, 1.3, 0.12), Vector3(x + dx, y + 2.05, back - signf(z) * 0.38), c.orange, 0.025)
				b.box(Vector3(4.8, 0.16, 0.95), Vector3(x + dx, y + 1.27, back), c.concrete, 0.025)
			b.box(Vector3(1.5, 0.5, 0.08), Vector3(x + 3, y + 2, front - signf(z) * 0.4), c.orange, 0.02)
			for dx in [-0.9, 0.9]:
				b.box(Vector3(0.12, 0.12, 1.25), Vector3(x + dx, y + 2.8, front - signf(z) * 0.55), c.rust, 0.02)
			b.box(Vector3(2.4, 0.1, 1.4), Vector3(x, y + 2.9, front - signf(z) * 0.55), c.rust, 0.02)
			b.drum(0.5, 0.85, Vector3(x + 6, y + 0.45, z - 3), Paint.coat(Paint.CERAMIC), Basis.IDENTITY, 10)
			# Uneven facing stones and old anchor plates read as repair, not a fresh wall.
			for side in [-1.0, 1.0]:
				for row in 5:
					for col in 6:
						var dx: float = side * (2.0 + col * 1.05 + (0.25 if row % 2 == 1 else 0.0))
						var paint: Paint.Coat = c.stone if (row + col) % 4 != 0 else c.plaster
						b.box(Vector3(0.98, 0.42, 0.14), Vector3(x + dx, y + 0.25 + row * 0.46, front - signf(z) * 0.37), paint, 0.035)
			for dx in [-7.8, 7.8]:
				b.box(Vector3(0.4, 0.3, 0.08), Vector3(x + dx, y + 2.65, front - signf(z) * 0.43), c.grey, 0.03)
			# A narrow service conduit meets the back wall and the old roof beam.
			b.drum(0.06, 3.3, Vector3(x - 8.0, y + 1.7, back - signf(z) * 0.4), c.rust, Basis.IDENTITY, 8)
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
	for z in [-24.0, 24.0]:
		for x in [270.0, 276.0, 282.0, 288.0, 294.0, 300.0, 306.0, 312.0]:
			b.box(Vector3(0.08, 3.6, 0.12), Vector3(x, 43.8, z + signf(z) * 0.36), c.rust, 0.015)
		for x in [273.0, 285.0, 297.0, 309.0]:
			b.box(Vector3(10.8, 0.3, 0.12), Vector3(x, 42.2, z + signf(z) * 0.37), c.orange, 0.02)
			for dx in [-3.0, 3.0]:
				b.box(Vector3(0.08, 2.0, 0.1), Vector3(x + dx, 41, z), c.grey, 0.015)
	for z in [-16.0, 16.0]:
		for y in [43.0, 51.0, 59.0, 67.0]:
			b.box(Vector3(4.3, 0.5, 4.3), Vector3(306, y, z), c.rust, 0.03)
		for x in [280.0, 289.0]:
			b.drum(1.3, 8.0, Vector3(x, 40, z), c.grey, Basis.IDENTITY, 16)
			b.drum(1.45, 0.3, Vector3(x, 44, z), c.orange, Basis.IDENTITY, 16)


static func pipe_points() -> PackedVector3Array:
	var path := PackedVector3Array()
	for x in [-282.0, -240.0, -200.0, -160.0, -120.0, -80.0, -40.0, 0.0, 40.0, 80.0, 120.0, 160.0, 200.0, 240.0, 270.0, 292.0]:
		path.append(Vector3(x, grade(x) + 2.0, 13.0))
	return path


static func _pipe(b: Paint.Pieces, start: Vector3, end: Vector3, c: Dictionary) -> void:
	var along := end - start
	var turn := Basis(Quaternion(Vector3.UP, along.normalized()))
	b.drum(0.7, along.length() + 0.12, (start + end) * 0.5, c.grey, turn, 12)
