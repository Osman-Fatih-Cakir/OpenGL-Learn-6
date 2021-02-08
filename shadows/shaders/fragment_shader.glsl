#version 330 core

in VS_OUT {
    vec3 fPos;
    vec3 fNormal;
    vec4 fPos_light_space;
} fs_in;

out vec4 out_color;

uniform sampler2D shadow_map;

uniform vec3 light_pos;
uniform vec3 eye;

uniform int enable_pcf;
uniform int enable_shadow_acne;

uniform vec4 fColor;

// Return shadow value, (1.0: shadow, 0.0: non-shadow)
float shadow_calculation(vec4 _fPos_light_space, float bias)
{
    // Perspective divide
    vec3 proj_coord = _fPos_light_space.xyz / _fPos_light_space.w;

    // Transform to [1, 0] range
    proj_coord = proj_coord * 0.5 + 0.5;

    // Get closest depth value from light's perspective (using [0,1] range fPos_light as coords)
    float closest_depth = texture(shadow_map, proj_coord.xy).r; 

    // Get depth of current fragment from light's perspective
    float current_depth = proj_coord.z;

    // Check if the fragment is in shadow or not
    float shadow = 0.0;
    if (enable_pcf == 1) // Use PCF (perenrage-closer-filtering) for more good looking shadow edges
    {
        vec2 texel_size = 1.0 / textureSize(shadow_map, 0);
        for (int i = -1; i <= 1; i++)
        {
            for (int j = -1; j <= 1; j++)
            {
                float pcf_depth = texture(shadow_map, proj_coord.xy + vec2(i, j) * texel_size).r;
                shadow += current_depth - bias > pcf_depth ? 1.0 : 0.0;
            }
        }
        shadow /= 9.0;
    }
    else
    {
        shadow = current_depth - bias > closest_depth ? 1.0 : 0.0;
    }

    if(proj_coord.z > 1.0) // Out of projection borders
    {
        shadow = 0.0;
    }

    return shadow;
}

void main()
{
    vec4 color = fColor;

    // Blinn-Phong shading
    vec3 normal = normalize(fs_in.fNormal);
    vec3 light_color = vec3(0.3);
    // Ambient
    vec3 ambient = 0.2 * color.xyz; 
    // Diffuse
    vec3 light_dir = normalize(light_pos - fs_in.fPos);
    float diff = max(dot(light_dir, normal), 0.0);
    vec3 diffuse = diff * light_color;
    // Specular
    float spec = 0.0;
    vec3 view_dir = normalize(eye - fs_in.fPos);
    vec3 half_vector = normalize(light_dir + view_dir);
    spec = pow(max(dot(normal, half_vector), 0.0), 64.0);
    vec3 specular = spec * light_color;

    //
    //// Shadow
    //

    // For prevent shadow acne, we define a small bias value
    float bias = 0.0;
    if (enable_shadow_acne == 0)
    {
        bias = max(0.01 * (1.0 - dot(normal, light_dir)), 0.005);
    }
    float shadow = shadow_calculation(fs_in.fPos_light_space, bias);

    vec3 lighting = (ambient + (1.0 - shadow) * (diffuse + specular)) * color.xyz;
    out_color = vec4(lighting, 1.0);
}