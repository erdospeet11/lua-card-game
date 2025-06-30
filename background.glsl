uniform float time;
uniform vec2 resolution;

// Manual tanh implementation since it's not available in GLSL ES
vec3 tanh_approx(vec3 x) {
    vec3 x2 = x * x;
    vec3 a = x * (135135.0 + x2 * (17325.0 + x2 * (378.0 + x2)));
    vec3 b = 135135.0 + x2 * (62370.0 + x2 * (3150.0 + x2 * 28.0));
    return a / b;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords.xy / resolution.xy;
    vec2 r = uv * 2.0 - 1.0;
    r.x *= resolution.x / resolution.y;

    vec3 o = vec3(0.0);
    float t = time;
    float z = 0.0;
    float d = 0.0;

    for (float i = 0.0; i < 50.0; i++) {
        vec3 colorSource = vec3(r, 0.5);
        vec3 p = z * normalize(colorSource * 2.0 - vec3(r.x, r.y, r.x));
        p.z += 9.0;
        p = vec3(p.y + 5.0 - 0.6 * z, t - atan(p.x, p.z) * 4.0, length(p));
        
        for (float j = 1.0; j < 7.0; j++) {
            p += sin(vec3(p.z, p.x, p.y) * j + t + i * 0.2) / j;
        }
        
        d = 0.1 * length(vec4(cos(p) - 1.0, p.x));
        z += d;
        o += (cos(sin(i) + p.y + vec3(2.0, 4.0, 5.0)) + 1.0) / max(d, 0.001);
    }

    vec3 result = tanh_approx(o * o / 200000.0);
    return vec4(result, 1.0);
} 