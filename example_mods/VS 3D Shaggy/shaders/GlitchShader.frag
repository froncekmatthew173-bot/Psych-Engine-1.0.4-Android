#ifdef GL_ES
precision mediump float;
#endif

#pragma header   // this is used by Haxe/OpenFL to inject common shader vars

// Uniforms
uniform float uTime;           // Time
uniform float uSpeed;          // How fast the waves move
uniform float uFrequency;      // Number of waves
uniform bool  uEnabled;        // Enable toggle
uniform float uWaveAmplitude;  // Amplitude of wave distortion

vec2 sineWave(vec2 pt)
{
    float x = 0.0;
    float y = 0.0;
    
    float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
    float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
    pt.x += offsetX; // * (pt.y - 1.0); // Uncomment to stop bottom part of the screen from moving
    pt.y += offsetY;

    return vec2(pt.x + x, pt.y + y);
}

void main()
{
    vec2 uv = sineWave(openfl_TextureCoordv);
    gl_FragColor = texture2D(bitmap, uv);
}
