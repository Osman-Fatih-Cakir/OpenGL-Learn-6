#version 330 core

in vec2 fTexCoord;

out vec4 out_color;

uniform sampler2D depth_map;
uniform float near;
uniform float far;

// required when using a perspective projection matrix
float linearize_depth(float depth)
{
    float z = depth * 2.0 - 1.0; // Back to NDC 
    return (2.0 * near * far) / (far + near - z * (far - near));	
}

void main()
{
	float depth_value = texture(depth_map, fTexCoord).r;
    // out_color = vec4(vec3(linearize_depth(depth_value) / far), 1.0); // perspective
    out_color = vec4(vec3(depth_value), 1.0); // orthographic
}

