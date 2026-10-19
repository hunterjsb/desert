class_name NoiseGLSL
extends RefCounted
## Godot's FastNoiseLite as GLSL, the smooth simplex (OpenSimplex2S) with FBm,
## so a compute pass draws the very noise the CPU reads: WindMap's twins of
## the dunes and the wind. A port of FastNoiseLite 1.1 (game/world/CREDITS.md),
## in 32 bits as Godot runs it; only what those fields use.


## A noise as SOURCE's Noise reads it, 16 bytes: its seed, octaves, frequency
## and the share the octaves are scaled by. Anything SOURCE doesn't draw stops here.
static func pack(noise: FastNoiseLite, into: StreamPeerBuffer) -> void:
	var fbm := noise.fractal_type == FastNoiseLite.FRACTAL_FBM
	if noise.noise_type != FastNoiseLite.TYPE_SIMPLEX_SMOOTH or noise.domain_warp_enabled \
			or noise.offset != Vector3.ZERO or not (fbm or noise.fractal_type == FastNoiseLite.FRACTAL_NONE) \
			or fbm and (noise.fractal_lacunarity != 2.0 or noise.fractal_gain != 0.5 or noise.fractal_weighted_strength != 0.0):
		push_error("NoiseGLSL draws only smooth simplex with plain FBm")
	var octaves := noise.fractal_octaves if fbm else 1
	var total := 0.0
	for i in octaves:
		total += pow(0.5, i)
	into.put_32(_int32(noise.seed))
	into.put_32(octaves)
	into.put_float(noise.frequency)
	into.put_float(1.0 / total)


## An int as C++ holds it in 32 bits.
static func _int32(v: int) -> int:
	v &= 0xffffffff
	return v - 0x100000000 if v >= 0x80000000 else v


const SOURCE := """
struct Noise {
	int seed;
	int octaves;
	float frequency;
	float bounding;
};

const int PRIME_X = 501125321;
const int PRIME_Y = 1136930381;
const int PRIME_Z = 1720413743;

const float GRADIENTS_2D[256] = float[](
	0.130526192220052, 0.99144486137381, 0.38268343236509, 0.923879532511287, 0.608761429008721, 0.793353340291235, 0.793353340291235, 0.608761429008721,
	0.923879532511287, 0.38268343236509, 0.99144486137381, 0.130526192220051, 0.99144486137381, -0.130526192220051, 0.923879532511287, -0.38268343236509,
	0.793353340291235, -0.60876142900872, 0.608761429008721, -0.793353340291235, 0.38268343236509, -0.923879532511287, 0.130526192220052, -0.99144486137381,
	-0.130526192220052, -0.99144486137381, -0.38268343236509, -0.923879532511287, -0.608761429008721, -0.793353340291235, -0.793353340291235, -0.608761429008721,
	-0.923879532511287, -0.38268343236509, -0.99144486137381, -0.130526192220052, -0.99144486137381, 0.130526192220051, -0.923879532511287, 0.38268343236509,
	-0.793353340291235, 0.608761429008721, -0.608761429008721, 0.793353340291235, -0.38268343236509, 0.923879532511287, -0.130526192220052, 0.99144486137381,
	0.130526192220052, 0.99144486137381, 0.38268343236509, 0.923879532511287, 0.608761429008721, 0.793353340291235, 0.793353340291235, 0.608761429008721,
	0.923879532511287, 0.38268343236509, 0.99144486137381, 0.130526192220051, 0.99144486137381, -0.130526192220051, 0.923879532511287, -0.38268343236509,
	0.793353340291235, -0.60876142900872, 0.608761429008721, -0.793353340291235, 0.38268343236509, -0.923879532511287, 0.130526192220052, -0.99144486137381,
	-0.130526192220052, -0.99144486137381, -0.38268343236509, -0.923879532511287, -0.608761429008721, -0.793353340291235, -0.793353340291235, -0.608761429008721,
	-0.923879532511287, -0.38268343236509, -0.99144486137381, -0.130526192220052, -0.99144486137381, 0.130526192220051, -0.923879532511287, 0.38268343236509,
	-0.793353340291235, 0.608761429008721, -0.608761429008721, 0.793353340291235, -0.38268343236509, 0.923879532511287, -0.130526192220052, 0.99144486137381,
	0.130526192220052, 0.99144486137381, 0.38268343236509, 0.923879532511287, 0.608761429008721, 0.793353340291235, 0.793353340291235, 0.608761429008721,
	0.923879532511287, 0.38268343236509, 0.99144486137381, 0.130526192220051, 0.99144486137381, -0.130526192220051, 0.923879532511287, -0.38268343236509,
	0.793353340291235, -0.60876142900872, 0.608761429008721, -0.793353340291235, 0.38268343236509, -0.923879532511287, 0.130526192220052, -0.99144486137381,
	-0.130526192220052, -0.99144486137381, -0.38268343236509, -0.923879532511287, -0.608761429008721, -0.793353340291235, -0.793353340291235, -0.608761429008721,
	-0.923879532511287, -0.38268343236509, -0.99144486137381, -0.130526192220052, -0.99144486137381, 0.130526192220051, -0.923879532511287, 0.38268343236509,
	-0.793353340291235, 0.608761429008721, -0.608761429008721, 0.793353340291235, -0.38268343236509, 0.923879532511287, -0.130526192220052, 0.99144486137381,
	0.130526192220052, 0.99144486137381, 0.38268343236509, 0.923879532511287, 0.608761429008721, 0.793353340291235, 0.793353340291235, 0.608761429008721,
	0.923879532511287, 0.38268343236509, 0.99144486137381, 0.130526192220051, 0.99144486137381, -0.130526192220051, 0.923879532511287, -0.38268343236509,
	0.793353340291235, -0.60876142900872, 0.608761429008721, -0.793353340291235, 0.38268343236509, -0.923879532511287, 0.130526192220052, -0.99144486137381,
	-0.130526192220052, -0.99144486137381, -0.38268343236509, -0.923879532511287, -0.608761429008721, -0.793353340291235, -0.793353340291235, -0.608761429008721,
	-0.923879532511287, -0.38268343236509, -0.99144486137381, -0.130526192220052, -0.99144486137381, 0.130526192220051, -0.923879532511287, 0.38268343236509,
	-0.793353340291235, 0.608761429008721, -0.608761429008721, 0.793353340291235, -0.38268343236509, 0.923879532511287, -0.130526192220052, 0.99144486137381,
	0.130526192220052, 0.99144486137381, 0.38268343236509, 0.923879532511287, 0.608761429008721, 0.793353340291235, 0.793353340291235, 0.608761429008721,
	0.923879532511287, 0.38268343236509, 0.99144486137381, 0.130526192220051, 0.99144486137381, -0.130526192220051, 0.923879532511287, -0.38268343236509,
	0.793353340291235, -0.60876142900872, 0.608761429008721, -0.793353340291235, 0.38268343236509, -0.923879532511287, 0.130526192220052, -0.99144486137381,
	-0.130526192220052, -0.99144486137381, -0.38268343236509, -0.923879532511287, -0.608761429008721, -0.793353340291235, -0.793353340291235, -0.608761429008721,
	-0.923879532511287, -0.38268343236509, -0.99144486137381, -0.130526192220052, -0.99144486137381, 0.130526192220051, -0.923879532511287, 0.38268343236509,
	-0.793353340291235, 0.608761429008721, -0.608761429008721, 0.793353340291235, -0.38268343236509, 0.923879532511287, -0.130526192220052, 0.99144486137381,
	0.38268343236509, 0.923879532511287, 0.923879532511287, 0.38268343236509, 0.923879532511287, -0.38268343236509, 0.38268343236509, -0.923879532511287,
	-0.38268343236509, -0.923879532511287, -0.923879532511287, -0.38268343236509, -0.923879532511287, 0.38268343236509, -0.38268343236509, 0.923879532511287
);

const float GRADIENTS_3D[256] = float[](
	0.0, 1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0,
	1.0, 0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, 1.0, 0.0, -1.0, 0.0, -1.0, 0.0, -1.0, 0.0,
	1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0, 0.0,
	0.0, 1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0,
	1.0, 0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, 1.0, 0.0, -1.0, 0.0, -1.0, 0.0, -1.0, 0.0,
	1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0, 0.0,
	0.0, 1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0,
	1.0, 0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, 1.0, 0.0, -1.0, 0.0, -1.0, 0.0, -1.0, 0.0,
	1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0, 0.0,
	0.0, 1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0,
	1.0, 0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, 1.0, 0.0, -1.0, 0.0, -1.0, 0.0, -1.0, 0.0,
	1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0, 0.0,
	0.0, 1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0,
	1.0, 0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, 1.0, 0.0, -1.0, 0.0, -1.0, 0.0, -1.0, 0.0,
	1.0, 1.0, 0.0, 0.0, -1.0, 1.0, 0.0, 0.0, 1.0, -1.0, 0.0, 0.0, -1.0, -1.0, 0.0, 0.0,
	1.0, 1.0, 0.0, 0.0, 0.0, -1.0, 1.0, 0.0, -1.0, 1.0, 0.0, 0.0, 0.0, -1.0, -1.0, 0.0
);

// FastNoiseLite's own floor: a negative whole number floors one lower.
int fnl_floor(float f) {
	return f >= 0.0 ? int(f) : int(f) - 1;
}

float grad2(int seed, int xp, int yp, float xd, float yd) {
	int h = (seed ^ xp ^ yp) * 0x27d4eb2d;
	h ^= h >> 15;
	h &= 127 << 1;
	return xd * GRADIENTS_2D[h] + yd * GRADIENTS_2D[h | 1];
}

float grad3(int seed, int xp, int yp, int zp, float xd, float yd, float zd) {
	int h = (seed ^ xp ^ yp ^ zp) * 0x27d4eb2d;
	h ^= h >> 15;
	h &= 63 << 2;
	return xd * GRADIENTS_3D[h] + yd * GRADIENTS_3D[h | 1] + zd * GRADIENTS_3D[h | 2];
}

float simplex2s(int seed, float x, float y) {
	const float SQRT3 = 1.7320508075688772;
	const float G2 = (3.0 - SQRT3) / 6.0;
	int i = fnl_floor(x);
	int j = fnl_floor(y);
	float xi = x - float(i);
	float yi = y - float(j);
	i *= PRIME_X;
	j *= PRIME_Y;
	int i1 = i + PRIME_X;
	int j1 = j + PRIME_Y;
	float t = (xi + yi) * G2;
	float x0 = xi - t;
	float y0 = yi - t;
	float a0 = (2.0 / 3.0) - x0 * x0 - y0 * y0;
	float value = (a0 * a0) * (a0 * a0) * grad2(seed, i, j, x0, y0);
	float a1 = (2.0 * (1.0 - 2.0 * G2) * (1.0 / G2 - 2.0)) * t + ((-2.0 * (1.0 - 2.0 * G2) * (1.0 - 2.0 * G2)) + a0);
	float x1 = x0 - (1.0 - 2.0 * G2);
	float y1 = y0 - (1.0 - 2.0 * G2);
	value += (a1 * a1) * (a1 * a1) * grad2(seed, i1, j1, x1, y1);
	float xmyi = xi - yi;
	if (t > G2) {
		if (xi + xmyi > 1.0) {
			float x2 = x0 + (3.0 * G2 - 2.0);
			float y2 = y0 + (3.0 * G2 - 1.0);
			float a2 = (2.0 / 3.0) - x2 * x2 - y2 * y2;
			if (a2 > 0.0) {
				value += (a2 * a2) * (a2 * a2) * grad2(seed, i + (PRIME_X << 1), j + PRIME_Y, x2, y2);
			}
		} else {
			float x2 = x0 + G2;
			float y2 = y0 + (G2 - 1.0);
			float a2 = (2.0 / 3.0) - x2 * x2 - y2 * y2;
			if (a2 > 0.0) {
				value += (a2 * a2) * (a2 * a2) * grad2(seed, i, j + PRIME_Y, x2, y2);
			}
		}
		if (yi - xmyi > 1.0) {
			float x3 = x0 + (3.0 * G2 - 1.0);
			float y3 = y0 + (3.0 * G2 - 2.0);
			float a3 = (2.0 / 3.0) - x3 * x3 - y3 * y3;
			if (a3 > 0.0) {
				value += (a3 * a3) * (a3 * a3) * grad2(seed, i + PRIME_X, j + (PRIME_Y << 1), x3, y3);
			}
		} else {
			float x3 = x0 + (G2 - 1.0);
			float y3 = y0 + G2;
			float a3 = (2.0 / 3.0) - x3 * x3 - y3 * y3;
			if (a3 > 0.0) {
				value += (a3 * a3) * (a3 * a3) * grad2(seed, i + PRIME_X, j, x3, y3);
			}
		}
	} else {
		if (xi + xmyi < 0.0) {
			float x2 = x0 + (1.0 - G2);
			float y2 = y0 - G2;
			float a2 = (2.0 / 3.0) - x2 * x2 - y2 * y2;
			if (a2 > 0.0) {
				value += (a2 * a2) * (a2 * a2) * grad2(seed, i - PRIME_X, j, x2, y2);
			}
		} else {
			float x2 = x0 + (G2 - 1.0);
			float y2 = y0 + G2;
			float a2 = (2.0 / 3.0) - x2 * x2 - y2 * y2;
			if (a2 > 0.0) {
				value += (a2 * a2) * (a2 * a2) * grad2(seed, i + PRIME_X, j, x2, y2);
			}
		}
		if (yi < xmyi) {
			float x2 = x0 - G2;
			float y2 = y0 - (G2 - 1.0);
			float a2 = (2.0 / 3.0) - x2 * x2 - y2 * y2;
			if (a2 > 0.0) {
				value += (a2 * a2) * (a2 * a2) * grad2(seed, i, j - PRIME_Y, x2, y2);
			}
		} else {
			float x2 = x0 + G2;
			float y2 = y0 + (G2 - 1.0);
			float a2 = (2.0 / 3.0) - x2 * x2 - y2 * y2;
			if (a2 > 0.0) {
				value += (a2 * a2) * (a2 * a2) * grad2(seed, i, j + PRIME_Y, x2, y2);
			}
		}
	}
	return value * 18.24196194486065;
}

float simplex2s(int seed, float x, float y, float z) {
	int i = fnl_floor(x);
	int j = fnl_floor(y);
	int k = fnl_floor(z);
	float xi = x - float(i);
	float yi = y - float(j);
	float zi = z - float(k);
	i *= PRIME_X;
	j *= PRIME_Y;
	k *= PRIME_Z;
	int seed2 = seed + 1293373;
	int xm = int(-0.5 - xi);
	int ym = int(-0.5 - yi);
	int zm = int(-0.5 - zi);
	float x0 = xi + float(xm);
	float y0 = yi + float(ym);
	float z0 = zi + float(zm);
	float a0 = 0.75 - x0 * x0 - y0 * y0 - z0 * z0;
	float value = (a0 * a0) * (a0 * a0) * grad3(seed, i + (xm & PRIME_X), j + (ym & PRIME_Y), k + (zm & PRIME_Z), x0, y0, z0);
	float x1 = xi - 0.5;
	float y1 = yi - 0.5;
	float z1 = zi - 0.5;
	float a1 = 0.75 - x1 * x1 - y1 * y1 - z1 * z1;
	value += (a1 * a1) * (a1 * a1) * grad3(seed2, i + PRIME_X, j + PRIME_Y, k + PRIME_Z, x1, y1, z1);
	float xf0 = float((xm | 1) << 1) * x1;
	float yf0 = float((ym | 1) << 1) * y1;
	float zf0 = float((zm | 1) << 1) * z1;
	float xf1 = float(-2 - (xm << 2)) * x1 - 1.0;
	float yf1 = float(-2 - (ym << 2)) * y1 - 1.0;
	float zf1 = float(-2 - (zm << 2)) * z1 - 1.0;
	bool skip5 = false;
	float a2 = xf0 + a0;
	if (a2 > 0.0) {
		value += (a2 * a2) * (a2 * a2) * grad3(seed, i + (~xm & PRIME_X), j + (ym & PRIME_Y), k + (zm & PRIME_Z),
			x0 - float(xm | 1), y0, z0);
	} else {
		float a3 = yf0 + zf0 + a0;
		if (a3 > 0.0) {
			value += (a3 * a3) * (a3 * a3) * grad3(seed, i + (xm & PRIME_X), j + (~ym & PRIME_Y), k + (~zm & PRIME_Z),
				x0, y0 - float(ym | 1), z0 - float(zm | 1));
		}
		float a4 = xf1 + a1;
		if (a4 > 0.0) {
			value += (a4 * a4) * (a4 * a4) * grad3(seed2, i + (xm & (PRIME_X * 2)), j + PRIME_Y, k + PRIME_Z,
				float(xm | 1) + x1, y1, z1);
			skip5 = true;
		}
	}
	bool skip9 = false;
	float a6 = yf0 + a0;
	if (a6 > 0.0) {
		value += (a6 * a6) * (a6 * a6) * grad3(seed, i + (xm & PRIME_X), j + (~ym & PRIME_Y), k + (zm & PRIME_Z),
			x0, y0 - float(ym | 1), z0);
	} else {
		float a7 = xf0 + zf0 + a0;
		if (a7 > 0.0) {
			value += (a7 * a7) * (a7 * a7) * grad3(seed, i + (~xm & PRIME_X), j + (ym & PRIME_Y), k + (~zm & PRIME_Z),
				x0 - float(xm | 1), y0, z0 - float(zm | 1));
		}
		float a8 = yf1 + a1;
		if (a8 > 0.0) {
			value += (a8 * a8) * (a8 * a8) * grad3(seed2, i + PRIME_X, j + (ym & (PRIME_Y << 1)), k + PRIME_Z,
				x1, float(ym | 1) + y1, z1);
			skip9 = true;
		}
	}
	bool skipD = false;
	float aA = zf0 + a0;
	if (aA > 0.0) {
		value += (aA * aA) * (aA * aA) * grad3(seed, i + (xm & PRIME_X), j + (ym & PRIME_Y), k + (~zm & PRIME_Z),
			x0, y0, z0 - float(zm | 1));
	} else {
		float aB = xf0 + yf0 + a0;
		if (aB > 0.0) {
			value += (aB * aB) * (aB * aB) * grad3(seed, i + (~xm & PRIME_X), j + (~ym & PRIME_Y), k + (zm & PRIME_Z),
				x0 - float(xm | 1), y0 - float(ym | 1), z0);
		}
		float aC = zf1 + a1;
		if (aC > 0.0) {
			value += (aC * aC) * (aC * aC) * grad3(seed2, i + PRIME_X, j + PRIME_Y, k + (zm & (PRIME_Z << 1)),
				x1, y1, float(zm | 1) + z1);
			skipD = true;
		}
	}
	if (!skip5) {
		float a5 = yf1 + zf1 + a1;
		if (a5 > 0.0) {
			value += (a5 * a5) * (a5 * a5) * grad3(seed2, i + PRIME_X, j + (ym & (PRIME_Y << 1)), k + (zm & (PRIME_Z << 1)),
				x1, float(ym | 1) + y1, float(zm | 1) + z1);
		}
	}
	if (!skip9) {
		float a9 = xf1 + zf1 + a1;
		if (a9 > 0.0) {
			value += (a9 * a9) * (a9 * a9) * grad3(seed2, i + (xm & (PRIME_X * 2)), j + PRIME_Y, k + (zm & (PRIME_Z << 1)),
				float(xm | 1) + x1, y1, float(zm | 1) + z1);
		}
	}
	if (!skipD) {
		float aD = xf1 + yf1 + a1;
		if (aD > 0.0) {
			value += (aD * aD) * (aD * aD) * grad3(seed2, i + (xm & (PRIME_X << 1)), j + (ym & (PRIME_Y << 1)), k + PRIME_Z,
				float(xm | 1) + x1, float(ym | 1) + y1, z1);
		}
	}
	return value * 9.046026385208288;
}

// FastNoiseLite.get_noise_2d: frequency, the simplex skew, then the octaves.
float noise2(Noise n, float x, float y) {
	x *= n.frequency;
	y *= n.frequency;
	const float F2 = 0.5 * (1.7320508075688772 - 1.0);
	float t = (x + y) * F2;
	x += t;
	y += t;
	float sum = 0.0;
	float amp = n.bounding;
	for (int o = 0; o < n.octaves; o++) {
		sum += simplex2s(n.seed + o, x, y) * amp;
		x *= 2.0;
		y *= 2.0;
		amp *= 0.5;
	}
	return sum;
}

// get_noise_3d: frequency, the 3D rotation, then the octaves.
float noise3(Noise n, vec3 p) {
	p *= n.frequency;
	float r = (p.x + p.y + p.z) * (2.0 / 3.0);
	p = r - p;
	float sum = 0.0;
	float amp = n.bounding;
	for (int o = 0; o < n.octaves; o++) {
		sum += simplex2s(n.seed + o, p.x, p.y, p.z) * amp;
		p *= 2.0;
		amp *= 0.5;
	}
	return sum;
}
"""
