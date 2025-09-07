extends GPUParticles3D

# Wind visualization particles that respond to WindManager data
# Shows wind direction, strength, and gusts through particle effects

@export var base_particle_count: int = 4
@export var gust_particle_multiplier: float = 2.0
@export var update_frequency: float = 0.1  # Update 10 times per second

var wind_manager: Node = null
var process_mat: ParticleProcessMaterial = null
var update_timer: float = 0.0

func _ready() -> void:
	# Find wind manager in the scene
	wind_manager = find_wind_manager()
	
	# Get reference to process material
	process_mat = process_material as ParticleProcessMaterial
	
	if wind_manager:
		# Connect to wind events for responsive updates
		wind_manager.cardinal_direction_changed.connect(_on_wind_direction_changed)
		wind_manager.gust_started.connect(_on_gust_started)
		wind_manager.gust_ended.connect(_on_gust_ended)
		
		# Set initial particle state based on current wind
		update_particles_from_wind()
	
	print("WindParticles: Initialized, WindManager found: ", wind_manager != null)

func find_wind_manager() -> Node:
	# Look for WindManager in the scene hierarchy
	var root = get_tree().current_scene
	if root:
		return find_node_recursive(root, "WindManager")
	return null

func find_node_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = find_node_recursive(child, target_name)
		if result:
			return result
	
	return null

func _process(delta: float) -> void:
	# Update particles periodically for performance
	update_timer += delta
	if update_timer >= update_frequency:
		update_timer = 0.0
		update_particles_from_wind()

func update_particles_from_wind() -> void:
	if not wind_manager or not process_mat:
		return
	
	# Get current wind data
	var wind_vector = wind_manager.get_wind_vector()
	var wind_strength = wind_vector.length()
	var wind_direction_world = wind_vector.normalized()
	
	# Convert world wind direction to player's local space
	# Since particles are attached to player, we need relative direction
	var player = get_parent()
	if player and wind_direction_world != Vector3.ZERO:
		# Transform wind direction from world space to player's local space
		var player_transform = player.global_transform
		var wind_direction_local = player_transform.basis.inverse() * wind_direction_world
		process_mat.direction = wind_direction_local
	
	# Scale particle speed based on wind strength
	var base_velocity = 5.0  # Base particle speed
	var velocity = base_velocity + (wind_strength * 2.0)  # Wind amplifies particle speed
	process_mat.initial_velocity_min = velocity * 0.8
	process_mat.initial_velocity_max = velocity * 1.2
	
	# Adjust turbulence based on wind conditions
	var turbulence_strength = clamp(wind_strength / 5.0, 0.1, 0.5)  # More wind = more turbulence
	process_mat.turbulence_influence_min = 0.0
	process_mat.turbulence_influence_max = turbulence_strength

# Signal callbacks for responsive wind changes
func _on_wind_direction_changed(new_angle: float) -> void:
	# Immediately update when wind direction changes
	update_particles_from_wind()

func _on_gust_started() -> void:
	# Increase particle count and intensity during gusts
	if process_mat:
		amount = int(base_particle_count * gust_particle_multiplier)
		# Boost turbulence for chaotic gust effect
		process_mat.turbulence_influence_max = min(process_mat.turbulence_influence_max * 1.5, 0.8)

func _on_gust_ended() -> void:
	# Return to normal particle count after gust
	amount = base_particle_count
	# Update particles to restore normal turbulence
	update_particles_from_wind()
