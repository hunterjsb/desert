class_name Ruin
extends Structure
## The house ruin, the second age's (SecondAgeKit), and the pattern every kit
## piece follows: a thick-walled building of three rooms, a hall open to the
## sky and two roofed rooms behind it, with a door front and back. Boxes and
## slabs built for walking, never scaled, never moved. Its footprint is part
## of the ground's one function: dug out, the sand lies just under its floor
## inside; outside, it drifts up the walls, falls away at the doors and
## blends back into the dunes. Buried, the sand fills it to its wall tops.
##
## Plan coordinates are metres: u along its length, v across, the floor's top
## at 0, its front door facing +v. Outer walls stand on whole metres and are a
## metre thick, so the lattice's rows meet their faces and the sand's rise
## from floor to drift happens inside a wall, where nobody sees it.

## Half its length and width to the outer faces, m.
const HALF := Vector2i(9, 6)
const WALL := 1.0
const HEIGHT := 3.0
const DOOR_WIDTH := 1.4
const DOOR_HEIGHT := 2.3
## Walls reach this far under the floor, so no drift ever shows their foot.
const FOOT := 0.6
const SLAB := 0.3
const ROOF := 0.3
## Inside, the sand lies this far under the floor's top, so the floor shows.
const SAND_UNDER := StructureKit.SAND_UNDER
## Sand drifts this high against the walls and is gone this far out; this
## far out the dunes have their own shape back.
const DRIFT := 0.7
const DRIFT_REACH := 4.0
const APRON := 12.0
## The drift rises beside a door over this far, m.
const DOOR_SIDE := 2.7
## Doors in the outer walls: the middle of the doorway on the outer face, and outward.
const DOORS := [[Vector2(-3.0, 6.0), Vector2(0.0, 1.0)], [Vector2(5.0, -6.0), Vector2(0.0, -1.0)]]
## Rooms, as plan rects: the hall, then the two roofed rooms.
const ROOMS := [Rect2(-8.0, -5.0, 9.8, 10.0), Rect2(2.2, -5.0, 5.8, 4.8), Rect2(2.2, 0.2, 5.8, 4.8)]
## A walk in the front door, through every room and doorway, out the back,
## and back in and out the front: plan points on the floor.
const TOUR := [Vector2(-3.0, 10.0), Vector2(-3.0, 4.0), Vector2(-4.5, -2.5), Vector2(0.5, 2.5),
	Vector2(4.5, 2.5), Vector2(5.0, 1.2), Vector2(5.0, -1.5), Vector2(5.0, -4.3), Vector2(5.0, -10.0),
	Vector2(5.0, -4.0), Vector2(3.5, -2.5), Vector2(0.0, -2.5), Vector2(-3.0, 3.0), Vector2(-3.0, 10.0)]
## Where finds lie on its floor, out of the way between doors: the first is
## the hall's, where a whole device stands.
const SPOTS := [Vector2(-6.6, 0.0), Vector2(-7.3, -4.3), Vector2(-7.3, 4.3), Vector2(-0.8, -4.3),
	Vector2(7.3, 4.3), Vector2(7.3, 0.9), Vector2(7.3, -4.3), Vector2(2.8, -4.4)]
## Where a scenario stands you to look at it: out in front of the front door.
const APPROACH := Vector2(-3.0, 18.0)

## Its middle, world metres on the lattice.
var center: Vector2i:
	get:
		return Vector2i(roundi(x), roundi(z))


## Half its outer extent along world x and z, turned.
static func half_on(quarter_turns: int) -> Vector2i:
	return HALF if quarter_turns % 2 == 0 else Vector2i(HALF.y, HALF.x)


## The boxes it's built of, as plan AABBs: floor, walls with their doorways
## and lintels, roof, and the jar on its corner.
static func boxes() -> Array[AABB]:
	return StructureKit.piece(&"house_ruin").boxes


## Builds what every structure shares, its looks and its shapes, so the first
## chunk with one doesn't pay for it inside the streaming budget.
static func prepare() -> void:
	StructureKit.prepare()
