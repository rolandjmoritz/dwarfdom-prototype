#ifndef DISPLAYNORMALSSHADER
	#define DISPLAYNORMALSSHADER

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"

	struct Attributes // world position
	{
		real4 positionOS : POSITION;
		real4 tangentOS : TANGENT;
		real3 normalOS : NORMAL;
		real2 uv : TEXCOORD0;
	};

	struct VertexOutput // local position
	{
		real4 positionCS : POSITION0;
		real3 normalVS : NORMAL;
		real2 uv : TEXCOORD0;
	};

	VertexOutput VertexProgram(Attributes attrInfo)
	{
		VertexOutput vertInfo;

		vertInfo.positionCS = TransformObjectToHClip(attrInfo.positionOS.xyz); // Clip space vertex position.
		vertInfo.normalVS = mul((real3x3)UNITY_MATRIX_MV, attrInfo.normalOS); // view space normal
		vertInfo.uv = attrInfo.uv;

		return vertInfo;
	}

	real4 FragmentProgram(VertexOutput vertInfo) : SV_Target
	{
		real3 surfaceNormals = normalize(vertInfo.normalVS);
		return real4(surfaceNormals * 0.5 + 0.5, 1);
	}

#endif