shader_type canvas_item;
render_mode unshaded;

// Passe de pós-processamento 2D (não substitui o tonemap 3D): dá acabamento
// cinematográfico ao quadro — vinheta, contraste, saturação e split-tone
// (sombras frias / altas luzes quentes), típico de ARPG dark fantasy.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.42;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.42;
uniform float contrast : hint_range(0.8, 1.5) = 1.05;
uniform float saturation : hint_range(0.5, 1.6) = 1.06;
uniform vec3 shadow_tint : source_color = vec3(0.035, 0.055, 0.085);
uniform vec3 highlight_tint : source_color = vec3(1.03, 1.0, 0.95);
uniform float grain_strength : hint_range(0.0, 0.06) = 0.012;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	// Contraste em torno do cinza médio
	col = (col - 0.5) * contrast + 0.5;

	// Saturação seletiva
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(luma), col, saturation);

	// Split-tone: sombras puxam para o azul profundo, luzes para o dourado
	col = mix(col + shadow_tint * (1.0 - luma), col * highlight_tint, smoothstep(0.35, 1.0, luma));

	// Vinheta radial suave
	vec2 d = (SCREEN_UV - vec2(0.5)) * vec2(1.0, 0.92);
	float dist = length(d) * 1.35;
	float vig = 1.0 - smoothstep(vignette_start, 1.05, dist) * vignette_strength;
	col *= vig;

	// Grão sutil para quebrar banding do céu/fog
	float g = hash12(SCREEN_UV * vec2(1920.0, 1080.0) + vec2(TIME * 37.0));
	col += (g - 0.5) * grain_strength;

	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), 1.0);
}
