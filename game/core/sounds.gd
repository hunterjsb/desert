class_name Sounds
extends RefCounted
## Every sound the game plays, and the buses they play on. Each file is
## levelled to how loud it's heard played at 0 dB, so the mix lives in the
## files (the table is in assets/audio/CREDITS.md) and code only rides a sound
## down from there. Sound reads the game and never feeds it.

## Everything in the world, muted while the main menu's desert shows.
const WORLD := &"World"
## The storm and the wind, through World, muffled inside a bubble.
const WEATHER := &"Weather"
## The menus, heard over the menu's silent desert too.
const UI := &"UI"

# Hands: a soft seat for fitting, its match for taking out, a dull knock
# when take or use can't, a line tied on, a line drawn hand over hand.
const SEAT: Array[AudioStream] = [preload("res://assets/audio/seat_a.ogg"),
	preload("res://assets/audio/seat_b.ogg")]
const UNSEAT := preload("res://assets/audio/unseat.ogg")
const REFUSE := preload("res://assets/audio/refuse.ogg")
const TIE := preload("res://assets/audio/tie.ogg")
const REEL := preload("res://assets/audio/reel.ogg")
const TUG := preload("res://assets/audio/hum.ogg")
const SAND_TAKE := preload("res://assets/audio/sand_take.ogg")
const SAND_PUT := preload("res://assets/audio/sand_put.ogg")
const THROW := preload("res://assets/audio/throw.ogg")
const STAKE := preload("res://assets/audio/stake.ogg")
# The suit: softer still than the hands.
const POUCH_IN := preload("res://assets/audio/pouch_in.ogg")
const POUCH_OUT := preload("res://assets/audio/pouch_out.ogg")
const BAG_OPEN := preload("res://assets/audio/bag_open.ogg")
const BAG_CLOSE := preload("res://assets/audio/bag_close.ogg")
const CHIME_FIRST := preload("res://assets/audio/chime_first.ogg")
const CHIME_LAST := preload("res://assets/audio/chime_last.ogg")
const CHIME_LOST := preload("res://assets/audio/chime_lost.ogg")
# You on foot.
const STEPS: Array[AudioStream] = [preload("res://assets/audio/step_a.ogg"),
	preload("res://assets/audio/step_b.ogg"), preload("res://assets/audio/step_c.ogg"),
	preload("res://assets/audio/step_d.ogg"), preload("res://assets/audio/step_e.ogg"),
	preload("res://assets/audio/step_f.ogg")]
const SLIDE := preload("res://assets/audio/slide.ogg")
const LANDING := preload("res://assets/audio/impact.ogg")
# The board, its hums also a hover tray lifting off and settling.
const HOVER := preload("res://assets/audio/hover.ogg")
const BOARD_ON := preload("res://assets/audio/board_on.ogg")
const BOARD_OFF := preload("res://assets/audio/board_off.ogg")
const LOW_TICK := preload("res://assets/audio/low_tick.ogg")
# Devices.
const SHIELD_BOOT := preload("res://assets/audio/shield_boot.ogg")
const SHIELD_HUM := preload("res://assets/audio/shield_hum.ogg")
const SHIELD_DOWN := preload("res://assets/audio/shield_down.ogg")
const POUR := preload("res://assets/audio/pour.ogg")
const PICK := preload("res://assets/audio/pick.ogg")
const FOOD_DROP := preload("res://assets/audio/food_drop.ogg")
const DRIPS: Array[AudioStream] = [preload("res://assets/audio/drip_a.ogg"),
	preload("res://assets/audio/drip_b.ogg")]
const CREAK := preload("res://assets/audio/creak.ogg")
# The radio: Sand Game's two tracks, by day and by night, the static the
# storm brings, the dial turning, a beacon's ping and the weather station's tones.
const RADIO_DAY := preload("res://assets/audio/radio_day.ogg")
const RADIO_NIGHT := preload("res://assets/audio/radio_night.ogg")
const RADIO_STATIC := preload("res://assets/audio/radio_static.ogg")
const RADIO_TUNE := preload("res://assets/audio/radio_tune.ogg")
const RADIO_PING := preload("res://assets/audio/radio_ping.ogg")
const RADIO_TONES := preload("res://assets/audio/radio_tones.ogg")
# The weather station's hold music while there's nothing to report, and the
# Stoker's furnace song on its frequency.
const RADIO_CLEAR_SKIES := preload("res://assets/audio/radio_clear_skies.ogg")
const RADIO_STOKER := preload("res://assets/audio/radio_stoker.ogg")
# Weather.
const STORM := preload("res://assets/audio/storm.ogg")
const WIND := preload("res://assets/audio/wind.ogg")
# Menus: very quiet.
const MENU_MOVE := preload("res://assets/audio/menu_move.ogg")
const MENU_CONFIRM := preload("res://assets/audio/menu_confirm.ogg")
const MENU_BACK := preload("res://assets/audio/menu_back.ogg")

## Small things are heard at their level from this far, m, and fade past it.
const NEAR := 2.0


## Heard where you are, from beside `owner`; it outlives a menu that closes
## as it plays. Freed when it ends.
static func play(owner: Node, stream: AudioStream, bus := WORLD, db := 0.0) -> void:
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.bus = bus
	voice.volume_db = db
	voice.autoplay = true
	voice.finished.connect(voice.queue_free)
	owner.add_child.call_deferred(voice)


## Heard from a point in the world, and from `owner` as it moves.
static func play_at(owner: Node3D, stream: AudioStream, db := 0.0, unit := NEAR) -> void:
	var voice := world_voice(stream, db, unit)
	voice.autoplay = true
	voice.finished.connect(voice.queue_free)
	owner.add_child.call_deferred(voice)


## A voice in the world: its level at `unit` metres, louder only a little
## nearer, and gone past 25 units so a far camp stays quiet.
static func world_voice(stream: AudioStream, db := 0.0, unit := NEAR) -> AudioStreamPlayer3D:
	var voice := AudioStreamPlayer3D.new()
	voice.stream = stream
	voice.bus = WORLD
	voice.volume_db = db
	voice.unit_size = unit
	voice.max_db = 3.0
	voice.max_distance = unit * 25.0
	return voice


## When something let go of lands, a soft fall into the sand where it does.
static func on_landing(body: RigidBody3D, watcher: Node3D) -> void:
	var landing := Landing.new()
	landing.body = body
	watcher.add_child(landing)


## Watches one falling body, only reading it, and is gone once it lands.
class Landing extends Node:
	## Falling at least this fast, m/s, then slowed to a stop, it has landed.
	const FALLING := 1.0
	const STOPPED := 0.3
	const GIVE_UP := 4.0
	var body: RigidBody3D
	var _fastest := 0.0
	var _age := 0.0

	func _physics_process(delta: float) -> void:
		_age += delta
		if not is_instance_valid(body) or not body.is_inside_tree() or body.freeze or _age > GIVE_UP:
			queue_free()
			return
		var down := -body.linear_velocity.y
		_fastest = maxf(_fastest, down)
		if _fastest > FALLING and down < STOPPED:
			var voice := Sounds.world_voice(SAND_PUT, linear_to_db(clampf(_fastest / 5.0, 0.3, 1.0)))
			voice.finished.connect(voice.queue_free)
			voice.top_level = true
			get_parent().add_child(voice)
			voice.global_position = body.global_position
			voice.play()
			queue_free()
