#version 120

// vertex to fragment shader io
varying vec3 normal;
varying vec3 distance_to_center;
varying vec4 color;
varying vec4 vertex_position;

uniform int shader_mode;


float edgefalloff = 1.0;
float intensity = 0.5;
float ambient = 0.01;

vec4 blinn(gl_LightSourceParameters light) {
    vec3 n = normalize(normal);
    vec3 l = normalize((light.position - vertex_position).xyz);
    float d = length(light.position - vertex_position);
    vec3 v = -normalize((vertex_position).xyz);
    vec3 h = normalize((l+v)/2.0);
    // Note: for purposes of efficiency we could have computed l, v and h in the
    // vertex shader and would only need to renormalize those here.

    float attenuation = 1/(light.constantAttenuation +
                           light.linearAttenuation * d +
                           light.quadraticAttenuation * d * d);

    return   attenuation * (
                gl_FrontMaterial.diffuse*light.diffuse*max(dot(l, n), 0) +
                gl_FrontMaterial.specular*light.specular*pow(max(dot(h, n), 0), gl_FrontMaterial.shininess)
             );
}

void main()
{    
    if (shader_mode == 0) {
        gl_FragColor = color;
    } else if (shader_mode == 1) {
        vec4 c = gl_FrontMaterial.emission + gl_FrontMaterial.ambient * gl_LightModel.ambient + blinn(gl_LightSource[0]);
        gl_FragColor = c;
    } else if (shader_mode == 2) {    
        float opac = dot(normalize(-normal), normalize(-distance_to_center));
        opac = abs(opac);
        opac = ambient + intensity*(1.0-pow(opac, edgefalloff));
        gl_FragColor =  color;// * exp(0.02 * (vertex_position.z + 300));
        gl_FragColor.a = opac;
    
    } else if (shader_mode == 3) {    
        float opac = dot(normalize(-normal), normalize(-distance_to_center));
        opac = abs(opac);
        opac = ambient + intensity/3.0*(1.0-pow(opac, edgefalloff));
        gl_FragColor =  color;// * exp(0.02 * (vertex_position.z + 300));
        gl_FragColor.a = opac;
    
    }
    else {
        gl_FragColor = vec4(0.5,0.5,0.5,1.0);
    }
}
        

