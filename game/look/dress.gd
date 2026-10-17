class_name Dress
extends RefCounted
## What each frame and part looks like in B's paint, inside its own box so
## nothing it touches changes: one merged mesh per catalog id, shared by every
## copy. A frame is centred on its box; a part stands out from its socket
## along +Z. Shapes are placeholders like the boxes were; only the finish is
## meant.

static var _made := {}


## A frame's look, or null to keep a grey box. `extra` is its mast's height.
static func frame(id: StringName, size: Vector3, extra := 0.0) -> ArrayMesh:
	return _cached(&"frame", id, func() -> ArrayMesh: return _frame(id, size, extra))


## A part's look, or null to keep a grey box.
static func part(id: StringName, size: Vector3) -> ArrayMesh:
	return _cached(&"part", id, func() -> ArrayMesh: return _part(id, size))


## What turns on a frame's mast head, about its own +Z, or null for none: a
## turbine's hub and blades, something to see turn into the wind, not to touch.
static func rotor(id: StringName) -> ArrayMesh:
	return _cached(&"rotor", id, func() -> ArrayMesh:
		if id != &"turbine":
			return null
		var b := Paint.Pieces.new()
		b.drum(0.06, 0.08, Vector3(0.0, 0.0, 0.04), Paint.coat(Paint.BLACK, 0.3, 0.3, 0.6), Basis(Vector3.RIGHT, PI / 2.0), 12)
		for s in [-1, 1]:
			b.box(Vector3(0.55, 0.08, 0.02), Vector3(s * 0.32, 0.0, 0.06), Paint.coat(Paint.BONE, 0.8), 0.006)
			b.box(Vector3(0.08, 0.082, 0.022), Vector3(s * 0.56, 0.0, 0.06), Paint.coat(Paint.YELLOW, 0.6), 0.004)
		return b.commit())


## A free socket's tell: a dark bezel with a tab in its kind's colour.
static func tell(kind: StringName) -> ArrayMesh:
	return _cached(&"tell", kind, func() -> ArrayMesh:
		var b := Paint.Pieces.new()
		var bezel := Paint.coat(Paint.BLACK, 0.6, 0.3, 0.5, 0.6)
		for s in [-1, 1]:
			b.box(Vector3(0.13, 0.022, 0.012), Vector3(0.0, s * 0.054, 0.006), bezel, 0.004)
			b.box(Vector3(0.022, 0.086, 0.012), Vector3(s * 0.054, 0.0, 0.006), bezel, 0.004)
		b.box(Vector3(0.088, 0.088, 0.006), Vector3(0.0, 0.0, 0.003), Paint.coat(Color(0.04, 0.04, 0.04), 0.0, 0.0, 0.7, 0.3))
		b.box(Vector3(0.084, 0.04, 0.008), Vector3(0.0, 0.022, 0.005), Paint.coat(Catalog.KINDS[kind], 0.0, 0.0, 0.5, 0.15, 0.35), 0.002)
		return b.commit())


## Builds every look now, while the world loads: the first of a kind costs
## up to a dozen milliseconds, too long for a find laid out while streaming.
static func prepare() -> void:
	for id: StringName in Catalog.DEVICES:
		Catalog.device(id).free()
	Catalog.stake().free()
	for id: StringName in Catalog.PARTS:
		Catalog.part(id).free()


static func _cached(group: StringName, id: StringName, build: Callable) -> ArrayMesh:
	var key := [group, id]
	if not _made.has(key):
		_made[key] = build.call()
	return _made[key]


static func _frame(id: StringName, size: Vector3, extra: float) -> ArrayMesh:
	var h := size * 0.5
	var b := Paint.Pieces.new(-h.y)
	var gun := Paint.coat(Paint.GUNMETAL)
	var teal := Paint.coat(Paint.TEAL)
	var black := Paint.coat(Paint.BLACK, 0.3, 0.3, 0.6)
	match id:
		&"crate_frame":
			for x in [-1, 1]:
				for z in [-1, 1]:
					b.box(Vector3(0.07, size.y, 0.07), Vector3(x * (h.x - 0.035), 0.0, z * (h.z - 0.035)), gun, 0.012)
					# Caps stand proud of the post and rails they meet: faces in one
					# plane fight over every pixel and flicker.
					for y in [-1, 1]:
						b.box(Vector3(0.116, 0.086, 0.116), Vector3(x * (h.x - 0.055), y * (h.y - 0.04), z * (h.z - 0.055)),
							Paint.coat(Paint.BLACK, 0.7, 0.3), 0.02)
			for y in [-1, 1]:
				for s in [-1, 1]:
					b.box(Vector3(size.x - 0.1, 0.06, 0.06), Vector3(0.0, y * (h.y - 0.03), s * (h.z - 0.03)), gun)
					b.box(Vector3(0.06, 0.06, size.z - 0.1), Vector3(s * (h.x - 0.03), y * (h.y - 0.03), 0.0), gun)
			# Panels set in between the rails, a seam across each. The two ring
			# sides carry its label, beside the ring: who it was sent to.
			for side in 4:
				var turn := Basis(Vector3.UP, side * PI * 0.5)
				var depth := h.z if side % 2 == 0 else h.x
				if side % 2 == 1:
					b.stamp(Paint.Mark.CONSIGNMENT, turn * Vector3(0.19, 0.08, depth - 0.025), 0.22, turn, Paint.Ink.PALE)
				b.box(Vector3(size.x - 0.14, size.y - 0.14, 0.03), turn * Vector3(0.0, 0.0, depth - 0.04), teal, 0.008, turn)
				b.box(Vector3(size.x - 0.16, 0.012, 0.034), turn * Vector3(0.0, -0.08, depth - 0.04), black, 0.002, turn)
			for y in [-1, 1]:
				b.box(Vector3(size.x - 0.12, 0.03, size.z - 0.12), Vector3(0.0, y * (h.y - 0.03), 0.0), teal if y > 0 else gun, 0.008)
		&"planter":
			# Another maker's growing tub, bone white on gunmetal skids.
			# Its top sits under the rim, and the rim's rails meet rather than cross.
			b.box(Vector3(size.x - 0.02, size.y - 0.054, size.z - 0.02), Vector3(0.0, 0.023, 0.0), Paint.coat(Paint.BONE), 0.03)
			b.box(Vector3(size.x - 0.08, 0.02, size.z - 0.08), Vector3(0.0, h.y - 0.012, 0.0), Paint.coat(Paint.SOIL, 0.0, 0.0, 1.0, 0.0), 0.004)
			for s in [-1, 1]:
				b.box(Vector3(size.x, 0.05, 0.05), Vector3(0.0, h.y - 0.025, s * (h.z - 0.025)), teal)
				b.box(Vector3(0.05, 0.05, size.z - 0.1), Vector3(s * (h.x - 0.025), h.y - 0.025, 0.0), teal)
				b.box(Vector3(0.12, 0.06, size.z - 0.06), Vector3(s * (h.x - 0.16), -h.y + 0.03, 0.0), gun)
			b.box(Vector3(size.x - 0.12, 0.012, 0.004), Vector3(0.0, -0.03, h.z - 0.009), black, 0.001)
		&"charger":
			b.box(size, Vector3.ZERO, gun, 0.025)
			for i in 4:
				b.box(Vector3(0.012, size.y * 0.55, 0.01), Vector3(-0.12 + i * 0.035, 0.0, -h.z + 0.004), black, 0.002)
			_hazard(b, Vector3(size.x * 0.9, 0.035, 0.012), Vector3(0.0, -h.y + 0.03, h.z - 0.004), Basis.IDENTITY)
		&"turbine":
			b.box(Vector3(size.x, size.y - 0.04, size.z), Vector3(0.0, -0.02, 0.0), gun, 0.03)
			b.box(Vector3(size.x - 0.06, 0.04, size.z - 0.06), Vector3(0.0, h.y - 0.02, 0.0), Paint.coat(Paint.YELLOW, 0.8), 0.01)
			for side in 4:
				var turn := Basis(Vector3.UP, side * PI * 0.5)
				# Its maker's sign on the side nothing plugs into.
				if side == 2:
					b.stamp(Paint.Mark.WIND_MAKER, turn * Vector3(0.0, -0.02, h.z), 0.24, turn, Paint.Ink.PALE)
				b.box(Vector3(size.x - 0.12, size.y - 0.14, 0.012), turn * Vector3(0.0, -0.02, h.z - 0.004), teal, 0.004, turn)
			# The mast; its hub and blades are its rotor, on the mast's head.
			b.drum(0.04, extra, Vector3(0.0, h.y + extra * 0.5, 0.0), gun, Basis.IDENTITY, 12, 0.03)
		&"condenser":
			for x in [-1, 1]:
				for z in [-1, 1]:
					b.box(Vector3(0.06, size.y, 0.06), Vector3(x * (h.x - 0.03), 0.0, z * (h.z - 0.03)), gun, 0.01)
			# The contractor's tag that set it up, under the louvres on its free side.
			b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.0, -0.12, -h.z + 0.02), 0.2, Basis(Vector3.UP, PI), Paint.Ink.PALE)
			b.box(Vector3(size.x - 0.04, size.y - 0.06, size.z - 0.04), Vector3.ZERO, teal, 0.01)
			# Louvres the night air comes in through.
			for side in 4:
				var turn := Basis(Vector3.UP, side * PI * 0.5)
				for i in 5:
					b.box(Vector3(size.x - 0.16, 0.014, 0.016), turn * Vector3(0.0, 0.08 + i * 0.045, h.z - 0.012), black, 0.003, turn)
			b.box(Vector3(size.x + 0.006, 0.056, size.z + 0.006), Vector3(0.0, h.y - 0.025, 0.0), gun, 0.012)
			# Its fan's ring, under the top mount's tell and over the lid.
			b.drum(0.2, 0.008, Vector3(0.0, h.y + 0.001, 0.0), black, Basis.IDENTITY, 20)
			_hazard(b, Vector3(size.x * 0.7, 0.035, 0.012), Vector3(0.0, -h.y + 0.05, h.z - 0.006), Basis.IDENTITY)
		&"shield", &"light_shield":
			# A different maker: bone white, round, finned, on pads for its sockets.
			# Bought new, it carries its maker's sign on its back; a deep one wears
			# the tag of the contractor who fitted it there, its maker's only on
			# the emitter.
			var r := h.x * 0.88
			var back := Basis(Vector3.UP, PI)
			var fitted := id == &"shield"
			b.drum(h.x * 0.98, size.y * 0.24, Vector3(0.0, -h.y + size.y * 0.12, 0.0), gun, Basis.IDENTITY, 20)
			b.stamp(Paint.Mark.CONTRACTOR if fitted else Paint.Mark.SHIELD_MAKER, Vector3(0.0, -h.y + size.y * 0.52, -r),
				0.12 if fitted else 0.16, back)
			b.drum(r, size.y * 0.6, Vector3(0.0, -h.y + size.y * 0.5, 0.0), Paint.coat(Paint.BONE, 0.4), Basis.IDENTITY, 24)
			for i in 8:
				var turn := Basis(Vector3.UP, i * TAU / 8.0 + PI / 8.0)
				b.box(Vector3(0.015, size.y * 0.4, h.x * 0.25), turn * Vector3(0.0, -0.02, r + h.x * 0.06), gun, 0.004, turn)
			for turn: Basis in [Basis.IDENTITY, Basis(Vector3.UP, PI * 0.5), Basis(Vector3.UP, -PI * 0.5)]:
				b.box(Vector3(0.13, 0.13, h.x - r + 0.02), turn * Vector3(0.0, -0.05 * size.y / 0.42, h.x - (h.x - r + 0.02) * 0.5), gun, 0.01, turn)
			if fitted:
				b.stamp(Paint.Mark.SHIELD_MAKER, Vector3(0.0, h.y - size.y * 0.14, -h.x * 0.65), 0.1, back, Paint.Ink.PALE)
			b.drum(h.x * 0.65, size.y * 0.12, Vector3(0.0, h.y - size.y * 0.14, 0.0), gun, Basis.IDENTITY, 20)
			b.ball(h.x * 0.5, Vector3(0.0, h.y - size.y * 0.13, 0.0), Paint.coat(Paint.CELL, 0.0, 0.4, 0.15, 0.4), Vector3(1.0, 0.55, 1.0))
			# A bracket out to the box's corner, where every frame's charge light sits.
			b.box(Vector3(0.09, 0.07, 0.09), Vector3(h.x - 0.045, h.y - 0.05, h.z - 0.05), gun, 0.01)
		&"light_panel":
			b.box(Vector3(size.x - 0.006, 0.03, size.z - 0.06), Vector3(0.0, -0.01, 0.0), Paint.coat(Paint.STEEL, 0.4, 0.5), 0.006)
			for s in [-1, 1]:
				b.box(Vector3(size.x, size.y, 0.03), Vector3(0.0, 0.0, s * (h.z - 0.015)), gun, 0.006)
			_cells(b, Vector2(size.x - 0.04, size.z - 0.08), 4, 2, Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0.0, 0.008, 0.0))
		&"survival_kit":
			# Packed to be found: the brightest thing on the sand.
			b.box(Vector3(size.x - 0.02, size.y - 0.02, size.z - 0.02), Vector3.ZERO, Paint.coat(Paint.YELLOW, 0.7), 0.03)
			b.box(Vector3(size.x - 0.01, 0.014, size.z - 0.01), Vector3(0.0, h.y - 0.07, 0.0), black, 0.003)
			for x in [-1, 1]:
				for y in [-1, 1]:
					for z in [-1, 1]:
						b.box(Vector3(0.06, 0.06, 0.06), Vector3(x * (h.x - 0.03), y * (h.y - 0.03), z * (h.z - 0.03)), gun, 0.01)
				b.box(Vector3(0.03, 0.06, 0.012), Vector3(x * (h.x - 0.03), h.y - 0.07, h.z - 0.003), black, 0.004)
		&"board":
			# A skimmer crew's patch on the tail, what shows when it's found.
			var tail := Basis(Vector3.LEFT, Vector3.BACK, Vector3.UP)
			b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(0.0, h.y, h.z - 0.1), 0.26, tail, Paint.Ink.PALE)
			b.box(Vector3(size.x, 0.03, size.z), Vector3(0.0, h.y - 0.015, 0.0), teal, 0.01)
			b.box(Vector3(size.x - 0.06, 0.006, size.z * 0.55), Vector3(0.0, h.y, 0.08), Paint.coat(Color(0.05, 0.05, 0.05), 0.2, 0.0, 0.95, 1.0), 0.002)
			b.box(Vector3(size.x - 0.04, size.y - 0.03, size.z - 0.1), Vector3(0.0, -0.015, 0.0), gun, 0.012)
			_hazard(b, Vector3(size.x + 0.004, 0.05, 0.034), Vector3(0.0, h.y - 0.015, -h.z + 0.06), Basis(Vector3.RIGHT, -PI / 2.0))
			for z in [-0.35, 0.35]:
				b.drum(0.07, 0.012, Vector3(0.0, -h.y + 0.005, z), Paint.coat(Color(0.45, 0.8, 1.0), 0.0, 0.0, 0.3, 0.3, 2.0), Basis.IDENTITY, 16)
		&"radio":
			# A set made to carry: a speaker's slats and a dial that lights
			# while it plays on its face, a handle, an aerial up from the back.
			b.box(Vector3(size.x - 0.02, size.y - 0.02, size.z - 0.02), Vector3.ZERO, teal, 0.02)
			for x in [-1, 1]:
				b.box(Vector3(0.03, size.y, size.z), Vector3(x * (h.x - 0.015), 0.0, 0.0), gun, 0.008)
				b.box(Vector3(0.02, 0.04, 0.02), Vector3(x * 0.09, h.y + 0.02, 0.0), gun, 0.004)
			for i in 6:
				b.box(Vector3(0.13, 0.012, 0.01), Vector3(-0.06, -0.065 + i * 0.026, h.z - 0.004), black, 0.002)
			b.box(Vector3(0.1, 0.045, 0.012), Vector3(0.08, 0.04, h.z - 0.004), Paint.coat(Color(1.0, 0.7, 0.35), 0.0, 0.0, 0.3, 0.2, 2.5), 0.003)
			b.drum(0.022, 0.02, Vector3(0.08, -0.04, h.z + 0.006), black, Basis(Vector3.RIGHT, PI / 2.0), 14)
			b.box(Vector3(0.2, 0.02, 0.025), Vector3(0.0, h.y + 0.045, 0.0), gun, 0.006)
			b.drum(0.006, 0.3, Vector3(-h.x + 0.045, h.y + 0.15, -h.z + 0.03), Paint.coat(Paint.STEEL, 0.8, 0.6), Basis.IDENTITY, 8)
		&"stake":
			var iron := Paint.coat(Paint.RUST.lightened(0.1), 1.4, 0.3, 0.8)
			b.box(Vector3(0.05, Stake.LENGTH - 0.12, 0.05), Vector3(0.0, 0.03, 0.0), iron, 0.01)
			b.drum(0.035, 0.12, Vector3(0.0, -h.y + 0.06, 0.0), iron, Basis(Vector3.RIGHT, PI), 4, 0.0)
			b.box(Vector3(0.09, 0.05, 0.09), Vector3(0.0, Stake.RING.y - 0.06, 0.0), iron, 0.012)
		_:
			return null
	return b.commit()


static func _part(id: StringName, size: Vector3) -> ArrayMesh:
	var b := Paint.Pieces.new()
	var h := size * 0.5
	var gun := Paint.coat(Paint.GUNMETAL)
	var steel := Paint.coat(Paint.STEEL, 0.8, 0.6)
	var black := Paint.coat(Paint.BLACK, 0.4, 0.2)
	var along := Basis(Vector3.RIGHT, PI / 2.0)
	match id:
		&"battery", &"big_battery":
			# Commodity: no maker's mark, only safety yellow on its terminals.
			b.box(size - Vector3(0.01, 0.01, 0.01), Vector3(0.0, 0.0, h.z), Paint.coat(Color(0.2, 0.21, 0.19), 0.6), 0.012)
			b.box(Vector3(size.x - 0.03, 0.03, size.z * 0.6), Vector3(0.0, h.y - 0.012, h.z), Paint.coat(Paint.YELLOW, 0.6), 0.006)
			b.box(Vector3(size.x * 0.5, 0.025, 0.02), Vector3(0.0, -h.y * 0.35, size.z + 0.002), black, 0.006)
		&"hook":
			b.drum(0.035, 0.02, Vector3(0.0, 0.0, 0.01), Paint.coat(Paint.GUNMETAL, 0.6, 0.3), along)
			b.drum(0.014, 0.12, Vector3(0.0, 0.0, 0.08), steel, along, 10)
		&"hover_tray":
			b.box(Vector3(size.x, size.y, 0.06), Vector3(0.0, 0.0, 0.03), gun, 0.015)
			for side in 4:
				var turn := Basis(Vector3.BACK, side * PI * 0.5)
				_hazard(b, Vector3(size.x * 0.82, 0.035, 0.012), turn * Vector3(0.0, h.y - 0.04, 0.062), turn)
			for x in [-1, 1]:
				for y in [-1, 1]:
					b.drum(0.08, 0.02, Vector3(x * 0.18, y * 0.18, 0.065), Paint.coat(Paint.BLACK, 0.3, 0.3), along, 16)
					b.drum(0.06, 0.012, Vector3(x * 0.18, y * 0.18, 0.074), Paint.coat(Color(0.45, 0.8, 1.0), 0.0, 0.0, 0.3, 0.3, 2.0), along, 16)
		&"solar_panel":
			b.box(Vector3(size.x, size.y, 0.03), Vector3(0.0, 0.0, 0.015), Paint.coat(Paint.STEEL, 0.4, 0.5), 0.006)
			_cells(b, Vector2(size.x - 0.04, size.y - 0.04), 4, 2, Basis.IDENTITY, Vector3(0.0, 0.0, 0.032))
		&"lamp":
			b.drum(0.03, 0.17, Vector3(0.0, 0.0, 0.085), gun, along, 10)
			b.drum(0.055, 0.08, Vector3(0.0, 0.0, 0.205), Paint.coat(Paint.YELLOW, 0.7), along, 16)
			b.drum(0.045, 0.01, Vector3(0.0, 0.0, size.z - 0.003), Paint.coat(Color(1.0, 0.85, 0.6), 0.0, 0.0, 0.2, 0.2, 3.0), along, 16)
		&"plug", &"strong_plug":
			var collar := Paint.coat(Color(1.0, 0.5, 0.1) if id == &"plug" else Color(0.7, 0.15, 0.1), 0.5)
			b.drum(h.x * 0.95, 0.025, Vector3(0.0, 0.0, 0.0125), collar, along, 12)
			b.drum(h.x * 0.8, size.z - 0.025, Vector3(0.0, 0.0, 0.025 + (size.z - 0.025) * 0.5), Paint.coat(Color(0.06, 0.06, 0.06), 0.2, 0.0, 0.85), along, 10, h.x * 0.55)
		&"coil":
			b.ring(0.09, 0.17, Vector3(0.0, 0.0, size.z * 0.5), Paint.coat(Paint.ROPE, 0.0, 0.0, 1.0, 0.6), along)
			b.box(Vector3(0.05, 0.1, 0.05), Vector3(0.13, 0.0, size.z * 0.5), Paint.coat(Paint.GUNMETAL, 0.6, 0.3), 0.008)
		&"canister":
			b.drum(h.x * 0.92, size.z - 0.04, Vector3(0.0, 0.0, (size.z - 0.04) * 0.5), Paint.coat(Color(0.55, 0.62, 0.68), 0.6, 0.5, 0.45), along, 16)
			b.drum(h.x * 0.5, 0.04, Vector3(0.0, 0.0, size.z - 0.02), Paint.coat(Paint.TEAL, 0.5), along, 12)
			for z in [0.06, size.z - 0.08]:
				b.drum(h.x * 0.95, 0.015, Vector3(0.0, 0.0, z), black, along, 16)
			b.box(Vector3(0.1, 0.012, 0.03), Vector3(0.0, h.y * 0.9, size.z * 0.6), black, 0.003)
		&"ration":
			b.box(size - Vector3(0.006, 0.006, 0.006), Vector3(0.0, 0.0, h.z), Paint.coat(Color(0.45, 0.42, 0.25), 0.3, 0.3, 0.5), 0.01)
			b.box(Vector3(size.x * 0.3, size.y + 0.002, size.z + 0.002), Vector3(-size.x * 0.2, 0.0, h.z), Paint.coat(Paint.YELLOW, 0.3), 0.004)
		&"harvester":
			b.box(Vector3(size.x, size.y, size.z * 0.6), Vector3(0.0, 0.0, size.z * 0.3), Paint.coat(Paint.TEAL), 0.012)
			b.box(Vector3(size.x - 0.02, size.y - 0.04, size.z * 0.4), Vector3(0.0, 0.0, size.z * 0.8), Paint.coat(Paint.YELLOW, 0.7), 0.008)
			for i in 5:
				b.box(Vector3(0.012, size.y * 0.5, 0.01), Vector3(-0.07 + i * 0.035, 0.0, size.z), black, 0.002)
		_:
			return null
	return b.commit()


## Solar cells in a grid over `area`, facing +Z of `turn`.
static func _cells(b: Paint.Pieces, area: Vector2, cols: int, rows: int, turn: Basis, at: Vector3) -> void:
	var cell := Vector2(area.x / cols, area.y / rows)
	for i in cols:
		for j in rows:
			var middle := Vector3(-area.x * 0.5 + (i + 0.5) * cell.x, -area.y * 0.5 + (j + 0.5) * cell.y, 0.0)
			b.box(Vector3(cell.x - 0.01, cell.y - 0.01, 0.006), at + turn * middle, Paint.coat(Paint.CELL, 0.2, 0.6, 0.18, 0.3), 0.001, turn)


## Black and yellow: the bands a safety officer would sign off.
static func _hazard(b: Paint.Pieces, size: Vector3, at: Vector3, turn: Basis) -> void:
	b.box(size, at, Paint.coat(Paint.YELLOW, 0.75), 0.003, turn)
	var n := int(size.x / (size.y * 1.6))
	for i in n:
		var x := -size.x * 0.5 + (i + 0.5) * size.x / n
		b.box(Vector3(size.y * 0.55, size.y * 1.05, size.z + 0.002), at + turn * Vector3(x, 0.0, 0.0), Paint.coat(Paint.BLACK, 0.6), 0.001,
			turn * Basis(Vector3.BACK, 0.7))
