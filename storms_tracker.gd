# SandstormManager.gd
extends Node

var sandstorms: Array[Area3D] = []

# Adds a sandstorm to the registry
func register_sandstorm(sandstorm: Area3D):
	sandstorms.append(sandstorm)

# Removes a sandstorm from the registry
func unregister_sandstorm(sandstorm: Area3D):
	sandstorms.erase(sandstorm)

# Finds the nearest sandstorm and returns the distance and reference to it
func get_nearest_sandstorm(target_position: Vector3) -> Dictionary:
	var closest_sandstorm: Area3D = null
	var closest_distance: float = INF
	
	for sandstorm in sandstorms:
		var distance = target_position.distance_to(sandstorm.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_sandstorm = sandstorm
	
	return {
		"sandstorm": closest_sandstorm,
		"distance": closest_distance
	}
