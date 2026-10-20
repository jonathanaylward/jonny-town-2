shader_type spatial;
render_mode diffuse_lambert;

uniform vec3 color_valley : source_color = vec3(0.08, 0.22, 0.04);
uniform vec3 color_peak   : source_color = vec3(0.15, 0.42, 0.08);
uniform sampler2D noise;
uniform float noise_scale   : hint_range(1.0, 100.0) = 25.0;
uniform float noise_strength : hint_range(0.0, 1.0)  = 0.25;
uniform float height_range  : hint_range(0.1, 50.0)  = 10.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Remap world Y into 0..1 across the expected terrain height range.
	float height_t = clamp((world_pos.y + height_range) / (height_range * 2.0), 0.0, 1.0);

	// Blend valley → peak color based on height.
	vec3 base_color = mix(color_valley, color_peak, height_t);

	// Add subtle noise-driven color patches.
	float n = texture(noise, world_pos.xz / noise_scale).r;
	base_color = mix(base_color, base_color * (0.75 + n * 0.5), noise_strength);

	ALBEDO = base_color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
