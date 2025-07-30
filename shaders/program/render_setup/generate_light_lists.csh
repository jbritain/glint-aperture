layout(local_size_x = 64) in;

#include "/lib/buffers/light_lists.glsl"

void main(){


  ap_PointLight light = iris_getPointLight(uint(gl_GlobalInvocationID.x));


}