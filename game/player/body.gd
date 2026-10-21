class_name Body
extends Node3D
## Your body, as you see it looking down and as its shadow falls: the
## Surveyor's suit (SurveyorLooks), its pieces rigid on their joints, posed
## each frame from how you're moving. Your legs stride as you walk (a
## footfall each half stride, as Feel's steps fall), bend as you crouch and
## fold under you sat; lying down you're stretched out behind your eyes.
## Holding something, your hands go to it; empty, your arms swing against
## your stride. Your helmet and what rings your eyes (its collar, the
## shoulder yokes) are drawn for their shadow and for others only, on a
## layer your own eyes skip. It's only looks: no shapes, nothing to hit. A child of the player.

## Your helmet's layer, which your camera leaves out.
const OWN_LAYER := 1 << 17
## Each limb's length, m, joint to joint.
const UPPER_ARM := 0.28
const FOREARM := 0.25
const THIGH := 0.42
const SHIN := 0.41
## Where the hand grips, m below the wrist along the hand.
const GRIP := 0.08
## Your eyes stand this far in front of your trunk's middle, m: looking down
## you see your chest, not into it.
const EYES_AHEAD := 0.24
## Your stride: how far the swinging foot lifts, m, and how far your hips sway
## and your arms swing, rad, at a walk; more at a run.
const LIFT := 0.09
const ARM_SWING := Vector2(0.25, 0.6)
## Looking down or up, your trunk leans with your head this share of it.
const LEAN := 0.1
## The legs and arms ease toward a new pose in about this long, s.
const EASE := 0.12

var player: Player
var _parts := {}
var _phase := 0.0
var _feet := [Vector3.ZERO, Vector3.ZERO]
var _hands := [Vector3.ZERO, Vector3.ZERO]
var _settled := false


func _ready() -> void:
	player = get_parent() as Player
	for name: StringName in [&"hips", &"trunk", &"collar", &"head", &"upper_arm_r", &"forearm_r", &"hand_r", &"upper_arm_l",
			&"forearm_l", &"hand_l", &"thigh_r", &"shin_r", &"foot_r", &"thigh_l", &"shin_l", &"foot_l"]:
		var view := MeshInstance3D.new()
		view.name = String(name)
		view.mesh = SurveyorLooks.part(name)
		add_child(view)
		view.set_instance_shader_parameter(&"age", Paint.ERA_NEW)
		_parts[name] = view
	for name: StringName in [&"head", &"collar"]:
		(_parts[name] as MeshInstance3D).layers = OWN_LAYER
	if player != null and player.camera != null:
		player.camera.cull_mask &= ~OWN_LAYER


func _process(delta: float) -> void:
	if player == null:
		return
	# Thrown and tumbling, or flying about in the dev's way, there's no pose
	# that stays out of your eyes.
	visible = player.tumble == null and not player.flying
	if not visible:
		_settled = false
		return
	pose(delta)


## Sets every piece from how you're moving now; `delta` 0 snaps to it.
func pose(delta: float) -> void:
	var tuning := Tuning.current()
	var own := Vector3(player.own.x, 0.0, player.own.y)
	if player.ride != null:
		own = Vector3.ZERO
	var moving := player.global_basis.inverse() * own
	var speed := moving.length()
	if speed > 0.1 and player.is_on_floor():
		_phase += speed * delta / Feel.stride(speed) * PI
	var pace := clampf((speed - tuning.walk_speed) / maxf(tuning.sprint_speed - tuning.walk_speed, 0.1), 0.0, 1.0)
	var pitch := player.camera.rotation.x
	var rest_eye: float = player.posture.standing_eye
	var drop := clampf(rest_eye - player.camera.position.y, 0.0, rest_eye - 0.2)
	var prone := player.ground_pose == &"prone"
	var sat := player.ground_pose == &"sit" or (player.helm != null and player.helm.sits)
	# The trunk: from the hips, leaning with your look, set back of your eyes.
	var lean := Basis(Vector3.RIGHT, pitch * LEAN)
	var hips_at := Vector3(0.0, SurveyorLooks.HIPS.y - drop, EYES_AHEAD)
	var turn := lean
	if prone:
		# Face down, stretched out behind your eyes.
		turn = Basis(Vector3.RIGHT, -PI * 0.5)
		hips_at = Vector3(0.0, 0.16, 0.62)
	elif sat:
		hips_at = Vector3(0.0, SurveyorLooks.HIPS.y - drop - 0.05, EYES_AHEAD + 0.05)
	var waist := hips_at + turn * (SurveyorLooks.WAIST - SurveyorLooks.HIPS)
	_put(&"hips", turn, hips_at)
	_put(&"trunk", turn, waist)
	_put(&"collar", turn, waist)
	_put(&"head", turn, waist + turn * (SurveyorLooks.NECK - SurveyorLooks.WAIST))
	# The legs: each foot planted or swinging, the knee bent to reach it.
	for i in 2:
		var side := 1.0 if i == 0 else -1.0
		var hip := hips_at + turn * (Vector3(SurveyorLooks.HIP.x * side, SurveyorLooks.HIP.y, SurveyorLooks.HIP.z)
			- SurveyorLooks.HIPS)
		var foot: Vector3
		var knee_way := turn * Vector3.FORWARD
		if prone:
			foot = hip + turn * Vector3(0.02 * side, -(THIGH + SHIN) * 0.97, 0.0)
			knee_way = Vector3.DOWN
		elif sat:
			foot = Vector3(0.16 * side, 0.08, -0.5)
			knee_way = Vector3.UP
		else:
			var phase := _phase + (0.0 if i == 0 else PI)
			var stride := Feel.stride(maxf(speed, 0.1)) if speed > 0.1 else 0.0
			var way := moving.normalized() if speed > 0.1 else Vector3.FORWARD
			var reach := way * (-cos(phase) * stride * 0.5)
			var lift := maxf(sin(phase), 0.0) * LIFT * minf(speed, 1.0) * (1.0 + pace)
			foot = Vector3(SurveyorLooks.ANKLE.x * side, SurveyorLooks.ANKLE.y + lift, EYES_AHEAD) + reach
			if not player.is_on_floor() and player.ride == null:
				# In the air your legs gather under you.
				foot += Vector3(0.0, 0.18, -0.05)
			if player.ride != null:
				# On the board: feet apart along it, knees soft.
				foot = Vector3(0.12 * side, SurveyorLooks.ANKLE.y, EYES_AHEAD - 0.22 * side)
		_feet[i] = foot if delta <= 0.0 or not _settled else _feet[i].lerp(foot, minf(delta / EASE, 1.0))
		var bones := _reach(hip, _feet[i], THIGH, SHIN, knee_way)
		var s := "r" if i == 0 else "l"
		_put(StringName("thigh_" + s), bones[0], hip)
		_put(StringName("shin_" + s), bones[1], bones[2])
		# Lying face down, toes dig into the sand.
		var flat := turn if prone else Basis.IDENTITY
		_put(StringName("foot_" + s), flat, bones[3])
	# The arms: to what you hold, or swinging against your stride.
	var held := player.hands.held if player.hands != null else null
	for i in 2:
		var side := 1.0 if i == 0 else -1.0
		var shoulder := waist + turn * (Vector3(SurveyorLooks.SHOULDER.x * side, SurveyorLooks.SHOULDER.y,
			SurveyorLooks.SHOULDER.z) - SurveyorLooks.WAIST)
		var grip_at := _grips(held, shoulder)
		var hand: Vector3
		if grip_at.size() > i:
			hand = grip_at[i]
		elif prone:
			hand = shoulder + Vector3(0.12 * side, -0.12, -0.32)
		else:
			var swing := sin(_phase + (PI if i == 0 else 0.0)) * lerpf(ARM_SWING.x, ARM_SWING.y, pace) \
				* minf(speed, 1.0)
			var hang := Basis(Vector3.RIGHT, swing) * Vector3(0.05 * side, -(UPPER_ARM + FOREARM + GRIP) * 0.96, 0.0)
			hand = shoulder + turn * hang
			if sat:
				hand = Vector3(0.18 * side, hips_at.y + 0.05, -0.18)
		_hands[i] = hand if delta <= 0.0 or not _settled else _hands[i].lerp(hand, minf(delta / EASE, 1.0))
		var elbow_way := (turn * Vector3(0.4 * side, -0.3, 1.0)).normalized()
		var arm := _reach(shoulder, _hands[i], UPPER_ARM, FOREARM + GRIP, elbow_way)
		var s := "r" if i == 0 else "l"
		_put(StringName("upper_arm_" + s), arm[0], shoulder)
		_put(StringName("forearm_" + s), arm[1], arm[2])
		_put(StringName("hand_" + s), arm[1], arm[2] + arm[1] * Vector3(0.0, -FOREARM, 0.0))
	_settled = true


## Where your hands grip what you hold, in this node's space: either side
## of it, as wide as it is (its drawn pieces' bounds); a small thing in your
## right hand alone. Tools use their handle; chassis use this shoulder's
## nearest physical frame surface.
func _grips(held: Node3D, shoulder := Vector3.ZERO) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if held == null or not is_instance_valid(held):
		return out
	if held is Cutter:
		# Dress puts the handle under the rear of the lance, not beside its barrel.
		out.append(to_local(held.to_global(Vector3(0.0, -0.04, 0.16))))
		return out
	if held is Chassis:
		# Each real frame is a surface; the empty space between joined frames isn't.
		var nearest := Vector3.ZERO
		var distance := INF
		var from := to_global(shoulder)
		for child in held.get_children():
			var shape := child as CollisionShape3D
			if shape == null or shape.disabled or shape.has_meta(&"socket") or not (shape.shape is BoxShape3D):
				continue
			var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
			var local := shape.to_local(from)
			var surface := local.clamp(-half, half)
			if surface == local:
				# A large carried frame can surround the shoulder; still choose its skin.
				var axis := (half - local.abs()).min_axis_index()
				surface[axis] = half[axis] if local[axis] >= 0.0 else -half[axis]
			var at := shape.to_global(surface)
			var far := from.distance_squared_to(at)
			if far < distance:
				distance = far
				nearest = to_local(at)
		if distance < INF:
			# The caller supplies this arm's shoulder, so both entries are its own grip.
			return [nearest, nearest]
	var wide := 0.0
	for child in held.get_children():
		var view := child as VisualInstance3D
		if view != null and view.visible:
			wide = maxf(wide, view.get_aabb().size.x * 0.5)
	wide = clampf(wide, 0.04, 0.25)
	var at := to_local(held.global_position)
	out.append(at + Vector3.RIGHT * wide)
	if wide > 0.08:
		out.append(at - Vector3.RIGHT * wide)
	return out


## Two bones from `root` toward `target`, `a` then `b` long, bending toward
## `way`: [the first's basis, the second's, where the second starts, where it
## ends]. Each basis hangs its bone down its own -Y, its front (-Z) toward the bend.
static func _reach(root: Vector3, target: Vector3, a: float, b: float, way: Vector3) -> Array:
	var to := target - root
	var far := clampf(to.length(), 0.02, (a + b) * 0.999)
	var along := to.normalized() if to.length() > 0.001 else Vector3.DOWN
	var bend := (way - along * way.dot(along))
	bend = bend.normalized() if bend.length() > 0.001 else along.cross(Vector3.RIGHT).normalized()
	var cos_a := clampf((a * a + far * far - b * b) / (2.0 * a * far), -1.0, 1.0)
	var mid := root + along * a * cos_a + bend * a * sqrt(1.0 - cos_a * cos_a)
	var end := root + along * far
	return [_hang((mid - root).normalized(), bend), _hang((end - mid).normalized(), bend), mid, end]


## A basis whose -Y runs along `down` and whose -Z faces `front`, as near as it can.
static func _hang(down: Vector3, front: Vector3) -> Basis:
	var y := -down
	var z := -(front - down * front.dot(down))
	z = z.normalized() if z.length() > 0.001 else y.cross(Vector3.RIGHT).normalized()
	return Basis(y.cross(z).normalized(), y, z)


func _put(name: StringName, turn: Basis, at: Vector3) -> void:
	(_parts[name] as Node3D).transform = Transform3D(turn, at)
