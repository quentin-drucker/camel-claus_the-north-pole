shader_type spatial;
render_mode specular_disabled;
// Waddle + bob for horde enemies, done on the GPU (no skeletons, no per-enemy CPU work).
// Rocks the model side to side around its feet and hops; the phase comes from the world
// position so neighbours don't move in lockstep.

uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform float waddle_speed = 9.0;
uniform float waddle_angle = 0.14;
uniform float bob_height = 0.05;
// Status look (hit flash / frozen / poisoned): blend toward a palette tint; frozen stops waddling.
uniform vec3 tint : source_color = vec3(1.0);
uniform float tint_amount = 0.0;
uniform float waddle = 1.0;

void vertex() {
	float phase = NODE_POSITION_WORLD.x * 1.7 + NODE_POSITION_WORLD.z * 1.3;
	float t = TIME * waddle_speed + phase;
	float a = sin(t) * waddle_angle * waddle;
	float c = cos(a);
	float s = sin(a);
	VERTEX.xy = vec2(c * VERTEX.x - s * VERTEX.y, s * VERTEX.x + c * VERTEX.y);
	NORMAL.xy = vec2(c * NORMAL.x - s * NORMAL.y, s * NORMAL.x + c * NORMAL.y);
	VERTEX.y += abs(sin(t)) * bob_height * waddle;
}

void fragment() {
	ALBEDO = mix(texture(albedo_tex, UV).rgb, tint, tint_amount);
	ROUGHNESS = 1.0;
}
