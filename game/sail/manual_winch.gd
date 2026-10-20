class_name ManualWinch
extends Device
## A braked hand drum pays an ordinary tied line. It never steers its load.

var wanted := NAN
var _operator: Player
var _worked: Rope
var _wheel: MeshInstance3D
var _turned := 0.0


func _ready() -> void:
	super()
	process_physics_priority = -17
	_wheel = MeshInstance3D.new()
	_wheel.mesh = Dress.winch_wheel()
	_wheel.position = Vector3(0, 0.035, 0)
	add_child(_wheel)


func line() -> Rope:
	if world == null:
		return null
	for socket in frame_sockets():
		if socket.kind == &"tie" and socket.part != null and socket.part.has_meta(&"line"):
			var laid: Line = socket.part.get_meta(&"line")
			if laid.rope != null and world.ropes.ropes.has(laid.rope):
				return laid.rope
	return null


func notch(by: int, player: Player) -> bool:
	if host() == null or wrecked():
		return player.hands.refuse("fit the hand winch to a chassis")
	var rope := line()
	if rope == null:
		return player.hands.refuse("tie a line to the winch drum")
	if rope != _worked:
		_worked = rope
		wanted = rope.length
	var least := world.tuning.winch_min_m
	for end in [rope.a, rope.b]:
		if end.has_meta(&"socket"):
			var socket: Socket = end.get_meta(&"socket")
			var mast := socket.get_parent() as Mast
			if mast != null and socket == mast.halyard_socket() and rope.through == mast.pulley:
				var other: RopeEnd = rope.b if rope.a == end else rope.a
				least = maxf(least, other.global_position.distance_to(mast.pulley.global_position) + 0.16)
	_operator = player
	wanted = clampf(wanted - by * world.tuning.winch_notch_m, least, rope.full)
	Sounds.play_at(self, Sounds.REEL)
	return true


func interact(by: Player) -> bool:
	if by.hands.held != null:
		return false
	by.hands.say("look at the wheel and " + Controls.key_for(&"reel_in") + " / " + Controls.key_for(&"pay_out"))
	return true


func _physics_process(delta: float) -> void:
	follow_mount()
	super(delta)
	var rope := line()
	if rope == null or rope != _worked or host() == null or wrecked():
		_worked = null
		wanted = NAN
		return
	if not is_instance_valid(_operator) or not Controls.playing() or _operator.suit.open \
			or _operator.hands.held != null or _operator.hands.grasp.body != null \
			or _operator.hands.look_device != self \
			or _operator.camera.global_position.distance_to(global_position) > world.tuning.reach:
		wanted = rope.length
		return
	var load := maxf(rope.tension, rope.haul_n)
	var pace := world.tuning.winch_pace_mps
	if wanted < rope.length:
		pace *= 1.0 - smoothstep(world.tuning.winch_pull_n * 0.5, world.tuning.winch_pull_n, load)
	var step := clampf(wanted - rope.length, -pace * delta, pace * delta)
	rope.length += step
	rope.strand.set_length(rope.length)
	_turned -= step / world.tuning.winch_drum_radius
	_wheel.rotation.z = _turned
	if step < 0.0:
		for child in world.content.get_children():
			if child is Line and (child as Line).rope == rope:
				for end: Part in (child as Line).ends:
					if end.socket != null and end.socket.get_parent() is Mast:
						var mast := end.socket.get_parent() as Mast
						if mast.hoist_enabled and mast.raise >= world.tuning.winch_hoist_deed:
							Deeds.done(world, &"hand_hoist")

