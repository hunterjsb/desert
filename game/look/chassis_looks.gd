class_name ChassisLooks
extends RefCounted
## Recoverable structural kit: extrusions, service plates and bolted fittings.
## Frames sit on their centres; socket parts grow along +Z as the catalog does.

const FRAMES: Array[StringName] = [&"chassis", &"helm_seat", &"hand_winch", &"mast", &"mast_top", &"boom", &"stake"]
const PARTS: Array[StringName] = [&"frame", &"hull_plate"]
const ALONG := Basis(Vector3.RIGHT, PI / 2.0)
static var _eras := {}

static func frame(b: Paint.Pieces, id: StringName, size: Vector3, era := Eras.NEW) -> bool:
	match id:
		&"chassis": _deck(b, size, era)
		&"helm_seat": _seat(b, size, era)
		&"hand_winch": _winch(b, size, era)
		&"mast": _mast(b, size, era)
		&"mast_top": _spar(b, size, true)
		&"boom": _spar(b, size, false)
		&"stake": _stake(b, size)
		_: return false
	return true

static func part(b: Paint.Pieces, id: StringName, size: Vector3, era := Eras.NEW) -> bool:
	match id:
		&"frame": _frame(b, size, era)
		&"hull_plate": _plate(b, size, era)
		_: return false
	return true

## Reuses Dress's lineage cache: shape and overlaid marks remain one surface.
static func lineage(id: StringName, line: Array) -> ArrayMesh:
	var b: Paint.Pieces
	var era := Eras.era_of(line)
	var key := [id, era]
	if _eras.has(key):
		return _eras[key]
	if FRAMES.has(id) and Catalog.DEVICES.has(id):
		var size: Vector3 = Catalog.DEVICES[id].size
		b = Paint.Pieces.new(-size.y * 0.5)
		frame(b, id, size, era)
	elif PARTS.has(id):
		b = Paint.Pieces.new()
		part(b, id, Catalog.PARTS[id].size, era)
	else:
		return null
	_eras[key] = b.commit()
	return _eras[key]

static func _panel(era: StringName) -> Paint.Coat:
	var color: Color = {Eras.SECOND: Paint.CERAMIC, Eras.COLONIAL: Paint.BONE, Eras.SKIMMER: Paint.RUST}.get(era, Paint.TEAL)
	return Paint.coat(color, 0.65, 0.2, 0.6)

static func _metal() -> Paint.Coat:
	return Paint.coat(Paint.GUNMETAL, 0.5, 0.6, 0.5)

static func _black() -> Paint.Coat:
	return Paint.coat(Paint.BLACK, 0.25, 0.1, 0.8)

static func _bolt(b: Paint.Pieces, at: Vector3, radius := 0.012, turn := Basis.IDENTITY) -> void:
	b.drum(radius, radius * 0.5, at, Paint.coat(Paint.STEEL, 0.4, 0.8), turn, 6)
	b.box(Vector3(radius * 0.9, radius * 0.12, radius * 0.18), at + turn.y * radius * 0.28, _black(), 0.0, turn)

static func _bar(b: Paint.Pieces, a: Vector3, z: Vector3, width: float, coat: Paint.Coat) -> void:
	var d := z - a
	b.box(Vector3(width, d.length(), width), (a + z) * 0.5, coat, width * 0.15, Basis(Quaternion(Vector3.UP, d.normalized())))

static func _deck(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var metal := _metal()
	var panel := _panel(era)
	var edge := 0.075
	# Extruded perimeter and inset walking plates leave the joining rings clear.
	for s in [-1.0, 1.0]:
		b.box(Vector3(size.x - 0.14, size.y - 0.018, edge), Vector3(0, 0, s * (h.z - edge * 0.5 - 0.006)), metal, 0.012)
		if era == Eras.SECOND and s < 0:
			# A lost extrusion replaced by a round saltbush spar, lashed to the core.
			b.drum(0.045, size.z - 0.16, Vector3(-h.x + 0.055, -0.003, 0), Paint.coat(Paint.SALTWOOD, 0.45, 0.0, 0.9), ALONG, 12)
		else:
			b.box(Vector3(edge, size.y - 0.018, size.z - 0.14), Vector3(s * (h.x - edge * 0.5 - 0.006), 0, 0), metal, 0.012)
		b.box(Vector3(size.x - 0.22, 0.015, 0.025), Vector3(0, -h.y + 0.014, s * 0.22), metal, 0.004)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var at := Vector3(x * (h.x - 0.065), 0, z * (h.z - 0.065))
			if era == Eras.SECOND and x < 0 and z > 0:
				b.ball(1.0, Vector3(-h.x + 0.1, 0, h.z - 0.1), Paint.coat(Paint.CERAMIC, 0.45, 0.0, 0.3), Vector3(0.098, 0.055, 0.098))
			else:
				b.box(Vector3(0.13, size.y, 0.13), at, _black(), 0.022)
				_bolt(b, at + Vector3(0, h.y - 0.006, 0), 0.013)
	# Two removable panels, each with pressed channels and recessed screws.
	for x in [-1.0, 1.0]:
		var wide := (size.x - 0.19) * 0.5
		var at := Vector3(x * (wide * 0.5 + 0.006), h.y - Chassis.PANEL_DROP - 0.014, 0)
		if era == Eras.SECOND and x < 0:
			b.box(Vector3(wide - 0.015, 0.028, size.z - 0.2), at, Paint.coat(Paint.LIMEWASH, 0.5, 0.0, 0.9), 0.013)
			for z in [-0.24, 0.23]:
				b.box(Vector3(wide - 0.06, 0.009, 0.033), at + Vector3(0.01, 0.018, z), Paint.coat(Paint.SALTWOOD, 0.5, 0.0, 0.9), 0.005)
		else:
			b.box(Vector3(wide, 0.028, size.z - 0.18), at, panel, 0.007)
			for z in [-0.27, -0.09, 0.09, 0.27]:
				b.box(Vector3(wide - 0.05, 0.006, 0.012), at + Vector3(0, 0.016, z), metal, 0.002)
		for z in [-1.0, 1.0]:
			_bolt(b, at + Vector3(0, 0.017, z * (h.z - 0.125)), 0.009)
	# Side join shoes and high contrast tie points, rather than a painted edge.
	for side in 4:
		var turn := Basis(Vector3.UP, side * PI * 0.5)
		for x in [-0.25, 0.25]:
			b.box(Vector3(0.15, size.y * 0.58, 0.012), turn * Vector3(x, 0, h.z - 0.008), panel, 0.006, turn)
			Dress._hazard(b, Vector3(0.11, 0.024, 0.006), turn * Vector3(x, 0, h.z - 0.004), turn)
	# Era changes are structural: heirloom caps, ceramic repair, welded splice.
	if era == Eras.FIRST:
		for x in [-1.0, 1.0]:
			b.box(Vector3(0.065, 0.016, size.z - 0.27), Vector3(x * (h.x - 0.1), h.y - 0.009, 0), Paint.coat(Paint.YELLOW, 0.6, 0.65), 0.007)
			for z in [-0.23, 0.0, 0.23]:
				_bolt(b, Vector3(x * (h.x - 0.1), h.y - 0.005, z), 0.011)
	elif era == Eras.SECOND:
		for z in [-0.22, 0.22]:
			for turn in [-0.016, 0.0, 0.016]:
				b.ring(0.041, 0.052, Vector3(-h.x + 0.055, -0.003, z + turn), Paint.coat(Paint.CORD, 0.4, 0.0, 0.9), ALONG, 8)
	elif era == Eras.SKIMMER:
		for z in [-0.24, 0.17]:
			b.box(Vector3(0.25, 0.02, 0.09), Vector3(-0.12, h.y - 0.011, z), metal, 0.003, Basis(Vector3.UP, 0.2))
			for x in [-0.22, -0.02]:
				_bolt(b, Vector3(x, h.y - 0.005, z), 0.01)

static func _frame(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var rail := Frame.RAIL
	var e := size.x * 0.5 - rail * 0.5
	var metal := _metal()
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			b.box(Vector3(rail, rail, size.z - 0.04), Vector3(x * e, y * e, size.z * 0.5), metal, 0.009)
			# End castings with inset bolt heads; the holes remain open.
			for z in [0.04, size.z - 0.04]:
				b.box(Vector3(rail, rail, 0.08), Vector3(x * e, y * e, z), _panel(era), 0.012)
				_bolt(b, Vector3(x * e, y * e, z), 0.012, ALONG)
	for z in [rail * 0.5, size.z - rail * 0.5]:
		for s in [-1.0, 1.0]:
			b.box(Vector3(size.x - rail * 2, rail * 0.85, rail * 0.85), Vector3(0, s * e, z), metal, 0.006)
			b.box(Vector3(rail * 0.85, size.y - rail * 2, rail * 0.85), Vector3(s * e, 0, z), metal, 0.006)
	# Short corner knees make the frame read as a reusable load-bearing kit.
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			_bar(b, Vector3(x * (e - 0.13), y * e, 0.06), Vector3(x * e, y * (e - 0.13), 0.06), rail * 0.5, metal)

static func _plate(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var metal := _metal()
	b.box(Vector3(size.x, size.y, size.z * 0.72), Vector3(0, 0, size.z * 0.36), _panel(era), 0.012)
	for side in [-1.0, 1.0]:
		b.box(Vector3(size.x - 0.025, 0.028, size.z * 0.25), Vector3(0, side * (h.y - 0.02), size.z * 0.82), metal, 0.004)
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			_bolt(b, Vector3(x * (h.x - 0.04), y * (h.y - 0.04), size.z * 0.82), 0.012, ALONG)
	for x in [-0.16, 0.0, 0.16]:
		b.box(Vector3(0.024, size.y - 0.1, size.z * 0.22), Vector3(x, 0, size.z * 0.85), metal, 0.004)

	if era == Eras.FIRST:
		b.box(Vector3(0.1, 0.16, 0.004), Vector3(0, 0.12, size.z - 0.003), Paint.coat(Paint.YELLOW, 0.4, 0.6), 0.001)
	elif era == Eras.SECOND:
		b.box(Vector3(0.15, 0.28, 0.008), Vector3(0.13, 0, size.z - 0.004), Paint.coat(Paint.BONE, 0.5), 0.003)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.23, 0.07, 0.006), Vector3(-0.1, -0.1, size.z - 0.003), metal, 0.002, Basis(Vector3.BACK, 0.25))

static func _winch(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var metal := _metal()
	b.box(Vector3(size.x - 0.015, 0.035, size.z - 0.04), Vector3(0, -h.y + 0.018, 0), metal, 0.012)
	for x in [-1.0, 1.0]:
		var at := Vector3(x * (h.x - 0.035), -0.015, 0)
		b.box(Vector3(0.045, 0.23, 0.19), at, _panel(era), 0.014)
		b.drum(0.048, 0.02, at + Vector3(x * 0.012, 0.05, 0), metal, Basis(Vector3.BACK, PI / 2.0), 12)
		for z in [-0.13, 0.13]:
			_bolt(b, Vector3(x * (h.x - 0.04), -h.y + 0.04, z), 0.013)
	b.drum(0.083, 0.20, Vector3(0, 0.035, 0), _black(), ALONG, 16)
	for z in [-0.109, 0.109]:
		b.drum(0.105, 0.018, Vector3(0, 0.035, z), metal, ALONG, 20)
	for z in [-0.072, -0.036, 0.0, 0.036, 0.072]:
		b.ring(0.079, 0.091, Vector3(0, 0.035, z), Paint.coat(Paint.ROPE), ALONG, 12)
	# Pawl housing and fairlead cheek share the actual sheet entry's centre.
	b.box(Vector3(0.07, 0.07, 0.08), Vector3(-0.06, 0.07, -0.10), metal, 0.01)
	b.box(Vector3(0.12, 0.025, 0.06), Vector3(0, 0.0, -0.165), Paint.coat(Paint.YELLOW), 0.007)
	for x in [-0.05, 0.05]:
		b.drum(0.014, 0.05, Vector3(x, 0.035, -0.165), Paint.coat(Paint.STEEL, 0.4, 0.8), Basis.IDENTITY, 10)

	if era == Eras.FIRST:
		for x in [-1.0, 1.0]:
			b.box(Vector3(0.06, 0.025, 0.22), Vector3(x * (h.x - 0.035), 0.11, 0), Paint.coat(Paint.YELLOW, 0.5, 0.7), 0.009)
	elif era == Eras.SECOND:
		b.drum(0.055, 0.024, Vector3(h.x - 0.018, 0.04, 0), Paint.coat(Paint.CERAMIC, 0.5, 0.0, 0.3), Basis(Vector3.BACK, PI / 2.0), 12)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.015, 0.15, 0.09), Vector3(-h.x + 0.022, 0.01, 0.02), metal, 0.002, Basis(Vector3.RIGHT, 0.2))

static func _seat(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var metal := _metal()
	var panel := _panel(era)
	b.box(Vector3(size.x - 0.025, 0.04, size.z - 0.025), Vector3(0, -h.y + 0.02, 0), metal, 0.014)
	b.drum(0.075, 0.13, Vector3(0, -0.145, 0), metal, Basis.IDENTITY, 16)
	b.drum(0.09, 0.025, Vector3(0, -0.1, 0), Paint.coat(Paint.YELLOW), Basis.IDENTITY, 16)
	b.box(Vector3(size.x - 0.07, 0.055, size.z - 0.1), Vector3(0, -0.055, 0.015), panel, 0.018)
	if era == Eras.SECOND:
		b.box(Vector3(size.x - 0.11, 0.035, size.z - 0.15), Vector3(0, -0.012, 0.025), Paint.coat(Paint.SALTWOOD, 0.5, 0.0, 0.9), 0.015)
		b.ball(1.0, Vector3(0.015, 0.125, -h.z + 0.04), Paint.coat(Paint.CERAMIC, 0.45, 0.0, 0.3), Vector3(0.2, 0.12, 0.034))
		b.ball(1.0, Vector3(-0.02, 0.12, -h.z + 0.09), Paint.coat(Paint.SALTWOOD, 0.5, 0.0, 0.9), Vector3(0.16, 0.085, 0.02))
	else:
		b.box(Vector3(size.x - 0.11, 0.035, size.z - 0.15), Vector3(0, -0.012, 0.025), _black(), 0.015)
		b.box(Vector3(size.x - 0.07, 0.22, 0.06), Vector3(0, 0.13, -h.z + 0.04), panel, 0.018)
		b.box(Vector3(size.x - 0.12, 0.17, 0.026), Vector3(0, 0.13, -h.z + 0.085), _black(), 0.01)
	for x in [-1.0, 1.0]:
		_bar(b, Vector3(x * 0.19, -0.08, -0.18), Vector3(x * 0.19, 0.19, -0.21), 0.025, metal)
		if era == Eras.SECOND and x < 0:
			b.drum(0.018, 0.3, Vector3(x * (h.x - 0.02), 0.07, 0.015), Paint.coat(Paint.SALTWOOD, 0.5, 0.0, 0.9), ALONG, 12)
		else:
			b.box(Vector3(0.035, 0.035, 0.3), Vector3(x * (h.x - 0.02), 0.07, 0.015), panel, 0.009)
		for z in [-0.18, 0.18]:
			_bolt(b, Vector3(x * 0.18, -h.y + 0.045, z), 0.014)
	if era != Eras.SECOND:
		for x in [-0.12, 0.0, 0.12]:
			b.box(Vector3(0.01, 0.15, 0.004), Vector3(x, 0.13, -h.z + 0.1), panel, 0.001)

	if era == Eras.FIRST:
		b.box(Vector3(size.x - 0.025, 0.025, 0.075), Vector3(0, h.y - 0.014, -h.z + 0.04), Paint.coat(Paint.YELLOW, 0.5, 0.7), 0.01)
	elif era == Eras.SECOND:
		# A cord, bead and loose fringe belong to the repaired wooden arm.
		b.drum(0.004, 0.16, Vector3(-0.22, -0.02, 0.15), Paint.coat(Paint.CORD), Basis.IDENTITY, 8)
		b.ball(0.014, Vector3(-0.22, -0.11, 0.15), Paint.coat(Paint.CERAMIC, 0.45, 0.0, 0.3))
		for x in [-0.008, 0.0, 0.008]:
			_bar(b, Vector3(-0.22, -0.12, 0.15), Vector3(-0.22 + x, -0.185, 0.16), 0.003, Paint.coat(Paint.CORD))
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.05, 0.14, 0.022), Vector3(-0.09, 0.13, -h.z + 0.12), Paint.coat(Paint.ROPE), 0.003, Basis(Vector3.BACK, 0.2))

static func _mast(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var metal := _metal()
	b.drum(0.047, size.y - 0.02, Vector3.ZERO, Paint.coat(Paint.STEEL, 0.65, 0.7), Basis.IDENTITY, 20)
	for y in [-h.y + 0.045, h.y - 0.035, minf(Mast.BOOM_AT.y, h.y - 0.04)]:
		b.drum(0.066, 0.055, Vector3(0, y, 0), _panel(era), Basis.IDENTITY, 16)
		for x in [-1.0, 1.0]:
			_bolt(b, Vector3(x * 0.063, y, 0), 0.006, Basis(Vector3.BACK, PI / 2.0))
	for y in [-0.25, 0.12, 0.38]:
		b.box(Vector3(0.016, 0.14, 0.012), Vector3(0, y, 0.049), metal, 0.004)
	b.box(Vector3(0.045, 0.045, 0.04), Vector3(0, minf(Mast.BOOM_AT.y, h.y - 0.04), -0.05), metal, 0.008)

	if era == Eras.FIRST:
		b.drum(0.07, 0.035, Vector3(0, h.y - 0.02, 0), Paint.coat(Paint.YELLOW, 0.5, 0.7), Basis.IDENTITY, 12, 0.054)
	elif era == Eras.SECOND:
		for y in [0.16, 0.18, 0.20]:
			b.drum(0.06, 0.014, Vector3(0, y, 0), Paint.coat(Paint.CORD), Basis.IDENTITY, 12)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.025, 0.24, 0.014), Vector3(0.0, 0.2, 0.052), metal, 0.003)

static func _spar(b: Paint.Pieces, size: Vector3, up: bool) -> void:
	var length := size.y if up else size.z
	var direction := Vector3.UP if up else Vector3.BACK
	var turn := Basis.IDENTITY if up else ALONG
	var radius := minf(size.x, size.y if not up else size.z) * 0.5
	b.drum(radius * 0.78, length, direction * length * 0.5, Paint.coat(Paint.STEEL, 0.65, 0.7), turn, 16)
	for t in [0.025, 0.48, 0.97]:
		b.drum(radius, minf(length * 0.04, 0.04), direction * length * t, _metal(), turn, 16)
	for t in [0.18, 0.38, 0.58, 0.78]:
		b.box(Vector3(radius * 0.35, 0.05, radius * 0.14), Vector3(0, length * t, radius * 0.83) if up else Vector3(0, radius * 0.83, length * t), Paint.coat(Paint.YELLOW), 0.001, Basis.IDENTITY if up else ALONG)

static func _stake(b: Paint.Pieces, size: Vector3) -> void:
	var h := size.y * 0.5
	var metal := _metal()
	b.box(Vector3(0.04, size.y - 0.15, 0.04), Vector3(0, 0.015, 0), metal, 0.006)
	b.drum(0.028, 0.12, Vector3(0, -h + 0.06, 0), metal, Basis(Vector3.RIGHT, PI), 4, 0.0)
	b.box(Vector3(0.06, 0.04, 0.06), Vector3(0, h - 0.02, 0), Paint.coat(Paint.YELLOW), 0.009)
	for y in [h - 0.08, h - 0.13, h - 0.18]:
		b.box(Vector3(0.048, 0.013, 0.048), Vector3(0, y, 0), _black(), 0.004)
	for y in [-0.12, 0.0, 0.12]:
		b.box(Vector3(0.004, 0.035, 0.004), Vector3(0.022, y, 0), Paint.coat(Paint.YELLOW), 0.0)
