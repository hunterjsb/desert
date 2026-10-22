class_name Wounds
extends Node
## What a wreck's hazards do to someone who skips the safe way: each kind its
## own wound. A shock from a live capacitor bank takes a bite of health at
## once, throws what you hold out of your hands and leaves you stunned, unable
## to move, look round or close your hands, for a moment: a white flash, a
## crack and a shower of sparks, the view jolting. A sickness from a breached
## store takes health a little at a time while it lasts, and stops you healing; the edges of your sight go sallow while it
## does. It wears off, or a med kit cures it. A save keeps the sickness.

## Seconds of stun and of sickness left.
var stun := 0.0
var sick := 0.0
## How many of each you've had, all run.
var shocks := 0
var sicknesses := 0

var _vitals: Vitals
var _flash: ColorRect
var _sallow: ColorRect


func _ready() -> void:
	_vitals = get_parent() as Vitals
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_sallow = ColorRect.new()
	_sallow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sallow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sallow.material = _vignette()
	_sallow.modulate.a = 0.0
	layer.add_child(_sallow)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(0.85, 0.92, 1.0)
	_flash.modulate.a = 0.0
	layer.add_child(_flash)


## A live hazard goes off on you, from where it stood (the engine's frame).
func take(hazard: StringName, at := Vector3.INF) -> void:
	match hazard:
		&"electrical":
			shock(at)
		&"bio":
			sicken(at)


func shock(at := Vector3.INF) -> void:
	var tuning := Tuning.current()
	shocks += 1
	stun = tuning.shock_stun
	_vitals.hurt(tuning.shock_harm)
	_flash.modulate.a = 0.85
	var player := _vitals.get_parent() as Player
	if player == null:
		return
	if player.hands.held != null:
		player.hands.drop()
	if at.is_finite() and player.world != null:
		Sounds.play_at(player, Sounds.ZAP, 0.0, 4.0)
		ScrapFx.burst(player.world.content, at, 70, 4.5)


func sicken(at := Vector3.INF) -> void:
	sicknesses += 1
	sick = Tuning.current().sickness_seconds
	var player := _vitals.get_parent() as Player
	if player != null and at.is_finite():
		Sounds.play_at(player, Sounds.HISS_LOOP, -2.0, 2.0)


## A med kit: the sickness gone. Says whether there was one to cure.
func cure() -> bool:
	var was := sick > 0.0
	sick = 0.0
	return was


func stunned() -> bool:
	return stun > 0.0


## Health the sickness takes over `seconds` of world time, and the time it runs down.
func loss(seconds: float) -> float:
	if sick <= 0.0:
		return 0.0
	var lasting := minf(seconds, sick)
	sick -= lasting
	return lasting * Tuning.current().sickness_harm


func _process(delta: float) -> void:
	_flash.modulate.a = move_toward(_flash.modulate.a, 0.0, delta * 2.5)
	var target := 0.0
	if sick > 0.0:
		target = 0.55 + 0.1 * sin(Time.get_ticks_msec() / 900.0)
	_sallow.modulate.a = move_toward(_sallow.modulate.a, target, delta * 0.6)


func _physics_process(delta: float) -> void:
	stun = maxf(stun - delta, 0.0)


static func _vignette() -> ShaderMaterial:
	var made := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
// The sallow edge of a sick man's sight.
void fragment() {
	vec2 off = UV - vec2(0.5);
	float edge = smoothstep(0.3, 0.75, length(off * vec2(1.3, 1.0)));
	COLOR = vec4(0.42, 0.45, 0.16, edge * 0.6);
}
"""
	made.shader = shader
	return made
