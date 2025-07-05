uniform float time;
uniform vec2 resolution;

vec2 hash2(float n) {
    return fract(sin(vec2(n, n + 1.0)) * vec2(43758.5453, 22578.1459));
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 fragCoord = screen_coords;
    vec2 uv = fragCoord / resolution.xy;
    vec2 centerUV = (fragCoord - 0.5 * resolution.xy) / resolution.y;
    float t = time * 0.2;
    vec3 col = vec3(0.0);

    for (int i = 0; i < 100; i++)
    {
        float seed = float(i);
        vec2 rnd = hash2(seed);

        // Random screen position
        vec2 starBase = rnd;

        // Star depth controls parallax and size
        float depth = fract(t + fract(sin(seed * 78.233) * 93.5453));
        float size = mix(0.001, 0.003, depth); // smaller size

        vec2 starPos = (starBase - 0.5) * mix(0.2, 1.5, pow(depth, 1.5));
        vec2 pos = centerUV - starPos;
        float dist = length(pos);

        // Soft falloff for brightness
        float brightness = exp(-pow(dist / size, 2.0)) * 1.2;

        col += vec3(brightness);
    }

    // Optional subtle tint
    col *= vec3(1.2, 1.3, 1.5);

    // Tone mapping
    col = 1.0 - exp(-col);

    return vec4(col, 1.0);
}
