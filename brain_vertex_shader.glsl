#version 120
// Application to vertex shader
varying vec3 normal;
varying vec3 distance_to_center;
varying vec4 color;

void main()
{
	vec4 vertex_position = gl_ModelViewMatrix * gl_Vertex;	
	distance_to_center  = vertex_position.xyz - vec3 (0);
	normal  = gl_NormalMatrix * gl_Normal;
	color = gl_Color;
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;	
}