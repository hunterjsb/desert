class_name Hose
extends Cable
## A hose: two ends on a length of hose, carrying water as a cable carries
## power. Each end fits a water socket as a canister does, and fitted it
## offers a water socket of its own, so a canister or another hose goes on
## there too. It holds what it joins as a common cable does: pulled too far,
## a loose end is dragged along, and with both ends held fast one pops out.
## While its ends sit in two different devices, Water joins them.

## Its ends' catalog id.
const END := &"hose_end"


func _ready() -> void:
	_wire.mesh = Dress.hose()
	_wire.set_instance_shader_parameter(&"age", Paint.age_of(&"", 1.0))


## Whether a part is a hose's end.
static func is_end(part: Object) -> bool:
	return part is Part and (part as Part).get_meta(&"catalog", &"") == END
