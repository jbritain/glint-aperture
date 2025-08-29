#version 460 core

layout(local_size_x = 8, local_size_y = 8) in;

#include "/lib/common.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/util/misc.glsl"
#include "/lib/util/dither.glsl"

// TODO: holy shit definitely not this
#define gl_FragCoord gl_GlobalInvocationID

#include "/lib/atmospherics/volumetric_clouds.glsl"

layout(rgba16f) uniform image2D cloud_spheremap;

void main(){
  ivec2 texel_coord = ivec2(gl_GlobalInvocationID.xy);
  ivec2 lut_res = imageSize(cloud_spheremap);

  vec2 uv;
  uv.x = clamp(texel_coord.x, 0.0, lut_res.x - 1.0) / lut_res.x;
  uv.y = clamp(texel_coord.y, 0.0, lut_res.y - 1.0) / lut_res.y;

  vec3 dir = hemispherical_to_cartesian(uv * TAU);

  vec4 clouds = get_clouds(ap.camera.pos, dir, true, false);

  if(any(isnan(clouds))){
    clouds = vec4(0.0, 0.0, 0.0, 1.0);
  }

  imageStore(cloud_spheremap, texel_coord, clouds);


}