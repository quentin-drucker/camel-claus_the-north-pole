shader_type spatial;
render_mode specular_disabled;
// Pixel-art snow computed in world space: chunky texels, palette colors only,
// large drifts so the 120 m arena never shows a repeating tile.

uniform float pixels_per_meter = 16.0;
uniform vec3 snow_light : source_color = vec3(0.957, 0.973, 1.0);   // #F4F8FF
uniform vec3 snow_mid : source_color = vec3(0.788, 0.855, 0.941);   // #C9DAF0
uniform vec3 snow_dark : source_color = vec3(0.561, 0.663, 0.820);  // #8FA9D1
uniform vec3 sparkle : source_color = vec3(0.498, 0.839, 0.949);    // #7FD6F2
uniform float drift_scale = 0.07;
uniform float mid_threshold = 0.56;
uniform float dark_threshold = 0.76;

varying vec3 world_pos;

float hash(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = floor(world_pos.xz * pixels_per_meter);
	vec2 p = cell / pixels_per_meter;
	float drift = value_noise(p * drift_scale) * 0.6
			+ value_noise(p * drift_scale * 4.0) * 0.3
			+ value_noise(p * drift_scale * 16.0) * 0.1;
	float h = hash(cell + 17.0);
	vec3 c = snow_light;
	if (drift > mid_threshold) {
		c = snow_mid;
	}
	if (drift > dark_threshold) {
		c = snow_dark;
	}
	if (h > 0.9993) {
		c = sparkle;
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
