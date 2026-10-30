shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

uniform vec4 wing_color_core : source_color = vec4(0.04, 0.15, 0.32, 0.45);
uniform vec4 wing_color_edge : source_color = vec4(0.2, 0.85, 0.95, 0.9);
uniform float emission_power : hint_range(0.0, 5.0) = 1.2;
uniform float fresnel_power : hint_range(0.5, 6.0) = 2.5;

void fragment() {
	// Gradiente da borda e altura da asa
	float edge = clamp(abs(UV.x - 0.5) * 2.0, 0.0, 1.0);
	float vertical = clamp(UV.y, 0.0, 1.0);
	
	// Efeito Fresnel para borda brilhante e centro translucido
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	
	float glow_factor = pow(edge, 2.2) * 0.7 + fresnel * 0.5 + pow(vertical, 2.5) * 0.2;
	glow_factor = clamp(glow_factor, 0.0, 1.0);

	vec3 col = mix(wing_color_core.rgb, wing_color_edge.rgb, glow_factor);
	float pulse = (sin(TIME * 2.2) + 1.0) * 0.5;

	ALBEDO = col;
	ALPHA = mix(wing_color_core.a, wing_color_edge.a, glow_factor);
	EMISSION = wing_color_edge.rgb * (emission_power + pulse * 0.4) * pow(glow_factor, 1.8);
	ROUGHNESS = 0.15;
	METALLIC = 0.3;
}
