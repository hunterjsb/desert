class_name Shelter
extends Node3D
## A sphere round a running shield, centred here. Weather reads every shelter
## in the tree: within its live radius the felt weather loses whatever share
## of each harm the shelter blocks, so nested bubbles slot in per harm. One
## that blocks the storm outright is still, clear air the dust stops at, and
## the storm pass and the senses carve it out. Inside is a place, asked of the
## distance at any moment, never an event.

const GROUP := &"shelters"
## The most the shaders take at once; twin of SHELTER_MAX.
const MAX := 8

## Bumped whenever a shelter enters or leaves the tree, so a gathered list of
## them is never stale, even for a shield set down between two ticks.
static var changes := 0

## Metres to the shell as it stands now, blooming or collapsing; 0 when down.
var radius := 0.0
## How brightly the shell shows: 1 when steady, more while it blooms, less
## while it flickers.
var glow := 1.0
## What it keeps out of each harm, 0 (none) to 1 (immune): the PRD's levels
## are shares here, so a strong or weak type is a number, not code. The base
## shield's: wind and storm outright, temperature not at all.
var blocks := {&"wind": 1.0, &"storm": 1.0, &"temperature": 0.0}


func _init() -> void:
	add_to_group(GROUP)
	# Once it's in, and once it's wholly out.
	tree_entered.connect(_changed)
	tree_exited.connect(_changed)


func _changed() -> void:
	changes += 1


## The dust stops at its shell: it's standing and blocks the storm outright.
func carves() -> bool:
	return radius > 0.0 and blocks.get(&"storm", 0.0) >= 1.0


## Shelters' centres and radii as a shader's array takes them, every slot filled.
static func padded(holes: PackedVector4Array) -> PackedVector4Array:
	var out := holes.duplicate()
	out.resize(MAX)
	return out
