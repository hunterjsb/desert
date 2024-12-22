extends GPUParticles3D

@onready var wind_node = $"../../WindSystem"

func _ready():
	# Particle system-level properties:
	amount = 500
	preprocess = 1.0
	emitting = true
	fixed_fps = 0
	lifetime = 2.0

	# Create and configure the ParticleProcessMaterial:
	var process_mat = ParticleProcessMaterial.new()
	process_material = process_mat
	process_mat.lifetime_randomness = 0.5

	# Set emission shape and properties on the process material
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_mat.emission_sphere_radius = 2.0

	# Direction and velocities
	process_mat.direction = Vector3(1, 0, 0)
	process_mat.spread = 30.0
	process_mat.initial_velocity_min = 0.5
	process_mat.initial_velocity_max = 1.0

	# Gravity and other properties
	process_mat.gravity = Vector3(0, -1, 0)

	# Scale and color
	process_mat.scale_min = 0.5
	process_mat.scale_max = 1.0
	process_mat.color = Color(1.0, 0.9, 0.5, 0.8)

	var mat = StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	set_material_override(mat)

func _process(delta: float):
	if wind_node and process_material:
		var process_mat = process_material as ParticleProcessMaterial
		var dir = wind_node.wind_direction.normalized()
		process_mat.direction = dir
		var base_vel = wind_node.wind_strength
		process_mat.initial_velocity_min = base_vel * 0.5
		process_mat.initial_velocity_max = base_vel * 1.0
