shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Paleta Dark Fantasy / Diablo IV (Scosglen & Sanctuary)
// Tons de musgo ancestral, húmus de floresta úmida, terra batida e xisto escuro equilibrados
uniform vec4 grass_dark : source_color = vec4(0.08, 0.18, 0.10, 1.0);
uniform vec4 grass_light : source_color = vec4(0.20, 0.38, 0.18, 1.0);
uniform vec4 dirt_color : source_color = vec4(0.22, 0.15, 0.10, 1.0);
uniform vec4 stone_color : source_color = vec4(0.28, 0.30, 0.33, 1.0);

uniform float uv_scale = 28.0;

// Biomas por região a partir do Santuário
uniform float biome_start = 70.0;
uniform float biome_full = 150.0;
uniform float biome_strength : hint_range(0.0, 1.0) = 1.0;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.88;

// Hash robusto sem trigonometria (Dave Hoskins) - imune a artefatos de precisão float em coordenadas distantes
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Ruído com interpolação quíntica Hermite (C1 contínuo) - elimina facetas triangulares e grid lines
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
	           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm2(vec2 p) {
	return 0.65 * noise(p) + 0.35 * noise(p * 2.18 + vec2(17.3, 41.7));
}

void fragment() {
	vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec2 p = world_pos * (uv_scale * 0.035);

	float n_macro = fbm2(p * 0.18);
	float n_mid = fbm2(p * 0.85);
	float n_micro = noise(p * 4.0);
	float n_pebble = noise(p * 18.0) * 0.65 + noise(p * 36.0) * 0.35;

	// Transição suave entre biomas sem descontinuidade
	float r = length(world_pos);
	vec2 d = world_pos / max(r, 0.001);
	float k = smoothstep(biome_start, biome_full, r) * biome_strength;
	float wN = smoothstep(0.20, 0.80, -d.y);
	float wW = smoothstep(0.20, 0.80, -d.x) * (1.0 - wN);
	float wS = smoothstep(0.20, 0.80, d.y);
	float wSE = wS * smoothstep(-0.20, 0.20, d.x);
	float wSW = wS * (1.0 - smoothstep(-0.20, 0.20, d.x));

	vec3 c_dark = grass_dark.rgb;
	vec3 c_light = grass_light.rgb;
	vec3 c_dirt = dirt_color.rgb;

	// Bioma Norte (Floresta Ancestral / Templo das Ruínas - verde musgo profundo e úmido)
	c_dark = mix(c_dark, vec3(0.07, 0.16, 0.09), wN * k);
	c_light = mix(c_light, vec3(0.16, 0.32, 0.16), wN * k);
	c_dirt = mix(c_dirt, vec3(0.18, 0.14, 0.10), wN * k);

	// Bioma Oeste (Terras Áridas / Cinzas Vulcânicas)
	c_dark = mix(c_dark, vec3(0.20, 0.15, 0.10), wW * k);
	c_light = mix(c_light, vec3(0.32, 0.25, 0.15), wW * k);
	c_dirt = mix(c_dirt, vec3(0.34, 0.26, 0.17), wW * k);

	// Bioma Sudeste (Ruínas Criptográficas / Pântano Negro)
	c_dark = mix(c_dark, vec3(0.12, 0.11, 0.14), wSE * k);
	c_light = mix(c_light, vec3(0.18, 0.17, 0.22), wSE * k);
	c_dirt = mix(c_dirt, vec3(0.17, 0.15, 0.18), wSE * k);

	// Bioma Sudoeste (Permafrost / Gelo Antigo)
	c_dark = mix(c_dark, vec3(0.13, 0.17, 0.23), wSW * k);
	c_light = mix(c_light, vec3(0.22, 0.29, 0.38), wSW * k);
	c_dirt = mix(c_dirt, vec3(0.20, 0.22, 0.27), wSW * k);

	// Composição de camadas: grama densa, tufos de musgo, terra de clareira e pedregulhos
	vec3 grass_clumps = mix(c_dark, c_light, smoothstep(0.25, 0.75, n_mid + (n_pebble - 0.5) * 0.25));
	vec3 base_terrain = mix(grass_clumps, c_dirt, smoothstep(0.38, 0.75, n_macro));
	base_terrain = mix(base_terrain, stone_color.rgb, smoothstep(0.65, 0.90, n_micro * n_pebble));
	// Micro-sombra de contato nos relevos da terra
	base_terrain *= (0.84 + 0.32 * n_pebble);

	// Relevo 3D de alta definição via derivadas de hardware (zero custo de GPU)
	float h = n_mid * 0.45 + n_pebble * 0.40 + n_micro * 0.15;
	vec3 bump_normal = normalize(NORMAL + vec3(dFdx(h) * 2.2, 0.0, dFdy(h) * 2.2));

	ALBEDO = base_terrain;
	NORMAL = bump_normal;
	ROUGHNESS = mix(roughness_val, 0.72, smoothstep(0.55, 0.85, n_macro));
	METALLIC = 0.01;
	SPECULAR = 0.18;
}
