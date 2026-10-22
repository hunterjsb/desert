class_name ShipLooks
extends RefCounted
## A modest contractor departure cabin, using the same worn industrial pieces as its kit.

const WINDOW_AT := Vector3(0, 1.44, -5.0)
const WINDOW_SIZE := Vector2(4.6, 2.28)
const COMPUTER_AT := Vector3(-1.8, 1.35, -3.73)
const COMPUTER_TILT := Basis(Vector3.RIGHT, -0.25)
const COMPUTER_SIZE := Vector3(1.34, 0.88, 0.14)
const DISPLAY_SIZE := Vector2(1.15, 0.68)

static func boxes() -> Array:
	# [size, center, basis]: every solid architectural piece has the same drawn skin.
	var out := [
		[Vector3(6.4, 0.18, 8.4), Vector3(0, -0.09, -1), Basis.IDENTITY],
		[Vector3(6.4, 0.16, 8.4), Vector3(0, 3.08, -1), Basis.IDENTITY],
		[Vector3(0.18, 3.0, 8.4), Vector3(-3.11, 1.5, -1), Basis.IDENTITY],
		[Vector3(0.18, 3.0, 8.4), Vector3(3.11, 1.5, -1), Basis.IDENTITY],
		[Vector3(6.4, 3.0, 0.18), Vector3(0, 1.5, 3.11), Basis.IDENTITY],
		[Vector3(6.4, 0.30, 0.18), Vector3(0, 0.15, -5.11), Basis.IDENTITY],
		[Vector3(6.4, 0.42, 0.18), Vector3(0, 2.79, -5.11), Basis.IDENTITY],
		[Vector3(0.9, 2.28, 0.18), Vector3(-2.75, 1.44, -5.11), Basis.IDENTITY],
		[Vector3(0.9, 2.28, 0.18), Vector3(2.75, 1.44, -5.11), Basis.IDENTITY],
		[Vector3(1.05, 0.06, 0.949), Vector3(1.4, 0.12, 1.8), Basis(Vector3.RIGHT, atan(0.30 / 0.9))],
		[Vector3(1.05, 0.06, 0.8), Vector3(1.4, 0.27, 0.95), Basis.IDENTITY],
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
	var bone := Paint.coat(Paint.BONE, 0.4, 0.25, 0.44, 0.025)
	var gun := Paint.coat(Paint.GUNMETAL, 0.7, 0.65, 0.5, 0.04)
	var teal := Paint.coat(Paint.TEAL, 0.6, 0.3, 0.45, 0.025)
	var black := Paint.coat(Paint.BLACK, 0.4, 0.35, 0.68, 0.06)
	var yellow := Paint.coat(Paint.YELLOW, 0.7, 0.3, 0.5, 0.025)
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
			for rib in 9:
				b.box(Vector3(1.65, 0.004, 0.014), Vector3(x, 0.031, z - 0.72 + rib * 0.18), gun, 0.001)
			b.box(Vector3(1.84, 0.025, 1.84), Vector3(x, 2.987, z), bone, 0.025)
	# Outside, the same pressure compartment has inset service plates and corner guards.
	for z in [-4.0, -2.0, 0.0, 2.0]:
		for side in [-1.0, 1.0]:
			b.box(Vector3(0.045, 2.58, 1.7), Vector3(side * 3.22, 1.5, z), bone, 0.05)
			b.box(Vector3(0.06, 0.24, 1.62), Vector3(side * 3.25, 0.64, z), teal, 0.015)
			for y in [0.36, 2.62]:
				b.box(Vector3(0.075, 0.1, 0.1), Vector3(side * 3.27, y, z - 0.68), gun, 0.012)
		for x in [-2.0, 0.0, 2.0]:
			b.box(Vector3(1.83, 0.045, 1.83), Vector3(x, 3.18, z), bone, 0.045)
	for side in [-1.0, 1.0]:
		b.box(Vector3(0.18, 0.18, 8.3), Vector3(side * 2.85, 3.27, -1), gun, 0.035)
		for z in [-5.05, 3.05]:
			b.box(Vector3(0.22, 2.95, 0.22), Vector3(side * 3.12, 1.5, z), gun, 0.045)
			b.box(Vector3(0.23, 0.28, 0.23), Vector3(side * 3.12, 0.3, z), yellow, 0.03)
	for x in [-1.9, 1.9]:
		b.box(Vector3(1.9, 2.6, 0.035), Vector3(x, 1.5, 3.22), bone, 0.06)
		b.box(Vector3(1.8, 2.6, 0.025), Vector3(x, 1.5, 3.005), bone, 0.04)
	b.box(Vector3(1.25, 2.25, 0.045), Vector3(0, 1.2, 3.23), teal, 0.08)
	b.box(Vector3(0.12, 0.38, 0.09), Vector3(0.38, 1.1, 3.29), gun, 0.018)
	# A bay boundary closes around the actual capsule, opening only at its boarding ramp.
	for x in [0.65, 2.15]:
		b.box(Vector3(0.055, 0.008, 2.65), Vector3(x, 0.038, -0.15), yellow, 0.002)
	for z in [-1.45, 1.18]:
		for x in [0.77, 2.03]:
			b.box(Vector3(0.28, 0.008, 0.055), Vector3(x, 0.038, z), yellow, 0.002)
	for z in [1.65, 1.95]:
		for side in [-1.0, 1.0]:
			b.box(Vector3(0.30, 0.009, 0.04), Vector3(1.4 + side * 0.11, 0.039, z),
				yellow, 0.002, Basis(Vector3.UP, side * -0.5))
	# The lower real sill clears the existing reclined eye.
	for x in [-2.34, 2.34]:
		b.box(Vector3(0.14, 2.46, 0.3), Vector3(x, WINDOW_AT.y, -4.99), gun, 0.025)
	for y in [0.26, 2.62]:
		b.box(Vector3(4.82, 0.13, 0.3), Vector3(0, y, -4.99), gun, 0.02)
	b.box(Vector3(4.7, 0.07, 0.30), Vector3(0, 0.27, -4.89), teal, 0.015)
	# A real live display fills this recess; there is no painted imitation UI.
	b.box(COMPUTER_SIZE, COMPUTER_AT, bone, 0.035, COMPUTER_TILT)
	b.box(Vector3(1.19, 0.72, 0.018), COMPUTER_AT + COMPUTER_TILT * Vector3(0, 0, 0.077), black, 0.012, COMPUTER_TILT)
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
