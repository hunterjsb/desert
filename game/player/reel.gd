class_name Reel
extends Node3D
## Working a line hand over hand: reel in draws it in a notch, pay out gives a
## notch back, up to all there is of it. It works the line's end in your
## hand, else the waist line chosen in the carry view. Only the line draws, pulling
## both its ends, so what's on it comes only as hard as your strength allows;
## against a stake, or anything too heavy to come, you step in along it
## instead. A sheet runs through its block, so what comes in is its inboard,
## as hard as its sail allows. Each notch is a stroke of your hand, the rope
## gathers into a coil where it's on you, and it rubs through your hands as it comes.

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
const CHOOSE_LINE := "Open carry view and choose a rope"

var rope: Rope
## A chosen waist end, or null when no rope is selected. Never a physical tie.
var _chosen: RigidBody3D
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
var _coil_amount := 0.0
var _coil_line: Rope
var _sound: AudioStreamPlayer
var _yank_left := 0.0
var _yank_wait := 0.0
var _yank_m := 0.0
var _yank_n := 0.0


func _ready() -> void:
	_player = get_parent().get_parent() as Player
	_coil = MeshInstance3D.new()
	_coil.mesh = Dress.coil()
	_coil.top_level = true
	_coil.visible = false
	add_child(_coil)
	_sound = AudioStreamPlayer.new()
	_sound.stream = Sounds.REEL
	_sound.bus = Sounds.WORLD
	_sound.max_polyphony = 3
	add_child(_sound)


## A held line wins; one connection needs no choice, several keep the chosen line.
func line() -> Rope:
	var held := in_hand()
	if held != null:
		return held
	var chosen := chosen_body()
	if chosen != null:
		return _line_of(chosen)
	var connected := connected_ropes()
	return connected[0] if connected.size() == 1 else null


## Individual original ends carried at the waist or in the held knot.
func waist_lines() -> Array[RigidBody3D]:
	var found: Array[RigidBody3D] = []
	var roots: Array[RigidBody3D] = _player.waist.tied.duplicate()
	if _player.hands.held is RopeTip:
		roots.append(_player.hands.held)
	for root in roots:
		if not is_instance_valid(root) or not root is Part:
			continue
		for member in RopeBundle.members(root):
			if _live_rope(_line_of(member)):
				found.append(member)
	return found


## Count real connections, including knots and the stake carried at the waist.
func connected_ropes() -> Array[Rope]:
	var found: Array[Rope] = []
	var roots: Array[RigidBody3D] = _player.waist.tied.duplicate()
	if _player.hands.held is RopeTip:
		roots.append(_player.hands.held)
	for body in roots:
		if not is_instance_valid(body):
			continue
		for child in body.get_children():
			if child is RopeEnd:
				for on in _player.world.ropes.lines_on(child):
					if _live_rope(on) and not found.has(on):
						found.append(on)
	return found


func _live_rope(on: Rope) -> bool:
	return on != null and _player.world.ropes.ropes.has(on) and is_instance_valid(on.a) \
		and is_instance_valid(on.b) and is_instance_valid(on.a.holder) and is_instance_valid(on.b.holder)


## Explicit selection is lost when its physical tie is lost.
func chosen_body() -> RigidBody3D:
	if not is_instance_valid(_chosen) or not _live_carried(_chosen):
		_chosen = null
	return _chosen


## Null clears the choice; selecting never changes a rope or tie.
func choose(body: RigidBody3D) -> void:
	_chosen = body if _live_carried(body) else null


func _live_carried(body: RigidBody3D) -> bool:
	return is_instance_valid(body) and waist_lines().has(body)


## The line whose end is in your hand, or null.
func in_hand() -> Rope:
	var hands := _player.hands
	if hands.phase != Hands.Phase.HELD or not is_instance_valid(hands.held):
		return null
	return _line_of(held_end()) if hands.held is RopeTip else _line_of(hands.held)


## The original end worked inside the knot in hand, without changing any tie.
func held_end() -> Part:
	var hands := _player.hands
	if not hands.held is RopeTip:
		return null
	var members := RopeBundle.members(hands.held)
	var chosen := chosen_body()
	if members.has(chosen):
		return chosen
	for member in members:
		if _live_rope(_line_of(member)):
			return member
	return null


## The waist end explicitly selected for reeling.
func waist_body() -> RigidBody3D:
	var selected := line()
	if selected == null:
		return null
	for end in [selected.a, selected.b]:
		if is_instance_valid(end) and _player.waist.holds(end.holder):
			return end.holder
	return null


## A named target and its live load make the wheel's choice visible.
func waist_readout() -> String:
	var body := waist_body()
	if body == null:
		return ""
	return waist_description(body) + (" · selected" if body == chosen_body() else "")


## The same name and live numbers in the carry view and the sailing readout.
func waist_description(body: RigidBody3D) -> String:
	if not _live_carried(body):
		return ""
	var selected := _line_of(body)
	var label := "Sail sheet" if Mast.sheet_end(body) else "Waist line"
	var far := _far(selected)
	if label == "Waist line" and far.holder is Chassis and _player._bridled():
		var deck := far.holder as Chassis
		var middle := 0.0
		for piece in deck.pieces():
			middle += piece.pose().origin.x / deck.pieces().size()
		label = "Left bow line" if deck.to_local(far.global_position).x < middle else "Right bow line"
	elif label == "Waist line" and far.holder is Device:
		label = "Line to " + (far.holder as Device).label.to_lower()
	elif label == "Waist line" and far.holder is Stake:
		label = "Stake line"
	return "%s · %.1f m · %d N" % [label, selected.length, roundi(selected.tension)]


## A notch in, or out for a negative `by`. Says whether there was a line to work.
func notch(by: int) -> bool:
	_yank_left = 0.0
	var now := line()
	if now == null:
		if not connected_ropes().is_empty():
			_player.hands.say(CHOOSE_LINE)
		return false
	if now != rope:
		rope = now
		wanted = now.length
	# A sheet pays out into its sail even with all of the line out; what the
	# sail can't take, the line won't give past all there is of it.
	var most := INF if now.hauls.is_valid() else now.full
	wanted = clampf(wanted - by * NOTCH, minf(SHORTEST, now.length), most)
	return true


## A short haul does work through the rope; it never applies a body impulse.
func yank() -> bool:
	if not working() or _yank_wait > 0.0:
		return false
	var now := line()
	if now == null:
		if not connected_ropes().is_empty():
			_player.hands.say(CHOOSE_LINE)
		return false
	rope = now
	wanted = maxf(minf(SHORTEST, now.length), now.length - _tuning.rope_yank_m)
	_yank_left = _tuning.rope_yank_seconds
	_yank_wait = _tuning.rope_yank_seconds + _tuning.rope_yank_recover_seconds
	_yank_m = 0.0
	_yank_n = 0.0
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
	_yank_wait = maxf(0.0, _yank_wait - delta)
	if rope != null and (not _player.world.ropes.ropes.has(rope) or line() != rope):
		rope = null
		_yank_left = 0.0
	var yanking := _yank_left > 0.0
	var stroke_seconds := minf(delta, _yank_left) if yanking else delta
	_yank_left = maxf(0.0, _yank_left - delta)
	var off := wanted - rope.length if rope != null else 0.0
	if absf(off) < 1e-5 or not working():
		if yanking and (not working() or _yank_left == 0.0):
			_yank_left = 0.0
			wanted = rope.length if rope != null else 0.0
		# A stroke under way finishes; the next starts afresh.
		if _stroke > 0.0:
			_stroke += delta * PACE / NOTCH
			if _stroke >= 1.0:
				_stroke = 0.0
		return
	var pace := PACE
	if yanking:
		pace = _tuning.rope_yank_m / maxf(_tuning.rope_yank_seconds, 0.001)
	_way = signf(-off)
	if off < 0.0:
		# Slower as the pull nears your strength, a sheet's sail's too: what
		# won't come along the line, you step in to.
		var strain := smoothstep(STRAIN, 1.0, rope.tension / _tuning.hand_strength)
		pace *= 1.0 - maxf(strain, smoothstep(STRAIN, 1.0, rope.haul_n / _tuning.hand_strength))
		var far := _far(rope).global_position - _player.global_position
		walk_in = Vector2(far.x, far.z).normalized() * PACE * strain
	var step := clampf(off, -pace * stroke_seconds, pace * stroke_seconds)
	# What a sheet takes in hauls its sail instead, and the line needn't.
	var left: float = rope.hauls.call(step) if rope.hauls.is_valid() else step
	left = minf(left, rope.full - rope.length)
	wanted -= step - left
	rope.length += left
	rope.strand.set_length(rope.length)
	if yanking and step < 0.0:
		_yank_m -= step
		_yank_n = maxf(_yank_n, maxf(rope.tension, rope.haul_n))
		if _yank_m >= _tuning.rope_yank_deed_m and _yank_n >= _tuning.rope_yank_deed_n:
			Deeds.done(_player.world, &"quick_haul")
	if yanking and _yank_left == 0.0:
		wanted = rope.length
	if _stroke == 0.0 and step != 0.0:
		_rub()
	_stroke += absf(step) / NOTCH
	if _stroke >= 1.0:
		_stroke -= 1.0
		_rub()


## Your hands are on it: no menu up, the inventory shut. Riding, it works the
## line at your waist: a sheet the board stays tied to.
func working() -> bool:
	return Controls.playing() and not _player.suit.open


## The rope gathered where the line is on you, as a coil growing with it.
func _process(delta: float) -> void:
	var paying := _paying_in_hand()
	var now := paying.rope if paying != null else line()
	var gathered := now.full - now.length + now.haul_gathered if now != null else 0.0
	var was_visible := _coil.visible
	_coil.visible = gathered > 0.0
	if not _coil.visible:
		_coil_line = null
		_coil_amount = 0.0
		return
	# Before its first tie the rest is on the belt; afterward it pays from the hand.
	var end := Line._tip(paying.ends[1 - paying._first]) if paying != null else (now.a if _on_you(now.a) else now.b)
	var target := clampf(gathered / now.full, 0.0, 1.0)
	var settle := 1.0 - exp(-delta / float(_tuning.rope_coil_visual.response_seconds))
	_coil_amount = lerpf(_coil_amount, target, settle) if _coil_line == now else target
	_coil_line = now
	CoilLooks.show_amount(_coil, _coil_amount)
	var right := _player.global_basis.x
	var ahead := -_player.global_basis.z
	var axis := (right + ahead).normalized()
	var across := Vector3.UP.cross(axis).normalized()
	var basis := Basis(across, axis.cross(across), axis)
	if was_visible:
		basis = _coil.global_basis.slerp(basis, settle)
	# The leading end stays on its live attachment; changing fill never recentres it.
	_coil.global_transform = Transform3D(basis, end.global_position - basis * CoilLooks.anchor())


## Laying a new line owns its coil display without changing the selected reel.
func _paying_in_hand() -> Line:
	var held := _player.hands.held
	if not is_instance_valid(held) or not held.has_meta(&"line"):
		return null
	var laid: Variant = held.get_meta(&"line")
	if not is_instance_valid(laid) or not laid is Line:
		return null
	if laid.state in [Line.State.FIRST, Line.State.PAYING] and laid.ends.has(held) \
			and laid.ends.size() == 2 and _live_rope(laid.rope):
		return laid
	return null


func _rub() -> void:
	# Paying out is the same rub let go, lower.
	_sound.pitch_scale = randf_range(0.92, 1.08) * (1.0 if _way > 0.0 else 0.8)
	_sound.play()


func _line_of(body: Variant) -> Rope:
	if not is_instance_valid(body) or not (body is Part):
		return null
	# A scenario cleared away may free a line whose end is still on you.
	var laid: Variant = body.get_meta(&"line") if body.has_meta(&"line") else null
	if laid != null and (not is_instance_valid(laid) or (laid as Line).state != Line.State.LAID):
		return null
	if body.has_meta(&"tip"):
		var tip: RopeEnd = body.get_meta(&"tip")
		if not is_instance_valid(tip):
			return null
		var lines := _player.world.ropes.lines_on(tip)
		return lines[0] if lines.size() == 1 else null
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
