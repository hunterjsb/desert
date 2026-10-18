class_name ColonialKit
extends RefCounted
## The colonial era's pieces (part 4): pylon stubs along the power lines,
## pipeline segments, hab pods, relay masts. Overbuilt and crisp (part 5):
## rounded rectangles, chamfered edges, modular panels, composites and
## alloys in off-white, grey and safety orange, the contractor's tag and a
## member state's seal on them. The deepest of the eras: big, mostly buried,
## rarely exposed; a storm strips a dune and shows a roof or a tower's top.

const PANEL := Color(0.8, 0.79, 0.74)
const GREY := Color(0.5, 0.52, 0.53)
const DARK := Color(0.24, 0.26, 0.27)
const ORANGE := Color(0.86, 0.42, 0.1)
const CONCRETE := Color(0.62, 0.6, 0.56)
const GLASS := Color(0.06, 0.09, 0.11)
const INSULATOR := Color(0.85, 0.82, 0.74)
## How much a lattice tower's face weighs on the eye far off, its members
## against the sky between: drawn a pixel or none, they read heavier than
## their width.
const LATTICE := 0.6

static var _coats := {}


static func pieces() -> Array[StructureKit.Piece]:
	return [_pylon_stub(), _pipeline_segment(), _hab_pod(), _relay_mast()]


static func coats() -> Dictionary:
	if _coats.is_empty():
		_coats = {"panel": Paint.coat(PANEL, 1.0, 0.1, 0.5), "grey": Paint.coat(GREY, 1.0, 0.5, 0.45),
			"dark": Paint.coat(DARK, 1.0, 0.4, 0.5), "orange": Paint.coat(ORANGE, 1.0, 0.1, 0.45),
			"concrete": Paint.coat(CONCRETE, 0.3, 0.0, 0.9), "glass": Paint.coat(GLASS, 0.2, 0.3, 0.08, 0.3),
			"steel": Paint.coat(Paint.STEEL, 0.8, 0.85, 0.4), "insulator": Paint.coat(INSULATOR, 0.2, 0.0, 0.25, 0.5)}
	return _coats


# --- The pylon stub: a power line's pylon, cut down to its stub. ---

static func _pylon_stub() -> StructureKit.Piece:
	var p := StructureKit.define(&"pylon_stub", Vector2(1.0, 1.0), Vector2(4.2, 4.2), Vector2(2.4, 2.4))
	p.apron = 3.5
	p.drift_reach = 1.5
	p.drift = PackedFloat32Array([0.2, 0.3, 0.3])
	p.survey = Vector2(0.7, 24.0)
	p.age = Vector2(0.08, 0.3)
	p.marks = 2
	# They run along the line: what slides keeps to it.
	p.slide = Vector2(0.0, 1.0)
	p.slide_m = 12.0
	StructureKit.box(p, Vector3(-1.0, -0.8, -1.0), Vector3(1.0, 0.4, 1.0), "concrete")
	StructureKit.box(p, Vector3(-0.3, 0.4, -0.3), Vector3(0.3, 4.8, 0.3), "")
	StructureKit.box(p, Vector3(-0.15, 4.4, -1.4), Vector3(0.15, 4.7, 1.4), "steel")
	StructureKit.box(p, Vector3(0.3, 1.0, -0.2), Vector3(0.55, 1.4, 0.2), "grey")
	for side in [-1.0, 1.0]:
		StructureKit.box(p, Vector3(-0.12, 3.9, side * 1.25 - 0.12), Vector3(0.12, 4.4, side * 1.25 + 0.12), "")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.55, 1.2, 0.0), &"shelf"))
	p.approach = Vector2(4.0, 5.0)
	p.look = _pylon_look
	# A row of them is a power line's trace across the dunes.
	var c := coats()
	StructureKit.far_box(p, Vector3(-1.0, -0.8, -1.0), Vector3(1.0, 0.4, 1.0), c.concrete)
	# Its lattice: thin members dark in their own shade, the sky between them.
	StructureKit.far_box(p, Vector3(-0.3, 0.4, -0.3), Vector3(0.3, 4.8, 0.3), c.dark, LATTICE)
	StructureKit.far_box(p, Vector3(-0.15, 4.4, -1.4), Vector3(0.15, 4.7, 1.4), c.steel)
	StructureKit.glint(p, Vector3(0.0, 4.7, 0.0), Vector3(0.0, 1.0, 0.25), 4.0)
	StructureKit.glint(p, Vector3(0.1, 4.3, 1.25), Vector3(0.9, 0.35, 0.25), 5.0)
	StructureKit.glint(p, Vector3(-0.1, 4.3, -1.25), Vector3(-0.9, 0.35, -0.25), 5.0)
	return p


static func _pylon_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.0, 0.05, 1.0), 0.9)
	StructureKit.draw_boxes(b, p, state, c, 0.05)
	lattice(b, Vector3(0.0, 0.4, 0.0), 0.3, 4.4, 1.1, c.grey, p, state)
	# A safety band, the insulators under the arm, a snapped cable hanging.
	if StructureKit.shows(p, state, 2.4):
		b.box(Vector3(0.66, 0.3, 0.66), Vector3(0.0, 2.25, 0.0), c.orange, 0.02)
	for side in [-1.0, 1.0]:
		for k in 3:
			b.drum(0.11, 0.06, Vector3(0.0, 4.3 - k * 0.14, side * 1.25), c.insulator, Basis.IDENTITY, 10)
		b.drum(0.03, 0.5, Vector3(0.0, 3.95, side * 1.25), c.steel, Basis.IDENTITY, 6)
	StructureKit.rod(b, Vector3(0.0, 3.7, 1.25), Vector3(0.4, 2.6, 1.6), 0.04, c.dark)


# --- The pipeline segment: a length of pipe on its saddles. ---

static func _pipeline_segment() -> StructureKit.Piece:
	var p := StructureKit.define(&"pipeline_segment", Vector2(0.95, 6.1), Vector2(1.6, 1.6), Vector2(1.0, 1.0))
	p.apron = 4.0
	p.drift_reach = 2.0
	# Buried, the sand humps over it, its back and flanges showing along the
	# top: a straight line in the dunes.
	p.drift = PackedFloat32Array([0.12, 0.3, 0.25])
	p.survey = Vector2(0.7, 22.0)
	p.age = Vector2(0.08, 0.3)
	p.marks = 2
	p.slide = Vector2(0.0, 1.0)
	p.slide_m = 12.0
	StructureKit.box(p, Vector3(-0.5, 0.4, -6.0), Vector3(0.5, 1.8, 6.0), "")
	StructureKit.box(p, Vector3(-0.7, 0.6, -6.0), Vector3(0.7, 1.6, 6.0), "")
	for v: float in [-3.5, 3.5]:
		StructureKit.box(p, Vector3(-0.95, -0.6, v - 0.4), Vector3(0.95, 0.55, v + 0.4), "concrete")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(0.0, 1.8, 2.0), &"cache", 0.5))
	p.approach = Vector2(5.0, 4.0)
	p.look = _pipe_look
	# Its lengths in a row are a run of old pipe across the dunes.
	StructureKit.far_box(p, Vector3(-0.7, 0.4, -6.0), Vector3(0.7, 1.9, 6.0), coats().panel)
	StructureKit.glint(p, Vector3(0.66, 1.35, -3.0), Vector3(0.94, 0.34, 0.0), 4.0)
	StructureKit.glint(p, Vector3(-0.66, 1.35, 3.5), Vector3(-0.94, 0.34, 0.0), 4.0)
	return p


static func _pipe_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.05)
	var along := Basis(Vector3.RIGHT, PI * 0.5)
	if StructureKit.shows(p, state, 1.8):
		b.drum(0.7, 12.0, Vector3(0.0, 1.1, 0.0), c.panel, along, 18)
		# Bolted flanges at its ends and middle, a band and the contractor's tag.
		for v: float in [-5.95, 0.0, 5.95]:
			b.drum(0.8, 0.14, Vector3(0.0, 1.1, v), c.grey, along, 18)
		b.drum(0.71, 0.4, Vector3(0.0, 1.1, 4.4), c.orange, along, 18)
		b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.71, 1.1, -2.0), 0.9, Basis(Vector3.UP, PI * 0.5))
		b.box(Vector3(0.02, 0.5, 1.0), Vector3(0.7, 1.1, -2.0), c.panel, 0.002)
		# The inspection hatch on its back.
		b.box(Vector3(0.6, 0.06, 0.8), Vector3(0.0, 1.8, 2.0), c.dark, 0.02)


# --- The hab pod: a modular living pod, overbuilt for this moon. ---

static func _hab_pod() -> StructureKit.Piece:
	var p := StructureKit.define(&"hab_pod", Vector2(4.0, 3.0), Vector2(2.9, 2.9), Vector2(1.7, 1.7))
	p.lattice = true
	p.apron = 9.0
	p.drift_reach = 3.5
	p.drift = PackedFloat32Array([0.25, 0.45, 0.7])
	p.survey = Vector2(1.9, 20.0)
	p.age = Vector2(0.08, 0.3)
	p.marks = 2
	p.rooms.append(StructureKit.room(Vector2(-3.0, -2.0), Vector2(3.0, 2.0)))
	p.doors.append([Vector2(-1.5, 3.0), Vector2(0.0, 1.0), 1.4])
	var top := 3.0
	StructureKit.box(p, Vector3(-4.0, -0.3, -3.0), Vector3(4.0, 0.0, 3.0), "dark")
	StructureKit.wall(p, true, 2.0, 3.0, -4.0, 4.0, -0.6, top, [-1.5], "panel")
	StructureKit.wall(p, true, -3.0, -2.0, -4.0, 4.0, -0.6, top, [], "panel")
	StructureKit.wall(p, false, -4.0, -3.0, -2.0, 2.0, -0.6, top, [], "panel")
	StructureKit.wall(p, false, 3.0, 4.0, -2.0, 2.0, -0.6, top, [], "panel")
	StructureKit.box(p, Vector3(-4.0, top, -3.0), Vector3(4.0, top + 0.35, 3.0), "panel")
	# A bunk along the back wall, and the roof's hatch.
	StructureKit.bed(p, Vector3(-3.0, 0.0, -2.0), Vector3(0.5, 0.6, -1.2), "grey")
	StructureKit.box(p, Vector3(1.4, top + 0.35, -1.0), Vector3(2.6, top + 0.55, 0.2), "grey")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-2.0, 0.0, 0.5), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.8, 0.0, 0.8), &"floor"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(-1.5, 0.6, -1.6), &"shelf"))
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(2.2, 0.0, -1.5), &"cache", 0.5))
	p.tour = PackedVector2Array([Vector2(-1.5, 8.0), Vector2(-1.5, 3.5), Vector2(-1.5, 0.5), Vector2(1.5, 0.5),
		Vector2(-1.5, 0.5), Vector2(-1.5, 3.5), Vector2(-1.5, 8.0)])
	p.approach = Vector2(-1.5, 13.0)
	p.look = _hab_look
	# Its windows, and the roof hatch.
	for side in [-1.0, 1.0]:
		StructureKit.glint(p, Vector3(side * 4.01, 1.95, 0.0), Vector3(side, 0.2, 0.0), 3.0)
	StructureKit.glint(p, Vector3(2.0, 3.55, -0.4), Vector3(0.0, 1.0, 0.3), 4.0)
	return p


static func _hab_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	StructureKit.draw_boxes(b, p, state, c, 0.18)
	# Panel seams down its faces, a safety band round it, windows along its sides.
	for u: float in [-3.0, 0.0, 2.0]:
		b.box(Vector3(0.025, 2.6, 0.02), Vector3(u, 1.5, 3.008), c.grey, 0.004)
	for u: float in [-3.0, -1.0, 1.0, 3.0]:
		b.box(Vector3(0.025, 2.6, 0.02), Vector3(u, 1.5, -3.008), c.grey, 0.004)
	for side in [-1.0, 1.0]:
		if StructureKit.shows(p, state, 1.25):
			b.box(Vector3(8.02, 0.22, 0.02), Vector3(0.0, 1.12, side * 3.01), c.orange, 0.004)
			b.box(Vector3(0.02, 0.22, 6.02), Vector3(side * 4.01, 1.12, 0.0), c.orange, 0.004)
		if StructureKit.shows(p, state, 2.2):
			b.box(Vector3(0.02, 0.45, 3.6), Vector3(side * 4.012, 1.95, 0.0), c.glass, 0.004)
	# The door's frame, and the early marks that don't match beside it: the
	# contractor's tag, a member state's seal in another hand's paint.
	if StructureKit.shows(p, state, 2.4):
		for u: float in [-2.28, -0.72]:
			b.box(Vector3(0.12, 2.4, 0.06), Vector3(u, 1.2, 3.03), c.orange, 0.01)
		b.box(Vector3(1.68, 0.12, 0.06), Vector3(-1.5, 2.36, 3.03), c.orange, 0.01)
		b.stamp(Paint.Mark.CONTRACTOR, Vector3(1.0, 1.75, 3.012), 0.7)
		b.box(Vector3(0.8, 0.4, 0.02), Vector3(1.0, 1.75, 3.0), c.panel, 0.002)
		b.stamp(Paint.Mark.MEMBER_STATE, Vector3(2.2, 1.75, 3.012), 0.6)
		b.box(Vector3(0.6, 0.3, 0.02), Vector3(2.2, 1.75, 3.0), c.panel, 0.002)
	# An antenna stub on the roof by its hatch.
	b.drum(0.04, 1.2, Vector3(-3.2, 3.95, -2.2), c.steel, Basis.IDENTITY, 6)
	b.drum(0.1, 0.12, Vector3(-3.2, 4.55, -2.2), c.orange, Basis.IDENTITY, 8)


# --- The relay mast: a comms tower, the colony's line of sight. ---

static func _relay_mast() -> StructureKit.Piece:
	var p := StructureKit.define(&"relay_mast", Vector2(1.3, 1.3), Vector2(7.0, 7.0), Vector2(2.2, 2.2))
	p.apron = 4.0
	p.drift_reach = 1.5
	p.drift = PackedFloat32Array([0.25, 0.3, 0.3])
	p.survey = Vector2(0.9, 24.0)
	p.age = Vector2(0.08, 0.3)
	p.marks = 2
	StructureKit.box(p, Vector3(-1.3, -0.9, -1.3), Vector3(1.3, 0.35, 1.3), "concrete")
	StructureKit.box(p, Vector3(-0.35, 0.35, -0.35), Vector3(0.35, 14.0, 0.35), "")
	StructureKit.box(p, Vector3(0.55, 0.35, -0.5), Vector3(1.25, 1.95, 0.5), "panel")
	p.sockets.append(StructureKit.SiteSocket.new(Vector3(1.25, 1.0, 0.0), &"shelf"))
	p.approach = Vector2(5.0, 8.0)
	p.look = _mast_look
	# The colony's line of sight, the tallest thing on the dunes: its footing,
	# its lattice, the cabinet at its foot, the dish and the lamp on top.
	var c := coats()
	StructureKit.far_box(p, Vector3(-1.3, -0.9, -1.3), Vector3(1.3, 0.35, 1.3), c.concrete)
	StructureKit.far_box(p, Vector3(-0.35, 0.35, -0.35), Vector3(0.35, 14.0, 0.35), c.dark, LATTICE)
	StructureKit.far_box(p, Vector3(0.55, 0.35, -0.5), Vector3(1.25, 1.95, 0.5), c.panel)
	StructureKit.far_box(p, Vector3(-0.7, 12.25, 0.45), Vector3(0.7, 13.55, 0.65), c.panel)
	StructureKit.far_box(p, Vector3(-0.14, 14.0, -0.14), Vector3(0.14, 14.3, 0.14), c.orange)
	# Its dish, and the lamp's glass on its top.
	StructureKit.glint(p, Vector3(0.0, 12.9, 0.62), Vector3(0.0, 0.25, 0.97), 5.0)
	StructureKit.glint(p, Vector3(0.1, 14.15, 0.1), Vector3(0.7, 0.3, 0.6), 6.0)
	StructureKit.glint(p, Vector3(-0.1, 14.15, -0.1), Vector3(-0.7, 0.3, -0.6), 6.0)
	return p


static func _mast_look(b: Paint.Pieces, p: StructureKit.Piece, state: int) -> void:
	var c := coats()
	b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.0, 0.0, 1.3), 1.0)
	StructureKit.draw_boxes(b, p, state, c, 0.06)
	lattice(b, Vector3(0.0, 0.35, 0.0), 0.35, 13.65, 1.6, c.grey, p, state)
	# Its cabinet's orange door, its dish and the light on its top.
	if StructureKit.shows(p, state, 1.85):
		b.box(Vector3(0.03, 1.3, 0.8), Vector3(1.26, 1.15, 0.0), c.orange, 0.01)
		b.box(Vector3(0.05, 0.3, 0.05), Vector3(1.29, 1.15, 0.3), c.dark, 0.01)
	b.drum(0.7, 0.12, Vector3(0.0, 12.9, 0.55), c.panel, Basis(Vector3.RIGHT, PI * 0.42), 16)
	b.drum(0.14, 0.3, Vector3(0.0, 14.15, 0.0), c.orange, Basis.IDENTITY, 10)


## A square lattice tower `half` m across its corner posts, from `foot` up
## `tall` m, braced every `every` m: four posts and a diagonal on each face.
static func lattice(b: Paint.Pieces, foot: Vector3, half: float, tall: float, every: float, look: Paint.Coat,
		p: StructureKit.Piece, state: int) -> void:
	var from := maxf(foot.y, p.sink[state] - 0.2) if p.lean == 0.0 else foot.y
	if from >= foot.y + tall:
		return
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			b.box(Vector3(0.09, foot.y + tall - from, 0.09), Vector3(sx * half, (from + foot.y + tall) * 0.5, sz * half),
				look, 0.01)
	var y := foot.y
	var k := 0
	while y + every <= foot.y + tall + 0.01:
		if y + every > from:
			var flip := 1.0 if k % 2 == 0 else -1.0
			for face in 4:
				var turn := Basis(Vector3.UP, face * PI * 0.5)
				StructureKit.rod(b, turn * Vector3(-half * flip, y, half), turn * Vector3(half * flip, y + every, half), 0.05, look)
				StructureKit.rod(b, turn * Vector3(-half, y + every, half), turn * Vector3(half, y + every, half), 0.05, look)
		y += every
		k += 1
