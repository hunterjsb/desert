class_name Mast
extends Device
## A mast with a freely hinged physical boom. The wind, ordinary sheet and
## real collision geometry determine its swing; reeling only changes rope length.

## The boom's root, in the mast's frame: it swings about the mast's axis.
## Seated, a device faces its host's back, so its boom, lying along its own
## front, trails behind the host: a camp sails the way it faces.
const BOOM_AT := Vector3(0.0, 0.8, 0.0)
## The boom's end, m from the mast, where the sheet ties: the sail's tie.
const BOOM := 2.33
## The sail's height up the mast over the boom, and its head's width, m.
const LUFF := 3.4
const HEAD := 1.0
## Where the sail's push acts, over the boom and back from the mast, m: up at
## its middle, and back about a third of its chord, where a filled sail draws.
const MIDDLE := Vector2(1.47, 0.6)
## Seated, it stands to its full height over this long, s.
const EXTEND_SECONDS := 0.6
## What the first sheet at your waist teaches, once a profile: what the
## controls do, never how to sail well (Hunter, 2026-10-18: "we want this to
## require skill").
const HOW_TO := "sheet"
const HOW_TO_SAYS := "Look at the hand winch and {reel_in} to raise the sail; {pay_out} lowers it. Its brake holds when you stop.\n" \
	+ "The sheet runs from the boom's end through a deck hook to your waist.\n" \
	+ "{reel_in} takes in rope; {pay_out} gives slack. Wind and the rope move the boom.\n" \
	+ "With several waist lines, open {inventory}, hover one and click to choose which to work."
## What a rig flown from both its bow corners teaches, the first time you
## ride it: the bridle's two bow lines, and changing tack by them.
const BRIDLE_HOW_TO := "bridle"
const BRIDLE_HOW_TO_SAYS := "The rig flies on its sheet and a bow line from each bow corner, both at your waist.\n" \
	+ "To change tack, open {inventory} and select the rope to its far bow corner, then {reel_in} as you bear away: it pulls the rig across.\n" \
	+ "Head up onto the new side and {pay_out} it again."
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
## Its cloth shows the trim: under this angle of attack its luff lifts, under
## this it flogs whole, rad; and in less than this felt wind it hangs, m/s.
const LIFTS := deg_to_rad(12.0)
const FLOGS := deg_to_rad(2.0)
const LIGHT_AIR := 3.0
## Standing, it takes things stuck on it as a deck's faces do: on its pole's
## four sides, up the reach that stands out of its stowed pole, and on its
## head. Its head, over its middle, m; its upper pole's half width; and the
## span of the pole things stick on, m over its middle.
const MASTHEAD := &"head"
const SIDES := {&"front": Vector3.FORWARD, &"back": Vector3.BACK, &"left": Vector3.LEFT, &"right": Vector3.RIGHT}
const HEAD_Y := BOOM_AT.y + LUFF + 0.15
const HALYARD_FOOT := Vector3(0.12, BOOM_AT.y, 0.0)
const HALYARD_CLEARANCE := 0.08
const PULLEY_AT := Vector3(0.12, BOOM_AT.y + LUFF + HALYARD_CLEARANCE, -0.08)
const POLE_R := 0.045
const POLE := Vector2(0.75, HEAD_Y - 0.06)

## Hoisted this close to the pulley, its head block is seated there.
const SEATED := 0.01
var pulley: RopeEnd
var _pulley_block: MeshInstance3D
var _head_at := 0.0
var _halyard_load: Rope
var raised := false
## How far up the mast its halyard holds the cloth's head, 0 to 1, and how
## fast the head slides, shares of the luff a second.
var raise := 0.0
var head_speed := 0.0
## The boom's swing off straight back, rad, and how fast it swings.
var boom := 0.0
var boom_spin := 0.0
var sheet_n := 0.0
## What the wind does to the sail, felt long enough to tear it, N, as if on
## the whole sail: its push, or as a raised sail it beats, drawing or not, a
## torn one no less than a whole one; and its push alone, felt as long,
## which bends the mast.
var load_n := 0.0
## What the wind presses on each square metre of cloth, N: the furled bundle's
## drag isn't the cloth's, and over the last of the cloth showing it would tear it.
var _per_m2 := 0.0
var bend_n := 0.0
## How far it stands up from stowed, 0 to 1.
var extend := 0.0
## What a tick of its sail costs, µs, on average.
var cost_us := 0.0
## Since it was last yours to sail: the ground its camp has made against the
## wind, m, kept through its tacks; and how far it has run on a front's
## outflow ahead of the wall, m, without leaving it.
var upwind_m := 0.0
var outflow_m := 0.0
## What the sail made last tick: its push, N, the angle of attack and lift,
## and the air it felt, m/s, for the readout and the look.
var force := Vector3.ZERO
var attack := 0.0
var lift := 0.0
var _felt := 0.0
## The wind at the sail last tick, for its slack sheet to stir in.
var _wind := Vector3.ZERO
var _boom_body: RigidBody3D
var _boom_joint: HingeJoint3D
var _boom_carrier: Device
var _physical_part: Part
var _saved_boom := {}
var boom_pose: Transform3D:
	get:
		return global_transform.affine_inverse() * _boom_body.global_transform if is_instance_valid(_boom_body) else Transform3D(Basis(Vector3.UP, boom), Vector3.ZERO)
	set(value):
		_saved_boom.pose = value
var boom_velocity: Vector3:
	get:
		return _boom_body.linear_velocity if is_instance_valid(_boom_body) else Vector3.ZERO
	set(value):
		_saved_boom.velocity = value
var boom_angular: Vector3:
	get:
		return _boom_body.angular_velocity if is_instance_valid(_boom_body) else Vector3.ZERO
	set(value):
		_saved_boom.angular = value
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
## Its upper reach as your hands meet it, there only while it stands: the
## pole the sand and what's round it meet stays the stowed one, as it was.
var _reach: Area3D
static var _look: ShaderMaterial


func _ready() -> void:
	super()
	# Refresh the boom endpoint before the ordinary rope solver reads it.
	process_physics_priority = -15
	_build_look()
	pulley = RopeEnd.make(self, PULLEY_AT, false)
	_pulley_block = MeshInstance3D.new()
	_pulley_block.mesh = Dress.halyard_block()
	_pulley_block.position = PULLEY_AT - _top.position - Vector3.UP * 0.043
	_top.add_child(_pulley_block)
	var bracket := MeshInstance3D.new()
	bracket.mesh = Dress.halyard_mount()
	bracket.position = _pulley_block.position
	_top.add_child(bracket)
	if world != null:
		world.origin_shifted.connect(_shift_boom)


## A halyard end in hand passes over the masthead pulley; only hauling that
## line raises the sail.
func interact(by: Player) -> bool:
	if sail() == null or wrecked() or sail_m2() <= 0.0:
		return false
	if by.hands.held is RopeTip and by.hands.held.has_meta(&"line"):
		var laid: Line = by.hands.held.get_meta(&"line")
		var head := halyard_socket()
		if head == null or head.part == null or not laid.ends.has(head.part):
			return false
		var why := laid.route(pulley)
		if why != "":
			return by.hands.refuse(why)
		by.hands.say("halyard over masthead pulley" if laid.rope.through != null else "halyard clear of pulley")
		return true
	if by.hands.held != null:
		return false
	if halyard() == null:
		return by.hands.refuse("pass a halyard over the masthead pulley")
	return by.hands.refuse("haul its halyard to raise the sail")


func halyard_socket() -> Socket:
	for socket in frame_sockets():
		if socket.kind == &"tie":
			return socket
	return null


## A rig's halyard from the cloth's head over the pulley to a tie on `to`, a
## hand winch or the deck (its nearest free one unless `tie` is given), as
## rig recipes build it; `hauled`, made fast with the cloth right up.
func rig_hoist(to: Device, tie: Socket = null, hauled := false) -> Line:
	follow_mount()
	to.follow_mount()
	var head := halyard_socket()
	if tie == null:
		tie = to.free_tie(global_position)
	if head == null or not head.is_open() or tie == null:
		return null
	# Authored rigs begin assembled, with rope measured over the standing mast.
	extend = 1.0
	_show()
	_head_pose()
	var line := Line.between(world, head, tie, 0.0)
	line.rope.through = pulley
	line.rope.strand.through = pulley
	line.full = Line._tip(line.ends[0]).global_position.distance_to(pulley.global_position) \
		+ pulley.global_position.distance_to(Line._tip(line.ends[1]).global_position) + LUFF * raise
	line.rope.full = line.full
	line.rope.length = line.full - LUFF * raise
	if hauled:
		line.rope.length = pulley.global_position.distance_to(Line._tip(line.ends[1]).global_position) + HALYARD_CLEARANCE
		raise = 1.0
		_head_pose()
	line.rope.strand.set_length(line.rope.length)
	return line


func halyard() -> Rope:
	var head := halyard_socket()
	if head == null or not is_instance_valid(head.part) or not head.part.has_meta(&"line"):
		return null
	var line: Variant = head.part.get_meta(&"line")
	if not is_instance_valid(line) or not line is Line:
		return null
	return line.rope if line.rope != null and world.ropes.ropes.has(line.rope) else null


func _head_pose() -> void:
	var head := halyard_socket()
	if head == null:
		return
	var height := LUFF * raise
	var step := Vector3.UP * (height - _head_at)
	head.position = HALYARD_FOOT + Vector3.UP * height
	for node in head.fitted:
		node.position += step
	_head_at = height


func _clear_halyard_load() -> void:
	if _halyard_load != null:
		_halyard_load.carried_n = 0.0
	_halyard_load = null


func _exit_tree() -> void:
	_clear_halyard_load()


## The cloth's head hangs on its halyard over the masthead pulley: the line
## bears its weight, hauling it raises the sail, and eased or let go the
## cloth slides down the mast under that weight, no faster than its luff runs.
func _hoist(delta: float, area: float) -> void:
	_clear_halyard_load()
	# A sail on show has no world to hang in: it stands as it was set.
	if world == null:
		_head_pose()
		return
	var rope := halyard()
	# The least the line lets the head drop to, as a share of the luff: none
	# unless the line runs over the pulley and its far end is held.
	var held_at := 0.0
	if rope != null and rope.through == pulley and carrier() != null and area > 0.0:
		var head := halyard_socket()
		var tip := Line._tip(head.part)
		var far := rope.b if rope.a == tip else rope.a
		var toward := global_basis.inverse() * (far.global_position - pulley.global_position)
		_pulley_block.rotation.y = atan2(-toward.x, -toward.z)
		if far.has_meta(&"socket") or world.ropes.on_you(far.holder):
			var inboard := far.global_position.distance_to(pulley.global_position)
			held_at = clampf(1.0 - (rope.length - inboard - HALYARD_CLEARANCE) / LUFF, 0.0, 1.0)
	var upright := maxf(global_basis.y.normalized().dot(Vector3.UP), 0.0)
	var g := world.tuning.gravity
	head_speed = maxf(head_speed - g * upright / LUFF * delta, -1.0 / world.tuning.halyard_lower_seconds)
	raise += head_speed * delta
	if raise <= held_at:
		raise = held_at
		head_speed = 0.0
		if held_at > 0.0:
			rope.carried_n = sail().mass * g * upright
			_halyard_load = rope
	if raise <= 0.0:
		raise = 0.0
		head_speed = 0.0
	raised = raise > 0.0
	_head_pose()


## Hauled right up, its head block seated against the pulley.
func hoisted() -> bool:
	return raise >= 1.0 - SEATED


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


## Whether a line's end is a sheet's: the other end of its line is tied at a
## sail's boom.
static func sheet_end(end: Node) -> bool:
	# Untyped: a scenario cleared away may have freed the line.
	var line = end.get_meta(&"line") if end != null and end.has_meta(&"line") else null
	if not is_instance_valid(line) or line.rope == null:
		return false
	return line.rope.a.get_parent() is Mast or line.rope.b.get_parent() is Mast


## The tie at the boom's end, where its sheet is made fast.
func boom_tie() -> Socket:
	return _tie()


## The device whose body takes its push: what it's seated on, all the way down.
func carrier() -> Device:
	var at: Device = host()
	while at != null and at.host() != null:
		at = at.host()
	return at


## Out the way it went in: the sail comes off with its boom straight back.
func take(socket: Socket) -> Part:
	if socket == _sail_socket() or socket == halyard_socket():
		_clear_halyard_load()
	if socket == _sail_socket():
		var head := halyard_socket()
		if head != null and head.part != null:
			super.take(head)
		_release_boom()
		boom = 0.0
		boom_spin = 0.0
		sheet_n = 0.0
		_swing_nodes()
		_base.clear()
		raise = 0.0
		head_speed = 0.0
		raised = false
		_head_pose()
	return super(socket)


func _physics_process(delta: float) -> void:
	follow_mount()
	super(delta)
	var started := Time.get_ticks_usec()
	var on := carrier()
	extend = move_toward(extend, 1.0 if on != null else 0.0, delta / EXTEND_SECONDS)
	_stand_reach(extend >= 1.0 and on != null)
	_physical_boom(on)
	_read_boom()
	_swing_nodes()
	_find_sheet()
	var area := sail_m2() if not wrecked() else 0.0
	_hoist(delta, area)
	force = Vector3.ZERO
	sheet_n = 0.0
	_felt = 0.0
	if on != null and not on.freeze and world != null:
		_sail(on, area, delta)
		if world.counts_deeds:
			_deeds(on, delta)
	_show()
	if on == null or on.freeze or world == null:
		return
	cost_us += (Time.get_ticks_usec() - started - cost_us) * 0.05
	Dev.put("sail/load", "%d N" % roundi(load_n))
	Dev.put("sail/sheet", "%d N" % roundi(sheet_n))
	Dev.put("sail/us", "%d+%d" % [roundi(cost_us), roundi(on.glider.cost_us) if on.glider != null else 0])


## A tick of the sail on its carrier: the boom swings as the wind pushes it,
## held by its sheet, and the push goes into the carrier.
func _sail(on: Device, area: float, h: float) -> void:
	if not is_instance_valid(_boom_body):
		return
	var axis := global_basis.y.normalized()
	var centre := global_transform * _middle_at(boom)
	var state := PhysicsServer3D.body_get_direct_state(_boom_body.get_rid())
	var middle := _boom_body.global_transform * _boom_body.center_of_mass
	var moving := state.linear_velocity + state.angular_velocity.cross(centre - middle)
	_wind = world.weather.felt_wind(centre)
	var air := _wind - moving
	var beating := world.tuning.wind_catch_per_m2 / SQUARE * air.length_squared()
	air -= axis * air.dot(axis)
	var upright := clampf(inverse_lerp(cos(deg_to_rad(70.0)), cos(deg_to_rad(40.0)), axis.dot(Vector3.UP)), 0.0, 1.0)
	var catch := world.tuning.wind_catch_per_m2 / SQUARE * upright
	force = _push(air, boom, area * raise, catch * air.length_squared(), global_basis)
	_felt = air.length()
	_boom_body.apply_impulse(force * h, centre - _boom_body.global_position)
	# Bearing friction is an equal and opposite torque, never an angle target.
	var friction := axis * boom_spin * world.tuning.boom_hinge_drag * h
	_boom_body.apply_torque_impulse(-friction)
	on.apply_torque_impulse(friction)
	sheet_n = _sheet.tension if _sheet != null else 0.0
	var whole: float = Catalog.PARTS[&"sail"].stats.sail_m2
	var pressing := maxf(_per_m2, beating) * whole if area * raise > 0.0 else 0.0
	load_n += (pressing - load_n) * (1.0 - exp(-h / LOAD_SECONDS))
	bend_n += (force.length() - bend_n) * (1.0 - exp(-h / BEND_SECONDS))
	_strain(h)


## Sailed by you, all the way up: what its camp makes against the field's
## wind, and runs on a storm's outflow short of its wall.
func _deeds(on: Device, h: float) -> void:
	if not (Deeds.waiting(world, &"close_hauled") or Deeds.waiting(world, &"storm_runner")):
		return
	if not hoisted() or not sailed_by_you(on):
		upwind_m = 0.0
		outflow_m = 0.0
		return
	var way := Vector2(on.linear_velocity.x, on.linear_velocity.z)
	var blowing := world.weather.field_wind(on.global_position)
	if blowing.length() > 0.1:
		upwind_m = maxf(upwind_m - way.dot(Vector2(blowing.x, blowing.z).normalized()) * h, 0.0)
		Deeds.measure(world, &"close_hauled", upwind_m)
	var x := world.world_x(on.global_position.x)
	var z := world.world_z(on.global_position.z)
	var field := world.weather.field
	if field.outflow_at(x, z, world.time) > 0.0 and field.raw_storm_at(x, z, world.time) <= 0.0:
		outflow_m += way.length() * h
		Deeds.measure(world, &"storm_runner", outflow_m)
	else:
		outflow_m = 0.0


## Whether you sail it: its sheet on you, or you at the helm of its camp.
func sailed_by_you(on: Device) -> bool:
	var player := world.player
	if player.helm != null and player.helm.carrier() == on:
		return true
	if _sheet == null or not _held:
		return false
	var mine: RopeEnd = _tie().part.get_meta(&"tip")
	var other := _sheet.b if _sheet.a == mine else _sheet.a
	return is_instance_valid(other) and world.ropes.on_you(other.holder)


## The sail's push at a swing of the boom: lift across the air flowing past
## it and drag along it, by its angle of attack. Furled, only drag.
func _push(air: Vector3, swing: float, showing: float, q: float, turned: Basis) -> Vector3:
	var speed := air.length()
	_per_m2 = 0.0
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
	_per_m2 = q * (lift * across + drag * flow).length()
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
		_crack()
		return
	if load_n > tuning.sail_tear_n and raise > 0.0:
		var full: float = Catalog.PARTS[&"sail"].stats.sail_m2
		var was: float = on.stats.sail_m2
		on.stats.sail_m2 = maxf(was - full * TEAR_RATE * (load_n / tuning.sail_tear_n - 1.0) * h, 0.0)


## Its head, where a camp lying over rests on its mast: the spar has its own
## collider, the upper mast none.
func masthead() -> Vector3:
	return global_transform * Vector3(0.0, BOOM_AT.y + LUFF * extend, 0.0)


## Its sheet: the line on the boom's end, which reeling hauls through the
## block there, and whether anything holds its far end.
func _find_sheet() -> void:
	var found: Rope = null
	var tie := _tie()
	if tie != null and tie.part != null and tie.part.has_meta(&"tip"):
		var lines := world.ropes.lines_on(tie.part.get_meta(&"tip")) if world != null else []
		if lines.size() == 1:
			found = lines[0]
	if found != _sheet:
		if _sheet != null and _sheet.hauls == _worked:
			_sheet.hauls = Callable()
		_sheet = found
	if _sheet != null:
		_sheet.hauls = _worked
	_held = false
	if _sheet != null:
		var mine: RopeEnd = tie.part.get_meta(&"tip")
		var other := _sheet.b if _sheet.a == mine else _sheet.a
		_held = is_instance_valid(other) and not (other.holder is Part and not world.ropes.on_you(other.holder))


## Whether a streamer flies anywhere on a camp, its mast's too: a telltale to trim by.
static func _streamed(on: Device) -> bool:
	var riding: Array[Device] = [on]
	while not riding.is_empty():
		var each: Device = riding.pop_back()
		if each is Streamer:
			return true
		riding.append_array(each.mounted())
	return false


func _process(_delta: float) -> void:
	if is_instance_valid(_boom_body):
		_read_boom()
		_swing_nodes()


## Whether it stands at its full height on a camp, taking things stuck on it.
func standing() -> bool:
	return extend >= 1.0 and carrier() != null


## A sticky face in its own frame, +Z out of it: a side of its pole, along
## the pole's middle, or its head.
func face_frame(face: StringName) -> Transform3D:
	if face == MASTHEAD:
		return Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0.0, HEAD_Y, 0.0))
	var out: Vector3 = SIDES[face]
	var z := out
	var x := Vector3.UP.cross(z)
	return Transform3D(Basis(x, Vector3.UP, z), out * POLE_R + Vector3.UP * (POLE.x + POLE.y) * 0.5)


## Where on a face a thing may sit, in the face's frame: up and down the
## pole's middle, or on the head's middle.
func face_room(face: StringName) -> Rect2:
	if face == MASTHEAD:
		return Rect2()
	var half := (POLE.y - POLE.x) * 0.5
	return Rect2(Vector2(0.0, -half), Vector2(0.0, 2.0 * half))


## The face something stuck on it is on, by its way out.
func face_of(socket: Socket) -> StringName:
	return face_out(socket.out)


## The face whose way out, in its own frame, is nearest `out`.
static func face_out(out: Vector3) -> StringName:
	if out.y > 0.7:
		return MASTHEAD
	var best := &"front"
	var most := -INF
	for face: StringName in SIDES:
		var along := (SIDES[face] as Vector3).dot(out)
		if along > most:
			most = along
			best = face
	return best


## The face a look meets on it, by the way out where it met and, on its
## pole's edge, the way you look from.
func face_toward(normal: Vector3, looking: Vector3) -> StringName:
	var out := global_basis.orthonormalized().inverse() * normal
	if absf(out.y) < 0.7 and Vector2(out.x, out.z).length() < 0.5:
		out = -(global_basis.orthonormalized().inverse() * looking)
	return face_out(out) if out.y < 0.7 else MASTHEAD


## Its upper reach is there for your hands only while it stands, so a stowed
## mast is the pole you carry.
func _stand_reach(up: bool) -> void:
	if up == (_reach != null):
		return
	if up:
		_reach = Area3D.new()
		_reach.monitoring = false
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var low: float = Catalog.DEVICES[&"mast"].size.y * 0.5
		box.size = Vector3(POLE_R * 2.0, HEAD_Y - low, POLE_R * 2.0)
		shape.shape = box
		shape.position = Vector3(0.0, (HEAD_Y + low) * 0.5, 0.0)
		_reach.add_child(shape)
		add_child(_reach)
	else:
		remove_child(_reach)
		_reach.queue_free()
		_reach = null


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
	var turn := global_transform.affine_inverse() * _boom_body.global_transform if is_instance_valid(_boom_body) else Transform3D(Basis(Vector3.UP, boom), Vector3.ZERO)
	var moved := is_instance_valid(_boom_body) or boom != _shown or on.size() != _base.size()
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
			if node is CollisionShape3D:
				(node as CollisionShape3D).disabled = is_instance_valid(_boom_body)
		for node in _base.keys():
			if not seen.has(node):
				_base.erase(node)
		_shapes_changed()
	var tie := _tie()
	if tie != null and tie.part != null and tie.part.has_meta(&"tip"):
		var tip: RopeEnd = tie.part.get_meta(&"tip")
		tip.holder = _boom_body if is_instance_valid(_boom_body) else (carrier() as Node3D if carrier() != null else self)
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
	if pulley != null:
		pulley.position = _top.position + (PULLEY_AT - _top.position) * Vector3(1.0, maxf(extend, 0.01), 1.0)
	_cloth.visible = on and raise > 0.01
	_spar.visible = on and raise >= 0.3
	var swing := (global_transform.affine_inverse() * _boom_body.global_transform * Transform3D(Basis.IDENTITY, BOOM_AT)) if is_instance_valid(_boom_body) else Transform3D(Basis(Vector3.UP, boom), BOOM_AT)
	_cloth.transform = swing
	_spar.transform = swing * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	if _cloth.visible:
		var full: float = Catalog.PARTS[&"sail"].stats.sail_m2
		# Filled as hard as the air presses across it, running as on a reach;
		# luffing from the luff aft as it's eased past meeting the wind, harder
		# in a harder wind.
		var a := absf(attack)
		var pressed := (lift * cos(a) + drag_of(a) * sin(a)) / LIFT_MOST * smoothstep(0.0, LIGHT_AIR, _felt)
		var luffing := 1.0 - smoothstep(FLOGS, LIFTS, a)
		var look := Vector4(raise, -0.09 * clampf(pressed, 0.0, 1.0) * signf(attack),
			luffing * raise * clampf(_felt / 10.0, 0.0, 1.5),
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


## The sail belongs to a separate rigid body while mounted: count it once.
func _fitted_mass(socket: Socket) -> float:
	return 0.0 if (socket == _sail_socket() or socket == _tie()) and is_instance_valid(_boom_body) else super(socket)


func _physical_boom(on: Device) -> void:
	if on == _boom_carrier and sail() == _physical_part and is_instance_valid(_boom_body):
		_boom_body.freeze = on.freeze
		_weigh_boom()
		return
	_release_boom()
	if on == null or sail() == null or world == null or wrecked():
		return
	_boom_carrier = on
	_physical_part = sail()
	_boom_body = RigidBody3D.new()
	_boom_body.name = "PhysicalBoom"
	_boom_body.set_meta(&"boom_mast", self)
	_boom_body.top_level = true
	_boom_body.mass = sail().mass
	_boom_body.can_sleep = false
	_boom_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	_boom_body.center_of_mass = BOOM_AT + Vector3(0.0, MIDDLE.x, -MIDDLE.y)
	_boom_body.collision_layer = on.collision_layer
	_boom_body.collision_mask = on.collision_mask
	add_child(_boom_body)
	# Configure the hinge in its authored rest frame, independent of saved yaw.
	_boom_body.global_transform = global_transform
	PhysicsServer3D.body_set_state(_boom_body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, _boom_body.global_transform)
	_boom_body.freeze = on.freeze
	var shape := CollisionShape3D.new()
	var spar := BoxShape3D.new()
	var pole: Vector3 = Catalog.DEVICES[&"mast"].size
	var clear := Vector2(pole.x, pole.z).length() * 0.5 + 0.035 + world.tuning.boom_root_clearance
	spar.size = Vector3(0.07, 0.07, BOOM - clear)
	shape.shape = spar
	shape.position = BOOM_AT + Vector3(0.0, 0.0, -(BOOM + clear) * 0.5)
	_boom_body.add_child(shape)
	_weigh_boom()
	_reweigh()
	_boom_joint = HingeJoint3D.new()
	add_child(_boom_joint)
	# HingeJoint's local Z is its free axis.
	_boom_joint.transform = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), BOOM_AT)
	_boom_joint.node_a = _boom_joint.get_path_to(on)
	_boom_joint.node_b = _boom_joint.get_path_to(_boom_body)
	_boom_joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, false)
	_boom_joint.exclude_nodes_from_collision = false
	_boom_body.global_transform = global_transform * Transform3D(Basis(Vector3.UP, boom), Vector3.ZERO)
	_inherit_boom_velocity()
	RopeArticulation.forget(on)


## The boom's own rigid body while it swings on its hinge, or null.
func boom_body() -> RigidBody3D:
	return _boom_body if is_instance_valid(_boom_body) else null


func _weigh_boom() -> void:
	var tip := _tie()
	var end_mass := tip.part.mass if tip != null and tip.part != null else 0.0
	var cloth_mass := sail().mass
	var total := cloth_mass + end_mass
	# A rectangular mass surrogate follows the gathering cloth; the tip's
	# mass is separate. The real spar collider supplies contact, not inertia.
	var height := maxf(0.18, LUFF * raise)
	var cloth_middle := BOOM_AT + Vector3(0.0, height * 0.5, -BOOM * 0.5)
	var end_middle := BOOM_AT + Vector3(0.0, 0.0, -BOOM)
	var middle := (cloth_mass * cloth_middle + end_mass * end_middle) / total
	var inert := cloth_mass / 12.0 * Vector3(height * height + BOOM * BOOM, BOOM * BOOM + 0.07 * 0.07, height * height + 0.07 * 0.07)
	for entry in [[cloth_mass, cloth_middle], [end_mass, end_middle]]:
		var r: Vector3 = entry[1] - middle
		inert += entry[0] * Vector3(r.y * r.y + r.z * r.z, r.x * r.x + r.z * r.z, r.x * r.x + r.y * r.y)
	if _boom_body.mass != total:
		_boom_body.mass = total
	if _boom_body.center_of_mass != middle:
		_boom_body.center_of_mass = middle
	if _boom_body.inertia != inert:
		_boom_body.inertia = inert



func _read_boom() -> void:
	if not is_instance_valid(_boom_body):
		return
	var chord := global_basis.inverse() * -_boom_body.global_basis.z
	boom = atan2(-chord.x, -chord.z)
	boom_spin = (_boom_body.angular_velocity - _boom_carrier.angular_velocity).dot(global_basis.y.normalized())


func _release_boom() -> void:
	var had_body := is_instance_valid(_boom_body)
	if is_instance_valid(_boom_joint):
		_boom_joint.free()
	_boom_joint = null
	if is_instance_valid(_boom_body):
		_boom_body.free()
	_boom_body = null
	RopeArticulation.forget(_boom_carrier)
	_boom_carrier = null
	_physical_part = null
	if had_body:
		_reweigh()


func _reweigh() -> void:
	var on: Device = self
	while on != null:
		on._recompute()
		on = on.host()


func _shift_boom(by: Vector2i) -> void:
	if is_instance_valid(_boom_body):
		var offset := Vector3(by.x * world.tuning.chunk_size, 0.0, by.y * world.tuning.chunk_size)
		world.teleport(_boom_body, _boom_body.global_transform.translated(-offset))


func restored() -> void:
	_head_pose()
	_physical_boom(carrier())
	if is_instance_valid(_boom_body):
		_boom_body.global_transform = global_transform * _saved_boom.get("pose", Transform3D(Basis(Vector3.UP, boom), Vector3.ZERO))
		PhysicsServer3D.body_set_state(_boom_body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, _boom_body.global_transform)
		_inherit_boom_velocity()
		_boom_body.linear_velocity = _saved_boom.get("velocity", _boom_body.linear_velocity)
		_boom_body.angular_velocity = _saved_boom.get("angular", _boom_body.angular_velocity)
	_saved_boom.clear()
	_swing_nodes()


## Starter rigging is a real removable hook and one ordinary routed line.
## Its length includes the whole path; no virtual inboard is gathered on the reel.
func rig_sheet(line: Line, eased_degrees := 55.0) -> bool:
	var on := carrier() as Chassis
	if on == null or line.rope == null:
		return false
	var want := global_transform * Vector3(0.0, -Catalog.DEVICES[&"mast"].size.y * 0.5 + 0.06, -BOOM)
	var seats := SheetEye.seat(on, want)
	if seats.is_empty():
		return false
	var hook := Catalog.part(&"hook") as RopeHook
	var mount := seats[0]
	mount.basis = Basis(Vector3.RIGHT, -PI / 2.0)
	mount.origin -= Vector3.UP * SheetEye.EYE_UP
	on.stick(hook, mount, Vector3.UP)
	line.rope.through = hook.guide
	line.rope.strand.through = hook.guide
	var direct := line.rope.a.global_position.distance_to(line.rope.b.global_position)
	var path := line.rope.a.global_position.distance_to(hook.guide.global_position) + hook.guide.global_position.distance_to(line.rope.b.global_position)
	var slack := maxf(line.rope.length - direct, 0.0)
	var middle := hook.guide.global_position
	# Enough real line for either tack at departure, measured through this hook.
	for side: float in [-1.0, 1.0]:
		var swing := deg_to_rad(eased_degrees) * side
		var tip := global_transform * (BOOM_AT + Vector3(-sin(swing) * BOOM, 0.0, -cos(swing) * BOOM))
		path = maxf(path, tip.distance_to(middle) + middle.distance_to(line.rope.b.global_position))
	line.rope.length = path + slack
	line.full = maxf(line.rope.length, world.tuning.rope_coil_length)
	line.rope.full = line.full
	return true


## Actual line path at an eased departure swing, with this guide and endpoint.
func eased_length(degrees: float, side := 0.0) -> float:
	var rope := sheet()
	if rope == null:
		return 0.0
	var mine: RopeEnd = _tie().part.get_meta(&"tip")
	var other := rope.b if rope.a == mine else rope.a
	var guide := rope.through
	var path := 0.0
	for way: float in ([-1.0, 1.0] if side == 0.0 else [side]):
		var swing := deg_to_rad(degrees) * way
		var tip := global_transform * (BOOM_AT + Vector3(-sin(swing) * BOOM, 0.0, -cos(swing) * BOOM))
		var span := tip.distance_to(other.global_position)
		if is_instance_valid(guide):
			span = tip.distance_to(guide.global_position) + guide.global_position.distance_to(other.global_position)
		path = maxf(path, span)
	return path


## Observe the existing trimming action without taking any of its rope length.
func _worked(step: float) -> float:
	if step != 0.0 and world != null and world.counts_deeds and hoisted() and carrier() != null \
			and sailed_by_you(carrier()) and _streamed(carrier()):
		Deeds.done(world, &"telltale")
	return step


func _inherit_boom_velocity() -> void:
	var root_middle := _boom_carrier.global_transform * PhysicsServer3D.body_get_direct_state(_boom_carrier.get_rid()).center_of_mass_local
	var middle := _boom_body.global_transform * _boom_body.center_of_mass
	var axis := global_basis.y.normalized()
	_boom_body.linear_velocity = _boom_carrier.linear_velocity + _boom_carrier.angular_velocity.cross(middle - root_middle) + axis.cross(middle - global_transform * BOOM_AT) * boom_spin
	_boom_body.angular_velocity = _boom_carrier.angular_velocity + axis * boom_spin
