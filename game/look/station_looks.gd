class_name StationLooks
extends RefCounted
## Field instruments built as serviceable socket cartridges; all geometry stays static.
const IDS: Array[StringName] = [&"anemometer", &"barometer", &"hygrometer", &"particle_sensor", &"ground_radar", &"radar", &"harvester", &"screen", &"solar_panel"]
const ALONG := Basis(Vector3.RIGHT, PI / 2.0)
static var _eras := {}
static var _cup_shell := []

static func part(b: Paint.Pieces, id: StringName, size: Vector3, era := Eras.NEW, _count := -1) -> bool:
	match id:
		&"anemometer": _wind(b, size, era)
		&"barometer": _pressure(b, size, era)
		&"hygrometer": _humidity(b, size, era)
		&"particle_sensor": _dust(b, size, era)
		&"ground_radar": _survey(b, size, era)
		&"radar": _radar(b, size, era)
		&"harvester": _harvester(b, size, era)
		&"screen": _screen(b, size, era)
		&"solar_panel": _solar(b, size, era)
		_: return false
	return true

static func lineage(id: StringName, line: Array) -> ArrayMesh:
	if not IDS.has(id): return null
	var era := Eras.era_of(line)
	var key := [id, era]
	if not _eras.has(key):
		var b := Paint.Pieces.new()
		part(b, id, Catalog.PARTS[id].size, era)
		_eras[key] = b.commit()
	return _eras[key]

static func glass() -> Paint.Coat:
	# Backed dark glazing catches the sky without lighting an unpowered instrument.
	return Paint.coat(Paint.CELL, 0.0, 0.12, 0.07, 0.0)
static func _metal() -> Paint.Coat: return Paint.coat(Paint.GUNMETAL, 0.5, 0.65, 0.5)
static func _dark() -> Paint.Coat: return Paint.coat(Paint.BLACK, 0.2, 0.1, 0.8)
static func _skin(era: StringName) -> Paint.Coat:
	return Paint.coat({Eras.COLONIAL: Paint.BONE, Eras.SECOND: Paint.CERAMIC, Eras.SKIMMER: Paint.RUST}.get(era, Paint.TEAL), 0.55, 0.1, 0.55)
static func _trim(era: StringName) -> Paint.Coat:
	return Paint.coat(Paint.BRASS if era == Eras.FIRST else Paint.STEEL, 0.4, 0.7, 0.4)
static func _bolt(b: Paint.Pieces, at: Vector3, r := 0.004) -> void:
	b.drum(r, 0.002, at, Paint.coat(Paint.STEEL, 0.4, 0.7), ALONG, 6)
static func _plate(b: Paint.Pieces, size: Vector3, depth: float, era: StringName) -> void:
	b.box(Vector3(size.x - 0.004, size.y - 0.004, depth), Vector3(0, 0, depth * 0.5), _metal(), 0.006)
	for x in [-1, 1]:
		for y in [-1, 1]: _bolt(b, Vector3(x * (size.x * 0.5 - 0.012), y * (size.y * 0.5 - 0.012), depth - 0.001))
	if era == Eras.FIRST:
		b.box(Vector3(size.x - 0.01, 0.009, depth), Vector3(0, size.y * 0.5 - 0.006, depth * 0.5), _trim(era), 0.002)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.014, size.y - 0.012, 0.008), Vector3(-size.x * 0.5 + 0.009, 0, depth - 0.003), _trim(era), 0.001)
static func _cord(b: Paint.Pieces, at: Vector3, radius: float, turn := ALONG) -> void:
	for step in [-0.004, 0.004]:
		b.drum(radius, 0.004, at + turn.y * step, Paint.coat(Paint.CORD, 0, 0, 0.95), turn, 10)

static func _wind(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	_plate(b, size, 0.028, era)
	b.box(Vector3(0.08, 0.055, 0.018), Vector3(0, -0.005, 0.033), _skin(era), 0.012)
	b.drum(0.014, 0.063, Vector3(0, 0, 0.069), _trim(era), ALONG, 12)
	b.drum(0.020, 0.018, Vector3(0, 0, 0.104), _dark(), ALONG, 16)
	b.drum(0.012, 0.014, Vector3(0, 0, 0.12), _trim(era), ALONG, 12)
	for i in 3:
		var angle := i * TAU / 3.0
		var radial := Vector3(sin(angle), cos(angle), 0)
		var tangent := Vector3(cos(angle), -sin(angle), 0)
		var cup := radial * 0.048 + Vector3(0, 0, 0.123)
		b.box(Vector3(0.006, 0.048, 0.006), radial * 0.024 + Vector3(0, 0, 0.12), _trim(era), 0.001, Basis(Vector3.BACK, -angle))
		_cup(b, cup, tangent, Paint.coat(Paint.BONE if era == Eras.SECOND else Paint.YELLOW, 0.45, 0.08, 0.5))
	if era == Eras.SECOND:
		b.ball(1, Vector3(-0.029, -0.012, 0.035), _skin(era), Vector3(0.032, 0.04, 0.015))
		_cord(b, Vector3(0, 0, 0.072), 0.016)


static func _cup(b: Paint.Pieces, at: Vector3, opening: Vector3, coat: Paint.Coat) -> void:
	# A hollow hemisphere, not a capped drum: every mouth catches the same turn.
	if _cup_shell.is_empty():
		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		for band in 4:
			var low := band * PI / 8.0
			var high := (band + 1) * PI / 8.0
			for side in 12:
				var a := side * TAU / 12.0
				var z := (side + 1) * TAU / 12.0
				var points := [Vector3(sin(low) * cos(a), -cos(low), sin(low) * sin(a)),
					Vector3(sin(high) * cos(a), -cos(high), sin(high) * sin(a)),
					Vector3(sin(high) * cos(z), -cos(high), sin(high) * sin(z)),
					Vector3(sin(low) * cos(z), -cos(low), sin(low) * sin(z))]
				for face: Array in [[0, 1, 2], [0, 2, 3]]:
					var outer := [points[face[0]], points[face[1]], points[face[2]]]
					_cup_face(vertices, normals, outer, outer)
					_cup_face(vertices, normals, [outer[0] * 0.86, outer[1] * 0.86, outer[2] * 0.86], [-outer[0], -outer[1], -outer[2]])
				if band == 3:
					var x: Vector3 = points[1]
					var y: Vector3 = points[2]
					_cup_face(vertices, normals, [x, y, y * 0.86], [Vector3.UP, Vector3.UP, Vector3.UP])
					_cup_face(vertices, normals, [x, y * 0.86, x * 0.86], [Vector3.UP, Vector3.UP, Vector3.UP])
		_cup_shell.resize(Mesh.ARRAY_MAX)
		_cup_shell[Mesh.ARRAY_VERTEX] = vertices
		_cup_shell[Mesh.ARRAY_NORMAL] = normals
	var turn := Basis(Quaternion(Vector3.UP, opening)) * Basis.from_scale(Vector3.ONE * 0.019)
	b._add(_cup_shell, Transform3D(turn, at), coat, Vector3.ONE, 1.0)

static func _cup_face(vertices: PackedVector3Array, normals: PackedVector3Array, points: Array, facing: Array) -> void:
	var cross: Vector3 = (points[1] - points[0]).cross(points[2] - points[0])
	if cross.length_squared() < 1e-12: return
	var order := [0, 2, 1] if cross.dot(facing[0] + facing[1] + facing[2]) > 0 else [0, 1, 2]
	for i: int in order:
		vertices.append(points[i])
		normals.append(facing[i])

static func _pressure(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var r := size.x * 0.5
	b.drum(r - 0.003, 0.027, Vector3(0, 0, 0.014), _metal(), ALONG, 24)
	b.drum(r - 0.013, 0.012, Vector3(0, 0, 0.032), _skin(era), ALONG, 24)
	b.drum(r - 0.020, 0.004, Vector3(0, 0, 0.041), Paint.coat(Paint.BONE, 0, 0, 0.25, 0.1), ALONG, 24)
	b.ring(r - 0.021, r - 0.010, Vector3(0, 0, 0.042), _trim(era), ALONG, 12)
	for i in 13:
		var angle := -2.25 + i * 4.5 / 12
		var turn := Basis(Vector3.BACK, angle)
		b.box(Vector3(0.003, 0.008 if i % 3 == 0 else 0.005, 0.002), turn * Vector3(0, r - 0.029, 0) + Vector3(0, 0, 0.045), _dark(), 0, turn)
	b.drum(0.007, 0.004, Vector3(0, 0, 0.049), _trim(era), ALONG, 12)
	var turn := Basis(Vector3.BACK, 0.5)
	b.box(Vector3(0.0025, 0.053, 0.002), turn * Vector3(0, 0.018, 0) + Vector3(0, 0, 0.052), _dark(), 0.0005, turn)
	b.box(Vector3(0.009, 0.006, 0.002), Vector3(-0.032, 0.035, 0.047), Paint.coat(Paint.YELLOW), 0.001)
	for x in [-0.063, 0.063]: _bolt(b, Vector3(x, 0, 0.033), 0.004)
	if era == Eras.SECOND:
		b.ball(1, Vector3(0.052, -0.04, 0.021), _skin(era), Vector3(0.022, 0.032, 0.018))
		b.box(Vector3(0.025, 0.012, 0.016), Vector3(-0.032, -0.059, 0.023), Paint.coat(Paint.SALTWOOD), 0.004)
	elif era == Eras.FIRST:
		b.drum(r - 0.009, 0.012, Vector3(0, 0, 0.026), _trim(era), ALONG, 24)

static func _humidity(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	_plate(b, size, 0.025, era)
	if era == Eras.SECOND:
		b.ball(1, Vector3(0.005, 0, 0.046), _skin(era), Vector3(0.060, 0.068, 0.025))
	else:
		b.box(Vector3(size.x - 0.018, size.y - 0.018, 0.045), Vector3(0, 0, 0.049), _skin(era), 0.013)
	for y in [-0.04, -0.012, 0.016, 0.044]:
		b.box(Vector3(size.x - 0.038, 0.011, 0.012), Vector3(0, y, 0.070), _dark(), 0.002)
		b.box(Vector3(size.x - 0.038, 0.003, 0.014), Vector3(0, y + 0.008, 0.071), _trim(era), 0.001)
	b.box(Vector3(0.012, 0.068, 0.004), Vector3(-0.043, 0, 0.074), Paint.coat(Paint.BONE), 0.001)
	if era == Eras.SECOND: _cord(b, Vector3(0.040, -0.03, 0.043), 0.017, Basis.IDENTITY)

static func _dust(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	_plate(b, size, 0.025, era)
	b.box(Vector3(size.x - 0.02, size.y - 0.02, 0.035), Vector3(0, 0, 0.042), _skin(era), 0.009)
	b.drum(0.028, 0.064, Vector3(0, 0, 0.087), _metal(), ALONG, 16, 0.022)
	for z in [0.061, 0.098]: b.drum(0.033, 0.010, Vector3(0, 0, z), _trim(era), ALONG, 16)
	b.drum(0.030, 0.020, Vector3(0, 0, size.z - 0.014), Paint.coat(Paint.YELLOW), ALONG, 16)
	b.drum(0.022, 0.004, Vector3(0, 0, size.z - 0.003), _dark(), ALONG, 16)
	for x in [-0.012, 0, 0.012]:
		b.box(Vector3(0.002, 0.032, 0.002), Vector3(x, 0, size.z - 0.0015), _trim(era), 0)
	if era == Eras.SECOND:
		b.ball(1, Vector3(-0.037, -0.019, 0.045), _skin(era), Vector3(0.034, 0.029, 0.022))
		_cord(b, Vector3(0, 0, 0.083), 0.030)

static func _survey(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	_plate(b, size, 0.025, era)
	b.box(Vector3(size.x - 0.018, size.y - 0.02, size.z - 0.04), Vector3(0, 0, (size.z + 0.02) * 0.5), Paint.coat(Paint.BONE, 0.55, 0.1, 0.55) if era == Eras.NEW else _skin(era), 0.014)
	for x in [-1, 1]:
		b.box(Vector3(0.018, size.y - 0.01, size.z - 0.025), Vector3(x * (size.x * 0.5 - 0.011), 0, (size.z + 0.025) * 0.5), _metal(), 0.005)
	# The guarded antenna looks into the sand, clear of the rear connector.
	b.box(Vector3(size.x - 0.05, 0.010, size.z - 0.065), Vector3(0, -size.y * 0.5 + 0.007, size.z * 0.6), _dark(), 0.003)
	for z in [0.06, 0.09, 0.12]:
		b.box(Vector3(size.x - 0.065, 0.006, 0.003), Vector3(0, -size.y * 0.5 + 0.003, z), _trim(era), 0.001)
	b.box(Vector3(size.x - 0.044, 0.012, 0.008), Vector3(0, 0.045, size.z - 0.012), Paint.coat(Paint.YELLOW, 0.6), 0.002)
	for x in [-0.04, 0, 0.04]:
		b.drum(0.006, 0.003, Vector3(x, 0.02, size.z - 0.003), Paint.coat(Paint.TEAL, 0, 0, 0.4, 0.3, 1.5), ALONG, 8)
	if era == Eras.SECOND:
		b.ball(1, Vector3(-0.045, 0.023, 0.10), _skin(era), Vector3(0.038, 0.045, 0.05))
		b.box(Vector3(0.016, 0.10, 0.04), Vector3(size.x * 0.5 - 0.011, 0, 0.11), Paint.coat(Paint.SALTWOOD), 0.005)

static func _radar(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	b.drum(0.07, 0.035, Vector3(0, 0, 0.018), _metal(), ALONG, 20)
	b.drum(0.026, 0.102, Vector3(0, 0, 0.083), _trim(era), ALONG, 16)
	b.drum(0.036, 0.022, Vector3(0, 0, 0.12), _skin(era), ALONG, 16)
	b.drum(0.108, 0.025, Vector3(0, 0.024, 0.145), _skin(era), Basis.IDENTITY, 24, 0.060)
	b.drum(0.086, 0.005, Vector3(0, 0.038, 0.145), _dark(), Basis.IDENTITY, 24, 0.06)
	b.drum(0.015, 0.07, Vector3(0, 0.069, 0.145), _trim(era), Basis.IDENTITY, 12)
	for x in [-1, 1]:
		b.box(Vector3(0.009, 0.045, 0.008), Vector3(x * 0.068, 0.037, 0.145), _trim(era), 0.002, Basis(Vector3.BACK, x * 0.6))
	if era == Eras.SECOND:
		b.ball(1, Vector3(-0.047, 0, 0.027), _skin(era), Vector3(0.04, 0.045, 0.025))
		_cord(b, Vector3(0, 0, 0.073), 0.028)
	elif era == Eras.FIRST:
		b.drum(0.075, 0.012, Vector3(0, 0, 0.032), _trim(era), ALONG, 20)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.035, 0.02, 0.10), Vector3(0.02, -0.025, 0.10), _metal(), 0.003)

static func _harvester(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	_plate(b, size, 0.018, era)
	b.box(Vector3(size.x - 0.025, size.y - 0.025, 0.052), Vector3(0, 0, 0.045), _skin(era), 0.012)
	b.box(Vector3(size.x - 0.045, 0.052, 0.023), Vector3(0, -0.015, 0.085), _dark(), 0.004)
	for x in [-0.072, -0.036, 0, 0.036, 0.072]:
		b.box(Vector3(0.012, 0.048, 0.014), Vector3(x, -0.015, 0.092), Paint.coat(Paint.YELLOW, 0.7), 0.002)
	for x in [-1, 1]:
		b.drum(0.026, 0.008, Vector3(x * 0.095, 0, 0.045), _trim(era), Basis(Vector3.BACK, PI / 2), 12)
	if era == Eras.SECOND:
		b.ball(1, Vector3(-0.06, 0.005, 0.044), _skin(era), Vector3(0.04, 0.05, 0.027))
		b.box(Vector3(0.014, 0.09, 0.035), Vector3(0.09, 0, 0.05), Paint.coat(Paint.SALTWOOD), 0.004)

static func _screen(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	b.box(Vector3(size.x - 0.004, size.y - 0.004, 0.018), Vector3(0, 0, 0.009), _metal(), 0.006)
	b.box(Vector3(size.x - 0.038, size.y - 0.038, 0.004), Vector3(0, 0, size.z - 0.003), glass(), 0.001)
	for x in [-1, 1]:
		b.box(Vector3(0.014, size.y - 0.014, 0.011), Vector3(x * (size.x * 0.5 - 0.010), 0, 0.023), _skin(era), 0.003)
		for y in [-1, 1]: _bolt(b, Vector3(x * (size.x * 0.5 - 0.012), y * (size.y * 0.5 - 0.018), 0.026), 0.004)
	for y in [-1, 1]:
		b.box(Vector3(size.x - 0.03, 0.014, 0.012), Vector3(0, y * (size.y * 0.5 - 0.010), 0.023), _trim(era), 0.003)
	if era == Eras.SECOND:
		b.drum(0.007, size.y - 0.02, Vector3(-size.x * 0.5 + 0.009, 0, 0.020), Paint.coat(Paint.SALTWOOD), Basis.IDENTITY, 12)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.04, 0.016, 0.01), Vector3(size.x * 0.25, -size.y * 0.5 + 0.01, 0.023), Paint.coat(Paint.BONE), 0.001)

static func _solar(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	b.box(Vector3(size.x - 0.004, size.y - 0.004, 0.018), Vector3(0, 0, 0.01), _metal(), 0.006)
	for x in [-1, 1]:
		b.box(Vector3(0.022, size.y - 0.004, 0.026), Vector3(x * (size.x * 0.5 - 0.014), 0, 0.019), _skin(era), 0.005)
	for y in [-1, 1]:
		b.box(Vector3(size.x - 0.048, 0.022, 0.026), Vector3(0, y * (size.y * 0.5 - 0.014), 0.019), _skin(era), 0.005)
	var wide := (size.x - 0.07) / 4
	var tall := (size.y - 0.07) / 2
	for x in 4:
		for y in 2:
			var at := Vector3(-size.x * 0.5 + 0.035 + wide * (x + 0.5), -size.y * 0.5 + 0.035 + tall * (y + 0.5), 0.032)
			b.box(Vector3(wide - 0.007, tall - 0.007, 0.006), at, Paint.coat(Paint.CELL, 0, 0.15, 0.20), 0.002)
			for dx in [-0.035, 0, 0.035]: b.box(Vector3(0.0015, tall - 0.014, 0.001), at + Vector3(dx, 0, 0.0035), _trim(era), 0)
	if era == Eras.SECOND:
		b.drum(0.009, size.x - 0.03, Vector3(0, -size.y * 0.5 + 0.012, 0.021), Paint.coat(Paint.SALTWOOD), Basis(Vector3.BACK, PI / 2), 12)
		b.ball(1, Vector3(size.x * 0.5 - 0.023, size.y * 0.5 - 0.023, 0.02), _skin(era), Vector3(0.020, 0.020, 0.018))
	elif era == Eras.FIRST:
		b.box(Vector3(size.x - 0.018, 0.016, 0.03), Vector3(0, size.y * 0.5 - 0.01, 0.020), _trim(era), 0.004)
