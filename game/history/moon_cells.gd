class_name MoonCells
extends RefCounted
## The moon cut into cells about `size` m across, so history can be made and
## laid a cell at a time: bands of latitude, each cut round into as many
## cells as fit, so a cell is near square everywhere but at the poles. A cell
## is an int, the same for the same moon every run.

var radius: float
var size: float
var bands: int
var count := 0
var _counts := PackedInt32Array()
var _offsets := PackedInt32Array()


func _init(moon_radius: float, cell_m: float) -> void:
	radius = moon_radius
	size = cell_m
	bands = maxi(1, roundi(PI * radius / size))
	for b in bands:
		var n := maxi(1, roundi(TAU * radius * cos(_middle(b)) / size))
		_offsets.append(count)
		_counts.append(n)
		count += n


## The cell a place is in.
func cell_at(p: Vector3) -> int:
	var b := _band_of(Sphere.latitude(p))
	var n := _counts[b]
	return _offsets[b] + mini(floori(fposmod(Sphere.longitude(p) + PI, TAU) / TAU * n), n - 1)


## A cell's middle.
func center(cell: int) -> Vector3:
	var b := band(cell)
	var n := _counts[b]
	return Sphere.point(_middle(b), -PI + (cell - _offsets[b] + 0.5) * TAU / n)


func band(cell: int) -> int:
	return _offsets.bsearch(cell, false) - 1


## The farthest any of a cell lies from its middle, m.
func half_diagonal(cell: int) -> float:
	var b := band(cell)
	var tall := PI * radius / bands
	# Widest at the edge nearer the equator.
	var lat := maxf(absf(_middle(b)) - PI * 0.5 / bands, 0.0)
	var wide := TAU * radius * cos(lat) / _counts[b]
	return 0.5 * sqrt(tall * tall + wide * wide)


## A cell's bounds: [south, north, west, east] in rad, east past west.
func box(cell: int) -> PackedFloat64Array:
	var b := band(cell)
	var n := _counts[b]
	var lat0 := -PI * 0.5 + b * PI / bands
	var lon0 := -PI + (cell - _offsets[b]) * TAU / n
	return PackedFloat64Array([lat0, lat0 + PI / bands, lon0, lon0 + TAU / n])


## A cell's corners, south-west first, going round.
func corners(cell: int) -> Array[Vector3]:
	var at := box(cell)
	return [Sphere.point(at[0], at[2]), Sphere.point(at[0], at[3]), Sphere.point(at[1], at[3]), Sphere.point(at[1], at[2])]


## Every cell any part of which may lie within `metres` of p.
func within(p: Vector3, metres: float) -> PackedInt32Array:
	var found := PackedInt32Array()
	var by := metres / radius
	var lat := Sphere.latitude(p)
	var lon := Sphere.longitude(p)
	var half_band := PI * 0.5 / bands
	var lo := _band_of(lat - by - half_band)
	var hi := _band_of(lat + by + half_band)
	# The cap's widest reach in longitude, at its widest latitude.
	var wrap := absf(lat) + by >= PI * 0.5 - 1e-9
	var reach := PI if wrap else asin(minf(1.0, sin(by) / cos(absf(lat) + by)))
	for b in range(lo, hi + 1):
		var n := _counts[b]
		var step := TAU / n
		var first := 0
		var last := n - 1
		if not wrap and reach + step < PI:
			first = floori((lon - reach - step + PI) / step)
			last = floori((lon + reach + step + PI) / step)
		var seen := {}
		for k in range(first, last + 1):
			var cell := _offsets[b] + posmod(k, n)
			if seen.has(cell):
				continue
			seen[cell] = true
			if Sphere.angle(p, center(cell)) * radius <= metres + half_diagonal(cell):
				found.append(cell)
	return found


## Every cell a box of latitude and longitude touches, rad, west to east
## unwrapped: east may run past PI.
func in_box(south: float, north: float, west: float, east: float) -> PackedInt32Array:
	var found := PackedInt32Array()
	for b in range(_band_of(south), _band_of(north) + 1):
		var n := _counts[b]
		var step := TAU / n
		var first := floori((west + PI) / step)
		var last := mini(floori((east + PI) / step), first + n - 1)
		for k in range(first, last + 1):
			found.append(_offsets[b] + posmod(k, n))
	return found


func _band_of(lat: float) -> int:
	return clampi(floori((lat + PI * 0.5) / PI * bands), 0, bands - 1)


func _middle(b: int) -> float:
	return -PI * 0.5 + (b + 0.5) * PI / bands
