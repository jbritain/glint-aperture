#ifndef UTIL_GLSL
#define UTIL_GLSL

float luminance(vec3 color){
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float linearstep(float edge0, float edge1, float x) {
  return clamp01((x - edge0) * rcp(edge1 - edge0));
}

float remap(float originalValue, float originalMin, float originalMax, float newMin, float newMax){
	return newMin + (((originalValue - originalMin) / (originalMax - originalMin)) * (newMax - newMin));
}

// https://blog.demofox.org/2022/01/01/interleaved-gradient-noise-a-different-kind-of-low-discrepancy-sequence/
// adapted with help from balint and hardester
float interleavedGradientNoise(vec2 coord){
	return fract(52.9829189 * fract(0.06711056 * coord.x + (0.00583715 * coord.y)));
}

float interleavedGradientNoise(vec2 coord, int frame){
	return interleavedGradientNoise(coord + 5.588238 * (frame & 63));
}

mat2 rotate(float a) {
    vec2 m;
    m.x = sin(a);
    m.y = cos(a);
	return mat2(m.y, -m.x,  m.x, m.y);
}


vec2 sincos(float x) { return vec2(sin(x), cos(x)); }

vec2 rotate(vec2 vector, float angle) {
	vec2 sc = sincos(angle);
	return vec2(sc.y * vector.x + sc.x * vector.y, sc.y * vector.y - sc.x * vector.x);
}

vec3 rotate(vec3 vector, vec3 axis, float angle) {
	// https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
	vec2 sc = sincos(angle);
	return sc.y * vector + sc.x * cross(axis, vector) + (1.0 - sc.y) * dot(axis, vector) * axis;
}

vec3 rotate(vec3 vector, vec3 from, vec3 to) {
	// where "from" and "to" are two unit vectors determining how far to rotate
	// adapted version of https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula

	float cosTheta = dot(from, to);
	if (abs(cosTheta) >= 0.9999) { return cosTheta < 0.0 ? -vector : vector; }
	vec3 axis = normalize(cross(from, to));

	vec2 sc = vec2(sqrt(1.0 - cosTheta * cosTheta), cosTheta);
	return sc.y * vector + sc.x * cross(axis, vector) + (1.0 - sc.y) * dot(axis, vector) * axis;
}

float henyeyGreenstein(float g, float costh)
{
  return (1.0 - g * g) / (4.0 * PI * pow(1.0 + g * g - 2.0 * g * costh, 3.0/2.0));
}

const float isotropicPhase = 0.25 / PI;

float dualHenyeyGreenstein(float g1, float g2, float costh, float weight) {
  return mix(henyeyGreenstein(g1, costh), henyeyGreenstein(g2, costh), weight);
}

vec3 multipleScattering(float density, float costh, float g1, float g2, vec3 extinction, int octaves, float lobeWeight, float attenuation, float contribution, float phaseAttenuation){
  vec3 radiance = vec3(0.0);

  // float attenuation = 0.9;
  // float contribution = 0.5;
  // float phaseAttenuation = 0.7;

  float a = 1.0;
  float b = 1.0;
  float c = 1.0;

  for(int n = 0; n < octaves; n++){
    float phase = dualHenyeyGreenstein(g1 * c, g2 * c, costh, lobeWeight);
    radiance += b * phase * exp(-density * extinction * a);

    a *= attenuation;
    b *= contribution;
    c *= (1.0 - phaseAttenuation);
  }

  return radiance;
}

vec3 hsv(vec3 c) {
	const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 rgb(vec3 c) {
	const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	
	return c.z * mix(K.xxx, clamp01(p - K.xxx), c.y);
}

// O is the ray origin, D is the direction
// height is the height of the plane
bool rayPlaneIntersection(vec3 O, vec3 D, float height, inout vec3 point){
  vec3 N = vec3(0.0, sign(O.y - height), 0.0); // plane normal vector
  vec3 P = vec3(0.0, height, 0.0); // point on the plane

  float NoD = dot(N, D);
  if(NoD == 0.0){
    return false;
  }

  float t = dot(N, P - O) / NoD;

  point = O + t*D;

  if(t < 0){
    return false;
  }

  return true;
}

vec2 vogelDiscSample(int stepIndex, int stepCount, float noise) {
	float rotation = noise * 2 * PI;
	const float goldenAngle = 2.4;

	float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
	float theta = stepIndex * goldenAngle + rotation;

	return r * vec2(cos(theta), sin(theta));
}

// fast acos and sqrt from ebin

#define fsqrt(x) intBitsToFloat(0x1FBD1DF5 + (floatBitsToInt(x) >> 1))
float facos(float x) {
	float ax = abs(x);
	float res = -0.156583 * ax + PI;
	res *= fsqrt(1.0 - ax);
	return x >= 0 ? res : PI - res;
}

float getMiePhase(float cosTheta) {
	const float g = 0.8;
	const float scale = 3.0/(8.0*PI);
	
	float num = (1.0-g*g)*(1.0+cosTheta*cosTheta);
	float denom = (2.0+g*g)*pow((1.0 + g*g - 2.0*g*cosTheta), 1.5);
	
	return scale*num/denom;
}

float getRayleighPhase(float cosTheta) {
	const float k = 3.0/(16.0*PI);
	return k*(1.0+cosTheta*cosTheta);
}

mat3 frisvadTBN(vec3 normal){
	mat3 tbn;
	tbn[2] = normal;

	if(normal.z < -0.9) {
		tbn[0] = vec3(0.,-1,0);
		tbn[1] = vec3(-1, 0, 0);
	} else {
		float a = 1./(1.+normal.z);
		float b = -normal.x*normal.y*a;
		tbn[0] = vec3(1. - normal.x*normal.x*a, b, -normal.x) ;
		tbn[1] = vec3(b, 1. - normal.y*normal.y*a , -normal.y);
	}

	return tbn;
}

uniform sampler2D blueNoiseTex;
vec4 blueNoise(vec2 texcoord){
  ivec2 sampleCoord = ivec2(texcoord * ap.game.screenSize);
  sampleCoord = sampleCoord % ivec2(1024);

  return texelFetch(blueNoiseTex, sampleCoord, 0);
}

vec4 blueNoise(in vec2 texcoord, int frame){
  const float g = 1.6180339887498948482;
  const float a1 = rcp(g);
  const float a2 = rcp(pow2(g));

  vec2 offset = vec2(fract(0.5 + a1 * frame), fract(0.5 + a2 * frame));
  texcoord += offset;

  return blueNoise(texcoord);
}

float mean(vec3 x){
	return (x.x + x.y + x.z) / 3.0;
}

float bayer2(vec2 a) {
    a = floor(a);
    return fract(a.x * 0.5 + a.y * a.y * 0.75);
}

#define bayer4(a) (bayer2(a * 0.5) * 0.25 + bayer2(a))
#define bayer8(a) (bayer4(a * 0.5) * 0.25 + bayer2(a))
#define bayer16(a) (bayer8(a * 0.5) * 0.25 + bayer2(a))

#endif // UTIL_GLSL
