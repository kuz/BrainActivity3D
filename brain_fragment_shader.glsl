#version 120

// vertex to fragment shader io
varying vec3 normal;
varying vec3 distance_to_center;
varying vec4 color;
varying vec4 vertex_position;

uniform bool shader_xray;

float edgefalloff = 1.0;
float intensity = 0.2;
float ambient = 0.01;

vec4 blinn1(gl_LightSourceParameters light) {
    vec3 l = vec3(0, 0, 1);
    vec3 v = vec3(0, 0, 1);
    vec3 n = normalize(normal);
    float d = length(light.position - vertex_position);
    vec3 h = normalize(l+v);
    float attenuation = 1.0/(light.constantAttenuation +
                           light.linearAttenuation * d +
                           light.quadraticAttenuation * d * d);
    return   attenuation * (
                gl_FrontMaterial.diffuse*light.diffuse*max(dot(l, n), 0) +
                gl_FrontMaterial.specular*light.specular*pow(max(dot(h, n), 0), gl_FrontMaterial.shininess)
             );
}

vec4 blinn2(gl_LightSourceParameters light) {
    vec3 l = vec3(0, 0, -1);
    vec3 v = vec3(0, 0, -1);
    vec3 n = normalize(normal);
    float d = length(light.position - vertex_position);
    vec3 h = normalize(l+v);
    float attenuation = 1.0/(light.constantAttenuation +
                           light.linearAttenuation * d +
                           light.quadraticAttenuation * d * d);
    return   attenuation * (
                gl_FrontMaterial.diffuse*light.diffuse*max(dot(l, n), 0) +
                gl_FrontMaterial.specular*light.specular*pow(max(dot(h, n), 0), gl_FrontMaterial.shininess)
             );
}

void main()
{
    
    if (shader_xray == true) {
    
        float opac = dot(normalize(-normal), normalize(-distance_to_center));
        opac = abs(opac);
        opac = ambient + intensity*(1.0-pow(opac, edgefalloff));
    
        gl_FragColor =  opac * color * exp(0.02 * (vertex_position.z + 300));
        gl_FragColor.a = opac;
    
    } else {
    
        vec4 c = gl_FrontMaterial.ambient * gl_LightModel.ambient + blinn1(gl_LightSource[0]) + blinn2(gl_LightSource[0]);
        gl_FragColor = c;
    
    }
}
        

