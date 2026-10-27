class_name BoardLooks
extends RefCounted
## The boards and the rig under a camp (Dress), each make in its era's shape
## (art direction, "Shape by era"). The company's issue is a crisp moulded
## hull: a rubber-bumpered rail round a panelled deck, ribbed grip, a cradle
## for its battery and two nose lamps; a colonial find is the same hull in
## the colony's off-white, grey and safety orange. The skimmer racer is light
## and hasty: a crew-red sheet on a welded frame, taped round its rails, a
## kicked tail and one taped-on lamp. The patrol board is a First Kingdoms
## heirloom the Knights Requisitioner keep: the colonial hull intact under
## brass and a house's enamel band, plated, its deck the order's grey. The
## temple board is a craft object over an old hover core: saltbush planks in
## fern cord, its battery seated on a round glazed cap. A deck is seen from
## above while ridden, so its top carries the detail; emitters and lamps glow
## while it runs. Nose -Z, tail +Z; a part grows along +Z.

const IDS: Array[StringName] = [&"board", &"racer_board", &"patrol_board", &"temple_board", &"hover_tray", &"skates", &"board_plate", &"keel", &"sail"]

## The eras whose hands give the company's board a shape of its own: a
## colonial one wears the colony's paint, the others what they did to it.
const SHAPES := {Eras.COLONIAL: &"colonial", Eras.SKIMMER: &"skimmer", Eras.FIRST: &"first", Eras.SECOND: &"second"}
const ALONG := Basis(Vector3.RIGHT, PI / 2.0)
const ACROSS := Basis(Vector3.BACK, PI / 2.0)
## Flat on a deck: a face's +Z up, its +Y toward the nose.
const FLAT := Basis(Vector3.RIGHT, -PI / 2.0)
## A stencil read from the tail, faced up.
const TAIL := Basis(Vector3.LEFT, Vector3.BACK, Vector3.UP)
## The moulded hull, m over a board's middle: its rail's top, its deck
## panels', the seam between nose and tail panels, and its nose and tail.
const RAIL_TOP := 0.026
const DECK_TOP := 0.031
const SEAM_Z := 0.43
const ENDS := 0.646

static var _eras := {}


## A thing's look in the shape its last hands' era gave it, for its lineage's
## marks to go on (Dress); null where it keeps its own.
static func lineage(id: StringName, line: Array) -> ArrayMesh:
	var era := Eras.era_of(line)
	return look(id, era) if id == &"board" and SHAPES.has(era) else null


## The company's board in an era's shape, made once.
static func look(id: StringName, era: StringName) -> ArrayMesh:
	var key := [id, era]
	if not _eras.has(key):
		var size: Vector3 = Catalog.DEVICES[id].size
		var b := Paint.Pieces.new(-size.y * 0.5)
		frame(b, id, size, era)
		_eras[key] = b.commit()
	return _eras[key]


## Draws a board into its pieces; false for an id that isn't one.
static func frame(b: Paint.Pieces, id: StringName, size: Vector3, era := Eras.NEW, _extra := 0.0) -> bool:
	match id:
		&"board":
			_issue(b, size, SHAPES.get(era, &""))
		&"racer_board":
			_racer(b, size)
		&"patrol_board":
			_patrol(b, size)
		&"temple_board":
			_temple(b, size)
		_:
			return false
	return true


## Draws a rig part into its pieces; false for one that isn't the rig's.
static func part(b: Paint.Pieces, id: StringName, size: Vector3, _era := Eras.NEW, _count := -1) -> bool:
	match id:
		&"hover_tray":
			_tray(b, size)
		&"skates":
			_skates(b, size)
		&"board_plate":
			_plate(b, size)
		&"keel":
			_keel(b, size)
		&"sail":
			_sail(b, size)
		_:
			return false
	return true


## The field's glow, bright enough to bloom: a board reads by it at night
## and in a storm.
static func _glow(strength := 3.0) -> Paint.Coat:
	return Paint.coat(Paint.HOVER, 0.0, 0.0, 0.3, 0.3, strength)


static func _lamp() -> Paint.Coat:
	return Paint.coat(Paint.LAMP, 0.0, 0.0, 0.2, 0.2, 4.0)


static func _cord() -> Paint.Coat:
	return Paint.coat(Paint.CORD, 0.1, 0.0, 0.9, 0.5)


static func _weld() -> Paint.Coat:
	return Paint.coat(Paint.RUST, 0.3, 0.6, 0.55)


# --- Kit pieces ----------------------------------------------------------------


## A plan: a rectangle `w` across from z0 to z1, its corners at z0 `r0` round
## and at z1 `r1`.
static func _plan(w: float, z0: float, z1: float, r0: float, r1: float, steps := 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	var hx := w * 0.5
	for corner: Array in [[hx - r1, z1 - r1, r1, 0.0], [-hx + r1, z1 - r1, r1, PI * 0.5], [-hx + r0, z0 + r0, r0, PI],
			[hx - r0, z0 + r0, r0, PI * 1.5]]:
		var r: float = corner[2]
		for i in (steps + 1 if r > 0.0 else 1):
			var a: float = corner[3] + PI * 0.5 * i / steps
			out.append(Vector2(corner[0] + cos(a) * r, corner[1] + sin(a) * r))
	return out


## A slab of a convex `outline` (x, z) from y0 to y1, its top and bottom edges
## bevelled by `cut`: a moulded plate. One piece, worn as a box of its extents.
static func _slab(b: Paint.Pieces, outline: PackedVector2Array, y0: float, y1: float, cut: float, look: Paint.Coat,
		at := Vector3.ZERO, turn := Basis.IDENTITY) -> void:
	var n := outline.size()
	var lo := outline[0]
	var hi := outline[0]
	var area := 0.0
	for i in n:
		var p := outline[i]
		var q := outline[(i + 1) % n]
		lo = lo.min(p)
		hi = hi.max(p)
		area += p.x * q.y - q.x * p.y
	var mid := (lo + hi) * 0.5
	var half := Vector3((hi.x - lo.x) * 0.5, (y1 - y0) * 0.5, (hi.y - lo.y) * 0.5)
	var c := minf(cut, half.y * 0.9)
	var way := 1.0 if area > 0.0 else -1.0
	var edges: Array[Vector2] = []
	for i in n:
		var d := (outline[(i + 1) % n] - outline[i]).normalized()
		edges.append(Vector2(d.y, -d.x) * way)
	# Its outline at four heights, the bevels' inset along each corner's miter.
	var heights: Array[float] = [-half.y, -half.y + c, half.y - c, half.y]
	var rings: Array[PackedVector3Array] = []
	for level in 4:
		var row := PackedVector3Array()
		for i in n:
			var p := outline[i] - mid - (_miter(edges, i) * c if level == 0 or level == 3 else Vector2.ZERO)
			row.append(Vector3(p.x, heights[level], p.y))
		rings.append(row)
	var verts: Array[Vector3] = []
	var norms: Array[Vector3] = []
	for i in n:
		var j := (i + 1) % n
		var e := edges[i]
		# Smooth round a gentle corner, sharp round a hard one.
		var ni := _miter(edges, i).normalized() if edges[(i - 1 + n) % n].dot(e) > 0.8 else e
		var nj := _miter(edges, j).normalized() if edges[j].dot(e) > 0.8 else e
		for band in 3:
			var up := Vector3.UP * (band - 1)
			var a := (Vector3(ni.x, 0.0, ni.y) + up).normalized()
			var z := (Vector3(nj.x, 0.0, nj.y) + up).normalized()
			_tri(verts, norms, [rings[band][i], rings[band][j], rings[band + 1][j]], [a, z, z])
			_tri(verts, norms, [rings[band][i], rings[band + 1][j], rings[band + 1][i]], [a, z, a])
		for level in [0, 3]:
			var face := Vector3.UP if level == 3 else Vector3.DOWN
			_tri(verts, norms, [Vector3(0.0, heights[level], 0.0), rings[level][i], rings[level][j]], [face, face, face])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(verts)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(norms)
	b._add(arrays, Transform3D(turn, at + turn * Vector3(mid.x, (y0 + y1) * 0.5, mid.y)), look, half, 1.0)


## A corner's way out, long enough that both its edges move out by one.
static func _miter(edges: Array[Vector2], i: int) -> Vector2:
	var a := edges[(i - 1 + edges.size()) % edges.size()]
	var e := edges[i]
	return (a + e) / maxf(1.0 + a.dot(e), 0.5)


## A triangle wound to face where its normals point.
static func _tri(verts: Array[Vector3], norms: Array[Vector3], p: Array, ns: Array) -> void:
	var face: Vector3 = ns[0] + ns[1] + ns[2]
	var order := [0, 1, 2] if ((p[1] - p[0]) as Vector3).cross(p[2] - p[0]).dot(face) <= 0.0 else [0, 2, 1]
	for k: int in order:
		verts.append(p[k])
		norms.append(ns[k])


## Safety stripes: a band in `color` with black slashes a hair proud of both
## its faces, `turn`'s +Z out of the band.
static func _hazard(b: Paint.Pieces, size: Vector3, at: Vector3, turn: Basis, color := Paint.YELLOW) -> void:
	b.box(size, at, Paint.coat(color, 0.75), 0.002, turn)
	var count := int(size.x / (size.y * 1.6))
	for i in count:
		var x := -size.x * 0.5 + (i + 0.5) * size.x / count
		b.box(Vector3(size.y * 0.5, size.y * 0.98, size.z + 0.002), at + turn * Vector3(x, 0.0, 0.0), Paint.coat(Paint.BLACK, 0.6),
			0.0, turn * Basis(Vector3.BACK, 0.7))


## A hover emitter under a deck: its housing, and its field's glow standing
## a little below it.
static func _emitter(b: Paint.Pieces, at: Vector3, radius: float, housing: Paint.Coat, strength := 3.0) -> void:
	b.drum(radius + 0.016, 0.006, at + Vector3(0.0, 0.003, 0.0), housing, Basis.IDENTITY, 14)
	b.drum(radius, 0.0058, at + Vector3(0.0, -0.0001, 0.0), _glow(strength), Basis.IDENTITY, 14)


## A lamp in a nose, its lens's middle at `at`, looking -Z: a bezel and a
## domed lens, or the bezel alone where the lens is lost.
static func _nose_lamp(b: Paint.Pieces, at: Vector3, radius: float, bezel: Paint.Coat, lit := true) -> void:
	b.drum(radius + 0.0025, 0.008, at + Vector3(0.0, 0.0, 0.004), bezel, ALONG, 10)
	if lit:
		b.ball(radius, at, _lamp(), Vector3(1.0, 1.0, 0.35))


## Cord or tape wound round a moulded rail, over its top edge and under its bumper.
static func _wrap(b: Paint.Pieces, side: float, z: float, long: float, look: Paint.Coat, skew := 0.0) -> void:
	b.box(Vector3(0.0185, 0.0365, long), Vector3(side * 0.17025, 0.00925, z), look, 0.003, Basis(Vector3.UP, skew))


## A scrap plate welded over a face, a bead at each corner.
static func _patch(b: Paint.Pieces, at: Vector3, size: Vector2, turn: float, look: Paint.Coat = null) -> void:
	var lie := Basis(Vector3.UP, turn)
	b.box(Vector3(size.x, 0.003, size.y), at, look if look != null else Paint.scrap(), 0.001, lie)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			b.drum(0.005, 0.005, at + lie * Vector3(x * size.x * 0.5, 0.0005, z * size.y * 0.5), _weld(), Basis.IDENTITY, 6)


## A salvaged lamp taped onto a nose, its middle at `at`, looking -Z.
static func _taped_lamp(b: Paint.Pieces, at: Vector3) -> void:
	b.drum(0.0105, 0.03, at, Paint.black(), ALONG, 10)
	b.ball(0.0085, at + Vector3(0.0, 0.0, -0.0148), _lamp(), Vector3(1.0, 1.0, 0.35))
	b.drum(0.0122, 0.012, at + Vector3(0.0, 0.0, 0.004), Paint.tape(), ALONG, 10)


# --- The company's moulded hull, and what each era's hands did to it ----------


## The company's board: the moulded hull in the issue's paint or the colony's,
## and whatever its last hands' era did to it.
static func _issue(b: Paint.Pieces, size: Vector3, shape: StringName) -> void:
	var issue := shape == &""
	var crew := shape == &"skimmer"
	var orange := Paint.coat(ColonialKit.ORANGE, 0.7, 0.0, 0.5)
	var deck := Paint.coat(Paint.TEAL) if issue else (Paint.coat(SkimmerKit.PLATE_RED, 0.9, 0.0, 0.55) if crew
		else Paint.coat(ColonialKit.PANEL, 0.5, 0.1, 0.5))
	var rail := Paint.coat(Paint.GUNMETAL) if issue else Paint.coat(ColonialKit.GREY, 0.6, 0.4, 0.45)
	var under := Paint.coat(Paint.GUNMETAL, 0.8, 0.5, 0.5) if issue else Paint.coat(ColonialKit.DARK, 0.4, 0.3, 0.5)
	_hull(b, size, under, rail, Paint.brass() if shape == &"first" else Paint.rubber())
	# Tilg & Standard's batch stencil on its tail, or TILG's consignment.
	b.stamp(Paint.Mark.CONSIGNMENT, Vector3(0.0, size.y * 0.5, 0.53), 0.24, TAIL, Paint.Ink.PALE)
	_panels(b, size, deck, shape == &"second")
	_grip(b, &"ribs", Vector2(-0.33, -0.03))
	_grip(b, &"ribs", Vector2(0.05, 0.38))
	_cradle(b, Paint.coat(Paint.YELLOW, 0.75) if issue else orange)
	if issue:
		_hazard(b, Vector3(0.22, 0.02, 0.004), Vector3(0.0, DECK_TOP + 0.0015, -0.603), FLAT)
	elif not crew:
		b.box(Vector3(0.22, 0.003, 0.02), Vector3(0.0, DECK_TOP + 0.001, -0.603), orange, 0.001)
	for x in [-0.06, 0.06]:
		_nose_lamp(b, Vector3(x, 0.0095, -0.6478), 0.0055, Paint.rubber(), x < 0.0 or not (crew or shape == &"second"))
	for z in [-0.36, 0.36]:
		_emitter(b, Vector3(0.0, -0.0369, z), 0.062, Paint.black())
	_port(b, size, Paint.rubber())
	match shape:
		&"first":
			_heirloom(b)
		&"skimmer":
			_crewed(b)
		&"second":
			_mended(b)


## The moulded hull: a narrower underbody, a rail round it from `nose` to the
## tail with its bumper standing proud.
static func _hull(b: Paint.Pieces, size: Vector3, under: Paint.Coat, rail: Paint.Coat, bumper: Paint.Coat, nose := -ENDS) -> void:
	_slab(b, _plan(0.3, -0.55, 0.55, 0.08, 0.08, 3), -0.034, -0.004, 0.01, under)
	_slab(b, _plan(size.x - 0.008, nose, ENDS, 0.1, 0.1), -0.01, RAIL_TOP, 0.009, rail)
	_slab(b, _plan(size.x - 0.0044, nose - 0.0016, ENDS + 0.0016, 0.1018, 0.1018), -0.007, 0.001, 0.0015, bumper)


## The deck's two panels from `nose` and the seam between: the tail's first,
## to take its stencil; where the second age lost it, saltbush planks.
static func _panels(b: Paint.Pieces, size: Vector3, deck: Paint.Coat, planked: bool, nose := -0.618) -> void:
	var w := size.x - 0.034
	if not planked:
		_slab(b, _plan(w, SEAM_Z + 0.002, 0.618, 0.0, 0.085), 0.018, DECK_TOP, 0.004, deck)
	_slab(b, _plan(w, nose, SEAM_Z - 0.002, 0.085, 0.0), 0.018, DECK_TOP, 0.004, deck)
	b.box(Vector3(w - 0.004, 0.004, 0.008), Vector3(0.0, DECK_TOP + 0.0005, SEAM_Z), Paint.black(), 0.001)


## A grip pad over a span of the deck: ribbed tape, or tread plate whose
## bumps the boots wear through to the steel.
static func _grip(b: Paint.Pieces, kind: StringName, span: Vector2, w := 0.27) -> void:
	var long := span.y - span.x
	if kind == &"ribs":
		_slab(b, _plan(w, span.x, span.y, 0.025, 0.025), DECK_TOP - 0.002, DECK_TOP + 0.0025, 0.0012,
			Paint.coat(Paint.GRIP, 0.15, 0.0, 0.95, 0.5))
		var count := int(long / 0.024)
		for i in count:
			b.box(Vector3(w - 0.03, 0.003, 0.005), Vector3(0.0, DECK_TOP + 0.0035, span.x + (i + 0.5) * long / count),
				Paint.coat(Paint.GRIP, 0.3, 0.0, 0.9, 0.5), 0.0)
		return
	_slab(b, _plan(w, span.x, span.y, 0.012, 0.012, 2), DECK_TOP - 0.002, DECK_TOP + 0.0025, 0.0012,
		Paint.coat(Paint.ORDER_GREY, 0.7, 0.4, 0.55))
	var bump := Paint.coat(Paint.ORDER_GREY, 1.0, 0.6, 0.45)
	var rows := int(long / 0.048)
	for row in rows:
		for col in 6:
			var lean := 0.785 if (row + col) % 2 == 0 else -0.785
			b.box(Vector3(0.022, 0.0026, 0.005), Vector3((col - 2.5) * w / 6.6, DECK_TOP + 0.0035, span.x + (row + 0.5) * long / rows),
				bump, 0.0, Basis(Vector3.UP, lean))
	for x in [-1.0, 1.0]:
		for z in [span.x + 0.014, span.y - 0.014]:
			b.drum(0.006, 0.004, Vector3(x * (w * 0.5 - 0.014), DECK_TOP + 0.0035, z), Paint.brass(), Basis.IDENTITY, 6)


## The battery's moulded cradle at the nose under its socket, a release lever
## each side.
static func _cradle(b: Paint.Pieces, lever: Paint.Coat) -> void:
	_slab(b, _plan(0.25, -0.585, -0.415, 0.02, 0.02), DECK_TOP - 0.004, 0.0392, 0.002, Paint.matte_black())
	for x in [-1.0, 1.0]:
		b.box(Vector3(0.014, 0.009, 0.07), Vector3(x * 0.138, 0.0352, -0.5), lever, 0.002)


## The tail's block round its charging port.
static func _port(b: Paint.Pieces, size: Vector3, look: Paint.Coat, wide := 0.17) -> void:
	b.box(Vector3(wide, 0.03, 0.012), Vector3(0.0, 0.004, size.z * 0.5 - 0.0065), look, 0.004)


## First Kingdoms: the colonial hull kept whole and dressed: a brass rub strip
## for its bumper, flared brass bosses at its deck's corners and its nose, and
## a brass filigree vent over the hover core between the grip pads.
static func _heirloom(b: Paint.Pieces) -> void:
	_bosses(b, [-0.575, 0.575])
	_vent(b, 0.01, 0.2)
	b.drum(0.012, 0.008, Vector3(0.0, 0.0095, -0.6455), Paint.brass(), ALONG, 12, 0.018)


static func _bosses(b: Paint.Pieces, zs: Array) -> void:
	for x in [-1.0, 1.0]:
		for z: float in zs:
			b.drum(0.02, 0.013, Vector3(x * 0.146, 0.0305, z), Paint.brass(), Basis.IDENTITY, 10, 0.014)


## A dark vent framed in brass under a diamond lattice, `wide` across at z.
static func _vent(b: Paint.Pieces, z: float, wide: float) -> void:
	var brass := Paint.brass()
	b.box(Vector3(wide, 0.003, 0.046), Vector3(0.0, DECK_TOP + 0.0005, z), Paint.black(), 0.0)
	for s in [-1.0, 1.0]:
		b.box(Vector3(wide + 0.008, 0.005, 0.006), Vector3(0.0, DECK_TOP + 0.0025, z + s * 0.025), brass, 0.001)
		b.box(Vector3(0.006, 0.004, 0.044), Vector3(s * (wide * 0.5 + 0.001), DECK_TOP + 0.002, z), brass, 0.001)
		b.bars(FLAT, Vector3(0.0, DECK_TOP + (0.0017 if s < 0.0 else 0.003), z), Vector2(wide * 0.5 - 0.004, 0.019),
			Vector2(1.0, s).normalized(), 0.016, brass)


## The skimmer era's: repainted crew red with a pale stripe, tape round its
## rails, a scrap plate welded over a tail corner, one lamp lost and another
## taped on.
static func _crewed(b: Paint.Pieces) -> void:
	b.box(Vector3(0.03, 0.003, 0.9), Vector3(0.0, DECK_TOP + 0.0005, 0.0), Paint.coat(Paint.BONE, 0.7), 0.0)
	for z in [-0.28, 0.02, 0.3]:
		for side in [-1.0, 1.0]:
			_wrap(b, side, z + side * 0.03, 0.04, Paint.tape(), 0.03 * side)
	_patch(b, Vector3(0.13, DECK_TOP + 0.0015, 0.57), Vector2(0.06, 0.08), 0.3)
	_taped_lamp(b, Vector3(0.06, 0.0265, -0.628))


## The second age's: the tail panel lost and planked in saltbush lashed with
## cord, the right lamp's hole capped in ceramic, limewash where the deck
## chipped between the pads, cord bound round the left rail.
static func _mended(b: Paint.Pieces) -> void:
	var wood := Paint.coat(Paint.SALTWOOD, 0.2, 0.0, 0.85, 0.7)
	for plank: Array in [[-0.1, 0.098, 0.0, 0.03], [0.0, 0.1, 0.004, -0.02], [0.1, 0.094, -0.002, 0.025]]:
		b.box(Vector3(plank[1], 0.012, 0.19), Vector3(plank[0], 0.026 + plank[2] * 0.25, 0.534 + plank[2]), wood, 0.004,
			Basis(Vector3.UP, plank[3]))
	for z in [0.47, 0.6]:
		b.box(Vector3(0.3, 0.02, 0.012), Vector3(0.0, 0.0255, z), _cord(), 0.003)
	b.ball(0.022, Vector3(0.06, 0.0095, -0.6398), Paint.coat(Paint.CERAMIC, 0.45, 0.0, 0.3), Vector3(1.0, 0.8, 0.45))
	b.box(Vector3(0.17, 0.003, 0.05), Vector3(-0.01, DECK_TOP + 0.0005, 0.01), Paint.coat(Paint.LIMEWASH, 0.4, 0.0, 0.85, 0.8),
		0.001, Basis(Vector3.UP, 0.08))
	for z in [-0.2, 0.22]:
		for i in 3:
			_wrap(b, -1.0, z + (i - 1) * 0.0075, 0.006, _cord())


# --- The makes -----------------------------------------------------------------


## The skimmer racer: a crew-red sheet on a welded frame of two stringers and
## cross members, narrow with a pointed nose, its tail kicked up on a sheet of
## its own, tape round its rails, hand-cut grip, a plate welded where its
## battery sits, three small pads under it and a lamp taped on its nose.
static func _racer(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var red := Paint.coat(SkimmerKit.PLATE_RED, 0.9, 0.0, 0.55)
	var metal := Paint.coat(SkimmerKit.GUNMETAL, 0.8, 0.5, 0.5)
	var weld := _weld()
	var top := 0.0305
	_slab(b, PackedVector2Array([Vector2(0.0, -0.646), Vector2(0.05, -0.622), Vector2(0.125, -0.43), Vector2(0.125, 0.442),
		Vector2(-0.125, 0.442), Vector2(-0.125, -0.43), Vector2(-0.05, -0.622)]), 0.021, top, 0.003, red)
	# The kicked tail, welded on a hair under the deck so the joint never fights.
	var kick := PackedVector2Array([Vector2(0.125, 0.432), Vector2(0.125, 0.6), Vector2(0.104, 0.636), Vector2(0.062, 0.6455),
		Vector2(-0.062, 0.6455), Vector2(-0.104, 0.636), Vector2(-0.125, 0.6), Vector2(-0.125, 0.432)])
	var lift := Basis(Vector3.RIGHT, -0.0477)
	var middle := Vector3(0.0, 0.0, 0.53875)
	b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(0.0, h.y, 0.545), 0.2, TAIL, Paint.Ink.PALE)
	_slab(b, kick, -0.0047, 0.0047, 0.003, red, Vector3(0.0, 0.0299, 0.0) + middle - lift * middle, lift)
	b.drum(0.0032, 0.246, Vector3(0.0, top - 0.0004, 0.441), weld, ACROSS, 6)
	# The frame under the sheet: two stringers and cross members, beaded at
	# the joins, a strut back to the port's housing.
	for x in [-0.07, 0.07]:
		b.box(Vector3(0.022, 0.027, 0.98), Vector3(x, 0.0085, -0.05), metal, 0.004)
	for z in [-0.42, -0.1, 0.2, 0.4]:
		b.box(Vector3(0.118, 0.016, 0.02), Vector3(0.0, 0.012, z), metal, 0.003)
		for x in [-0.059, 0.059]:
			b.drum(0.0055, 0.018, Vector3(x, 0.011, z + 0.011), weld, Basis.IDENTITY, 6)
	b.box(Vector3(0.02, 0.016, 0.16), Vector3(0.0, 0.01, 0.51), metal, 0.003)
	b.box(Vector3(0.11, 0.034, 0.06), Vector3(0.0, 0.009, 0.618), metal, 0.005)
	# Three small pads, each a pod welded under the stringers.
	for z in [-0.4, 0.0, 0.38]:
		b.drum(0.058, 0.029, Vector3(0.0, -0.0185, z), metal, Basis.IDENTITY, 14)
		b.drum(0.046, 0.007, Vector3(0.0, -0.0363, z), _glow(), Basis.IDENTITY, 14)
		for x in [-0.05, 0.05]:
			b.drum(0.005, 0.01, Vector3(x, -0.006, z), weld, Basis.IDENTITY, 6)
	# Tape round the rails, wound in a hurry.
	for i in 3:
		var z: float = [-0.3, -0.04, 0.22][i]
		for x in [-1.0, 1.0]:
			b.box(Vector3(0.018, 0.0125, 0.034), Vector3(x * 0.122, 0.0258, z + x * 0.02), Paint.tape(), 0.003,
				Basis(Vector3.UP, 0.06 * x * (i - 1)))
	# The crew's pale stripe, hand-cut grip, an olive splice plate welded
	# across where the sheet cracked, a scrap plate over the tail.
	b.box(Vector3(0.032, 0.003, 0.98), Vector3(0.0, top + 0.0002, -0.08), Paint.coat(Paint.BONE, 0.7), 0.0)
	var grip := Paint.coat(Paint.GRIP, 0.25, 0.0, 0.95, 0.5)
	b.box(Vector3(0.15, 0.004, 0.28), Vector3(0.0, top + 0.001, -0.2), grip, 0.001, Basis(Vector3.UP, 0.03))
	b.box(Vector3(0.16, 0.004, 0.32), Vector3(0.0, top + 0.001, 0.185), grip, 0.001, Basis(Vector3.UP, -0.035))
	_patch(b, Vector3(0.0, top + 0.0025, -0.024), Vector2(0.236, 0.042), 0.04, Paint.coat(SkimmerKit.OLIVE, 1.0, 0.4, 0.6))
	_patch(b, Vector3(0.095, top + 0.0025, 0.39), Vector2(0.05, 0.08), -0.25)
	# The battery's plate, beaded at its corners; rivets down the sheet's edges.
	b.box(Vector3(0.17, 0.0095, 0.13), Vector3(0.0, 0.035, -0.5), Paint.scrap(), 0.002)
	for x in [-0.082, 0.082]:
		for z in [-0.565, -0.435]:
			b.drum(0.005, 0.008, Vector3(x, 0.034, z), weld, Basis.IDENTITY, 6)
	for z in [-0.36, -0.12, 0.08, 0.3]:
		for x in [-0.108, 0.108]:
			b.drum(0.004, 0.003, Vector3(x, top + 0.0005, z), Paint.coat(Paint.STEEL, 0.4, 0.8), Basis.IDENTITY, 6)
	_taped_lamp(b, Vector3(0.0, 0.026, -h.z + 0.0205))


## The patrol board: the colonial hull kept whole as an heirloom, its bumper a
## house's enamel band, flared brass at its tail's corners and a filigree
## vent; the Knights' grey deck in tread plate, their daubed sign and the
## stencil on its tail, every crate accounted for; olive armour riveted down
## its rails, a steel bumper lashed across its nose with two dim lamps and a
## brass boss in it, and four dim pads ringed in brass under it.
static func _patrol(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var steel := Paint.coat(Paint.STEEL, 0.6, 0.8, 0.45)
	var enamel := Paint.coat(FirstKingdomsKit.HOUSES[0], 0.5, 0.1, 0.25, 0.6)
	_hull(b, size, Paint.coat(Paint.GUNMETAL, 0.8, 0.5, 0.5), Paint.coat(ColonialKit.GREY, 0.6, 0.4, 0.45), enamel, -0.62)
	b.stamp(Paint.Mark.CONSIGNMENT, Vector3(0.0, h.y, 0.55), 0.22, TAIL, Paint.Ink.PALE)
	_panels(b, size, Paint.coat(Paint.ORDER_GREY, 0.6, 0.0, 0.85), false, -0.592)
	_grip(b, &"tread", Vector2(-0.34, -0.03), 0.28)
	_grip(b, &"tread", Vector2(0.05, 0.33), 0.28)
	_cradle(b, Paint.brass())
	_bosses(b, [0.575])
	_vent(b, 0.01, 0.2)
	# The order's sign, daubed by hand across the tail.
	var daub := Paint.coat(SecondAgeKit.DAUB, 0.5, 0.0, 0.9, 0.8)
	b.box(Vector3(0.03, 0.003, 0.12), Vector3(0.0, DECK_TOP + 0.0006, 0.425), daub, 0.0, Basis(Vector3.UP, 0.02))
	b.box(Vector3(0.16, 0.003, 0.026), Vector3(0.0, DECK_TOP + 0.0022, 0.4), daub, 0.0, Basis(Vector3.UP, -0.03))
	# Olive armour down each rail, three plates a side, riveted in brass.
	var plate := Paint.coat(SkimmerKit.OLIVE, 1.0, 0.4, 0.6)
	for x in [-1.0, 1.0]:
		for span: Vector2 in [Vector2(-0.4, -0.13), Vector2(-0.09, 0.18), Vector2(0.22, 0.48)]:
			b.box(Vector3(0.008, 0.015, span.y - span.x), Vector3(x * 0.1745, 0.0185, (span.x + span.y) * 0.5), plate, 0.003)
			for end in [span.x + 0.02, span.y - 0.02]:
				b.drum(0.0045, 0.0023, Vector3(x * 0.17865, 0.0185, end), Paint.brass(), ACROSS, 6)
	# The steel bumper across the nose on two brackets, lashed to them in cord.
	b.box(Vector3(0.34, 0.022, 0.024), Vector3(0.0, 0.004, -0.6335), steel, 0.005)
	for x in [-0.12, 0.12]:
		b.box(Vector3(0.026, 0.026, 0.09), Vector3(x, 0.0, -0.59), steel, 0.005)
		b.box(Vector3(0.036, 0.034, 0.016), Vector3(x, 0.001, -0.615), _cord(), 0.004)
	for x in [-0.07, 0.07]:
		_nose_lamp(b, Vector3(x, 0.006, -0.6478), 0.006, Paint.rubber())
	b.drum(0.016, 0.008, Vector3(0.0, 0.006, -0.6455), Paint.brass(), ALONG, 12, 0.022)
	for z in [-0.42, -0.14, 0.14, 0.42]:
		_emitter(b, Vector3(0.0, -0.0369, z), 0.05, Paint.brass(), 1.6)
	_port(b, size, steel)


## The temple board: an old hover core under saltbush planks on battens,
## lashed in fern cord at four stations, a saltbush rail lashed along its
## left; its battery seated on a round ceramic cap in Mother Cistern's blue
## glaze on a bare collar, the sign of Tu on limewash at its tail, a water
## vial bound at its right, a tassel at its tail and ceramic rings round its
## two emitters.
static func _temple(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var wood := Paint.coat(Paint.SALTWOOD, 0.2, 0.0, 0.8, 0.8)
	var cord := Paint.coat(Paint.CORD, 0.1, 0.0, 0.95, 0.25)
	var bare := Paint.coat(Paint.CERAMIC, 0.1, 0.0, 0.85, 0.8)
	var core := Paint.coat(Paint.GUNMETAL, 1.0, 0.5, 0.5)
	_slab(b, _plan(0.22, -0.46, 0.46, 0.06, 0.06), -0.034, 0.004, 0.01, core)
	b.box(Vector3(0.03, 0.016, 0.2), Vector3(0.0, 0.0, 0.54), core, 0.004)
	_port(b, size, core, 0.11)
	for z in [-0.42, 0.0, 0.42]:
		b.box(Vector3(0.33, 0.014, 0.04), Vector3(0.0, 0.008, z), wood, 0.004)
	# Three planks, none quite the length or the height of the next.
	for plank: Array in [[-0.112, 0.108, 1.2, 0.0245, 0.012, -0.02], [0.0, 0.112, 1.24, 0.0255, -0.006, 0.0],
			[0.114, 0.104, 1.16, 0.024, 0.01, 0.02]]:
		b.box(Vector3(plank[1], (plank[3] - 0.0145) * 2.0, plank[2]), Vector3(plank[0], plank[3], plank[5]), wood, 0.006,
			Basis(Vector3.UP, plank[4]))
	# Lashings: four turns round all three planks, a gap between each.
	for z in [-0.38, -0.08, 0.22, 0.5]:
		for i in 4:
			b.box(Vector3(0.336, 0.026, 0.0045), Vector3(0.0, 0.0255, z + (i - 1.5) * 0.0065), cord, 0.0012)
	# A saltbush rail along the left, lashed at three places.
	b.drum(0.009, 0.96, Vector3(-0.168, 0.02, 0.02), wood, ALONG, 8)
	for z in [-0.3, 0.06, 0.4]:
		b.drum(0.0115, 0.012, Vector3(-0.168, 0.02, z), cord, ALONG, 8)
	# The round cap the battery sits on, glazed, on a bare coil, corded down.
	b.drum(0.112, 0.008, Vector3(0.0, -0.002, -0.535), bare, Basis.IDENTITY, 20)
	b.drum(0.105, 0.0695, Vector3(0.0, 0.00475, -0.535), Paint.coat(Paint.GLAZE, 0.25, 0.0, 0.25, 0.4), Basis.IDENTITY, 20, 0.09)
	for x in [-1.0, 1.0]:
		b.strand(Vector3(x * 0.1, 0.03, -0.47), Vector3(x * 0.14, 0.036, -0.38), 0.005, cord)
	# A charm off the left cord: a glazed bead on a short tail.
	b.strand(Vector3(-0.14, 0.036, -0.38), Vector3(-0.172, 0.006, -0.36), 0.003, cord)
	b.ball(0.008, Vector3(-0.172, 0.002, -0.36), Paint.coat(Paint.GLAZE, 0.25, 0.0, 0.25, 0.4))
	# The sign of Tu on limewash at the tail.
	b.stamp(Paint.Mark.TU, Vector3(0.0, h.y, 0.565), 0.17, TAIL)
	b.box(Vector3(0.2, 0.004, 0.11), Vector3(0.0, 0.037, 0.565), Paint.coat(Paint.LIMEWASH, 0.35, 0.0, 0.88), 0.001,
		Basis(Vector3.UP, -0.04))
	# The water vial bound under the right planks, stoppered in ceramic.
	b.drum(0.018, 0.09, Vector3(0.16, -0.004, 0.12), Paint.coat(Paint.SAND_GLASS, 0.3, 0.2, 0.1, 0.4), ALONG, 10)
	b.drum(0.012, 0.014, Vector3(0.16, -0.004, 0.069), bare, ALONG, 8)
	for z in [0.095, 0.145]:
		b.box(Vector3(0.028, 0.04, 0.008), Vector3(0.16, -0.004, z), cord, 0.003)
	# The tassel at the tail's left corner.
	var knot := Vector3(-0.14, -0.002, h.z - 0.012)
	b.box(Vector3.ONE * 0.014, knot, cord, 0.004, Basis(Vector3.UP, PI * 0.25))
	for i in 3:
		b.strand(knot, knot + Vector3((i - 1) * 0.008, -0.034, 0.004), 0.004, Paint.coat(Paint.DYED, 0.3, 0.0, 0.85))
	# Ceramic rings round the old core's two emitters.
	for z in [-0.3, 0.32]:
		_emitter(b, Vector3(0.0, -0.0369, z), 0.055, Paint.coat(Paint.CERAMIC, 0.5, 0.0, 0.35, 0.7), 2.4)


# --- The rig -------------------------------------------------------------------


## The hover tray: a moulded housing banded in safety stripes, castings at its
## corners, four emitters in guarded nacelles and the junction box their
## conduits run from.
static func _tray(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var steel := Paint.coat(Paint.STEEL, 0.6, 0.8, 0.45)
	var face := 0.05
	_slab(b, _plan(size.x - 0.004, -h.y + 0.002, h.y - 0.002, 0.07, 0.07), 0.004, face, 0.01, Paint.coat(Paint.GUNMETAL), Vector3.ZERO,
		ALONG)
	for side in 4:
		var turn := Basis(Vector3.BACK, side * PI * 0.5)
		_hazard(b, Vector3(0.36, 0.022, 0.006), turn * Vector3(0.0, h.y - 0.004, 0.027), turn * FLAT)
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			var corner := Vector3(x * 0.29, y * 0.29, 0.0)
			b.box(Vector3(0.07, 0.07, 0.016), corner + Vector3(0.0, 0.0, face + 0.004), Paint.black(), 0.006)
			b.bolt(corner + Vector3(0.0, 0.0, face + 0.012), 0.011, ALONG)
	b.box(Vector3(0.12, 0.12, 0.02), Vector3(0.0, 0.0, face + 0.006), Paint.black(), 0.006)
	for x in [-1.0, 1.0]:
		for y in [-1.0, 1.0]:
			var at := Vector3(x * 0.18, y * 0.18, 0.0)
			b.strand(Vector3(x * 0.055, y * 0.055, face + 0.005), at * 0.62 + Vector3(0.0, 0.0, face + 0.005), 0.012,
				Paint.black())
			b.drum(0.092, 0.024, at + Vector3(0.0, 0.0, face + 0.008), Paint.black(), ALONG, 18)
			b.drum(0.072, 0.0058, at + Vector3(0.0, 0.0, face + 0.0205), _glow(), ALONG, 18)
			for k in 2:
				b.box(Vector3(0.17, 0.006, 0.008), at + Vector3(0.0, 0.0, face + 0.0225 - k * 0.0015), steel, 0.0,
					Basis(Vector3.BACK, PI * 0.25 + k * PI * 0.5))


## Skates: two crossbars cast at their ends on a spine striped down its face,
## a hanger at each blade's ends, the blades long and steel-edged with their
## noses turned up so a crest's lip never digs one in, a tie rod between them.
static func _skates(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var keel: float = Catalog.PARTS[&"skates"].stats.keel
	var reach := size.z + keel
	var gun := Paint.coat(Paint.GUNMETAL)
	var steel := Paint.coat(Paint.STEEL, 0.5, 0.8, 0.5)
	for y in [-0.28, 0.28]:
		b.box(Vector3(size.x - 0.04, 0.06, size.z - 0.004), Vector3(0.0, y, size.z * 0.5), gun, 0.008)
		for x in [-1.0, 1.0]:
			b.box(Vector3(0.05, 0.074, size.z), Vector3(x * (h.x - 0.035), y, size.z * 0.5 + 0.0005), Paint.black(), 0.008)
	b.box(Vector3(0.05, 0.62, 0.012), Vector3(0.0, 0.0, 0.015), gun, 0.004)
	_hazard(b, Vector3(0.4, 0.03, 0.004), Vector3(0.0, 0.0, 0.023), ACROSS)
	for x in [-1.0, 1.0]:
		var blade := Vector3(x * (h.x - 0.05), 0.0, 0.0)
		for y in [-0.28, 0.28]:
			b.box(Vector3(0.046, 0.07, keel - 0.008), blade + Vector3(0.0, y, size.z + (keel - 0.008) * 0.5), gun, 0.006)
			b.drum(0.01, 0.06, blade + Vector3(0.0, y, size.z + 0.022), steel, ACROSS, 8)
		b.box(Vector3(0.022, size.y - 0.2, 0.026), blade + Vector3(0.0, 0.0, reach - 0.019), gun, 0.004)
		b.box(Vector3(0.012, size.y - 0.22, 0.008), blade + Vector3(0.0, 0.0, reach - 0.004), steel, 0.002)
		for y in [-1.0, 1.0]:
			var up := Basis(Vector3.RIGHT, -y * 0.5)
			var nose := blade + Vector3(0.0, y * (h.y - 0.075), reach - 0.034)
			b.box(Vector3(0.022, 0.095, 0.022), nose, gun, 0.004, up)
			b.box(Vector3(0.012, 0.085, 0.007), nose + up * Vector3(0.0, 0.0, 0.0125), steel, 0.002, up)
	b.drum(0.008, size.x - 0.12, Vector3(0.0, 0.0, size.z + 0.03), steel, ACROSS, 8)


## The board plate: a frame plate on four struts on rubber, one wide runner
## under them turned up at nose and tail like a sled's, its face gunmetal
## worn bright along three skid strips, rubber down its long edges.
static func _plate(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var keel: float = Catalog.PARTS[&"board_plate"].stats.keel
	var face := size.z + keel
	var gun := Paint.coat(Paint.GUNMETAL)
	var steel := Paint.coat(Paint.STEEL, 0.5, 0.55, 0.6, 0.7)
	b.box(Vector3(size.x - 0.02, size.y - 0.12, size.z - 0.002), Vector3(0.0, 0.0, h.z), gun, 0.006)
	for x in [-1.0, 1.0]:
		_hazard(b, Vector3(0.24, 0.024, 0.004), Vector3(x * (h.x - 0.05), 0.0, size.z - 0.0005), ACROSS)
		for y in [-1.0, 1.0]:
			var at := Vector3(x * (h.x - 0.1), y * (h.y - 0.15), 0.0)
			b.drum(0.026, 0.006, at + Vector3(0.0, 0.0, size.z + 0.003), Paint.rubber(), ALONG, 10)
			b.box(Vector3(0.04, 0.04, keel - 0.012), at + Vector3(0.0, 0.0, size.z + 0.006 + (keel - 0.012) * 0.5), gun, 0.005)
			b.bolt(Vector3(x * (h.x - 0.03), y * (h.y - 0.075), size.z - 0.0005), 0.009, ALONG)
	b.box(Vector3(size.x - 0.01, size.y - 0.2, 0.012), Vector3(0.0, 0.0, face - 0.008), gun, 0.004)
	for y in [-1.0, 1.0]:
		var up := Basis(Vector3.RIGHT, -y * 0.45)
		var end := Vector3(0.0, y * (h.y - 0.064), face - 0.0254)
		b.box(Vector3(size.x - 0.01, 0.08, 0.012), end, gun, 0.004, up)
		for x in [-0.2, 0.0, 0.2]:
			b.box(Vector3(0.03, 0.07, 0.004), end + up * Vector3(x, 0.0, 0.007), steel, 0.001, up)
	for x in [-0.2, 0.0, 0.2]:
		b.box(Vector3(0.03, size.y - 0.204, 0.004), Vector3(x, 0.0, face - 0.002), steel, 0.001)
	for x in [-1.0, 1.0]:
		b.box(Vector3(0.012, size.y - 0.2, 0.016), Vector3(x * (h.x - 0.0065), 0.0, face - 0.009), Paint.rubber(), 0.003)


## The keel: a skimmer's ventral strake, an olive plate bolted under the deck,
## a fin tapering fore and aft under it with ribs welded up its flanks, its
## field's emitter glowing in cells down its edge.
static func _keel(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var gun := Paint.coat(SkimmerKit.GUNMETAL, 0.8, 0.5, 0.5)
	var weld := _weld()
	b.box(Vector3(size.x - 0.004, size.y - 0.004, 0.022), Vector3(0.0, 0.0, 0.0115), Paint.coat(SkimmerKit.OLIVE, 1.0, 0.4, 0.6), 0.006)
	# The fin's profile, root to edge, as a slab turned on its side.
	var side := Basis(Vector3(0.0, 1.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0))
	_slab(b, PackedVector2Array([Vector2(-0.43, -0.02), Vector2(0.43, -0.02), Vector2(0.3, -0.068), Vector2(-0.3, -0.068)]),
		-0.024, 0.024, 0.008, gun, Vector3.ZERO, side)
	for y in [-0.3, -0.15, 0.0, 0.15, 0.3]:
		for x in [-1.0, 1.0]:
			b.box(Vector3(0.006, 0.012, 0.038), Vector3(x * 0.025, y, 0.042), gun, 0.002)
			b.drum(0.004, 0.012, Vector3(x * 0.026, y, 0.0225), weld, ALONG, 6)
	b.box(Vector3(0.03, 0.62, 0.012), Vector3(0.0, 0.0, 0.072), Paint.black(), 0.003)
	for i in 6:
		b.box(Vector3(0.016, 0.085, 0.006), Vector3(0.0, -0.25 + i * 0.1, 0.0765), _glow(), 0.001)
	for y in [-1.0, 1.0]:
		_hazard(b, Vector3(0.18, 0.026, 0.004), Vector3(0.0, y * (h.y - 0.03), 0.0225), Basis.IDENTITY)
		for x in [-1.0, 1.0]:
			b.bolt(Vector3(x * (h.x - 0.022), y * (h.y - 0.075), 0.0225), 0.008, ALONG)
	b.box(Vector3(0.07, 0.11, 0.003), Vector3(0.06, 0.2, 0.0235), Paint.scrap(), 0.001, Basis(Vector3.BACK, 0.18))


## The sail furled on its boom: a steel boom collared as the boom spar is, a
## gooseneck at its root and a sheet block at its end, the cloth flaked over
## it in lumpy folds, fuller toward the mast, tied down with gaskets.
static func _sail(b: Paint.Pieces, size: Vector3) -> void:
	var gun := Paint.gunmetal()
	var steel := Paint.coat(Paint.STEEL, 0.65, 0.7)
	var cloth := Paint.coat(Paint.SAILCLOTH, 0.5, 0.0, 0.95)
	var rope := Paint.coat(Paint.ROPE, 0.4, 0.0, 0.9)
	b.drum(0.027, size.z - 0.06, Vector3(0.0, 0.0, size.z * 0.5), steel, ALONG, 12)
	for z in [0.05, size.z * 0.5, size.z - 0.08]:
		b.drum(0.034, 0.05, Vector3(0.0, 0.0, z), gun, ALONG, 12)
	b.box(Vector3(0.05, 0.05, 0.05), Vector3(0.0, 0.0, 0.026), gun, 0.008)
	b.drum(0.012, 0.07, Vector3(0.0, 0.0, 0.026), steel, Basis.IDENTITY, 8)
	b.box(Vector3(0.03, 0.06, 0.05), Vector3(0.0, -0.01, size.z - 0.03), gun, 0.006)
	b.drum(0.022, 0.016, Vector3(0.0, -0.022, size.z - 0.03), Paint.black(), ACROSS, 10)
	# The furl between its gaskets, each fold a little off the last.
	var ties: Array[float] = [0.18, 0.5, 0.84, 1.18, 1.5, 1.8]
	var stops: Array[float] = [0.1]
	stops.append_array(ties)
	stops.append(size.z - 0.14)
	for i in stops.size() - 1:
		var z0 := stops[i]
		var z1 := stops[i + 1]
		var full := lerpf(0.068, 0.046, z0 / size.z) * (1.0 + 0.06 * sin(i * 2.3))
		var pinch := full * 0.8
		var at := Vector3(0.006 * sin(i * 1.7), 0.014, 0.0)
		b.drum(pinch, (z1 - z0) * 0.5, at + Vector3(0.0, 0.0, z0 + (z1 - z0) * 0.25), cloth, ALONG, 10, full)
		b.drum(full, (z1 - z0) * 0.5, at + Vector3(0.0, 0.0, z0 + (z1 - z0) * 0.75), cloth, ALONG, 10, pinch)
	for z in ties:
		var girth := lerpf(0.068, 0.046, z / size.z) * 0.8 + 0.006
		b.drum(girth, 0.012, Vector3(0.0, 0.014, z), rope, ALONG, 10)
		b.box(Vector3(0.018, 0.014, 0.02), Vector3(0.0, 0.014 + girth, z), rope, 0.004)
