#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec2 vTexCoord;

out vec2 fTexCoord;

void main()
{
	fTexCoord = vTexCoord;

	gl_Position = vec4(position, 1.0f);
}

