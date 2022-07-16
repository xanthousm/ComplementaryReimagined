////////////////////////////////////////
// Complementary Reimagined by EminGT //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;
in vec2 lmCoord;

flat in vec3 normal, upVec, sunVec, northVec, eastVec;

in vec4 glColor;

//Uniforms//
uniform int isEyeInWater;
uniform int entityId;
uniform int blockEntityId;

uniform float viewWidth;
uniform float viewHeight;
uniform float nightVision;
uniform float frameTimeCounter;

uniform ivec2 atlasSize;

uniform vec3 fogColor;
uniform vec3 skyColor;
uniform vec3 cameraPosition;

uniform vec4 entityColor;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform sampler2D texture;

#ifdef CLOUD_SHADOWS
	uniform sampler2D gaux3;
#endif

//Pipeline Constants//

//Common Variables//
float NdotU = dot(normal, upVec);
float SdotU = dot(sunVec, upVec);
float sunFactor = SdotU < 0.0 ? clamp(SdotU + 0.375, 0.0, 0.75) / 0.75 : clamp(SdotU + 0.03125, 0.0, 0.0625) / 0.0625;
float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
float sunVisibility2 = sunVisibility * sunVisibility;
float shadowTimeVar1 = abs(sunVisibility - 0.5) * 2.0;
float shadowTimeVar2 = shadowTimeVar1 * shadowTimeVar1;
float shadowTime = shadowTimeVar2 * shadowTimeVar2;

#ifdef OVERWORLD
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
#else
	vec3 lightVec = sunVec;
#endif

//Common Functions//

//Includes//
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/lighting/mainLighting.glsl"

//Program//
void main() {
	vec4 color = texture2D(texture, texCoord);
	color *= glColor;

	float materialMask = OSIEBB * 4.0; // No SSAO, No TAA
	
	//lightning fix
	if (entityId == 50004) {
		color.a = 1.0;
	}
	if (color.a > 0.00001) {
		color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		vec3 viewPos = ScreenToView(screenPos);
		vec3 nViewPos = normalize(viewPos);
		vec3 playerPos = ViewToPlayer(viewPos);
		float lViewPos = length(viewPos);
		float VdotN = dot(nViewPos, normal);

		float emission = 0.0, highlightMult = 1.0;
		vec2 lmCoordM = lmCoord;
		vec3 normalM = VdotN > 0.0 ? -normal : normal; // Inverted Normal Workaround
		vec3 shadowMult = vec3(1.0);
		#ifdef IPBR
			#include "/lib/materials/entityMaterials.glsl"
		#else
			// I should put player effects here when I actually do player effects
		#endif
		//lightning fix
		if (entityId == 50004) {
			color = vec4(0.8, 0.85, 0.9, 0.5);
			emission = 0.25;
		}
		DoLighting(color.rgb, shadowMult, playerPos, viewPos, lViewPos, normalM, lmCoordM,
		           true, false, false, 0,
			       0.0, highlightMult, emission);
	}

	/* DRAWBUFFERS:01 */
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(0.0, materialMask, 0.0, 1.0);
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;
out vec2 lmCoord;

flat out vec3 normal, upVec, sunVec, northVec, eastVec;

out vec4 glColor;

//Uniforms//
#ifdef FLICKERING_FIX
	uniform int entityId;

	uniform vec3 cameraPosition;

	uniform mat4 gbufferModelViewInverse;
#endif

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
	gl_Position = ftransform();

	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	lmCoord  = GetLightMapCoordinates();

	glColor = gl_Color;

	normal = normalize(gl_NormalMatrix * gl_Normal);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
	northVec = normalize(gbufferModelView[2].xyz);
	sunVec = GetSunVector();

	#ifdef GBUFFERS_ENTITIES_GLOWING
		if (glColor.a > 0.99) gl_Position.z *= 0.01;
	#endif

	#ifdef FLICKERING_FIX
		if (entityId == 50008 || entityId == 50012) { // Item Frame, Glow Item Frame
			if (dot(normal, upVec) > 0.99) {
				vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
				vec3 comPos = fract(position.xyz + cameraPosition);
				comPos = abs(comPos - vec3(0.5));
				if ((comPos.y > 0.437 && comPos.y < 0.438) || (comPos.y > 0.468 && comPos.y < 0.469)) {
					gl_Position.z += 0.0001;
				}
			}
		}
	#endif
}

#endif
