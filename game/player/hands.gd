class_name Hands
extends Node3D
## Your hands, with room for one thing: a part, or a device small enough to
## carry, like a stake. Look at a loose part and take it, or at a fitted or
## stuck one and it slides out the way it went in. Carry it and look at a
## chassis's sticky face: the thing itself goes there, flat on the face or
## upright on a wall, where it would stick, touching nothing until it's set;
## it edges to the face's edges and its neighbours, the rotate gesture turns
## it, settling into soft detents, and it tints red with a few words where it
## won't go. Take leaves it there. A plug, a hose's end, a hook, a crop or a
## mod goes in its slot instead: the slot leans it in, a ghost shows the
## spot, and take seats it home. Nothing sticks or fits by being bumped. Take
## picks up, takes out, puts in and puts down; use works what you look at or
## uses what you hold. Finds lying in the sand are taken the same way, and
## whatever you take, take from, stick on or use becomes yours. A chassis
## piece joins a deck at a free edge ring, or on a frame's face, the same
## way. Take on a deck takes hold of the whole of it, and only a bare piece
## comes off. Having hold of something too heavy to carry, a Console or a
## loaded piece, it goes where it would stick or join as you look there, and
## take sets it; a throw punches what you have hold of. Whenever take or use
## can't do what you aim at, it says why, with a soft knock.

signal fitted(part: Part, device: Device, socket: Socket)
signal taken(part: Part, device: Device, socket: Socket)

enum Phase { EMPTY, TAKING, ARRIVING, HELD }

## A part that's come free reaches your hand in this long, s.
const ARRIVE := 0.12
## Blocked on its way to your hand this long, it skips there instead, s.
const STUCK := 0.3
## Shapes are shrunk this much a side when asking whether a part is inside
## something, so resting against it doesn't count, m.
const SKIN := 0.005
const GHOST := Color(0.75, 0.95, 1.0)
## What take would move shows in the ghost's colour this faintly, a shell
## this far out over it, m.
const MARK := 0.12
const MARK_GROW := 0.01
## Why use did nothing stays in the readout this long, s.
const NOTICE := 1.5
## Reel in and pay out bring what you carry this near your eyes, or push it
## this far out, m; nothing comes nearer than clears you.
const HOLD_NEAREST := 0.5
const HOLD_FARTHEST := 2.0
## How fast what you carry eases to a new distance, 1/s.
const HOLD_EASE := 12.0
## Where a heat cutter's carried, from your eyes, m: low at your right, and
## this far ahead.
const TOOL_AT := Vector3(0.28, -0.32, 0.0)
const TOOL_AWAY := 0.55
## How each tuning action works a radio: [notches, fine, the volume knob].
const TUNES := {&"reel_in": [1, false, false], &"pay_out": [-1, false, false],
	&"tune_fine_up": [1, true, false], &"tune_fine_down": [-1, true, false],
	&"volume_up": [1, false, true], &"volume_down": [-1, false, true]}
## What you have hold of comes no nearer than this clear of you, m.
const GRASP_CLEAR := 0.1
## The tints where what you hold won't go, or would with a warning (Fitting).
const BLOCKED := Fitting.BLOCKED
const WARNED := Fitting.WARNED
## Something too heavy to carry comes off its seat this far, m, so it starts
## clear of what it sat on; a chassis piece slides this far off its deck
## before it comes to your hand.
const LIFT_OFF := 0.02
const SLIDE_OFF := 0.15
## Hits asked for when asking whether something has room: the sand answers
## once for each of its faces a shape crosses, which mustn't crowd out the rest.
const TOUCHES := 64
## Why take does nothing: riding, stunned, at the helm.
const RIDING := "not from the board"
const STUNNED := "your hands won't close"
const AT_HELM := "not from the helm"
## The cutter's hot spot off a seam (Scrapping).
const NO_SEAM := Scrapping.NO_SEAM

var held: RigidBody3D
var phase := Phase.EMPTY
## What you hold that's too heavy to carry.
var grasp: Grasp
## The deck's free ring or frame face a piece you have hold of would join
## at, and at how many quarter turns (Fitting).
var stand: Socket
var _stand_turns := 0
## The line you work hand over hand.
var reel: Reel
## Your hands' work on wrecks and ruins with a tool.
var _scrapping: Scrapping
## What your look meets.
var _sight: Sight
## Where what's in your hands would go.
var _fitting: Fitting
## What the look ray hits: a loose part, or a device and, when it's a fitted
## part, that part's socket, or the sand itself (not a ruin standing in it);
## and where it hit.
var look_part: Part
var look_line: Line
var look_device: Device
var look_socket: Socket
var look_sand := false
## Looking at a ruin's bed, which sleeps you there.
var look_bed := false
## A static fitting you aim at whose `fixture` meta works it by hand.
var look_fixture: CollisionObject3D
var look_point := Vector3.ZERO
var look_normal := Vector3.UP
## A piece of a wreck that some work takes away: a plate, a layer of sand, a
## hazard; or the wreck whose shell you look at.
var look_work: StaticBody3D
## The wreck your look meets, its shell or a piece of it, and a piece of it
## that takes no work (a plate cut away, a hazard dealt with).
var look_wreck: Wreckage
var look_scrap: StaticBody3D
## Your line of sight, from your eyes to whatever it stops at, or as far as you reach.
var sight_from := Vector3.ZERO
var sight_to := Vector3.ZERO
## The free socket the held part leans toward, how far your line of sight
## passes from where the part would sit there, m, and how hard it leans, 0 to 1.
var socket: Socket
var gap := INF
var pull := 0.0
## What the readout says about why use did nothing, while it shows.
var notice := ""
## Empty-handed at a deck, the pieces take would move, as they're
## highlighted: every piece of it, or the bare one that comes off.
var moves: Array[Chassis] = []
## Where what you hold, or have hold of, would stick: the sticky face your
## look meets, as {deck, piece, face, pose in the deck's frame, out, why,
## warn}; {} where it meets none.
var sticking := {}

var _player: Player
var _tuning := Tuning.current()
var _hooked := false
## The held part's shapes, shrunk copies of them, and their bounds and middle
## in the part's own frame.
var _shapes: Array[CollisionShape3D] = []
var _skins: Array[Shape3D] = []
var _bounds := AABB()
var _middle := Vector3.ZERO
var _layers := Vector2i.ZERO
var _freeze_mode := RigidBody3D.FREEZE_MODE_STATIC
## How the held part is turned relative to your heading.
var _carry := Basis.IDENTITY
## How far in front of your eyes you'd carry it, and how far it is now, m.
var _away := 0.0
var _held_at := 0.0
## How far a small thing in your arms is up to read, eased, 0 to 1.
var _reads := 0.0
## Where the held part is as the simulation knows it: placed by the tick
## alone, so its lines pull the same at any frame rate.
var _ticked := Transform3D.IDENTITY
## Progress through sliding out or arriving, 0 to 1; where arriving began, and
## how long the way has been blocked.
var _t := 0.0
var _from := Transform3D.IDENTITY
var _stuck := 0.0
var _slide := 0.0
## How far from its socket a part starts sliding out: past the crop, when
## picking leaves one there. Where it starts and which way it slides, in its
## source's frame.
var _slide_from := 0.0
var _slide_at := Transform3D.IDENTITY
var _slide_way := Vector3.BACK
## The device a part is coming out of, held still meanwhile so it can't drop
## onto the part, and what it was doing before.
var _source: Device
var _source_was := {}
## Take pressed while what you took is still on its way to your hands: done
## the moment it's there, so a part taken off goes straight back on.
var _take_queued := false
## Parts just let go, which can't push you until they're clear of you.
var _released: Array[Dictionary] = []
var _body_radius := 0.35
var _ghost: Node3D
var _ghost_look: StandardMaterial3D
var _marks: Node3D
var _mark_look: StandardMaterial3D
var _readout: Label
## A physical display has its own readable controls while the eye is focused.
var display_focused := false
## The aim dot and its line, out of the way while a menu is up.
var _hud: CanvasLayer
var _dot: Control
var _sound: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _seated_count := 0
var _notice_left := 0.0
var _cast := PhysicsShapeQueryParameters3D.new()
var _inside := PhysicsShapeQueryParameters3D.new()


func _ready() -> void:
	_player = get_parent() as Player
	grasp = Grasp.new(_player)
	_scrapping = Scrapping.new(self, _player)
	_sight = Sight.new(self, _player)
	_fitting = Fitting.new(self, _player, _sight)
	reel = Reel.new()
	add_child(reel)
	for child in _player.get_children():
		var body := child as CollisionShape3D
		if body != null and body.shape is CapsuleShape3D:
			_body_radius = (body.shape as CapsuleShape3D).radius
	_ghost = Node3D.new()
	_ghost.top_level = true
	_ghost.visible = false
	add_child(_ghost)
	_ghost_look = StandardMaterial3D.new()
	_ghost_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Seen through whatever is in the way, even the sand under a resting device.
	_ghost_look.no_depth_test = true
	_ghost_look.albedo_color = GHOST
	# Compiles its shader now, while the world loads: otherwise the first thing
	# taken out stalls its frame on it (10 ms on the desktop's GPU).
	_ghost_look.get_rid()
	_marks = Node3D.new()
	_marks.top_level = true
	_marks.visible = false
	add_child(_marks)
	_mark_look = StandardMaterial3D.new()
	_mark_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mark_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mark_look.albedo_color = Color(GHOST, MARK)
	_mark_look.grow = true
	_mark_look.grow_amount = MARK_GROW
	_mark_look.get_rid()
	_sound = AudioStreamPlayer.new()
	_sound.max_polyphony = 2
	_sound.bus = Sounds.WORLD
	add_child(_sound)
	var hum: AudioStreamOggVorbis = Sounds.TUG
	hum.loop = true
	_hum = AudioStreamPlayer.new()
	_hum.stream = hum
	_hum.bus = Sounds.WORLD
	add_child(_hum)
	_build_hud()
	get_tree().physics_frame.connect(_back_to_tick)


## Take: take what you're looking at, or, holding something, fit it if a socket
## is in tug range and put it down if not. Something too heavy to carry, you
## take hold of instead, and taking again lets go. Says whether it did anything.
func grab() -> bool:
	if _player.world.arrival != null and _player.world.arrival.take():
		return true
	if grasp.body != null:
		if stand != null:
			_fitting.stand_on(stand)
			return true
		if not sticking.is_empty():
			if sticking.why != "":
				return refuse(sticking.why)
			_fitting.stick_grasped()
			return true
		var why := _fitting.stand_why
		grasp.let_go()
		if why != "":
			refuse(why)
		return true
	if held != null:
		if phase != Phase.HELD:
			# On its way to your hands: done once it's there.
			_take_queued = true
			return true
		if socket != null:
			_fitting.fit(socket)
			return true
		if not sticking.is_empty():
			if sticking.why != "":
				return refuse(sticking.why)
			_fitting.stick_held()
			return true
		var why := _fitting.no_fit()
		if why != "":
			return refuse(why)
		drop()
		return true
	_look()
	var salvage := _player.world.salvage
	if _player.vitals.wounds.stunned():
		return refuse(STUNNED)
	# The board tows nothing: riding, you take only what comes off no line,
	# loose, into your hands. Aboard at the helm, nothing.
	if _player.helm != null:
		return refuse(AT_HELM) if look_device != null or look_part != null else false
	# A module still held fast in its wreck won't come, and taking hold of one
	# with a live hazard on it sets that off: a shock throws you off it.
	var target: Node = look_part if look_part != null else look_device
	var fast := salvage.held_fast(target)
	if fast != "":
		return refuse(fast)
	if salvage.touched(target, _player) == Wreckage.ELECTRICAL:
		return true
	if look_line != null:
		var gathered := look_line.gather(look_point)
		if gathered != null:
			_pick_up(gathered)
			return true
	var riding := _player.board != null
	# Standing on a deck, a device keeps its sockets: a part you aim at comes out of it.
	var own_part := look_socket != null and look_socket.part != null
	if look_device != null and look_device.host() != null and not (look_device.on_deck() and own_part):
		if riding:
			return refuse(RIDING)
		# Last on, first off: a seated device comes off whole, whatever of it you
		# aim at, once nothing's stuck on it.
		if not look_device.stuck().is_empty():
			return refuse("take what's on it off first")
		_take_off(look_device)
		return true
	if look_part != null:
		if riding and _player.waist.carries_line(look_part):
			return refuse(RIDING)
		salvage.unbury(look_part)
		_pick_up(look_part)
		return true
	if look_socket != null and look_socket.part != null:
		if riding:
			return refuse(RIDING)
		var deck_holds := (look_device as Chassis).holds(look_socket) if look_device is Chassis else ""
		if deck_holds != "":
			return refuse(deck_holds)
		salvage.claim(look_device)
		_take_out(look_device, look_socket)
		return true
	# A bare piece the rest of the deck holds together without comes off when
	# you aim at it; at any other, you take hold of the whole deck.
	var deck := look_device as Chassis
	if deck != null and deck.comes_off(deck.piece_at(look_point)):
		if riding:
			return refuse(RIDING)
		_unjoin(deck, deck.piece_at(look_point))
		return true
	if look_device != null and look_device.carryable:
		if riding and _player.waist.carries_line(look_device):
			return refuse(RIDING)
		salvage.unbury(look_device)
		_pick_up(look_device)
		return true
	if riding:
		return refuse(RIDING) if look_device != null else false
	if look_device != null and (not look_device.freeze or salvage.lying(look_device)):
		# Something found comes up out of the sand as you take hold of it.
		salvage.unbury(look_device)
		grasp.take(look_device)
		return true
	return false


## Use: work the device you look at, or use what you hold. Holding a line with
## nothing else to do, it goes on your waist; empty-handed, the selected line at
## your waist comes back to your hands. Says whether it did anything.
func interact() -> bool:
	if _player.world.arrival != null and _player.world.arrival.interact():
		return true
	_look()
	# A fitting worked by hand, such as a furnace's feed: its own Callable says what use does.
	if look_fixture != null and look_fixture.get_meta(&"fixture").call(_player):
		return true
	if look_bed and held == null and look_device == null and look_part == null:
		return _player.world.sleep.offer(_player)
	if look_work != null:
		return _scrapping.work_once()
	var op := Wreckage.tool_op(held) if phase == Phase.HELD else &""
	if look_wreck != null and op in [Wreckage.CUT, Wreckage.CLEAR]:
		var where := look_wreck.nearest_work(op, look_point)
		return refuse(where if where != "" else "nothing left on it for that")
	if op == Wreckage.CLEAR and look_sand:
		# Held down, it digs (scrap).
		return true
	if look_device != null and _player.world.salvage.held_fast(look_device) != "":
		return refuse(_player.world.salvage.held_fast(look_device))
	# A cable's plug held at a driven stake: the cable passes through its ring, or off it.
	var through := _cable_at_stake()
	if not through.is_empty():
		var why := (through.cable as Cable).route(through.stake)
		if why != "":
			return refuse(why)
		_play(Sounds.TIE)
		return true
	if look_device != null and look_device.interact(_player):
		# Marking Home requires ownership; a refusal must not claim its host.
		if not look_device is HomeBeacon:
			_player.world.salvage.claim(look_device)
		if look_device is Radio:
			_player.close_up.tuned(look_device)
		return true
	if held == null:
		if grasp.body == null and _player.waist.give_back():
			return true
		if not reel.connected_ropes().is_empty() and reel.chosen_body() == null:
			return refuse(Reel.CHOOSE_LINE)
		if grasp.body == null and look_device == null and look_part == null \
				and _player.ground_pose == &"prone" and _player.is_on_floor():
			return _player.world.sleep.offer(_player)
		return refuse("wrecked" if look_device.wrecked() else "nothing to use") if look_device != null else false
	if phase != Phase.HELD:
		return false
	var used := false
	if held is Part:
		used = (held as Part).use(_player, look_point)
	elif held is Device:
		used = (held as Device).use(_player, look_point)
	if used and held is Radio:
		_player.close_up.tuned(held)
	if used or _player.waist.take_from_hands():
		return true
	return refuse("no use for it there") if look_device != null else false


## Holding a cable's plug, looking at a driven stake: {cable, stake}, else {}.
func _cable_at_stake() -> Dictionary:
	if phase != Phase.HELD or not held is Part or (held as Part).kind != &"port":
		return {}
	var stake := look_device as Stake
	if stake == null or not stake.driven:
		return {}
	var cable := Cable.of(held as Part, _player.world)
	return {"cable": cable, "stake": stake} if cable != null else {}


## Continuing a waist return never takes a device's or ground work's Use.
func gathering_clear() -> bool:
	_look()
	return Controls.playing() and held is RopeTip and phase == Phase.HELD and grasp.body == null \
		and look_device == null and look_part == null and look_work == null \
		and look_wreck == null and look_scrap == null and not look_bed


func look_hook() -> RopeHook:
	if look_part is RopeHook and (look_part as RopeHook).socket != null:
		return look_part as RopeHook
	var at := look_socket
	while at != null:
		if at.part is RopeHook:
			return at.part as RopeHook
		at = at.get_meta(&"socket") if at.has_meta(&"socket") else null
	# Looking through the ring's hole meets its mounting face, not its small stem.
	if look_device != null:
		for seat in look_device.sockets():
			var hook := seat.part as RopeHook
			if hook != null and hook.guide.global_position.distance_to(look_point) <= _tuning.snap_reach:
				return hook
	return null


## Rotate held down: the mouse turns what you hold, or have hold of, instead
## of your view, `by` rad along and up the screen, its near side following the
## mouse: across turns it about the vertical, up and down about your view's
## right. Says whether it did.
func turn(by: Vector2) -> bool:
	if not rotating():
		return false
	var turned := Basis(Vector3.UP, by.x) * Basis(Vector3.RIGHT, by.y)
	if grasp.body != null:
		grasp.turn(turned)
	else:
		_carry = (turned * _carry).orthonormalized()
	return true


## Whether rotate has the mouse: held down, with something in your hands, and
## the mouse looking rather than free to click.
func rotating() -> bool:
	return (held != null or grasp.body != null) and reel.in_hand() == null \
		and not Controls.mouse_free and Controls.held(&"hands_rotate")


## Takes a body straight into your hands from wherever it is, if they're free:
## a coil's rest once its first end is on, a line untied from your waist.
func hold(body: RigidBody3D) -> void:
	if held != null or body == null:
		return
	grasp.let_go()
	_grip(body)
	_arrive_from(body.global_transform)
	# A line's end in your hand tows what it leads to.
	_player.world.ropes.count_towed()


## Reel in by `notches`, or pay out for a negative count: a line's end in
## your hand or at your waist reels; else what you carry, or have hold of,
## comes nearer or goes farther. Not in a menu, the inventory or riding. Says
## whether it did anything.
func scroll(notches: int) -> bool:
	if not reel.working():
		return false
	var by := notches * Reel.NOTCH
	if grasp.body != null:
		var box := _box_of(grasp.body)
		grasp.bring(by, _body_radius + Vector2(box.size.x, box.size.z).length() * 0.5 + GRASP_CLEAR, _tuning.reach)
		return true
	if held != null and phase == Phase.HELD:
		var nearest := nearest_hold(_bounds)
		_away = clampf(_away - by, nearest, maxf(HOLD_FARTHEST, nearest))
		return true
	return false


## Lets go of what you hold without dropping it, for something else to take.
func stow() -> RigidBody3D:
	var body := held
	if body != null:
		_let_go()
	return body


## Let go, moving as you were.
func drop() -> void:
	_landing()
	_release(_player.velocity)


## Throw: let go with a throw along your aim.
func throw() -> void:
	if held != null:
		_play(Sounds.THROW)
	_landing()
	_release(_player.velocity - _player.camera.global_basis.z * _tuning.throw_speed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hands_grab"):
		if grab():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if interact():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("switch_band"):
		# The band switch, on the radio the tuning actions work.
		var radio := dialled()
		if radio != null and radio.switch_band():
			_player.close_up.tuned(radio, false)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("mark_frequency"):
		# A radio in your hands: mark where its dial stands, or unmark it.
		if held is Radio and phase == Phase.HELD and (held as Radio).has_dial_marks() and not (held as Radio).wrecked():
			(held as Radio).toggle_mark()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hands_throw") and held != null and not Controls.mouse_free:
		throw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hands_throw") and not Controls.mouse_free and punch():
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("rope_yank", false, true) and not Controls.mouse_free \
			and grasp.body == null and (held == null or reel.in_hand() != null):
		if reel.yank():
			get_viewport().set_input_as_handled()
	elif _tunes(event):
		get_viewport().set_input_as_handled()
	# Exactly, so bringing near or pushing out never reels a line too.
	elif event.is_action_pressed("reel_in", false, true) or event.is_action_pressed("pay_out", false, true):
		# A worked drum wins over waist lines, so hoisting never trims the sheet too.
		_look()
		if reel.working() and held == null and grasp.body == null and look_device is ManualWinch:
			(look_device as ManualWinch).notch(1 if event.is_action_pressed("reel_in", false, true) else -1, _player)
			get_viewport().set_input_as_handled()
		elif reel.working() and reel.notch(1 if event.is_action_pressed("reel_in", false, true) else -1):
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("bring_near") or event.is_action_pressed("push_out"):
		if scroll(1 if event.is_action_pressed("bring_near") else -1):
			get_viewport().set_input_as_handled()


## Reel in and pay out tune a radio a notch, the fine-tune actions a fine
## step and the volume actions turn its knob, on the radio dialled() picks;
## with none, reel in and pay out reel.
func _tunes(event: InputEvent) -> bool:
	if not reel.working():
		return false
	for action: StringName in TUNES:
		# Exactly, so each modifier means only its own.
		if event.is_action_pressed(action, false, true):
			var radio := dialled()
			if radio == null:
				return false
			var how: Array = TUNES[action]
			var turned := radio.turn_volume(how[0]) if how[2] else radio.tune(how[0], how[1])
			if turned:
				_player.close_up.tuned(radio, how[1])
			return turned
	return false


## The radio the tuning actions work: the one you look at, or the first in
## the system of a console you look at, unless you're reeling the line in
## your hand; else the one you hold, while there's no line at your waist to reel.
func dialled() -> Radio:
	_look()
	return dial()


## The radio the tuning actions work, as your look last fell.
func dial() -> Radio:
	if reel.in_hand() != null:
		return null
	var radio := tuned_by_look()
	if radio == null and held is Radio and phase == Phase.HELD and reel.line() == null:
		radio = held
	return radio


## The radio your look tunes: the one you look at, or the first in the system
## of a console you look at.
func tuned_by_look() -> Radio:
	if look_device is Radio:
		return look_device
	var console := look_device as Console
	if console != null:
		for device in console._system():
			if device is Radio:
				return device
	return null


## Use held down with a heat cutter or a scoop, for `delta` s (Scrapping).
## Says whether it did any work.
func scrap(delta: float) -> bool:
	return _scrapping.scrap(delta)


func _physics_process(delta: float) -> void:
	var world := _player.world
	if world == null:
		return
	if not _hooked:
		world.origin_shifted.connect(_on_origin_shifted)
		_hooked = true
	if phase != Phase.EMPTY and not is_instance_valid(held):
		_forget()
	_look()
	if Controls.playing() and Controls.held(&"interact"):
		scrap(delta)
	else:
		_scrapping.stop()
	_held_at = _away + (_held_at - _away) * exp(-HOLD_EASE * delta)
	var reads := 1.0 if _reading() else 0.0
	_reads = reads + (_reads - reads) * exp(-HOLD_EASE * delta)
	# A radio in your hands you tune turns its face up to your eyes, to read its dial.
	if held is Radio and _player.close_up.radio == held:
		var to_eyes := Basis(Vector3.RIGHT, _player.camera.rotation.x)
		_carry = _carry.slerp(to_eyes, 1.0 - exp(-HOLD_EASE * delta)).orthonormalized()
	match phase:
		Phase.TAKING:
			if not is_instance_valid(_source):
				_arrive_from(held.global_transform)
			else:
				_t = minf(_t + delta / _tuning.take_seconds, 1.0)
				held.global_transform = _sliding()
				if _t >= 1.0:
					_arrive_from(held.global_transform)
		Phase.ARRIVING:
			_arrive(delta)
		Phase.HELD:
			_fitting.tug(delta)
			held.global_transform = _within_reach(_pose(false))
	if phase == Phase.HELD:
		_ticked = held.global_transform
		if _take_queued:
			_take_queued = false
			_fitting.tug(0.0)
			grab()
	grasp.step(delta)
	if grasp.slipped:
		grasp.slipped = false
		refuse("it won't shift")
	_find_stand(delta)
	_unblock_released()
	_show(delta)


## Drawn frame by frame too, so a held part never trails your view as you
## turn; the next tick puts it back where the last one left it.
func _process(_delta: float) -> void:
	if _hud != null:
		_hud.visible = Controls.playing() and not display_focused
		# Close up on a dial the view isn't your aim.
		_dot.visible = _player.close_up.close < 0.5
	if phase == Phase.HELD and is_instance_valid(held):
		held.global_transform = _within_reach(_pose(true))
		held.global_position += reel.stroke(held)


## Before anything reads it this tick.
func _back_to_tick() -> void:
	if phase == Phase.HELD and is_instance_valid(held):
		held.global_transform = _ticked


## What your look meets now, set as look_* (Sight).
func _look() -> void:
	_sight.look()


## How far along your look it meets something, out to `far`, m, or INF (Sight).
func meets(far: float) -> float:
	return _sight.meets(far)


## Whether your look ends on sand out past reach, or on none (Sight).
func sand_beyond_reach() -> bool:
	return _sight.sand_beyond_reach()


## Whether a hit is the sand's own surface, its heightmap, which a deck lifts
## itself clear of: a ruin's boxes share its body and still count as in the way.
static func _sand(hit: Dictionary) -> bool:
	var body := hit.collider as StaticBody3D
	if body == null:
		return false
	var holder := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as CollisionShape3D
	return holder != null and holder.shape is HeightMapShape3D


## Says in the readout, for a moment, why use did nothing.
func say(why: String) -> void:
	notice = why
	_notice_left = NOTICE


## Take or use can't do what you aim at: the readout says why for a moment
## and a soft knock sounds, never silence (Hunter, 2026-10-17: "we should
## have a way to communicate when a slot is full"). Every refusal comes
## through here. Says it answered.
func refuse(why: String) -> bool:
	say(why)
	_play(Sounds.REFUSE)
	return true


## A body's bounds in its own frame, kept once worked out.
static func _box_of(body: RigidBody3D) -> AABB:
	if body.has_meta(&"hands_box"):
		return body.get_meta(&"hands_box")
	var box := _body_box(body)
	body.set_meta(&"hands_box", box)
	return box


## How near your eyes something held comes at its nearest, m, its middle
## straight ahead: HOLD_NEAREST, or farther for one too big to come so near.
## `bounds` are its own.
func nearest_hold(bounds: AABB) -> float:
	return maxf(HOLD_NEAREST, _body_radius + bounds.size.length() * 0.5)


## A body's middle in its own frame, by its shapes as they stand now: the
## point held ahead of your eyes.
static func middle_of(body: Node3D) -> Vector3:
	return _body_box(body).get_center()


## nearest_hold() for a body, by its shapes as they stand now.
func nearest_hold_of(body: Node3D) -> float:
	return nearest_hold(_body_box(body))


## A body's bounds in its own frame, as its shapes stand now.
static func _body_box(body: Node3D) -> AABB:
	return _shapes_box(body.get_children())


## The bounds of the shapes among some nodes, in their parent's frame.
static func _shapes_box(nodes: Array) -> AABB:
	var box := AABB()
	var first := true
	for child: Node in nodes:
		var shape := child as CollisionShape3D
		if shape != null and shape.shape != null:
			var each := shape.transform * Catalog.bounds(shape.shape)
			box = each if first else box.merge(each)
			first = false
	return box

func _pick_up(body: RigidBody3D) -> void:
	var stake := body as Stake
	if stake != null and stake.driven:
		# Pulled up out of the sand first, so its way to your hand is clear.
		stake.driven = false
		stake.global_position.y = _player.world.height_under(stake.global_position) + Stake.LENGTH * 0.5 + 0.02
	_grip(body)
	_arrive_from(body.global_transform)
	_play(Sounds.SAND_TAKE)


## Its host holds still while a stuck device lifts straight off its face,
## then it comes to your hand; too heavy to carry, it comes off standing on
## the sand beside the deck, and you have hold of it.
func _take_off(device: Device) -> void:
	_player.world.salvage.claim(device)
	var host := device.host()
	var from := host.seat_of(device)
	var way := from.outward()
	if not device.carryable:
		host.dismount(from)
		var beside := _beside_deck(device, host) if host is Chassis else Transform3D()
		if beside != Transform3D():
			_player.world.teleport(device, beside)
		else:
			_player.world.teleport(device, device.global_transform.translated(host.global_basis * way * LIFT_OFF))
		grasp.take(device)
		_play(Sounds.UNSEAT)
		return
	_begin_slide(host, device.transform, way)
	host.dismount(from)
	_grip(device)
	_slide = _bounds.size.y + 0.02
	_slide_from = 0.0
	_t = 0.0
	phase = Phase.TAKING
	_play(Sounds.UNSEAT)


## What you take out holds its source still, and slides from where it sat
## there along its way out, both in the source's frame.
func _begin_slide(source: Device, at: Transform3D, way: Vector3) -> void:
	_source = source
	_source_was = {"freeze": source.freeze, "velocity": source.linear_velocity, "spin": source.angular_velocity}
	source.freeze = true
	_slide_at = at
	_slide_way = way.normalized()


## Off a deck, a device comes down on the sand beside it, on the clear side
## nearest you: left on a floating deck, dragging it would rub the deck
## along with it. Empty if no side is clear.
func _beside_deck(device: Device, deck: Device) -> Transform3D:
	var reach := _shapes_box(deck.get_children())
	var own := _shapes_box(device.get_children())
	var half := maxf(own.size.x, own.size.z) * 0.5
	var middle := Vector3(reach.get_center().x, 0.0, reach.get_center().z)
	var world := _player.world
	var sides: Array[Transform3D] = []
	for along: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out := deck.global_transform * (middle + along * (absf(along.dot(reach.size)) * 0.5 + half + 0.25))
		# Its foot clear of the highest sand under it, so it never starts in a slope.
		var ground := world.height_under(out)
		for corner: Vector3 in [Vector3(1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(-1, 0, -1)]:
			ground = maxf(ground, world.height_under(out + corner * half))
		out.y = ground - own.position.y + 0.05
		sides.append(Transform3D(device.global_basis, out))
	var me := _player.global_position
	sides.sort_custom(func(a: Transform3D, b: Transform3D) -> bool:
		return a.origin.distance_squared_to(me) < b.origin.distance_squared_to(me))
	# Tested a little above the sand, so only something standing there, a wall,
	# you or another device, rules a side out.
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = own.size
	query.shape = box
	query.exclude = [device.get_rid(), deck.get_rid()]
	for side in sides:
		query.transform = side.translated_local(own.get_center() + Vector3.UP * 0.25)
		if _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return side
	return Transform3D()


## A bare piece comes off the deck the way one goes on, out across a ring it
## leaves or off the frame's face it was on, while the deck holds still, then
## to your hand.
func _unjoin(deck: Chassis, off: Chassis) -> void:
	var at := deck.global_transform * off.pose().origin
	var out := deck.global_basis * off.joined_at.transform.basis.z if off.on_frame() else Vector3.ZERO
	var was := {"freeze": deck.freeze, "velocity": deck.linear_velocity, "spin": deck.angular_velocity}
	var piece := deck.detach(off)
	var from := deck.ring_to(at)
	if out == Vector3.ZERO and from != null:
		out = deck.global_basis * from.transform.basis.z
	_play(Sounds.UNSEAT)
	_begin_slide(deck, deck.global_transform.affine_inverse() * piece.global_transform, deck.global_basis.inverse() * out)
	_source_was = was
	_grip(piece)
	_slide = SLIDE_OFF
	_slide_from = 0.0
	_t = 0.0
	phase = Phase.TAKING


## Where what you have hold of would join or stick, shown there (Fitting).
func _find_stand(delta: float) -> void:
	_fitting.find_stand(delta)


## Having hold of something, a throw punches it where you look: a small shove
## to right a tipped rig with. Says whether it did.
func punch() -> bool:
	var body := grasp.body
	if body == null or grasp.showing() or held != null:
		return false
	var at := look_point if look_device == body else body.global_transform * _box_of(body).get_center()
	body.apply_impulse(-_player.camera.global_basis.z * _tuning.punch_impulse, at - body.global_position)
	_play(Sounds.SEAT[_seated_count % Sounds.SEAT.size()])
	return true


## The device holds still while the part slides straight out its socket's
## way, or off the face it was stuck on, then the part comes to your hand.
func _take_out(device: Device, from: Socket) -> void:
	_begin_slide(device, from.transform, from.outward())
	var grouped := from.part is RopeTip and RopeBundle.members(from.part).size() > 1
	var part := device.pop(from) if grouped else device.take(from)
	_grip(part)
	_slide = part.depth()
	_slide_from = from.part.depth() if from.part != null else 0.0
	_t = 0.0
	phase = Phase.TAKING
	_play(Sounds.PICK if device is Planter and part.kind == &"food" else Sounds.UNSEAT)
	taken.emit(part, device, from)


func _grip(part: RigidBody3D) -> void:
	if _player.world.arrival != null:
		_player.world.arrival.recover(part)
	held = part
	_layers = Vector2i(part.collision_layer, part.collision_mask)
	_freeze_mode = part.freeze_mode
	part.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	part.freeze = true
	# Held, it touches nothing: it can't shove a device, a part or you.
	part.collision_layer = 0
	part.collision_mask = 0
	_unblock(part)
	refresh_held_shape()
	_carry = _tidy(Basis(Vector3.UP, -_player.global_rotation.y) * part.global_basis.orthonormalized())
	# A small thing comes into your arms, all the way in; anything else out ahead.
	_away = nearest_hold(_bounds) if carried() else _tuning.hold_distance
	_held_at = _away
	_reads = 0.0
	pull = 0.0
	socket = null
	gap = INF


## New nested ends change the carried body's real bounds and preview together.
func refresh_held_shape() -> void:
	if not is_instance_valid(held):
		return
	var part := held
	_shapes.clear()
	_skins.clear()
	for child in part.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		_shapes.append(shape)
		_skins.append(_skin(shape.shape))
	if not _shapes.is_empty():
		_bounds = _shapes_box(_shapes)
	_middle = _bounds.get_center()
	_build_ghost(part)


func _arrive_from(pose: Transform3D) -> void:
	_from = pose
	_t = 0.0
	_stuck = 0.0
	phase = Phase.ARRIVING


## Eases to your hand, but never through anything: blocked, it waits, and
## blocked too long it skips to your hand, which is always clear.
func _arrive(delta: float) -> void:
	var next := minf(_t + delta / ARRIVE, 1.0)
	var pose := _within_reach(_blend(_from, _hand(false), smoothstep(0.0, 1.0, next)))
	if _clear(pose):
		_t = next
		_stuck = 0.0
		held.global_transform = pose
	else:
		_stuck += delta
		if _stuck > STUCK:
			_t = 1.0
			held.global_transform = _within_reach(_hand(false))
	if _t >= 1.0:
		phase = Phase.HELD
		_release_source()


func _release(velocity: Vector3) -> void:
	if held == null:
		return
	var part := held
	var middle := _middle
	var radius := _bounds.size.length() * 0.5
	_let_go()
	part.linear_velocity = velocity
	part.angular_velocity = Vector3.ZERO
	# It may start inside you: it can't push you until it's clear of you.
	part.add_collision_exception_with(_player)
	_released.append({"part": part, "middle": middle, "radius": radius})


func _let_go() -> void:
	var part := held
	_release_source()
	part.freeze = false
	part.freeze_mode = _freeze_mode
	part.collision_layer = _layers.x
	part.collision_mask = _layers.y
	_forget()


func _forget() -> void:
	_release_source()
	_take_queued = false
	_fitting.forget()
	held = null
	phase = Phase.EMPTY
	socket = null
	sticking = {}
	pull = 0.0
	gap = INF
	_clear_ghost()


func _release_source() -> void:
	if is_instance_valid(_source):
		_source.freeze = _source_was.freeze
		if not _source.freeze:
			_source.linear_velocity = _source_was.velocity
			_source.angular_velocity = _source_was.spin
	_source = null


func _unblock_released() -> void:
	for i in range(_released.size() - 1, -1, -1):
		var gone: Dictionary = _released[i]
		if not is_instance_valid(gone.part):
			_released.remove_at(i)
			continue
		var part: RigidBody3D = gone.part
		var off: Vector3 = part.global_transform * gone.middle - _player.global_position
		if Vector2(off.x, off.z).length() > _body_radius + gone.radius or off.y < -gone.radius or off.y > 2.5:
			_unblock(part)


func _unblock(part: RigidBody3D) -> void:
	for i in range(_released.size() - 1, -1, -1):
		if is_instance_valid(_released[i].part) and _released[i].part == part:
			_released.remove_at(i)
			part.remove_collision_exception_with(_player)


## Where the held part sits: in your hand, leaning toward a socket as hard as
## the tug pulls, or gone where it would stick; as drawn this frame, or as
## the tick knows it.
func _pose(drawn: bool) -> Transform3D:
	return _fitting.lean(_hand(drawn), drawn)


## As far in front of your eyes as you'd carry it, turned with you, and
## stopped short of anything in the way, so it never ends up inside the sand
## or a device.
func _hand(drawn: bool) -> Transform3D:
	var eye := _player.camera.global_transform
	if not drawn:
		eye.origin = _player.global_transform * _player.feel.steady_eye()
	var basis := _held_basis()
	var ahead := -eye.basis.z.normalized() * _held_at
	if held is Cutter:
		# A cutter's carried low at your right, aimed where you look, so what
		# it bites is in sight.
		var at := eye.origin + eye.basis * TOOL_AT
		var aim := (sight_to - at) if (sight_to - at).length() > 0.3 else -eye.basis.z
		basis = Basis.looking_at(aim.normalized(), Vector3.UP if absf(aim.normalized().y) < 0.98 else Vector3.BACK)
		ahead = -eye.basis.z.normalized() * TOOL_AWAY
		var low := Transform3D(basis, at - basis * _middle)
		return low.translated(ahead * _sweep(low, ahead))
	var start := Transform3D(basis, eye.origin - basis * _middle)
	if carried():
		ahead = _in_arms(ahead)
	return start.translated(ahead * _sweep(start, ahead))


## Whether what you hold is a small thing carried in your arms: not a tool
## you aim, a deck or anything a line is on, which stay out ahead.
func carried() -> bool:
	if not is_instance_valid(held) or held is Cutter or held is Chassis or held is RopeTip or held is RopeHook:
		return false
	if held is Part and (held as Part).kind == &"coil":
		return false
	if held.get_children().any(func(child: Node) -> bool: return child is RopeEnd):
		return false
	return _bounds.size.length() < _tuning.pick_small


## Where a carried thing goes from your eyes, given `ahead`, where it'd be
## straight out: all the way in it hangs low in your arms, out of your face,
## swinging a little with your look (Hunter, 2026-10-22); pushed out, it rises
## to straight ahead by where you'd hold anything. Read (a radio you're tuning,
## a booklet open), it comes up into view.
func _in_arms(ahead: Vector3) -> Vector3:
	var turn := Basis(Vector3.UP, _player.global_rotation.y)
	var pitch := _player.camera.rotation.x
	var low := turn * Basis(Vector3.RIGHT, pitch * _tuning.suit_carry_follow - _tuning.suit_carry_drop) * Vector3.FORWARD
	var out := clampf(inverse_lerp(nearest_hold(_bounds), _tuning.hold_distance, _held_at), 0.0, 1.0)
	var carried_at := low.slerp(ahead.normalized(), out) * _held_at
	return carried_at.lerp(turn * Basis(Vector3.RIGHT, pitch) * _tuning.suit_read, _reads)


func _reading() -> bool:
	return (held is Radio and _player.close_up.radio == held) \
		or (held is SailingNotes and Controls.ui != null and Controls.ui.is_open())


## A pose for what you hold, kept within reach of its lines: turning round or
## a tug toward a ring further off can't stretch a line, only your body can.
func _within_reach(pose: Transform3D) -> Transform3D:
	for child in held.get_children():
		var end := child as RopeEnd
		if end != null:
			var at := pose * end.position
			pose.origin += _player.world.ropes.reach(end, at) - at
	return pose


## How far along motion the held part can move from start before it touches
## something, 0 to 1. Starting inside something, it can't tell, so all the way.
func _sweep(start: Transform3D, motion: Vector3) -> float:
	var space := get_world_3d().direct_space_state
	_cast.exclude = _exclusions()
	_cast.motion = motion
	var safe := 1.0
	for shape in _shapes:
		_cast.shape = shape.shape
		_cast.transform = start * shape.transform
		var fraction := space.cast_motion(_cast)
		if fraction[1] > 0.0:
			safe = minf(safe, fraction[0])
	return safe


func _clear(pose: Transform3D) -> bool:
	var space := get_world_3d().direct_space_state
	_inside.exclude = _exclusions()
	for i in _shapes.size():
		_inside.shape = _skins[i]
		_inside.transform = pose * _shapes[i].transform
		if not space.intersect_shape(_inside, 1).is_empty():
			return false
	return true


func _sliding() -> Transform3D:
	var out := 1.0 - (1.0 - _t) * (1.0 - _t)
	return (_source.global_transform * _slide_at).translated(_source.global_basis * _slide_way * (_slide_from + _slide * out))


## A socket's frame in the world (Fitting).
func _frame_of(into: Socket) -> Transform3D:
	return Fitting.frame_of(into)


## How what you hold is turned in the world as the tick has it.
func _held_basis() -> Basis:
	return Basis(Vector3.UP, _player.global_rotation.y) * _carry


## Between two poses of the held part, turning about its own middle.
func _blend(a: Transform3D, b: Transform3D, t: float) -> Transform3D:
	var basis := a.basis.orthonormalized().slerp(b.basis.orthonormalized(), t)
	var middle := (a * _middle).lerp(b * _middle, t)
	return Transform3D(basis, middle - basis * _middle)


func _exclusions() -> Array[RID]:
	var out: Array[RID] = [_player.get_rid()]
	if is_instance_valid(held):
		out.append(held.get_rid())
	return out


## Squared up to your heading, whatever way it lay.
static func _tidy(turn: Basis) -> Basis:
	var x := _axis(turn.x)
	var y := _axis(turn.y - x * turn.y.dot(x))
	return Basis(x, y, x.cross(y))


static func _axis(v: Vector3) -> Vector3:
	var a := v.abs()
	if a.x >= a.y and a.x >= a.z:
		return Vector3(signf(v.x), 0.0, 0.0)
	if a.y >= a.z:
		return Vector3(0.0, signf(v.y), 0.0)
	return Vector3(0.0, 0.0, signf(v.z))


static func _skin(shape: Shape3D) -> Shape3D:
	var box := shape as BoxShape3D
	if box == null:
		return shape
	var thinner := BoxShape3D.new()
	thinner.size = (box.size - Vector3.ONE * SKIN * 2.0).max(Vector3.ONE * SKIN)
	return thinner


func _on_origin_shifted(by: Vector2i) -> void:
	var offset := Vector3(by.x, 0.0, by.y) * _tuning.chunk_size
	_from.origin -= offset
	_ticked.origin -= offset
	_fitting.shift(offset)


func _build_ghost(part: RigidBody3D) -> void:
	_clear_ghost()
	_copy_looks(part.get_children(), _ghost, _ghost_look)


## Copies of the meshes among `nodes`, where they sit in their body, drawn in `look`.
static func _copy_looks(nodes: Array, into: Node3D, look: Material) -> void:
	for child in nodes:
		var mesh := child as MeshInstance3D
		if mesh == null:
			continue
		var copy := MeshInstance3D.new()
		copy.mesh = mesh.mesh
		copy.transform = mesh.transform
		copy.material_override = look
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		into.add_child(copy)


## Empty-handed at a deck, take's two ways show before you take: a bare
## piece that would come off is highlighted alone, else the whole deck it
## would drag.
func _highlight() -> void:
	var deck := look_device as Chassis
	if held != null or grasp.body != null or look_socket != null or _player.board != null \
			or deck == null or deck.joined.is_empty():
		deck = null
	var piece := deck.piece_at(look_point) if deck != null else null
	var now: Array[Chassis] = []
	if deck != null and deck.comes_off(piece):
		now.append(piece)
	elif deck != null:
		now = deck.pieces()
	if now != moves:
		moves = now
		for child in _marks.get_children():
			child.free()
		if now.size() == 1:
			_copy_looks([piece.frame_view], _marks, _mark_look)
		elif deck != null:
			_copy_looks(deck.get_children(), _marks, _mark_look)
	_marks.visible = not moves.is_empty()
	if deck != null:
		_marks.global_transform = deck.global_transform


func _clear_ghost() -> void:
	for child in _ghost.get_children():
		child.free()
	_ghost.visible = false


func _play(stream: AudioStream) -> void:
	_sound.stream = stream
	_sound.play()


func seat_sound() -> void:
	_play(Sounds.SEAT[_seated_count % Sounds.SEAT.size()])
	_seated_count += 1


## What you let go of lands softly in the sand, heard where it does.
func _landing() -> void:
	if held != null and phase == Phase.HELD:
		Sounds.on_landing(held, self)


## A dot where you aim and, under it, one short line about what it's on.
func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 99
	add_child(hud)
	_hud = hud
	var dot := Control.new()
	_dot = dot
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.draw.connect(func() -> void:
		dot.draw_circle(Vector2.ZERO, 2.5, dot.get_theme_color(&"shadow", &"Palette"))
		dot.draw_circle(Vector2.ZERO, 1.5, dot.get_theme_color(&"text", &"Palette")))
	hud.add_child(dot)
	_readout = Label.new()
	_readout.theme_type_variation = &"AsideValue"
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.set_anchors_preset(Control.PRESET_CENTER)
	_readout.offset_left = -400.0
	_readout.offset_right = 400.0
	_readout.offset_top = 10.0
	_readout.offset_bottom = 70.0
	_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readout.modulate.a = 0.0
	hud.add_child(_readout)


## What the look-at line says now (Readout).
func line() -> String:
	return Readout.line(self, _player)


## A thing's label and, at most, the one thing you need about it now (Readout).
static func describe(label: String, stats: Dictionary) -> String:
	return Readout.describe(label, stats)


func _show(delta: float) -> void:
	_readout.visible = not _player.suit.open and Controls.playing()
	_notice_left = maxf(_notice_left - delta, 0.0)
	if _notice_left <= 0.0:
		notice = ""
	var said := Readout.said(self, _player)
	if said != "" and said != _readout.text:
		_readout.text = said
	_readout.modulate.a = move_toward(_readout.modulate.a, 1.0 if said != "" else 0.0, delta * 8.0)

	_ghost.visible = socket != null and _fitting.in_sight(socket)
	if socket != null:
		_ghost.global_transform = _fitting.seat_pose(socket)
		_ghost_look.albedo_color.a = 0.2 + 0.3 * pull
	elif held is Stake and phase == Phase.HELD and look_sand:
		# Where it will go in.
		_ghost.visible = true
		_ghost.global_transform = Transform3D(Basis(Vector3.UP, held.global_rotation.y),
			Vector3(look_point.x, _player.world.height_under(look_point) + Stake.DRIVEN_AT, look_point.z))
		_ghost_look.albedo_color.a = 0.3
	_highlight()
	if pull > 0.01:
		_hum.volume_db = linear_to_db(pull)
		if not _hum.playing:
			_hum.play()
	elif _hum.playing:
		_hum.stop()

	Dev.put("hands/held", held.get(&"label") if held != null
		else ("hold " + str(grasp.body.get(&"label")) if grasp.body != null else "-"))
	Dev.put("hands/tug", "%.2f %.2fm" % [pull, gap] if socket != null else "-")
