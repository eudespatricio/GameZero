shader_type spatial;
render_mode depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

// --- CORES DA MADEIRA ÉLFICA ANCESTRAL (PALETA DETALHADA) ---
uniform vec4 bark_shadow : source_color = vec4(0.05, 0.035, 0.025, 1.0);  // Fissuras e sulcos escuros profundos
uniform vec4 bark_base : source_color = vec4(0.14, 0.09, 0.065, 1.0);     // Madeira élfica antiga
uniform vec4 bark_ridge : source_color = vec4(0.25, 0.18, 0.12, 1.0);     // Cristas elevadas e ressecadas
uniform vec4 bark_moss : source_color = vec4(0.12, 0.30, 0.14, 1.0);      // Musgo aveludado ancestral nas fendas

// --- PARÂMETROS DA TEXTURA DE CASCA ---
uniform float uv_scale_y = 1.8;
uniform float uv_scale_circ = 6.0;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.88;
uniform float bump_strength : hint_range(0.0, 2.0) = 0.55;

// --- DESOBSTRUÇÃO DE VISÃO (SEE-THROUGH OCCLUSION) ---
global uniform vec3 player_world_pos;
global uniform vec3 camera_world_pos;

uniform float los_capsule_radius = 2.8;    // Raio da linha de visão Câmera-Jogador para troncos
uniform float los_fade_min = 0.25;         // Alpha mínimo quando tronco bloqueia visão do herói

// --- RUÍDO PROCEDURAL PARA RANHURAS VERTICAIS ---
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(133.7, 269.5))) * 43758.5453123);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float bark_fbm(vec2 p) {
	// Alongamento vertical para fibras e sulcos de madeira
	vec2 st = vec2(p.x, p.y * 0.28);
	return 0.65 * noise2d(st) + 0.35 * noise2d(st * vec2(2.1, 2.3) + vec2(5.2, 11.4));
}

// Distância do ponto ao segmento de reta [A, B]
float dist_to_segment(vec3 p, vec3 a, vec3 b) {
	vec3 ab = b - a;
	vec3 ap = p - a;
	float t = clamp(dot(ap, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
	vec3 closest = a + t * ab;
	return length(p - closest);
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// 1. MAPEAMENTO CILÍNDRICO PROCEDURAL DE FIBRAS DE MADEIRA
	float angle = atan(VERTEX.x, VERTEX.z);
	vec2 bark_uv = vec2(angle * uv_scale_circ, (world_pos.y + VERTEX.y * 0.5) * uv_scale_y);
	
	float grain = bark_fbm(bark_uv);
	float fine_fissures = noise2d(vec2(bark_uv.x * 2.5, bark_uv.y * 3.0));
	
	// Cor base e sulcos
	vec3 wood_col = mix(bark_shadow.rgb, bark_base.rgb, smoothstep(0.2, 0.55, grain));
	wood_col = mix(wood_col, bark_ridge.rgb, smoothstep(0.55, 0.85, grain + fine_fissures * 0.2));
	
	// Musgo verdejante em superfícies expostas para cima (raízes e bifurcações)
	float upward = clamp(NORMAL.y, 0.0, 1.0);
	float moss_mask = smoothstep(0.28, 0.75, upward * 0.8 + grain * 0.4);
	vec3 final_color = mix(wood_col, bark_moss.rgb, moss_mask * 0.7);
	
	// 2. PERTURBAÇÃO DE NORMAL REALISTA VIA DERIVADAS DE TELA
	vec3 bark_norm = normalize(NORMAL + vec3(dFdx(grain) * 1.8, 0.0, dFdy(fine_fissures) * 1.8) * bump_strength);
	NORMAL = bark_norm;
	
	ALBEDO = final_color;
	ROUGHNESS = roughness_val;
	METALLIC = 0.02;
	SPECULAR = 0.18;
	
	// 3. DESOBSTRUÇÃO DE VISÃO COM FAST-PATH DE DISTÂNCIA
	float dist_xz = length(world_pos.xz - player_world_pos.xz);
	if (dist_xz > 10.0) {
		ALPHA = 1.0;
	} else {
		// Tronos espessos entre a câmera e o jogador ficam transparentes
		vec3 player_eye = player_world_pos + vec3(0.0, 1.25, 0.0);
		float dist_los = dist_to_segment(world_pos, player_eye, camera_world_pos);
		float los_alpha = smoothstep(1.0, los_capsule_radius, dist_los);
		
		float final_alpha = mix(los_fade_min, 1.0, los_alpha);
		
		if (los_alpha < 0.9) {
			float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
			ALBEDO += bark_ridge.rgb * pow(rim, 3.0) * (1.0 - los_alpha) * 0.35;
		}
		
		ALPHA = final_alpha;
	}
}
