shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// --- TELÉGRAFO DE COMBATE DARK FANTASY (DIABLO IV / SOULS) ---
// Substitui o disco vermelho de plástico por um anel rúnico de perigo com pulso e borda incandescente.

uniform vec4 danger_color : source_color = vec4(0.95, 0.18, 0.12, 1.0); // Carmesim de impacto
uniform vec4 rune_edge : source_color = vec4(1.0, 0.65, 0.15, 1.0);     // Borda incandescente
uniform float fill_progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);

	// Máscara externa circular suave (sem cantos duros)
	float outer_mask = 1.0 - smoothstep(0.96, 1.0, r);

	// Anel de aviso na borda externa
	float rim = smoothstep(0.04, 0.0, abs(r - 0.94)) * 1.5;
	float inner_rim = smoothstep(0.02, 0.0, abs(r - 0.88)) * 0.7;

	// Preenchimento interior translúcido com fade em direção ao centro
	float interior = smoothstep(0.0, 0.92, r) * 0.22;

	// Pulso de advertência
	float pulse = 0.85 + 0.15 * sin(TIME * 8.0);

	vec3 col = mix(danger_color.rgb, rune_edge.rgb, clamp(rim + inner_rim, 0.0, 1.0));
	float alpha = (interior + rim * 0.75 + inner_rim * 0.4) * outer_mask * pulse;

	ALBEDO = col;
	EMISSION = col * (rim * 1.8 + 0.3);
	ALPHA = clamp(alpha, 0.0, 0.85);
	ROUGHNESS = 0.5;
}
