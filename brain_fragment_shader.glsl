#version 120

// vertex to fragment shader io
varying vec3 normal;
varying vec3 distance_to_center;
varying vec4 color;
varying vec4 vertex_position;

float edgefalloff = 1.0;
float intensity = 0.5;
float ambient = 0.01;

void main()
{
    float opac = dot(normalize(-normal), normalize(-distance_to_center));
    opac = abs(opac);
    opac = ambient + intensity*(1.0-pow(opac, edgefalloff));
    
    gl_FragColor =  opac * color * exp(0.02 * (vertex_position.z + 300));
    gl_FragColor.a = opac;
}
