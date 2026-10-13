// Ocean water shader for Godot 4.x (Forward+ / Mobile)
// 5x Gerstner waves + scrolling normal maps + depth-based absorption,
// refraction, crest/shore foam and backlit subsurface glow.
shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

// ---------- Waves ----------
// xy = direction, z = steepness (keep the sum of all z below ~1.0), w = wavelength
group_uniforms waves;
uniform vec4 wave_a = vec4(1.0, 0.3, 0.22, 38.0);
uniform vec4 wave_b = vec4(0.7, 0.7, 0.18, 21.0);
uniform vec4 wave_c = vec4(-0.4, 0.9, 0.14, 12.0);
uniform vec4 wave_d = vec4(0.9, -0.5, 0.10, 7.5);
uniform vec4 wave_e = vec4(-0.8, -0.3, 0.08, 4.5);
uniform float amplitude : hint_range(0.0, 1.5) = 0.9;
uniform float wave_speed : hint_range(0.0, 3.0) = 1.0;

// ---------- Color ----------
group_uniforms color;
uniform vec4 shallow_color : source_color = vec4(0.02, 0.62, 0.66, 1.0);
uniform vec4 deep_color : source_color = vec4(0.01, 0.10, 0.26, 1.0);
uniform float absorption : hint_range(0.01, 2.0) = 0.25;
uniform float refraction_strength : hint_range(0.0, 0.2) = 0.04;
uniform vec4 sss_color : source_color = vec4(0.05, 0.55, 0.45, 1.0);
uniform float sss_strength : hint_range(0.0, 3.0) = 1.0;

// ---------- Surface detail ----------
group_uniforms surface;
uniform sampler2D normal_a : hint_normal, repeat_enable, filter_linear_mipmap;
uniform sampler2D normal_b : hint_normal, repeat_enable, filter_linear_mipmap;
uniform float normal_scale = 0.08;
uniform vec2 scroll_a = vec2(0.03, 0.02);
uniform vec2 scroll_b = vec2(-0.02, 0.04);
uniform float normal_strength : hint_range(0.0, 2.0) = 0.6;
uniform float normal_fade_start = 30.0;
uniform float normal_fade_end = 120.0;
uniform float water_roughness : hint_range(0.0, 1.0) = 0.04;

// ---------- Foam ----------
group_uniforms foam;
uniform sampler2D foam_noise : repeat_enable, filter_linear_mipmap; // NoiseTexture2D (seamless)
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float foam_amount : hint_range(0.0, 1.0) = 0.7;
uniform float crest_threshold : hint_range(0.0, 1.0) = 0.55;
uniform float foam_noise_scale = 0.05;
uniform float shore_foam_width = 0.6;

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

varying vec3 v_world;
varying float v_crest;

void gerstner(vec4 w, vec2 p, float t, inout vec3 pos, inout vec3 tg, inout vec3 bn, inout float h, inout float tot) {
	vec2 d = normalize(w.xy);
	float s = w.z * amplitude;
	float k = TAU / w.w;
	float c = sqrt(9.8 / k);
	float f = k * (dot(d, p) - c * t * wave_speed);
	float a = s / k;
	float sn = sin(f);
	float cs = cos(f);
	pos += vec3(d.x * a * cs, a * sn, d.y * a * cs);
	tg += vec3(-d.x * d.x * s * sn, d.x * s * cs, -d.x * d.y * s * sn);
	bn += vec3(-d.x * d.y * s * sn, d.y * s * cs, -d.y * d.y * s * sn);
	h += a * sn;
	tot += a;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 p = wp.xz;
	vec3 pos = vec3(0.0);
	vec3 tg = vec3(1.0, 0.0, 0.0);
	vec3 bn = vec3(0.0, 0.0, 1.0);
	float h = 0.0;
	float tot = 0.0;

	gerstner(wave_a, p, TIME, pos, tg, bn, h, tot);
	gerstner(wave_b, p, TIME, pos, tg, bn, h, tot);
	gerstner(wave_c, p, TIME, pos, tg, bn, h, tot);
	gerstner(wave_d, p, TIME, pos, tg, bn, h, tot);
	gerstner(wave_e, p, TIME, pos, tg, bn, h, tot);

	VERTEX += pos;
	NORMAL = normalize(cross(bn, tg));
	v_world = wp + pos;
	v_crest = h / max(tot, 0.0001);
}

void fragment() {
	// --- detail normals (fade out with distance) ---
	vec2 uv = v_world.xz * normal_scale;
	vec3 n1 = texture(normal_a, uv + TIME * scroll_a).rgb;
	vec3 n2 = texture(normal_b, uv * 2.3 + TIME * scroll_b).rgb;
	vec3 nm = mix(n1, n2, 0.5);
	float dist = length(VERTEX);
	float fade = 1.0 - smoothstep(normal_fade_start, normal_fade_end, dist);
	NORMAL_MAP = nm;
	NORMAL_MAP_DEPTH = normal_strength * fade;

	// --- water thickness from depth buffer ---
	float depth_raw = texture(depth_tex, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 scene_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	scene_view.xyz /= scene_view.w;
	float thickness = max(VERTEX.z - scene_view.z, 0.0);

	// --- refraction + absorption ---
	vec2 offset = (nm.xy * 2.0 - 1.0) * refraction_strength * fade;
	vec3 refr = textureLod(screen_tex, SCREEN_UV + offset, 0.0).rgb;
	float depth_fade = 1.0 - exp(-thickness * absorption);
	vec3 water = mix(refr * shallow_color.rgb, deep_color.rgb, clamp(depth_fade, 0.0, 1.0));
	water = mix(water, shallow_color.rgb, clamp(v_crest, 0.0, 1.0) * 0.25);

	// --- foam: wave crests + shoreline ---
	float n = texture(foam_noise, v_world.xz * foam_noise_scale + vec2(TIME * 0.02, 0.0)).r;
	float crest_foam = smoothstep(crest_threshold, crest_threshold + 0.25, v_crest + (n - 0.5) * 0.35) * foam_amount;
	float shore_foam = (1.0 - smoothstep(0.0, shore_foam_width, thickness)) * smoothstep(0.3, 0.6, n);
	float foam = clamp(crest_foam + shore_foam, 0.0, 1.0);

	// --- output ---
	// Water body goes in EMISSION so refracted pixels aren't lit twice;
	// reflections (Fresnel) come from the engine's built-in specular.
	ALBEDO = foam_color.rgb * foam;
	EMISSION = water * (1.0 - foam);
	ROUGHNESS = mix(water_roughness, 0.7, foam);
	SPECULAR = 0.5;
	METALLIC = 0.0;
	BACKLIGHT = sss_color.rgb * smoothstep(0.0, 0.8, v_crest) * sss_strength;
}
