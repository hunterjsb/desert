class_name Footing
extends RefCounted
## What you're standing on, as your footsteps hear it: sand, metal plate,
## stone or wood. The ground's own heightmap is sand. Anything else says so
## with a `footing` meta on its shape or its body; a structure's boxes take
## theirs from the coat each is painted in, so a wreck's hull rings and a
## second-age floor scuffs; devices and parts (your deck, a crate) are metal
## unless they say otherwise. Something solid that says nothing is stone.

const SAND := &"sand"
const METAL := &"metal"
const STONE := &"stone"
const WOOD := &"wood"
const META := &"footing"

## A structure box's coat, by name, as underfoot: every coat a kit piece's
## boxes are painted in, whatever its era. Cloth coats are wood, the
## nearest give.
const COATS := {
	"steel": METAL, "grey": METAL, "dark": METAL, "panel": METAL, "hull": METAL, "olive": METAL,
	"scrap": METAL, "armour": METAL, "cobalt": METAL, "teal": METAL, "rail": METAL, "rust": METAL,
	"orange": METAL,
	"concrete": STONE, "stone": STONE, "stone_dark": STONE, "floor": STONE, "render": STONE,
	"lime": STONE, "clay": STONE, "plaster": STONE,
	"wood": WOOD, "seat": WOOD, "ochre": WOOD, "indigo": WOOD,
}
## A box with no coat (its look drawn some other way), by its era's make.
const ERAS := {Eras.COLONIAL: METAL, Eras.SKIMMER: METAL, &"nomad": WOOD}


## What a floor contact is: the body hit and the shape node it hit.
static func of(body: Object, holder: Object) -> StringName:
	if holder != null and holder.has_meta(META):
		return holder.get_meta(META)
	if body != null and body.has_meta(META):
		return body.get_meta(META)
	var shape := holder as CollisionShape3D
	if shape != null and shape.shape is HeightMapShape3D:
		return SAND
	if body is Device or body is Part:
		return METAL
	return STONE


## A structure box's footing, from its coat's name or else its era.
static func of_coat(coat: String, era: StringName) -> StringName:
	if coat.is_empty():
		return ERAS.get(era, STONE)
	return COATS.get(coat, STONE)
