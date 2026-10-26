class_name CampLooks
extends RefCounted
## Serviceable camp kit: tubs, insulated machines, field cases and canvas.
const IDS: Array[StringName] = [&"planter", &"deep_planter", &"burner", &"turbine", &"condenser", &"light_panel", &"console", &"cargo", &"survival_kit", &"bedroll"]
const ALONG := Basis(Vector3.RIGHT, PI / 2.0)
static var _eras := {}

static func frame(b: Paint.Pieces, id: StringName, size: Vector3, extra := 0.0, era := Eras.NEW) -> bool:
	match id:
		&"planter", &"deep_planter": _planter(b, size, era)
		&"burner": _burner(b, size, era)
		&"turbine": _turbine(b, size, extra, era)
		&"condenser": _condenser(b, size, era)
		&"light_panel": _solar(b, size, era)
		&"console": _console(b, size, era)
		&"cargo": _cargo(b, size, era)
		&"survival_kit": _kit(b, size, era)
		&"bedroll": _roll(b, size, era)
		_: return false
	return true

static func lineage(id: StringName, line: Array) -> ArrayMesh:
	if not IDS.has(id): return null
	var era := Eras.era_of(line)
	var key := [id, era]
	if not _eras.has(key):
		var spec: Dictionary = Catalog.DEVICES[id]
		var b := Paint.Pieces.new(-spec.size.y * 0.5)
		frame(b, id, spec.size, spec.get("mast", 0.0), era)
		_eras[key] = b.commit()
	return _eras[key]

static func _metal() -> Paint.Coat: return Paint.coat(Paint.GUNMETAL, 0.5, 0.65)
static func _dark() -> Paint.Coat: return Paint.coat(Paint.BLACK, 0.2, 0.1, 0.85)
static func _skin(era: StringName) -> Paint.Coat:
	return Paint.coat({Eras.COLONIAL: Paint.BONE, Eras.SECOND: Paint.LIMEWASH, Eras.SKIMMER: Paint.RUST}.get(era, Paint.TEAL), 0.55, 0.15)
static func _trim(era: StringName) -> Paint.Coat:
	return Paint.coat(Paint.BRASS if era == Eras.FIRST else Paint.STEEL, 0.5, 0.7)
static func _bolt(b: Paint.Pieces, at: Vector3, r := 0.01, turn := Basis.IDENTITY) -> void:
	b.drum(r, r * 0.45, at, Paint.coat(Paint.STEEL, 0.4, 0.7), turn, 6)
	b.box(Vector3(r, r * 0.12, r * 0.15), at + turn.y * r * 0.25, _dark(), 0.0, turn)
static func _bar(b: Paint.Pieces, a: Vector3, z: Vector3, r: float, look: Paint.Coat) -> void:
	var d := z - a
	b.drum(r, d.length(), (a + z) * 0.5, look, Basis(Quaternion(Vector3.UP, d.normalized())), 8)
static func _feet(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	for x in [-1, 1]:
		b.box(Vector3(0.075, 0.045, size.z - 0.04), Vector3(x * (h.x - 0.055), -h.y + 0.0225, 0), _metal(), 0.009)
static func _bindings(b: Paint.Pieces, at: Vector3, r: float, turn := Basis.IDENTITY) -> void:
	for t in [-0.009, 0.009]:
		b.ring(r, r + 0.008, at + turn.y * t, Paint.coat(Paint.CORD, 0.0, 0.0, 0.95), turn, 8)
static func _rim(b: Paint.Pieces, size: Vector3, y: float, wide: float, look: Paint.Coat) -> void:
	for s in [-1, 1]:
		b.box(Vector3(size.x, wide, wide), Vector3(0, y, s * (size.z - wide) * 0.5), look, wide * 0.2)
		b.box(Vector3(wide, wide, size.z - wide * 2), Vector3(s * (size.x - wide) * 0.5, y, 0), look, wide * 0.2)
static func _patch(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	if era == Eras.FIRST:
		b.box(Vector3(size.x * 0.65, 0.018, 0.035), Vector3(0, h.y - 0.013, h.z - 0.025), _trim(era), 0.005)
	elif era == Eras.SECOND:
		b.ball(1, Vector3(-h.x + 0.07, h.y - 0.07, -h.z + 0.07), Paint.coat(Paint.CERAMIC, 0.3), Vector3(0.068, 0.068, 0.068))
		_bindings(b, Vector3(-h.x + 0.04, 0, -h.z + 0.04), 0.025)
	elif era == Eras.SKIMMER:
		b.box(Vector3(size.x * 0.55, 0.024, 0.016), Vector3(-size.x * 0.1, h.y - 0.018, h.z - 0.014), _metal(), 0.002)

static func _planter(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	_feet(b, size)
	# The wet bed stays at the catalog's planting plane in every era.
	b.box(Vector3(size.x - 0.09, size.y - 0.065, size.z - 0.09), Vector3(0, 0.01, 0), _metal(), 0.025)
	b.box(Vector3(size.x - 0.10, 0.018, size.z - 0.10), Vector3(0, h.y - 0.017, 0), Paint.coat(Paint.SOIL, 0, 0, 1, 0), 0.004)
	_rim(b, size - Vector3(0.008, 0, 0.008), h.y - 0.025, 0.042, _skin(era))
	for s in [-1, 1]:
		if era == Eras.SECOND and s == 1:
			b.ball(1, Vector3(h.x - 0.065, -0.005, h.z - 0.065), Paint.coat(Paint.CERAMIC, 0.3), Vector3(0.063, h.y - 0.025, 0.063))
		else:
			b.box(Vector3(0.035, size.y - 0.07, size.z - 0.11), Vector3(s * (h.x - 0.032), 0.008, 0), _skin(era), 0.012)
		b.box(Vector3(size.x - 0.15, size.y - 0.11, 0.028), Vector3(0, -0.005, s * (h.z - 0.027)), _skin(era), 0.01)
		for x in [-0.28, 0, 0.28]:
			b.box(Vector3(0.022, size.y - 0.085, 0.02), Vector3(x, 0, s * (h.z - 0.02)), _trim(era), 0.004)
		for x in [-1, 1]: _bolt(b, Vector3(x * (h.x - 0.06), h.y - 0.004, s * (h.z - 0.035)), 0.008)
	if era == Eras.SECOND:
		b.drum(0.018, size.x - 0.12, Vector3(0, h.y - 0.030, -h.z + 0.030), Paint.coat(Paint.SALTWOOD), Basis(Vector3.BACK, PI / 2), 12)
		for x in [-0.24, 0.24]: _bindings(b, Vector3(x, h.y - 0.030, -h.z + 0.030), 0.018, Basis(Vector3.BACK, PI / 2))
	elif era == Eras.FIRST:
		_rim(b, size - Vector3(0.012, 0, 0.012), h.y - 0.013, 0.022, _trim(era))
	elif era == Eras.SKIMMER:
		b.box(Vector3(size.x * 0.65, 0.026, 0.018), Vector3(0.04, -0.04, h.z - 0.01), _metal(), 0.003)
	# The level gauge is a protected slit beside, not over, the water port.
	b.box(Vector3(0.10, 0.03, 0.008), Vector3(0.10, -0.025, h.z - 0.008), _dark(), 0.003)
	for x in [-0.03, 0, 0.03]: b.box(Vector3(0.008, 0.012, 0.004), Vector3(0.10 + x, -0.025, h.z - 0.002), Paint.coat(Paint.HOSE), 0)

static func _burner(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	_feet(b, size)
	if era == Eras.SECOND:
		b.ball(1, Vector3(0.025, -0.03, 0), Paint.coat(Paint.CERAMIC, 0.25), Vector3(h.x - 0.04, h.y - 0.055, h.z - 0.045))
	else:
		b.box(size - Vector3(0.065, 0.10, 0.065), Vector3(0, -0.02, 0), _skin(era), 0.035)
	b.box(Vector3(0.40, 0.37, 0.05), Vector3(0, -0.1, h.z - 0.028), _metal(), 0.02)
	b.box(Vector3(0.30, 0.17, 0.015), Vector3(0, -0.12, h.z - 0.010), _dark(), 0.008)
	for x in [-0.17, 0.17]:
		b.drum(0.018, 0.22, Vector3(x, -0.12, h.z - 0.025), _trim(era), Basis.IDENTITY, 10)
		_bolt(b, Vector3(x, -0.22, h.z - 0.003), 0.009, ALONG)
	# A ventilated heat guard and a cool latch make the insulated firebox readable.
	b.box(Vector3(0.014, 0.38, 0.43), Vector3(h.x - 0.011, 0.08, 0), _metal(), 0.006)
	for i in 6:
		b.box(Vector3(0.008, 0.018, 0.32), Vector3(h.x - 0.005, -0.045 + i * 0.045, 0), _dark(), 0.002)
	for z in [-0.18, 0.18]:
		for y in [-0.075, 0.24]: _bolt(b, Vector3(h.x - 0.005, y, z), 0.008, Basis(Vector3.BACK, -PI / 2))
	for y in [-0.16, -0.08]:
		b.box(Vector3(0.055, 0.014, 0.018), Vector3(0.12, y, h.z - 0.009), _trim(era), 0.003)
	b.drum(0.011, 0.09, Vector3(0.14, -0.12, h.z - 0.013), Paint.coat(Paint.SALTWOOD if era == Eras.SECOND else Paint.BLACK), Basis.IDENTITY, 10)
	# The fuel mouth leaves the existing socket free, just above the fire door.
	b.box(Vector3(0.40, 0.025, 0.10), Vector3(0, 0.17, h.z - 0.05), _metal(), 0.008)
	for x in [-0.20, 0.20]: b.box(Vector3(0.022, 0.14, 0.10), Vector3(x, 0.23, h.z - 0.05), _skin(era), 0.006)
	b.drum(0.052, 0.22, Vector3(-0.21, h.y - 0.11, -0.18), _metal(), Basis.IDENTITY, 14)
	b.drum(0.07, 0.025, Vector3(-0.21, h.y - 0.016, -0.18), _trim(era), Basis.IDENTITY, 12)
	for i in 6: b.box(Vector3(0.32, 0.015, 0.025), Vector3(0.04, -0.18 + i * 0.065, -h.z + 0.016), _trim(era), 0.003)
	if era == Eras.SECOND:
		_bindings(b, Vector3(-0.21, h.y - 0.10, -0.18), 0.052)
	else: _patch(b, size - Vector3(0.04, 0.04, 0.04), era)

static func _turbine(b: Paint.Pieces, size: Vector3, mast: float, era: StringName) -> void:
	var h := size * 0.5
	_feet(b, size)
	b.box(size - Vector3(0.035, 0.06, 0.035), Vector3(0, -0.005, 0), _skin(era), 0.022)
	_rim(b, size - Vector3(0.006, 0, 0.006), h.y - 0.025, 0.035, _trim(era))
	for x in [-0.13, -0.065, 0, 0.065, 0.13]:
		b.box(Vector3(0.018, 0.09, 0.012), Vector3(x, -0.01, -h.z + 0.01), _dark(), 0.003)
	b.drum(0.058, 0.055, Vector3(0, h.y - 0.03, 0), _metal(), Basis.IDENTITY, 16)
	# The mast ends at the same rotor pivot; the rotor remains a separate mesh.
	b.drum(0.035, mast, Vector3(0, h.y + mast * 0.5, 0), _metal(), Basis.IDENTITY, 16, 0.025)
	for y in [0.07, mast * 0.52, mast - 0.025]:
		b.drum(0.043, 0.025, Vector3(0, h.y + y, 0), _trim(era), Basis.IDENTITY, 12)
	if era == Eras.SECOND:
		b.ball(1, Vector3(-h.x + 0.07, 0.025, -h.z + 0.07), Paint.coat(Paint.CERAMIC), Vector3(0.068, 0.10, 0.068))
		_bindings(b, Vector3(0, h.y + 0.18, 0), 0.035)
		b.drum(0.038, 0.72, Vector3(0, h.y + 0.75, 0), Paint.coat(Paint.SALTWOOD), Basis.IDENTITY, 12)
	elif era == Eras.FIRST:
		for s in [-1, 1]: _bar(b, Vector3(s * 0.17, h.y - 0.02, 0), Vector3(0, h.y + 0.24, 0), 0.008, _trim(era))
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.075, 0.20, 0.05), Vector3(0.015, h.y + 0.5, 0), _metal(), 0.004)

static func _condenser(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	_feet(b, size)
	b.box(size - Vector3(0.07, 0.08, 0.07), Vector3(0, 0, 0), _dark(), 0.025)
	for x in [-1, 1]:
		for z in [-1, 1]:
			b.box(Vector3(0.045, size.y - 0.03, 0.045), Vector3(x * (h.x - 0.026), 0, z * (h.z - 0.026)), _metal(), 0.008)
		b.box(Vector3(0.028, size.y - 0.14, size.z - 0.09), Vector3(x * (h.x - 0.027), 0.01, 0), _skin(era), 0.01)
		for i in 6:
			b.box(Vector3(0.015, 0.018, size.z - 0.17), Vector3(x * (h.x - 0.012), -0.12 + i * 0.06, 0), _trim(era), 0.003)
	b.box(Vector3(size.x - 0.09, size.y - 0.17, 0.022), Vector3(0, 0, -h.z + 0.023), _skin(era), 0.009)
	# An insulated receiver bowl sits under the existing water tap.
	b.drum(0.14, 0.17, Vector3(0.03, -0.18, 0.10), _skin(era), Basis.IDENTITY, 18)
	b.drum(0.19, 0.025, Vector3(0, h.y - 0.018, 0), _trim(era), Basis.IDENTITY, 20)
	b.drum(0.15, 0.012, Vector3(0, h.y - 0.009, 0), _dark(), Basis.IDENTITY, 20)
	for x in [-0.08, -0.04, 0, 0.04, 0.08]:
		b.box(Vector3(0.012, 0.008, 0.24), Vector3(x, h.y - 0.004, 0), _trim(era), 0.001)
	if era == Eras.SECOND:
		b.ball(1, Vector3(-0.13, -0.14, 0.13), Paint.coat(Paint.CERAMIC), Vector3(0.15, 0.17, 0.14))
		_bindings(b, Vector3(-h.x + 0.035, 0.05, -h.z + 0.035), 0.022)
	elif era == Eras.FIRST:
		_rim(b, size - Vector3(0.012, 0, 0.012), h.y - 0.035, 0.025, _trim(era))
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.035, size.y - 0.12, 0.03), Vector3(0.16, 0, -h.z + 0.017), _metal(), 0.004)

static func _solar(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	b.box(size - Vector3(0.012, 0.014, 0.012), Vector3(0, -0.005, 0), _metal(), 0.006)
	_rim(b, size - Vector3(0.004, 0, 0.004), 0, 0.022, _skin(era))
	var wide := (size.x - 0.07) / 4
	var deep := (size.z - 0.07) / 2
	for x in 4:
		for z in 2:
			var at := Vector3(-h.x + 0.035 + wide * (x + 0.5), 0.012, -h.z + 0.035 + deep * (z + 0.5))
			b.box(Vector3(wide - 0.007, 0.006, deep - 0.007), at, Paint.coat(Paint.CELL, 0.0, 0.35, 0.2), 0.002)
			for dx in [-0.035, 0, 0.035]: b.box(Vector3(0.0015, 0.001, deep - 0.012), at + Vector3(dx, 0.004, 0), _trim(era), 0)
	if era == Eras.SECOND:
		b.box(Vector3(size.x * 0.4, 0.018, 0.018), Vector3(-0.14, 0.009, -h.z + 0.012), Paint.coat(Paint.SALTWOOD), 0.006)
		b.ball(1, Vector3(h.x - 0.03, 0, h.z - 0.03), Paint.coat(Paint.CERAMIC), Vector3(0.028, 0.022, 0.028))
	elif era == Eras.FIRST:
		for x in [-1, 1]:
			b.box(Vector3(0.028, 0.028, size.z - 0.004), Vector3(x * (h.x - 0.018), 0, 0), _trim(era), 0.005)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.018, 0.028, size.z * 0.75), Vector3(0.22, 0, 0.02), _metal(), 0.003)
	for x in [-1, 1]:
		for z in [-1, 1]: _bolt(b, Vector3(x * (h.x - 0.025), 0.017, z * (h.z - 0.025)), 0.007)

static func _console(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	_feet(b, size)
	b.box(Vector3(size.x - 0.015, 0.075, size.z - 0.015), Vector3(0, -h.y + 0.04, 0), _metal(), 0.018)
	b.box(Vector3(size.x - 0.015, 0.035, size.z - 0.015), Vector3(0, h.y - 0.023, 0), _metal(), 0.01)
	for x in [-1, 1]:
		for z in [-1, 1]: b.box(Vector3(0.035, size.y - 0.035, 0.035), Vector3(x * (h.x - 0.022), 0, z * (h.z - 0.022)), _trim(era), 0.007)
		# Split service cheeks leave the computer-mod centres unobstructed.
		for z in [-1, 1]:
			if era == Eras.SECOND and x == 1 and z == -1:
				b.ball(1, Vector3(h.x - 0.026, 0.02, -0.19), Paint.coat(Paint.CERAMIC), Vector3(0.024, 0.56, 0.085))
			else:
				b.box(Vector3(0.025, size.y - 0.13, 0.16), Vector3(x * (h.x - 0.018), 0, z * 0.19), _skin(era), 0.007)
			for y in 8: b.box(Vector3(0.01, 0.009, 0.10), Vector3(x * (h.x - 0.005), -0.46 + y * 0.12, z * 0.19), _dark(), 0.001)
		for y in [-0.54, -0.36, -0.18, 0, 0.18, 0.36, 0.54]: _bolt(b, Vector3(x * (h.x - 0.024), y, -h.z + 0.006), 0.007, ALONG)
	# Electronics sit behind removable cheeks, with the same live display recess.
	b.box(Vector3(size.x - 0.12, size.y - 0.16, size.z - 0.12), Vector3(0, 0, 0.015), _dark(), 0.015)
	# The fitted display remains on the existing screen socket, ahead of this recess.
	b.box(Vector3(0.61, 1.13, 0.015), Vector3(0, 0.01, -h.z + 0.018), _dark(), 0.005)
	for y in [-0.57, 0.59]: b.box(Vector3(0.61, 0.025, 0.03), Vector3(0, y, -h.z + 0.017), _skin(era), 0.006)
	b.box(Vector3(size.x - 0.10, size.y - 0.15, 0.025), Vector3(0, 0.015, h.z - 0.018), _skin(era), 0.01)
	for y in [-0.42, 0.25]:
		b.drum(0.095, 0.012, Vector3(0.03, y, h.z - 0.008), _dark(), ALONG, 18)
		for x in [-0.05, 0, 0.05]: b.box(Vector3(0.01, 0.14, 0.008), Vector3(0.03 + x, y, h.z - 0.004), _trim(era), 0.001)
	if era == Eras.SECOND:
		# A lost rear corner is a salt-glazed service jar, bound to the rack.
		b.ball(1, Vector3(-h.x + 0.085, 0.13, h.z - 0.085), Paint.coat(Paint.CERAMIC), Vector3(0.08, 0.38, 0.08))
		for y in [-0.10, 0.34]: _bindings(b, Vector3(-h.x + 0.035, y, h.z - 0.035), 0.025)
		b.box(Vector3(0.022, 0.82, 0.15), Vector3(h.x - 0.018, -0.06, -0.18), Paint.coat(Paint.SALTWOOD), 0.008)
	elif era == Eras.FIRST:
		b.box(Vector3(size.x - 0.025, 0.045, 0.10), Vector3(0, h.y - 0.026, 0), _trim(era), 0.012)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.035, 0.8, 0.028), Vector3(-h.x + 0.02, 0, h.z - 0.016), _metal(), 0.003)

static func _cargo(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	# Drop orange is a recognition cue, even on a container repaired by later hands.
	b.box(size - Vector3(0.04, 0.04, 0.08), Vector3.ZERO, Paint.coat(Paint.DROP_ORANGE, 0.45, 0.2), 0.04)
	for z in [-1, 1]:
		if era == Eras.SECOND and z == -1:
			b.ball(1, Vector3(0, 0, -h.z + 0.09), Paint.coat(Paint.CERAMIC), Vector3(h.x - 0.005, h.y - 0.005, 0.087))
		else:
			b.box(Vector3(size.x - 0.006, size.y - 0.006, 0.055), Vector3(0, 0, z * (h.z - 0.029)), _metal(), 0.018)
		for x in [-1, 1]:
			for y in [-1, 1]:
				b.box(Vector3(0.11, 0.11, 0.06), Vector3(x * (h.x - 0.058), y * (h.y - 0.058), z * (h.z - 0.033)), _dark(), 0.012)
		b.box(Vector3(0.23, 0.035, 0.02), Vector3(0, 0.08, z * (h.z - 0.011)), _trim(era), 0.007)
	for z in [-0.26, 0.26]: _cargo_band(b, size, z, era)
	# Rails stop at the supplies' socket plane rather than growing through it.
	for y in [-0.30, 0, 0.30]: b.box(Vector3(0.018, 0.025, size.z - 0.22), Vector3(h.x - 0.01, y, -0.06), _metal(), 0.004)
	_patch(b, size - Vector3(0.015, 0.015, 0.015), era)
static func _cargo_band(b: Paint.Pieces, size: Vector3, z: float, era: StringName) -> void:
	var h := size * 0.5
	for x in [-1, 1]: b.box(Vector3(0.018, size.y - 0.015, 0.05), Vector3(x * (h.x - 0.012), 0, z), _trim(era), 0.004)
	for y in [-1, 1]: b.box(Vector3(size.x - 0.015, 0.018, 0.05), Vector3(0, y * (h.y - 0.012), z), _dark(), 0.004)

static func _kit(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	if era == Eras.SECOND:
		b.box(size - Vector3(0.06, 0.03, 0.025), Vector3(0.015, -0.006, 0), Paint.coat(Paint.YELLOW, 0.55), 0.022)
		b.ball(1, Vector3(-h.x + 0.065, 0, 0.05), Paint.coat(Paint.CERAMIC), Vector3(0.06, 0.12, 0.12))
	else:
		b.box(size - Vector3(0.025, 0.03, 0.025), Vector3(0, -0.006, 0), Paint.coat(Paint.YELLOW, 0.55), 0.022)
	_rim(b, size - Vector3(0.008, 0, 0.008), h.y - 0.055, 0.022, _dark())
	for x in [-1, 1]:
		for z in [-1, 1]: b.box(Vector3(0.045, size.y - 0.01, 0.045), Vector3(x * (h.x - 0.024), 0, z * (h.z - 0.024)), _metal(), 0.007)
		b.box(Vector3(0.035, 0.06, 0.016), Vector3(x * 0.18, 0.025, h.z - 0.009), _trim(era), 0.004)
		b.box(Vector3(0.018, 0.015, 0.08), Vector3(x * 0.18, h.y - 0.011, 0), _metal(), 0.003)
	# A recessed pull on the back leaves the two supply sockets clear.
	for x in [-0.085, 0.085]:
		b.box(Vector3(0.025, 0.055, 0.014), Vector3(x, 0, -h.z + 0.01), _trim(era), 0.004)
	b.drum(0.009, 0.16, Vector3(0, 0.018, -h.z + 0.012), _dark(), Basis(Vector3.BACK, PI / 2), 10)
	_patch(b, size - Vector3(0.01, 0.01, 0.01), era)

static func _cloth(era: StringName) -> Paint.Coat:
	return Paint.coat({Eras.COLONIAL: Paint.BONE, Eras.SECOND: Paint.OCHRE_DYE, Eras.SKIMMER: Paint.RUST_DYE}.get(era, Paint.TEAL), 0, 0, 0.95)
static func _roll(b: Paint.Pieces, size: Vector3, era: StringName) -> void:
	var h := size * 0.5
	var r := h.x - 0.009
	b.drum(r, size.z - 0.025, Vector3.ZERO, _cloth(era), ALONG, 24)
	for s in [-1, 1]:
		b.drum(r - 0.012, 0.008, Vector3(0, 0, s * (h.z - 0.012)), Paint.coat(Paint.BONE, 0, 0, 0.95), ALONG, 24)
		b.ring(r - 0.006, r + 0.006, Vector3(0, 0, s * 0.26), Paint.coat(Paint.CORD if era == Eras.SECOND else Paint.BLACK), ALONG, 20)
		b.box(Vector3(0.035, 0.016, 0.045), Vector3(0, r + 0.001, s * 0.26), _trim(era), 0.003)
	# The exposed end shows concentric folds rather than a solid painted disk.
	for r1 in [0.04, 0.065, 0.09]:
		b.ring(r1 - 0.002, r1 + 0.002, Vector3(0, 0, h.z - 0.006), _cloth(era), ALONG, 24)
	if era == Eras.SECOND:
		b.box(Vector3(0.06, 0.012, 0.17), Vector3(0.02, 0.099, -0.08), Paint.coat(Paint.SALTWOOD), 0.005)
	elif era == Eras.FIRST:
		b.box(Vector3(0.04, 0.012, 0.28), Vector3(0.02, 0.101, 0), _trim(era), 0.004)
	elif era == Eras.SKIMMER:
		b.box(Vector3(0.018, 0.01, 0.15), Vector3(-0.04, 0.10, 0.07), Paint.coat(Paint.BONE), 0.001)

## The same stored canvas unrolls along the bedroll's existing head-to-foot path.
static func unroll(open: float, era: StringName) -> ArrayMesh:
	var size: Vector3 = Catalog.DEVICES[&"bedroll"].size
	var h := size * 0.5
	var b := Paint.Pieces.new(-h.y)
	var foot := -h.y
	var head := -h.x
	var r0 := h.x - 0.009
	var r := sqrt(r0 * r0 * (1 - open) + Dress.BEDROLL_HEM * Dress.BEDROLL_HEM * open)
	var x := head + r0 + open * (Dress.BEDROLL_LENGTH - r0 - Dress.BEDROLL_HEM)
	var laid := x - head
	var wide := size.z - 0.025
	b.box(Vector3(laid, Dress.BEDROLL_PAD, wide), Vector3(head + laid * 0.5, foot + Dress.BEDROLL_PAD * 0.5, 0), _cloth(era), 0.006)
	for z in [-1, 1]:
		b.box(Vector3(laid, 0.004, 0.012), Vector3(head + laid * 0.5, foot + Dress.BEDROLL_PAD + 0.001, z * (wide * 0.5 - 0.012)), Paint.coat(Paint.BONE, 0, 0, 0.95), 0.001)
		b.box(Vector3(0.29, 0.004, 0.025), Vector3(head - 0.015, foot + 0.002, z * 0.26), Paint.coat(Paint.CORD if era == Eras.SECOND else Paint.BLACK), 0)
	var seam := 0.40
	while head + seam < x - r:
		b.box(Vector3(0.012, 0.004, wide - 0.05), Vector3(head + seam, foot + Dress.BEDROLL_PAD + 0.001, 0), Paint.coat(Paint.BONE, 0, 0, 0.95), 0)
		seam += 0.28
	var plump := smoothstep(0, 0.25, open)
	b.ball(1, Vector3(head + 0.13, foot + Dress.BEDROLL_PAD + 0.065 * plump, 0), Paint.coat(Paint.BONE, 0, 0, 0.95), Vector3(0.12, 0.065 * plump + 0.005, 0.36))
	if x - r > head + 0.5:
		b.box(Vector3(0.2, 0.012, wide - 0.03), Vector3(head + 0.38, foot + Dress.BEDROLL_PAD + 0.006, 0), Paint.coat(Paint.BONE, 0, 0, 0.95), 0.004)
	b.drum(r, wide, Vector3(x, foot + r, 0), _cloth(era), ALONG, 24)
	for s in [-1, 1]:
		b.drum(maxf(r - 0.015, r * 0.5), 0.008, Vector3(x, foot + r, s * wide * 0.5), Paint.coat(Paint.BONE, 0, 0, 0.95), ALONG, 24)
	return b.commit()
