shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// Membrana de energia espiralada dos Portais de Fronteira (Quad vertical dentro do arco do portão)

uniform vec4 core_color : source_color = vec4(0.55, 0.92, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.10, 0.30, 0.95, 1.0);
uniform float swirl_speed = 0.9;
uniform float intensity = 1.7;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(11.7);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float ang = atan(q.y, q.x);
	float t = TIME * swirl_speed;

	float spiral = ang + r * 5.0 - t * 3.0;
	vec2 sp = vec2(cos(spiral), sin(spiral)) * r;
	float n = fbm(sp * 2.5 + vec2(t * 0.4, -t * 0.3));
	float arms = 0.5 + 0.5 * sin(spiral * 3.0 + n * 4.0);

	float core = smoothstep(0.55, 0.0, r);
	float rim = smoothstep(0.76, 0.96, r) * (1.0 - smoothstep(0.96, 1.04, r));
	float mask = 1.0 - smoothstep(0.90, 1.0, r);

	vec3 col = mix(edge_color.rgb, core_color.rgb, clamp(core + arms * 0.35 * n, 0.0, 1.0));
	col += rim * core_color.rgb * 1.4;

	ALBEDO = col * intensity;
	ALPHA = clamp((0.30 + arms * 0.45 + core * 0.65 + rim) * mask, 0.0, 1.0);
}
