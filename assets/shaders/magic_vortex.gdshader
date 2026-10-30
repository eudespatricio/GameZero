shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// Círculo rúnico do Vórtice de Sylveria: anéis, runas pulsantes e braços espiralados puxando para o centro.

uniform vec4 color : source_color = vec4(0.70, 0.30, 1.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float intensity = 2.0;

float hash(float n) {
	return fract(sin(n * 78.233) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float ang = atan(uv.y, uv.x);
	float t = TIME;

	float mask = 1.0 - smoothstep(0.94, 1.0, r);

	// Anéis concêntricos
	float ring = smoothstep(0.022, 0.0, abs(r - 0.93)) + smoothstep(0.016, 0.0, abs(r - 0.80)) * 0.7;

	// Runas entre os anéis
	float seg_f = (ang + 3.14159) / 6.28318 * 24.0;
	float seg = floor(seg_f);
	float tick = fract(seg_f);
	float rune = step(0.82, r) * step(r, 0.92) * step(0.30, tick) * step(tick, 0.70) * step(0.5, hash(seg)) * (0.6 + 0.4 * sin(t * 3.0 + seg));

	// Braços espiralados (fase decrescente em r => movimento para dentro)
	float sp = ang * 3.0 + r * 9.0 + t * 5.0;
	float arms = pow(0.5 + 0.5 * sin(sp), 3.0) * smoothstep(0.08, 0.28, r) * (1.0 - smoothstep(0.70, 0.95, r));

	float core = smoothstep(0.28, 0.0, r) * (0.7 + 0.3 * sin(t * 8.0));

	float a = (ring + rune * 0.9 + arms * 0.8 + core) * mask * alpha;
	ALBEDO = mix(color.rgb, vec3(1.0), core * 0.5) * intensity;
	ALPHA = clamp(a, 0.0, 1.0);
}
