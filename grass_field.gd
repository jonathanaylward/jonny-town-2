extends MultiMeshInstance3D

@export var blade_count: int = 40000
@export var field_size: Vector2 = Vector2(50.0, 50.0)
@export var ground_y: float = 0.25

@export_group("Terrain")
@export var terrain_noise: FastNoiseLite
@export var terrain_height_multiplier: float = 10.0
@export var scale_variance: float = 0.25
@export var height_variance: float = 0.5
@export var color_base: Color = Color(0.15, 0.42, 0.08)
@export var color_tip: Color = Color(0.45, 0.72, 0.18)

@export_group("Wind")
@export var wind_direction: Vector2 = Vector2(1.0, 0.3)
@export var wind_speed: float = 1.4
@export var wind_strength: float = 0.3
@export var wind_frequency: float = 0.5
@export var gust_frequency: float = 0.25
@export var gust_strength: float = 0.6


func _ready() -> void:
	multimesh = _build_multimesh()
	material_override = _build_material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_multimesh() -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = load("res://mesh/Grass_2_Mesh.res")
	mm.instance_count = blade_count

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in blade_count:
		var x := rng.randf_range(-field_size.x * 0.5, field_size.x * 0.5)
		var z := rng.randf_range(-field_size.y * 0.5, field_size.y * 0.5)
		var scale := 1.0 + rng.randf_range(-scale_variance, scale_variance)
		var height := 1.0 + rng.randf_range(-height_variance, height_variance)
		var rot_y := rng.randf_range(0.0, TAU)

		var t := Transform3D.IDENTITY
		t = t.scaled(Vector3(scale * 0.5, scale * height * 0.5, scale * 0.5))
		t = t.rotated(Vector3.UP, rot_y)
		var y := ground_y
		if terrain_noise:
			y = terrain_noise.get_noise_2d(x, z) * terrain_height_multiplier
		t.origin = Vector3(x, y, z)
		mm.set_instance_transform(i, t)

	return mm


func _build_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://mesh/Grass_2_Mesh.gdshader")
	mat.set_shader_parameter("color", color_base)
	mat.set_shader_parameter("color2", color_tip)
	mat.set_shader_parameter("noiseScale", 20.0)
	mat.set_shader_parameter("windDirection", wind_direction)
	mat.set_shader_parameter("windSpeed", wind_speed)
	mat.set_shader_parameter("windStrength", wind_strength)
	mat.set_shader_parameter("windFrequency", wind_frequency)
	mat.set_shader_parameter("gustFrequency", gust_frequency)
	mat.set_shader_parameter("gustStrength", gust_strength)

	var noise_tex := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.05
	noise_tex.noise = noise
	noise_tex.width = 256
	noise_tex.height = 256
	mat.set_shader_parameter("noise", noise_tex)

	return mat
