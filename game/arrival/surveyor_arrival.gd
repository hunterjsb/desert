class_name SurveyorArrival
extends Node
## One saved Surveyor opening. Rendering, physical recovery and saves share its state.
const PHASES: Array[StringName] = [&"orbit", &"ejection", &"descent", &"entry", &"landing", &"recovery"]
var world: World
var restoring := false
var _view: Node
var _held := false
var _warp := 1.0
var _physics := true
var _input := true
var _hands_input := true
var _suit_input := true
var _vitals := true

func start() -> void:
	if not world.arrival_state.is_empty():
		restore()
		return
	var point := Sphere.point(world.moon.latitude, world.moon.longitude)
	world.arrival_state = SurveyorManifest.resolve(world.run_seed, point)
	var state := world.arrival_state
	state.heading = world.player.global_rotation.y
	state.landing_world = Vector2(world.player_world_x(), world.player_world_z())
	var exit := Basis(Vector3.UP, state.heading) * Vector3(-world.tuning.surveyor_arrival.exit_offset_m, 0, 0)
	state.exit_world = state.landing_world + Vector2(exit.x, exit.z)
	state.elapsed = 0.0
	state.materialized = false
	state.flight_warp = world.time_warp
	restore()

func restore() -> void:
	restoring = false
	if world.arrival_state.is_empty():
		cancel()
		return
	if active():
		_hold()
		_show()
		set_physics_process(true)
	else:
		_release()
		set_physics_process(false)

func recover(body: Node) -> void:
	if world.get_meta(&"arrival_restoring", false) or active() or not is_instance_valid(body):
		return
	var uid: StringName = body.get_meta(&"arrival_uid", &"")
	if uid == &"":
		return
	for entry: Dictionary in world.arrival_state.get("structure", []) + world.arrival_state.get("equipment", []):
		if entry.uid == uid and entry.survives and not entry.recovered:
			entry.recovered = true
			Deeds.done(world, &"first_recovery")
			return

func active() -> bool:
	return not world.arrival_state.is_empty() and world.arrival_state.get("phase", &"recovery") != &"recovery"

func cancel() -> void:
	_release()
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	if restoring or world == null or world.arrival_state.is_empty() or world.get_meta(&"arrival_restoring", false):
		return
	if not active():
		return
	var state := world.arrival_state
	state.elapsed = float(state.get("elapsed", 0.0)) + delta
	var phase: StringName = state.phase
	var duration := _seconds(phase)
	state.phase_seconds = duration
	state.progress = clampf(state.elapsed / maxf(duration, 0.001), 0.0, 1.0)
	if state.elapsed >= duration:
		if phase == &"entry" and not _landing_ready():
			state.elapsed = duration
		else:
			var next := PHASES.find(phase) + 1
			if next > 0 and next < PHASES.size():
				if PHASES[next] == &"landing" and not _land():
					state.elapsed = duration
				else:
					state.phase = PHASES[next]
					state.elapsed = 0.0
					state.progress = 0.0
					state.phase_seconds = _seconds(state.phase)
					if state.phase == &"recovery":
						_release()
						var words := "Recover your supplies. The pod's panels can become your camp."
						if is_zero_approx(world.weather.day.sun_shown(world.time)):
							words = Controls.key_for(&"headlamp") + " · headlamp. Recover supplies; pod panels become your camp."
						world.player.hands.say(words)
						set_physics_process(false)
	_show()

func _seconds(phase: StringName) -> float:
	return maxf(float(world.tuning.surveyor_arrival.get(String(phase) + "_s", 0.0)), 0.0)

func _landing_ready() -> bool:
	var at: Vector2 = world.arrival_state.landing_world
	return world.terrain.is_settled_around(at.x, at.y)

func _land() -> bool:
	var state := world.arrival_state
	if not state.get("materialized", false):
		var materializer: Script = load("res://game/arrival/surveyor_recovery.gd")
		if materializer == null:
			return false
		var counting := world.counts_deeds
		world.counts_deeds = false
		world.arrival_nodes = materializer.call(&"materialize", world, state)
		world.counts_deeds = counting
		if not state.get("materialized", false):
			return false
	var exit: Vector2 = state.exit_world
	var position := Vector3(world.engine_x(exit.x), world.height_at(exit.x, exit.y) + world.tuning.surveyor_arrival.landing_clearance_m, world.engine_z(exit.y))
	world.teleport(world.player, Transform3D(Basis(Vector3.UP, float(state.heading) - PI * 0.5), position))
	world.player.velocity = Vector3.ZERO
	world.player.camera.rotation.x = -0.18
	world.set_meta(&"kit", world.arrival_nodes.values().filter(func(node: Node) -> bool: return is_instance_valid(node)))
	return true

func _hold() -> void:
	if _held:
		return
	var player := world.player
	_warp = world.time_warp
	_physics = player.is_physics_processing()
	_input = player.is_processing_unhandled_input()
	_hands_input = player.hands.is_processing_unhandled_input()
	_suit_input = player.suit.is_processing_unhandled_input()
	_vitals = player.vitals.is_physics_processing()
	world.time_warp = 0.0
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.hands.set_process_unhandled_input(false)
	player.suit.set_process_unhandled_input(false)
	player.vitals.set_physics_process(false)
	_held = true

func _release() -> void:
	if is_instance_valid(_view):
		_view.call(&"dispose")
	_view = null
	if not _held:
		return
	world.time_warp = float(world.arrival_state.get("flight_warp", _warp))
	world.player.set_physics_process(_physics)
	world.player.set_process_unhandled_input(_input)
	world.player.hands.set_process_unhandled_input(_hands_input)
	world.player.suit.set_process_unhandled_input(_suit_input)
	world.player.vitals.set_physics_process(_vitals)
	_held = false

func _show() -> void:
	if not active():
		return
	if not is_instance_valid(_view):
		var presentation: Script = load("res://game/arrival/arrival_view.gd")
		if presentation == null:
			return
		_view = presentation.new()
		add_child(_view)
		_view.call(&"setup", world)
	_view.call(&"present", world.arrival_state)
