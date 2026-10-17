class_name Reel
extends Node3D
## Working a line hand over hand: reel in draws it in a notch, pay out gives a
## notch back, up to all there is of it. It works the line's end in your
## hand, else the last line tied at your waist. Only the line draws, pulling
## both its ends, so what's on it comes only as hard as your strength allows;
## against a stake, or anything too heavy to come, you step in along it
## instead. Each notch is a stroke of your hand, the rope gathers into a coil
## where it's on you, and it rubs through your hands as it comes.

## One scroll step, m.
const NOTCH := 0.25
## Shortest you reel a line, m.
const SHORTEST := 1.0
## Hand over hand this fast, m/s: well under a line's closing speed, so
## what's on it is drawn, never flung.
const PACE := 1.0
## Past this share of your strength the reel slows, and you step in instead.
const STRAIN := 0.5
## A stroke dips your hand this far, m, across the line so it never stretches it.
const STROKE := 0.04

var rope: Rope
## The length it's being reeled to, m.
var wanted := 0.0
## Where your reel walks you in, m/s along engine x and z: toward what won't come.
var walk_in := Vector2.ZERO
## How far through a notch's stroke your hand is, 0 to 1, and which way: 1 in, -1 out.
var _stroke := 0.0
var _way := 1.0
var _player: Player
var _tuning := Tuning.current()
var _coil: MeshInstance3D
var _sound: AudioStreamPlayer


func _ready() -> void:
	_player = get_parent().get_parent() as Player
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 1.0
	torus.rings = 16
	torus.ring_segments = 6
	var look := StandardMaterial3D.new()
	look.albedo_color = Color(0.42, 0.31, 0.2)
	look.roughness = 0.95
	torus.material = look
	_coil = MeshInstance3D.new()
	_coil.mesh = torus
	_coil.top_level = true
	_coil.visible = false
	add_child(_coil)
	_sound = AudioStreamPlayer.new()
	_sound.stream = Sounds.REEL
	_sound.bus = Sounds.WORLD
	_sound.max_polyphony = 3
	add_child(_sound)


## The line reel in and pay out work now: its end in your hand, else the last
## line tied at your waist; none while a coil still pays it out.
func line() -> Rope:
	var hands := _player.hands
	if hands.phase == Hands.Phase.HELD and is_instance_valid(hands.held):
		var held := _line_of(hands.held)
		if held != null:
			return held
	var tied := _player.waist.tied
	for i in range(tied.size() - 1, -1, -1):
		var waisted := _line_of(tied[i])
		if waisted != null:
			return waisted
	return null


## A notch in, or out for a negative `by`. Says whether there was a line to work.
func notch(by: int) -> bool:
	var now := line()
	if now == null:
		return false
	if now != rope:
		rope = now
		wanted = now.length
	wanted = clampf(wanted - by * NOTCH, minf(SHORTEST, now.length), now.full)
	return true


## Your hand's stroke this frame, if the line it reels in ends in `body`: a
## dip and rise per notch, across the line, so the drawn line stays its
## length. Paid out, it just slips through your hand.
func stroke(body: Node) -> Vector3:
	if rope == null or _stroke <= 0.0 or _way < 0.0:
		return Vector3.ZERO
	var near := rope.a if _on_you(rope.a) else rope.b
	if near.holder != body:
		return Vector3.ZERO
	var along := (_far(rope).global_position - near.global_position).normalized()
	var dip := Vector3.DOWN - along * along.dot(Vector3.DOWN)
	return dip.normalized() * STROKE * sin(PI * _stroke) if dip.length() > 0.1 else Vector3.ZERO


func _physics_process(delta: float) -> void:
	walk_in = Vector2.ZERO
	if rope != null and (not _player.world.ropes.ropes.has(rope) or line() != rope):
		rope = null
	var off := wanted - rope.length if rope != null else 0.0
	if absf(off) < 1e-5 or not working():
		# A stroke under way finishes; the next starts afresh.
		if _stroke > 0.0:
			_stroke += delta * PACE / NOTCH
			if _stroke >= 1.0:
				_stroke = 0.0
		return
	var pace := PACE
	_way = signf(-off)
	if off < 0.0:
		# Slower as the pull nears your strength: what won't come, you step in to.
		var strain := smoothstep(STRAIN, 1.0, rope.tension / _tuning.hand_strength)
		pace *= 1.0 - strain
		var far := _far(rope).global_position - _player.global_position
		walk_in = Vector2(far.x, far.z).normalized() * PACE * strain
	var step := clampf(off, -pace * delta, pace * delta)
	rope.length += step
	rope.strand.set_length(rope.length)
	if _stroke == 0.0 and step != 0.0:
		_rub()
	_stroke += absf(step) / NOTCH
	if _stroke >= 1.0:
		_stroke -= 1.0
		_rub()


## Your hands are on it: no menu up, the inventory shut, not riding.
func working() -> bool:
	return Controls.playing() and not _player.suit.open and _player.board == null


## The rope gathered where the line is on you, as a coil growing with it.
func _process(_delta: float) -> void:
	var now := line()
	var gathered := now.full - now.length if now != null else 0.0
	_coil.visible = gathered > 0.05
	if not _coil.visible:
		return
	var at := (now.a if _on_you(now.a) else now.b).global_position
	var size := 0.06 + 0.035 * sqrt(gathered)
	var right := _player.global_basis.x
	var ahead := -_player.global_basis.z
	# Hanging from where it's held, turned half toward you so it reads as a coil.
	var axis := (right + ahead).normalized()
	var across := Vector3.UP.cross(axis).normalized()
	_coil.global_transform = Transform3D(Basis(across, axis, across.cross(axis)).scaled(Vector3.ONE * size),
		at + Vector3.DOWN * size * 0.8)


func _rub() -> void:
	# Paying out is the same rub let go, lower.
	_sound.pitch_scale = randf_range(0.92, 1.08) * (1.0 if _way > 0.0 else 0.8)
	_sound.play()


func _line_of(body: Variant) -> Rope:
	if not is_instance_valid(body) or not (body is Part):
		return null
	var laid: Line = body.get_meta(&"line") if body.has_meta(&"line") else null
	if laid != null and laid.state != Line.State.LAID:
		return null
	for child in body.get_children():
		if child is RopeEnd:
			var lines := _player.world.ropes.lines_on(child)
			if lines.size() == 1:
				return lines[0]
	return null


func _on_you(end: RopeEnd) -> bool:
	return _player.world.ropes.on_you(end.holder)


func _far(on: Rope) -> RopeEnd:
	return on.b if _on_you(on.a) else on.a
