@tool
extends MeshInstance3D

@export var noise : FastNoiseLite:
	set(value):
		noise = value
		if noise != null and Engine.is_editor_hint():
			apply_noise_to_mesh()
			material_override = _build_material()

@export var height_multiplier : float = 10.0:
	set(value):
		height_multiplier = value
		if noise != null and Engine.is_editor_hint():
			apply_noise_to_mesh()
			material_override = _build_material()

@export_group("Material")
@export var color_valley: Color = Color(0.08, 0.22, 0.04)
@export var color_peak:   Color = Color(0.15, 0.42, 0.08)
@export var noise_strength: float = 0.25
@export var noise_scale: float = 25.0

func _ready():
	if noise != null:
		apply_noise_to_mesh()
	material_override = _build_material()


func _build_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://ground.gdshader")
	mat.set_shader_parameter("color_valley", color_valley)
	mat.set_shader_parameter("color_peak", color_peak)
	mat.set_shader_parameter("noise_strength", noise_strength)
	mat.set_shader_parameter("noise_scale", noise_scale)
	mat.set_shader_parameter("height_range", height_multiplier)

	if noise:
		var noise_tex := NoiseTexture2D.new()
		noise_tex.noise = noise
		noise_tex.width = 256
		noise_tex.height = 256
		mat.set_shader_parameter("noise", noise_tex)

	return mat

func apply_noise_to_mesh():
	# 1. Use SurfaceTool as a translator to convert the Primitive PlaneMesh to an ArrayMesh
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(mesh, 0)
	var array_mesh = surface_tool.commit()
	
	# 2. NOW the MeshDataTool can safely read it
	var mesh_data = MeshDataTool.new()
	mesh_data.create_from_surface(array_mesh, 0)
	
	# 3. Loop through and pull the vertices up and down
	for i in range(mesh_data.get_vertex_count()):
		var vertex = mesh_data.get_vertex(i)
		var height = noise.get_noise_2d(vertex.x, vertex.z) * height_multiplier
		vertex.y = height
		mesh_data.set_vertex(i, vertex)
	
	# 4. Clear the old flat data and commit the bumpy data
	array_mesh.clear_surfaces()
	mesh_data.commit_to_surface(array_mesh)
	
	# 5. Fix the lighting so it doesn't look like a flat optical illusion
	var final_surface_tool = SurfaceTool.new()
	final_surface_tool.create_from(array_mesh, 0)
	final_surface_tool.generate_normals()
	
	# 6. Apply the final visible mesh
	mesh = final_surface_tool.commit()
	
	# --- 7. NEW: Generate the Physics Floor ---
	# Clean up any old collision nodes first
	for child in get_children():
		if child is StaticBody3D:
			child.queue_free()
			
	# Tell Godot to auto-generate a physics body based on the bumpy mesh
	create_trimesh_collision()