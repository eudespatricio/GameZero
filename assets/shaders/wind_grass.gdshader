shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 color_root : source_color = vec4(0.04, 0.12, 0.08, 1.0);
uniform vec4 color_tip : source_color = vec4(0.18, 0.65, 0.42, 1.0);
uniform float wind_speed = 2.2;
uniform float wind_strength = 0.25;
uniform float wind_wave_freq = 0.8;

void vertex() {
	// Apenas afeta o topo da lâmina de grama (onde VERTEX.y > 0.05)
	float height_factor = clamp(VERTEX.y, 0.0, 1.5);
	float wind_offset = sin(TIME * wind_speed + (NODE_POSITION_WORLD.x + VERTEX.x) * wind_wave_freq + (NODE_POSITION_WORLD.z + VERTEX.z) * wind_wave_freq);
	VERTEX.x += wind_offset * wind_strength * height_factor;
	VERTEX.z += cos(TIME * (wind_speed * 0.8) + (NODE_POSITION_WORLD.x) * 0.5) * (wind_strength * 0.6) * height_factor;
}

void fragment() {
	// Gradiente vertical do caule até a ponta
	float grad = clamp(UV.y, 0.0, 1.0);
	vec3 base_color = mix(color_tip.rgb, color_root.rgb, grad);
	
	ALBEDO = base_color;
	ROUGHNESS = 0.65;
	METALLIC = 0.05;
	SPECULAR = 0.2;
}
