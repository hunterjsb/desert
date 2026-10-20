class_name SummitKit
extends RefCounted
## The relay and the elevator's severed foot share colonial service galleries.
## Their silhouettes are the same meshes from the horizon to the foundation.
static func pieces() -> Array[StructureKit.Piece]:
	var out: Array[StructureKit.Piece] = []
	for kind in [&"starcom_summit", &"observatory_summit"]:
		var p := StructureKit.define(kind, Vector2(42, 32), Vector2(0, 0.6), Vector2(0, 0.2))
		p.builds = SummitSite
		p.apron = 48.0
		p.age = Vector2(0.18, 0.32)
		p.look = _look
		# Low galleries leave a walk-in gap on the south side, with a roof and bench.
		_box(p, Vector3(0, -0.5, 0), Vector3(84, 1, 64), "concrete")
		for x in [-32.0, 32.0]:
			_box(p, Vector3(x, 3, 0), Vector3(1.4, 6, 44), "panel")
			_box(p, Vector3(x - signf(x) * 6, 6, 0), Vector3(14, 0.8, 44), "panel")
			_box(p, Vector3(x - signf(x) * 6, 3, -22), Vector3(14, 6, 1.2), "concrete")
			for z in [-18.0, 0.0, 18.0]:
				_box(p, Vector3(x - signf(x) * 12, 3, z), Vector3(0.6, 6, 0.6), "grey")
			p.sockets.append(StructureKit.SiteSocket.new(Vector3(x - signf(x) * 4, 0.8, -15), &"cache"))
			p.sockets.append(StructureKit.SiteSocket.new(Vector3(x - signf(x) * 5, 0.8, 12), &"shelf"))
		StructureKit.bed(p, Vector3(23, 0, 1), Vector3(27, 0.8, 3), "grey")
		p.rooms.append(StructureKit.room(Vector2(-38, -28), Vector2(38, 28)))
		if kind == &"starcom_summit":
			for x in [-8.0, 8.0]:
				_box(p, Vector3(x, 55, -5), Vector3(3, 110, 4), "grey")
			for y in [12.0, 36.0, 60.0, 84.0, 108.0]:
				_box(p, Vector3(0, y, -5), Vector3(20, 2, 6), "panel")
			_box(p, Vector3(0, 116, -5), Vector3(1.2, 20, 1.2), "orange")
		else:
			# Four colossal elevator rails, cut at unequal heights. The observatory
			# was fitted between them long after the cable was lost.
			for x in [-12.0, 12.0]:
				for z in [-12.0, 12.0]:
					var h: float = 170.0 + x + z * 0.5
					_box(p, Vector3(x, h * 0.5, z), Vector3(6, h, 6), "concrete")
			for y in [18.0, 54.0, 90.0, 126.0]:
				_box(p, Vector3(0, y, -12), Vector3(30, 3, 6), "grey")
				_box(p, Vector3(-12, y, 0), Vector3(6, 3, 30), "grey")
			_box(p, Vector3(0, 144, 0), Vector3(28, 8, 28), "panel")
		for state in 3:
			p._shown[state] = PackedInt32Array(range(p.boxes.size()))
		out.append(p)
	return out

static func _box(p: StructureKit.Piece, at: Vector3, size: Vector3, coat: String) -> void:
	StructureKit.box(p, at - size * 0.5, at + size * 0.5, coat)

static func _look(b: Paint.Pieces, p: StructureKit.Piece, _state: int) -> void:
	var c := ColonialKit.coats()
	for i in p.boxes.size():
		b.box(p.boxes[i].size, p.boxes[i].get_center(), c[p.coats[i]], 0.08)
	# Rings and radial ribs make a recognisable receiving array without a billboard.
	var y := 82.0 if p.kind == &"starcom_summit" else 151.0
	var r := 18.0 if p.kind == &"starcom_summit" else 10.0
	var at := Vector3(0, y, 0)
	var turn := Basis(Vector3.RIGHT, PI * 0.35)
	for radius in [r * 0.35, r * 0.68, r]:
		b.ring(radius - 0.35, radius, at, c.panel, turn, 40)
	for k in 16:
		var a := TAU * k / 16.0
		StructureKit.rod(b, at, at + turn * Vector3(cos(a), 0, sin(a)) * r, 0.4, c.grey)
	b.drum(1.5, 5, at, c.orange, turn)
	for x in [-31.2, 31.2]:
		for z in range(-18, 19, 6):
			b.box(Vector3(0.12, 1.2, 2.4), Vector3(x, 2.5, z), c.orange, 0.02)
