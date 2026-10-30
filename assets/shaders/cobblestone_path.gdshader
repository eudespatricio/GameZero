shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 stone_color_1 : source_color = vec4(0.20, 0.19, 0.18, 1.0);
uniform vec4 stone_color_2 : source_color = vec4(0.13, 0.13, 0.14, 1.0);
uniform vec4 mortar_dirt : source_color = vec4(0.07, 0.06, 0.05, 1.0);
uniform vec4 moss_seam : source_color = vec4(0.06, 0.13, 0.07, 1.0);

uniform vec2 uv_scale = vec2(14.0, 36.0);

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec2 i_uv = floor(uv);
	vec2 f_uv = fract(uv);

	// Voronoi irregular flagstone (pedras orgânicas medievais estilo Diablo IV, sem grade quadrada artificial)
	float min_dist1 = 8.0;
	float min_dist2 = 8.0;
	vec2 best_cell = vec2(0.0);
	vec2 best_vec = vec2(0.0);

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 pt = hash2(i_uv + neighbor);
			pt = 0.2 + 0.6 * pt;
			vec2 diff = neighbor + pt - f_uv;
			float d = length(diff);
			if (d < min_dist1) {
				min_dist2 = min_dist1;
				min_dist1 = d;
				best_cell = i_uv + neighbor;
				best_vec = diff;
			} else if (d < min_dist2) {
				min_dist2 = d;
			}
		}
	}

	float border = min_dist2 - min_dist1;
	float seam_mask = 1.0 - smoothstep(0.03, 0.11, border);

	vec2 rnd = hash2(best_cell);
	vec3 stone_rgb = mix(stone_color_1.rgb, stone_color_2.rgb, rnd.x);
	// Micro-variação de superfície na laje
	stone_rgb *= 0.90 + 0.18 * hash2(floor(uv * 3.0)).y;

	vec3 seam_rgb = mix(mortar_dirt.rgb, moss_seam.rgb, smoothstep(0.35, 0.75, rnd.y));
	vec3 final_color = mix(stone_rgb, seam_rgb, seam_mask);

	// Bordas laterais da estrada desgastadas mesclando suavemente com o solo da floresta
	float edge_fade = smoothstep(0.0, 0.12, UV.x) * smoothstep(1.0, 0.88, UV.x);
	float edge_noise = hash2(floor(uv * 0.5)).x * 0.08;
	float alpha_mask = clamp((edge_fade - edge_noise) * 1.15, 0.0, 1.0);

	// Relevo suave de laje plana desgastada (sem almofadas estufadas)
	vec2 norm_xy = best_vec * (1.0 - seam_mask) * 0.55;
	vec3 tangent_norm = normalize(vec3(norm_xy.x, norm_xy.y, 1.0));

	ALBEDO = final_color;
	ALPHA = alpha_mask;
	NORMAL_MAP = tangent_norm * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.65;
	ROUGHNESS = mix(0.78, 0.96, seam_mask);
	METALLIC = 0.04;
	SPECULAR = 0.18;
}
