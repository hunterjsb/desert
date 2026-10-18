extends WreckProbe
## Wreck probe 2: a wreck needs its operations. In every kind, each module is
## held fast as found and stays so while anything it needs is left: a plate
## in its way, or sand packed round it. It comes free the moment the last
## goes, never before. The wrong tool's work does nothing. A plate comes away
## only along its seams: the hot spot off a seam cuts nothing, half its seams
## leave it on, and cut through it falls outward off the hull onto the sand,
## where it then lies. A hold clears a slice at a time from its open end, and
## a hold cleared from the top lies level, whatever the wreck's lean.

const APART := 70.0


func run() -> void:
	await load_salvage()
	var spot := open_sand()
	var n := 0
	for kind in wreck_kinds():
		var wreck := await wreck_at(kind, spot.x + (n % 5) * APART, spot.y + (n / 5) * APART, 0.7 + n * 1.3)
		n += 1
		if wreck == null:
			continue
		var modules := modules_of(wreck)
		for socket: int in modules:
			check(modules[socket] != null and salvage.held_fast(modules[socket]) != "",
				"the %s's module %d is held fast as found" % [kind, socket])
		_wrong_tools(kind, wreck)
		await _seams(kind, wreck)
		_slices(kind, wreck)
		# Each module, its needs done one at a time: held until the last.
		for socket: int in modules:
			var body: Node = modules[socket]
			if body == null:
				continue
			var needs: Array = (wreck.plan.modules[socket] as WreckPlan.Module).needs
			for k in needs.size():
				var need: Array = needs[k]
				var left := needs.slice(k).any(func(each: Array) -> bool:
					return not wreck.done(each[1]) if each[0] == &"plate" else wreck.cleared(each[1]) < each[2])
				if left:
					check(salvage.held_fast(body) != "", "the %s's %s is held while it needs %s" % [kind, body.label,
						"its %s" % (wreck.plan.plates[need[1]].label if need[0] == &"plate" else wreck.plan.holds[need[1]].label)])
				if need[0] == &"plate":
					cut_away(wreck, need[1])
				else:
					clear_out(wreck, need[1], need[2])
			check(salvage.held_fast(body) == "", "with the last of it gone, the %s's %s comes free" % [kind, body.label])


## A scoop does nothing to a plate, a cutter nothing to sand, and neither
## makes a hazard safe.
func _wrong_tools(kind: StringName, wreck: Wreckage) -> void:
	var plate := wreck.plate_body(0)
	var sand := wreck.slice_body(0, wreck.cleared(0))
	check(plate == null or not wreck.clear(plate, 10.0), "a scoop does nothing to the %s's plate" % kind)
	check(sand == null or not wreck.cut(sand, sand.global_position, 10.0).seam, "a cutter does nothing to its sand")
	for socket: int in wreck.plan.modules:
		var hazard := wreck.hazard_body(socket)
		if hazard != null:
			var right := Wreckage.GROUND if wreck.plan.modules[socket].hazard == Wreckage.ELECTRICAL else Wreckage.SEAL
			var wrong := Wreckage.SEAL if right == Wreckage.GROUND else Wreckage.GROUND
			check(not wreck.make_safe(hazard, wrong) and wreck.hazard(socket) != &"",
				"the wrong tool leaves the %s's hazard live" % kind)


## The first plate facing out of the wreck (one facing in falls into what's
## behind it): nothing off its seams, half its seams leave it on, cut
## through it falls outward and lies on the sand.
func _seams(kind: StringName, wreck: Wreckage) -> void:
	var i := 0
	for k in wreck.plan.plates.size():
		var past: Vector3 = wreck.plan.plates[k].face() + wreck.plan.plates[k].normal() * 2.0
		if wreck.site.piece.out_of(Vector2(past.x, past.z)) > 0.0:
			i = k
			break
	var plate := wreck.plate_body(i)
	var p: WreckPlan.Plate = wreck.plan.plates[i]
	var face := plate.global_transform * p.face()
	var off := wreck.cut(plate, face, 30.0)
	check(not off.seam and wreck.progress(i) == 0.0, "the hot spot off the %s's seams cuts nothing" % kind)
	var cells := p.cells.size()
	for c in range(0, cells, 2):
		wreck.cut(plate, wreck.cell_point(i, c), wreck.cell_seconds() * 0.5)
	check(wreck.plate_body(i) != null and wreck.progress(i) > 0.2 and wreck.progress(i) < 0.9,
		"half cut, the %s's %s stays on (%d%%)" % [kind, p.label, roundi(wreck.progress(i) * 100.0)])
	var before := wreck.global_transform * p.box.get_center()
	var out := wreck.plate_normal(i)
	cut_away(wreck, i)
	check(wreck.plate_body(i) == null and wreck.done(i), "cut through, the %s's %s comes away" % [kind, p.label])
	await physics_frames(roundi(Wreckage.SETTLE_MOST * Engine.physics_ticks_per_second) + 10)
	check(wreck.state.fallen.has(i), "it comes to rest")
	if not wreck.state.fallen.has(i):
		return
	var lying: Transform3D = wreck.global_transform * (wreck.state.fallen[i] as Transform3D)
	var moved := lying.origin - before
	var under := world.height_under(lying.origin)
	print("%s: its %s fell %.2f m outward, %.2f m down, lying %.2f m over the sand" % [kind, p.label,
		moved.dot(out), -moved.y, lying.origin.y - under])
	check(moved.dot(out) > 0.1 or out.y > 0.5, "the %s's %s falls outward off the hull" % [kind, p.label])
	check(absf(lying.origin.y - under) < 1.2 or lying.origin.y < before.y, "and lies on the sand, or in the wreck below where it was")


## Only a hold's open slice can be cleared; a level hold lies level.
func _slices(kind: StringName, wreck: Wreckage) -> void:
	for h in wreck.plan.holds.size():
		var hold: WreckPlan.Hold = wreck.plan.holds[h]
		var first := wreck.cleared(h)
		if first + 1 < hold.slices:
			var deeper := wreck.slice_body(h, first + 1)
			check(deeper == null or not wreck.clear(deeper, 30.0), "the %s's %s clears from its open end" % [kind, hold.label])
		var open := wreck.slice_body(h, first)
		if open == null:
			continue
		if hold.from == WreckPlan.TOP:
			var up := (open.get_parent() as Node3D).global_basis.y.normalized()
			check(up.dot(Vector3.UP) > 0.9999, "the %s's %s lies level at %.0f° lean" % [kind, hold.label,
				rad_to_deg(wreck.site.tilt * wreck.site.piece.lean)])
		wreck.clear(open, wreck.slice_seconds(h, first) * 0.5)
		check(wreck.slice_body(h, first) != null and wreck.cleared(h) == first,
			"half a slice's work leaves the %s's %s standing" % [kind, hold.label])
		wreck.clear(open, wreck.slice_seconds(h, first) * 0.5 + 0.01)
		check(wreck.cleared(h) == first + 1, "the rest clears it")
