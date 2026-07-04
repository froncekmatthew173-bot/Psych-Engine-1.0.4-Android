#pragma header

uniform float strength;
uniform vec3 glowColor;

void main()
{
    vec4 tex = texture2D(bitmap, openfl_TextureCoordv);
    float glow = tex.a * strength;

    vec3 finalColor = tex.rgb + glow * glowColor;
    gl_FragColor = vec4(finalColor, tex.a);
}
