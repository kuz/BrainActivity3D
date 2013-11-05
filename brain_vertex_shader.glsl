#version 330
// Application to vertex shader
out vec3 normal;
out vec3 distance;
out vec4 color;

void main()
{
	vec4 vertex_position = gl_ModelViewMatrix * gl_Vertex;	
	distance  = vertex_position.xyz - vec3 (0);
	normal  = gl_NormalMatrix * gl_Normal;
	color = gl_Color;
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;	
}