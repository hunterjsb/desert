class_name Shelter
extends Node3D
## A sphere of still, clear air round a running shield, centred here. Weather
## reads every shelter in the tree: the felt wind and storm are zero inside,
## the storm pass draws the dust stopping at the shell, and the senses follow.
## Inside is a place, asked of the distance at any moment, never an event.

const GROUP := &"shelters"
## The most the shaders take at once; twin of SHELTER_MAX.
const MAX := 8

## Metres to the shell as it stands now, blooming or collapsing; 0 when down.
var radius := 0.0
## How brightly the shell shows: 1 when steady, more while it blooms.
var glow := 1.0


func _init() -> void:
	add_to_group(GROUP)


## Shelters' centres and radii as a shader's array takes them, every slot filled.
static func padded(holes: PackedVector4Array) -> PackedVector4Array:
	var out := holes.duplicate()
	out.resize(MAX)
	return out
