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
## Aiming from this far behind a socket's face still counts as its open side, m.
const OPEN_MARGIN := 0.05
## Your line of sight passing this near a device's frame still offers it what
## you hold, m.
const NEAR_FRAME := 0.4
## Empty-handed, your line of sight passing this near a part fitted under a
## device looks at it, m: standing, it's out of sight under the frame. A look
## at the frame itself counts only this low on it, and only in this lower share
## of its height, so a thin frame like a chassis piece is still itself by its
## top and the upper half of its edges.
const UNDER := 0.15
const UNDER_SHARE := 0.5
## An offered socket leans what you hold at least this far in, 0 to 1, so the
## tug shows where it goes even with your aim off the spot.
const OFFER := 0.35
## How fast the tug swings over when a nearer socket wins, 1/s.
const SWING := 16.0
## The small thing your aim settled on stays the one until another is this much
## nearer your aim, so a wavering aim doesn't flicker between them.
const STICKY := 0.7
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
## Having hold of a lone piece, a deck's free ring or frame face whose place
## is this near it is offered, m: it can't get nearer, held off by the deck's edge.
const STAND_REACH := 1.2
## What you hold eases onto where it would stick in about this long, s, and
## a red tint, or amber for a warning, shows where it won't go.
const PLACE_SECONDS := 0.08
const BLOCKED := Color(1.0, 0.2, 0.15, 0.5)
const WARNED := Color(1.0, 0.65, 0.15, 0.35)
## Something too heavy to carry comes off its seat this far, m, so it starts
## clear of what it sat on; a chassis piece slides this far off its deck
## before it comes to your hand.
const LIFT_OFF := 0.02
const SLIDE_OFF := 0.15
## Hits asked for when asking whether something has room: the sand answers
## once for each of its faces a shape crosses, which mustn't crowd out the rest.
const TOUCHES := 64
## What a refusal calls each kind of socket that's full.
const SOCKET_NAMES := {&"battery": "battery slot", &"ring": "ring", &"bottom": "tray mount",
	&"plant_pot": "pot", &"plant_standard": "planter", &"plant_deep": "deep bed", &"port": "port", &"tie": "hook",
	&"water": "water socket", &"mod": "mod mount", &"food": "food slot", &"face": "frame face",
	&"computer_mod": "computer-mod port", &"computer_top": "computer-mod top", &"screen": "screen port", &"sail": "sail mount"}
const RIDING := "not from the board"
const STUNNED := "your hands won't close"
## What a piece of a wreck needs before it gives, said when you try it without.
const WRECK_NEEDS := {&"cut": "needs a heat cutter: hold use along its seams",
	&"clear": "needs a sand scoop: hold use on it", &"ground": "live: ground it with a stake first",
	&"seal": "breached: seal it first"}
## The cutter's hot spot off a seam, on one the sand holds, and flat.
const NO_SEAM := "trace the seam: the weld round its edge"
const SEAM_BURIED := "that seam's under the sand"
const CUTTER_FLAT := "the cutter's battery is flat"
## A scoop stroke takes this long, s.
const STROKE := 0.45
## A scoop on sand with no ruin under it, or on one dug out; a sieve this
## near the dig sifts it, m.
const NO_RUIN := "no ruin under this sand"
const DUG_OUT := "dug out: what's left is the weather's"
const SIFT_REACH := 4.0
const AT_HELM := "not from the helm"

var held: RigidBody3D
var phase := Phase.EMPTY
## What you hold that's too heavy to carry.
var grasp: Grasp
## The deck's free ring or frame face a piece you have hold of would join
## at; where it would sit there and at how many quarter turns; or why there's none.
var stand: Socket
var _stand_pose := Transform3D.IDENTITY
var _stand_turns := 0
var _stand_why := ""
## The line you work hand over hand.
var reel: Reel
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
## Where the held part is as the simulation knows it: placed by the tick
## alone, so its lines pull the same at any frame rate.
var _ticked := Transform3D.IDENTITY
## Where the tug leans the part, swung smoothly between sockets.
var _lean := Transform3D.IDENTITY
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
## Where what you hold would stick, in the deck's frame, eased toward as it
## moves; in the world as last placed; and how far it's gone there, 0 to 1.
var _stick_local := Transform3D.IDENTITY
var _stick_world := Transform3D.IDENTITY
var _placing := 0.0
## What's tinted now and how, so a tint is set and cleared once.
var _tinted: Node3D
var _tint := Color(0.0, 0.0, 0.0, 0.0)
var _tints := {}
## The device a part is coming out of, held still meanwhile so it can't drop
## onto the part, and what it was doing before.
var _source: Device
var _source_was := {}
## Take pressed while what you took is still on its way to your hands: done
## the moment it's there, so a part taken off goes straight back on.
var _take_queued := false
var _aim := Vector3.ZERO
## Where on the device you look at you aim, for its offer.
var _offer_at := Vector3.ZERO
## The small loose thing your aim settled on.
var _picked: RigidBody3D
## Parts just let go, which can't push you until they're clear of you.
var _released: Array[Dictionary] = []
var _body_radius := 0.35
var _ghost: Node3D
var _ghost_look: StandardMaterial3D
var _marks: Node3D
var _mark_look: StandardMaterial3D
var _readout: Label
## The aim dot and its line, out of the way while a menu is up.
var _hud: CanvasLayer
var _dot: Control
var _sound: AudioStreamPlayer
## Until a cutter or a scoop at work sounds again, s.
## Until a scoop's next stroke, s.
var _stroke := 0.0
var _hum: AudioStreamPlayer
var _seated_count := 0
var _notice_left := 0.0
var _cast := PhysicsShapeQueryParameters3D.new()
var _inside := PhysicsShapeQueryParameters3D.new()


func _ready() -> void:
	_player = get_parent() as Player
	grasp = Grasp.new(_player)
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
	if grasp.body != null:
		if stand != null:
			_stand_on(stand)
			return true
		if not sticking.is_empty():
			if sticking.why != "":
				return refuse(sticking.why)
			_stick_grasped()
			return true
		var why := _stand_why
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
			_fit(socket)
			return true
		if not sticking.is_empty():
			if sticking.why != "":
				return refuse(sticking.why)
			_stick_held()
			return true
		var why := _no_fit()
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
	_look()
	if _player.world.stoker != null and _player.world.stoker.interact(_player):
		return true
	# A radio in your hands with frequencies marked: use goes to the next.
	if held is Radio and phase == Phase.HELD and (held as Radio).next_mark():
		_player.close_up.tuned(held)
		return true
	if look_bed and held == null and look_device == null and look_part == null:
		return _player.world.sleep.offer(_player)
	if look_work != null:
		return _work_once()
	var op := Wreckage.tool_op(held) if phase == Phase.HELD else &""
	if look_wreck != null and op in [Wreckage.CUT, Wreckage.CLEAR]:
		var where := look_wreck.nearest_work(op, look_point)
		return refuse(where if where != "" else "nothing left on it for that")
	if op == Wreckage.CLEAR and look_sand:
		# Held down, it digs (scrap).
		return true
	if look_device != null and _player.world.salvage.held_fast(look_device) != "":
		return refuse(_player.world.salvage.held_fast(look_device))
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


func _look_hook() -> RopeHook:
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
	_player.world.ropes._towing()


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


## One line: what it is and, at most, the one thing you need about it now
## (Hunter, 2026-10-18: "almost everything is overload"). The rest shows
## another way or isn't said: weight in what you carry, a device's charge on
## its light, a line's strain in its creak, floating by where it hangs, what
## take would move by its highlight.
static func describe(label: String, stats: Dictionary) -> String:
	var now := _state(stats)
	return label if now == "" else "%s · %s" % [label, now]


## The first of these a thing has: a crop ripe or why it isn't growing, a
## device that would run but has no power, a radio's frequency, what a thing
## holds, then power, said as the device does it: output, or draws.
static func _state(stats: Dictionary) -> String:
	if stats.get("ripe", false):
		return "ripe"
	if stats.has("growing") and stats.growing != Plant.GROWING:
		return str(stats.growing)
	if stats.get("dark", false):
		return "no power"
	if stats.get("making_lph", 0.0) > 0.0:
		return "water %.1f L/h" % stats.making_lph
	if stats.has("water_l"):
		return "%.1f/%.1f L" % [stats.get("water_left_l", 0.0), stats.water_l]
	if stats.has("food_kcal"):
		return "%d kcal" % roundi(stats.get("food_left_kcal", 0.0))
	# A radio's frequency before its battery's charge: its dial is what you need.
	if stats.has("tuned"):
		return str(stats.tuned)
	if stats.has("charge_wh") and stats.get("capacity_wh", 0.0) > 0.0:
		return "%d/%d Wh" % [floori(stats.charge_wh), roundi(stats.capacity_wh)]
	if stats.get("in_w", 0.0) > 0.0:
		return "output %d W" % roundi(stats.in_w)
	if stats.get("out_w", 0.0) > 0.0:
		return "draws %d W" % roundi(stats.out_w)
	if stats.has("rope_m"):
		return "%d m" % roundi(stats.rope_m)
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("hands_grab"):
		if grab():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if interact():
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


## Use on a piece of a wreck: what you hold does that piece's work. A hazard's
## is done at once: a stake laid across a capacitor bank's terminals shorts it
## to the hull, and falls where it was; sealant is used up over a breached
## store. A cutter or a scoop works while use is held down (scrap). Without
## the tool for it, it says what it needs.
func _work_once() -> bool:
	var what := Wreckage.work_of(look_work)
	var wreck: Wreckage = look_work.get_meta(&"wreckage")
	var op := Wreckage.tool_op(held) if phase == Phase.HELD else &""
	if op != what[0]:
		return refuse(WRECK_NEEDS[what[0]])
	if op == Wreckage.CUT or op == Wreckage.CLEAR:
		if op == Wreckage.CUT and not (held as Cutter).cuts():
			return refuse(CUTTER_FLAT)
		return true
	var at := look_point + look_normal * 0.12
	if not wreck.make_safe(look_work, op):
		return false
	var used := stow()
	if used is Stake:
		used.global_position = at
		used.freeze = false
		ScrapFx.burst(_player.world.content, look_point, 50, 3.5)
		Sounds.play_at(used, Sounds.ZAP, -4.0, 3.0)
		say("grounded: the bank's dead")
	else:
		Sounds.play_at(_player, Sounds.SEAL, -4.0, 2.0)
		used.queue_free()
		say("sealed")
	return true


## Use held down with a heat cutter or a scoop, for `delta` s. The cutter
## fires where you aim, and on a plate's seam its hot spot cuts the weld away
## as you trace it; a scoop clears the open slice of a hold a stroke at a
## time. Says whether it did any work.
func scrap(delta: float) -> bool:
	if phase != Phase.HELD or not is_instance_valid(held):
		return false
	var op := Wreckage.tool_op(held)
	var what := Wreckage.work_of(look_work)
	if op == Wreckage.CUT:
		var cutter := held as Cutter
		if not cutter.cuts():
			say(CUTTER_FLAT)
			return false
		if what.is_empty() or what[0] != Wreckage.CUT:
			cutter.fire(look_point if look_point != Vector3.ZERO else sight_to, false)
			return false
		var wreck: Wreckage = look_work.get_meta(&"wreckage")
		var label: String = wreck.plan.plates[what[1]].label
		var result := wreck.cut(look_work, look_point, delta)
		if not result.seam:
			cutter.fire(look_point, false)
			say(NO_SEAM)
			return false
		cutter.fire(result.at, not result.get("buried", false))
		if result.get("buried", false):
			say(SEAM_BURIED)
			return false
		if result.get("through", false):
			ScrapFx.burst(_player.world.content, result.at, 60, 3.0)
			say("the %s comes away" % label)
		return true
	if op == Wreckage.CLEAR and what.is_empty() and look_sand:
		return _dig(delta)
	if op != Wreckage.CLEAR or what.is_empty() or what[0] != Wreckage.CLEAR:
		return false
	var wreck: Wreckage = look_work.get_meta(&"wreckage")
	_stroke -= delta
	if _stroke <= 0.0:
		_stroke = STROKE
		Sounds.play_at(_player, Sounds.SCOOP, -4.0, 2.0)
		ScrapFx.spray(_player.world.content, look_point, sight_from - look_point, Wreckage.SAND)
	if not wreck.clear(look_work, delta):
		say(wreck.not_yet(look_work))
		return false
	return true


## A scoop held on the sand over a ruin digs it out, a stroke and a spray at
## a time, as a storm would lay it bare (Sites.dig_at); a sieve in your suit
## or set down near sifts what it digs for the small things in it. A dune's
## ruin dug out with half its sand or more off by your hand is yours, not a
## storm's. Says whether it dug.
func _dig(delta: float) -> bool:
	var world := _player.world
	var got := world.shape.sites.dig_at(world.world_x(look_point.x), world.world_z(look_point.z), delta, world.time)
	var site: Structure = got[0]
	if site == null:
		say(NO_RUIN)
		return false
	if got[1] <= 0.0:
		say(DUG_OUT)
		return false
	_stroke -= delta
	if _stroke <= 0.0:
		_stroke = STROKE
		Sounds.play_at(_player, Sounds.SCOOP, -4.0, 2.0)
		ScrapFx.spray(world.content, look_point, sight_from - look_point, Wreckage.SAND)
	if _sieved():
		_sift(site, got[2])
	if site.source == &"dune" and site.dug_m >= site.depth * _tuning.dig_own_share \
			and site.with_dug(site.pure_taken(world.time)) >= site.depth:
		Deeds.done(world, &"dune_dig")
	return true


## Whether a sieve sifts what you dig: carried, or lying or stuck on a deck near.
func _sieved() -> bool:
	for each in _player.suit.carried:
		if is_instance_valid(each) and each.get_meta(&"catalog", &"") == &"sieve":
			return true
	var world := _player.world
	for node in world.content.get_children():
		var near := node is Node3D and (node as Node3D).global_position.distance_to(_player.global_position) <= SIFT_REACH + 3.0
		if not near:
			continue
		var things: Array = (node as Chassis).camp() if node is Chassis else [node]
		for each: Node in things:
			if each is Node3D and each.get_meta(&"catalog", &"") == &"sieve" \
					and (each as Node3D).global_position.distance_to(_player.global_position) <= SIFT_REACH:
				return true
	return false


## What a sieve finds in `m3` more of a site's sand: one of the light things of
## its lesser rows (Drift.carried_from) each time sift_per_m3 more is
## through, from its own stream of the site's id and how many have come, laid
## on the sand at your feet.
func _sift(site: Structure, m3: float) -> void:
	var world := _player.world
	var before := floori(site.sifted_m3 * _tuning.sift_per_m3)
	site.sifted_m3 += m3
	for k in range(before, floori(site.sifted_m3 * _tuning.sift_per_m3)):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([site.id, "sift", k])
		var at := Vector2(world.player_world_x(), world.player_world_z()) + Vector2.from_angle(rng.randf() * TAU) * 0.8
		Drift.lay(world, {"id": Finds._pick(rng, Drift.carried_from(site)), "x": at.x, "z": at.y,
			"yaw": rng.randf() * TAU, "charge": rng.randf() * Drift.CHARGE,
			"layer": SiteLoot.ERAS[site.era].layer if SiteLoot.ERAS.has(site.era) else Finds.SURFACE})
		say("the sieve turns something up")


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
		_stroke = 0.0
	_held_at = _away + (_held_at - _away) * exp(-HOLD_EASE * delta)
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
			_tug(delta)
			held.global_transform = _within_reach(_pose(false))
	if phase == Phase.HELD:
		_ticked = held.global_transform
		if _take_queued:
			_take_queued = false
			_tug(0.0)
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
		_hud.visible = Controls.playing()
		# Close up on a dial the view isn't your aim.
		_dot.visible = _player.close_up.close < 0.5
	if phase == Phase.HELD and is_instance_valid(held):
		held.global_transform = _within_reach(_pose(true))
		held.global_position += reel.stroke(held)


## Before anything reads it this tick.
func _back_to_tick() -> void:
	if phase == Phase.HELD and is_instance_valid(held):
		held.global_transform = _ticked


func _look() -> void:
	look_part = null
	look_device = null
	look_socket = null
	look_line = null
	look_sand = false
	look_work = null
	look_wreck = null
	look_scrap = null
	look_bed = false
	var eye := _player.camera.global_transform
	sight_from = eye.origin
	sight_to = eye.origin - eye.basis.z * _tuning.reach
	var ray := PhysicsRayQueryParameters3D.create(sight_from, sight_to)
	ray.exclude = _exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	var hit_device := hit.get("collider") as Device
	var hit_shape: Node = hit_device.shape_owner_get_owner(hit_device.shape_find_owner(hit.shape)) if hit_device != null else null
	var hit_socket := _outermost(hit_device.socket_of(hit_shape)) if hit_device != null else null
	# A visible fitted part must not be replaced by its carryable host.
	if hit.is_empty() or not hit.collider is Part:
		_assist(eye, hit_device if hit_socket != null and hit_socket.part != null else null)
	if hit.is_empty():
		if look_part == null and look_device == null:
			_under()
			_ground_line()
		return
	sight_to = hit.position
	look_point = hit.position
	look_normal = hit.normal
	var body: Object = hit.collider
	look_sand = _is_sand(hit)
	if body is CollisionObject3D and body.has_meta(&"wreckage"):
		look_wreck = body.get_meta(&"wreckage")
		if body.has_meta(&"work"):
			look_work = body
		elif body is StaticBody3D:
			look_scrap = body
	elif body is StaticBody3D and not look_sand and _player.world != null:
		# A structure's boxes are its chunk's ground: on a wreck's, its shell.
		look_wreck = _player.world.salvage.wreckage_near(hit.position)
	look_bed = _is_bed(hit)
	if look_part != null or look_device != null:
		# Assisted: the small thing you aimed near, not the sand under it.
		return
	if body is RigidBody3D and body.has_meta(&"boom_mast"):
		# The spar is articulated, but taking it still removes its fitted sail.
		look_device = body.get_meta(&"boom_mast") as Mast
		look_socket = look_device._sail_socket()
	elif body is Part:
		look_part = body
	elif body is Device:
		look_device = body
		look_socket = hit_socket
		if held == null:
			_near_tie(hit.position)
		if look_socket == null and not _low_on(look_device, hit_shape as CollisionShape3D, hit.position):
			return
	if look_part == null and look_socket == null:
		_under()
	if look_part == null and look_device == null:
		_ground_line()


## The drawn strand is pickable without colliders along every moving segment.
func _ground_line() -> void:
	if held != null or grasp.body != null:
		return
	var best := _tuning.pick_assist
	for child in _player.world.content.get_children():
		var line := child as Line
		if line == null or not line.recoverable():
			continue
		var points := line.rope.strand.points
		for i in range(1, points.size()):
			var near := Geometry3D.get_closest_points_between_segments(sight_from, sight_to, points[i - 1], points[i])
			var gap := near[0].distance_to(near[1])
			if gap >= best:
				continue
			var ray := PhysicsRayQueryParameters3D.create(sight_from, near[1])
			ray.exclude = _exclusions()
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.position.distance_to(near[1]) > RopeStrand.RADIUS * 2.0:
				continue
			best = gap
			look_line = line
			look_point = near[1]


## A ring's hole has no collider: aim near its visible end to take the knot.
func _near_tie(hit_at: Vector3) -> void:
	var best := _tuning.pick_assist
	for socket in look_device.sockets():
		if socket.kind != &"tie" or socket.part == null:
			continue
		# A hook's hole needs help; a stake's own frame must still come up whole.
		if not socket.has_meta(&"socket") or not (socket.get_meta(&"socket") as Socket).part is RopeHook:
			continue
		var at := look_device.global_transform * socket.position
		if at.distance_to(sight_from) > _tuning.reach or at.distance_to(sight_from) > hit_at.distance_to(sight_from) + best:
			continue
		var gap := Geometry3D.get_closest_point_to_segment(at, sight_from, sight_to).distance_to(at)
		if gap >= best or (sight_from - at).dot(look_device.global_basis * socket.outward()) <= 0.0:
			continue
		var tip := Line._tip(socket.part) if socket.part.has_meta(&"tip") else null
		var target := tip.global_position if tip != null else at
		var ray := PhysicsRayQueryParameters3D.create(sight_from, target)
		ray.exclude = _exclusions()
		var seen := get_world_3d().direct_space_state.intersect_ray(ray)
		if not seen.is_empty():
			if seen.collider != look_device:
				continue
			var met := look_device.shape_owner_get_owner(look_device.shape_find_owner(seen.shape)) as Node
			if _outermost(look_device.socket_of(met)) != socket:
				continue
		best = gap
		look_socket = socket


## Whether a look meets a frame low enough to mean what's fitted under it.
func _low_on(device: Device, frame: CollisionShape3D, point: Vector3) -> bool:
	if frame == null or frame.shape == null:
		return true
	var box := frame.transform * Catalog.bounds(frame.shape)
	var up := (device.global_transform.affine_inverse() * point).y - box.position.y
	return up <= minf(UNDER, box.size.y * UNDER_SHARE)


## Empty-handed, what a look at a device's frame, or just past one, finds under
## it: the part fitted facing down that your line of sight passes nearest.
func _under() -> void:
	if held != null:
		return
	var best: Socket = null
	var nearest := UNDER
	var near: Array = [look_device] if look_device != null \
		else _player.world.content.get_children() + _player.world.salvage.near(sight_from)
	for child in near:
		var device := child as Device
		if device == null or device.host() != null or device.has_meta(&"buried") or _far(device):
			continue
		for each in device.sockets():
			if each.part == null or (device.global_basis * each.outward()).y > -0.7:
				continue
			var d := _gap_to(device.global_transform, _shapes_box(each.fitted))
			if d < nearest:
				nearest = d
				best = each
	if best != null:
		look_device = best.get_parent() as Device
		look_socket = best


## The ground's own heightmap; a ruin's boxes share its body.
static func _is_sand(hit: Dictionary) -> bool:
	var body := hit.collider as StaticBody3D
	if body == null:
		return false
	var shape := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as CollisionShape3D
	return shape != null and shape.shape is HeightMapShape3D


## A box of a ruin's that's a bed.
static func _is_bed(hit: Dictionary) -> bool:
	var body := hit.collider as StaticBody3D
	if body == null:
		return false
	var shape := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as Node
	return shape != null and shape.has_meta(&"bed")


## How far along your look it meets something, out to `far`, m, or INF.
func meets(far: float) -> float:
	var eye := _player.camera.global_transform
	var ray := PhysicsRayQueryParameters3D.create(eye.origin, eye.origin - eye.basis.z * far)
	ray.exclude = _exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return INF if hit.is_empty() else eye.origin.distance_to(hit.position)


## A distant planting aim must not become a waist tie just because its
## sand is past reach, or past the ground whose collision is streamed.
func sand_beyond_reach() -> bool:
	var eye := _player.camera.global_transform
	if eye.basis.z.y > 0.0:
		return true
	var ray := PhysicsRayQueryParameters3D.create(eye.origin, eye.origin - eye.basis.z * _player.camera.far)
	ray.exclude = _exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and _is_sand(hit)


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


## Holding something aimed at a device with sockets of its kind but nowhere
## it goes: why. "" where it has none of the kind, and what you hold is
## simply put down.
func _no_fit() -> String:
	var target := _root(look_device) if look_device != null else null
	if target == null or target == held:
		return ""
	var piece := held as Chassis
	var kind: StringName = &"ring" if piece != null else (held.kind if held is Part else &"")
	var named := kind
	var any := false
	var free := false
	for each in target.sockets():
		if piece != null:
			if each.kind != &"ring" or not target is Chassis or each.has_meta(&"socket"):
				continue
		elif each.kind != kind and not (held is Device and (held as Device).fits_in(each)):
			continue
		any = true
		named = each.kind
		free = free or (Chassis.free_ring(each) if piece != null else each.is_open())
	if not any:
		return ""
	if not free:
		return "no free %s" % SOCKET_NAMES.get(named, "socket")
	if piece != null:
		return "wrecked" if piece.wrecked() or target.wrecked() else "no room at that ring"
	return ""


## Last on, first off: aimed at a hook with a line tied to it, it's the line's
## end you take, and the hook once it's bare.
static func _outermost(socket: Socket) -> Socket:
	if socket == null or socket.part == null:
		return socket
	for node in socket.fitted:
		var added := node as Socket
		if added != null and added.part != null:
			return _outermost(added)
	return socket


## Aiming at the sand near a small loose thing takes it, so a battery lying
## there needs no pixel-perfect aim: the nearest your aim among those you can
## see, and the one it settled on until another is clearly nearer.
func _assist(eye: Transform3D, except_body: RigidBody3D = null) -> void:
	if held != null:
		_picked = null
		return
	var forward := -eye.basis.z
	var space := get_world_3d().direct_space_state
	var best: RigidBody3D = null
	var best_score := INF
	var kept := INF
	if not is_instance_valid(_picked):
		_picked = null
	for child in _player.world.content.get_children() + _player.world.salvage.near(eye.origin):
		var body := child as RigidBody3D
		if body == null or body == except_body or not (body is Part or (body is Device and (body as Device).carryable)):
			continue
		var box := _box_of(body)
		var size := box.size.length() * 0.5
		if size * 2.0 > _tuning.pick_small:
			continue
		var middle := body.global_transform * box.get_center()
		var along := (middle - eye.origin).dot(forward)
		if along <= 0.0 or along > _tuning.reach:
			continue
		var score := (middle - eye.origin - forward * along).length() / (size + _tuning.pick_assist)
		if score > 1.0 or score >= best_score and body != _picked:
			continue
		var ray := PhysicsRayQueryParameters3D.create(eye.origin, middle)
		ray.exclude = _exclusions()
		var seen := space.intersect_ray(ray)
		if not seen.is_empty() and seen.collider != body:
			continue
		if body == _picked:
			kept = score
		if score < best_score:
			best_score = score
			best = body
	if best != _picked and kept <= 1.0 and best_score > kept * STICKY:
		best = _picked
	_picked = best
	if best is Part:
		look_part = best
	elif best is Device:
		look_device = best


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


## Having hold of a lone piece: the deck's free ring or frame face it would
## join at. Having hold of something that sticks: where your look would
## stick it. Either way the real thing is shown there, until it's set or you
## look away.
func _find_stand(delta: float) -> void:
	var body := grasp.body
	var piece := body as Chassis
	if piece != null and not (piece.joined.is_empty() and piece.deck == null):
		piece = null
	var best: Socket = null
	_stand_why = ""
	if piece != null:
		best = _find_ring(piece)
	stand = best
	if held == null:
		sticking = _stick_target(body, grasp.held_basis()) if body != null and best == null else {}
	var share := 1.0 - exp(-SWING * delta)
	if body != null and stand != null:
		grasp.show_at(_stand_pose, share)
	elif body != null and not sticking.is_empty():
		grasp.show_at(sticking.deck.global_transform * sticking.pose, share)
	elif grasp.showing():
		grasp.unshow()
	if held == null:
		_tint_as(body if grasp.showing() else null, sticking)


## The free edge ring or frame face of a deck a lone piece you have hold of
## would join at: the one whose place is nearest the piece, within reach,
## with room there. Two whole decks don't merge yet.
func _find_ring(piece: Chassis) -> Socket:
	var best: Socket = null
	var nearest := STAND_REACH
	var at := grasp.where()
	for each in _near():
		var deck := each as Chassis
		if deck == null or deck == piece or deck.deck != null:
			continue
		for ring in deck.sockets():
			var place := Transform3D()
			if Chassis.free_ring(ring):
				place = deck.global_transform * deck._pose_at(ring, 0)
			elif ring.kind == &"face" and ring.is_open():
				place = deck.global_transform * ring.transform * Frame.piece_seat()
			else:
				continue
			var d := place.origin.distance_to(at)
			if d < nearest:
				nearest = d
				best = ring
	if best == null:
		return null
	var deck := best.get_parent() as Chassis
	if best.kind == &"face":
		var on_face := deck.global_transform * best.transform * Frame.piece_seat()
		if not piece.fits_in(best) or Stick.clear(piece, on_face, _player) != "":
			_stand_why = "something's in the way"
			return null
		_stand_pose = on_face
		_stand_turns = 0
		return best
	var turns := deck._turns_for(piece, best, piece.global_basis)
	if turns < 0:
		_stand_why = "wrecked" if piece.wrecked() or deck.wrecked() else "no room at that ring"
		return null
	var pose := deck.global_transform * deck._pose_at(best, turns)
	if not deck.room_for(piece, pose):
		_stand_why = "something's in the way"
		return null
	_stand_pose = pose
	_stand_turns = turns
	return best


## Joins the piece you have hold of to a deck at its ring or on a frame's face.
func _stand_on(socket: Socket) -> void:
	var piece := grasp.body as Chassis
	var deck := socket.get_parent() as Chassis
	grasp.let_go(false)
	stand = null
	_tint_as(null, {})
	_player.world.salvage.claim(deck)
	deck.join(piece, socket, _stand_turns)
	_seat_sound()


## Where a thing would stick: the sticky face your look meets within reach,
## the thing under your look, turned as it's held, edged and settled there
## (Stick.aim), and why it can't go there, or a warning that it would sink a
## floating deck; {} where your look meets no sticky face.
func _stick_target(thing: RigidBody3D, held_basis: Basis) -> Dictionary:
	if thing == null or not Stick.sticks(thing) or not thing.is_inside_tree():
		return {}
	var ray := PhysicsRayQueryParameters3D.create(sight_from, sight_from - _player.camera.global_basis.z * _tuning.reach)
	var skip := _exclusions()
	skip.append(thing.get_rid())
	ray.exclude = skip
	# A standing mast's upper reach is there for your hands alone.
	ray.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	var on := Stick.face_hit(hit, -_player.camera.global_basis.z)
	if on.is_empty():
		return {}
	var deck: Device = on[0]
	var face := Stick.face_for(deck, on[1], on[2], thing)
	var placed := Stick.aim(deck, on[1], face, hit.position, held_basis, thing)
	var pose := Stick.pose_on(deck, on[1], face, placed[0], placed[1], thing)
	var why := Stick.why_not(deck, on[1], face, thing)
	if why == "":
		why = Stick.clear(thing, deck.global_transform * pose, _player)
	# Floating now, and too much for its trays with this on: it'd settle.
	var camp := deck
	while camp.host() != null:
		camp = camp.host()
	var now := camp.stats()
	var warn := "too heavy" if now.can_float and not camp.resting \
		and now.lift_kg + _lift_of(thing) < camp.mass + thing.mass else ""
	return {"deck": deck, "piece": on[1], "face": face, "pose": pose,
		"out": Stick.frame_of(deck, on[1], face).basis.z, "why": why, "warn": warn}


## What a thing lifts once it's stuck facing down: a tray its lift, else none.
static func _lift_of(thing: Node) -> float:
	var part := thing as Part
	return part.stats.get("lift_kg", 0.0) if part != null else 0.0


## Sticks what you hold where it's shown, with a soft clunk.
func _stick_held() -> void:
	var target := sticking
	var thing := held
	var deck: Device = target.deck
	_player.world.salvage.claim(deck)
	_let_go()
	var into := deck.stick(thing, target.pose, target.out, target.piece)
	_seat_sound()
	if thing is Part:
		fitted.emit(thing, deck, into)


## Sticks what you have hold of where it's shown.
func _stick_grasped() -> void:
	var target := sticking
	var thing := grasp.body as Device
	var deck: Device = target.deck
	_player.world.salvage.claim(deck)
	grasp.let_go(false)
	sticking = {}
	_tint_as(null, {})
	deck.stick(thing, target.pose, target.out, target.piece)
	_seat_sound()


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
	var part := device.take(from)
	_grip(part)
	_slide = part.depth()
	_slide_from = from.part.depth() if from.part != null else 0.0
	_t = 0.0
	phase = Phase.TAKING
	_play(Sounds.PICK if device is Planter and part.kind == &"food" else Sounds.UNSEAT)
	taken.emit(part, device, from)


func _grip(part: RigidBody3D) -> void:
	held = part
	_layers = Vector2i(part.collision_layer, part.collision_mask)
	_freeze_mode = part.freeze_mode
	part.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	part.freeze = true
	# Held, it touches nothing: it can't shove a device, a part or you.
	part.collision_layer = 0
	part.collision_mask = 0
	_unblock(part)
	_shapes.clear()
	_skins.clear()
	var first := true
	for child in part.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		_shapes.append(shape)
		_skins.append(_skin(shape.shape))
		var box := shape.transform * Catalog.bounds(shape.shape)
		_bounds = box if first else _bounds.merge(box)
		first = false
	_middle = _bounds.get_center()
	_carry = _tidy(Basis(Vector3.UP, -_player.global_rotation.y) * part.global_basis.orthonormalized())
	_away = _tuning.hold_distance
	_held_at = _away
	pull = 0.0
	socket = null
	gap = INF
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


func _tug(delta: float) -> void:
	var was: Variant = sticking.get("deck")
	_find_socket()
	var want := 0.0
	if socket != null:
		var seat := _settle_in(_seat(socket))
		want = maxf(smoothstep(_tuning.snap_reach, _tuning.snap_home, gap), OFFER)
		_lean = seat if pull == 0.0 else _blend(_lean, seat, 1.0 - exp(-SWING * delta))
	pull = move_toward(pull, want, delta / _tuning.tug_seconds)
	# Where it would stick, eased toward in the deck's frame, so it rides a floating deck.
	if not sticking.is_empty():
		var deck: Device = sticking.deck
		if _placing <= 0.0 or not is_instance_valid(was) or was != deck:
			_stick_local = deck.global_transform.affine_inverse() * held.global_transform
		var share := 1.0 - exp(-SWING * delta)
		_stick_local = Transform3D(_stick_local.basis.orthonormalized().slerp(sticking.pose.basis.orthonormalized(), share),
			_stick_local.origin.lerp(sticking.pose.origin, share))
		_stick_world = deck.global_transform * _stick_local
	_placing = move_toward(_placing, 1.0 if not sticking.is_empty() else 0.0, delta / PLACE_SECONDS)
	_tint_as(held if not sticking.is_empty() else null, sticking)


## The free socket of the held part's kind nearest your line of sight, among
## the devices in reach, reached from its open side: measured from where the
## part would sit there, so aiming at the spot or at the ghost is the same.
## Aimed near none, the device you look at offers its own, so a low socket
## needs no crouch. Worked out afresh every tick from what's free now, so one
## just emptied takes a part straight back.
func _find_socket() -> void:
	var target := _looked_at()
	var best: Socket = null
	var nearest := INF
	for device in _near():
		if device == held or _far(device):
			continue
		for each in device.sockets():
			if not _takes(each):
				continue
			var seat := _seat(each)
			var d := _sight_gap(seat)
			if d < nearest and _open(_frame_of(each), device) and _within_reach(seat) == seat:
				nearest = d
				best = each
	sticking = {}
	if nearest >= _tuning.snap_reach:
		best = null
		# Short of a slot you aim right at, a sticky face your look meets wins.
		sticking = _stick_target(held, _held_basis())
		if sticking.is_empty() and target != null:
			best = _offer(target)
		nearest = _sight_gap(_seat(best)) if best != null else INF
	gap = nearest
	socket = best


## The device you look at, or that your line of sight passes nearest within
## NEAR_FRAME of; one seated on another counts as its host, whose sockets are
## the ones open. _offer_at is where on it you aim.
func _looked_at() -> Device:
	if look_device != null:
		_offer_at = look_point
		var root := _root(look_device)
		return null if root == held else root
	var best: Device = null
	var nearest := NEAR_FRAME
	for device in _near():
		# A find under the sand you look at is out of sight.
		if device == held or device.has_meta(&"buried") or _far(device):
			continue
		var d := _gap_to(device.global_transform, _body_box(device))
		if d < nearest:
			nearest = d
			best = device
			_offer_at = _aim
	return best


## What a device offers the held part: of its free sockets of the kind, the
## only one, or of several the one nearest your aim, among those facing you
## if any do.
func _offer(device: Device) -> Socket:
	var best: Socket = null
	var best_facing := false
	var nearest := INF
	for each in device.sockets():
		if not _takes(each):
			continue
		var seat := _seat(each)
		if _within_reach(seat) != seat:
			continue
		var frame := _frame_of(each)
		var facing := (sight_from - frame.origin).dot(frame.basis.z) > 0.0
		var d := _outside(seat.affine_inverse() * _offer_at, _bounds)
		if best == null or facing and not best_facing or facing == best_facing and d < nearest:
			best = each
			best_facing = facing
			nearest = d
	return best


## Whether your look ray is on the device a socket belongs to, or one seated on it.
func _on(each: Socket) -> bool:
	return look_device != null and _root(look_device) == _root(each.get_parent() as Device)


## The device whose sockets a look at this one offers: its host, unless it
## stands on a deck, where it keeps its own.
static func _root(device: Device) -> Device:
	while device != null and device.host() != null and not device.on_deck():
		device = device.host()
	return device


## The devices your hands look over: yours in the world, the finds round
## you, whatever stands on a deck, which keeps its own sockets, and the Walker.
func _near() -> Array[Device]:
	var found: Array[Device] = []
	for child in _player.world.content.get_children() + _player.world.salvage.near(sight_from) \
			+ Walker.near(_player.world):
		var device := child as Device
		if device != null:
			found.append(device)
			_on_decks(device, found)
	return found


static func _on_decks(device: Device, found: Array[Device]) -> void:
	for each in device.mounted():
		if each.on_deck():
			found.append(each)
			_on_decks(each, found)


## Whether a device is past what your hands work on from your eyes: a deck
## by its nearest piece, since its far end can lie well past its first.
func _far(device: Device) -> bool:
	var nearest := device.global_position.distance_to(sight_from)
	var deck := device as Chassis
	if deck != null:
		for piece in deck.joined:
			nearest = minf(nearest, (deck.global_transform * piece.pose().origin).distance_to(sight_from))
	return nearest > _tuning.reach + 2.0


## Whether a free socket takes what you hold: a part of its kind, a device
## that seats there, a chassis piece at a deck's free edge with room beyond.
func _takes(each: Socket) -> bool:
	# A hook on a deck's ring, or a loose part beyond it, gets out of a joining piece's way.
	if held is Chassis and each.kind == &"ring":
		return (held as Chassis).fits_in(each) \
			and (each.get_parent() as Chassis).room_for(held, _seat(each))
	if held is Chassis and each.kind == &"face":
		return (held as Chassis).fits_in(each) and Stick.clear(held, _seat(each), _player) == ""
	if not each.is_open() or each.stuck():
		return false
	if held is Device:
		return (held as Device).fits_in(each)
	return each.kind == held.get(&"kind") or each.kind == &"face" and Frame.takes(held)


## Whether a hit is the sand's own surface, which a deck lifts itself clear
## of: a ruin's wall still counts as in the way.
static func _sand(hit: Dictionary) -> bool:
	var body := hit.collider as StaticBody3D
	if body == null:
		return false
	var holder := body.shape_owner_get_owner(body.shape_find_owner(hit.shape)) as CollisionShape3D
	return holder != null and holder.shape is HeightMapShape3D


## How near your line of sight passes to the part as it would sit in this
## seat, m; _aim is the point on it that passes nearest.
func _sight_gap(seat: Transform3D) -> float:
	return _gap_to(seat, _bounds)


## How near your line of sight passes to a box in a frame, m; _aim is the
## point on it that passes nearest.
func _gap_to(frame: Transform3D, box: AABB) -> float:
	var inverse := frame.affine_inverse()
	var a := inverse * sight_from
	var b := inverse * sight_to
	# The distance to a box along a line has one valley: close in on it.
	var lo := 0.0
	var hi := 1.0
	for i in 24:
		var one := lerpf(lo, hi, 1.0 / 3.0)
		var two := lerpf(lo, hi, 2.0 / 3.0)
		if _outside(a.lerp(b, one), box) <= _outside(a.lerp(b, two), box):
			hi = two
		else:
			lo = one
	var nearest := a.lerp(b, (lo + hi) * 0.5)
	_aim = frame * nearest
	return _outside(nearest, box)


## How far a point is outside a box in the same frame.
static func _outside(local: Vector3, box: AABB) -> float:
	return local.distance_to(local.clamp(box.position, box.end))


func _open(seat: Transform3D, device: Device) -> bool:
	var out := seat.basis.z
	if (_aim - seat.origin).dot(out) >= -OPEN_MARGIN:
		return true
	# A seat facing down into the sand is only reached from beside: you slide
	# the part under, aiming at the device's side.
	var tip := seat * Vector3(0.0, 0.0, _bounds.end.z)
	return out.y < -0.7 and tip.y < _player.world.height_under(tip) and look_device == device \
		and absf(look_normal.dot(out)) < 0.5


## Parts are plain boxes, the same turned end over end about their middle, so
## the tug leans one toward whichever way of sitting in the seat is nearest
## how it's held, never flipping it over on the way; fit() then seats it
## exactly, and nothing you can see changes.
func _settle_in(seat: Transform3D) -> Transform3D:
	var held_turn := (Basis(Vector3.UP, _player.global_rotation.y) * _carry).get_rotation_quaternion()
	var best := seat
	var nearest := INF
	for flip: Basis in [Basis.IDENTITY, Basis(Vector3.RIGHT, PI), Basis(Vector3.UP, PI), Basis(Vector3.BACK, PI)]:
		var basis := (seat.basis * flip).orthonormalized()
		var angle := held_turn.angle_to(basis.get_rotation_quaternion())
		if angle < nearest:
			nearest = angle
			best = Transform3D(basis, seat * _middle - basis * _middle)
	return best


func _fit(into: Socket) -> void:
	var device := into.get_parent() as Device
	_player.world.salvage.claim(device)
	if held is Chassis and into.kind in [&"ring", &"face"]:
		var piece := held as Chassis
		var turn := _held_basis()
		_let_go()
		var deck := device as Chassis
		deck.join(piece, into, deck._turns_for(piece, into, turn))
		_seat_sound()
		return
	if held is Device:
		var seated := held as Device
		_let_go()
		device.mount(seated, into)
		_seat_sound()
		return
	var part := held as Part
	_let_go()
	device.fit(part, into)
	if part.has_meta(&"line"):
		_play(Sounds.TIE)
	else:
		_seat_sound()
	fitted.emit(part, device, into)


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
	_tint_as(null, {})
	held = null
	phase = Phase.EMPTY
	socket = null
	sticking = {}
	_placing = 0.0
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
	var hand := _hand(drawn)
	if _placing > 0.0:
		var there := _stick_world
		if drawn and not sticking.is_empty() and is_instance_valid(sticking.deck):
			there = (sticking.deck as Node3D).global_transform * _stick_local
		return _blend(hand, there, smoothstep(0.0, 1.0, _placing))
	return hand if pull <= 0.0 else _blend(hand, _lean, smoothstep(0.0, 1.0, pull))


## As far in front of your eyes as you'd carry it, turned with you, and
## stopped short of anything in the way, so it never ends up inside the sand
## or a device.
func _hand(drawn: bool) -> Transform3D:
	var eye := _player.camera.global_transform
	if not drawn:
		eye.origin = _player.global_transform * _player.feel.steady_eye()
	var basis := Basis(Vector3.UP, _player.global_rotation.y) * _carry
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
	return start.translated(ahead * _sweep(start, ahead))


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


## Where what you hold sits in a socket, in the world.
func _seat(into: Socket) -> Transform3D:
	return _frame_of(into) * _seated(into)


## A socket's frame in the world: where a part's own frame sits in it.
func _frame_of(into: Socket) -> Transform3D:
	return ((into.get_parent() as Node3D).global_transform * into.transform).orthonormalized()


## Where what you hold sits in a socket's frame: a part on it, a device
## upright on it, a chassis piece flush beyond a deck's edge ring or flat on
## a frame's face.
func _seated(into: Socket) -> Transform3D:
	if held is Chassis and into.kind in [&"ring", &"face"]:
		return (held as Chassis).seat_in(into, _held_basis())
	return (held as Device).seat() if held is Device else Transform3D.IDENTITY


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
	_lean.origin -= offset
	_ticked.origin -= offset
	_stick_world.origin -= offset


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


## Drawn through everything, a ghost on a device's far side would read as on
## its near side, so it shows only from a socket's open side; one facing down
## is slid into from beside, so it always shows.
func _in_sight(into: Socket) -> bool:
	var frame := _frame_of(into)
	return frame.basis.z.y < -0.7 or (sight_from - frame.origin).dot(frame.basis.z) > 0.0


func _clear_ghost() -> void:
	for child in _ghost.get_children():
		child.free()
	_ghost.visible = false


## Tints what's shown where it would stick: red where it won't go, amber
## with a warning, else as it is. Set and cleared once each.
func _tint_as(body: Node3D, target: Dictionary) -> void:
	var color := Color(0.0, 0.0, 0.0, 0.0)
	if body != null and not target.is_empty():
		color = BLOCKED if target.why != "" else (WARNED if target.warn != "" else color)
	if body == _tinted and color == _tint:
		return
	if is_instance_valid(_tinted):
		for mesh: MeshInstance3D in _tinted.find_children("*", "MeshInstance3D", true, false):
			mesh.material_overlay = null
	_tinted = body if color.a > 0.0 else null
	_tint = color
	if _tinted == null:
		return
	if not _tints.has(color):
		var look := StandardMaterial3D.new()
		look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		look.albedo_color = color
		_tints[color] = look
	for mesh: MeshInstance3D in _tinted.find_children("*", "MeshInstance3D", true, false):
		mesh.material_overlay = _tints[color]


func _play(stream: AudioStream) -> void:
	_sound.stream = stream
	_sound.play()


func _seat_sound() -> void:
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


## A part's stats as they stand: a battery's charge, a crop's state, a coil's length.
func _part_stats(part: Part) -> Dictionary:
	var now := part.stats.duplicate()
	if part is Battery:
		now["charge_wh"] = part.charge_wh
	if part is Plant:
		now["ripe"] = part.ripe()
		if part.socket != null:
			now["growing"] = part.state
	if part.has_meta(&"line"):
		now.merge((part.get_meta(&"line") as Line).readout())
	return now


## What the look-at line says now: why take or use did nothing, why what you
## hold won't stick where it's shown or what to mind, else what you look at.
func line() -> String:
	if notice != "":
		return notice
	if phase == Phase.HELD and held is Part and held.has_meta(&"line") and _look_hook() != null:
		var laid: Line = held.get_meta(&"line")
		return Controls.key_for(&"interact") + " · " + ("remove line from hook" if laid.rope != null \
			and laid.rope.through == _look_hook().guide else "pass line through hook")
	if not sticking.is_empty() and (sticking.why != "" or sticking.warn != ""):
		return sticking.why if sticking.why != "" else sticking.warn
	if not sticking.is_empty() and (held is CrowsNest or grasp.body is CrowsNest) \
			and sticking.deck is Mast and sticking.face == Mast.MASTHEAD:
		return "Crow's nest on masthead"
	if look_wreck != null and (look_work != null or look_scrap != null):
		return look_wreck.describe(look_work if look_work != null else look_scrap)
	if look_line != null:
		return Controls.key_for(&"hands_grab") + " · gather rope · %.1f m" % look_line.full
	if look_part != null:
		return describe(look_part.label, _part_stats(look_part))
	if look_socket != null and look_socket.part != null:
		return describe(look_socket.part.label, _part_stats(look_socket.part))
	if look_device == null:
		return "Bed" if look_bed else ""
	if look_device is ManualWinch:
		return "%s · %s / %s" % [look_device.label, Controls.key_for(&"reel_in"), Controls.key_for(&"pay_out")]
	var stats := look_device.stats()
	# A device's charge is on its light.
	stats.erase("charge_wh")
	stats["in_w"] = look_device.production_w()
	stats["out_w"] = look_device.demand_w() if look_device.powered else 0.0
	stats["dark"] = not look_device.powered and look_device.demand_w() > 0.0
	return describe(look_device.label, stats)


func _show(delta: float) -> void:
	_readout.visible = not _player.suit.open and Controls.playing()
	_notice_left = maxf(_notice_left - delta, 0.0)
	if _notice_left <= 0.0:
		notice = ""
	var said := line()
	var waisted := _player.waist.release_readout()
	if waisted == "" and _player.waist.untying >= 0.0:
		waisted = "Untying line · %.1f s" % _player.waist.untying
	if waisted != "":
		said += ("\n" if said != "" else "") + waisted
	if said != "" and said != _readout.text:
		_readout.text = said
	_readout.modulate.a = move_toward(_readout.modulate.a, 1.0 if said != "" else 0.0, delta * 8.0)

	_ghost.visible = socket != null and _in_sight(socket)
	if socket != null:
		_ghost.global_transform = _seat(socket)
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
