class_name SurveyorLooks
extends RefCounted
## You: the Surveyor in a Tilg & Standard field suit, in the game's own kit
## (Paint.Pieces, the worn shader), as the lab worked it out (kit pieces
## bound rigidly to their bones; lab/anim on codex/ai-anim-pipeline). Bone
## white, gunmetal where it bends, teal trim to match a teal pack banded in
## safety yellow, black boots. Plain shapes that read at a glance; little
## detail to fuss over. Body poses the parts; each is built about its own joint,
## hanging straight down (limbs) or standing up (the trunk) as it does at rest.
## Metres; front -Z, up +Y, your right +X.

## Where each joint stands at rest, feet on the sand at the origin; the left
## side is the right's mirror.
const HIPS := Vector3(0.0, 0.98, 0.0)
const WAIST := Vector3(0.0, 1.16, 0.0)
const NECK := Vector3(0.0, 1.56, -0.01)
const SHOULDER := Vector3(0.155, 1.46, 0.0)
const ELBOW := Vector3(0.195, 1.18, 0.03)
const WRIST := Vector3(0.215, 0.93, -0.01)
## An authored free-hand reach during a climb, mirrored for the left side.
const CLIMB_HAND := Vector3(0.205, 1.48, -0.52)
const HIP := Vector3(0.1, 0.93, 0.0)
const KNEE := Vector3(0.11, 0.51, -0.02)
const ANKLE := Vector3(0.11, 0.1, 0.02)

const SUIT := Color(0.8, 0.76, 0.66)
const SUIT_SHADE := Color(0.7, 0.66, 0.57)
const PACK := Paint.TEAL
const VISOR := Color(0.12, 0.16, 0.2)

static var _made := {}


static func _coats() -> Dictionary:
	return {"suit": Paint.coat(SUIT, 0.5, 0.0, 0.75), "shade": Paint.coat(SUIT_SHADE, 0.5, 0.0, 0.8),
		"joint": Paint.coat(Paint.GUNMETAL, 0.7, 0.5, 0.5), "black": Paint.coat(Paint.BLACK, 0.4, 0.0, 0.8),
		"pack": Paint.coat(PACK, 0.9, 0.0, 0.55), "trim": Paint.coat(PACK, 0.6, 0.0, 0.7), "band": Paint.coat(Paint.YELLOW, 0.8, 0.0, 0.5),
		"steel": Paint.coat(Paint.STEEL, 0.4, 0.6, 0.35), "glove": Paint.coat(Color(0.3, 0.29, 0.27), 0.4, 0.0, 0.85),
		"visor": Paint.coat(VISOR, 0.0, 0.6, 0.08, 0.0, 0.15), "lamp": Paint.coat(Color(1.0, 0.88, 0.7), 0.0, 0.0, 0.3, 0.0, 1.0),
		"readout": Paint.coat(Color(1.0, 0.62, 0.2), 0.0, 0.0, 0.3, 0.0, 1.6)}


## A part's mesh, by name: &"hips", &"trunk", &"collar", &"head", and per side (&"r" or
## &"l"): &"upper_arm_r", &"forearm_r", &"hand_r", &"thigh_r", &"shin_r", &"foot_r".
static func part(name: StringName) -> ArrayMesh:
	if _made.has(name):
		return _made[name]
	var c := _coats()
	var b := Paint.Pieces.new()
	var s := name.get_slice("_", name.get_slice_count("_") - 1)
	var side := -1.0 if s == "l" else 1.0
	match name:
		&"hips":
			_hips(b, c)
		&"trunk":
			_trunk(b, c)
		&"collar":
			_collar(b, c)
		&"head":
			_head(b, c)
		_:
			match name.trim_suffix("_" + s):
				"upper_arm":
					_upper_arm(b, c, side)
				"forearm":
					_forearm(b, c, side)
				"hand":
					_hand(b, c, side)
				"thigh":
					_thigh(b, c, side)
				"shin":
					_shin(b, c, side)
				"foot":
					_foot(b, c, side)
	_made[name] = b.commit()
	return _made[name]


## About the hips' joint: the seat, a gunmetal belt with its buckle and two
## pouches.
static func _hips(b: Paint.Pieces, c: Dictionary) -> void:
	b.box(Vector3(0.31, 0.2, 0.21), Vector3(0.0, -0.02, 0.0), c.suit, 0.05)
	b.box(Vector3(0.33, 0.06, 0.23), Vector3(0.0, 0.07, 0.0), c.joint, 0.012)
	b.box(Vector3(0.07, 0.05, 0.02), Vector3(0.0, 0.07, -0.12), c.steel, 0.006)
	for x in [-1, 1]:
		b.box(Vector3(0.07, 0.09, 0.05), Vector3(x * 0.125, 0.02, -0.085), c.shade, 0.012)


## About the waist: the bellows the suit bends at (a teal one in the middle),
## the chest plate, the pack on its back (teal, banded, finned).
static func _trunk(b: Paint.Pieces, c: Dictionary) -> void:
	for i in 3:
		b.box(Vector3(0.25 - i * 0.01, 0.035, 0.18), Vector3(0.0, 0.02 + i * 0.045, 0.0), c.trim if i == 1 else c.shade, 0.012)
	# Cut lean through the chest (gonkhub, 2026-10-21): a fitted suit, not a barrel.
	b.box(Vector3(0.3, 0.3, 0.19), Vector3(0.0, 0.27, 0.0), c.suit, 0.055)
	# The chest plate, lying flat on it.
	b.box(Vector3(0.2, 0.16, 0.014), Vector3(0.0, 0.3, -0.099), c.suit, 0.006)
	# The pack.
	b.box(Vector3(0.28, 0.42, 0.15), Vector3(0.0, 0.2, 0.17), c.pack, 0.04)
	b.box(Vector3(0.3, 0.05, 0.16), Vector3(0.0, 0.34, 0.17), c.band, 0.008)
	for i in 3:
		b.box(Vector3(0.22, 0.01, 0.02), Vector3(0.0, 0.05 + i * 0.035, 0.25), c.joint, 0.002)



## About the waist too: what sits round your eyes, drawn for its shadow and
## for others (Body puts it on your helmet's layer): the teal collar ring
## the helmet locks to, the shoulder yokes, the pack's top and the hose from
## it over your shoulder to the collar.
static func _collar(b: Paint.Pieces, c: Dictionary) -> void:
	for x in [-1, 1]:
		b.box(Vector3(0.09, 0.065, 0.19), Vector3(x * 0.13, 0.39, 0.0), c.joint, 0.02)
	b.ring(0.095, 0.12, Vector3(0.0, 0.42, -0.01), c.trim, Basis.IDENTITY, 16)
	b.drum(0.03, 0.12, Vector3(0.11, 0.42, 0.18), c.joint, Basis.IDENTITY, 10)
	for i in 5:
		var t := i / 4.0
		var at := Vector3(0.11 - t * 0.05, 0.48 + sin(t * PI) * 0.03, 0.18 - t * 0.17)
		b.drum(0.022, 0.05, at, c.black, Basis(Vector3.RIGHT, PI / 2.0 - t * 0.6), 8)


## About the neck: the helmet, one rounded shell with a wide dark visor and
## a small lamp on its right (where the headlamp shines from).
static func _head(b: Paint.Pieces, c: Dictionary) -> void:
	b.box(Vector3(0.26, 0.31, 0.3), Vector3(0.0, 0.18, -0.02), c.suit, 0.075)
	b.box(Vector3(0.22, 0.1, 0.05), Vector3(0.0, 0.18, -0.155), c.visor, 0.025)
	b.box(Vector3(0.035, 0.025, 0.012), Vector3(0.07, 0.255, -0.17), c.lamp, 0.004)
	b.drum(0.06, 0.04, Vector3(0.0, 0.0, -0.01), c.joint, Basis.IDENTITY, 14)


## About the shoulder, down the arm: a sleeve, a gunmetal ring at the joint.
static func _upper_arm(b: Paint.Pieces, c: Dictionary, side: float) -> void:
	var down := (ELBOW - SHOULDER)
	b.ball(0.065, Vector3.ZERO, c.joint)
	b.box(Vector3(0.105, down.length() - 0.04, 0.105), Vector3(0.0, -down.length() * 0.5, 0.0), c.suit, 0.032)
	b.box(Vector3(0.11, 0.03, 0.11), Vector3(0.0, -0.06, 0.0), c.band if side > 0.0 else c.shade, 0.008)


## About the elbow, down to the wrist: the pad at the elbow, the cuffed
## forearm; on the left, the wrist readout, glowing amber, where you'd glance.
static func _forearm(b: Paint.Pieces, c: Dictionary, side: float) -> void:
	var long := (WRIST - ELBOW).length()
	b.ball(0.06, Vector3.ZERO, c.joint)
	b.box(Vector3(0.07, 0.07, 0.04), Vector3(0.0, -0.01, 0.055), c.joint, 0.015)
	b.box(Vector3(0.095, long - 0.03, 0.095), Vector3(0.0, -long * 0.5, 0.0), c.suit, 0.028)
	b.box(Vector3(0.11, 0.05, 0.11), Vector3(0.0, -long + 0.03, 0.0), c.joint, 0.012)
	if side < 0.0:
		# Worn on the back of the wrist, turned up to read.
		b.box(Vector3(0.03, 0.09, 0.07), Vector3(-0.05, -long + 0.09, -0.005), c.black, 0.008)
		b.box(Vector3(0.006, 0.06, 0.05), Vector3(-0.066, -long + 0.09, -0.005), c.readout, 0.002)


## About the wrist: a work glove, half closed, its palm facing in (toward
## your middle) and its fingers ready to grip; a gunmetal knuckle guard.
static func _hand(b: Paint.Pieces, c: Dictionary, side: float) -> void:
	b.box(Vector3(0.05, 0.09, 0.095), Vector3(0.0, -0.05, -0.005), c.glove, 0.015)
	b.box(Vector3(0.054, 0.025, 0.09), Vector3(0.0, -0.085, -0.005), c.joint, 0.006)
	# Four fingers, two joints each, curled toward the palm.
	for i in 4:
		var z := -0.04 + i * 0.026
		var root := Vector3(0.0, -0.095, z)
		var curl := 0.5 + i * 0.08
		var first := Basis(Vector3.FORWARD, -curl * side)
		b.box(Vector3(0.024, 0.045, 0.022), root + first * Vector3(0.0, -0.022, 0.0), c.glove, 0.006, first)
		var second := Basis(Vector3.FORWARD, -curl * 2.0 * side)
		var tip := root + first * Vector3(0.0, -0.045, 0.0)
		b.box(Vector3(0.022, 0.035, 0.02), tip + second * Vector3(0.0, -0.017, 0.0), c.glove, 0.006, second)
	# The thumb, across the front of the palm.
	var thumb := Basis(Vector3.RIGHT, 0.7) * Basis(Vector3.FORWARD, -0.5 * side)
	b.box(Vector3(0.026, 0.06, 0.024), Vector3(-0.025 * side, -0.06, -0.05), c.glove, 0.007, thumb)


## About the hip, down the thigh: the leg, a pocket on its side.
static func _thigh(b: Paint.Pieces, c: Dictionary, side: float) -> void:
	var long := (KNEE - HIP).length()
	b.box(Vector3(0.145, long - 0.02, 0.155), Vector3(0.0, -long * 0.5, 0.0), c.suit, 0.042)
	b.box(Vector3(0.03, 0.12, 0.09), Vector3(side * 0.082, -long * 0.45, -0.01), c.shade, 0.01)


## About the knee, down the shin: a teal knee pad, the plain shin.
static func _shin(b: Paint.Pieces, c: Dictionary, side: float) -> void:
	var long := (ANKLE - KNEE).length()
	b.ball(0.075, Vector3.ZERO, c.joint)
	b.box(Vector3(0.095, 0.11, 0.05), Vector3(0.0, -0.02, -0.07), c.trim, 0.02)
	b.box(Vector3(0.12, long - 0.06, 0.13), Vector3(0.0, -long * 0.5, 0.0), c.suit, 0.038)


## About the ankle: a boot, its cuff, a black sole, a gunmetal toe cap.
static func _foot(b: Paint.Pieces, c: Dictionary, side: float) -> void:
	b.box(Vector3(0.14, 0.09, 0.15), Vector3(0.0, -0.01, 0.0), c.black, 0.025)
	b.box(Vector3(0.13, 0.08, 0.17), Vector3(0.0, -0.05, -0.1), c.black, 0.03)
	b.box(Vector3(0.14, 0.03, 0.3), Vector3(0.0, -0.09, -0.05), Paint.coat(Color(0.05, 0.05, 0.05), 0.3, 0.0, 0.9), 0.01)
	b.box(Vector3(0.12, 0.05, 0.05), Vector3(0.0, -0.05, -0.18), c.joint, 0.015)
	b.box(Vector3(0.145, 0.025, 0.14), Vector3(0.0, 0.045, 0.0), c.joint, 0.008)


## Two plaited turns follow the real belt above the hips. Shared with every waist tie.
static func waist_wrap() -> ArrayMesh:
	if _made.has(&"waist_wrap"):
		return _made[&"waist_wrap"]
	var b := Paint.Pieces.new()
	var rules := Tuning.current().rope_coil_visual
	var fibre := Paint.coat(Paint.ROPE.lightened(0.14), 0.0, 0.0, 0.95, 0.35)
	var binding := Paint.coat(Paint.TEAL.darkened(0.24), 0.0, 0.0, 0.95, 0.25)
	for strand in int(rules.end_strands):
		var phase := float(strand) * TAU / float(rules.end_strands)
		for i in 96:
			var ends: Array[Vector3] = []
			for t in [float(i) / 96.0, float(i + 1) / 96.0]:
				var angle: float = t * TAU * 2.0
				var radius := Vector3(sin(angle), 0.0, -cos(angle))
				var at := Vector3(radius.x * 0.215, 0.045 + t * 0.05, radius.z * 0.16)
				var twist: float = phase + t * float(rules.fibre_turns) * TAU
				ends.append(at + (radius * cos(twist) + Vector3.UP * sin(twist)) * float(rules.end_strand_orbit))
			var span := ends[1] - ends[0]
			b.drum(float(rules.end_strand_radius), span.length(), (ends[0] + ends[1]) * 0.5, fibre,
				Basis(Quaternion(Vector3.UP, span.normalized())), int(rules.sides))
	# A small crossing and muted whipping make the forward tie readable.
	b.drum(float(rules.gauge), 0.065, Vector3(0, 0.07, -0.17), fibre, Basis(Vector3.FORWARD, PI * 0.5), int(rules.sides))
	for x in [-0.022, -0.014, 0.014, 0.022]:
		b.drum(float(rules.end_wrap_radius), float(rules.end_wrap_width), Vector3(x, 0.07, -0.17), binding,
			Basis(Vector3.FORWARD, PI * 0.5), int(rules.sides))
	_made[&"waist_wrap"] = b.commit()
	return _made[&"waist_wrap"]


## A short laid lead, stretched only visually between the belt knot and its real tie point.
static func waist_lead() -> ArrayMesh:
	if _made.has(&"waist_lead"):
		return _made[&"waist_lead"]
	var b := Paint.Pieces.new()
	var rules := Tuning.current().rope_coil_visual
	var fibre := Paint.coat(Paint.ROPE.lightened(0.14), 0.0, 0.0, 0.95, 0.35)
	for strand in int(rules.end_strands):
		var phase := float(strand) * TAU / float(rules.end_strands)
		for i in int(rules.end_sections):
			var ends: Array[Vector3] = []
			for t in [float(i) / float(rules.end_sections), float(i + 1) / float(rules.end_sections)]:
				var angle: float = phase + t * float(rules.end_twists) * TAU
				ends.append(Vector3(cos(angle) * float(rules.end_strand_orbit), t,
					sin(angle) * float(rules.end_strand_orbit)))
			var span := ends[1] - ends[0]
			b.drum(float(rules.end_strand_radius), span.length(), (ends[0] + ends[1]) * 0.5, fibre,
				Basis(Quaternion(Vector3.UP, span.normalized())), int(rules.sides))
	_made[&"waist_lead"] = b.commit()
	return _made[&"waist_lead"]
