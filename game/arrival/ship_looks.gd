class_name ShipLooks
extends RefCounted
## A modest contractor departure cabin, using the same worn industrial pieces as its kit.

static func boxes() -> Array:
	# [size, center, basis]: every solid architectural piece has the same drawn skin.
	var out := [
		[Vector3(6.4, 0.18, 8.4), Vector3(0, -0.09, -1), Basis.IDENTITY],
		[Vector3(6.4, 0.16, 8.4), Vector3(0, 3.08, -1), Basis.IDENTITY],
		[Vector3(0.18, 3.0, 8.4), Vector3(-3.11, 1.5, -1), Basis.IDENTITY],
		[Vector3(0.18, 3.0, 8.4), Vector3(3.11, 1.5, -1), Basis.IDENTITY],
		[Vector3(6.4, 3.0, 0.18), Vector3(0, 1.5, 3.11), Basis.IDENTITY],
		[Vector3(6.4, 0.8, 0.18), Vector3(0, 0.4, -5.11), Basis.IDENTITY],
		[Vector3(6.4, 0.4, 0.18), Vector3(0, 2.8, -5.11), Basis.IDENTITY],
		[Vector3(0.9, 1.8, 0.18), Vector3(-2.75, 1.7, -5.11), Basis.IDENTITY],
		[Vector3(0.9, 1.8, 0.18), Vector3(2.75, 1.7, -5.11), Basis.IDENTITY],
		[Vector3(1.05, 0.06, 0.86), Vector3(1.4, 0.12, 1.2), Basis(Vector3.RIGHT, atan(0.24 / 0.86))],
		[Vector3(0.9, 0.7, 0.65), Vector3(-1.8, 0.35, -3.65), Basis.IDENTITY],
		[Vector3(0.95, 0.12, 0.7), Vector3(-1.8, 0.76, -3.65), Basis.IDENTITY],
	]
	for z in [-0.4, 1.6]:
		out.append([Vector3(0.07, 2.2, 0.07), Vector3(-2.9, 1.1, z), Basis.IDENTITY])
		out.append([Vector3(0.07, 2.2, 0.07), Vector3(-2.02, 1.1, z), Basis.IDENTITY])
	for y in [0.18, 1.05, 2.15]:
		out.append([Vector3(0.95, 0.08, 2.1), Vector3(-2.47, y, 0.6), Basis.IDENTITY])
	return out


static func mesh() -> ArrayMesh:
	var b := Paint.Pieces.new()
	var bone := Paint.coat(Paint.BONE, 0.4, 0.6, 0.65)
	var gun := Paint.coat(Paint.GUNMETAL, 0.7, 0.5, 0.65)
	var teal := Paint.coat(Paint.TEAL, 0.6, 0.3, 0.6)
	var black := Paint.coat(Paint.BLACK, 0.4, 0.3, 0.8)
	var yellow := Paint.coat(Paint.YELLOW, 0.7, 0.4, 0.7)
	var amber := Paint.coat(Color(1.0, 0.48, 0.12), 0.0, 0.0, 0.4, 0.0, 0.9)
	var lamp := Paint.coat(Color(1.0, 0.88, 0.65), 0.0, 0.0, 0.3, 0.0, 1.2)
	for item: Array in boxes():
		b.box(item[0], item[1], gun, 0.015, item[2])
	# Separate inset panels leave the ribs readable rather than one featureless wall.
	for z in [-4.0, -2.0, 0.0, 2.0]:
		for side in [-1.0, 1.0]:
			b.box(Vector3(0.025, 2.62, 1.75), Vector3(side * 3.006, 1.5, z), bone, 0.04)
			b.box(Vector3(0.035, 0.18, 1.68), Vector3(side * 2.985, 0.42, z), teal, 0.012)
			b.box(Vector3(0.06, 0.05, 1.4), Vector3(side * 2.96, 2.66, z), lamp, 0.01)
		for x in [-2.0, 0.0, 2.0]:
			b.box(Vector3(1.85, 0.025, 1.85), Vector3(x, 0.016, z), black, 0.018)
			b.box(Vector3(1.84, 0.025, 1.84), Vector3(x, 2.987, z), bone, 0.025)
	for x in [-0.4, 2.2]:
		b.box(Vector3(0.05, 0.008, 3.6), Vector3(x, 0.035, 0.3), yellow, 0.002)
	# Window jambs and a broad sill: the renderer fills only the real aperture.
	for x in [-2.34, 2.34]:
		b.box(Vector3(0.14, 1.98, 0.3), Vector3(x, 1.7, -4.99), gun, 0.025)
	for y in [0.76, 2.64]:
		b.box(Vector3(4.82, 0.13, 0.3), Vector3(0, y, -4.99), gun, 0.02)
	b.box(Vector3(4.7, 0.07, 0.48), Vector3(0, 0.77, -4.83), teal, 0.015)
	# The launch station's angled glass, bezel, recessed keys and mechanical consent lever.
	var tilt := Basis(Vector3.RIGHT, -0.25)
	var screen := Vector3(-1.8, 1.03, -3.73)
	b.box(Vector3(0.88, 0.49, 0.14), screen, bone, 0.035, tilt)
	b.box(Vector3(0.72, 0.34, 0.018), screen + tilt * Vector3(0, 0, 0.077), black, 0.012, tilt)
	for i in 4:
		b.box(Vector3(0.49 - i * 0.07, 0.012, 0.006), screen + tilt * Vector3(-0.045, 0.105 - i * 0.055, 0.089), amber, 0.001, tilt)
	for x in [-1.98, -1.84, -1.7]:
		b.box(Vector3(0.09, 0.025, 0.06), Vector3(x, 0.84, -3.4), black, 0.006)
	b.box(Vector3(0.07, 0.13, 0.06), Vector3(-1.48, 0.88, -3.44), yellow, 0.008, Basis(Vector3.RIGHT, -0.3))
	# Staging rack: teal back and six thin retaining bars, not fictitious cargo.
	b.box(Vector3(0.025, 2.05, 2.05), Vector3(-2.96, 1.15, 0.6), teal, 0.02)
	for y in [0.35, 1.22]:
		for z in [-0.05, 0.6, 1.25]:
			b.box(Vector3(0.03, 0.14, 0.03), Vector3(-2.0, y, z), yellow, 0.006)
	# Rear retainers hold the real removed pod panels upright.
	for x in [-0.65, 0.55, 1.75]:
		b.box(Vector3(1.08, 0.09, 0.32), Vector3(x, 0.08, 2.7), gun, 0.015)
		b.box(Vector3(0.08, 0.12, 0.14), Vector3(x - 0.46, 0.15, 2.54), yellow, 0.006)
		b.box(Vector3(0.08, 0.12, 0.14), Vector3(x + 0.46, 0.15, 2.54), yellow, 0.006)
	return b.commit()
