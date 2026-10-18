extends WreckProbe
## Wreck probe 1: every wreck stands where history puts it and holds its
## modules. History lays every kind of wreck: skimmer hulls and tithe haulers
## in the wreck fields, haulers at the black site's checkpoints, freight pods
## by the colonial frontier towns, lifeboats off the roads into Port Morgan and the
## Knights' hoppers along the crusade's road and by their bunkers. Laid by
## hand dug out, at its era's least lean and its most, every wreck has at
## least three modules, each lying in it held fast, a device with at least
## two parts (or as many as it has sockets for), over the sand; every plate's seams clear of the dunes, and
## something in every hold to clear.

## Each kind, the landmark history lays it toward, and how far round it to look, m.
const WHERE := {&"wreck_hull": [&"halloran", 12000.0], &"tithe_hauler": [&"halloran", 12000.0],
	&"freight_pod": [&"port_morgan", 20000.0], &"lifeboat": [&"port_morgan", 16000.0],
	&"hopper": [&"port_morgan", 40000.0]}
## Laid in rows this far apart, m, five to a row.
const APART := 70.0


func run() -> void:
	var tuning := Tuning.current()
	var history := History.new(1234, tuning)
	for kind: StringName in WHERE:
		var near: Array = WHERE[kind]
		var found := StructureKit.nearest_on_moon(history, history.landmark(near[0]).p, kind, near[1], 3)
		var sources := {}
		for each in found:
			sources[each.source] = true
		print("history lays %d %s within %.0f km of %s, from %s" % [found.size(), kind, near[1] / 1000.0, near[0],
			", ".join(sources.keys())])
		check(not found.is_empty(), "history lays a %s" % kind)

	await load_salvage()
	var spot := open_sand()
	var n := 0
	for kind in wreck_kinds():
		var tilt: Vector2 = Eras.TILT.get(StructureKit.piece(kind).era, Vector2.ZERO)
		for share: float in ([tilt.x / tilt.y, 1.0] if tilt.y > 0.0 else [1.0]):
			var wreck := await wreck_at(kind, spot.x + (n % 5) * APART, spot.y + (n / 5) * APART, 0.3 + n * 1.1, share)
			n += 1
			if wreck == null:
				continue
			var lean := "%.0f° lean" % rad_to_deg(wreck.site.tilt * wreck.site.piece.lean)
			var modules := modules_of(wreck)
			check(modules.size() >= 3, "a %s has at least three modules (%d)" % [kind, modules.size()])
			for socket: int in modules:
				var body: Device = modules[socket]
				check(body != null, "the %s's module %d lies in it at %s" % [kind, socket, lean])
				if body == null:
					continue
				var parts := body.sockets().filter(func(s: Socket) -> bool: return s.part != null).size()
				check(parts >= fillable(wreck, body), "the %s's %s has %d parts fitted" % [kind, body.label, parts])
				check(salvage.held_fast(body) != "", "the %s's %s is held fast as found" % [kind, body.label])
				var low := INF
				for corner in corners(body):
					low = minf(low, corner.y - world.height_under(corner))
				check(low > -0.15, "the %s's %s stands over the sand at %s (%.2f m)" % [kind, body.label, lean, low])
			for i in wreck.plan.plates.size():
				var buried := 0
				for c in wreck.plan.plates[i].cells.size():
					buried += int(wreck.cell_buried(i, c))
				check(buried == 0, "the %s's %s has its seams clear of the sand at %s (%d buried)" % [kind,
					wreck.plan.plates[i].label, lean, buried])
			for h in wreck.plan.holds.size():
				check(wreck.slice_body(h, 0) != null, "the %s's %s has sand to clear" % [kind, wreck.plan.holds[h].label])
