shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// --- SHADER DE PERMAFROST & GELO GLACIAL ANCESTRAL (DARK FANTASY) ---
uniform vec4 ice_deep : source_color = vec4(0.06, 0.14, 0.22, 1.0);   // Gelo escuro profundo
uniform vec4 ice_shallow : source_color = vec4(0.18, 0.38, 0.52, 1.0); // Gelo glacial translúcido
uniform vec4 frost_rim : source_color = vec4(0.75, 0.88, 0.98, 1.0);   // Geada e rachaduras de gelo

uniform float uv_scale : hint_range(1.0, 15.0) = 4.0;
uniform float crack_intensity : hint_range(0.0, 2.0) = 0.65;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float voronoi_cracks(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	vec2 mg, mr;
	float md = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < md) {
				md = d;
				mr = r;
				mg = g;
			}
		}
	}
	md = 8.0;
	for (int j = -2; j <= 2; j++) {
		for (int i = -2; i <= 2; i++) {
			vec2 g = mg + vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			vec2 r = g + o - f;
			if (dot(mr - r, mr - r) > 0.00001) {
				md = min(md, dot(0.5 * (mr + r), normalize(r - mr)));
			}
		}
	}
	return md;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 base_uv = world_pos.xz * (uv_scale * 0.10);

	float d_crack = voronoi_cracks(base_uv * 1.8);
	float crack_mask = 1.0 - smoothstep(0.01, 0.08, d_crack);

	vec3 col = mix(ice_deep.rgb, ice_shallow.rgb, smoothstep(0.1, 0.4, d_crack));
	col = mix(col, frost_rim.rgb, crack_mask * 0.85);

	// Transição circular suave nas bordas
	float dist = length(UV - vec2(0.5)) * 2.0;
	float alpha_fade = 1.0 - smoothstep(0.50, 0.95, dist);

	ALBEDO = col;
	ROUGHNESS = mix(0.12, 0.55, crack_mask);
	METALLIC = 0.05;
	SPECULAR = 0.75;
	EMISSION = frost_rim.rgb * crack_mask * crack_intensity * 0.35;
	ALPHA = alpha_fade * 0.95;
}
