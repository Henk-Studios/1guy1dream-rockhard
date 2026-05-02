shader_type canvas_item;

uniform float crack_scale : hint_range(0.1, 5.0) = 1.0;
uniform float crack_threshold : hint_range(0.3, 0.9) = 0.6;

// Simple hash-based noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // smoothstep
    
    float n00 = hash(i);
    float n10 = hash(i + vec2(1.0, 0.0));
    float n01 = hash(i + vec2(0.0, 1.0));
    float n11 = hash(i + vec2(1.0, 1.0));
    
    float nx0 = mix(n00, n10, f.x);
    float nx1 = mix(n01, n11, f.x);
    return mix(nx0, nx1, f.y);
}

// void fragment() {
//     vec2 world_uv = WORLD_POSITION_CHANGED_MATRIX * FRAGCOORD;
//     vec2 crack_uv = world_uv / (16.0 * crack_scale);
    
//     float n = noise(crack_uv);
//     float cracks = step(crack_threshold, n);
    
//     vec4 original_color = texture(TEXTURE, UV);
//     vec3 crack_color = mix(original_color.rgb, vec3(0.2), cracks * 0.5);
    
//     COLOR = vec4(crack_color, original_color.a);
// }

uniform vec2 world_offset;

void fragment() {
    vec2 world_uv = (UV + world_offset) * (16.0 * crack_scale);
    
    float n = noise(world_uv);
    float cracks = step(crack_threshold, n);
    
    vec4 original_color = texture(TEXTURE, UV);
    vec3 crack_color = mix(original_color.rgb, vec3(0.2), cracks * 0.5);
    
    COLOR = vec4(crack_color, original_color.a);
}