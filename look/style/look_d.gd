extends "res://look/style/look_c.gd"
## D: C's shapes and palette drawn as a picture-book: cel shading in two flat
## steps and a dark warm ink line round every silhouette, the ruin included.

const TOON := preload("res://look/style/toon.gdshader")
const INK := preload("res://look/style/ink.gdshader")


func title() -> String:
	return "D: cel-shaded, inked"


func _make(color: StringName) -> Material:
	var look := ShaderMaterial.new()
	look.shader = TOON
	var c: Color = Color(0.74, 0.64, 0.52) if color == &"ruin" else PALETTE[color]
	look.set_shader_parameter("color", c)
	look.set_shader_parameter("shade", Color(0.55, 0.42, 0.5))
	look.set_shader_parameter("glow", 1.8 if color == &"glow" else 0.0)
	var line := ShaderMaterial.new()
	line.shader = INK
	# The ruin is many boxes in one mesh, so it grows along its normals.
	line.set_shader_parameter("boxy", color != &"ruin")
	line.set_shader_parameter("width", 0.003 if color == &"ruin" else 0.0025)
	look.next_pass = line
	return look
