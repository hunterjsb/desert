class_name HalloranSite
extends Structure
## One connected grade keeps the old street, toll gate and furnace reachable.
## Only the lower rooms fill; the road was cut to shed drifting sand.

func place_step() -> bool:
	var shape: TerrainShape = _ctx.shape.get_ref()
	if shape == null:
		return super()
	_stand(shape.dunes(x, z))
	return true


func _made(dx: float, dz: float, level: float) -> Vector2:
	var at := plan(dx, dz)
	var grade := HalloranKit.grade(at.x)
	var fill := piece.fill_at(level) * smoothstep(5.0, 12.0, absf(at.y))
	var outside := piece.out_of(at)
	return Vector2(_pad + grade + fill - StructureKit.SAND_UNDER,
		smoothstep(0.0, piece.apron, outside))


func sand(at_x: float, at_z: float, dunes: float) -> float:
	var step := ground if ground >= 0 else piece.step_of(level())
	var made := _made(at_x - x, at_z - z, piece.level_of(step))
	return lerpf(made.x, dunes, made.y)


## A large landmark only computes the chunk being built, never a moon-sized grid.
func carve(step: int, rect := Rect2()) -> Array:
	if rect.size == Vector2.ZERO:
		rect = Rect2(_grid_x, _grid_z, _grid_w - 1, _grid_d - 1)
	var lo := rect.position.floor()
	var hi := rect.end.ceil()
	var width := int(hi.x - lo.x) + 1
	var rows := int(hi.y - lo.y) + 1
	var made := PackedFloat32Array()
	made.resize(width * rows * 2)
	var shown := piece.level_of(step)
	for j in rows:
		for i in width:
			var each := _made(lo.x + i - x, lo.y + j - z, shown)
			var k := (j * width + i) * 2
			made[k] = each.x
			made[k + 1] = each.y
	return [made, lo.x, lo.y, float(width), float(rows)]
