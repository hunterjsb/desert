class_name SalvageKite
extends Device
## A small contained rig: wind loads its bridle, and one ordinary rope carries it.

var flying := false:
	set(value):
		flying = value
		if is_node_ready():
			_refresh()
var line_issued := false
var paying := false
var phase := 0.0
var load_n := Vector3.ZERO
var sailed_m := 0.0
var _wing: MeshInstance3D
var _canopy: CollisionShape3D
var _rope: Rope


func _ready() -> void:
	super()
	phase = float(hash(get_instance_id()) % 1000) * 0.01
	_wing = MeshInstance3D.new()
	_wing.mesh = KiteLooks.kite()
	var cloth := _wing.mesh.surface_get_material(_wing.mesh.get_surface_count() - 1).duplicate() as ShaderMaterial
	cloth.set_shader_parameter(&"cloth", KiteLooks.SALVAGE_CLOTH)
	cloth.set_shader_parameter(&"chevron", KiteLooks.SALVAGE_TRIM)
	_wing.set_surface_override_material(_wing.mesh.get_surface_count() - 1, cloth)
	add_child(_wing)
	_canopy = CollisionShape3D.new()
	var envelope := BoxShape3D.new()
	envelope.size = Vector3(KiteLooks.SPAN, KiteLooks.TALL, 0.06)
	_canopy.shape = envelope
	_canopy.disabled = true
	add_child(_canopy)
	angular_damp = Tuning.current().traction_spin_damp
	_refresh()


func bridle() -> Socket:
	for socket in frame_sockets():
		if socket.kind == &"tie":
			return socket
	return null


func laid() -> Line:
	var socket := bridle()
	if socket != null and is_instance_valid(socket.part) and socket.part.has_meta(&"line"):
		var found: Variant = socket.part.get_meta(&"line")
		if is_instance_valid(found) and found is Line and found.rope != null and world.ropes.ropes.has(found.rope):
			return found
	return null


func interact(by: Player) -> bool:
	return _toggle(by) if by.hands.held == null else false


func use(by: Player, _at: Vector3) -> bool:
	return _toggle(by)


func _toggle(by: Player) -> bool:
	if flying:
		flying = false
		paying = false
		load_n = Vector3.ZERO
		_refresh()
		Sounds.play_at(self, Sounds.REEL)
		return true
	if wrecked():
		return by.hands.refuse("the kite is torn to rags")
	if not mounted().is_empty() or on_deck():
		return by.hands.refuse("take the kite off the craft before launching it")
	if world.weather.felt_wind(global_position).length() < world.tuning.kite_lift_ms:
		return by.hands.refuse("too little wind to fly the kite")
	if laid() == null and (line_issued or not bridle().is_open()):
		return by.hands.refuse("tie a rope to the kite's bridle")
	if by.hands.held == self:
		by.hands.drop()
	if laid() == null:
		var line := Line.to_waist(world, bridle(), world.tuning.traction_launch_slack_m)
		line.full = maxf(line.full, world.tuning.traction_line_m)
		line.rope.full = line.full
		line_issued = true
	world.salvage.claim(self)
	flying = true
	paying = true
	linear_velocity += Vector3.UP * world.tuning.traction_toss_ms
	_refresh()
	Sounds.play_at(self, Sounds.THROW)
	if Controls.ui != null:
		Controls.ui.teach("salvage_kite", "{reel_in} holds the kite closer; {pay_out} gives it room.\n"
			+ "Steer with your board. Bring the kite within reach and {interact} to fold it.\n"
			+ "Its ordinary line can tie to a camp hook or stake.")
	by.hands.say("let the line out; reel to hold it short; steer with your board")
	return true


func _refresh() -> void:
	carryable = not flying
	set_meta(&"wind_catch", wind_catch())
	if _wing == null:
		return
	_canopy.set_deferred(&"disabled", not flying)
	_wing.visible = flying
	frame_view.visible = not flying
	_wing.scale = Vector3.ONE * Tuning.current().traction_scale
	show_wear()


func wind_catch() -> float:
	return 0.0 if flying else super()


func painted() -> Array[MeshInstance3D]:
	var views := super()
	if _wing != null:
		views.append(_wing)
	return views


func _hauled(step: float) -> float:
	paying = false
	return step


func _physics_process(delta: float) -> void:
	super(delta)
	if world == null:
		return
	if carryable == flying:
		_refresh()
	if not flying:
		return
	var line := laid()
	var rope := line.rope if line != null else null
	if rope != _rope:
		if _rope != null and _rope.hauls == _hauled:
			_rope.hauls = Callable()
		_rope = rope
	if _rope != null and not _rope.hauls.is_valid():
		_rope.hauls = _hauled
	if wrecked():
		flying = false
		load_n = Vector3.ZERO
		_refresh()
		return
	if line != null and paying:
		line.rope.length = minf(line.rope.length + world.tuning.traction_payout_ms * delta, line.full)
		line.rope.strand.set_length(line.rope.length)
		paying = line.rope.length < line.full
	var air := world.weather.felt_wind(global_position) - linear_velocity
	var across := Vector2(air.x, air.z)
	var tuning := world.tuning
	var direction := KiteFlight.direction(across, world.time, phase, tuning)
	var pressure := across.length_squared() * tuning.traction_area_m2 * tuning.traction_catch * durability
	var force := direction * pressure
	force.y += air.y * absf(air.y) * tuning.traction_vertical_drag
	load_n = load_n.lerp(force, KiteFlight.settling(delta))
	apply_central_force(load_n)
	_orient()
	if global_position.y - world.height_under(global_position) > AntennaKite.LOW:
		var storm := world.weather.field.raw_storm_at(world.world_x(global_position.x), world.world_z(global_position.z), world.time)
		wear(KiteFlight.wear_rate(across.length(), storm, tuning) * delta * world.time_warp)
	if line != null and is_instance_valid(world.player.board) and line.rope.tension > tuning.traction_deed_load_n:
		var travel := world.player.ride.last_step
		var pull := line.rope.impulse() if world.ropes.on_you(line.rope.a.holder) else line.rope.impulse_b()
		var on_you := world.ropes.on_you(line.rope.a.holder) or world.ropes.on_you(line.rope.b.holder)
		if on_you and Vector2(travel.x, travel.z).dot(Vector2(pull.x, pull.z)) > 0.0:
			sailed_m += Vector2(travel.x, travel.z).length()
			if world.counts_deeds:
				Deeds.measure(world, &"kite_board", sailed_m)


func _exit_tree() -> void:
	if _rope != null and _rope.hauls == _hauled:
		_rope.hauls = Callable()


func _process(_delta: float) -> void:
	_orient()


func _orient() -> void:
	if not flying or _wing == null:
		return
	var toward := -load_n.normalized() if load_n.length_squared() > 0.01 else Vector3.DOWN
	var side := Vector3.UP.cross(toward)
	var up := toward.cross(side).normalized() if side.length_squared() > 0.001 else Vector3.BACK
	_wing.global_basis = Basis.looking_at(-toward, up).scaled(Vector3.ONE * Tuning.current().traction_scale)
	_wing.position = -(global_basis.inverse() * (_wing.global_basis * KiteLooks.RING))
	_canopy.transform = _wing.transform
	_wing.set_instance_shader_parameter(&"torn", clampf((1.0 - durability) * 0.9, 0.0, 0.9))
	_wing.set_instance_shader_parameter(&"weathered", 1.0 - durability)
