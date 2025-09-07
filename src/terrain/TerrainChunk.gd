extends MeshInstance3D

# Constants for better code clarity
const DEFAULT_AUTO_LOD = 10
const OBJECT_SPAWN_CHANCE = 10  # Percentage chance (10%)
const STRUCTURE_SPAWN_CHANCE = 1  # Per 300 attempts
const YUCCA_SPAWN_WEIGHT = 0.01
const POST_SPAWN_WEIGHT = 0.5

# LOD distance thresholds
const LOD_DISTANCE_CLOSE = 3
const LOD_DISTANCE_MEDIUM = 6  
const LOD_DISTANCE_FAR = 10
const LOD_DISTANCE_VERY_FAR = 20
const LOD_DISTANCE_EXTREME = 40

#==> OTHER <==#
var terrain = null
var autoLOD = DEFAULT_AUTO_LOD
var oldLod = 0

#==> SCENES <==#
var ruins_scene = preload("res://src/structure/ruins/ruins_01.tscn")
var yucca_scene = preload("res://src/object/agriculture/yucca.tscn")
var post_scene = preload("res://src/structure/post/post.tscn")

#==> SPAWNABLES + CHANCES <==#
var spawnables = [yucca_scene, post_scene] 
var spawn_chances = [YUCCA_SPAWN_WEIGHT, POST_SPAWN_WEIGHT]

#==> CODE <==#
func get_distance():
	var player_pos = terrain.player.global_position
	return int(player_pos.distance_to(position))


func create_base_mesh():
	var chunk_size = terrain.chunk_size
	var subdivide_size = chunk_size / (autoLOD * terrain.LOD)
	mesh = PlaneMesh.new()
	mesh.size = Vector2(chunk_size, chunk_size)
	mesh.subdivide_depth = subdivide_size
	mesh.subdivide_width = subdivide_size
	return mesh


func create_collision_mesh(trimesh = false):
	# Rebuild the terrain mesh
	var new_mesh = create_base_mesh()
	var terrain_mesh = create_noise_terrain(new_mesh)
	mesh = terrain_mesh

	if trimesh:
		# This built-in function creates a StaticBody3D + CollisionShape3D child for us
		create_trimesh_collision()

		# Give the terrain collision a unique name so we only remove it (and not spawned objects)
		for child in get_children():
			if child.get_class() == "StaticBody3D":
				child.name = "TerrainCollision"


func remove_chunk():
	var cName = "c_" + str(global_position.x) + "X" + str(global_position.z)
	terrain.chunk_list.erase(cName)
	create_tween().tween_property(self, "transparency", 1, terrain.chunk_show_speed).set_trans(Tween.TRANS_LINEAR)
	await get_tree().create_timer(terrain.chunk_show_speed).timeout
	queue_free()


func _process(_delta):
	var dist = get_distance()

	# If chunk is too far away, remove it entirely
	if dist > (terrain.render_distance * terrain.chunk_size) / 1.25:
		remove_chunk()
		return

	# Adjust LOD by distance using constants
	var distance_ratio = dist / terrain.chunk_size
	if distance_ratio <= LOD_DISTANCE_CLOSE:
		autoLOD = 0.5
	elif distance_ratio <= LOD_DISTANCE_MEDIUM:
		autoLOD = 1
	elif distance_ratio <= LOD_DISTANCE_FAR:
		autoLOD = 2
	elif distance_ratio <= LOD_DISTANCE_VERY_FAR:
		autoLOD = 4
	elif distance_ratio <= LOD_DISTANCE_EXTREME:
		autoLOD = 6
	else:
		autoLOD = 3

	# Rebuild terrain collision if LOD changed
	if oldLod != autoLOD:
		oldLod = autoLOD

		# IMPORTANT FIX:
		# Only remove the terrain collision body, not every StaticBody3D
		for child in get_children():
			if child.get_class() == "StaticBody3D" and child.name == "TerrainCollision":
				child.free()

		# Re-create collision if needed
		if autoLOD < 1 and terrain.optimised_collision:
			create_collision_mesh(true)
		elif not terrain.optimised_collision:
			create_collision_mesh(true)


func create_lod(_pos):
	var lod = 1
	mesh.subdivide_width = terrain.chunk_size / lod
	mesh.subdivide_depth = terrain.chunk_size / lod
	return mesh


func create_noise_terrain(_mesh):
	var surface_tool = SurfaceTool.new()
	var data_tool = MeshDataTool.new()

	terrain.noise.offset = position  # Important for chunk-level noise offset

	surface_tool.clear()
	surface_tool.create_from(_mesh, 0)
	var array_mesh = surface_tool.commit()

	data_tool.clear()
	data_tool.create_from_surface(array_mesh, 0)

	var vertex_count = data_tool.get_vertex_count()
	for i in range(vertex_count):
		var vertex = data_tool.get_vertex(i)
		var value = terrain.noise.get_noise_3d(vertex.x, vertex.y, vertex.z)
		vertex.y = value * terrain.terrain_height
		data_tool.set_vertex(i, vertex)

	array_mesh.clear_surfaces()
	data_tool.commit_to_surface(array_mesh)
	surface_tool.clear()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.create_from(array_mesh, 0)
	surface_tool.generate_normals()
	return surface_tool.commit()


func get_terrain_height(world_x: float, world_z: float) -> float:
	var local_x = world_x - position.x
	var local_z = world_z - position.z
	var noise_value = terrain.noise.get_noise_3d(local_x, 0, local_z)
	return noise_value * terrain.terrain_height


func create_chunk(pos: Vector3):
	position = pos
	var cName = "c_" + str(pos.x) + "X" + str(pos.z)
	transparency = 1
	terrain.noise.offset = pos

	mesh = PlaneMesh.new()
	mesh.size = Vector2(terrain.chunk_size, terrain.chunk_size)
	name = cName
	mesh = create_lod(pos)
	material_override = load("res://texture/desert.tres")
	var terrain_chunk = create_noise_terrain(mesh)
	mesh = terrain_chunk

	terrain.chunk_list.append(cName)

	# Randomly spawn a plant or post
	if randi() % 100 < OBJECT_SPAWN_CHANCE:
		var random_x = randf_range(0, terrain.chunk_size)
		var random_z = randf_range(0, terrain.chunk_size)
		var world_x = pos.x + random_x
		var world_z = pos.z + random_z
		var height_y = get_terrain_height(world_x, world_z)
		var spawn_pos = Vector3(world_x, height_y, world_z)

		var random_rotation = randf() * 360.0
		var random_scale = 1.0
		spawn_body(spawn_pos + Vector3(0, 0.75, 0), random_rotation, random_scale)

	# Randomly spawn a ruin or structure
	if randi() % 300 < STRUCTURE_SPAWN_CHANCE:
		var random_rotation = randf() * 360.0
		var random_scale = 2 + randf() * 1.5
		spawn_structure(
			position + Vector3(terrain.chunk_size * 0.5, 4 * random_scale, terrain.chunk_size * 0.5),
			random_rotation,
			random_scale
		)

	return self


func spawn_structure(pos: Vector3, rotation_y: float, scale_factor: float):
	var ruins = ruins_scene.instantiate()
	add_child(ruins)
	ruins.call_deferred("_set_transform", pos, rotation_y, scale_factor)
	ruins.env = terrain.env
	ruins.spawn_loot(pos)


func spawn_body(pos: Vector3, rotation_y: float, scale_factor: float):
	# Weighted selection from spawnables
	var total_chance = 0.0
	for chance in spawn_chances:
		total_chance += chance

	var roll = randf() * total_chance
	var cumulative = 0.0
	var chosen_index = 0

	for i in range(spawnables.size()):
		cumulative += spawn_chances[i]
		if roll <= cumulative:
			chosen_index = i
			break

	var selected_scene = spawnables[chosen_index].instantiate()
	add_child(selected_scene)

	# We'll call a custom method _set_transform() in the spawnable scene
	selected_scene.call_deferred("_set_transform", pos, rotation_y, scale_factor)
