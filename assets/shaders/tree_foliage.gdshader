shader_type spatial;
render_mode depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

// --- CORES DA FOLHAGEM ÉLFICA (PALETA RICA MULTI-TOM DARK FANTASY) ---
uniform vec4 foliage_deep : source_color = vec4(0.04, 0.13, 0.07, 1.0);     // Verde esmeralda florestal escuro
uniform vec4 foliage_mid : source_color = vec4(0.08, 0.26, 0.14, 1.0);      // Verde viridiano elegante
uniform vec4 foliage_highlight : source_color = vec4(0.16, 0.42, 0.18, 1.0);// Folhagem nobre iluminada
uniform vec4 foliage_tip : source_color = vec4(0.30, 0.55, 0.22, 1.0);      // Luz suave de pontas élficas
uniform vec4 foliage_backlight : source_color = vec4(0.12, 0.38, 0.18, 1.0);// Transparência / Subsurface scattering

// --- PARÂMETROS DE RENDERIZAÇÃO & VENTO ---
uniform float roughness_val : hint_range(0.0, 1.0) = 0.86;
uniform float wind_speed = 1.4;
uniform float wind_strength = 0.12;
uniform float leaf_cluster_scale = 6.5;

// --- DESOBSTRUÇÃO DE VISÃO (SEE-THROUGH OCCLUSION) ---
global uniform vec3 player_world_pos;
global uniform vec3 camera_world_pos;

uniform float player_fade_radius = 6.8;    // Raio de corte quando o herói passa por baixo
uniform float player_fade_min = 0.18;      // Alpha mínimo sob a copa (visibilidade clara do herói)
uniform float los_capsule_radius = 3.6;    // Raio da linha de visão Câmera-Jogador
uniform float los_fade_min = 0.20;         // Alpha mínimo quando bloqueia a visão da câmera

// --- RUÍDO PROCEDURAL RÁPIDO ---
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Distância do ponto ao segmento de reta [A, B]
float dist_to_segment(vec3 p, vec3 a, vec3 b) {
	vec3 ab = b - a;
	vec3 ap = p - a;
	float t = clamp(dot(ap, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
	vec3 closest = a + t * ab;
	return length(p - closest);
}

void vertex() {
	// Balanço orgânico suave da copa das árvores com o vento
	vec3 wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sway_h = clamp(VERTEX.y * 0.12, 0.0, 1.5);
	float wave = sin(TIME * wind_speed + wpos.x * 0.4 + wpos.z * 0.4);
	float wave_cross = cos(TIME * (wind_speed * 0.85) + wpos.z * 0.5);
	
	VERTEX.x += wave * wind_strength * sway_h;
	VERTEX.z += wave_cross * (wind_strength * 0.75) * sway_h;
}

void fragment() {
	// Reconstrução de coordenadas de mundo
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// 1. TEXTURA PROCEDURAL DE FOLHAS & VARIAÇÃO MULTI-TOM
	vec2 p = world_pos.xz * 0.35 + vec2(world_pos.y * 0.25);
	float n_macro = noise2d(p * 0.6) * 0.7 + noise2d(p * 1.3) * 0.3;
	float n_leaf = noise2d(world_pos.xz * leaf_cluster_scale + vec2(world_pos.y * 1.5));
	
	// Gradiente vertical e normal de face (luz do sol no topo das copas)
	float sun_facing = clamp(NORMAL.y * 0.5 + 0.5, 0.0, 1.0);
	
	vec3 color = mix(foliage_deep.rgb, foliage_mid.rgb, n_macro);
	color = mix(color, foliage_highlight.rgb, sun_facing * 0.7 + n_leaf * 0.3);
	
	// Pontas élficas ensolaradas nos vértices externos
	float tip_mask = smoothstep(0.68, 0.95, sun_facing + n_leaf * 0.35);
	color = mix(color, foliage_tip.rgb, tip_mask * 0.6);
	
	ALBEDO = color;
	NORMAL = normalize(NORMAL + vec3(dFdx(n_leaf) * 1.6, 0.0, dFdy(n_leaf) * 1.6));
	ROUGHNESS = roughness_val;
	METALLIC = 0.0;
	SPECULAR = 0.25;
	BACKLIGHT = foliage_backlight.rgb * 0.38; // Simulação de translucência natural de folhas
	
	// 2. SISTEMA DE DESOBSTRUÇÃO DE VISÃO COM FAST-PATH DE DISTÂNCIA
	float dist_xz = length(world_pos.xz - player_world_pos.xz);
	if (dist_xz > 12.0) {
		ALPHA = 1.0;
	} else {
		// Caso A: Jogador passando por baixo da copa
		float height_diff = world_pos.y - player_world_pos.y;
		float prox_alpha = 1.0;
		if (height_diff > 0.6) {
			prox_alpha = smoothstep(1.8, player_fade_radius, dist_xz);
		}
		
		// Caso B: Folhagem situada entre a câmera e o jogador
		vec3 player_eye = player_world_pos + vec3(0.0, 1.25, 0.0);
		float dist_los = dist_to_segment(world_pos, player_eye, camera_world_pos);
		float los_alpha = smoothstep(1.2, los_capsule_radius, dist_los);
		
		// Combinação dos fatores de oclusão
		float total_occlusion = min(prox_alpha, los_alpha);
		float final_alpha = mix(min(player_fade_min, los_fade_min), 1.0, total_occlusion);
		
		// Borda sutil de destaque quando transparente para preservar a silhueta graciosa da árvore
		if (total_occlusion < 0.9) {
			float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
			ALBEDO += foliage_tip.rgb * pow(rim, 3.0) * (1.0 - total_occlusion) * 0.45;
		}
		
		ALPHA = final_alpha;
	}
}
