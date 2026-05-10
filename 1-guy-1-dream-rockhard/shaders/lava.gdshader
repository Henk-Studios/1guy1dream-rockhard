shader_type canvas_item;

uniform float timeScaleFactor = .04;
uniform float worldScale = 0.01;
uniform float opacity = 1.0;
uniform float borderFadeWidth = 28.0;
uniform float borderWaveAmount = 18.0;
uniform float borderWaveScale = 0.0025;
uniform float borderWaveSpeed = 1.5;

// Make sure to use a seamless noise texture
uniform sampler2D noise_texture: repeat_enable, filter_linear;

varying vec2 world_pos;
varying vec2 local_pos;

float localTime() {
	return TIME * timeScaleFactor;
}

mat2 makem2(float theta) {
	float c = cos(theta);
	float s = sin(theta);
	return mat2(vec2(c, -s), vec2(s, c));
}

float noise(vec2 x) {
	return texture(noise_texture, x * .01).x;
}

vec2 gradn(vec2 p) {
	float ep = .09;
	float gradx = noise(vec2(p.x + ep, p.y)) - noise(vec2(p.x - ep, p.y));
	float grady = noise(vec2(p.x, p.y + ep)) - noise(vec2(p.x, p.y - ep));
	return vec2(gradx, grady);
}

float flow(vec2 p) {
	float z = 2.;
	float rz = 0.;
	vec2 bp = p;
	
	for(float i = 1.; i < 7.; ++i) {
		p += localTime() * .6;
		bp += localTime() * 1.9;
		vec2 gr = gradn(i * p * .34 + localTime() * 1.);
		gr *= makem2(localTime() * 6. - (.05 * p.x + 0.03 * p.y) * 40.);
		p += gr * .5;
		rz += (sin(noise(p) * 7.) *.5 + .5) / z;
		p = mix(bp, p, .77);
		z *= 1.4;
		p *= 2.;
		bp *= 1.9;
	}
	return rz;
}

void vertex() {
	local_pos = VERTEX;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = world_pos * worldScale;
	
	float rz = flow(p);
	vec3 col = vec3(.2, .07, .01) / rz;
	col = pow(col, vec3(1.4));

	float edge_dist = min(
		min(local_pos.x - (-960.0), 967.0 - local_pos.x),
		min(local_pos.y - (-10.0), 6174.0 - local_pos.y)
	);
	float t = localTime() * borderWaveSpeed;
	vec2 wave_pos = world_pos * borderWaveScale;
	wave_pos += vec2(t * 1.3, t * -0.9);
	float wave = noise(wave_pos) * 2.0 - 1.0;
	wave += noise(wave_pos * 1.9 + vec2(t * 0.7, t * 1.1)) * 2.0 - 1.0;
	wave += sin(world_pos.x * 0.003 + t * 2.2) * 0.5;
	float border_alpha = smoothstep(0.0, borderFadeWidth, edge_dist + wave * borderWaveAmount);
	
	COLOR = vec4(col, opacity * border_alpha);
}