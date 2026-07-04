#pragma header
		
const float TAU = 6.2831853072;

uniform bool useGradient;       // true = use color gradient, false = solid
uniform vec4 colorStart;        // color at the start of the pie
uniform vec4 colorEnd;          // color at the end of the pie

uniform float _amount;
uniform float _start;
uniform float _end;
		
float getGradiant(in vec2 dist)
{
	float start = _start / 360.0;
	float delta = (_end - _start) / 360.0;
	float angle = atan(dist.x, -dist.y) / TAU;
    if (angle < 0.0) angle += 1.0; // keep in [0,1)

	if (_end > _start)
		return mod(angle - start, 1.0) / delta;
	else
		return mod(start - angle, 1.0) / -delta;
}
		
float wedge(in vec2 uv, in float ratio)
{
	vec2 dist = uv - vec2(0.5);
	float grad = getGradiant(dist);
	return step(ratio, grad < 0.0 ? 1.0 : grad);
}

void main()
{
    vec2 uv = openfl_TextureCoordv - vec2(0.5);
    
    float dist = length(uv);

    if (dist > 0.5) {
        discard;
    }

    if (_amount > 0.0)
    {
        float amount = clamp(_amount, 0.0, 1.0);
        vec4 bitmap = flixel_texture2D(bitmap, openfl_TextureCoordv);

        gl_FragColor = mix(bitmap, vec4(0.0), wedge(openfl_TextureCoordv, amount));
    }
    else
    {
        gl_FragColor = vec4(0.0);
    }
}