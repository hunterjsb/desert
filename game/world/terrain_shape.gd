class_name TerrainShape
extends RefCounted
## The ground's one function. The visible mesh, the collision and every placed
## object read height_at(); nothing computes height any other way.

var _noise := FastNoiseLite.new()
var _amplitude: float


func _init(run_seed: int, tuning: Tuning) -> void:
	_noise.seed = run_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0 / tuning.dune_wavelength
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = tuning.dune_octaves
	_amplitude = tuning.dune_amplitude


## World coordinates in metres. FastNoiseLite takes 32-bit inputs, so detail
## coarsens after ~1000 km of travel, but every reader still agrees exactly.
func height_at(x: float, z: float) -> float:
	return _noise.get_noise_2d(x, z) * _amplitude
