shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// --- SHADER DE RUÍNAS ÉLFICAS & PÁTIO ANCESTRAL (DARK FANTASY / DIABLO IV) ---
// Substitui o portal cósmico cegante por um solo de lajotas de pedra desgastada,
// musgo ancestral e glifos rúnicos com brilho suave e transição circular orgânica.

uniform vec4 stone_dark : source_color = vec4(0.14, 0.15, 0.17, 1.0);  // Granito escuro desgastado
uniform vec4 stone_light : source_color = vec4(0.24, 0.26, 0.28, 1.0); // Lajota desgastada pelo tempo
uniform vec4 moss_color : source_color = vec4(0.08, 0.14, 0.07, 1.0);   // Musgo élfico nas frestas
uniform vec4 rune_glow : source_color = vec4(0.25, 0.85, 0.65, 1.0);   // Glifos arcanos sutis

uniform float uv_scale : hint_range(1.0, 15.0) = 4.5;
uniform float rune_intensity : hint_range(0.0, 2.0) = 0.45;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Padrão procedural de lajotas de pedra (flagstones)
float stone_grid(vec2 p) {
	vec2 grid = abs(fract(p - 0.5) - 0.5);
	float edge = min(grid.x, grid.y);
	return edge;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 base_uv = world_pos.xz * (uv_scale * 0.10);

	// Leve irregularidade nas bordas das lajotas
	float warp = noise(base_uv * 4.0) * 0.06;
	float edge = stone_grid(base_uv + vec2(warp));
	float mortar = 1.0 - smoothstep(0.02, 0.08, edge);

	// Variação de cor entre pedras vizinhas
	vec2 stone_id = floor(base_uv + vec2(warp));
	float stone_rnd = hash(stone_id);
	vec3 stone_col = mix(stone_dark.rgb, stone_light.rgb, stone_rnd);
	stone_col *= (0.85 + noise(base_uv * 12.0) * 0.30);

	// Musgo entre as juntas das pedras
	vec3 col = mix(stone_col, moss_color.rgb, mortar * 0.85);

	// Glifo Rúnico Élfico Circular (Brilho atmosférico sutil, nunca cegante)
	vec2 center_uv = UV * 2.0 - 1.0;
	float dist_c = length(center_uv);
	float ang = atan(center_uv.y, center_uv.x);

	// Anel rúnico concêntrico suave
	float rune_ring1 = smoothstep(0.03, 0.0, abs(dist_c - 0.72));
	float rune_ring2 = smoothstep(0.02, 0.0, abs(dist_c - 0.50));
	float glyph_dots = step(0.65, sin(ang * 12.0 + TIME * 0.4)) * step(0.68, dist_c) * step(dist_c, 0.76);
	float rune_mask = clamp(rune_ring1 * 0.7 + rune_ring2 * 0.5 + glyph_dots * 0.6, 0.0, 1.0);

	// Transição perfeitamente circular nas bordas da arena (fade suave para o solo da floresta)
	float dist = length(UV - vec2(0.5)) * 2.0;
	float alpha_fade = 1.0 - smoothstep(0.50, 0.95, dist);

	ALBEDO = col;
	ROUGHNESS = mix(0.85, 0.65, mortar);
	METALLIC = 0.05;
	SPECULAR = 0.25;

	// Emissão suave dos glifos élficos (Dark Fantasy)
	EMISSION = rune_glow.rgb * rune_mask * rune_intensity;
	ALPHA = alpha_fade * 0.98;
}
