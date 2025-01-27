#ifndef DEBUG_GLSL
#define DEBUG_GLSL

#if defined DEBUG_ENABLE
layout (rgba8) uniform image2D debugImg;

void show(vec4 x, vec4 fragCoord){
  imageStore(debugImg, ivec2(fragCoord.xy), x);
}

void show(vec3 x, vec4 fragCoord){
  show(vec4(x, 1.0), fragCoord);
}

void show(vec2 x, vec4 fragCoord){
  show(vec3(x, 0.0), fragCoord);
}

void show(float x, vec4 fragCoord){
  show(vec3(x), fragCoord);
}

void show(bool x, vec4 fragCoord){
  show(float(x), fragCoord);
}

#else
void show(vec4 x, vec4 fragCoord){
}

void show(vec3 x, vec4 fragCoord){
}

void show(vec2 x, vec4 fragCoord){
}

void show(float x, vec4 fragCoord){
}

void show(bool x, vec4 fragCoord){
}
#endif

#define show(a) show(a, gl_FragCoord)

#endif // DEBUG_GLSL