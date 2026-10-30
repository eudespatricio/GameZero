shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

// --- SHADER DE ÁGUA DE RIO ÉLFICO / ALAGAËSIA (DARK FANTASY) ---
// Água fluida e translúcida com correnteza, reflexos PBR, espumas nas margens e ondulação.

uniform vec4 shallow_color : source_color = vec4(0.10, 0.52, 0.62, 0.85); // Água rasa cristalina azul-turquesa
uniform vec4 deep_color : source_color = vec4(0.03, 0.18, 0.32, 0.94);    // Profundidade safira escura
uniform vec4 foam_color : source_color = vec4(0.88, 0.96, 1.0, 0.95);    // Espuma alva das margens

uniform float flow_speed : hint_range(0.0, 3.0) = 0.65;
uniform float wave_amplitude : hint_range(0.0, 0.3) = 0.04;
uniform float wave_frequency : hint_range(0.1, 10.0) = 2.2;
uniform float foam_edge_width : hint_range(0.01, 0.4) = 0.12;

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

void vertex() {
	// Ondulação suave da correnteza ao longo do leito do rio (eixo X)
	float t = TIME * flow_speed;
	float w1 = sin(VERTEX.x * wave_frequency + t * 2.4) * 0.03;
	float w2 = cos(VERTEX.z * (wave_frequency * 1.5) + t * 1.8) * 0.02;
	VERTEX.y += w1 + w2;
}

void fragment() {
	// UV contínua ao longo do rio (X = fluxo, Z = largura da margem)
	vec2 uv_flow1 = UV * vec2(48.0, 3.0) + vec2(TIME * flow_speed, 0.0);
	vec2 uv_flow2 = UV * vec2(36.0, 2.5) + vec2(TIME * flow_speed * 1.35, TIME * 0.05);

	float n1 = noise(uv_flow1);
	float n2 = noise(uv_flow2);
	float ripple = (n1 + n2) * 0.5;

	// Gradiente de profundidade: mais raso nas margens (UV.y = 0 ou 1), mais fundo no centro (UV.y = 0.5)
	float bank_dist = abs(UV.y - 0.5) * 2.0; // 0 no centro, 1 nas margens
	float depth_fac = 1.0 - smoothstep(0.2, 0.95, bank_dist);

	vec3 water_rgb = mix(shallow_color.rgb, deep_color.rgb, depth_fac);

	// Espuma nas margens do rio (borda de contato com as pedras e areia)
	float foam_mask = smoothstep(1.0 - foam_edge_width, 1.0, bank_dist);
	// Espuma de correnteza no meio das ondas
	float crest_foam = smoothstep(0.68, 0.85, ripple) * 0.45 * depth_fac;
	float total_foam = clamp(foam_mask + crest_foam, 0.0, 1.0);

	vec3 final_color = mix(water_rgb, foam_color.rgb, total_foam * 0.88);

	// Normais procedurais para reflexão especular da luz do sol
	vec3 norm = vec3((n1 - 0.5) * 0.35, 1.0, (n2 - 0.5) * 0.35);

	ALBEDO = final_color;
	NORMAL = normalize(norm);
	ALPHA = mix(shallow_color.a, deep_color.a, depth_fac);
	ROUGHNESS = mix(0.08, 0.45, total_foam);
	METALLIC = 0.02;
	SPECULAR = 0.70;
}
