#pragma header

uniform float uampmul;        // amplitude multiplier
uniform float uTime;          // time
uniform float uSpeed;         // how fast the waves move
uniform float uFrequency;     // number of waves
uniform bool  uEnabled;       // toggle for effect
uniform float uWaveAmplitude; // how much pixels stretch

vec4 sineWave(vec4 pt, vec2 pos)
{
    if (uEnabled && uampmul > 0.0)
    {
        float offsetX = sin(pt.y * uFrequency + uTime * uSpeed);
        float offsetY = sin(pt.x * (uFrequency * 2.0) - (uTime / 2.0) * uSpeed);
        float offsetZ = sin(pt.z * (uFrequency / 2.0) + (uTime / 3.0) * uSpeed);

        pt.x = mix(pt.x,
                   sin(pt.x / 2.0 * pt.y + (5.0 * offsetX) * pt.z),
                   uWaveAmplitude * uampmul);
        pt.y = mix(pt.y,
                   sin(pt.y / 3.0 * pt.z + (2.0 * offsetZ) - pt.x),
                   uWaveAmplitude * uampmul);
        pt.z = mix(pt.z,
                   sin(pt.z / 6.0 * (pt.x * offsetY) - (50.0 * offsetZ) * (pt.z * offsetX)),
                   uWaveAmplitude * uampmul);
    }

    return vec4(pt.x, pt.y, pt.z, pt.w);
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    gl_FragColor = sineWave(texture2D(bitmap, uv), uv);
}
