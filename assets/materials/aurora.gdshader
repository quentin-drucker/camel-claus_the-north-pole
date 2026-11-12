shader_type spatial;
// Slow aurora ribbon far behind the arena (menu backdrop): soft ice-blue / pine-green curtains that
// drift sideways, quantised into pixel steps so it matches the art style. Additive and fog-free, kept
// faint so it never competes with gameplay.
render_mode unshaded, blend_add, cull_disabled, fog_disabled, depth_draw_never;

uniform vec4 color_a : source_color = vec4(0.498, 0.839, 0.949, 1.0);
uniform vec4 color_b : source_color = vec4(0.243, 0.604, 0.357, 1.0);
uniform float strength = 0.35;
uniform float pixels = 96.0;

void fragment() {
	vec2 uv = floor(UV * vec2(pixels, pixels * 0.25)) / vec2(pixels, pixels * 0.25);
	float t = TIME * 0.05;
	float wave = sin(uv.x * 9.0 + t * 6.0) * 0.12 + sin(uv.x * 23.0 - t * 4.0) * 0.05;
	float band = smoothstep(0.0, 0.35, uv.y - 0.25 - wave) * (1.0 - smoothstep(0.35, 0.95, uv.y - wave));
	float curtains = 0.55 + 0.45 * sin(uv.x * 40.0 + t * 10.0);
	float edges = smoothstep(0.0, 0.15, uv.x) * smoothstep(1.0, 0.85, uv.x);
	vec3 col = mix(color_b.rgb, color_a.rgb, clamp(uv.y + wave, 0.0, 1.0));
	ALBEDO = col * band * curtains * edges * strength;
}
