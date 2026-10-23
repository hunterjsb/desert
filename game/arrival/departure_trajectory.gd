class_name DepartureTrajectory
extends RefCounted
## A regulated carrier pass and one ballistic pod pulse, in planet-radius units.
const VERSION := 1
const NORTH := Vector3(0.0, 0.0, 1.0)

static func build(plan: Dictionary, epoch_s: float, tuning: Tuning) -> Dictionary:
	var candidate := LandingPlan.selected(plan)
	if not is_finite(epoch_s) or not plan.has("anchor"):
		return {}
	# Without a clear surveyed site, aim at the start itself; the forecast still judges the ground.
	var target: Vector3 = candidate.point if not candidate.is_empty() else plan.anchor.point
	var radius := 1.0 + tuning.arrival_departure_altitude_r
	var reference_speed := TAU * radius / tuning.arrival_free_orbit_s
	var nav_radius := tuning.moon_circumference / TAU
	var cfg := {"radius": radius, "mu": reference_speed * reference_speed * radius,
		"day_s": tuning.day_minutes * 60.0,
		"carrier_omega": TAU / (tuning.day_minutes * 60.0),
		"loiter_angle": tuning.arrival_loiter_m / (nav_radius * maxf(cos(Sphere.latitude(target)), 0.1)),
		"loiter_rate": tuning.arrival_drift_mps / tuning.arrival_loiter_m,
		"down": tuning.arrival_down_kick, "retro": tuning.arrival_retro_max,
		"cross": tuning.arrival_cross_max, "step": tuning.arrival_step_s,
		"max_s": tuning.arrival_max_s, "stride": tuning.arrival_path_stride,
		"handle": tuning.arrival_handle_r, "view": tuning.arrival_view_r}
	var model := {"version": VERSION, "seed": plan.seed, "epoch": epoch_s,
		"anchor": plan.anchor.duplicate(true), "nav_radius": nav_radius,
		"corridor_m": tuning.arrival_corridor_m,
		"pulse": tuning.arrival_default_pulse, "settings": cfg,
		"orbit_start": _body_basis(epoch_s, cfg) * target}
	# Calibrate once, before selection: the default pulse reaches the known site. The
	# closest pass is kept, so float noise can never leave the run without a model.
	var start := target
	var best := {}
	var miss := INF
	for attempt in 12:
		model.orbit_start = _body_basis(epoch_s, cfg) * start
		var shot := _flight(model, epoch_s, false)
		if shot.is_empty():
			break
		var landed := _body_basis(epoch_s + float(shot.seconds), cfg).inverse() * (shot.point as Vector3)
		var correction := Sphere.flat_from(landed, target)
		if correction.length() < miss:
			miss = correction.length()
			best = model.duplicate(true)
		if miss * nav_radius < tuning.arrival_calibration_m:
			break
		start = Sphere.from_flat(start, correction)
	return best

## Where the moon, ship and pulse handle stand now: cheap enough for every frame.
static func frame(model: Dictionary, clock_s: float) -> Dictionary:
	if not valid(model) or not is_finite(clock_s):
		return {}
	var cfg: Dictionary = model.settings
	var carrier := _carrier(model, clock_s)
	var initial: Vector3 = model.orbit_start
	var east := Sphere.east(initial)
	var look := (initial - east * 0.7 + initial.cross(east) * 0.45).normalized()
	var camera := look * float(cfg.view)
	return {"body_basis": _body_basis(clock_s, cfg), "ship_position": carrier.point,
		"pulse_handle": _handle(model, carrier), "clock": clock_s,
		"camera_transform": Transform3D(Basis.looking_at(-camera, NORTH), camera)}


## The whole predicted flight and landing; integrates the path, so callers cache it.
static func sample(model: Dictionary, clock_s: float) -> Dictionary:
	var result := frame(model, clock_s)
	if result.is_empty():
		return {"status": &"unsupported_trajectory", "safe": false}
	result.merge({"status": &"no_intercept", "safe": false, "path": PackedVector3Array()}, true)
	var cfg: Dictionary = model.settings
	var shot := _flight(model, clock_s, true)
	if shot.is_empty():
		return result
	var arrival := clock_s + float(shot.seconds)
	var landed := _body_basis(arrival, cfg).inverse() * (shot.point as Vector3)
	var anchor := _anchor(model)
	var at := anchor.place(landed)
	# Canonicalize only the reversible sphere/sheet conversion, never a site choice.
	landed = anchor.point_at(at.x, at.y)
	var ground_velocity := _body_basis(arrival, cfg).inverse() * ((shot.velocity as Vector3) - NORTH.cross(shot.point) * (TAU / float(cfg.day_s)))
	var bearing := atan2(ground_velocity.dot(Sphere.east(landed)), ground_velocity.dot(Sphere.north(landed)))
	var normal_speed := absf((shot.velocity as Vector3).dot(shot.point))
	var pitch := atan2(normal_speed, maxf(ground_velocity.slide(landed).length(), 0.000001))
	var profile: StringName = &"shallow" if pitch < PI / 6.0 else &"steep" if pitch > PI / 3.0 else &"standard"
	var inside := at.distance_to(model.anchor.world) <= float(model.corridor_m)
	result.merge({"status": &"unverified" if inside else &"outside_survey", "inside_survey": inside,
		"path": shot.path, "path_times": shot.path_times, "landing_point": landed, "landing_world": at,
		"landing_forward": ground_velocity.slide(landed).normalized(),
		"arrival_time": arrival, "flight_s": shot.seconds,
		"heading": wrapf(-anchor.ground_bearing(bearing) - PI * 0.5, -PI, PI), "profile": profile}, true)
	return result

## Ray coordinates are inertial planet-radius units, just like sample's handle.
static func drag(model: Dictionary, clock_s: float, ray_origin: Vector3, ray_direction: Vector3) -> Dictionary:
	if not valid(model) or not is_finite(clock_s) or not ray_origin.is_finite() or not ray_direction.is_finite():
		return {}
	var carrier := _carrier(model, clock_s)
	var cfg: Dictionary = model.settings
	var radial: Vector3 = carrier.radial
	var centre: Vector3 = carrier.point - radial * float(cfg.down) * float(cfg.handle)
	var denominator := ray_direction.dot(radial)
	if absf(denominator) < 0.000001:
		return model.duplicate(true)
	var distance := (centre - ray_origin).dot(radial) / denominator
	if distance <= 0.0:
		return model.duplicate(true)
	var off := ray_origin + ray_direction * distance - centre
	var copy := model.duplicate(true)
	copy.pulse = Vector2(clampf(-off.dot(carrier.east) / (float(cfg.handle) * float(cfg.retro)), 0.0, 1.0),
		clampf(off.dot(carrier.north) / (float(cfg.handle) * float(cfg.cross)), -1.0, 1.0))
	return copy

## The forecast landing judged against the actual seeded ground, as one launch candidate.
static func resolve(shape: TerrainShape, plan: Dictionary, model: Dictionary, clock_s: float, tuning: Tuning) -> Dictionary:
	var forecast := sample(model, clock_s)
	var result := {"status": forecast.status, "safe": false, "sample": forecast, "candidate": {}, "plan": {}, "clock": clock_s}
	if not valid(model) or model.seed != shape.history.run_seed or model.get("anchor") != plan.get("anchor"):
		result.status = &"foreign_survey"
		return result
	if not forecast.get("inside_survey", false):
		return result
	var anchor := _anchor(model)
	var at: Vector2 = forecast.landing_world
	var reach := tuning.arrival_structure_clear_m + tuning.arrival_footprint_half_m * sqrt(2.0) + SiteKinds.most_reach()
	var records := LandingPlan.sites_near(shape.history, forecast.landing_point, reach)
	var candidate := LandingPlan.candidate(shape, anchor, at, &"launch_pulse", records, LandingPlan.signals(shape, plan, tuning), tuning)
	result.candidate = candidate
	result.safe = candidate.safe
	result.status = &"ready" if candidate.safe else &"unsafe_footprint"
	if candidate.safe:
		var selected := plan.duplicate(true)
		selected.candidates = selected.candidates.filter(func(item: Dictionary) -> bool: return item.id != &"launch_pulse")
		selected.candidates.append(candidate)
		selected.selected_id = candidate.id
		selected.heading = forecast.heading
		selected.profile = forecast.profile
		selected.departure_trajectory = model.duplicate(true)
		selected.forecast_clock = clock_s
		selected.forecast_arrival_time = forecast.arrival_time
		result.plan = selected
	return result

static func _anchor(model: Dictionary) -> Sites.Anchor:
	var anchor: Dictionary = model.anchor
	return Sites.Anchor.new(anchor.world.x, anchor.world.y, anchor.point, anchor.facing, float(model.nav_radius))

static func _body_basis(clock_s: float, cfg: Dictionary) -> Basis:
	return Basis(NORTH, TAU * fposmod(clock_s / float(cfg.day_s), 1.0))

static func _carrier(model: Dictionary, clock_s: float) -> Dictionary:
	var cfg: Dictionary = model.settings
	var elapsed := clock_s - float(model.epoch)
	var phase := elapsed * float(cfg.loiter_rate)
	var angle := float(cfg.carrier_omega) * elapsed + float(cfg.loiter_angle) * sin(phase)
	var omega := float(cfg.carrier_omega) + float(cfg.loiter_angle) * float(cfg.loiter_rate) * cos(phase)
	var radial: Vector3 = (model.orbit_start as Vector3).rotated(NORTH, angle)
	var east := Sphere.east(radial)
	return {"point": radial * float(cfg.radius), "omega": omega, "radial": radial, "east": east, "north": radial.cross(east).normalized()}

static func _handle(model: Dictionary, carrier: Dictionary) -> Vector3:
	var cfg: Dictionary = model.settings
	return carrier.point + (-(carrier.radial as Vector3) * float(cfg.down)
		- (carrier.east as Vector3) * float(cfg.retro) * model.pulse.x
		+ (carrier.north as Vector3) * float(cfg.cross) * model.pulse.y) * float(cfg.handle)

static func _flight(model: Dictionary, clock_s: float, keep_path: bool) -> Dictionary:
	var cfg: Dictionary = model.settings
	var carrier := _carrier(model, clock_s)
	var point: Vector3 = carrier.point
	var speed := sqrt(float(cfg.mu) / float(cfg.radius))
	var velocity: Vector3 = NORTH.cross(point) * float(carrier.omega) + speed * (
		-(carrier.radial as Vector3) * float(cfg.down) - (carrier.east as Vector3) * float(cfg.retro) * model.pulse.x
		+ (carrier.north as Vector3) * float(cfg.cross) * model.pulse.y)
	var path := PackedVector3Array([point])
	var times := PackedFloat32Array([0.0])
	var acceleration: Vector3 = -float(cfg.mu) * point / pow(point.length(), 3.0)
	var elapsed := 0.0
	var steps := ceili(float(cfg.max_s) / float(cfg.step))
	for i in steps:
		var dt := minf(float(cfg.step), float(cfg.max_s) - elapsed)
		var next: Vector3 = point + velocity * dt + acceleration * (dt * dt * 0.5)
		var next_acceleration: Vector3 = -float(cfg.mu) * next / pow(next.length(), 3.0)
		var next_velocity: Vector3 = velocity + (acceleration + next_acceleration) * (dt * 0.5)
		if next.length() <= 1.0:
			var fraction := clampf((point.length() - 1.0) / (point.length() - next.length()), 0.0, 1.0)
			var hit := point.lerp(next, fraction).normalized()
			if keep_path:
				path.append(hit)
				times.append(elapsed + dt * fraction)
			return {"point": hit, "velocity": velocity.lerp(next_velocity, fraction), "seconds": elapsed + dt * fraction, "path": path, "path_times": times}
		point = next
		velocity = next_velocity
		acceleration = next_acceleration
		elapsed += dt
		if keep_path and (i + 1) % int(cfg.stride) == 0:
			path.append(point)
			times.append(elapsed)
	return {}

static func valid(model: Dictionary) -> bool:
	if model.get("version") != VERSION or not model.get("orbit_start") is Vector3 or not model.get("pulse") is Vector2 \
			or not model.get("settings") is Dictionary or not model.get("anchor") is Dictionary:
		return false
	var start: Vector3 = model.orbit_start
	var pulse: Vector2 = model.pulse
	if not start.is_finite() or not is_equal_approx(start.length_squared(), 1.0) or not pulse.is_finite() \
			or pulse.x < 0.0 or pulse.x > 1.0 or absf(pulse.y) > 1.0 or not is_finite(float(model.get("epoch", NAN))):
		return false
	for key in [&"radius", &"mu", &"day_s", &"carrier_omega", &"loiter_angle", &"loiter_rate", &"down", &"retro", &"cross", &"step", &"max_s", &"stride", &"handle", &"view"]:
		var value := float(model.settings.get(key, NAN))
		if not is_finite(value) or value <= 0.0:
			return false
	return model.settings.radius > 1.0 and is_finite(float(model.get("nav_radius", NAN))) and float(model.nav_radius) > 0.0
