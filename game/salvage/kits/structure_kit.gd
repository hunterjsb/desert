class_name StructureKit
extends RefCounted
## The one system every structure is built by. A kit piece is data, in its
## era's file: its footprint, how it presses into the ground's one function
## (rooms dug to their floors, drift up its walls, level at its doors), the
## boxes it's built of, its sockets, how deep each exposure state sinks it,
## and its look in its era's paint. Nothing here knows any one piece.
##
## Plan coordinates are metres, the floor's top at 0: u across, v along the
## way it faces. A lattice piece's outer faces, and the inner faces of its
## outer walls, stand on whole metres, so the sand's rise from floor to drift
## happens inside a wall where nobody sees it.

## Inside, the sand lies this far under a floor's top, so the floor shows.
const SAND_UNDER := 0.03
## A box whose top is no more than this above the sand is left out: there's
## nothing of it to see or stand on.
const SHOWS := 0.02
## A socket can be reached from the sand up to this high, m: a hand's reach.
const HANDS := 1.7
## A glint needs this much clear of the sand under it, m: dust lies on what
## the sand just let go.
const GLINT_CLEAR := 0.15


static var _pieces := {}


## A room, where the sand lies under the floor once the site's dug out: a plan
## rect and its floor's height, and a drift ramp down into it if it's sunk,
## the sand rising from its floor at `ramp.y` to the rim at `ramp.z` along u
## (`ramp.x` 0) or v (1).
class Room:
	var lo: Vector2
	var hi: Vector2
	var floor := 0.0
	var ramp := Vector3(-1.0, 0.0, 0.0)

	func holds(p: Vector2) -> bool:
		return p.x >= lo.x and p.x <= hi.x and p.y >= lo.y and p.y <= hi.y

	## The sand's height here once dug out, plan m.
	func sand(p: Vector2) -> float:
		if ramp.x < 0.0:
			return floor
		var along := p.x if ramp.x < 0.5 else p.y
		return lerpf(floor, 0.0, clampf((along - ramp.y) / (ramp.z - ramp.y), 0.0, 1.0))


## Where loot or a prop goes: a plan point on what it rests on, its kind (a
## floor spot, a shelf, a cache, a planter bed), and how much deeper than the
## rest of the site it lies, as a share of the site's burial a storm must
## strip past it.
class SiteSocket:
	var at: Vector3
	var kind: StringName
	var deep: float

	func _init(place: Vector3, socket_kind: StringName, deeper := 0.0) -> void:
		at = place
		kind = socket_kind
		deep = deeper


## What a structure reads its ground and weather from: the dunes it stands
## in, the run's weather and tuning, and the world's clock.
class Context:
	var shape: WeakRef
	var field: WeatherField
	var tuning: Tuning
	var clock := func() -> float: return 0.0


## One kit piece, as data. Its era's file fills it in; finish() works out the rest.
class Piece:
	var kind: StringName
	var era: StringName
	## Half its footprint to its outer faces, plan m.
	var half := Vector2.ONE
	## The footprint's parts the sand drifts against, plan rects as [lo, hi];
	## the whole footprint if none.
	var solids: Array[Array] = []
	## Its ground reaches this far past its footprint; there the dunes have
	## their own shape back.
	var apron := 4.0
	## How far out the drift against it reaches, m, and how high the sand
	## drifts against it in each state.
	var drift_reach := 2.0
	var drift := PackedFloat32Array([0.1, 0.2, 0.4])
	var rooms: Array[Room] = []
	## Openings the drift falls away level in front of, so you walk in: plan
	## [middle of the opening on its outer face, outward, width]; and how thick
	## the wall they pass through is.
	var doors: Array[Array] = []
	var wall := 1.0
	## Boxes and slabs in plan metres, built for walking, and the coat each
	## takes, by name.
	var boxes: Array[AABB] = []
	var coats := PackedStringArray()
	## The boxes you can sleep on, by their place in boxes: a bunk, a bench.
	var beds := PackedInt32Array()
	var sockets: Array[SiteSocket] = []
	## In each state (Exposure's order): how far it sinks below the sand, and
	## how high the sand fills its rooms, plan m (-INF: dug out to the floor).
	var sink := PackedFloat32Array([0.0, 0.0, 0.0])
	var fill := PackedFloat32Array([0.0, 0.0, -INF])
	## Where it may stand: the most the dunes over its ground may rise, m, and
	## how steep they may be, degrees.
	var survey := Vector2(1.2, 20.0)
	## Where the dunes won't take it, it may look this far along its plan u
	## axis (or v) for ground that will, m.
	var slide_m := 24.0
	var slide := Vector2(1.0, 0.0)
	## Walls stand on the lattice: it turns only in quarter turns.
	var lattice := false
	## How much of its site's lean it takes, about which plan axis, through
	## which plan point, so its free end digs into the sand.
	var lean := 0.0
	var lean_axis := Vector3.RIGHT
	var lean_pivot := Vector3.ZERO
	## A walk in through its openings and out again, plan points on the sand,
	## once dug out; and where to stand to see it.
	var tour := PackedVector2Array()
	var approach := Vector2(0.0, 12.0)
	## What draws its look: look.call(pieces, piece, state), in variant colours'
	## first; its other looks are the same with that colour swapped for each
	## of theirs (a house's colours).
	var variants := PackedColorArray()
	var look: Callable
	## How worn its paint looks, least and most: its era's years and how well
	## the sand kept it; and whose hands its maker's marks are from (Paint's
	## rows: 1 the surface's, 2 the deep's).
	var age := Vector2(0.4, 0.7)
	var marks := 1
	## What it's built as on the ground: a Structure, or a kind of one.
	var builds: Script
	## How it reads past the built ground (Skyline): plan boxes as [AABB, tone],
	## its outline in the colour its paint shows at a distance. None for what's
	## too low to read there.
	var far: Array[Array] = []
	## Whether its far look is a landmark's, drawn never smaller than one
	## (Tuning skyline_landmark_px): what stands tall enough to steer by.
	var far_landmark := false
	## Bare metal, glass or glaze the sun can catch: [plan point, the way it
	## faces, how wide its sparkle sweeps, rad].
	var glints: Array[Array] = []
	## How far its ground reaches from its middle, any way round, m.
	var reach := 0.0

	var _shown := {}
	var _shapes: Array[BoxShape3D] = []
	var _meshes := {}

	func finish() -> void:
		era = SiteKinds.era(kind)
		if builds == null:
			builds = Structure
		if solids.is_empty():
			solids.append([-half, half])
		var far := half
		for box in boxes:
			far = Vector2(maxf(far.x, maxf(absf(box.position.x), absf(box.end.x))),
				maxf(far.y, maxf(absf(box.position.z), absf(box.end.z))))
		reach = far.length() + apron

	## How far a plan point is outside its footprint, m: 0 within it.
	func out_of(p: Vector2) -> float:
		var near := INF
		for solid in solids:
			var lo: Vector2 = solid[0]
			var hi: Vector2 = solid[1]
			near = minf(near, Vector2(maxf(maxf(lo.x - p.x, p.x - hi.x), 0.0),
				maxf(maxf(lo.y - p.y, p.y - hi.y), 0.0)).length())
		return near

	## The drift falls away level in front of each opening.
	func clear_of_doors(p: Vector2) -> float:
		var clear := 1.0
		for door in doors:
			var at: Vector2 = door[0]
			var out: Vector2 = door[1]
			if (p - at).dot(out) >= -wall:
				var along := absf((p - at).dot(Vector2(out.y, -out.x)))
				var w: float = door[2] * 0.5 + 0.3
				clear = minf(clear, smoothstep(w, w + 2.7, along))
		return clear

	## The boxes the sand leaves showing in a state: those whose top rises
	## over the sand where they stand, in their room or out of one.
	func shown(state: int) -> PackedInt32Array:
		if not _shown.has(state):
			var keep := PackedInt32Array()
			for i in boxes.size():
				var box := boxes[i]
				# Where the sand's lowest over its top, a metre apart.
				var lowest := INF
				for a in ceili(box.size.x) + 1:
					for b in ceili(box.size.z) + 1:
						lowest = minf(lowest, sand_line(Vector2(minf(box.position.x + a, box.end.x),
							minf(box.position.z + b, box.end.z)), state))
				if lean > 0.0 or box.end.y > lowest + SHOWS:
					keep.append(i)
			_shown[state] = keep
		return _shown[state]

	## Where the sand lies at a plan point on its footprint in a state, plan m,
	## before any drift: in a room as its floor or fill says, else the sink.
	func sand_line(p: Vector2, state: int) -> float:
		for room in rooms:
			if room.holds(p):
				return maxf(room.sand(p), fill[state]) - SAND_UNDER
		return sink[state] - SAND_UNDER

	func shape(i: int) -> BoxShape3D:
		if _shapes.is_empty():
			for box in boxes:
				var made_shape := BoxShape3D.new()
				made_shape.size = box.size
				_shapes.append(made_shape)
		return _shapes[i]

	func looks() -> int:
		return maxi(1, variants.size())

	## Whether it shows from far off: a far look or a glint.
	func seen() -> bool:
		return not far.is_empty() or not glints.is_empty()

	## Its look in a state: one mesh every site of the kind and look shares,
	## its foot where the sand meets it. Leaning, it looks the same buried or not.
	func mesh(state: int, variant: int) -> ArrayMesh:
		var key := (state if lean == 0.0 else 0) * 16 + variant
		if not _meshes.has(key):
			if variant > 0:
				_meshes[key] = _recoloured(mesh(state, 0), variants[0], variants[variant])
			else:
				var b := Paint.Pieces.new(sink[state] if lean == 0.0 else -INF)
				look.call(b, self, state)
				_meshes[key] = b.commit()
		return _meshes[key]

	## The same mesh with one paint swapped for another.
	static func _recoloured(from: ArrayMesh, was: Color, now: Color) -> ArrayMesh:
		var arrays := from.surface_get_arrays(0)
		var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var old := was.srgb_to_linear()
		var new := now.srgb_to_linear()
		for i in colours.size():
			if colours[i].is_equal_approx(old):
				colours[i] = new
		arrays[Mesh.ARRAY_COLOR] = colours
		var made := ArrayMesh.new()
		# Only the custom channels' formats carry over: the rest follow the arrays.
		var customs := ((1 << (Mesh.ARRAY_FORMAT_CUSTOM_BASE + 4 * Mesh.ARRAY_FORMAT_CUSTOM_BITS)) - 1) \
			& ~((1 << Mesh.ARRAY_FORMAT_CUSTOM_BASE) - 1)
		made.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, from.surface_get_format(0) & customs)
		made.surface_set_material(0, from.surface_get_material(0))
		return made


## The piece a kind is built from, or null for a kind that's only a plan.
static func piece(kind: StringName) -> Piece:
	_load()
	return _pieces.get(kind)


static func has(kind: StringName) -> bool:
	_load()
	return _pieces.has(kind)


static func kinds() -> Array:
	_load()
	return _pieces.keys()


## History's sites of a kind nearest a place on the moon, nearest first,
## made from the cells round it a widening ring at a time, out to `most_m`:
## for the dev console and probes, which go to them however far they are.
static func nearest_on_moon(history: History, p: Vector3, kind: StringName, most_m: float,
		enough := 6) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var seen := {}
	var r := minf(2000.0, most_m)
	while true:
		for cell in history.cells.within(p, r):
			if seen.has(cell):
				continue
			seen[cell] = true
			for each in history.sites_in_cell(cell):
				if each.kind == kind:
					found.append(each)
		if found.size() >= enough or r >= most_m:
			break
		r = minf(r * 2.0, most_m)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Sphere.angle(p, a.p) < Sphere.angle(p, b.p))
	return found


## Where on the moon to start runs among history's house ruins: `aside` m
## off the middle of each of the `count` towns nearest `from` round which at
## least `least` of them stand, laid from about where a run's ground starts
## (`ground`, world metres), and that `wanted(shape, ground)` keeps, laid so.
## For probes, look-tests and dev scenarios: a run's own start is deep
## desert, where history left next to nothing. Nearest first.
static func starts_among(run_seed: int, tuning: Tuning, from: Vector3, ground: Vector2, count := 1,
		aside := 400.0, least := 4, wanted := Callable()) -> Array[Vector3]:
	var found: Array[Vector3] = []
	var shape := TerrainShape.new(run_seed, tuning)
	for town in towns_near(shape.history, from):
		var at := beside(shape.history, town, from, aside)
		if stands_among(shape, at, ground, aside + town.radius, least, wanted):
			found.append(at)
			if found.size() >= count:
				break
	return found


## History's villages and Rim towns nearest a place on the moon, nearest first.
static func towns_near(history: History, from: Vector3, most := 24) -> Array:
	var towns := history.settlements.filter(func(t: Dictionary) -> bool: return t.kind in [&"rim_town", &"village"])
	towns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return Sphere.angle(from, a.p) < Sphere.angle(from, b.p))
	return towns.slice(0, most)


## The place `aside` m off a town's middle toward `from`.
static func beside(history: History, town: Dictionary, from: Vector3, aside: float) -> Vector3:
	return Sphere.toward(town.p, Sphere.bearing(town.p, from), aside / history.radius)


## Whether, laid from `ground` with the moon's point at `at`, at least `least`
## house ruins stand within `within` m and `wanted(shape, ground)` keeps it.
static func stands_among(shape: TerrainShape, at: Vector3, ground: Vector2, within: float, least: int,
		wanted := Callable()) -> bool:
	# All of it laid at once, as far as laying reaches.
	shape.sites.follow(ground.x, ground.y, Sphere.latitude(at), Sphere.longitude(at), 1.0, INF)
	var standing := 0
	for unit in shape.sites.units():
		for site in unit.sites:
			if site is Ruin and site.stands() and site.distance_to(ground.x, ground.y) < within:
				standing += 1
	return standing >= least and (not wanted.is_valid() or wanted.call(shape, ground))


## The narrowest any structure's ground is, either way, m: a rectangle no
## wider than this can only meet one's ground by a corner.
static func narrowest() -> float:
	_load()
	var least := INF
	for each: Piece in _pieces.values():
		least = minf(least, 2.0 * (minf(each.half.x, each.half.y) + each.apron if each.lattice else each.reach))
	return least


## Builds every piece's looks and shapes while the world loads, so the first
## chunk with a structure doesn't pay for them inside the streaming budget.
static func prepare() -> void:
	_load()
	for each: Piece in _pieces.values():
		for state in 3:
			for variant in each.looks():
				each.mesh(state, variant)
		if not each.boxes.is_empty():
			each.shape(0)


static func _load() -> void:
	if not _pieces.is_empty():
		return
	for era: Script in [ColonialKit, SkimmerKit, FirstKingdomsKit, SecondAgeKit]:
		for each: Piece in era.pieces():
			each.finish()
			_pieces[each.kind] = each


# --- What the era files build their pieces from. ---

## A piece of a kind, its footprint and how it's sunk in each state as [sink,
## fill] buried, then partly exposed; exposed it stands on the sand, dug out.
static func define(kind: StringName, half: Vector2, buried: Vector2, partly: Vector2) -> Piece:
	var p := Piece.new()
	p.kind = kind
	p.half = half
	p.sink = PackedFloat32Array([buried.x, partly.x, 0.0])
	p.fill = PackedFloat32Array([buried.y, partly.y, -INF])
	return p


static func room(lo: Vector2, hi: Vector2, floor := 0.0, ramp := Vector3(-1.0, 0.0, 0.0)) -> Room:
	var r := Room.new()
	r.lo = lo
	r.hi = hi
	r.floor = floor
	r.ramp = ramp
	return r


static func box(p: Piece, lo: Vector3, hi: Vector3, coat: String) -> void:
	p.boxes.append(AABB(lo, hi - lo))
	p.coats.append(coat)


## A box that's a bed as well: use on it sleeps there (Sleep).
static func bed(p: Piece, lo: Vector3, hi: Vector3, coat: String) -> void:
	p.beds.append(p.boxes.size())
	box(p, lo, hi, coat)


## A box of its far look, plan m, in the tone it reads as from far off.
static func far_box(p: Piece, lo: Vector3, hi: Vector3, tone: Color) -> void:
	p.far.append([AABB(lo, hi - lo), tone])


## A spot the sun can catch, facing `facing` in plan axes, sweeping a few
## degrees. Seen from far off a glint reaches your eye only off a face
## turned up by about half the sun's height, so a curve takes a spot or two
## facing out low; what faces the sky glints for those above it.
static func glint(p: Piece, at: Vector3, facing: Vector3, degrees := 3.0) -> void:
	p.glints.append([at, facing.normalized(), deg_to_rad(degrees)])


## A wall from `a0` to `a1` along u (or v), `b0` to `b1` thick, from `y0` to
## `y1`, with an opening `width` wide and `high` tall at each of `doors` along
## it, a lintel over each that doesn't reach the top.
static func wall(p: Piece, along_u: bool, b0: float, b1: float, a0: float, a1: float, y0: float, y1: float,
		doors: Array, coat: String, width := 1.4, high := 2.3) -> void:
	var at := a0
	for door: float in doors:
		_span(p, along_u, at, door - width * 0.5, b0, b1, y0, y1, coat)
		if high < y1:
			_span(p, along_u, door - width * 0.5, door + width * 0.5, b0, b1, high, y1, coat)
		at = door + width * 0.5
	_span(p, along_u, at, a1, b0, b1, y0, y1, coat)


static func _span(p: Piece, along_u: bool, a0: float, a1: float, b0: float, b1: float, y0: float, y1: float,
		coat: String) -> void:
	if a1 - a0 < 0.01:
		return
	if along_u:
		box(p, Vector3(a0, y0, b0), Vector3(a1, y1, b1), coat)
	else:
		box(p, Vector3(b0, y0, a0), Vector3(b1, y1, a1), coat)


## Draws a piece's boxes the sand leaves showing, each in the coat its name
## takes, its edges cut back by `cut`; a box with no coat is only solid, its
## look drawn some other way.
static func draw_boxes(b: Paint.Pieces, p: Piece, state: int, coats: Dictionary, cut := 0.03) -> void:
	for i in p.shown(state):
		if p.coats[i].is_empty():
			continue
		var each := p.boxes[i]
		b.box(each.size, each.get_center(), coats[p.coats[i]], minf(cut, minf(each.size.x, minf(each.size.y, each.size.z)) * 0.3))


## Whether a decoration whose top is at `y1`, standing at plan `at`, shows
## above the sand in a state.
static func shows(p: Piece, state: int, y1: float, at := Vector2(INF, INF)) -> bool:
	if p.lean > 0.0:
		return true
	return y1 > (p.sink[state] - SAND_UNDER if not at.is_finite() else p.sand_line(at, state)) + SHOWS


## A thin box from one point to another.
static func rod(b: Paint.Pieces, from: Vector3, to: Vector3, thick: float, look: Paint.Coat) -> void:
	var along := to - from
	var y := along.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	b.box(Vector3(thick, along.length(), thick), (from + to) * 0.5, look, thick * 0.2, Basis(x, y, x.cross(y)))
