shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// Onda de choque expansiva no solo (Jierda e impactos de boss). Use em PlaneMesh deitado.

uniform vec4 color : source_color = vec4(0.30, 0.95, 0.60, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float intensity = 2.2;
uniform float cracks = 1.0;

float hash(float n) {
	return fract(sin(n * 91.345) * 47453.5453);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	float ang = atan(uv.y, uv.x);

	float head = 1.0 - pow(1.0 - progress, 3.0);
	float d = head - r;

	// Borda de ataque nítida com cauda luminosa
	float ring = smoothstep(0.0, 0.012, d) * (1.0 - smoothstep(0.012, 0.10, d));
	float trail = step(0.0, d) * smoothstep(0.22, 0.0, d) * 0.16;

	// Rachaduras radiais atrás da frente de onda
	float a = ang * 10.0;
	float spikes = pow(abs(sin(a + hash(floor(a / 3.14159)) * 6.0)), 36.0);
	float crack = spikes * smoothstep(0.0, 0.10, d) * smoothstep(0.55, 0.0, d) * cracks;

	float fade = 1.0 - smoothstep(0.55, 1.0, progress);
	float mask = 1.0 - smoothstep(0.96, 1.0, r);

	float outv = (ring * 1.25 + trail + crack * 0.85) * fade * mask;
	ALBEDO = mix(color.rgb, vec3(1.0), ring * 0.45) * intensity;
	ALPHA = clamp(outv, 0.0, 1.0);
}
