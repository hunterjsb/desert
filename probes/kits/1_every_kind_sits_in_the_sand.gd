extends Probe
## Structure kits probe 1: every kind sits in the sand, in each exposure
## state, by the ground's one function. Every kit piece, stood where the dunes
## take it, leaning as far as its era leans, buried, partly exposed and
## exposed by how deep it lies against the sand the weather took off it: what
## goes into the ground never shows its foot; what its state leaves out of its
## boxes lies under the sand, and something of it always shows; a room's floor
## never shows while it's buried, and dug out the sand lies just under it;
## round it the ground can be walked.

const SEED := 1234
## Points over a box's faces and a room's floor, this far apart, m.
const STEP := 0.5
## Sand this near a floor's top is just under it, m.
const UNDER := 0.05


func run() -> void:
	var tuning := Tuning.current()
	tuning.salvage = true
	var shape := TerrainShape.new(SEED, tuning)
	var field := WeatherField.new(SEED, tuning)
	var ground := Vector2.ONE * tuning.chunk_size * 0.5
	shape.sites.follow(ground.x, ground.y, 0.0, 0.0, 1.0, tuning.history_lay_m)
	var faults := 0
	var steepest := 0.0
	var tried := 0
	for kind: StringName in StructureKit.kinds():
		var piece := StructureKit.piece(kind)
		var lean := deg_to_rad(Eras.TILT.get(piece.era, Vector2.ZERO).y)
		for s in 3:
			var site := _stood(shape, field, tuning, kind, lean, s, ground + Vector2(300.0, 200.0), tried)
			tried += 1
			if site == null:
				faults += 1
				printerr("%s: nowhere it stands %s" % [kind, Exposure.NAMES[s]])
				continue
			var found := _faults(shape, site, s, tuning)
			steepest = maxf(steepest, found.steepest)
			for each: String in found.faults:
				faults += 1
				printerr("%s %s at %.0f,%.0f: %s" % [kind, Exposure.NAMES[s], site.x, site.z, each])
	print("%d kinds in three states each; the steepest ground round any is %.1f°" % [StructureKit.kinds().size(), steepest])
	check(faults == 0, "every kind sits in the sand in every state (%d faults)" % faults)
	check(steepest < tuning.slip_angle, "the ground round each can be walked (%.1f° against %.0f°)"
		% [steepest, tuning.slip_angle])


## A kind stood by hand where the dunes take it, near `near`, in state `s`:
## read at a moment the weather had stripped sand there, lying as deep as
## puts it in that state.
func _stood(shape: TerrainShape, field: WeatherField, tuning: Tuning, kind: StringName, lean: float, s: int,
		near: Vector2, start: int) -> Structure:
	for n in 200:
		var k := (n + start * 7) % 200
		var at := near + Vector2((k % 20) * 23.0, (k / 20) * 29.0)
		var site := shape.sites.by_hand(kind, at.x, at.y, 0.4 + k * 0.7, 0.0, lean)
		if not site.stands():
			continue
		for hour in 72:
			var t := hour * 3600.0
			var taken := Exposure.taken(field, site.x, site.z, t, tuning)
			if taken < 0.3:
				continue
			# Partly exposed's own look: two thirds of its depth off.
			site.depth = [taken * 4.0, taken * 1.5, 0.0][s]
			site.decide(t)
			if site.state() == s:
				return site
	return null


## What's wrong with a structure in its state, and the steepest ground round it.
func _faults(shape: TerrainShape, site: Structure, s: int, tuning: Tuning) -> Dictionary:
	var faults := PackedStringArray()
	var piece := site.piece
	var frame := site.frame()
	var shown := piece.shown(s)
	var showing := false
	for i in piece.boxes.size():
		var box := piece.boxes[i]
		# Into the ground, below the floor it stands on: its foot is under the
		# sand everywhere.
		var under := 0.0
		for room in piece.rooms:
			if room.holds(Vector2(box.get_center().x, box.get_center().z)):
				under = room.floor
		if box.position.y < under - 0.01:
			var highest := -INF
			for p in _face(box, box.position.y):
				var at := frame * p
				highest = maxf(highest, at.y - _ground(shape, site, at.x, at.z))
			if highest > 0.01:
				faults.append("box %d's foot shows %.2f m" % [i, highest])
		var above := -INF
		for p in _face(box, box.end.y):
			var at := frame * p
			above = maxf(above, at.y - _ground(shape, site, at.x, at.z))
		if i in shown:
			showing = showing or above > StructureKit.SHOWS
		elif above > StructureKit.SHOWS:
			faults.append("box %d is left out yet shows %.2f m" % [i, above])
	if not showing:
		faults.append("nothing of it shows")
	# A room's floor: never seen while buried, just under the sand once dug out.
	for room in piece.rooms:
		var off := 0.0
		var u := room.lo.x
		while u <= room.hi.x + 0.001:
			var v := room.lo.y
			while v <= room.hi.y + 0.001:
				var at := site.to_world(Vector2(u, v))
				var top := site.floor_in(s) + room.floor
				var sand := _ground(shape, site, roundf(at.x), roundf(at.y))
				var ramp := room.sand(Vector2(u, v)) > room.floor + 0.01
				if s != Exposure.EXPOSED and sand < top:
					off = maxf(off, top - sand)
				elif s == Exposure.EXPOSED and not ramp and (sand > top or sand < top - UNDER):
					off = maxf(off, absf(sand - top))
				v += 1.0
			u += 1.0
		if off > 0.001:
			faults.append("a room's floor is off the sand by %.3f m" % off)
	# Round it, where its ground isn't the dunes': never too steep to walk.
	var steepest := 0.0
	var r := ceili(site.reach)
	for j in range(-r, r + 1):
		for i in range(-r, r + 1):
			var x := roundf(site.x) + i
			var z := roundf(site.z) + j
			if piece.out_of(site.plan(x - site.x, z - site.z)) <= 0.0 \
					or absf(shape.sample(x, z, site) - shape.dunes(x, z)) < 0.01:
				continue
			var grade := Vector2(_ground(shape, site, x + 0.5, z) - _ground(shape, site, x - 0.5, z),
				_ground(shape, site, x, z + 0.5) - _ground(shape, site, x, z - 0.5))
			steepest = maxf(steepest, rad_to_deg(atan(grade.length())))
	return {"faults": faults, "steepest": steepest}


## Points over a box's face at height y, in its plan.
func _face(box: AABB, y: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var nu := maxi(1, ceili(box.size.x / STEP))
	var nv := maxi(1, ceili(box.size.z / STEP))
	for a in nu + 1:
		for b in nv + 1:
			out.append(Vector3(box.position.x + box.size.x * a / nu, y, box.position.z + box.size.z * b / nv))
	return out


## The ground's one function with this structure pressed into it.
func _ground(shape: TerrainShape, site: Structure, x: float, z: float) -> float:
	var i := floorf(x)
	var j := floorf(z)
	var fx := x - i
	var fz := z - j
	return TerrainShape.across(fx, fz, shape.sample(i + 1.0, j, site), shape.sample(i, j + 1.0, site),
		shape.sample(i, j, site) if fx + fz <= 1.0 else shape.sample(i + 1.0, j + 1.0, site))
