shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// Arco de corte luminoso (Brisingr / combo). PlaneMesh deitado; a frente do plano (-Z local) é o sentido do golpe.

uniform vec4 color : source_color = vec4(0.30, 0.85, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float intensity = 2.4;
uniform float arc_half_angle = 1.5;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	// ângulo 0 = frente (-Z do plano), positivo para a direita
	float ang = atan(uv.x, -uv.y);

	float sweep = mix(-arc_half_angle, arc_half_angle, progress);
	float behind = sweep - ang;
	float inarc = step(0.0, behind) * smoothstep(1.5, 0.0, behind) * step(ang, arc_half_angle);

	float band = smoothstep(0.50, 0.62, r) * (1.0 - smoothstep(0.88, 1.0, r));
	float edge = smoothstep(0.78, 0.92, r);

	float fade = 1.0 - smoothstep(0.65, 1.0, progress);
	float a = inarc * band * (0.45 + 0.85 * edge) * fade;

	ALBEDO = mix(color.rgb, vec3(1.0), edge * inarc * 0.6) * intensity;
	ALPHA = clamp(a, 0.0, 1.0);
}
