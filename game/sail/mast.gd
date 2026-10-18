class_name Mast
extends Device
## A mast for a sail. It seats on a crate's top mount or stands on a deck
## mount, and the sail fitted to it swings round it on its boom, held by its
## sheet, a line from the boom's end. Use raises or furls the sail.
##
## Raised, the sail makes lift and drag by its angle to the wind it feels, the
## felt wind less the camp's own way: lift peaks near 18° and stalls past it,
## drag grows toward square on. The push acts where the sail's middle is, high
## up, so its camp heels and, overpowered, tips. The wind swings the boom out
## to leeward until the sheet holds it: the sheet's length says how far, so
## reeling it in hauls the sail in and paying out eases it, and with nothing
## holding the sheet's far end it swings free and spills the wind. Held out,
## the sail's twist goes into the camp; swinging free, only the boom's drag
## does. Overloaded, the sail tears, and past that the mast snaps.

## The boom's root, in the mast's frame: it swings about the mast's axis.
## Seated, a device faces its host's back, so its boom, lying along its own
## front, trails behind the host: a camp sails the way it faces.
const BOOM_AT := Vector3(0.0, 0.3, 0.0)
## The boom's end, m from the mast, where the sheet ties: the sail's tie.
const BOOM := 2.33
## The sail's height up the mast over the boom, and its head's width, m.
const LUFF := 3.4
const HEAD := 1.0
## Where the sail's push acts, over the boom and back from the mast, m: up at
## its middle, and back about a third of its chord, where a filled sail draws.
const MIDDLE := Vector2(1.47, 0.6)
## The boom swings out no farther than this either way, rad.
const MOST := deg_to_rad(85.0)
## The boom and the sail on it turn this hard, kg·m², and their own drag
## against swinging, N·m·s/rad.
const SWING_MASS := 12.0
const SWING_DRAG := 60.0
## The boom swings at this rate within a tick, so a gybe never skips past its sheet.
const STEP_HZ := 120.0
## Raising or furling takes this long, s.
const RAISE_SECONDS := 1.5
## Seated, it stands to its full height over this long, s.
const EXTEND_SECONDS := 0.6
## Lift rises to its most at this angle of attack and stalls past it; drag
## grows with lift's square, and square on it pushes as any face that size.
const LIFT_MOST := 1.3
const STALL := deg_to_rad(18.0)
const STALL_WIDTH := deg_to_rad(8.0)
const SQUARE := 1.8
const DRAG_LEAST := 0.05
const DRAG_PER_LIFT := 0.12
## Furled, the sail on its boom still shows the wind this much, m².
const FURLED_M2 := 0.35
## Load is felt over this long before it tears the sail, and its pull this
## long before it snaps the mast, s.
const LOAD_SECONDS := 0.3
const BEND_SECONDS := 0.05
## Past its tearing load, the sail loses this share of itself a second for
## each share past it; below this much left it's rags.
const TEAR_RATE := 0.2
const RAGS := 0.15
## Lying over this far, its masthead and boom's end can rest on the sand, rad.
const TOUCH_TILT := deg_to_rad(25.0)

## Use raises it, or furls it: where the sail is headed, and how far up it is, 0 to 1.
var raised := false
var raise := 0.0
## The boom's swing off straight back, rad, and how fast it swings.
var boom := 0.0
var boom_spin := 0.0
## The sheet's inboard length, m: the boom swings out only as far as keeps its
## end this near where it lies hauled right in.
var trim := 0.0
## What the wind does to the sail, felt long enough to tear it, N, as if on
## the whole sail: its push, or as a raised sail it beats, drawing or not, a
## torn one no less than a whole one; and its push alone, felt as long,
## which bends the mast.
var load_n := 0.0
var bend_n := 0.0
## How far it stands up from stowed, 0 to 1.
var extend := 0.0
## What a tick of its sail costs, µs, on average.
var cost_us := 0.0
## What the sail made last tick: its push, N, the angle of attack and lift,
## for the readout and the look.
var force := Vector3.ZERO
var attack := 0.0
var lift := 0.0

var _sheet: Rope
var _held := false
## Each node swinging with the boom, as it lies with the boom straight back,
## and the swing they're shown at now.
var _base := {}
var _shown := 0.0
var _cloth: MeshInstance3D
## What the cloth was last shown as: raised, bellied, fluttering, torn.
var _looks := -Vector4.ONE
var _spar: MeshInstance3D
var _top: MeshInstance3D
static var _look: ShaderMaterial


func _ready() -> void:
	super()
	# After the ropes have pulled, before its camp's runners hold: they see its push.
	process_physics_priority = -5
	_build_look()


## Use raises or furls its sail; with none fitted, or wrecked, nothing to do.
func interact(by: Player) -> bool:
	if by.hands.held != null or sail() == null or wrecked() or sail_m2() <= 0.0:
		return false
	raised = not raised
	Sounds.play_at(self, Sounds.BAG_OPEN if raised else Sounds.BAG_CLOSE)
	return true


## The sail fitted to it, or null.
func sail() -> Part:
	var socket := _sail_socket()
	return socket.part if socket != null else null


## What's left of the sail's area, m²: it shrinks as it tears.
func sail_m2() -> float:
	var on := sail()
	if on == null:
		return 0.0
	var area: float = on.stats.get("sail_m2", 0.0)
	return area if area >= RAGS * (Catalog.PARTS[&"sail"].stats.sail_m2 as float) else 0.0


## The line tied at the boom's end, or null.
func sheet() -> Rope:
	_find_sheet()
	return _sheet


## Whether something holds the sheet's far end: you, a ring or a stake. Loose,
## it runs free, as far as the boom swings, so tied on again it holds the boom
## where it is.
func sheeted() -> bool:
	_find_sheet()
	return _held


## The widest the boom may swing either way now, rad.
func boom_most() -> float:
	if not _held:
		return MOST
	return minf(2.0 * asin(clampf(trim / (2.0 * BOOM), 0.0, 1.0)), MOST)


## Whether a line's end is a sheet's: the other end of its line is tied at a
## sail's boom.
static func sheet_end(end: Node) -> bool:
	var line: Line = end.get_meta(&"line") if end != null and end.has_meta(&"line") else null
	if line == null or line.rope == null:
		return false
	return line.rope.a.get_parent() is Mast or line.rope.b.get_parent() is Mast


## The device whose body takes its push: what it's seated on, all the way down.
func carrier() -> Device:
	var at: Device = host()
	while at != null and at.host() != null:
		at = at.host()
	return at


func stats() -> Dictionary:
	var now := super()
	if sail() != null:
		now["sail_m2"] = sail_m2()
		now["sail"] = "torn" if sail_m2() <= 0.0 else ("raised" if raised else "furled")
		now["boom_deg"] = rad_to_deg(boom)
		now["sail_n"] = force.length()
	return now


## Out the way it went in: the sail comes off with its boom straight back.
func take(socket: Socket) -> Part:
	if socket == _sail_socket():
		boom = 0.0
		boom_spin = 0.0
		_swing_nodes()
		_base.clear()
		raise = 0.0
		raised = false
	return super(socket)


func _physics_process(delta: float) -> void:
	super(delta)
	var started := Time.get_ticks_usec()
	var on := carrier()
	extend = move_toward(extend, 1.0 if on != null else 0.0, delta / EXTEND_SECONDS)
	# Off its mount, its sail comes down.
	if on == null:
		raised = false
	_find_sheet()
	var area := sail_m2() if not wrecked() else 0.0
	raise = move_toward(raise, 1.0 if raised and area > 0.0 else 0.0, delta / RAISE_SECONDS)
	force = Vector3.ZERO
	if on == null or on.freeze or world == null:
		_swing_nodes()
		return
	_sail(on, area, delta)
	_touch(on, delta)
	_swing_nodes()
	cost_us += (Time.get_ticks_usec() - started - cost_us) * 0.05
	Dev.put("sail/load", "%d N" % roundi(load_n))
	Dev.put("sail/us", "%d+%d" % [roundi(cost_us), roundi(on.glider.cost_us) if on.glider != null else 0])


## A tick of the sail on its carrier: the boom swings to where the wind and
## the sheet put it, and the push goes into the carrier.
func _sail(on: Device, area: float, h: float) -> void:
	var state := PhysicsServer3D.body_get_direct_state(on.get_rid())
	var axis := global_basis.y.normalized()
	var middle := on.global_transform * on.center_of_mass
	var centre := global_transform * _middle_at(boom)
	var moving := state.linear_velocity + state.angular_velocity.cross(centre - middle)
	var air := world.weather.felt_wind(centre) - moving
	var beating := world.tuning.wind_catch_per_m2 / SQUARE * air.length_squared()
	air -= axis * air.dot(axis)
	var showing := area * raise
	# Lying over, the sail meets the sand, not the wind.
	var upright := clampf(inverse_lerp(cos(deg_to_rad(70.0)), cos(deg_to_rad(40.0)), axis.dot(Vector3.UP)), 0.0, 1.0)
	var open := world.tuning.wind_catch_per_m2 / SQUARE * air.length_squared()
	var q := open * upright
	var most := boom_most()
	var n := maxi(1, roundi(h * STEP_HZ))
	var step := h / n
	var slam := 0.0
	var held_out := false
	var twist := 0.0
	var turned := global_basis
	for i in n:
		var push := _push(air, boom, showing, q, turned)
		twist = (turned * (_middle_at(boom) - BOOM_AT)).cross(push).dot(axis)
		# Out against its sheet and pushed farther, it stays: the camp holds it.
		held_out = absf(boom) >= most and twist * signf(boom) > 0.0
		if held_out:
			boom = signf(boom) * most
			boom_spin = 0.0
			continue
		boom_spin += (twist - SWING_DRAG * boom_spin) / SWING_MASS * step
		boom += boom_spin * step
		if absf(boom) >= most:
			boom = signf(boom) * most
			if boom_spin * signf(boom) > 0.0:
				# Brought up short by its sheet: the swing goes into the camp.
				slam += SWING_MASS * boom_spin
				boom_spin = 0.0
	force = _push(air, boom, showing, q, turned)
	# Held out, the sail's twist goes into the camp through the sheet; swinging
	# free, only its drag against swinging.
	var turning := twist if held_out else SWING_DRAG * boom_spin
	var at := global_transform * Vector3(0.0, BOOM_AT.y + MIDDLE.x * raise, 0.0)
	on.apply_impulse(force * h, at - on.global_position)
	on.apply_torque_impulse(axis * (turning * h + slam))
	# Luffing or lying over, a raised sail flogs as hard as the wind it stands in.
	var whole: float = Catalog.PARTS[&"sail"].stats.sail_m2
	var pressing := maxf(force.length() / showing, beating) * whole if showing > 0.0 else 0.0
	load_n += (pressing - load_n) * (1.0 - exp(-h / LOAD_SECONDS))
	bend_n += (force.length() - bend_n) * (1.0 - exp(-h / BEND_SECONDS))
	_strain(h)
	if not _held:
		trim = maxf(trim, 2.0 * BOOM * sin(absf(boom) * 0.5))


## The sail's push at a swing of the boom: lift across the air flowing past
## it and drag along it, by its angle of attack. Furled, only drag.
func _push(air: Vector3, swing: float, showing: float, q: float, turned: Basis) -> Vector3:
	var speed := air.length()
	if speed < 0.01 or q <= 0.0:
		return Vector3.ZERO
	var flow := air / speed
	var chord := (turned * Vector3(-sin(swing), 0.0, -cos(swing))).normalized()
	var axis := turned.y.normalized()
	var side := axis.cross(chord)
	attack = atan2(flow.dot(side), flow.dot(chord))
	var a := absf(attack)
	lift = lift_of(a)
	var drag := drag_of(a)
	# Pushed the way the air crossing it goes.
	var normal := side * signf(flow.dot(side))
	var across := normal - flow * normal.dot(flow)
	across = across.normalized() if across.length() > 1e-4 else Vector3.ZERO
	var furled := FURLED_M2 * (1.0 - raise) * SQUARE * absf(sin(attack))
	return q * (showing * (lift * across + drag * flow) + furled * flow)


## Lift by angle of attack, rad: rising to its most at the stall, falling
## away past it to what a flat sheet would make.
static func lift_of(a: float) -> float:
	var attached := LIFT_MOST * sin(PI * 0.5 * a / STALL) if a <= STALL \
		else LIFT_MOST * exp(-pow((a - STALL) / STALL_WIDTH, 2.0))
	return maxf(attached, SQUARE * sin(a) * absf(cos(a)))


static func drag_of(a: float) -> float:
	var attached := LIFT_MOST * sin(PI * 0.5 * minf(a, STALL) / STALL)
	return maxf(DRAG_LEAST + DRAG_PER_LIFT * attached * attached, SQUARE * sin(a) * sin(a) + DRAG_LEAST)


## Load past what it stands tears the sail, and past more snaps the mast.
func _strain(h: float) -> void:
	var tuning := world.tuning
	var on := sail()
	if on == null or wrecked():
		return
	if bend_n > tuning.mast_snap_n:
		wear(INF)
		raised = false
		_crack()
		return
	if load_n > tuning.sail_tear_n and raise > 0.0:
		var full: float = Catalog.PARTS[&"sail"].stats.sail_m2
		var was: float = on.stats.sail_m2
		on.stats.sail_m2 = maxf(was - full * TEAR_RATE * (load_n / tuning.sail_tear_n - 1.0) * h, 0.0)
		if sail_m2() <= 0.0:
			raised = false


## Lying over, its masthead and boom's end meet the sand as any end would:
## a soft push up and a drag along it, so a capsized camp rests on its mast.
func _touch(on: Device, h: float) -> void:
	if global_basis.y.normalized().dot(Vector3.UP) > cos(TOUCH_TILT):
		return
	for point in [Vector3(0.0, BOOM_AT.y + LUFF * extend, 0.0), _boom_end()]:
		Runners.touch(on, world, global_transform * point, 0.6, h)


## Its sheet: the line on the boom's end, which reeling hauls through the
## sail, and whether anything holds its far end.
func _find_sheet() -> void:
	var found: Rope = null
	var tie := _tie()
	if tie != null and tie.part != null and tie.part.has_meta(&"tip"):
		var lines := world.ropes.lines_on(tie.part.get_meta(&"tip")) if world != null else []
		if lines.size() == 1:
			found = lines[0]
	if found != _sheet:
		if _sheet != null and _sheet.hauls == _haul:
			_sheet.hauls = Callable()
		_sheet = found
	_held = false
	if _sheet != null:
		_sheet.hauls = _haul
		var mine: RopeEnd = tie.part.get_meta(&"tip")
		var other := _sheet.b if _sheet.a == mine else _sheet.a
		_held = is_instance_valid(other) and not (other.holder is Part and not world.ropes.on_you(other.holder))


## Reeling the sheet hauls the sail in or eases it, as far as it goes; past
## that, the line itself is reeled. A sail too loaded for your strength won't
## come in. Returns what's left of the step for the line.
func _haul(step: float) -> float:
	if _sheet == null or _sheet.hauls != _haul:
		return step
	var was := trim
	var most := 2.0 * BOOM * sin(MOST * 0.5)
	if step < 0.0 and _load_in() > world.tuning.hand_strength:
		return step
	trim = clampf(trim + step, 0.0, most)
	return step - (trim - was)


## What the sheet holds the sail in with, N: its twist over the sheet's lever.
func _load_in() -> float:
	var arm := BOOM * cos(absf(boom) * 0.5)
	var twist := (global_basis * (_middle_at(boom) - BOOM_AT)).cross(force).dot(global_basis.y.normalized())
	return absf(twist) / maxf(arm, 0.1)


## The sail's middle at a swing of the boom, in its own frame.
func _middle_at(swing: float) -> Vector3:
	return BOOM_AT + Vector3(-sin(swing) * MIDDLE.y, MIDDLE.x * maxf(raise, 0.05), -cos(swing) * MIDDLE.y)


func _boom_end() -> Vector3:
	return BOOM_AT + Vector3(-sin(boom) * BOOM, 0.0, -cos(boom) * BOOM)


func _sail_socket() -> Socket:
	for socket in frame_sockets():
		if socket.kind == &"sail":
			return socket
	return null


## The tie the sail adds at the boom's end, while it's fitted.
func _tie() -> Socket:
	var socket := _sail_socket()
	if socket == null or socket.part == null:
		return null
	for node in socket.fitted:
		if node is Socket:
			return node
	return null


## Everything on the boom turns with it: the sail and its tie, and whatever's
## tied there.
func _swing_nodes() -> void:
	var socket := _sail_socket()
	var on: Array[Node3D] = []
	if socket != null:
		on.append_array(socket.fitted)
		var tie := _tie()
		if tie != null:
			on.append_array(tie.fitted)
	var turn := Transform3D(Basis(Vector3.UP, boom), Vector3.ZERO)
	var moved := boom != _shown or on.size() != _base.size()
	var seen := {}
	for node in on:
		if not _base.has(node):
			_base[node] = Transform3D(Basis(Vector3.UP, -_shown), Vector3.ZERO) * node.transform
			moved = true
		seen[node] = true
	# Its shapes swing with the boom, so what was kept of them goes.
	if moved:
		for node in on:
			node.transform = turn * (_base[node] as Transform3D)
		for node in _base.keys():
			if not seen.has(node):
				_base.erase(node)
		_shapes_changed()
	_shown = boom
	_show()


func _show() -> void:
	if _cloth == null:
		return
	var area := sail_m2()
	var on := sail() != null
	var bag: MeshInstance3D = null
	if on:
		for node in _sail_socket().fitted:
			if node is MeshInstance3D:
				bag = node
	if bag != null:
		bag.visible = raise < 0.3
	_top.visible = extend > 0.0
	_top.scale = Vector3(1.0, maxf(extend, 0.01), 1.0)
	_cloth.visible = on and raise > 0.01
	_spar.visible = on and raise >= 0.3
	var swing := Transform3D(Basis(Vector3.UP, boom), BOOM_AT)
	_cloth.transform = swing
	_spar.transform = swing * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	if _cloth.visible:
		var full: float = Catalog.PARTS[&"sail"].stats.sail_m2
		var filled := clampf(lift / LIFT_MOST, 0.0, 1.0) * signf(attack)
		var look := Vector4(raise, -0.09 * filled, 0.04 * (1.0 - clampf(absf(attack) / deg_to_rad(8.0), 0.0, 1.0)) * raise,
			clampf(1.0 - area / full, 0.0, 1.0) if area > 0.0 else 0.85)
		if look.distance_to(_looks) > 0.002:
			_looks = look
			_cloth.set_instance_shader_parameter(&"raise", look.x)
			_cloth.set_instance_shader_parameter(&"belly", look.y)
			_cloth.set_instance_shader_parameter(&"flutter", look.z)
			_cloth.set_instance_shader_parameter(&"torn", look.w)
			_cloth.set_instance_shader_parameter(&"age", 1.0 - durability)


func show_wear() -> void:
	super()
	if _top != null:
		var layer: StringName = get_meta(&"layer", &"")
		_top.set_instance_shader_parameter(&"age", Paint.age_of(layer, durability))
		_top.set_instance_shader_parameter(&"era", Paint.era_of(layer))
		# Snapped, only its stowed pole stands.
		_top.visible = not wrecked() and extend > 0.0


func _build_look() -> void:
	if _look == null:
		_look = ShaderMaterial.new()
		_look.shader = preload("res://game/sail/sail.gdshader")
		_look.set_shader_parameter(&"luff", LUFF)
		_look.set_shader_parameter(&"foot", BOOM)
		_look.set_shader_parameter(&"head", HEAD)
	var grid := PlaneMesh.new()
	grid.size = Vector2.ONE
	grid.subdivide_width = 8
	grid.subdivide_depth = 10
	grid.material = _look
	grid.custom_aabb = AABB(Vector3(-1.2, -0.1, -BOOM - 0.2), Vector3(2.4, LUFF + 0.3, BOOM + 0.4))
	_cloth = MeshInstance3D.new()
	_cloth.mesh = grid
	_cloth.visible = false
	add_child(_cloth)
	_spar = MeshInstance3D.new()
	_spar.mesh = Dress.frame(&"boom", Vector3(0.07, 0.07, BOOM))
	_spar.visible = false
	add_child(_spar)
	var size: Vector3 = Catalog.DEVICES[&"mast"].size
	_top = MeshInstance3D.new()
	_top.mesh = Dress.frame(&"mast_top", Vector3(0.09, BOOM_AT.y + LUFF + 0.15 - size.y * 0.5, 0.09))
	_top.position = Vector3(0.0, size.y * 0.5, 0.0)
	_top.visible = false
	add_child(_top)
	show_wear()


func _crack() -> void:
	Sounds.play_at(self, Sounds.LANDING)
