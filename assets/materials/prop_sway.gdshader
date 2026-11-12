shader_type spatial;
// Decorative props (MultiMesh): gentle sway that grows toward the top, plus an optional twinkle on the
// gold swatch (gift-pile ribbons). Phase comes from each instance's world position, so no two props
// move in sync. Lit like the baked StandardMaterial3Ds: matte, no specular, nearest filtering.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest;
// Metres of sway at `height` (0 = still).
uniform float sway = 0.0;
uniform float sway_speed = 1.2;
uniform float height = 3.0;
// 0..1: how bright gold texels flash now and then.
uniform float twinkle = 0.0;

varying float phase;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	phase = origin.x * 0.37 + origin.z * 0.53;
	float k = clamp(VERTEX.y / height, 0.0, 1.0);
	k *= k;
	VERTEX.x += sin(TIME * sway_speed + phase) * sway * k;
	VERTEX.z += cos(TIME * sway_speed * 0.8 + phase * 1.3) * sway * 0.6 * k;
}

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	if (twinkle > 0.0) {
		// #F2B53B in linear space.
		float gold = 1.0 - smoothstep(0.0, 0.06, distance(c, vec3(0.888, 0.462, 0.044)));
		float pulse = pow(max(sin(TIME * 2.2 + phase * 3.0 + UV.x * 20.0), 0.0), 12.0);
		EMISSION = c * gold * pulse * twinkle;
	}
}
