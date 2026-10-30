shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// --- SHADER DE PÂNTANO TÓXICO & CHARCO PUTREFATO (DARK FANTASY / DIABLO IV) ---
uniform vec4 swamp_deep : source_color = vec4(0.02, 0.04, 0.02, 1.0);     // Lamaçal negro profundo
uniform vec4 swamp_mud : source_color = vec4(0.08, 0.12, 0.05, 1.0);      // Lodo pantanoso escuro
uniform vec4 swamp_algae : source_color = vec4(0.14, 0.22, 0.08, 1.0);    // Nata de algas decompostas
uniform vec4 swamp_gas : source_color = vec4(0.20, 0.35, 0.12, 1.0);      // Espuma sulfúrica sutil

uniform float ooze_speed = 0.15;
uniform float uv_scale = 4.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(137.1, 269.7))) * 43758.5453123);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	// Ondulação suave de água viscosa estagnada
	float ripple = sin(TIME * 1.5 + VERTEX.x * 2.0 + VERTEX.z * 1.8) * 0.015;
	VERTEX.y += ripple;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 p = world_pos.xz * (uv_scale * 0.08);
	
	// Correntes lentas de lodo viscoso em turbilhão
	vec2 swirl = p + vec2(sin(p.y * 1.5 + TIME * ooze_speed), cos(p.x * 1.5 + TIME * ooze_speed)) * 0.12;
	float n1 = noise2d(swirl * 3.0);
	float n2 = noise2d(swirl * 6.0 + vec2(TIME * ooze_speed * 0.3));
	
	// Máscara de lodo orgânico e nata fúnebre
	float scum_mask = smoothstep(0.40, 0.75, n1 + n2 * 0.4);
	float bubble_spots = smoothstep(0.78, 0.96, n2);
	
	vec3 col = mix(swamp_deep.rgb, swamp_mud.rgb, scum_mask);
	col = mix(col, swamp_algae.rgb, bubble_spots * 0.85);
	
	// Transição suave radial para fundir perfeitamente com o solo sem cortes rígidos
	float dist = length(UV - vec2(0.5)) * 2.0;
	float alpha_fade = smoothstep(1.0, 0.65, dist);
	
	ALBEDO = col;
	ROUGHNESS = mix(0.08, 0.65, scum_mask); // Água negra reflete o ambiente como espelho, lodo é mais fosco
	METALLIC = 0.02;
	SPECULAR = 0.80; // Reflexo especular molhado de alta fidelidade
	
	// Brilho orgânico tênue e fúnebre (sem cegueira neon)
	EMISSION = swamp_gas.rgb * bubble_spots * 0.25;
	ALPHA = alpha_fade * 0.94;
}