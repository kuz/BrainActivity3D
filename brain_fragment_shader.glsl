#version 330
// vertex to fragment shader io
in vec3 normal;
in vec3 distance;
in vec4 color;

float edgefalloff = 1.0;
float intensity = 0.5;
float ambient = 0.01;

void main()
{
    float opac = dot(normalize(-normal), normalize(-distance));
    opac = abs(opac);
    opac = ambient + intensity*(1.0-pow(opac, edgefalloff));
    opac = 1.0 - opac;
    
    gl_FragColor =  opac * color;
    gl_FragColor.a = opac;
}
