class_name SummitSite
extends Structure
## The surviving foundation was made for this summit, not a wandering ruin.
func place_step() -> bool:
	var shape: TerrainShape = _ctx.shape.get_ref()
	if shape == null:
		return super()
	_stand(shape.dunes(x, z))
	return true

func view(at: Vector3, s: int) -> MeshInstance3D:
	var made := super(at, s)
	made.visibility_range_end = _ctx.tuning.skyline_handover_m.x
	made.visibility_range_end_margin = _ctx.tuning.skyline_handover_m.y - _ctx.tuning.skyline_handover_m.x
	made.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	return made
