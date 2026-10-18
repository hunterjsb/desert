extends WorldProbe
## World system probe 4: the site index answers as a scan of everything laid
## does, and the sheet never changes loaded ground. On a walk past Halfrise:
## every cell that could touch a loaded chunk is laid before it's built; a
## site laid stays where it was while it's laid; cells laid at different
## moments meet within the seam the doc gives; and after a jump of the moon
## point, what lies under loaded ground stays as it was while nothing new is
## laid over it.

const HOPS := 16
const HOP := 200.0
const RECTS := 60
## Cells laid from points apart meet at most this far off, m, at 22°.
const SEAM := 30.0


func run() -> void:
	await load_world(99, true, true)
	# West of Halfrise, at 22° north on this seed, so the walk east passes it
	# and the Rim's richest history.
	var halfrise: Vector3 = world.shape.history.landmark(&"halfrise").p
	var start := Sphere.toward(halfrise, -PI * 0.5, 1800.0 / world.shape.history.radius)
	world.travel(rad_to_deg(Sphere.latitude(start)), rad_to_deg(Sphere.longitude(start)), 0.0)
	await settle()
	var sites := world.shape.sites
	var history := world.shape.history
	var was := {}
	var moved := 0
	var unlaid := 0
	var seam := 0.0
	var from := Vector2(world.player_world_x(), world.player_world_z())
	for hop in HOPS:
		var at := from + Vector2(HOP, -HOP * 0.3) * hop
		teleport(at.x, at.y)
		await settle()
		var now := {}
		for unit in sites.units():
			for site in unit.sites:
				now[site.id] = Vector2(site.x, site.z)
				if was.has(site.id) and was[site.id] != now[site.id]:
					moved += 1
		was = now
		unlaid += _unlaid_under_loaded(sites, history)
		seam = maxf(seam, _seam(sites, history))
	check(moved == 0, "a laid site never moves while laid (%d did)" % moved)
	check(unlaid == 0, "every cell that could touch loaded ground was laid first (%d weren't)" % unlaid)
	print("widest seam between cells laid apart: %.2f m" % seam)
	check(seam > 0.0 and seam <= SEAM, "cells laid apart meet within %.0f m (%.2f)" % [SEAM, seam])
	_against_a_scan(sites)

	# A jump: the moon point moves with no walk. What's under loaded ground stays.
	var under := {}
	for unit in sites.units():
		if world.terrain.is_loaded_in(unit.ground):
			for site in unit.sites:
				under[site.id] = Vector2(site.x, site.z)
	world.moon.place(-10.0, 150.0)
	await physics_frames(2)
	var kept := 0
	for unit in sites.units():
		for site in unit.sites:
			if under.has(site.id) and under[site.id] == Vector2(site.x, site.z):
				kept += 1
	check(kept == under.size() and kept > 0, "after a jump, history under loaded ground stays as it was (%d of %d)"
		% [kept, under.size()])
	var over := sites._units.values().filter(func(u: Sites.Unit) -> bool: return world.terrain.is_loaded_in(u.ground))
	check(over.is_empty(), "and nothing new is laid over it (%d)" % over.size())


## Cells whose ground could touch a loaded chunk but aren't laid.
func _unlaid_under_loaded(sites: Sites, history: History) -> int:
	var anchor: Sites.Anchor = sites._anchor
	var missing := {}
	var reach := world.tuning.chunk_size * 0.75 + SiteKinds.most_reach() + PathNetwork.CORRIDOR
	for chunk: TerrainChunk in world.terrain.chunks():
		var middle := anchor.point_at((chunk.coord.x + 0.5) * chunk.side, (chunk.coord.y + 0.5) * chunk.side)
		for cell in history.cells.within(middle, reach):
			# within() is a box round the cap: only cells that really come near.
			var near := Sphere.angle(middle, history.cells.center(cell)) * history.radius - history.cells.half_diagonal(cell)
			if near <= reach and not sites._units.has(cell):
				missing[cell] = true
	return missing.size()


## The widest gap where one path's pieces from two cells meet.
func _seam(sites: Sites, history: History) -> float:
	var ends := {}
	var widest := 0.0
	for unit in sites.units():
		for piece in unit.pieces:
			ends[Vector2i(piece.path, piece.first)] = piece.points[0]
	for unit in sites.units():
		for piece in unit.pieces:
			var next: Variant = ends.get(Vector2i(piece.path, piece.first + piece.points.size() - 1))
			if next != null:
				widest = maxf(widest, (next as Vector2).distance_to(piece.points[-1]))
	return widest


## Rectangles round you: the index's answers against a scan of everything laid.
func _against_a_scan(sites: Sites) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var all_sites: Array[Site] = []
	var all_pieces: Array[Sites.Piece] = []
	for unit in sites.units():
		all_sites.append_array(unit.sites)
		all_pieces.append_array(unit.pieces)
	var wrong := 0
	var answered := 0
	var x := world.player_world_x()
	var z := world.player_world_z()
	for k in RECTS:
		var size := Vector2(rng.randf_range(1.0, 600.0), rng.randf_range(1.0, 600.0))
		var rect := Rect2(x + rng.randf_range(-900.0, 600.0), z + rng.randf_range(-900.0, 600.0), size.x, size.y)
		var asked := {}
		for site in sites.query(rect):
			asked[site] = true
		var scanned := {}
		for site in all_sites:
			if site.touches(rect):
				scanned[site] = true
		var pieces := {}
		for piece in sites.paths_in(rect):
			pieces[piece] = true
		var crossing := {}
		for piece in all_pieces:
			if piece.crosses(rect):
				crossing[piece] = true
		answered += asked.size() + pieces.size()
		if asked.keys().size() != scanned.size() or not scanned.keys().all(func(s: Site) -> bool: return asked.has(s)) \
				or pieces.size() != crossing.size() or not crossing.keys().all(func(p: Sites.Piece) -> bool: return pieces.has(p)):
			wrong += 1
	check(wrong == 0 and answered >= RECTS / 2, "the index answers as a scan does over %d areas (%d differ, %d answers)"
		% [RECTS, wrong, answered])
	# And each chunk's own, as chunks will ask: what touches its square, and
	# the sites whose middle stands in it.
	var off := 0
	var touching := 0
	for chunk: TerrainChunk in world.terrain.chunks():
		var square := Rect2(Vector2(chunk.coord) * chunk.side, Vector2.ONE * chunk.side)
		var scanned := all_sites.filter(func(s: Site) -> bool: return s.touches(square))
		var asked_here := sites.query(square, true)
		touching += scanned.size()
		if asked_here.size() != scanned.size() or not scanned.all(func(s: Site) -> bool: return asked_here.has(s)):
			off += 1
		var own := all_sites.filter(func(s: Site) -> bool: return square.has_point(Vector2(s.x, s.z)))
		var asked := sites.in_chunk(chunk.coord)
		if asked.size() != own.size() or not own.all(func(s: Site) -> bool: return asked.has(s)):
			off += 1
	check(off == 0 and touching > 0, "every chunk's own answers are a scan's (%d chunks differ, %d sites touch them)"
		% [off, touching])
