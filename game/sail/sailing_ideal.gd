class_name SailingIdeal
extends RefCounted
## A local polar for this rig. Each advance evaluates one small piece of it.

var result := {}
var _rig := {}
var _headings: Array[Vector2] = []
var _best := {}
var _index := 0
var _speed_step := 0
var _low := 0.0
var _high := 0.0


static func heading_of(deck: Device) -> Vector2:
	var ahead := -deck.global_basis.z
	return Vector2(ahead.x, ahead.z).normalized()


static func support(deck: Device) -> Vector2:
	var hold := Vector2.ZERO
	var keels := Runners.keels(deck) if deck.hovering() else []
	if not keels.is_empty():
		for keel: Array in keels:
			hold += Vector2(keel[2], keel[3]) / keels.size()
	elif deck.glider != null and deck.glider.touching > 0:
		for runner: Array in deck.glider.runners:
			hold += Vector2(runner[4], runner[2]) / deck.glider.runners.size()
	return hold * deck.mass * deck.world.gravity


func begin(mast: Mast, course: Vector2) -> bool:
	var deck := mast.carrier()
	if deck == null or mast.sail() == null or mast.raise <= 0.0 or course.length_squared() < 0.5:
		return false
	var tuning := deck.world.tuning
	var centre := mast.global_transform * mast._middle_at(mast.boom)
	var wind := deck.world.weather.felt_wind(centre)
	wind.y = 0.0
	if wind.length() < tuning.sailing_aid_calm_mps:
		return false
	var path := mast.sheet_path()
	if path.is_empty():
		return false
	var options := PackedVector3Array()
	for i in tuning.sailing_aid_sheet_steps * 2 + 1:
		var boom := PI * (float(i) / tuning.sailing_aid_sheet_steps - 1.0)
		var length := Mast.length_on_path(path, boom)
		if length <= path.full:
			options.append(Vector3(boom, Mast.length_on_path(path, boom + deg_to_rad(0.1)) - length, length))
	if options.is_empty():
		return false
	var moving := deck.linear_velocity + deck.angular_velocity.cross(centre - deck.global_transform * deck.center_of_mass)
	if is_instance_valid(mast._boom_body):
		var body := mast._boom_body
		var state := PhysicsServer3D.body_get_direct_state(body.get_rid())
		moving = state.linear_velocity + state.angular_velocity.cross(centre - body.global_transform * body.center_of_mass)
	var ahead := heading_of(deck)
	var yaw := atan2(-ahead.x, -ahead.y)
	_rig = {"mast": weakref(mast), "wind": wind, "relative": Basis(Vector3.UP, -yaw) * mast.global_basis,
		"hold": support(deck), "catch": deck.wind_catch(), "area": mast.sail_m2() * mast.raise, "raised": mast.raise,
		"pressure": tuning.wind_catch_per_m2 / Mast.SQUARE, "options": options, "path": path,
		"speed_steps": tuning.sailing_aid_speed_steps, "ceiling": wind.length() * tuning.sailing_aid_speed_ratio,
		"turn_cost": tuning.sailing_aid_turn_cost, "ahead": ahead, "course": course.normalized(), "velocity": moving,
		"boom": mast.boom}
	_best = {"heading": ahead, "boom": mast.boom, "vmg": -INF}
	_headings = [course.normalized(), ahead]
	for i in tuning.sailing_aid_heading_steps:
		_headings.append(Vector2.from_angle(TAU * i / tuning.sailing_aid_heading_steps))
	_high = _rig.ceiling
	return true


## One trim search is the indivisible unit; the Console bounds units by frame time.
func advance() -> bool:
	if _index >= _headings.size():
		_finish()
		return true
	var heading := _headings[_index]
	var toward: float = heading.dot(_rig.course)
	if toward <= 0.0:
		_index += 1
		return false
	var speed := (_low + _high) * 0.5
	var sample := _trim(_rig, heading, Vector3(heading.x, 0.0, heading.y) * speed)
	if sample.drive > _rig.hold.y:
		_low = speed
	else:
		_high = speed
	_speed_step += 1
	if _speed_step >= int(_rig.speed_steps):
		var vmg: float = _low * toward - _rig.turn_cost * absf((_rig.ahead as Vector2).angle_to(heading))
		if vmg > _best.vmg:
			_best = {"heading": heading, "boom": sample.boom, "vmg": vmg}
		_index += 1
		_speed_step = 0
		_low = 0.0
		_high = _rig.ceiling
	return false


func _finish() -> void:
	var mast := (_rig.mast as WeakRef).get_ref() as Mast
	if not is_instance_valid(mast):
		return
	var trim := _trim(_rig, _rig.ahead, _rig.velocity)
	result = _best
	result["trim"] = trim.boom
	result["length"] = Mast.length_on_path(_rig.path, trim.boom)
	result["actual"] = _rig.ahead
	result["actual_boom"] = _rig.boom
	var actual: Vector3 = mast.global_basis * Vector3(-sin(_rig.boom), 0.0, -cos(_rig.boom))
	var yaw := atan2(-result.heading.x, -result.heading.y)
	var ideal: Vector3 = Basis(Vector3.UP, yaw) * _rig.relative * Vector3(-sin(result.boom), 0.0, -cos(result.boom))
	result["actual_sail"] = Vector2(actual.x, actual.z).normalized()
	result["ideal_sail"] = Vector2(ideal.x, ideal.z).normalized()
	result["mast"] = mast


static func _trim(rig: Dictionary, heading: Vector2, velocity: Vector3) -> Dictionary:
	var turned: Basis = Basis(Vector3.UP, atan2(-heading.x, -heading.y)) * rig.relative
	var axis := turned.y.normalized()
	var air: Vector3 = rig.wind - velocity
	air -= axis * air.dot(axis)
	var q: float = rig.pressure * air.length_squared()
	var ahead := Vector3(heading.x, 0.0, heading.y)
	var crosswise := Vector3(-ahead.z, 0.0, ahead.x)
	var upright := clampf(inverse_lerp(cos(deg_to_rad(70.0)), cos(deg_to_rad(40.0)), axis.dot(Vector3.UP)), 0.0, 1.0)
	var best := {"drive": -INF, "boom": rig.boom}
	var hull: Vector3 = air * air.length() * rig.catch
	for option: Vector3 in rig.options:
		var boom := option.x
		var push := Mast.force_at(air, boom, rig.area, rig.raised, q * upright, turned)
		var chord := turned * Vector3(-sin(boom), 0.0, -cos(boom))
		# The sheet restrains motion away from its eye; it cannot push a boom out.
		if chord.cross(push).dot(axis) * option.y < -0.001:
			continue
		var force := push + hull
		var slipping := maxf(absf(force.dot(crosswise)) - rig.hold.x, 0.0)
		var drive := force.dot(ahead) - slipping
		if drive > best.drive:
			best = {"drive": drive, "boom": boom}
	return best
