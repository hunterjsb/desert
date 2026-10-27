class_name PowerLooks
extends RefCounted
## The power boxes in their eras' coats (Dress), each laid round its bays as
## the catalog places them, so a battery always sits in a bay you can see and
## each bay's strip sits in a bezel of its own. The colonial cabinet: off-white
## modular panels, grey and safety orange, crisp numbered bays, a readout
## across its head. The company's dock: gunmetal, teal and yellow, folded
## plate and rubber corners, its batch stencil. The skimmer's rack: tube and
## mismatched housings in olive, red plate and scrap, taped, three bays burnt
## out. The temple's shrine: limewashed render, ceramic and saltbush wood,
## niches under ceramic lintels, sand-glass tubes, the sign of Tu, charms.

const FRONT := Basis(Vector3.UP, PI)


## Draws a box's look into its pieces; false for an id that isn't one.
static func frame(b: Paint.Pieces, id: StringName, size: Vector3, _era := Eras.NEW, _extra := 0.0) -> bool:
	match id:
		&"power_cabinet":
			_cabinet(b, size)
		&"power_box":
			_dock(b, size)
		&"power_rack":
			_rack(b, size)
		&"power_shrine":
			_shrine(b, size)
		_:
			return false
	return true


## Its bays' entries and frames, dead ones too: [entry, frame].
static func _bays(id: StringName) -> Array:
	var out := []
	for entry: Array in Catalog.DEVICES[id].sockets:
		if entry[0] == &"battery" or entry[0] == PowerBox.DEAD:
			out.append([entry, PowerBox.bay_frame(entry)])
	return out


## A bezel behind each bay's strip, `rim` wider all round.
static func _bezels(b: Paint.Pieces, id: StringName, look: Paint.Coat, rim: float) -> void:
	var spec: Dictionary = PowerBox.MODELS[id]
	for each: Array in _bays(id):
		var bay: Dictionary = each[0][3] if each[0].size() > 3 else {}
		var at: Transform3D = each[1] * PowerBox.strip_frame(id, bay)
		b.box(Vector3(spec.wide + rim * 2.0, spec.long + rim * 2.0, 0.004), at * Vector3(0.0, 0.0, -0.004), look, 0.0015,
			at.basis)


static func _cabinet(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var panel := Paint.off_white()
	var grey := Paint.coat(ColonialKit.GREY, 0.6, 0.4, 0.45)
	var dark := Paint.coat(ColonialKit.DARK, 0.4, 0.3, 0.5)
	var orange := Paint.safety_orange()
	var black := Paint.black()
	var face := -h.z
	var recess: float = PowerBox.MODELS[&"power_cabinet"].recess
	# The body behind the bays, the plinth and the cap.
	b.box(Vector3(size.x - 0.02, size.y - 0.13, size.z - recess), Vector3(0.0, 0.025, recess * 0.5), panel, 0.02)
	b.box(Vector3(size.x, 0.09, size.z), Vector3(0.0, -h.y + 0.045, 0.0), dark, 0.015)
	b.hazard(Vector3(size.x * 0.7, 0.03, 0.012), Vector3(0.0, -h.y + 0.045, face - 0.004), FRONT)
	b.box(Vector3(size.x, 0.04, size.z), Vector3(0.0, h.y - 0.02, 0.0), grey, 0.012)
	b.box(Vector3(size.x - 0.02, 0.012, 0.006), Vector3(0.0, h.y - 0.035, face - 0.002), orange, 0.002)
	# The fascia: stiles and rails round the bays, set into it.
	var z := face + recess * 0.5
	var top := 0.43
	var low := -0.495
	for stile: Vector2 in [Vector2(-0.39, -0.3), Vector2(0.0, 0.06), Vector2(0.36, 0.39)]:
		b.box(Vector3(stile.y - stile.x, top - low, recess), Vector3((stile.x + stile.y) * 0.5, (top + low) * 0.5, z), panel, 0.006)
	for rail: Vector2 in [Vector2(0.19, 0.225), Vector2(-0.05, -0.015), Vector2(-0.29, -0.255), Vector2(-0.51, low)]:
		b.box(Vector3(size.x - 0.02, rail.y - rail.x, recess), Vector3(0.0, (rail.x + rail.y) * 0.5, z), panel, 0.003)
	b.box(Vector3(size.x - 0.02, h.y - 0.04 - top, recess), Vector3(0.0, (top + h.y - 0.04) * 0.5, z), panel, 0.006)
	# Each bay: a dark liner, its contacts, and its number stencilled over it.
	var bays := _bays(&"power_cabinet")
	for i in bays.size():
		var at: Transform3D = bays[i][1]
		b.box(Vector3(0.296, 0.201, 0.004), at * Vector3(0.0, 0.0, 0.003), dark, 0.002, at.basis)
		for x in [-0.05, 0.05]:
			b.box(Vector3(0.03, 0.02, 0.012), at * Vector3(x, -0.06, 0.0), orange, 0.002, at.basis)
		_digits(b, str(i + 1), at * Transform3D(Basis.IDENTITY, Vector3(-0.135, 0.131, recess + 0.0005)), 0.022, orange)
	_bezels(b, &"power_cabinet", black, 0.007)
	# The readout's glass across its head, in a grey bezel.
	b.box(Vector3(0.66, 0.095, 0.004), Vector3(0.0, h.y - 0.08, face - 0.001), grey, 0.002)
	b.box(Vector3(0.62, 0.07, 0.004), Vector3(0.0, h.y - 0.08, face - 0.003), Paint.coat(ColonialKit.GLASS, 0.0, 0.2, 0.15, 0.2), 0.001)
	# Sides: modular panels with louvres, orange grab handles, the contractor's tag.
	for x in [-1, 1]:
		var turn := Basis(Vector3.UP, x * PI * 0.5)
		if x > 0:
			b.stamp(Paint.Mark.CONTRACTOR, Vector3(h.x - 0.005, 0.3, 0.02), 0.2, turn, Paint.Ink.DARK)
		b.box(Vector3(size.z - 0.1, 0.5, 0.01), turn * Vector3(0.0, 0.25, h.x - 0.005), panel, 0.004, turn)
		b.box(Vector3(size.z - 0.1, 0.42, 0.01), turn * Vector3(0.0, -0.25, h.x - 0.005), panel, 0.004, turn)
		for i in 8:
			b.box(Vector3(size.z - 0.18, 0.012, 0.016), turn * Vector3(0.0, -0.42 + i * 0.045, h.x - 0.004), black, 0.002, turn)
		b.box(Vector3(0.03, 0.2, 0.03), Vector3(x * h.x, 0.12, -0.05), orange, 0.008)
	# Its back: the fan, the port's plate.
	b.box(Vector3(size.x - 0.1, size.y - 0.2, 0.012), Vector3(0.0, 0.02, h.z - 0.004), panel, 0.004)
	b.ring(0.1, 0.14, Vector3(0.0, 0.2, h.z - 0.002), black, Basis(Vector3.RIGHT, PI / 2.0), 12)
	b.box(Vector3(0.12, 0.08, 0.01), Vector3(0.0, -0.42, h.z - 0.004), dark, 0.003)


## The company's dock: bays in its top, strips at each bay's near edge.
static func _dock(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var gun := Paint.coat(Paint.GUNMETAL)
	var teal := Paint.coat(Paint.TEAL)
	var yellow := Paint.coat(Paint.YELLOW, 0.8)
	var black := Paint.black()
	var recess: float = PowerBox.MODELS[&"power_box"].recess
	var sole := h.y - recess
	b.box(Vector3(size.x - 0.02, sole + h.y, size.z - 0.02), Vector3(0.0, (sole - h.y) * 0.5, 0.0), gun, 0.012)
	# Its top plate, folded round the bays.
	var y := h.y - recess * 0.5
	for bar: Vector2 in [Vector2(-0.31, -0.295), Vector2(-0.015, 0.015), Vector2(0.295, 0.31)]:
		b.box(Vector3(bar.y - bar.x, recess, size.z), Vector3((bar.x + bar.y) * 0.5, y, 0.0), teal, 0.003)
	for bar: Vector2 in [Vector2(-0.25, -0.21), Vector2(-0.01, 0.03), Vector2(0.23, 0.25)]:
		b.box(Vector3(size.x, recess, bar.y - bar.x), Vector3(0.0, y, (bar.x + bar.y) * 0.5), teal, 0.003)
	for each: Array in _bays(&"power_box"):
		var at: Transform3D = each[1]
		b.box(Vector3(0.276, 0.196, 0.004), at * Vector3(0.0, 0.0, 0.003), Paint.coat(Paint.GRIP, 0.2), 0.001, at.basis)
	_bezels(b, &"power_box", black, 0.006)
	# Rubber corners, the batch stencil on its front, grips in its sides.
	for x in [-1, 1]:
		for z in [-1, 1]:
			b.box(Vector3(0.045, size.y, 0.045), Vector3(x * (h.x - 0.02), 0.0, z * (h.z - 0.02)), yellow, 0.01)
		b.box(Vector3(0.006, 0.025, 0.14), Vector3(x * (h.x - 0.008), -0.02, 0.0), black, 0.002)
	b.stamp(Paint.Mark.CONSIGNMENT, Vector3(0.0, -0.025, -h.z + 0.008), 0.2, FRONT, Paint.Ink.PALE)
	b.box(Vector3(0.36, 0.05, 0.004), Vector3(0.0, -0.025, -h.z + 0.008), gun, 0.002)


## The skimmer's rack: an open frame of tube, a housing bolted in for each
## bay, none matching.
static func _rack(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var olive := Paint.coat(SkimmerKit.OLIVE, 1.0, 0.4, 0.6)
	var red := Paint.coat(SkimmerKit.PLATE_RED, 0.9, 0.0, 0.55)
	var scrap := Paint.coat(SkimmerKit.SCRAP, 1.2, 0.5, 0.7)
	var gun := Paint.coat(SkimmerKit.GUNMETAL, 0.8, 0.5, 0.5)
	var rubber := Paint.coat(SkimmerKit.RUBBER, 0.2, 0.0, 0.9)
	var tape := Paint.tape()
	var soot := Paint.coat(Paint.SOOT, 0.0, 0.0, 1.0, 0.3)
	# Tube posts on rubber feet, rails across, a sheet of scrap behind.
	for x in [-1, 1]:
		for z in [-1, 1]:
			b.drum(0.024, size.y - 0.04, Vector3(x * (h.x - 0.03), 0.0, z * (h.z - 0.03)), gun, Basis.IDENTITY, 10)
			b.box(Vector3(0.08, 0.03, 0.08), Vector3(x * (h.x - 0.03), -h.y + 0.015, z * (h.z - 0.03)), rubber, 0.006)
	var across := Basis(Vector3.BACK, PI / 2.0)
	for y in [h.y - 0.03, -h.y + 0.05]:
		for z in [-1, 1]:
			b.drum(0.02, size.x - 0.06, Vector3(0.0, y, z * (h.z - 0.03)), gun, across, 10)
	b.box(Vector3(size.x - 0.08, size.y - 0.12, 0.012), Vector3(0.0, 0.0, h.z - 0.04), scrap, 0.002)
	b.hazard(Vector3(0.5, 0.035, 0.012), Vector3(0.12, -h.y + 0.05, -h.z + 0.008), FRONT)
	var looks := [olive, red, scrap, gun, olive, scrap, red, gun, olive, red, scrap, olive]
	var bays := _bays(&"power_rack")
	var recess: float = PowerBox.MODELS[&"power_rack"].recess
	for i in bays.size():
		var at: Transform3D = bays[i][1]
		var look: Paint.Coat = looks[i % looks.size()]
		var dead: bool = bays[i][0][0] == PowerBox.DEAD
		var deep := 0.25
		var mid := recess - deep * 0.5
		# Its housing: four walls and a back, open to the front.
		for s in [-1, 1]:
			b.box(Vector3(0.324, 0.012, deep), at * Vector3(0.0, s * 0.116, mid), look, 0.003, at.basis)
			b.box(Vector3(0.012, 0.22, deep), at * Vector3(s * 0.156, 0.0, mid), look, 0.003, at.basis)
		b.box(Vector3(0.3, 0.22, 0.01), at * Vector3(0.0, 0.0, recess - deep), soot if dead else gun, 0.002, at.basis)
		if i % 3 == 1:
			b.box(Vector3(0.18, 0.018, 0.05), at * Vector3(0.04, 0.122, recess - 0.02), tape, 0.004, at.basis)
		if dead:
			# Burnt out: soot, a plate riveted half over it, a red cross daubed on.
			var askew := at.basis * Basis(Vector3.BACK, 0.14)
			b.box(Vector3(0.2, 0.11, 0.006), at * Vector3(0.03, 0.03, recess - 0.004), scrap, 0.002, askew)
			for k in [-1, 1]:
				b.box(Vector3(0.11, 0.014, 0.004), at * Vector3(-0.08, -0.05, recess), red, 0.001,
					at.basis * Basis(Vector3.BACK, k * PI / 4.0))
		else:
			b.box(Vector3(0.04, 0.025, 0.012), at * Vector3(0.0, -0.075, recess - deep + 0.012), Paint.coat(Paint.YELLOW, 0.6), 0.002, at.basis)
	_bezels(b, &"power_rack", tape, 0.006)
	# Cable bodged between bays, and the crew's patch on its side.
	for wire: Array in [[Vector3(0.15, 0.27, -h.z + 0.03), 0.2], [Vector3(-0.16, 0.02, -h.z + 0.03), -0.35],
			[Vector3(0.0, -0.24, -h.z + 0.03), 0.1]]:
		b.box(Vector3(0.3, 0.01, 0.01), wire[0], Paint.coat(Paint.BLACK, 0.2), 0.002, Basis(Vector3.BACK, wire[1]))
	var side := Basis(Vector3.UP, -PI * 0.5)
	b.stamp(Paint.Mark.SKIMMER_CREW, Vector3(-h.x + 0.01, 0.12, 0.0), 0.2, side, Paint.Ink.PALE)
	b.box(Vector3(0.26, 0.3, 0.006), Vector3(-h.x + 0.01, 0.12, 0.0), red, 0.002, side)


## The temple's shrine round an old bus: niches in limewashed render under
## ceramic lintels, a dome, a sand-glass tube by each niche.
static func _shrine(b: Paint.Pieces, size: Vector3) -> void:
	var h := size * 0.5
	var render := Paint.coat(SecondAgeKit.RENDER, 0.8, 0.0, 0.9, 1.0)
	var lime := Paint.coat(Paint.LIMEWASH, 0.35, 0.0, 0.88)
	var ceramic := Paint.coat(Paint.CERAMIC, 0.5, 0.0, 0.35, 0.7)
	var clay := Paint.coat(SecondAgeKit.CLAY, 0.6, 0.0, 0.85)
	var wood := Paint.coat(Paint.SALTWOOD, 0.2, 0.0, 0.8, 0.8)
	var cord := Paint.coat(Paint.CORD, 0.1, 0.0, 0.9, 0.5)
	var glass := Paint.coat(Paint.SAND_GLASS, 0.3, 0.2, 0.1, 0.4)
	var brass := Paint.coat(Paint.BRASS, 0.5, 0.8, 0.35)
	var dyed := Paint.coat(Paint.DYED, 0.3, 0.0, 0.85)
	var gun := Paint.coat(Paint.GUNMETAL)
	var recess: float = PowerBox.MODELS[&"power_shrine"].recess
	var face := -h.z
	var top := 0.26
	# Saltbush planks under it, the render body behind the niches.
	for k in 3:
		b.box(Vector3(size.x - 0.01 * k, 0.035, 0.12), Vector3(0.004 * k, -h.y + 0.0175, -0.12 + k * 0.12), wood, 0.006)
	var foot := -h.y + 0.035
	b.box(Vector3(size.x - 0.02, top - foot, size.z - recess), Vector3(0.0, (top + foot) * 0.5, recess * 0.5), render, 0.03)
	# Its limewashed face round the niches.
	var z := face + recess * 0.5
	var bands := [[Vector2(-0.4, 0.4), Vector2(foot, -0.35)], [Vector2(-0.4, 0.4), Vector2(-0.13, -0.04)],
		[Vector2(-0.4, 0.4), Vector2(0.18, top)], [Vector2(0.33, 0.39), Vector2(-0.35, -0.13)],
		[Vector2(-0.03, 0.03), Vector2(-0.35, -0.13)], [Vector2(-0.39, -0.33), Vector2(-0.35, -0.13)],
		[Vector2(0.19, 0.39), Vector2(-0.04, 0.18)], [Vector2(-0.39, -0.11), Vector2(-0.04, 0.18)]]
	for band: Array in bands:
		var x: Vector2 = band[0]
		var y: Vector2 = band[1]
		b.box(Vector3(minf(x.y - x.x, size.x - 0.02), y.y - y.x, recess), Vector3((x.x + x.y) * 0.5, (y.x + y.y) * 0.5, z), lime, 0.008)
	# Each niche: clay inside, a ceramic lintel with its round cap over it.
	for each: Array in _bays(&"power_shrine"):
		var at: Transform3D = each[1]
		b.box(Vector3(0.296, 0.216, 0.004), at * Vector3(0.0, 0.0, 0.003), clay, 0.002, at.basis)
		b.box(Vector3(0.34, 0.03, 0.022), at * Vector3(0.0, 0.126, recess + 0.008), ceramic, 0.008, at.basis)
		b.ball(0.034, at * Vector3(0.0, 0.13, recess + 0.018), ceramic, Vector3(1.0, 1.0, 0.45), at.basis)
		for x in [-0.152, 0.152]:
			b.box(Vector3(0.01, 0.22, 0.012), at * Vector3(x, 0.0, recess + 0.004), ceramic, 0.003, at.basis)
	# The tubes: sand-glass behind each strip, brass at its ends.
	var spec: Dictionary = PowerBox.MODELS[&"power_shrine"]
	for each: Array in _bays(&"power_shrine"):
		var bay: Dictionary = each[0][3] if each[0].size() > 3 else {}
		var at: Transform3D = each[1] * PowerBox.strip_frame(&"power_shrine", bay)
		b.box(Vector3(spec.wide + 0.014, spec.long + 0.01, 0.006), at * Vector3(0.0, 0.0, -0.005), glass, 0.003, at.basis)
		for s in [-1, 1]:
			b.drum(0.024, 0.02, at * Vector3(0.0, s * (spec.long * 0.5 + 0.012), -0.004), brass, at.basis, 10)
	# A frieze of ceramic knobs along its head, saltbush posts at its front
	# corners, the dome on its collar with a brass finial, the sign of Tu on
	# limewash beside the high niche.
	for i in 9:
		b.ball(0.016, Vector3(-0.34 + i * 0.085, top - 0.025, face - 0.008), ceramic, Vector3(1.0, 1.0, 0.6))
	for x in [-1, 1]:
		b.box(Vector3(0.024, top - foot, 0.04), Vector3(x * (h.x - 0.012), (top + foot) * 0.5, face + 0.005), wood, 0.006)
		b.ball(0.026, Vector3(x * (h.x - 0.014), top + 0.01, face + 0.005), ceramic)
	b.drum(0.25, 0.04, Vector3(0.0, top + 0.02, 0.02), ceramic, Basis.IDENTITY, 20)
	b.ball(0.21, Vector3(0.0, top + 0.04, 0.02), ceramic, Vector3(1.0, 0.62, 0.8))
	b.drum(0.012, 0.03, Vector3(0.0, h.y - 0.015, 0.02), brass, Basis.IDENTITY, 8)
	b.stamp(Paint.Mark.TU, Vector3(0.28, 0.07, face - 0.002), 0.11, FRONT)
	b.box(Vector3(0.13, 0.07, 0.004), Vector3(0.28, 0.07, face - 0.002), lime, 0.001)
	# Cord lashed round its bands, a charm, tassels at its corners, a water vial tied on.
	for y in [(foot - 0.35) * 0.5, -0.085]:
		b.box(Vector3(size.x - 0.005, 0.016, 0.012), Vector3(0.0, y, face - 0.004), cord, 0.003)
	b.box(Vector3(0.006, 0.06, 0.006), Vector3(0.0, -0.16, face - 0.008), cord, 0.0)
	b.ball(0.02, Vector3(0.0, -0.195, face - 0.012), ceramic)
	for x in [-1, 1]:
		for i in 3:
			b.box(Vector3(0.008, 0.07, 0.008), Vector3(x * (h.x - 0.06) + i * 0.012, -0.36, face - 0.01), dyed, 0.0,
				Basis(Vector3.BACK, (i - 1) * 0.12))
	b.drum(0.022, 0.09, Vector3(-h.x, -0.11, -0.02), glass, Basis.IDENTITY, 10)
	b.box(Vector3(0.03, 0.02, 0.05), Vector3(-h.x + 0.005, -0.06, -0.02), cord, 0.003)
	# The machine buried in it: the old bus's plate and its port at the back.
	b.box(Vector3(0.3, 0.18, 0.008), Vector3(-0.2, -0.33, h.z - 0.004), gun, 0.003)


## Digits in Pieces.numeral's strokes, `tall` m high, reading left to right as you face the
## frame from its +Z, its first digit's top left at the frame's origin.
static func _digits(b: Paint.Pieces, text: String, at: Transform3D, tall: float, look: Paint.Coat) -> void:
	var wide := tall * 0.55
	var line := tall * 0.14
	var x := 0.0
	for digit in text:
		for stroke in Paint.Pieces.STROKES.get(digit, ""):
			var where: Vector2 = Paint.Pieces.PLACES[stroke]
			var mid := Vector3(x + wide * 0.5 + where.x * wide, -tall * 0.5 + where.y * tall, 0.0)
			var size := Vector3(wide + line, line, 0.001) if stroke in "adg" else Vector3(line, tall * 0.5 + line, 0.001)
			b.box(size, at * mid, look, 0.0, at.basis)
		x += wide + tall * 0.3
