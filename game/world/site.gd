class_name Site
extends RefCounted
## One structure on the ground, as the site index holds it: what history made
## it, and where the sheet laid it in world metres. A kind with a kit builds
## it on the ground (the house ruin's is Ruin); every other kind is history's
## plan for now, for the map and the packages that will build it.

var id: int
var kind: StringName
var era: StringName
## Where history put it on the sphere; zero for one of the ground's own grid.
var point := Vector3.ZERO
## Where it stands, world metres, and which way it faces, rad clockwise from
## the ground's north (-z); a lattice kind's quarter turns.
var x: float
var z: float
var bearing: float
var turn: int
var reach: float
## Sand over it, m, and how far it leans buried, rad.
var depth: float
var tilt: float
var loot: int
var source: StringName
var region: StringName
## Only a plan: no kit builds it on the ground yet.
var planned := true


## Whether its ground touches a rectangle of world metres.
func touches(rect: Rect2) -> bool:
	var dx := maxf(maxf(rect.position.x - x, 0.0), x - rect.end.x)
	var dz := maxf(maxf(rect.position.y - z, 0.0), z - rect.end.y)
	return dx * dx + dz * dz <= reach * reach


func distance_to(at_x: float, at_z: float) -> float:
	return Vector2(x - at_x, z - at_z).length()
