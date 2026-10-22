class_name Flare
extends Part
## A signal flare (gonkhub, 2026-10-20: "a signal flare to go with this- if
## the player lights the signal flare during the deliveryship's pass overhead, it
## will fire the cannon"). Use lights it, held or not; it burns at its tip
## for flare_burn_seconds, a flickering red light, sparks and a red smoke, and
## a fizz, then it's spent and won't light again. While it burns, the
## deliveryship passing high enough over it (Airdrop.overhead) fires its
## care-package cannon at it, once. How long it has burnt is kept in its
## stats, so a spent one stays spent through a save.

## Its light, red; how far it reaches, m; how bright it burns, and how much it
## flickers, of that.
const LIGHT := Color(1.0, 0.28, 0.16)
const REACH := 16.0
const ENERGY := 2.6
const FLICKER := 0.35

## Whether it burns now.
var lit := false
## Whether it has already brought the cannon down on itself.
var called := false

var _light: OmniLight3D
var _sparks: CPUParticles3D
var _smoke: CPUParticles3D
var _fizz: AudioStreamPlayer3D
var _flicker := FastNoiseLite.new()


## Rebuild the effects after all saved properties have been restored.
func restored() -> void:
	if lit and not spent():
		light()
	else:
		lit = false


## How long it has burnt, s.
var burnt: float:
	get:
		return stats.get("burnt_s", 0.0)
	set(to):
		stats["burnt_s"] = to


## Whether it has burnt all it can.
func spent() -> bool:
	return burnt >= Tuning.current().flare_burn_seconds


## Use lights it; lit or spent, nothing.
func use(by: Player, _at: Vector3) -> bool:
	if spent():
		return by.hands.refuse("burnt out")
	if lit:
		return false
	light()
	return true


## Lit: its light, sparks, smoke and fizz at its tip, burning on from where it had burnt to.
func light() -> void:
	lit = true
	var tip := Vector3(0.0, 0.0, Catalog.PARTS[&"flare"].size.z)
	_light = OmniLight3D.new()
	_light.light_color = LIGHT
	_light.omni_range = REACH
	_light.shadow_enabled = false
	_light.position = tip + Vector3(0.0, 0.0, 0.05)
	add_child(_light)
	_sparks = Airdrop.puffs(40, 0.5, Color(1.0, 0.7, 0.3, 1.0), Color(1.0, 0.25, 0.1, 0.0), Vector2(0.03, 0.07), false)
	_sparks.direction = Vector3(0.0, 0.0, 1.0)
	_sparks.spread = 35.0
	_sparks.initial_velocity_min = 1.0
	_sparks.initial_velocity_max = 3.0
	_sparks.gravity = Vector3(0.0, -4.0, 0.0)
	_sparks.position = tip
	add_child(_sparks)
	_smoke = Airdrop.puffs(60, 4.0, Color(0.95, 0.35, 0.3, 0.45), Color(0.8, 0.5, 0.45, 0.0), Vector2(0.25, 0.9), false, true)
	_smoke.direction = Vector3.UP
	_smoke.spread = 20.0
	_smoke.initial_velocity_min = 0.4
	_smoke.initial_velocity_max = 1.0
	_smoke.gravity = Vector3(0.0, 0.25, 0.0)
	_smoke.position = tip
	add_child(_smoke)
	_sparks.emitting = true
	_smoke.emitting = true
	_fizz = Sounds.world_voice(Sounds.RADIO_STATIC, -10.0, 2.0)
	_fizz.pitch_scale = 1.7
	add_child(_fizz)
	_fizz.play(randf() * Sounds.RADIO_STATIC.get_length())
	_flicker.seed = get_instance_id()
	_flicker.frequency = 6.0


func _physics_process(delta: float) -> void:
	if not lit:
		return
	burnt += delta
	var t := Time.get_ticks_msec() / 1000.0
	_light.light_energy = ENERGY * (1.0 + FLICKER * _flicker.get_noise_1d(t * 20.0))
	if spent():
		_go_out()
		return
	var world := World.of(self)
	if not called and world != null and is_inside_tree() and Airdrop.overhead(world, global_position):
		called = true
		Airdrop.fire(world, global_position)
		Deeds.done(world, &"care_package")


func _go_out() -> void:
	lit = false
	_light.queue_free()
	_sparks.emitting = false
	_smoke.emitting = false
	_fizz.stop()
	# Its last smoke drifts off before the emitters go.
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if is_instance_valid(_smoke):
			_smoke.queue_free()
			_sparks.queue_free())
