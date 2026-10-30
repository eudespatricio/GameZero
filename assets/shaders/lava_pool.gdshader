shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// --- SHADER DE CALDEIRA VULCÂNICA & LAVA BASÁLTICA DARK FANTASY (DIABLO IV) ---
// Fissuras tectônicas orgânicas sem bolinhas, com transição circular suave sem costuras.

uniform vec4 lava_hot : source_color = vec4(1.0, 0.65, 0.12, 1.0);     // Núcleo de magma incandescente
uniform vec4 lava_mid : source_color = vec4(0.85, 0.16, 0.02, 1.0);    // Magma vermelho rubro viscoso
uniform vec4 basalt_crust : source_color = vec4(0.06, 0.05, 0.05, 1.0); // Basalto negro poroso
uniform vec4 basalt_rim : source_color = vec4(0.14, 0.11, 0.10, 1.0);   // Borda queimada das placas

uniform float flow_speed : hint_range(0.01, 1.0) = 0.12;
uniform float uv_scale : hint_range(0.5, 10.0) = 3.2;
uniform float crack_width : hint_range(0.02, 0.40) = 0.11;
uniform float emission_boost : hint_range(0.5, 4.0) = 1.45;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Voronoi F2 - F1 (Distância à Borda da Placa): Fissuras tectônicas
float voronoi_edge_cracks(vec2 p) {
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
	vec2 base_uv = world_pos.xz * (uv_scale * 0.12);

	// Distorção orgânica de fluxo contínuo
	float warp1 = noise2d(base_uv * 2.2 + vec2(TIME * flow_speed * 0.2, 0.0));
	float warp2 = noise2d(base_uv * 2.2 + vec2(0.0, TIME * flow_speed * 0.2));
	vec2 warped_uv = base_uv + vec2(warp1, warp2) * 0.28;

	// Distância às fissuras entre placas
	float edge_dist = voronoi_edge_cracks(warped_uv);

	// Máscara de fissura: alta na borda, zero no centro da placa
	float fissure_mask = 1.0 - smoothstep(0.01, crack_width, edge_dist);
	float hot_core = 1.0 - smoothstep(0.005, crack_width * 0.40, edge_dist);

	// Textura de basalto poroso
	float rock_noise = noise2d(base_uv * 8.0);
	vec3 plate_col = mix(basalt_crust.rgb, basalt_rim.rgb, smoothstep(0.05, 0.25, edge_dist));
	plate_col *= (0.85 + rock_noise * 0.30);

	// Cor do magma nas fissuras
	vec3 magma_col = mix(lava_mid.rgb, lava_hot.rgb, hot_core);

	vec3 col = mix(plate_col, magma_col, fissure_mask);

	// Transição perfeitamente circular (fade radial de 0.50 a 0.95)
	// Elimina 100% de cantos quadrados e costuras com o chão
	float dist = length(UV - vec2(0.5)) * 2.0;
	float alpha_fade = 1.0 - smoothstep(0.50, 0.95, dist);

	ALBEDO = col;
	ROUGHNESS = mix(0.92, 0.20, fissure_mask);
	METALLIC = 0.05;
	SPECULAR = mix(0.18, 0.70, fissure_mask);

	// Emissão apenas nas fissuras incandescentes
	EMISSION = magma_col * fissure_mask * emission_boost;
	ALPHA = alpha_fade * 0.98;
}
