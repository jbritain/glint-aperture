#ifndef SCENE_DATA_GLSL
#define SCENE_DATA_GLSL

layout(binding = 0) buffer sceneData {
    vec3 sunlightColor;
    vec3 skylightColor;
};

#endif // SCENE_DATA_GLSL
