class_name SurveyReceiverLooks
extends RefCounted
## A survey instrument assembled from cast and screwed parts. Moving
## pieces share the case's worn paint but leave the dial clear to read.

const SIZE := Vector3(0.36, 0.50, 0.26)
const METER_CENTER := Vector3(-0.055, -0.062, 0.086)
const METER_AT := METER_CENTER + Vector3(0.0, -0.027, 0.009)
const KNOB_AT := Vector3(0.103, -0.115, 0.081)
const VOLUME_AT := Vector3(0.105, -0.184, 0.085)
const LOOP_AT := Vector3(0.0, 0.022, 0.0)
const FACE := Vector3(0.0, -0.075, 0.10)
const LAMP_AT := Vector3(0.105, -0.033, 0.091)
const FRONT := Basis(Vector3.RIGHT, PI / 2.0)

static var _frame: ArrayMesh
static var _needle: ArrayMesh
static var _loop: ArrayMesh
static var _knob: ArrayMesh


static func frame() -> ArrayMesh:
	if _frame != null:
		return _frame
	var b := Paint.Pieces.new(-0.25)
	var shell := Paint.coat(Paint.BONE, 0.35, 0.15, 0.74)
	var enamel := Paint.coat(Paint.TEAL, 0.32, 0.15, 0.65)
	var dark := Paint.coat(Paint.GUNMETAL, 0.25, 0.7, 0.54)
	var rubber := Paint.coat(Paint.BLACK, 0.35, 0.0, 0.94)
	var brass := Paint.coat(Paint.BRASS, 0.24, 0.75, 0.43)
	var steel := Paint.coat(Paint.STEEL, 0.18, 0.8, 0.42)
	var paper := Paint.coat(Color(0.88, 0.81, 0.61), 0.08, 0.0, 0.9, 1.0, 0.14)
	var ink := Paint.coat(Color(0.08, 0.12, 0.12), 0.0, 0.0, 0.85)
	# The cast rim protects the recessed face when the instrument is set down.
	b.box(Vector3(0.324, 0.25, 0.15), Vector3(0.0, -0.105, 0.0), shell, 0.026)
	b.box(Vector3(0.282, 0.214, 0.014), Vector3(0.0, -0.105, 0.074), enamel, 0.018)
	for x in [-1.0, 1.0]:
		for y in [-0.204, -0.007]:
			b.box(Vector3(0.043, 0.054, 0.17), Vector3(x * 0.145, y, -0.003), rubber, 0.013)
		b.box(Vector3(0.018, 0.12, 0.044), Vector3(x * 0.163, -0.104, -0.025), dark, 0.008)
		for y in [-0.13, -0.105, -0.08]:
			b.box(Vector3(0.008, 0.009, 0.051), Vector3(x * 0.173, y, -0.025), rubber, 0.003)
	for x in [-0.105, 0.105]:
		b.box(Vector3(0.055, 0.02, 0.10), Vector3(x, -0.24, 0.0), rubber, 0.005)
	# Rear cell cradle, its retaining band and the contacts' protective lip.
	b.box(Vector3(0.232, 0.16, 0.033), Vector3(0.0, -0.105, -0.083), dark, 0.012)
	b.box(Vector3(0.186, 0.127, 0.018), Vector3(0.0, -0.105, -0.105), enamel, 0.008)
	b.box(Vector3(0.025, 0.169, 0.012), Vector3(0.055, -0.105, -0.119), rubber, 0.004)
	b.box(Vector3(0.043, 0.022, 0.015), Vector3(0.055, -0.174, -0.121), brass, 0.003)
	# A circular meter is intentionally the largest readable shape on the face.
	b.drum(0.067, 0.012, METER_CENTER - Vector3(0.0, 0.0, 0.004), dark, FRONT, 40)
	b.drum(0.060, 0.013, METER_CENTER, brass, FRONT, 40)
	b.drum(0.055, 0.014, METER_CENTER + Vector3(0.0, 0.0, 0.002), paper, FRONT, 40)
	for i in 13:
		var angle := deg_to_rad(-60.0 + i * 10.0)
		var major := i % 3 == 0
		var radius := 0.062
		var at := METER_AT + Vector3(sin(angle), cos(angle), 0.0) * radius
		b.box(Vector3(0.0018 if major else 0.0009, 0.009 if major else 0.004, 0.0008), at,
			ink, 0.0, Basis(Vector3.BACK, -angle))
	# Low and strong marks read as shapes without a tiny numeric overlay.
	b.box(Vector3(0.013, 0.002, 0.001), METER_CENTER + Vector3(-0.027, -0.018, 0.010), ink, 0.0)
	for i in 3:
		b.box(Vector3(0.003, 0.003 + i * 0.003, 0.001),
			METER_CENTER + Vector3(0.022 + i * 0.005, -0.019, 0.010), ink, 0.0)
	# A dark grille has the same visible depth as the other inset panels.
	b.box(Vector3(0.134, 0.039, 0.007), Vector3(-0.056, -0.171, 0.083), rubber, 0.005)
	for i in 6:
		b.box(Vector3(0.008, 0.028, 0.008), Vector3(-0.11 + i * 0.021, -0.171, 0.088), dark, 0.002)
	# A knurled collar sits under the tuning wheel; the wheel turns separately.
	b.drum(0.042, 0.012, KNOB_AT - Vector3(0.0, 0.0, 0.002), brass, FRONT, 32)
	b.drum(0.020, 0.008, VOLUME_AT - Vector3(0.0, 0.0, 0.002), brass, FRONT, 24)
	for i in 3:
		b.box(Vector3(0.002, 0.004 + i * 0.003, 0.001), Vector3(0.069 + i * 0.005, -0.184, 0.090), ink, 0.0)
	b.drum(0.010, 0.010, LAMP_AT, dark, FRONT, 16)
	b.drum(0.0065, 0.011, LAMP_AT + Vector3(0.0, 0.0, 0.002),
		Paint.coat(Color(0.77, 0.37, 0.07), 0.08, 0.1, 0.35, 1.0, 0.8), FRONT, 16)
	# The loop hinges between two cast lugs, not in empty space.
	for x in [-1.0, 1.0]:
		b.box(Vector3(0.041, 0.024, 0.054), Vector3(x * 0.072, 0.021, 0.0), dark, 0.006)
		b.drum(0.013, 0.046, Vector3(x * 0.072, 0.031, 0.0), brass,
			Basis(Vector3.FORWARD, PI / 2.0), 16)
	# A contractor's plate and two screws finish the right shoulder.
	b.stamp(Paint.Mark.CONTRACTOR, Vector3(0.101, -0.067, 0.092), 0.053)
	b.box(Vector3(0.065, 0.023, 0.006), Vector3(0.101, -0.067, 0.086), shell, 0.003)
	for x in [-0.125, 0.125]:
		for y in [-0.19, -0.018]:
			b.drum(0.0045, 0.004, Vector3(x, y, 0.086), steel, FRONT, 12)
			b.box(Vector3(0.005, 0.0012, 0.0008), Vector3(x, y, 0.089), ink, 0.0)
	_frame = b.commit()
	return _frame


static func needle() -> ArrayMesh:
	if _needle == null:
		var b := Paint.Pieces.new()
		b.box(Vector3(0.0018, 0.062, 0.0015), Vector3(0.0, 0.028, 0.0),
			Paint.coat(Color(0.73, 0.105, 0.045), 0.0, 0.3, 0.4), 0.0003)
		b.drum(0.006, 0.003, Vector3.ZERO, Paint.coat(Paint.GUNMETAL, 0.0, 0.7), FRONT, 16)
		_needle = b.commit()
	return _needle


static func knob() -> ArrayMesh:
	if _knob == null:
		var b := Paint.Pieces.new()
		var rubber := Paint.coat(Paint.BLACK, 0.22, 0.0, 0.8)
		b.drum(0.034, 0.028, Vector3(0.0, 0.0, 0.015), rubber, FRONT, 32)
		for i in 24:
			var angle := TAU * i / 24.0
			b.box(Vector3(0.004, 0.008, 0.025), Vector3(sin(angle) * 0.033, cos(angle) * 0.033, 0.015),
				rubber, 0.001, Basis(Vector3.BACK, -angle))
		b.drum(0.025, 0.005, Vector3(0.0, 0.0, 0.031), Paint.coat(Paint.GUNMETAL, 0.15, 0.6), FRONT, 32)
		b.box(Vector3(0.003, 0.015, 0.002), Vector3(0.0, 0.013, 0.035), Paint.coat(Paint.BONE, 0.05), 0.0005)
		_knob = b.commit()
	return _knob


static func loop() -> ArrayMesh:
	if _loop == null:
		var b := Paint.Pieces.new()
		var dark := Paint.coat(Paint.GUNMETAL, 0.3, 0.8, 0.5)
		var brass := Paint.coat(Paint.BRASS, 0.23, 0.8, 0.5)
		for x in [-1.0, 1.0]:
			b.box(Vector3(0.014, 0.095, 0.018), Vector3(x * 0.073, 0.039, 0.0), dark, 0.004)
		b.ring(0.077, 0.091, Vector3(0.0, 0.122, 0.0), dark, FRONT, 12)
		b.ring(0.080, 0.084, Vector3(0.0, 0.122, 0.010), brass, FRONT, 10)
		b.box(Vector3(0.045, 0.017, 0.022), Vector3(0.0, 0.207, 0.0), Paint.coat(Paint.BONE, 0.2), 0.004)
		b.box(Vector3(0.009, 0.12, 0.006), Vector3(0.0, 0.09, 0.0), brass, 0.002)
		_loop = b.commit()
	return _loop
