shader_type spatial;
// Palette swap for Claus's cosmetics: every texel that is exactly one of `from_colors` becomes the
// matching `to_colors` (first match wins, so chains like tan->brown->dark don't cascade). Textures are
// palette-snapped, so exact matching is safe and every variant stays inside the art-direction palette.
// Lit like the baked StandardMaterial3Ds: matte, no specular, nearest filtering.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform vec4 from_colors[4] : source_color;
uniform vec4 to_colors[4] : source_color;
uniform int swap_count = 0;

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	for (int i = 0; i < 4; i++) {
		if (i < swap_count && distance(c, from_colors[i].rgb) < 0.01) {
			c = to_colors[i].rgb;
			break;
		}
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
