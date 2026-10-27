class_name KiteLooks
extends RefCounted
## The antenna kite, from the radio kit lab's model (look/radio_kit): a delta
## 1.4 m across in shortwave violet with safety-orange chevrons and a copper
## dipole sewn across its shoulder (kite.gdshader); a carbon spine, leading
## edges and spreader; a keel with its towing ring at the tip; two tails. Its
## sail takes `torn`, `weathered` and `charge` on its instance. And packed: the kite
## rolled on its spine, strapped to the drum of flying line it flies on.

const SHADER := preload("res://game/look/kite.gdshader")
const SPAN := 1.4
const TALL := 0.95
## Where its towing ring is, at the keel's tip, from its middle.
const RING := Vector3(0.0, 0.0, 0.32)

static var _made := {}


static func coat(color: Color, rough := 0.6, metal := 0.0) -> Paint.Coat:
	return Paint.coat(color, 0.6, metal, rough)


## The kite flying: its nose up +Y, its face +Z toward the wind's source.
static func kite() -> ArrayMesh:
	if _made.has(&"kite"):
		return _made[&"kite"]
	var b := Paint.Pieces.new()
	var spar := coat(Paint.CARBON, 0.3, 0.3)
	var orange := coat(Paint.SAFETY_ORANGE, 0.8)
	var nose := Vector3(0.0, TALL * 0.5, 0.0)
	var tips: Array[Vector3] = [Vector3(-SPAN * 0.5, -TALL * 0.5, 0.0), Vector3(SPAN * 0.5, -TALL * 0.5, 0.0)]
	var tail_at := Vector3(0.0, -TALL * 0.5 + 0.08, 0.0)
	# The spars: spine, leading edges, a spreader behind.
	_rod(b, nose, tail_at, 0.007, spar)
	for t in tips:
		_rod(b, nose, t, 0.006, spar)
	_rod(b, Vector3(-0.42, -0.1, -0.04), Vector3(0.42, -0.1, -0.04), 0.005, spar)
	for t in tips:
		b.drum(0.012, 0.02, t, coat(Paint.BLACK, 0.6), _along(t - nose), 8)
	# The keel, under the spine, the towing ring at its tip.
	var keel_top := [Vector3(0.0, 0.25, 0.0), Vector3(0.0, -0.3, 0.0)]
	for k in 8:
		var f := (k + 0.5) / 8.0
		var top: Vector3 = keel_top[0].lerp(keel_top[1], f)
		var deep := RING.z * (1.0 - absf(f - 0.45) / 0.55)
		b.box(Vector3(0.004, 0.55 / 8.0 + 0.002, deep), top + Vector3(0.0, 0.0, deep * 0.5), orange, 0.0)
	b.ring(0.012, 0.017, Vector3(0.0, -0.02, RING.z), coat(Paint.STEEL, 0.3, 0.7), Basis(Vector3.BACK, PI / 2.0), 8)
	# The dipole's feed: a ceramic block on the spine, its leads down the keel.
	b.box(Vector3(0.05, 0.035, 0.025), Vector3(0.0, nose.y - TALL * 0.42, 0.015), coat(Paint.CERAMIC, 0.3), 0.004)
	_rod(b, Vector3(0.0, nose.y - TALL * 0.42, 0.03), Vector3(0.0, -0.02, RING.z - 0.015), 0.0025, coat(Paint.COPPER, 0.35, 0.7))
	# Two tails off its trailing corners, streamers knotted along a cord.
	for t in tips:
		var from: Vector3 = t * 0.85 + Vector3(0.0, 0.03, 0.0)
		var long := 1.1
		for i in 8:
			var y := from.y - (i + 0.5) * long / 8.0
			var x := from.x + sin(i * 0.8) * 0.05 * signf(from.x)
			b.box(Vector3(0.04, long / 8.0 * 0.8, 0.003), Vector3(x, y, 0.0), orange if i % 2 == 0 else coat(Paint.SW_TELL, 0.8),
				0.0, Basis(Vector3.BACK, sin(i * 0.8) * 0.3))
	var mesh := b.commit()
	# The sail: a grid from nose (v 0) to trailing edge (v 1).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := 16
	var rows := 14
	var place := func(u: float, v: float) -> Vector3:
		var across := u * 2.0 - 1.0
		# Its trailing edge notched up at the spine.
		var y := nose.y - TALL * v * (1.0 - 0.14 * (1.0 - across * across) * v)
		return Vector3(across * SPAN * 0.5 * v, y, 0.0)
	for j in rows:
		for i in cols:
			for c: Array in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j], [i + 1, j + 1], [i, j + 1]]:
				var u := float(c[0]) / cols
				var v := float(c[1]) / rows
				st.set_uv(Vector2(u, v))
				st.set_normal(Vector3.BACK)
				st.add_vertex(place.call(u, v))
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	var cloth := ShaderMaterial.new()
	cloth.shader = SHADER
	cloth.set_shader_parameter(&"chevron", Paint.SAFETY_ORANGE)
	cloth.set_shader_parameter(&"copper", Paint.COPPER)
	mesh.surface_set_material(mesh.get_surface_count() - 1, cloth)
	_made[&"kite"] = mesh
	return mesh


## Packed, as the device stands: a drum of flying line between orange cheeks,
## a crank, the kite rolled on its spine strapped along the top, and the
## lead's brass terminal on its right cheek (the device's lead socket).
static func packed(size: Vector3, cloth := Paint.SW_TELL, trim := Paint.SAFETY_ORANGE) -> ArrayMesh:
	var h := size * 0.5
	var b := Paint.Pieces.new(-h.y)
	var across := Basis(Vector3.BACK, PI / 2.0)
	var steel := coat(Paint.STEEL, 0.3, 0.6)
	var drum_at := Vector3(0.0, -h.y + 0.08, 0.0)
	for s in [-1, 1]:
		b.drum(0.08, 0.012, drum_at + Vector3(s * (h.x - 0.03), 0.0, 0.0), coat(trim, 0.5), across, 20)
	b.drum(0.055, size.x - 0.07, drum_at, coat(Paint.FLYING_LINE, 0.7), across, 18)
	for i in 9:
		b.ring(0.054, 0.058, drum_at + Vector3(-h.x + 0.05 + i * (size.x - 0.1) / 8.0, 0.0, 0.0),
			coat(Paint.LINE_SHADE, 0.8), across, 14)
	b.drum(0.01, size.x - 0.02, drum_at, steel, across, 10)
	b.box(Vector3(0.008, 0.07, 0.012), drum_at + Vector3(-h.x + 0.006, -0.03, 0.03), steel, 0.003)
	b.drum(0.008, 0.04, drum_at + Vector3(-h.x - 0.012, -0.06, 0.03), coat(Paint.BLACK, 0.6), across, 8)
	# The rolled cloth and its straps keep the flying kite's colours.
	var roll_at := Vector3(0.0, h.y - 0.035, 0.0)
	b.drum(0.034, size.x - 0.03, roll_at, coat(cloth, 0.8), across, 14)
	for i in 3:
		b.drum(0.036, 0.022, roll_at + Vector3(-0.1 + i * 0.1, 0.0, 0.0), coat(trim, 0.8), across, 14)
	b.drum(0.006, size.x + 0.02, roll_at, coat(Paint.CARBON, 0.3, 0.3), across, 6)
	# Two straps down to the drum's axle.
	for x in [-0.09, 0.09]:
		b.box(Vector3(0.02, 0.09, 0.004), Vector3(x, h.y - 0.08, h.z - 0.03), coat(Paint.BLACK, 0.7), 0.001)
	# The lead's terminal: a ceramic standoff, a brass post.
	b.drum(0.012, 0.02, Vector3(h.x - 0.004, -0.02, 0.0), coat(Paint.CERAMIC, 0.25), across, 10)
	b.drum(0.006, 0.014, Vector3(h.x + 0.01, -0.02, 0.0), coat(Paint.BRASS, 0.3, 0.7), across, 8)
	return b.commit()


static func _rod(b: Paint.Pieces, a: Vector3, c: Vector3, r: float, look: Paint.Coat) -> void:
	b.drum(r, (c - a).length(), (a + c) * 0.5, look, _along(c - a), 6)


static func _along(d: Vector3) -> Basis:
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(x, y, x.cross(y))
