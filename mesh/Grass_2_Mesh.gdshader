shader_type spatial;
render_mode cull_disabled;

uniform vec3 color : source_color;
uniform vec3 color2 : source_color;
uniform sampler2D noise;
uniform float noiseScale = 20.0;

// Wind
uniform vec2 windDirection = vec2(1.0, 0.3);
uniform float windSpeed = 1.4;
uniform float windStrength = 0.3;
uniform float windFrequency = 0.5;
uniform float gustFrequency = 0.25;
uniform float gustStrength = 0.6;

varying vec3 worldPos;

void vertex() {
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Quadratic bend mask: base stays anchored, tip displaces fully.
	// UV.y is 0 at the tip and 1 at the base on this mesh, so invert.
	float bend = (1.0 - UV.y) * (1.0 - UV.y);

	vec2 windDir = normalize(windDirection);

	// Traveling primary wave along wind direction.
	float phase = dot(worldPos.xz, windDir) * windFrequency;
	float primaryWave = sin(TIME * windSpeed + phase);

	// Weaker cross-wind ripple for organic variation.
	vec2 perpDir = vec2(-windDir.y, windDir.x);
	float crossPhase = dot(worldPos.xz, perpDir) * windFrequency * 0.7;
	float crossWave = sin(TIME * windSpeed * 1.6 + crossPhase) * 0.25;

	// Slow rolling gust envelope.
	float gust = 1.0 + sin(TIME * gustFrequency + phase * 0.15) * gustStrength;
	gust = max(gust, 0.2);

	float totalWave = (primaryWave + crossWave) * gust;

	// Displace tip in XZ along wind direction.
	VERTEX.x += windDir.x * totalWave * windStrength * bend;
	VERTEX.z += windDir.y * totalWave * windStrength * bend;

	// Compress blade slightly downward when pushed sideways.
	VERTEX.y -= abs(totalWave) * windStrength * bend * 0.12;
}

void fragment() {
	vec3 noiseLevel = texture(noise, worldPos.xz / noiseScale).rgb;
	// Tint base color slightly with noise for per-cluster color variation.
	vec3 tintedBase = mix(color, color * (0.8 + noiseLevel.r * 0.4), 0.5);
	ALBEDO = mix(color2, tintedBase, UV.y);
}
