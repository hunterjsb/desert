extends WreckProbe
## Wreck probe 8: a wrecked nomad rig always yields a sail, and one is within
## a first run's reach but never handed out. On six worlds, round each
## origin's start, every nomad rig history lays holds its mast with its sail
## on it; the nearest sail (a nomad rig's, or one lying anywhere else as
## you'd find it when you'd walked there) is nearer than a fair walk, and no
## start has one at its feet. Laid by hand, a rig's mast lies beside it with
## its sail furled on it, free to take, and taking it you hold both.

const SEEDS := [1234, 1, 2, 42, 777, 1001]
## A fair walk and a first run's reach, m (loot probe 6's), and the nearest a
## sail may lie to where a run begins, m.
const REACH := 3000.0
const NOT_AT_FEET := 150.0


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var lay := tuning.history_lay_m
	tuning.history_lay_m = REACH + 200.0
	var ground := Vector2.ONE * tuning.chunk_size * 0.5
	var rigs := 0
	var rigged := 0
	var nearest: Array[float] = []
	for s: int in SEEDS:
		var shape := TerrainShape.new(s, tuning)
		for kit in Kit.origins():
			var at := Starts.find(shape, kit.start, tuning)
			shape.sites.follow(ground.x, ground.y, Sphere.latitude(at), Sphere.longitude(at), 1.0, INF)
			var found := _sails(shape, ground, tuning)
			rigs += found.rigs
			rigged += found.rigged
			nearest.append(found.m)
			print("seed %4d %-16s nearest sail %5.0f m (%s), the nearest nomad rig %5.0f m, %d rigs within %.0f m" % [s,
				kit.label, found.m, found.where, found.rig_m, found.rigs, REACH])
	tuning.history_lay_m = lay
	nearest.sort()
	print("the nearest sail: %.0f m at least, %.0f m on the median, %.0f m at most" % [nearest[0],
		nearest[nearest.size() / 2], nearest[-1]])
	check(rigs > 0 and rigged == rigs, "every nomad rig holds its mast with its sail (%d of %d)" % [rigged, rigs])
	check(nearest[-1] <= REACH, "every start has a sail within a first run's reach (%.0f m at most)" % nearest[-1])
	check(nearest[0] >= NOT_AT_FEET, "and none at its feet (%.0f m at least)" % nearest[0])

	await load_salvage()
	var spot := open_sand()
	var wreck := await wreck_at(&"nomad_rig", spot.x, spot.y)
	if wreck == null:
		return
	var mast: Mast = null
	for body in salvage.finds():
		if body is Mast and site_of(body) == wreck.site:
			mast = body
	check(mast != null and mast.sail() != null, "the rig's mast lies beside it with its sail on it")
	if mast == null:
		return
	check(salvage.held_fast(mast) == "", "free to take")
	# At its pole, under where the boom swings: taken hold of there, the whole mast comes.
	face(mast.global_transform * Vector3(0.0, -0.35, 0.0), mast.global_basis.x, 1.2)
	await physics_frames(2)
	hands.grab()
	await physics_frames(40)
	check((hands.held == mast or hands.grasp.body == mast) and mast.sail() != null and not salvage.lying(mast),
		"taken, you hold the mast and its sail, yours")


## The nearest sail round a start, as you'd find it there: {m, where, rig_m,
## rigs, rigged}.
func _sails(shape: TerrainShape, ground: Vector2, tuning: Tuning) -> Dictionary:
	var out := {"m": INF, "where": "none", "rig_m": INF, "rigs": 0, "rigged": 0}
	for unit in shape.sites.units():
		for site in unit.sites:
			var m := site.distance_to(ground.x, ground.y)
			if not site is Structure or m > REACH or shape.sites.covering(site.x, site.z) != site:
				continue
			var piece: StructureKit.Piece = site.piece
			if site.kind == &"nomad_rig":
				out.rigs += 1
				out.rig_m = minf(out.rig_m, m)
				for i in piece.sockets.size():
					if piece.sockets[i].kind == SiteLoot.RIGGED:
						var drawn := SiteLoot.draw(site, i)
						out.rigged += int(drawn.id == &"mast" and drawn.fill.any(func(f: Array) -> bool: return f[1] == &"sail"))
			site.decide(m / tuning.walk_speed)
			for spec in SiteLoot.plan(site, shape.height_at):
				if m < out.m and _sail(spec):
					out.m = m
					out.where = "%s %s" % [Exposure.NAMES[site.state()], site.kind]
			site.forget()
	return out


func _sail(spec: Dictionary) -> bool:
	return spec.id == &"sail" or spec.fill.any(func(f: Array) -> bool: return f[1] == &"sail") \
		or spec.has("rig")
