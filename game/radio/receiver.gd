class_name Receiver
extends Device
## A set you tune and listen to, the tiers of receiver sharing what a set is:
## a dial and a volume knob you turn on its face, its voices sounding from
## where it stands or, carried, in your ears, and a little power drawn while
## it's on. The broadcast radio (Radio) and the survey receiver are its tiers.

## Its dial's clicks are heard at their level this far off, m; what it plays,
## out to radio_heard_m.
const HEARD := 6.0
## Tuned within this many widths of a carrier, the dial counts it as on it.
const ON_IT := 2.0
## A beacon pings this often from far off and this often close by, s.
const PING_FAR := 2.5
const PING_NEAR := 0.5
## Its volume knob's notch, of full.
const VOLUME_STEP := 0.1
## The tuning knob goes once round across the whole dial, 0 to 2000 kHz
## (gonkhub, 2026-10-20: "make the visual for the knob turning match the
## bandwidth, so going from 0-20k is one full knob turn"); the volume knob
## sweeps three quarters round, silent to full.
const KHZ_A_TURN := Dial.HIGHEST
const VOLUME_SWEEP := PI * 1.5
## The needle and knobs catch up with where the dial stands in about this long, s.
const TURN_SECONDS := 0.05
## Set down, its voices are placed again this many physics frames apart.
const PLACE_EVERY := 30

## Whether it's switched on, and where its dial stands, kHz.
var on := false:
	set(to):
		on = to
		_recompute()
var frequency := 0.0
## Where its volume knob stands, 0 silent to 1 full: everything it plays.
var volume := 1.0
## What its beacon points at, decided when it found it: {x, z, coord, index}
## in world metres, or {} for no signal.
var target := {}
## What it says now, for the look-at line and the dev overlay; never shown as speech.
var said := ""
var hiss: AudioStreamPlayer3D
## What you turn on its face, and where they've got to, kHz and of full.
var needle: MeshInstance3D
var knob: MeshInstance3D
var volume_knob: MeshInstance3D
var shown_khz := 0.0
var shown_volume := 1.0

var _tuning := Tuning.current()
## Every voice it plays through.
var _voices: Array[AudioStreamPlayer3D] = []
## Its station's signal: tones, pings or pulses.
var _signal: AudioStreamPlayer3D
var _since_signal := INF
## Whether its voices were last placed in your ears, and on which physics frame.
var _in_ears := false
var _placed_frame := -PLACE_EVERY


func _init() -> void:
	carryable = true


func _physics_process(delta: float) -> void:
	super(delta)
	_listen(delta)


## What it plays this tick, from the systems it reads.
func _listen(_delta: float) -> void:
	pass


## The volume knob: turned `notches` a notch each, between silent and full.
func turn_volume(notches: int) -> bool:
	if wrecked() or world == null:
		return false
	world.salvage.claim(self)
	volume = clampf(snappedf(volume + notches * VOLUME_STEP, VOLUME_STEP), 0.0, 1.0)
	_loudness()
	return true


## Moves the dial `notches`, a notch or a fine step each. Says whether it turned.
func tune(_notches: int, _fine := false) -> bool:
	return false


## Whether it plays: on, powered, whole and in the world.
func playing() -> bool:
	return on and powered and not wrecked() and world != null and is_inside_tree()


## Whether you hear it where you are: its words in the line low in your
## view, or what it plays within earshot.
func heard() -> bool:
	var far := global_position.distance_to(world.player.camera.global_position)
	return far < Broadcast.EARSHOT or far < _tuning.radio_heard_m and volume > 0.0


func demand_w(t := NAN) -> float:
	return super(t) + (_tuning.radio_w if on and not wrecked() else 0.0)


## Where the volume knob puts everything it plays, dB: a fixed step a notch,
## as ears hear loudness, from radio_loudness_db at full down through
## radio_volume_range_db to barely there at a tenth, and silence at none.
func knob_db() -> float:
	if volume <= 0.0:
		return -80.0
	return _tuning.radio_loudness_db - _tuning.radio_volume_range_db * (1.0 - volume)


## The knob on what it plays besides its hiss.
func _loudness() -> void:
	pass


## Whether it's on you, in what you carry (Suit): then it plays straight into
## your ears.
func carried() -> bool:
	return has_meta(&"carried")


## Its voices sound from its middle, the point your hands hold ahead of you.
## Carried, they sound from just before your eyes, where that would be held
## as near as you can bring it (Hands.nearest_hold), straight ahead, with no
## panning, so looking round never moves them from side to side:
## as loud as that, and stowing one held close changes nothing you hear. Out
## again, they're back on the set.
func _to_your_ears(on_you: bool) -> void:
	# Set down, its voices stay where they were put; they're placed again as it's
	# picked up or put down, and now and then for parts fitted or taken off.
	var frame := Engine.get_physics_frames()
	if not on_you and not _in_ears and frame - _placed_frame < PLACE_EVERY:
		return
	_in_ears = on_you
	_placed_frame = frame
	# Its bounds are walked once for all its voices, not once each.
	var spot := _ears_spot(on_you)
	for each: AudioStreamPlayer3D in _voices:
		_place_at(each, on_you, spot)


func _place(voice: AudioStreamPlayer3D, on_you: bool) -> void:
	_place_at(voice, on_you, _ears_spot(on_you))


## Where its voices sound: just before your eyes carried (world space), else its middle (its own frame).
func _ears_spot(on_you: bool) -> Vector3:
	var player := get_parent() as Player
	if on_you and player != null and player.is_inside_tree():
		var eyes := player.camera.global_transform
		return eyes.origin - eyes.basis.z.normalized() * player.hands.nearest_hold_of(self)
	return Hands.middle_of(self)


func _place_at(voice: AudioStreamPlayer3D, on_you: bool, spot: Vector3) -> void:
	# No side to it in your ears, however fast you look round.
	voice.panning_strength = 0.0 if on_you else 1.0
	var in_ears := on_you and get_parent() is Player and (get_parent() as Player).is_inside_tree()
	if in_ears and voice.is_inside_tree():
		voice.global_position = spot
	else:
		voice.position = Hands.middle_of(self) if in_ears else spot


## A click of its dial, heard at its level within HEARD, from where its voices are.
func _click(stream: AudioStream, db: float) -> void:
	var voice := Sounds.world_voice(stream, db, HEARD)
	voice.autoplay = true
	voice.finished.connect(voice.queue_free)
	add_child.call_deferred(voice)
	_place.call_deferred(voice, carried())


## One of its voices: as loud as its knob at full allows, past the cap other
## things in the world have.
func _voice() -> AudioStreamPlayer3D:
	return add_voice(Sounds.radio_bus())


## A voice of its own through `bus`, which goes on into the radio's (the
## satellites' each have one), placed as its others are.
func add_voice(bus: StringName) -> AudioStreamPlayer3D:
	var out := Sounds.world_voice(null, 0.0, _tuning.radio_heard_m)
	out.max_db = _tuning.radio_loudness_db + 3.0
	# Through a small speaker: its lows cut.
	out.bus = bus
	add_child(out)
	out.position = Hands.middle_of(self)
	_voices.append(out)
	return out


## A station's signal again each `seconds`, at once on tuning in.
func _every(delta: float, seconds: float, stream: AudioStream) -> void:
	_since_signal += delta
	if _since_signal >= seconds:
		_since_signal = 0.0
		_signal.stream = stream
		_signal.play()


## How far the tuning knob stands turned at a frequency, rad clockwise.
static func knob_turn(khz: float) -> float:
	return TAU * khz / KHZ_A_TURN


func _on_face(look: ArrayMesh) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = look
	add_child(view)
	return view


## Its needle and knobs wear its paint too.
func painted() -> Array[MeshInstance3D]:
	var out := super()
	out.append_array([needle, knob, volume_knob])
	return out


## Its look-at line names where its dial stands, or that it's off.
func stats() -> Dictionary:
	var now := super()
	now["tuned"] = "%d kHz" % roundi(frequency) if on else "off"
	return now


## Where its face is, to read its dial: its middle, its +Z out of the face.
func face() -> Transform3D:
	return global_transform


func _recompute() -> void:
	super()
	# Its dial lights only while it's on.
	for view in painted():
		if view != null:
			view.set_instance_shader_parameter(&"lit", 1.0 if on and powered else 0.0)


## What only the broadcast set has: a band switch and frequency marks.
func switch_band() -> bool:
	return false


func has_dial_marks() -> bool:
	return false


func toggle_mark() -> bool:
	return false


func next_mark() -> bool:
	return false
