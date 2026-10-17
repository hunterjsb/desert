class_name Hose
extends StrongCable
## A hose: two ends on a length of hose, carrying water as a cable carries
## power. Each end fits a water socket as a canister does, and fitted it
## offers a water socket of its own, so a canister or another hose goes on
## there too. It's a rope like a strong cable, holding what it joins, but a
## third as strong as rope, and pulled past that it never snaps: an end pops
## out of its socket, and it drags that end along by the other. While its ends
## sit in two different devices, Water joins them.

## Its ends' catalog id.
const END := &"hose_end"
## Drawn thicker than rope, in hose rubber.
const RADIUS := 0.03


func bind(world: World) -> void:
	super(world)
	rope.breaking = world.tuning.hose_holding
	rope.gives = _give_way
	var look := rope.strand.material_override as ShaderMaterial
	look.set_shader_parameter("radius", RADIUS)
	look.set_shader_parameter("color", Paint.HOSE)


## Pulled too hard, an end pops out and the load starts over; with neither
## end in a socket it holds on.
func _give_way() -> void:
	if _pop():
		rope.sustained = 0.0


## Whether a part is a hose's end.
static func is_end(part: Object) -> bool:
	return part is Part and (part as Part).get_meta(&"catalog", &"") == END
